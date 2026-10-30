#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);

use lib 'lib';
use Developer::Dashboard::PageDocument;

{
    package Local::Problem48LegacyKeyReadCounter;

    sub TIEARRAY {
        my ( $class, $values ) = @_;
        return bless { values => $values, fetches => 0 }, $class;
    }

    sub FETCHSIZE { return scalar @{ $_[0]->{values} } }
    sub FETCH {
        my ( $self, $index ) = @_;
        $self->{fetches}++;
        return $self->{values}[$index];
    }
}

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

# Problem 48: reading a page id must not materialize the full public hash view.
{
    my $page = $PD->new( id => 'page-id-fast-path', title => 'Page ID' );
    is( $page->id, 'page-id-fast-path', 'id accessor returns the stored page id' );
    my $idless = $PD->new( title => 'No ID' );
    ok( !defined $idless->id, 'id accessor preserves an undefined page id' );
    my $mode = $PD->new( mode => 'render' );
    is( $mode->mode, 'render', 'mode accessor returns the stored mode' );
    is( $idless->mode, 'edit', 'mode accessor preserves the constructor default' );
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
        '=== HEAD ===',     '<meta name="robots" content="noindex">',
        '=== HTML ===',     '<b>hi</b>',
        '=== BOOKMARK ===', 'bm-modern',
        '=== NOTE ===',     'a modern note',
        '=== STASH ===',    '{ "k": "v" }',
        '=== CODE0 ===',    'print 1';
    my $page = $PD->from_instruction($text);
    is( $page->{title},      'Modern Title', 'modern doc parses TITLE past the preamble line' );
    is( $page->{meta}{icon}, 'star',         'modern doc parses ICON section (exists-true)' );
    is( $page->{meta}{head}, '<meta name="robots" content="noindex">', 'modern doc parses raw HEAD injection content' );
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
        'HEAD: <meta name="robots" content="noindex">',
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
    is( $page->{meta}{head}, '<meta name="robots" content="noindex">', 'legacy doc parses HEAD content' );
    ok( ( grep { $_->{id} eq 'CODE0' } @{ $page->{meta}{codes} } ), 'CODE0 section is captured' );
    ok( !$page->{id} || $page->{id} eq 'bm-legacy', 'unknown FOO key did not become the bookmark id' );
}

# Problem 48: the common one-section legacy instruction uses a single-section
# parser instead of allocating the split-parts list. Pin down the helper's
# exact section shape before wiring it into the production parser.
{
    my $parse_one = $PD->can('_parse_single_legacy_section');
    ok( $parse_one, 'single-section legacy parser helper is available' );
    my %undefined_single = $parse_one->(undef);
    is_deeply( \%undefined_single, {}, 'single-section parser returns no section for undefined input' );
    my %title = $parse_one->("\n TITLE :  Welcome\nline two \n");
    is_deeply( $title{TITLE}, [ 'Welcome', 'line two' ], 'single-section parser trims boundaries and preserves body lines' );
    my %code = $parse_one->("CODE1001: print 1\n");
    is_deeply( $code{CODE1001}, [ 'print 1' ], 'single-section parser accepts extended CODE section numbers' );
    my %unknown = $parse_one->('UNKNOWN: ignore me');
    is_deeply( \%unknown, {}, 'single-section parser discards unsupported section names' );
    my %empty = $parse_one->(" \n\t");
    is_deeply( \%empty, {}, 'single-section parser handles whitespace-only input' );
    my %undefined_legacy = $PD->can('_parse_legacy_sections')->(undef);
    is_deeply( \%undefined_legacy, {}, 'multi-section parser returns no sections for undefined input' );
}

# Problem 48: parsing a CODE key must not scan the 1,008-entry legacy-key list.
# The current parser also accepts CODE sections above CODE1000, so preserve it.
{
    my @original_keys = @Developer::Dashboard::PageDocument::LEGACY_KEYS;
    my $counter = tie @Developer::Dashboard::PageDocument::LEGACY_KEYS,
      'Local::Problem48LegacyKeyReadCounter', \@original_keys;
    my %sections = $PD->can('_parse_legacy_sections')->('CODE1000: final');
    is_deeply( $sections{CODE1000}, ['final'], 'legacy parser accepts the highest declared CODE key' );
    is( $counter->{fetches}, 0, 'legacy section allowlist validation does not linearly scan @LEGACY_KEYS' );
    my %extended = $PD->can('_parse_legacy_sections')->('CODE1001: extended');
    is_deeply( $extended{CODE1001}, ['extended'], 'legacy parser preserves acceptance of CODE keys above the declared range' );
    undef $counter;
    untie @Developer::Dashboard::PageDocument::LEGACY_KEYS;
    @Developer::Dashboard::PageDocument::LEGACY_KEYS = @original_keys;
}

