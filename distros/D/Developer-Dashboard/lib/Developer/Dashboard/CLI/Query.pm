package Developer::Dashboard::CLI::Query;

use strict;
use warnings;

our $VERSION = '1.33';

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

    return json_decode($text)           if $command eq 'pjq';
    return YAML::XS::Load($text)        if $command eq 'pyq';
    return TOML::Tiny::from_toml($text) if $command eq 'ptomq';
    return _parse_java_properties($text) if $command eq 'pjp';

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
  run_query_command( command => 'pjq', args => \@ARGV );

=head1 DESCRIPTION

Provides the lightweight shared implementation behind the standalone
C<pjq>, C<pyq>, C<ptomq>, and C<pjp> executables and the proxied
C<dashboard ...> command paths.

=cut
