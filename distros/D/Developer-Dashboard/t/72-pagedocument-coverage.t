#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);

use lib 'lib';
use Developer::Dashboard::PageDocument;

# Warnings are fatal in this repo: trap every warning and assert none appear.
my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

# Hermetic, isolated runtime. PageDocument is a pure data/format model, but keep
# the process rooted in a throwaway HOME/cwd so nothing can touch the real tree.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "chdir $home: $!";

my $PD  = 'Developer::Dashboard::PageDocument';
my $SEP = $Developer::Dashboard::PageDocument::LEGACY_SEP;

# ---------------------------------------------------------------------------
# from_instruction(undef): drives the "text is undefined" guard (line 63 true).
# The empty parse then dies with the no-sections error, which we swallow.
# ---------------------------------------------------------------------------
{
    my $page = eval { $PD->from_instruction(undef) };
    ok( !defined $page, 'from_instruction(undef) does not return a page' );
    like( $@, qr/did not contain any sections/, 'undef instruction hits the empty-sections die' );
}

# ---------------------------------------------------------------------------
# Modern format: a content line appears before the first === SECTION === header
# (line 76 "current is empty" true side), and an ICON section is present
# (line 90 exists-true side).
# ---------------------------------------------------------------------------
{
    my $text = join "\n",
        'preamble before any header',
        '=== TITLE ===',    'Modern Title',
        '=== ICON ===',     'star',
        '=== HTML ===',     '<b>hi</b>',
        '=== BOOKMARK ===', 'bm-modern',
        '=== NOTE ===',     'a modern note',
        '=== STASH ===',    '{ "k": "v" }',
        '=== CODE0 ===',    'print 1';
    my $page = $PD->from_instruction($text);
    is( $page->{title},      'Modern Title', 'modern doc parses TITLE past the preamble line' );
    is( $page->{meta}{icon}, 'star',         'modern doc parses ICON section (exists-true)' );
    is( $page->{state}{k},   'v',            'modern JSON STASH decodes' );
}

# Modern format WITHOUT an ICON section (line 90 exists-false side).
{
    my $page = $PD->from_instruction("=== TITLE ===\nNo Icon Here");
    is( $page->{title}, 'No Icon Here', 'modern doc without ICON still parses' );
    ok( !exists $page->{meta}{icon}, 'no icon key is set when ICON section is absent' );
}

# ---------------------------------------------------------------------------
# Legacy format with a rich mix: valid keys, a CODE key, an unknown key that is
# skipped (line 420 "next" side + inner grep condition matrix), and a perl-ish
# STASH that decodes through the eval path (line 401 true side).
# ---------------------------------------------------------------------------
{
    my $text = join "\n$SEP\n",
        'TITLE: Legacy Title',
        'CODE0: print "code";',
        'FOO: this key is unknown and is skipped',
        'ICON: L',
        'BOOKMARK: bm-legacy',
        'NOTE: legacy note',
        'STASH: foo => 1',
        'HTML: <i>body</i>';
    my $page = $PD->from_instruction($text);
    is( $page->{title},                'Legacy Title', 'legacy doc parses TITLE' );
    is( $page->{state}{foo},           1,              'perl-ish legacy STASH decodes via eval path' );
    is( $page->{meta}{source_format},  'legacy',       'legacy source format is recorded' );
    ok( ( grep { $_->{id} eq 'CODE0' } @{ $page->{meta}{codes} } ), 'CODE0 section is captured' );
    ok( !$page->{id} || $page->{id} eq 'bm-legacy', 'unknown FOO key did not become the bookmark id' );
}

# Legacy doc that begins with a separator: yields an empty leading part that is
# skipped (line 416 "part is empty" true side).
{
    my $page = $PD->from_instruction("---\nTITLE: Leading Sep");
    is( $page->{title}, 'Leading Sep', 'leading --- separator yields an empty part that is skipped' );
}

