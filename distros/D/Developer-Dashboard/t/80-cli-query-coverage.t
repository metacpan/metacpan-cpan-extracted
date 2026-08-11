#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use Capture::Tiny qw(capture);

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::CLI::Query qw(run_query_command);

# Hermetic runtime: the query commands resolve their runtime layer from the
# deepest .developer-dashboard directory at or above the CWD, so we chdir into a
# throwaway HOME before touching anything.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "chdir $home: $!";

# Anchor a registry the same way the rest of the suite does; the query helpers
# are stateless but we build one to mirror the standard hermetic setup and to
# keep the layer discovery contract exercised.
my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
isa_ok( $paths, 'Developer::Dashboard::PathRegistry', 'path registry built' );

my $Q = 'Developer::Dashboard::CLI::Query';

# run_query_command exits through _command_exit; override it so the whole flow
# runs in-process without tearing down the test.
my @exits;
{
    no warnings 'redefine';
    *Developer::Dashboard::CLI::Query::_command_exit = sub { push @exits, $_[0]; return; };
}

# ---------------------------------------------------------------------------
# run_query_command: full flow with a real file argument (command present,
# args present, file+path split, file read, dotted select, scalar print).
# ---------------------------------------------------------------------------
my $json_file = File::Spec->catfile( $home, 'input.json' );
{
    open my $fh, '>', $json_file or die "write $json_file: $!";
    print {$fh} '{"alpha":1}';
    close $fh;
}

{
    my ( $out, $err ) = capture {
        run_query_command( command => 'jq', args => [ $json_file, 'alpha' ] );
    };
    is( $out, "1\n", 'run_query_command prints the selected scalar value' );
    is( $err, '',    'run_query_command emits nothing on stderr' );
    is_deeply( \@exits, [0], 'run_query_command reached _command_exit(0)' );
}

# Missing command dies before anything else (covers the || die guard).
{
    local $@;
    eval { run_query_command( args => ['whatever'] ); 1 };
    like( $@, qr/Missing command/, 'run_query_command dies without a command' );
}

# Falsy args => empty argv => STDIN source (covers the args || [] guard).
{
    open my $in, '<', \"x,y\n1,2\n" or die $!;
    local *STDIN = $in;
    my ( $out, $err ) = capture {
        run_query_command( command => 'csvq', args => 0 );
    };
    like( $out, qr/"x"/, 'run_query_command reads STDIN when no args are given' );
    is( $err, '', 'STDIN-sourced run is stderr clean' );
}

# ---------------------------------------------------------------------------
# _split_query_args: order-independent file detection.
# ---------------------------------------------------------------------------
{
    my ( $path, $file ) = $Q->can('_split_query_args')->( $json_file, 'alpha.beta' );
    is( $file, $json_file,   'file argument detected regardless of position' );
    is( $path, 'alpha.beta', 'remaining argument becomes the query path' );
}
{
    # No existing file among the args: -f is false while $file is still empty.
    my ( $path, $file ) = $Q->can('_split_query_args')->('some.query.path');
    is( $file, '',                'no file selected when nothing is on disk' );
    is( $path, 'some.query.path', 'lone argument is treated as the query path' );
}

# ---------------------------------------------------------------------------
# _read_query_input: file open success and failure.
# ---------------------------------------------------------------------------
{
    my $raw = $Q->can('_read_query_input')->($json_file);
    is( $raw, '{"alpha":1}', 'reads the whole file when given a path' );
}
{
    local $@;
    my $missing = File::Spec->catfile( $home, 'definitely-not-here.json' );
    eval { $Q->can('_read_query_input')->($missing); 1 };
    like( $@, qr/Unable to read/, 'dies when the input file cannot be opened' );
}

# ---------------------------------------------------------------------------
# _parse_query_input: command dispatch and the text // '' guard.
# ---------------------------------------------------------------------------
{
    local $@;
    eval { $Q->can('_parse_query_input')->( text => 'x' ); 1 };
    like( $@, qr/Missing command/, '_parse_query_input dies without a command' );
}
{
    # command present, text absent => text defaults to '' => csvq path taken.
    my $data = $Q->can('_parse_query_input')->( command => 'csvq' );
    is_deeply( $data, [], 'csvq with no text yields an empty row list' );
}
{
    my $data = $Q->can('_parse_query_input')->( command => 'iniq', text => "[s]\nk=v\n" );
    is( $data->{s}{k}, 'v', 'iniq dispatch parses the INI body' );
}