# Legacy doc that begins with a separator: yields an empty leading part that is
# skipped (line 416 "part is empty" true side).
{
    my $page = $PD->from_instruction("---\nTITLE: Leading Sep");
    is( $page->{title}, 'Leading Sep', 'leading --- separator yields an empty part that is skipped' );
}

# Problem 48: hoisting the legacy Markdown separator regexp must preserve
# whitespace and CRLF delimiter behavior across multi-section documents.
{
    my %sections = $PD->can('_parse_legacy_sections')->(
        "TITLE: spaced separator\r\n  ---  \r\nHTML: body\r\n"
    );
    is_deeply( $sections{TITLE}, ['spaced separator'], 'legacy parser accepts padded CRLF Markdown separator' );
    is_deeply( $sections{HTML}, ['body'], 'legacy parser keeps the section after a padded CRLF separator' );
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
            head  => '<script>window.bookmarkHead = true;</script>',
            codes => [ { id => 'CODE0', body => 'print 1' }, { id => 'CODE1' } ],
        },
    );
    my $out = $page->legacy_instruction;
    like( $out, qr/TITLE: T/,          'serializes TITLE' );
    like( $out, qr/ICON: star/,        'serializes ICON when set' );
    like( $out, qr/^HEAD: <script>window\.bookmarkHead = true;<\/script>$/m, 'serializes HEAD when set' );
    like( $out, qr/BOOKMARK: bm1/,     'serializes BOOKMARK when id set' );
    like( $out, qr/NOTE: D/,           'serializes NOTE when description set' );
    like( $out, qr{HTML: <p>hi</p>},   'serializes HTML when body set' );
    like( $out, qr/CODE0: print 1/,    'serializes a code body' );
    like( $out, qr/^CODE1:/m,          'serializes a code with no body key as an empty body' );
}

# HEAD defined but empty (line 219: defined is true and the non-empty check is false).
{
    my $page = $PD->new( title => 'T', meta => { head => '' } );
    unlike( $page->legacy_instruction, qr/^HEAD:/m, 'an empty HEAD section is omitted from legacy output' );
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
    my $page = $PD->new(
        title       => 'RT',
        description => 'RD',
        layout      => { body => '<p>B</p>' },
        meta        => { head => '<meta name="x-bookmark" content="head-injected">' },
    );
    my $html = $page->render_html;
    like( $html, qr{<p>B</p>},            'render_html includes the body when present' );
    like( $html, qr{<title>RT</title>},   'render_html includes the escaped title' );
    like( $html, qr{<head>.*<meta name="x-bookmark" content="head-injected">.*</head>}s, 'render_html injects bookmark HEAD content inside the document head' );
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

{
    my $stash_text = q{p48_memo_copy_20261016 => { nested => ['original'] }};
    my $original_safe_parser = $PD->can('_safe_eval_stash_literal');
    my $safe_parser_calls = 0;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PageDocument::_safe_eval_stash_literal = sub {
            $safe_parser_calls++;
            return $original_safe_parser->(@_);
        };
        my $first = $PD->can('_decode_stash_section')->($stash_text);
        $first->{p48_memo_copy_20261016}{nested}[0] = 'mutated';
        my $second = $PD->can('_decode_stash_section')->($stash_text);
        is( $second->{p48_memo_copy_20261016}{nested}[0], 'original',
            'memoized legacy STASH returns a deep copy unaffected by caller mutation' );
        is( $safe_parser_calls, 1,
            'repeated identical legacy STASH text is evaluated in Safe only once' );
    }
    is_deeply( $PD->can('_decode_stash_section')->($stash_text),
        { p48_memo_copy_20261016 => { nested => ['original'] } },
        'memoized legacy STASH remains stable after the caller mutates a previous result' );
}

{
    my $stash_text = q{p48_memo_corruption_20261016 => 1};
    $PD->can('_decode_stash_section')->($stash_text);
    my $error = '';
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PageDocument::json_decode = sub { return [] };
        eval { $PD->can('_decode_stash_section')->($stash_text); 1 } or $error = $@;
    }
    like( $error, qr/Cached legacy STASH snapshot did not decode to a hash reference/,
        'memoized legacy STASH refuses a corrupt cached snapshot explicitly' );
}

