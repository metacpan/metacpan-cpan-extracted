package Developer::Dashboard::CLI::Query;

use strict;
use warnings;

our $VERSION = '2.76';

use Exporter 'import';

use TOML::Tiny ();
use XML::Parser ();
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
    my $value = _select_query_value( $data, $path );
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

    my $path = @rest ? join( ' ', @rest ) : '';
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

# _path_uses_perl_expression($path)
# Decides whether a query path should be treated as a Perl expression over $d instead of dotted traversal.
# Input: raw query path string.
# Output: true when the path requires Perl-expression evaluation.
sub _path_uses_perl_expression {
    my ($path) = @_;
    return 0 if !defined $path || $path eq '' || $path eq '$d' || $path eq '.';
    return 0 if $path =~ /^\$d(?:\.[A-Za-z0-9_]+)*\z/;
    return index( $path, '$d' ) >= 0 ? 1 : 0;
}

# _select_query_value($data, $path)
# Chooses either dotted-path traversal or Perl-expression evaluation for the requested query selector.
# Input: parsed Perl data structure and raw path or expression string.
# Output: selected scalar, hash ref, array ref, or undef.
sub _select_query_value {
    my ( $data, $path ) = @_;
    return $data if !defined $path || $path eq '';
    return _evaluate_query_expression( $data, $path ) if _path_uses_perl_expression($path);
    return _extract_query_path( $data, $path );
}

# _evaluate_query_expression($data, $expr)
# Evaluates a user-supplied Perl expression with $d bound to the decoded query data.
# Input: parsed Perl data structure and expression string.
# Output: scalar result, array ref for list results, or undef.
sub _evaluate_query_expression {
    my ( $data, $expr ) = @_;
    my $code = eval <<"PERL_EVAL";
sub {
    my (\$d) = \@_;
    return do { $expr };
}
PERL_EVAL
    die "Query expression '$expr' failed: $@" if $@;

    if ( $expr =~ /^\s*scalar\b/ ) {
        my $scalar = eval { scalar $code->($data) };
        die "Query expression '$expr' failed: $@" if $@;
        return $scalar;
    }

    my @list = eval { $code->($data) };
    die "Query expression '$expr' failed: $@" if $@;
    return \@list if _expression_prefers_list_output($expr);
    return \@list if @list > 1;
    return $list[0] if @list == 1;
    return [];
}

# _expression_prefers_list_output($expr)
# Detects common list-oriented Perl query expressions so one-item list results stay list-shaped.
# Input: raw query expression string.
# Output: true when the expression should keep list context output as an array ref.
sub _expression_prefers_list_output {
    my ($expr) = @_;
    return 0 if !defined $expr || $expr =~ /^\s*scalar\b/;
    return 0 if $expr =~ /\bjoin\b/;
    return $expr =~ /\b(?:sort|map|grep|keys|values)\b/ ? 1 : 0;
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
    my $parser = XML::Parser->new( Style => 'Tree' );
    my $tree = $parser->parse($text);
    return _xml_tree_to_data($tree);
}

# _xml_tree_to_data($tree)
# Converts the XML::Parser tree output into a hash/array/scalar structure that dotted paths and $d expressions can traverse.
# Input: XML::Parser tree array reference.
# Output: hash reference keyed by the document root tag.
sub _xml_tree_to_data {
    my ($tree) = @_;
    die 'XML tree must be an array reference' if ref($tree) ne 'ARRAY' || @{$tree} < 2;
    my ( $root_name, $root_children ) = @{$tree};
    return {
        $root_name => _xml_element_payload($root_children),
    };
}

# _xml_element_payload($children)
# Converts one XML::Parser child array into the dashboard XML query payload form.
# Input: XML::Parser child array reference.
# Output: scalar text, hash ref, or array-backed element payload.
sub _xml_element_payload {
    my ($children) = @_;
    die 'XML element payload must be an array reference' if ref($children) ne 'ARRAY';
    my $attrs = $children->[0];
    my @items = @{$children}[ 1 .. $#$children ];
    my @text;
    my %elements;
    my %repeated;

    while (@items) {
        my $name = shift @items;
        my $value = shift @items;
        if ( defined $name && $name eq '0' ) {
            push @text, $value if defined $value && $value !~ /^\s*$/;
            next;
        }

        my $decoded = _xml_element_payload($value);
        if ( exists $elements{$name} ) {
            if ( !$repeated{$name} ) {
                $elements{$name} = [ $elements{$name} ];
                $repeated{$name} = 1;
            }
            push @{ $elements{$name} }, $decoded;
            next;
        }
        $elements{$name} = $decoded;
    }

    my $text = join '', @text;
    my $has_attrs = ref($attrs) eq 'HASH' && keys %{$attrs};
    my $has_children = keys %elements ? 1 : 0;

    return $text if !$has_attrs && !$has_children;

    my %node = %elements;
    $node{_attributes} = $attrs if $has_attrs;
    $node{_text} = $text if $text ne '';
    return \%node;
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
common contract for every query helper: accept an optional dotted path or
C<$d>-based Perl expression plus an optional file path in either order, read
from STDIN when no file is given, parse the requested format, and print either
a scalar value or canonical JSON for structured data.

=head1 WHY IT EXISTS

It exists because the dashboard ships a family of query commands that should
feel consistent across file formats. Keeping parser selection, source
selection, dotted-path traversal, C<$d> expression handling, and
scalar-vs-structure output rules in one module prevents the helper wrappers
from drifting apart and keeps release tests focused on one implementation.

=head1 WHEN TO USE

Use this file when changing dotted-path semantics, C<$d> expression semantics,
format-specific parsing behavior, file-vs-STDIN selection, scalar-vs-JSON
output, or the exact error surface for malformed input and missing path
segments.

=head1 HOW TO USE

Call C<run_query_command> from a staged helper such as C<jq> or C<tomq>,
passing the helper name and the raw argv list. The module treats the first
existing file argument as the input source, rejoins the remaining non-file
arguments into one query string, accepts C<$d> or C<.> for the whole parsed
document, uses dotted traversal for plain path strings, and evaluates real
C<$d>-based Perl expressions such as C<sort keys %$d> against the decoded data.
Scalars print as plain text while arrays and hashes are emitted as canonical
JSON. The XML path now decodes XML into nested hashes and arrays so dotted
paths and C<$d> expressions work there too.

=head1 WHAT USES IT

It is used by the private query helper scripts under C<share/private-cli/>,
by install and release smoke runs that verify format-specific helpers, and by
coverage tests that exercise parser choice, order-independent argv handling,
root-document queries, and format-specific edge cases.

=head1 EXAMPLES

  printf '{"alpha":{"beta":2}}' | dashboard jq alpha.beta
  dashboard jq response.json '$d'
  dashboard jq response.json 'sort keys %$d'
  printf 'alpha:\n  beta: 3\n' | dashboard yq alpha.beta
  printf 'alpha.beta=5\nname=demo\n' | dashboard propq '$d'
  printf 'alpha,beta\n7,8\n' | dashboard csvq 1.1
  printf '<root><value>demo</value></root>' | dashboard xmlq root.value
  printf '<root><item id="1">x</item><item id="2">y</item></root>' | dashboard xmlq 'join q(,), map { $_->{_attributes}{id} } @{ $d->{root}{item} }'

=for comment FULL-POD-DOC END

=cut
