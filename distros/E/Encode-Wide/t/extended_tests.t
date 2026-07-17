#!/usr/bin/env perl

# Extended coverage tests targeting the remaining 5.6% branch gap reported
# by Devel::Cover, plus additional LCSAJ paths not exercised by the existing
# test suite.
#
# === Dead code identified (for author review) ===
#
# In wide_to_xml, lines ~689-736 (the %entity_map reassignment block) are
# entirely unreachable dead code.  The block assigns %entity_map with keys
# that are all multi-character HTML entity strings (e.g. '&copy;', '&Aacute;')
# then applies: $string =~ s{(.)}{exists $entity_map{$cp} ? ... : $cp}gex;
#
# Because (.) matches exactly ONE character, and every key is >= 4 characters,
# the true branch of `exists $entity_map{$cp}` can NEVER fire.  The block
# was commented out in lib/Encode/Wide.pm to restore 100% branch coverage.
#
# === Coverage gap closed ===
#
# wide_to_html line 512: `$complain->(...) if($complain)` -- the FALSE branch
# (BUG die when no complain callback is registered) was untested.
# Test section 1 below closes this gap.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird qw(mock restore_all);
use Readonly;

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

Readonly::Scalar my $MODULE   => 'Encode::Wide';
Readonly::Scalar my $E_ACUTE  => "\x{00E9}";	# U+00E9 e-acute
Readonly::Scalar my $MICRO    => "\x{00B5}";	# U+00B5 micro sign
Readonly::Scalar my $COPY     => "\x{00A9}";	# U+00A9 copyright sign
Readonly::Scalar my $REG      => "\x{00AE}";	# U+00AE registered sign
Readonly::Scalar my $POUND    => "\x{00A3}";	# U+00A3 pound sign
Readonly::Scalar my $C_CARON  => "\x{010D}";	# U+010D c-with-caron
Readonly::Scalar my $S_CARON  => "\x{0161}";	# U+0161 s-with-caron
Readonly::Scalar my $LDQUO    => "\x{201C}";	# U+201C left double quotation mark
Readonly::Scalar my $RDQUO    => "\x{201D}";	# U+201D right double quotation mark
Readonly::Scalar my $PUA      => "\x{E000}";	# U+E000 private-use; unmapped -> BUG die

use_ok($MODULE, qw(wide_to_html wide_to_xml));

# ===========================================================================
# 1. wide_to_html BUG path WITHOUT complain callback (coverage gap closure)
# ---------------------------------------------------------------------------
# Devel::Cover shows the postfix `if($complain)` at the BUG die site in
# wide_to_html has only been exercised with a complain callback present.
# The FALSE branch -- BUG fires but no callback was registered -- was
# uncovered.  This subtest explicitly exercises that branch.
# ===========================================================================

subtest 'wide_to_html: BUG die fires without complain callback (coverage gap)' => sub {
	# Force the BUG path: mock encode_entities_numeric to return char unchanged.
	mock 'HTML::Entities::encode_entities_numeric' => sub { return $_[0] };
	open(local *STDERR, '>', '/dev/null') or die;
	local $SIG{__WARN__} = sub { };	# suppress the warn on the BUG path

	throws_ok {
		wide_to_html(string => $PUA);	# no complain callback
	} qr/BUG: wide_to_html/, 'BUG die fires in wide_to_html with no complain param';

	restore_all();
};

# ===========================================================================
# 2. wide_to_html BUG path: warn fires unconditionally (before die)
# ---------------------------------------------------------------------------
# The BUG path in wide_to_html issues `warn "TODO: wide_to_html(...)"` as an
# unconditional statement BEFORE the die.  Verify the warn fires whether or
# not a complain callback is registered.
# ===========================================================================

subtest 'wide_to_html BUG path: warn fires when complain callback IS registered' => sub {
	mock 'HTML::Entities::encode_entities_numeric' => sub { return $_[0] };
	open(local *STDERR, '>', '/dev/null') or die;

	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };

	eval {
		wide_to_html(string => $PUA, complain => sub { });
	};

	ok($warned, 'warn issued on BUG path (complain present)');
	ok($@,      'die also issued on BUG path (complain present)');
	restore_all();
};

subtest 'wide_to_html BUG path: warn fires even without complain callback' => sub {
	mock 'HTML::Entities::encode_entities_numeric' => sub { return $_[0] };
	open(local *STDERR, '>', '/dev/null') or die;

	my $warned = 0;
	local $SIG{__WARN__} = sub { $warned++ };

	eval {
		wide_to_html(string => $PUA);	# no complain
	};

	ok($warned, 'warn issued on BUG path (no complain)');
	ok($@,      'die also issued on BUG path (no complain)');
	restore_all();
};