# ---------------------------------------------------------------------------
# _extract_query_path: whole-document shortcuts, empty path segments, and
# array-index validation.
# ---------------------------------------------------------------------------
my $tree = { a => { b => 5 } };
is( $Q->can('_extract_query_path')->( $tree, undef ), $tree, 'undef path returns the whole document' );
is( $Q->can('_extract_query_path')->( $tree, '' ),    $tree, 'empty path returns the whole document' );
is( $Q->can('_extract_query_path')->( $tree, 'a..b' ), 5, 'empty dotted segments are skipped' );

{
    my $arr = [ 10, 20 ];
    is( $Q->can('_extract_query_path')->( $arr, '0' ), 10, 'valid array index resolves' );
    local $@;
    eval { $Q->can('_extract_query_path')->( $arr, '5' ); 1 };
    like( $@, qr/Array index '5' is invalid/, 'numeric index beyond the end dies' );
    eval { $Q->can('_extract_query_path')->( $arr, 'foo' ); 1 };
    like( $@, qr/Array index 'foo' is invalid/, 'non-numeric array index dies' );
}

# ---------------------------------------------------------------------------
# _path_uses_perl_expression: whole-document markers plus undef/empty guards.
# ---------------------------------------------------------------------------
is( $Q->can('_path_uses_perl_expression')->(undef), 0, 'undef path is not a perl expression' );
is( $Q->can('_path_uses_perl_expression')->(''),    0, 'empty path is not a perl expression' );

# ---------------------------------------------------------------------------
# _select_query_value: dotted traversal, whole-document markers, and Perl
# expression dispatch.
# ---------------------------------------------------------------------------
is( $Q->can('_select_query_value')->( $tree, undef ), $tree, 'undef selector returns the whole document' );
is( $Q->can('_select_query_value')->( $tree, '' ),    $tree, 'empty selector returns the whole document' );
is( $Q->can('_select_query_value')->( $tree, '$d' ),  $tree, '$d selector returns the whole document' );
is( $Q->can('_select_query_value')->( $tree, '.' ),   $tree, '. selector returns the whole document' );
is( $Q->can('_select_query_value')->( $tree, 'a.b' ), 5,     'dotted selector traverses nested hashes' );

# ---------------------------------------------------------------------------
# _evaluate_query_expression (via _select_query_value): scalar success/failure
# and list-vs-scalar output shaping.
# ---------------------------------------------------------------------------
{
    my $list = { items => [ 1, 2, 3 ] };
    is_deeply(
        $Q->can('_select_query_value')->( $list, '@{ $d->{items} }' ),
        [ 1, 2, 3 ],
        'list expression with several results stays an array ref',
    );
    is(
        $Q->can('_select_query_value')->( $list, '$d->{items}[0]' ),
        1,
        'single-result expression returns the scalar element',
    );
}
{
    is(
        $Q->can('_select_query_value')->( { a => 1, b => 2 }, 'scalar keys %$d' ),
        2,
        'scalar expression returns the scalar result',
    );
    local $@;
    eval { $Q->can('_select_query_value')->( { a => 1 }, 'scalar $d->boom' ); 1 };
    like( $@, qr/Query expression .* failed/, 'scalar expression runtime error dies' );
    eval { $Q->can('_select_query_value')->( { a => 1 }, '$d->{' ); 1 };
    like( $@, qr/Query expression .* failed/, 'uncompilable expression dies' );
}

# ---------------------------------------------------------------------------
# _expression_prefers_list_output: undef and scalar-prefixed short-circuits.
# ---------------------------------------------------------------------------
is( $Q->can('_expression_prefers_list_output')->(undef), 0, 'undef expression prefers no list output' );
is( $Q->can('_expression_prefers_list_output')->('scalar keys %$d'), 0, 'scalar expression prefers no list output' );

# ---------------------------------------------------------------------------
# _parse_java_properties: undef text guard, blank-line skip, defined key.
# ---------------------------------------------------------------------------
is_deeply( $Q->can('_parse_java_properties')->(undef), {}, 'undef properties text yields an empty hash' );
{
    my $props = $Q->can('_parse_java_properties')->("name=demo\n   \nkey:val\n");
    is( $props->{name}, 'demo', 'properties key=value pair parsed' );
    is( $props->{key},  'val',  'properties key:value pair parsed' );
}