# ---------------------------------------------------------------------------
# legacy_instruction serialization: exercises the per-section guard conditions.
# Fully populated page -> all "both-true" sides, plus a code with a body and a
# code with no body key (line 203 "// empty" left-undef side).
# ---------------------------------------------------------------------------
{
    my $page = $PD->new(
        id          => 'bm1',
        title       => 'T',
        description => 'D',
        state       => { a => 1 },
        layout      => { body => '<p>hi</p>' },
        meta        => {
            icon  => 'star',
            codes => [ { id => 'CODE0', body => 'print 1' }, { id => 'CODE1' } ],
        },
    );
    my $out = $page->legacy_instruction;
    like( $out, qr/TITLE: T/,          'serializes TITLE' );
    like( $out, qr/ICON: star/,        'serializes ICON when set' );
    like( $out, qr/BOOKMARK: bm1/,     'serializes BOOKMARK when id set' );
    like( $out, qr/NOTE: D/,           'serializes NOTE when description set' );
    like( $out, qr{HTML: <p>hi</p>},   'serializes HTML when body set' );
    like( $out, qr/CODE0: print 1/,    'serializes a code body' );
    like( $out, qr/^CODE1:/m,          'serializes a code with no body key as an empty body' );
}

# Icon defined but empty string (line 192 left-true-right-false side).
{
    my $page = $PD->new( title => 'T', meta => { icon => '' } );
    my $out  = $page->legacy_instruction;
    unlike( $out, qr/^ICON:/m, 'empty icon string is not serialized' );
}

# Id defined but empty string (line 193 left-true-right-false side).
{
    my $page = $PD->new( title => 'T', id => '' );
    my $out  = $page->legacy_instruction;
    unlike( $out, qr/^BOOKMARK:/m, 'empty id string is not serialized' );
}

# Title undef internally (line 191 defined-or right side -> "Untitled").
{
    my $page = $PD->new( title => 'Whatever' );
    $page->{title} = undef;
    my $out = $page->legacy_instruction;
    like( $out, qr/TITLE: Untitled/, 'undef title falls back to Untitled' );
}

# Description undef internally (line 194 left operand false).
{
    my $page = $PD->new( title => 'T', description => 'x' );
    $page->{description} = undef;
    my $out = $page->legacy_instruction;
    unlike( $out, qr/^NOTE:/m, 'undef description is not serialized' );
}

# State undef internally (line 195 logical-or left operand false -> {}).
{
    my $page = $PD->new( title => 'T' );
    $page->{state} = undef;
    my $out = $page->legacy_instruction;
    like( $out, qr/STASH:/, 'undef state falls back to an empty stash section' );
}

# ---------------------------------------------------------------------------
# render_html: body present vs absent (line 239 ternary both sides).
# ---------------------------------------------------------------------------
{
    my $page = $PD->new( title => 'RT', description => 'RD', layout => { body => '<p>B</p>' } );
    my $html = $page->render_html;
    like( $html, qr{<p>B</p>},            'render_html includes the body when present' );
    like( $html, qr{<title>RT</title>},   'render_html includes the escaped title' );
    like( $html, qr{<p>RD</p>},           'render_html includes the description paragraph' );
}
{
    my $page = $PD->new( title => 'NB' );
    my $html = $page->render_html;
    like( $html, qr{class="body"></section>}, 'render_html emits an empty body section when body undef' );
}