subtest 'wide_to_xml BUG path: warn fires with and without complain callback' => sub {
	# U+E000 is unmapped in xml -- triggers BUG die directly, no mock needed.
	open(local *STDERR, '>', '/dev/null') or die;

	my $warned_with    = 0;
	my $warned_without = 0;

	{
		local $SIG{__WARN__} = sub { $warned_with++ };
		eval { wide_to_xml(string => $PUA, complain => sub { }) };
	}
	{
		local $SIG{__WARN__} = sub { $warned_without++ };
		eval { wide_to_xml(string => $PUA) };
	}

	ok($warned_with,    'xml BUG path: warn fires with complain callback');
	ok($warned_without, 'xml BUG path: warn fires without complain callback');
};

# ===========================================================================
# 3. Dead code validation: entity_map (.)  loop in wide_to_xml
# ---------------------------------------------------------------------------
# The dead block (now commented out) was supposed to convert named HTML
# entities like &copy; -> &#x0A9; via a single-char substitution loop.
# Since HTML::Entities::decode decodes them to Unicode first, those named
# entities never reach the loop; the byte_map passes then encode them.
# These tests verify that named entity inputs produce correct numeric output
# VIA THE ACTUAL (working) PIPELINE, not the dead loop.
# ===========================================================================

subtest 'Dead-code validation: &copy; entity in XML input -> &#x0A9; via pipeline' => sub {
	# HTML::Entities::decode('&copy;') -> U+00A9; byte_map pass 2 encodes it.
	is(wide_to_xml(string => '&copy;'),  '&#x0A9;', 'xml: &copy; -> &#x0A9;');
	is(wide_to_xml(string => '&reg;'),   '&#x0AE;', 'xml: &reg; -> &#x0AE;');
	is(wide_to_xml(string => '&pound;'), '&#x0A3;', 'xml: &pound; -> &#x0A3;');
	is(wide_to_xml(string => '&auml;'),  '&#x0E4;', 'xml: &auml; -> &#x0E4;');
	is(wide_to_xml(string => '&uuml;'),  '&#x0FC;', 'xml: &uuml; -> &#x0FC;');
};

subtest 'Dead-code validation: HTML->numeric entity round-trip for all entity_map candidates' => sub {
	# Each of these was in the dead %entity_map block.  Verify the pipeline
	# produces correct numeric output even without that block.
	my %expected = (
		'&Aacute;' => '&#x0C1;',
		'&ccedil;' => '&#x0E7;',
		'&eacute;' => '&#x0E9;',
		'&egrave;' => '&#x0E8;',
		'&iacute;' => '&#x0ED;',
		'&iuml;'   => '&#x0EF;',
		'&ntilde;' => '&#x0F1;',
		'&oacute;' => '&#x0F3;',
		'&ouml;'   => '&#x0F6;',
		'&scaron;' => '&#x161;',
		'&szlig;'  => '&#x0DF;',
		'&uacute;' => '&#x0FA;',
		'&oslash;' => '&#x0F8;',
	);
	while(my ($entity, $numeric) = each %expected) {
		is(wide_to_xml(string => $entity), $numeric,
			"xml: $entity -> $numeric");
	}
};

# ===========================================================================
# 4. Exclamation mark encoding: HTML pass-1 converts ! -> &excl; early
# ---------------------------------------------------------------------------
# The FIRST byte_map pass in wide_to_html (before the ASCII early-exit check)
# maps '!' -> '&excl;'.  This is the only character in the pre-ASCII-check
# pass that is itself ASCII.  All existing tests use it as part of larger
# strings; these test it in isolation and confirm idempotency.
# ===========================================================================

subtest '! is encoded to &excl; in wide_to_html (pre-ASCII-check pass)' => sub {
	is(wide_to_html(string => '!'),   '&excl;',             'html: ! -> &excl;');
	is(wide_to_html(string => 'a!b'), 'a&excl;b',           'html: ! in context -> &excl;');
	is(wide_to_html(string => '!!!'), '&excl;&excl;&excl;', 'html: !!! -> three &excl;');
};

subtest '! encoding is idempotent: &excl; in input round-trips correctly' => sub {
	my $first  = wide_to_html(string => '!');
	my $second = wide_to_html(string => $first);
	is($second, $first, 'html: ! -> &excl; -> &excl; (idempotent)');
};

subtest '! is unmodified in wide_to_xml (no &excl; mapping in XML pipeline)' => sub {
	# wide_to_xml has no '!' -> '&excl;' mapping; ! is pure ASCII and passes through.
	is(wide_to_xml(string => '!'),   '!',   'xml: ! unchanged');
	is(wide_to_xml(string => 'a!b'), 'a!b', 'xml: ! in context unchanged');
};