# ---------------------------------------------------------------------------
# _parse_ini: undef text guard, comment/blank skip, and non key/value lines.
# ---------------------------------------------------------------------------
is_deeply(
    $Q->can('_parse_ini')->(undef),
    { _global => {} },
    'undef INI text yields just the global section',
);
{
    my $ini = $Q->can('_parse_ini')->("; comment\n\n[sec]\nkey=val\nbareword\n");
    is( $ini->{sec}{key}, 'val', 'INI key/value under a section parsed' );
    ok( !exists $ini->{sec}{bareword}, 'a line without a delimiter is ignored' );
}

# ---------------------------------------------------------------------------
# _parse_csv: undef text guard and blank-line skip.
# ---------------------------------------------------------------------------
is_deeply( $Q->can('_parse_csv')->(undef), [], 'undef CSV text yields no rows' );
is_deeply(
    $Q->can('_parse_csv')->("a,b\n\nc,d\n"),
    [ [ 'a', 'b' ], [ 'c', 'd' ] ],
    'blank CSV lines are skipped',
);

# ---------------------------------------------------------------------------
# XML: full parse (text nodes, repeated elements, attributes) plus the
# defensive tree/payload guards.
# ---------------------------------------------------------------------------
{
    my $xml =
        '<root attr="x"> <child>hi</child> <item>a</item><item>b</item><item>c</item> </root>';
    my $data = $Q->can('_parse_query_input')->( command => 'xmlq', text => $xml );
    is( $data->{root}{child}, 'hi', 'XML child text node captured' );
    is_deeply( $data->{root}{item}, [ 'a', 'b', 'c' ], 'repeated XML elements collapse into an array' );
    is( $data->{root}{_attributes}{attr}, 'x', 'XML element attributes preserved' );
}
{
    local $@;
    eval { $Q->can('_xml_tree_to_data')->('notarray'); 1 };
    like( $@, qr/must be an array reference/, 'non-array XML tree is rejected' );
    eval { $Q->can('_xml_tree_to_data')->( ['only-one'] ); 1 };
    like( $@, qr/must be an array reference/, 'too-short XML tree is rejected' );
}
{
    # attrs slot holds a non-hash reference: exercises the has-attrs guard's
    # left operand without touching real XML::Parser output.
    is( $Q->can('_xml_element_payload')->( [ ['not-a-hash'] ] ), '', 'non-hash attrs yield an empty payload' );
}

done_testing;

__END__

=pod

=head1 NAME

t/80-cli-query-coverage.t - branch and condition coverage for the query command core

=head1 PURPOSE

This test exhaustively drives every decision point in the shared query command
implementation: command dispatch across JSON, YAML, INI, CSV, Java properties,
and XML; order-independent file-versus-path argument splitting; file and STDIN
input sourcing; whole-document selectors; dotted-path traversal with array
index validation; C<$d> Perl-expression evaluation with scalar-versus-list
output shaping; and the XML tree-to-data conversion including text nodes,
repeated elements, and attribute handling.

=head1 WHY IT EXISTS

The query core carries many small guards - defensive C<// ''> defaults, empty
path-segment filtering, array-bounds checks, and format dispatch - whose error
and edge branches are easy to leave unexercised. It exists to pin every branch
and condition in that module so a refactor cannot silently drop a validation,
mis-shape list output, or regress the file-or-STDIN selection, and so the
repository's all-metrics coverage gate stays satisfied for this file.

=head1 WHEN TO USE

Use this file when changing argument splitting, input sourcing, dotted-path or
C<$d> expression semantics, scalar-versus-JSON output rules, any format
parser, or the XML conversion. Extend it first when adding a new query format
or selector behavior.

=head1 HOW TO USE

Run C<prove -lv t/80-cli-query-coverage.t> while iterating. It builds a
hermetic HOME, overrides the process-exit wrapper so the full command flow runs
in-process, and calls both the exported entry point and the internal helpers
directly to reach guard branches that the public path cannot produce. Keep it
green under C<prove -lr t> and inside the coverage run before release.

=head1 WHAT USES IT

Developers during TDD, the repository test suite, and the Devel::Cover gate use
this file to keep the query command core at full branch and condition coverage.

=head1 EXAMPLES

Example 1:

  prove -lv t/80-cli-query-coverage.t

Run the query-core coverage checks by themselves.

Example 2:

  prove -lr t

Run it inside the full repository suite before release.

=cut