{
    my $original_safe_parser = $PD->can('_safe_eval_stash_literal');
    my $safe_parser_calls = 0;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PageDocument::_safe_eval_stash_literal = sub {
            $safe_parser_calls++;
            return $original_safe_parser->(@_);
        };
        local $Developer::Dashboard::PageDocument::LEGACY_STASH_CACHE_MAX_ENTRIES = 2;
        my $first  = q{p48_lru_first_20261016 => 1};
        my $second = q{p48_lru_second_20261016 => 2};
        my $third  = q{p48_lru_third_20261016 => 3};
        $PD->can('_decode_stash_section')->($first);
        is( $safe_parser_calls, 1, 'first bounded-cache literal is parsed' );
        $PD->can('_decode_stash_section')->($second);
        is( $safe_parser_calls, 2, 'second bounded-cache literal fills the cache' );
        $PD->can('_decode_stash_section')->($first);
        is( $safe_parser_calls, 2, 'recently used first literal remains cached' );
        $PD->can('_decode_stash_section')->($third);
        is( $safe_parser_calls, 3, 'third literal evicts the least-recently-used entry' );
        $PD->can('_decode_stash_section')->($first);
        is( $safe_parser_calls, 3, 'most recently used first literal survives eviction' );
        $PD->can('_decode_stash_section')->($second);
        is( $safe_parser_calls, 4, 'least-recently-used second literal must be evaluated after eviction' );
    }
}

{
    my $original_safe_parser = $PD->can('_safe_eval_stash_literal');
    my $safe_parser_calls = 0;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PageDocument::_safe_eval_stash_literal = sub {
            $safe_parser_calls++;
            return $original_safe_parser->(@_);
        };
        local $Developer::Dashboard::PageDocument::LEGACY_STASH_CACHE_MAX_TEXT_BYTES = 1;
        my $oversized = q{p48_oversized_memo_20261016 => 1};
        $PD->can('_decode_stash_section')->($oversized);
        $PD->can('_decode_stash_section')->($oversized);
        is( $safe_parser_calls, 2, 'legacy STASH text over the cache byte limit is not retained' );
    }
}

