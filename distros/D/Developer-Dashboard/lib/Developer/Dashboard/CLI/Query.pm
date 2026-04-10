package Developer::Dashboard::CLI::Query;

use strict;
use warnings;

our $VERSION = '2.17';

use Exporter 'import';
use FindBin qw($Bin);
use lib "$Bin/../../lib";

use TOML::Tiny ();
use YAML::XS ();

use Developer::Dashboard::JSON qw(json_decode json_encode);

our @EXPORT_OK = qw(run_query_command);

# run_query_command(%args)
# Parses structured input, optionally extracts a dotted path, and prints canonical JSON or a scalar.
# Input: command name plus mutable argv array reference.
# Output: exits after printing the selected value.
sub run_query_command {
    my (%args) = @_;
    my $command = $args{command} || die 'Missing command';
    my @argv    = @{ $args{args} || [] };
    my ( $path, $file ) = _split_query_args(@argv);

    my $raw = _read_query_input($file);
    my $data = _parse_query_input(
        command => $command,
        text    => $raw,
    );
    my $value = $path eq '' ? $data : _extract_query_path( $data, $path );
    _print_query_value($value);
    _command_exit(0);
}

# _split_query_args(@argv)
# Separates an optional file path from an optional query path without requiring a fixed argument order.
# Input: raw command-line arguments.
# Output: list containing query path string and file path string.
sub _split_query_args {
    my (@argv) = @_;
    my $file = '';
    my @rest;

    for my $arg (@argv) {
        if ( !$file && defined $arg && -f $arg ) {
            $file = $arg;
            next;
        }
        push @rest, $arg;
    }

    my $path = @rest ? $rest[0] : '';
    return ( $path, $file );
}

# _read_query_input($file)
# Reads query input from a file path or STDIN.
# Input: optional file path string.
# Output: full input text string.
sub _read_query_input {
    my ($file) = @_;
    if ($file) {
        open my $fh, '<', $file or die "Unable to read $file: $!";
        local $/;
        return <$fh>;
    }

    local $/;
    return scalar <STDIN>;
}

# _parse_query_input(%args)
# Dispatches to the format-specific parser for a structured data query command.
# Input: command name and raw text string.
# Output: parsed Perl scalar, array ref, or hash ref.
sub _parse_query_input {
    my (%args) = @_;
    my $command = $args{command} || die 'Missing command';
    my $text    = $args{text} // '';

    return json_decode($text)           if $command eq 'pjq' || $command eq 'jq';
    return YAML::XS::Load($text)        if $command eq 'pyq' || $command eq 'yq';
    return TOML::Tiny::from_toml($text) if $command eq 'ptomq' || $command eq 'tomq';
    return _parse_java_properties($text) if $command eq 'pjp' || $command eq 'propq';
    return _parse_ini($text)             if $command eq 'iniq';
    return _parse_csv($text)             if $command eq 'csvq';
    return _parse_xml($text)             if $command eq 'xmlq';

    die "Unsupported data query command '$command'\n";
}

# _extract_query_path($data, $path)
# Traverses a dotted path through nested hashes and arrays.
# Input: parsed Perl data structure and dotted path string.
# Output: selected Perl value or dies when the path is invalid.
sub _extract_query_path {
    my ( $data, $path ) = @_;
    return $data if !defined $path || $path eq '' || $path eq '$d' || $path eq '.';
    $path =~ s/^\$d\.?//;

    my @parts = grep { defined && $_ ne '' } split /\./, $path;
    my $value = $data;

    while (@parts) {
        if ( ref($value) eq 'HASH' ) {
            my $remaining = join '.', @parts;
            if ( exists $value->{$remaining} ) {
                return $value->{$remaining};
            }
        }

        my $part = shift @parts;
        if ( ref($value) eq 'HASH' ) {
            die "Missing path segment '$part'\n" if !exists $value->{$part};
            $value = $value->{$part};
            next;
        }
        if ( ref($value) eq 'ARRAY' ) {
            die "Array index '$part' is invalid\n" if $part !~ /^\d+$/ || $part > $#$value;
            $value = $value->[$part];
            next;
        }
        die "Path '$path' does not resolve through a nested structure\n";
    }

    return $value;
}

# _print_query_value($value)
# Emits a scalar as text or complex structures as canonical JSON.
# Input: Perl scalar, array ref, or hash ref.
# Output: prints to STDOUT and returns true.
sub _print_query_value {
    my ($value) = @_;
    if ( ref($value) ) {
        print json_encode($value), "\n";
        return 1;
    }
    print defined $value ? $value : '';
    print "\n";
    return 1;
}