# render_html runtime chunk handling: undef/ref chunks are skipped (lines 246 &
# 255 branch + condition matrix), a <script> without a marker vs with a marker
# (line 247 condition), and plain output/error text.
{
    my $page = $PD->new(
        title => 'RC',
        meta  => {
            runtime_outputs => [
                undef,
                {},
                '<script>plain output no marker</script>',
                '<script>set_chain_value("x","y")</script>',
                'plain trailing text',
            ],
            runtime_errors => [ undef, [], 'boom error' ],
        },
    );
    my $html = $page->render_html;
    like( $html, qr/plain output no marker/,          'non-bootstrap script goes to runtime output' );
    like( $html, qr/set_chain_value\("x","y"\)/,      'bootstrap-marker script is emitted' );
    like( $html, qr/plain trailing text/,             'plain runtime output is emitted' );
    like( $html, qr{class="runtime-error">boom error}, 'runtime error text is escaped and shown' );
    unlike( $html, qr/HASH\(0x|ARRAY\(0x/,            'ref runtime chunks are skipped, not stringified' );
}

# ---------------------------------------------------------------------------
# _decode_structured_json: valid JSON (line 384 true) vs JSON null that decodes
# to undef (line 384 false) vs empty text (early return).
# ---------------------------------------------------------------------------
is_deeply( $PD->can('_decode_structured_json')->('{"a":1}'), { a => 1 }, 'structured JSON decodes to a hash' );
is_deeply( $PD->can('_decode_structured_json')->('null'),    {},         'JSON null yields an empty hash (undef -> {})' );
is_deeply( $PD->can('_decode_structured_json')->(''),        {},         'empty structured JSON yields an empty hash' );

# _decode_stash_section: a legacy body whose eval fails (line 401 false -> {})
# and one that succeeds (line 401 true).
is_deeply( $PD->can('_decode_stash_section')->('oops'),      {},           'unparseable legacy stash falls back to {}' );
is_deeply( $PD->can('_decode_stash_section')->('foo => 1'),  { foo => 1 }, 'perl-ish legacy stash decodes to a hash' );

# _legacy_stash_text: non-hash arg (line 432 left-true), empty hash
# (right-true), populated hash (both-false).
is( $PD->can('_legacy_stash_text')->( [] ), '', 'non-hash stash value serializes to empty string' );
is( $PD->can('_legacy_stash_text')->( {} ), '', 'empty-hash stash value serializes to empty string' );
like( $PD->can('_legacy_stash_text')->( { foo => 1 } ), qr/foo => 1/, 'populated hash stash serializes pairs' );

# _template_value: nested resolution plus the terminal guards.
my $ctx = { a => { b => 'deep' }, s => 'str', n => undef, r => { x => 1 } };
is( $PD->can('_template_value')->( 'a.b',       $ctx ), 'deep', 'nested dot path resolves' );
is( $PD->can('_template_value')->( 's.b',       $ctx ), '',     'descending into a non-hash yields empty (473 left-true)' );
is( $PD->can('_template_value')->( 'a.missing', $ctx ), '',     'missing nested key yields empty (473 right-true)' );
is( $PD->can('_template_value')->( 'n',         $ctx ), '',     'undef leaf yields empty (476 left-true)' );
is( $PD->can('_template_value')->( 'r',         $ctx ), '',     'reference leaf yields empty (476 right-true)' );
is( $PD->can('_template_value')->( '.s',        $ctx ), 'str',  'leading-dot path drops empty segments (470)' );

# _trim / _trim_trailing_newline / _html: undef inputs (lines 636, 648, 659).
is( $PD->can('_trim')->(undef),                 '', '_trim(undef) is empty string' );
is( $PD->can('_trim_trailing_newline')->(undef), '', '_trim_trailing_newline(undef) is empty string' );
is( $PD->can('_html')->(undef),                 '', '_html(undef) is empty string' );
is( $PD->can('_html')->('<a> & "b"'), '&lt;a&gt; &amp; &quot;b&quot;', '_html escapes the standard entities' );

is_deeply( \@warnings, [], 'no warnings emitted during the run' )
    or diag( 'warnings: ' . join( ' | ', @warnings ) );

done_testing;

__END__

=pod

=head1 NAME

t/72-pagedocument-coverage.t - branch and condition coverage for the page document model

=head1 PURPOSE

This test drives every decision path in the page document model that the broader
suite leaves unexercised: the instruction parser's modern and legacy branches,
the per-section serialization guards, the HTML renderer's runtime-chunk handling,
and the private stash, template, trim, and escape helpers. It exists to hold the
module at full branch and condition coverage without weakening any behavior.

=head1 WHY IT EXISTS

The page document model is the format contract behind saved bookmarks, so its
guard clauses (undefined text, empty sections, unknown legacy keys, non-hash
stash values, undef or reference runtime chunks) must each be proven rather than
assumed. Those sides are hard to reach through the ordinary save/render flow, so
this file reaches them directly and pins them down against silent regression.

=head1 WHEN TO USE

Use this file when changing bookmark instruction parsing, the legacy separator
serialization, the page HTML renderer, or any of the module's private helpers.
Extend it first when a new branch or condition is introduced.

=head1 HOW TO USE

Run C<prove -lv t/72-pagedocument-coverage.t> while iterating, then confirm the
module still reports full branch and condition coverage under the repository
coverage gate before release.

=head1 WHAT USES IT

The repository test suite and the coverage gate use this file to keep the page
document model at full branch and condition coverage; developers use it as the
executable specification for the module's guard behavior.

=head1 EXAMPLES

Example 1:

  prove -lv t/72-pagedocument-coverage.t

Run the dedicated page document coverage check by itself.

Example 2:

  prove -lr t

Run it inside the full repository suite before release.

=cut