{
    my $original_safe_parser = $PD->can('_safe_eval_stash_literal');
    my $safe_parser_calls = 0;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PageDocument::_safe_eval_stash_literal = sub {
            $safe_parser_calls++;
            return $original_safe_parser->(@_);
        };
        local $Developer::Dashboard::PageDocument::LEGACY_STASH_CACHE_MAX_ENTRIES = 0;
        my $disabled = q{p48_disabled_memo_20261016 => 1};
        $PD->can('_decode_stash_section')->($disabled);
        $PD->can('_decode_stash_section')->($disabled);
        is( $safe_parser_calls, 2, 'legacy STASH memoization can be disabled without changing results' );
    }
}

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
is( $PD->can('_html')->('&'), '&amp;', '_html escapes ampersand when it is the first metacharacter' );
is( $PD->can('_html')->('<'), '&lt;', '_html escapes less-than when no earlier metacharacter exists' );
is( $PD->can('_html')->('>'), '&gt;', '_html escapes greater-than when no earlier metacharacter exists' );
is( $PD->can('_html')->('"'), '&quot;', '_html escapes a quote when no earlier metacharacter exists' );
{
    local $Developer::Dashboard::HtmlEscape::XS_LOADED = 0;
    is( $PD->can('_html')->('<' . ('plain text ' x 8)), '&lt;' . ('plain text ' x 8),
        '_html preserves the long-string fallback when the optional XS backend is unavailable' );
}
{
    my $dense_unicode = ( '<&>' x 30 ) . '"' . chr(0x1F600);
    my $escaped = $PD->can('_html')->($dense_unicode);
    is( $escaped, ( '&lt;&amp;&gt;' x 30 ) . '&quot;' . chr(0x1F600),
        '_html preserves output for large dense escaped Unicode text' );
    is( utf8::is_utf8($escaped) ? 1 : 0, utf8::is_utf8($dense_unicode) ? 1 : 0,
        '_html preserves the Perl UTF-8 flag on large dense text' );
}
{
    my $shared_escape_calls = 0;
    no warnings qw(redefine once);
    local $Developer::Dashboard::HtmlEscape::XS_LOADED = 1;
    local *Developer::Dashboard::HtmlEscape::_escape_html = sub {
        $shared_escape_calls++;
        return 'shared&amp;&lt;&gt;"';
    };
    my $dense_html = ( '<&>' x 32 ) . '"';
    is( $PD->can('_html')->($dense_html), 'shared&amp;&lt;&gt;&quot;',
        '_html keeps legacy quote escaping after shared body escaping' );
    is( $shared_escape_calls, 1, '_html delegates body metacharacters to the shared optimized escaper' );
}
{
    local $Developer::Dashboard::HtmlEscape::XS_LOADED = 1;
    no warnings qw(redefine once);
    local *Developer::Dashboard::HtmlEscape::_escape_html = sub {
        die "plain page text should bypass HTML escaping\n";
    };
    my $plain = 'ordinary page description ' x 5;
    is( $PD->can('_html')->($plain), $plain,
        '_html returns plain text without invoking the escaper' );
}
{
    local $Developer::Dashboard::HtmlEscape::XS_LOADED = 1;
    no warnings qw(redefine once);
    local *Developer::Dashboard::HtmlEscape::_escape_html = sub {
        die "sparse text should use the compatibility replacement path\n";
    };
    my $sparse = '<x> ' . ( 'ordinary text ' x 12 );
    is( $PD->can('_html')->($sparse), '&lt;x&gt; ' . ( 'ordinary text ' x 12 ),
        '_html uses the Perl path for long text with sparse early escapes' );
}
{
    local $Developer::Dashboard::HtmlEscape::XS_LOADED = 1;
    no warnings qw(redefine once);
    local *Developer::Dashboard::HtmlEscape::_escape_html = sub {
        die "short text should use the compatibility replacement path\n";
    };
    is( $PD->can('_html')->('short & text'), 'short &amp; text',
        '_html uses the Perl path for escaped text shorter than the XS threshold' );
}
{
    local $Developer::Dashboard::HtmlEscape::XS_LOADED = 1;
    my $reference_text = [];
    like( $PD->can('_html')->($reference_text), qr/^ARRAY\(/,
        '_html keeps references on the Perl stringification path instead of XS' );
}
{
    local $Developer::Dashboard::HtmlEscape::XS_LOADED = 0;
    my $reference_text = [];
    like( $PD->can('_html')->($reference_text), qr/^ARRAY\(/,
        '_html keeps reference stringification when the optional XS backend is unavailable' );
}

# ---------------------------------------------------------------------------
# DD-866: CODE-section ordering must be NUMERIC, not lexicographic. A page
# with >= 10 code blocks previously sorted "CODE10"/"CODE11" ahead of
# "CODE2".."CODE9" because the bare `sort` on line 93 compares strings.
# @LEGACY_KEYS already declares CODE0..CODE1000, so two- and three-digit
# section numbers are squarely in the module's own contract, not a
# hypothetical edge case.
# ---------------------------------------------------------------------------
{
    my $text = join "\n", map { ( "=== CODE$_ ===", "step $_" ) } 0 .. 11;
    my $page = $PD->from_instruction($text);
    my @ids  = map { $_->{id} } @{ $page->{meta}{codes} };
    is_deeply(
        \@ids,
        [ map { "CODE$_" } 0 .. 11 ],
        'CODE0..CODE11 resolve in true numeric order, not lexicographic (DD-866)'
    );
}

# Single-digit-only regression: CODE0..CODE9 must still come out in order
# when there is no multi-digit section to expose the lexicographic bug.
{
    my $text = join "\n", map { ( "=== CODE$_ ===", "step $_" ) } 0 .. 9;
    my $page = $PD->from_instruction($text);
    my @ids  = map { $_->{id} } @{ $page->{meta}{codes} };
    is_deeply(
        \@ids,
        [ map { "CODE$_" } 0 .. 9 ],
        'CODE0..CODE9 (single-digit only) still resolve in order (DD-866 regression check)'
    );
}

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
the C<HEAD> section parse/serialize/render paths, the per-section serialization
guards, the HTML renderer's runtime-chunk handling, the lightweight page-id
and display-mode accessors, the private stash, template, trim, and escape helpers, and
dense-versus-sparse native HTML escape dispatch.
It exists to hold the module at full branch and condition coverage without
weakening any behavior.

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

Example 3:

  my $id = $page->id;
  my $mode = $page->mode;

Read the identifier and display mode without constructing the complete
C<as_hash> result.

=cut