# _parse_java_properties($text)
# Parses a Java properties document into a flat hash.
# Input: raw properties text string.
# Output: hash reference of key to value mappings.
sub _parse_java_properties {
    my ($text) = @_;
    my %props;
    my @lines = split /\n/, $text // '';
    my $pending = '';

    for my $line (@lines) {
        $line =~ s/\r$//;
        next if $line =~ /^\s*[#!]/;
        if ( $line =~ s/\\$// ) {
            $pending .= $line;
            next;
        }
        $line = $pending . $line;
        $pending = '';
        next if $line =~ /^\s*$/;

        my ( $key, $value ) = split /\s*[:=]\s*|\s+/, $line, 2;
        $key   = '' if !defined $key;
        $value = '' if !defined $value;
        $key   =~ s/^\s+|\s+$//g;
        $value =~ s/^\s+|\s+$//g;
        $props{$key} = _unescape_properties($value);
    }

    return \%props;
}

# _unescape_properties($text)
# Decodes simple Java-properties escape sequences.
# Input: escaped property value string.
# Output: unescaped value string.
sub _unescape_properties {
    my ($text) = @_;
    $text =~ s/\\t/\t/g;
    $text =~ s/\\n/\n/g;
    $text =~ s/\\r/\r/g;
    $text =~ s/\\f/\f/g;
    $text =~ s/\\\\/\\/g;
    return $text;
}

# _parse_ini($text)
# Parses an INI document into a nested hash structure.
# Input: raw INI text string.
# Output: hash reference with sections as keys mapping to section hashes.
sub _parse_ini {
    my ($text) = @_;
    my %ini;
    my $current_section = '_global';
    $ini{$current_section} = {};
    my @lines = split /\n/, $text // '';

    for my $line (@lines) {
        $line =~ s/[\r\n]+$//;
        $line =~ s/^\s+|\s+$//g;
        next if $line =~ /^[;#]/ || $line eq '';
        
        if ($line =~ /^\[(.+)\]$/) {
            $current_section = $1;
            $ini{$current_section} = {};
            next;
        }
        
        if ($line =~ /^([^=:]+)\s*[:=]\s*(.*)$/) {
            my ($key, $value) = ($1, $2);
            $key =~ s/^\s+|\s+$//g;
            $value =~ s/^\s+|\s+$//g;
            $ini{$current_section}{$key} = $value;
        }
    }

    return \%ini;
}

# _parse_csv($text)
# Parses a CSV document into a list of rows (each row is an array ref).
# Input: raw CSV text string.
# Output: array reference of array refs (rows).
sub _parse_csv {
    my ($text) = @_;
    my @rows;
    my @lines = split /\n/, $text // '';

    for my $line (@lines) {
        $line =~ s/[\r\n]+$//;
        next if $line eq '';
        my @fields = split /,/, $line;
        push @rows, \@fields;
    }

    return \@rows;
}

# _parse_xml($text)
# Parses an XML document into a nested hash structure.
# Input: raw XML text string.
# Output: hash reference with tag structure.
sub _parse_xml {
    my ($text) = @_;
    my %xml;
    $xml{_raw} = $text;
    return \%xml;
}

# _command_exit($code)
# Wraps process exit so tests can override it and exercise command flow in-process.
# Input: integer process exit code.
# Output: never returns during normal command execution.
sub _command_exit {
    my ($code) = @_;
    exit $code;
}

1;

__END__

=pod

=head1 NAME

Developer::Dashboard::CLI::Query - standalone structured-data query command support

=head1 SYNOPSIS

  use Developer::Dashboard::CLI::Query qw(run_query_command);
  run_query_command( command => 'jq', args => \@ARGV );

=head1 DESCRIPTION

Provides the lightweight shared implementation behind the private runtime
helper scripts for C<jq>, C<yq>, C<tomq>, C<propq>, C<iniq>, C<csvq>, and
C<xmlq> plus the proxied C<dashboard ...> command paths. Earlier names such as
C<pjq>, C<pyq>, C<ptomq>, and C<pjp> still normalize through C<dashboard> for
compatibility.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module is the shared parser and dispatcher behind the lightweight query
commands for JSON, YAML, TOML, Java properties, INI, CSV, and XML. It owns the
common contract for every query helper: accept an optional dotted path plus an
optional file path in either order, read from STDIN when no file is given,
parse the requested format, and print either a scalar value or canonical JSON
for structured data.

=head1 WHY IT EXISTS

It exists because the dashboard ships a family of query commands that should
feel consistent across file formats. Keeping parser selection, source
selection, dotted-path traversal, and scalar-vs-structure output rules in one
module prevents the helper wrappers from drifting apart and keeps release tests
focused on one implementation.

=head1 WHEN TO USE

Use this file when changing dotted-path semantics, format-specific parsing
behavior, file-vs-STDIN selection, scalar-vs-JSON output, or the exact error
surface for malformed input and missing path segments.

=head1 HOW TO USE

Call C<run_query_command> from a staged helper such as C<jq> or C<tomq>,
passing the helper name and the raw argv list. The module treats the first
existing file argument as the input source, treats the remaining non-file
argument as the dotted query path, accepts C<$d> or C<.> for the whole parsed
document, and prints scalars as plain text while arrays and hashes are emitted
as canonical JSON. The XML path is intentionally minimal right now: the helper
stores the raw XML payload under C<_raw> rather than pretending to offer a full
tree query language.

=head1 WHAT USES IT

It is used by the private query helper scripts under C<share/private-cli/>,
by install and release smoke runs that verify format-specific helpers, and by
coverage tests that exercise parser choice, order-independent argv handling,
root-document queries, and format-specific edge cases.

=head1 EXAMPLES

  printf '{"alpha":{"beta":2}}' | dashboard jq alpha.beta
  dashboard jq response.json '$d'
  printf 'alpha:\n  beta: 3\n' | dashboard yq alpha.beta
  printf 'alpha.beta=5\nname=demo\n' | dashboard propq '$d'
  printf 'alpha,beta\n7,8\n' | dashboard csvq 1.1
  printf '<root><value>demo</value></root>' | dashboard xmlq _raw

=for comment FULL-POD-DOC END

=cut