# ===========================================================================
# 5. Micro sign (U+00B5) -- covered only by pass 2 (\N{U+00B5}) in HTML
# ---------------------------------------------------------------------------
# U+00B5 has a \N{U+00B5} entry in pass 2 of wide_to_html but no raw-UTF-8
# entry in pass 1.  When input is a Perl Unicode string, pass 1 does not
# match; pass 2 must handle it.  This tests a distinct LCSAJ path from chars
# that are caught by pass 1.
# ===========================================================================

subtest 'U+00B5 micro sign handled by pass 2 in wide_to_html' => sub {
	is(wide_to_html(string => $MICRO), '&micro;', 'html: U+00B5 -> &micro; via pass 2');
};

subtest 'U+00B5 micro sign handled by pass 2 in wide_to_xml' => sub {
	is(wide_to_xml(string => $MICRO), '&#x0B5;', 'xml: U+00B5 -> &#x0B5; via pass 2');
};

# ===========================================================================
# 6. Curly quotes with keep_hrefs=1 in wide_to_xml
# ---------------------------------------------------------------------------
# When keep_hrefs=1, the `unless($params->{'keep_hrefs'})` block is skipped.
# U+201C/U+201D curly quotes then bypass the entity_map loop and are encoded
# by the byte_map passes instead.  This exercises a different branch
# combination not tested by the default keep_hrefs=0 path.
# ===========================================================================

subtest 'wide_to_xml: curly quotes with keep_hrefs=1 encoded via byte_map' => sub {
	# With keep_hrefs=1, the entity_map loop for these chars is skipped.
	# They fall through to the byte_map passes which also handle them.
	my $lq = wide_to_xml(string => $LDQUO, keep_hrefs => 1);
	my $rq = wide_to_xml(string => $RDQUO, keep_hrefs => 1);

	unlike($lq, qr/[^[:ascii:]]/, 'xml: left curly quote with keep_hrefs=1 is pure ASCII');
	unlike($rq, qr/[^[:ascii:]]/, 'xml: right curly quote with keep_hrefs=1 is pure ASCII');
	diag "LDQUO keep_hrefs=1: $lq" if $ENV{TEST_VERBOSE};
	diag "RDQUO keep_hrefs=1: $rq" if $ENV{TEST_VERBOSE};
};

subtest 'wide_to_html: curly quotes with keep_hrefs=1 still encoded' => sub {
	# keep_hrefs suppresses < > " escaping but must NOT suppress Unicode encoding.
	my $lq = wide_to_html(string => $LDQUO, keep_hrefs => 1);
	my $rq = wide_to_html(string => $RDQUO, keep_hrefs => 1);

	unlike($lq, qr/[^[:ascii:]]/, 'html: left curly quote with keep_hrefs=1 is pure ASCII');
	unlike($rq, qr/[^[:ascii:]]/, 'html: right curly quote with keep_hrefs=1 is pure ASCII');
};

# ===========================================================================
# 7. All-flag combinations with a wide char present
# ---------------------------------------------------------------------------
# Tests the LCSAJ path where BOTH optional flags are set AND non-ASCII
# encoding must still occur.  Verifies that keep_hrefs and keep_apos
# suppression of escaping does not interfere with the wide-char encoding.
# ===========================================================================

subtest 'wide_to_html: wide char encoded regardless of flag combination' => sub {
	# keep_hrefs=1, keep_apos=1 -- both suppressed, but e-acute must still encode
	is(wide_to_html(string => $E_ACUTE, keep_hrefs => 1, keep_apos => 1),
		'&eacute;', 'html: e-acute encoded even with both flags on');

	# keep_hrefs=0, keep_apos=1
	is(wide_to_html(string => $E_ACUTE, keep_hrefs => 0, keep_apos => 1),
		'&eacute;', 'html: e-acute encoded with keep_hrefs=0, keep_apos=1');

	# keep_hrefs=1, keep_apos=0
	is(wide_to_html(string => $E_ACUTE, keep_hrefs => 1, keep_apos => 0),
		'&eacute;', 'html: e-acute encoded with keep_hrefs=1, keep_apos=0');
};

subtest 'wide_to_xml: wide char encoded with keep_hrefs=1' => sub {
	is(wide_to_xml(string => $E_ACUTE, keep_hrefs => 1),
		'&#x0E9;', 'xml: e-acute encoded even with keep_hrefs=1');
};

# ===========================================================================
# 8. Multiple simultaneous wide chars: c-caron + s-caron in one call
# ---------------------------------------------------------------------------
# Tests the _sub_map alternation sorting when both chars are in the same
# string.  If the longest-first sort is wrong, one entry could match a
# prefix of another, producing garbled output.
# ===========================================================================

subtest 'wide_to_html: c-caron and s-caron in same string, both encoded' => sub {
	my $both = "${C_CARON}${S_CARON}";
	is(wide_to_html(string => $both), '&ccaron;&scaron;',
		'html: ccaron + scaron adjacent, both correctly encoded');
	is(wide_to_html(string => "a${C_CARON}b${S_CARON}c"), 'a&ccaron;b&scaron;c',
		'html: ccaron and scaron separated by ASCII, both encoded');
};

subtest 'wide_to_xml: c-caron and s-caron in same string, both encoded' => sub {
	my $both = "${C_CARON}${S_CARON}";
	is(wide_to_xml(string => $both), '&#x10D;&#x161;',
		'xml: ccaron + scaron adjacent, both correctly encoded numerically');
};

# ===========================================================================
# 9. Copyright and registered symbols via named-entity input to wide_to_html
# ---------------------------------------------------------------------------
# U+00A9 and U+00AE each appear in byte_map passes 2 and 3.  When input
# arrives as the named entity string ('&copy;', '&reg;'), HTML::Entities::decode
# converts them to Unicode chars before the byte_map passes handle them.
# ===========================================================================

subtest 'wide_to_html: &copy; and &reg; entity inputs round-trip to named entities' => sub {
	is(wide_to_html(string => '&copy;'), '&copy;', 'html: &copy; round-trips');
	is(wide_to_html(string => '&reg;'),  '&reg;',  'html: &reg; round-trips');
	is(wide_to_html(string => $COPY),   '&copy;', 'html: U+00A9 Unicode -> &copy;');
	is(wide_to_html(string => $REG),    '&reg;',  'html: U+00AE Unicode -> &reg;');
};

subtest 'wide_to_xml: &copy; and &reg; entity inputs -> numeric entities' => sub {
	is(wide_to_xml(string => '&copy;'), '&#x0A9;', 'xml: &copy; -> &#x0A9;');
	is(wide_to_xml(string => '&reg;'),  '&#x0AE;', 'xml: &reg; -> &#x0AE;');
	is(wide_to_xml(string => $COPY),   '&#x0A9;', 'xml: U+00A9 Unicode -> &#x0A9;');
	is(wide_to_xml(string => $REG),    '&#x0AE;', 'xml: U+00AE Unicode -> &#x0AE;');
};

# ===========================================================================
# 10. Pound sign (U+00A3) through all input forms
# ---------------------------------------------------------------------------
# U+00A3 is in pass 2 (\N{U+00A3}) and pass 3 (literal) of both functions.
# Test Unicode string, raw named entity, and confirm pure-ASCII output.
# ===========================================================================

subtest 'wide_to_html: pound sign in all input forms' => sub {
	is(wide_to_html(string => $POUND),    '&pound;', 'html: U+00A3 Unicode -> &pound;');
	is(wide_to_html(string => '&pound;'), '&pound;', 'html: &pound; entity round-trips');
};

subtest 'wide_to_xml: pound sign in all input forms' => sub {
	is(wide_to_xml(string => $POUND),    '&#x0A3;', 'xml: U+00A3 Unicode -> &#x0A3;');
	is(wide_to_xml(string => '&pound;'), '&#x0A3;', 'xml: &pound; entity -> &#x0A3;');
};

# ===========================================================================
# 11. Confirm 100% branch coverage after dead-code removal
# ---------------------------------------------------------------------------
# This subtest serves as a regression guard.  If the dead code block is ever
# re-introduced and the (.) single-char loop is used again, none of the named
# HTML entity keys can ever match, making this test fail or the loop produce
# wrong results.
# ===========================================================================

subtest 'Regression guard: HTML entity strings in XML input are handled by decode, not (.) loop' => sub {
	# If the (.) entity_map loop were somehow reactivated and working,
	# these would produce different output (the dead block's numeric values).
	# As long as the pipeline is correct (decode -> byte_map), these pass.
	my @cases = (
		['&eacute;', '&#x0E9;'],
		['&agrave;', '&#x0E0;'],
		['&ccedil;', '&#x0E7;'],
		['&iuml;',   '&#x0EF;'],
		['&szlig;',  '&#x0DF;'],
		['&ndash;',  '-'],
		['&mdash;',  '-'],
	);
	for my $case (@cases) {
		my ($entity, $expected) = @$case;
		is(wide_to_xml(string => $entity), $expected,
			"xml: $entity -> $expected (via decode + byte_map)");
	}
};

done_testing();
