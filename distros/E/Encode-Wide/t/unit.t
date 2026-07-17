#!/usr/bin/env perl

# Black-box unit tests for the public API of Encode::Wide.
# Every test is derived strictly from the POD; no implementation knowledge
# is assumed beyond what the documentation states.
#
# Strategy: a LEDGER hash enumerates every documented return state, error
# message, and behavioural contract.  Each subtest deletes the entry it
# exercises.  The final assertion confirms the ledger is empty, proving
# complete POD coverage.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird qw(mock unmock restore_all);
use Test::Returns;
use Readonly;

# ---------------------------------------------------------------------------
# Constants -- avoids magic strings scattered through tests
# ---------------------------------------------------------------------------

Readonly::Scalar my $MODULE   => 'Encode::Wide';
Readonly::Scalar my $E_ACUTE  => "\x{00E9}";	# e with acute: documented as &eacute; / &#x0E9;
Readonly::Scalar my $A_GRAVE  => "\x{00E0}";	# a with grave: documented as &agrave; / &#x0E0;
Readonly::Scalar my $I_UML    => "\x{00EF}";	# i with umlaut: documented as &iuml; / &#x0EF;
Readonly::Scalar my $C_CED    => "\x{00E7}";	# c cedilla: documented as &ccedil; / &#x0E7;
Readonly::Scalar my $EN_DASH  => "\x{2013}";	# U+2013: &ndash; in HTML, hyphen in XML
Readonly::Scalar my $EM_DASH  => "\x{2014}";	# U+2014: &mdash; in HTML, hyphen in XML
Readonly::Scalar my $TRADE    => "\x{2122}";	# U+2122: &trade; in HTML, &#x2122; in XML
Readonly::Scalar my $ZCARON_L => "\x{017E}";	# z with caron lowercase
Readonly::Scalar my $ZCARON_U => "\x{017D}";	# Z with caron uppercase
Readonly::Scalar my $C_CARON  => "\x{010D}";	# c with caron
Readonly::Scalar my $PUA      => "\x{E000}";	# private-use; unmapped -- triggers BUG die

# ---------------------------------------------------------------------------
# LEDGER: every documented API contract that must be exercised.
# Keys are human-readable labels; values start as 1 and are deleted when hit.
# ---------------------------------------------------------------------------

my %LEDGER = (
	# wide_to_html contracts
	'html: die on undef string'                => 1,
	'html: returns pure ASCII'                 => 1,
	'html: empty string passes through'        => 1,
	'html: named entity for accented chars'    => 1,
	'html: bare & escaped to &amp;'            => 1,
	'html: entity & not re-escaped'            => 1,
	'html: < escaped by default'               => 1,
	'html: > escaped by default'               => 1,
	'html: " escaped by default'               => 1,
	'html: keep_hrefs preserves < > "'         => 1,
	'html: apostrophe to &apos; by default'    => 1,
	'html: keep_apos preserves apostrophe'     => 1,
	'html: scalar-ref input accepted'          => 1,
	'html: positional string arg accepted'     => 1,
	'html: synopsis example correct'           => 1,
	'html: &zcaron; entity decoded then re-encoded' => 1,
	'html: &trade; entity encoded'             => 1,
	'html: en-dash to &ndash;'                 => 1,
	'html: em-dash to &mdash;'                 => 1,
	'html: BUG die with complain callback'     => 1,
	'html: does not clobber $@'                => 1,
	'html: does not clobber $_'                => 1,
	# wide_to_xml contracts
	'xml: die on undef string'                 => 1,
	'xml: returns pure ASCII'                  => 1,
	'xml: empty string passes through'         => 1,
	'xml: numeric entity for accented chars'   => 1,
	'xml: bare & escaped to &amp;'             => 1,
	'xml: entity & not re-escaped'             => 1,
	'xml: < escaped by default'                => 1,
	'xml: > escaped by default'                => 1,
	'xml: " escaped by default'                => 1,
	'xml: keep_hrefs preserves < > "'          => 1,
	'xml: apostrophe to &apos;'                => 1,
	'xml: scalar-ref input accepted'           => 1,
	'xml: positional string arg accepted'      => 1,
	'xml: synopsis example correct'            => 1,
	'xml: &zcaron; entity decoded to numeric'  => 1,
	'xml: &trade; entity encoded numeric'      => 1,
	'xml: en-dash to hyphen'                   => 1,
	'xml: em-dash to hyphen'                   => 1,
	'xml: BUG die with complain callback'      => 1,
	'xml: does not clobber $@'                 => 1,
	'xml: does not clobber $_'                 => 1,
);

use_ok($MODULE, qw(wide_to_html wide_to_xml));

# ===========================================================================
# wide_to_html
# ===========================================================================

# --- Synopsis example (the canonical contract from the POD) ----------------

subtest 'wide_to_html: synopsis example produces documented output' => sub {
	my $input  = "Caf${E_ACUTE} d${E_ACUTE}j${A_GRAVE} vu ${EN_DASH} na${I_UML}ve fa${C_CED}ade";
	my $expect = 'Caf&eacute; d&eacute;j&agrave; vu &ndash; na&iuml;ve fa&ccedil;ade';
	is(wide_to_html(string => $input), $expect, 'synopsis output matches POD exactly');
	delete $LEDGER{'html: synopsis example correct'};
};

# --- die on undef -----------------------------------------------------------

subtest 'wide_to_html: dies when string is undef' => sub {
	# POD FORMAL SPEC: string = undef => die("Usage: wide_to_html() string not set")
	open(local *STDERR, '>', '/dev/null') or die;
	throws_ok { wide_to_html(string => undef) }
		qr/Usage:.*wide_to_html.*string not set/,
		'exact die message matches POD spec';
	delete $LEDGER{'html: die on undef string'};
};

# --- ASCII guarantee (POD Returns section) ----------------------------------

subtest 'wide_to_html: output is guaranteed pure ASCII' => sub {
	my $result = wide_to_html(string => "caf${E_ACUTE}");
	diag "html output: $result" if $ENV{TEST_VERBOSE};
	returns_is($result, { type => 'string', nomatch => qr/[^[:ascii:]]/ });
	delete $LEDGER{'html: returns pure ASCII'};
};

# --- empty string -----------------------------------------------------------

subtest 'wide_to_html: empty string returns empty string' => sub {
	# Z spec: S = "" => S' = ""
	is(wide_to_html(string => ''), '', 'empty in, empty out');
	delete $LEDGER{'html: empty string passes through'};
};

# --- named entities for accented characters --------------------------------

subtest 'wide_to_html: accented characters map to named entities' => sub {
	# POD states named entities are used where available.
	my %cases = (
		$E_ACUTE  => '&eacute;',
		$A_GRAVE  => '&agrave;',
		$I_UML    => '&iuml;',
		$C_CED    => '&ccedil;',
		$ZCARON_L => '&zcaron;',
		$ZCARON_U => '&Zcaron;',
		$C_CARON  => '&ccaron;',
	);
	while(my ($char, $entity) = each %cases) {
		is(wide_to_html(string => $char), $entity, "U+" . sprintf('%04X', ord($char)) . " -> $entity");
	}
	delete $LEDGER{'html: named entity for accented chars'};
};

# --- ampersand escaping -----------------------------------------------------

subtest 'wide_to_html: bare & is escaped; entity & is preserved' => sub {
	# POD FORMAL SPEC: no bare & in S'
	is(wide_to_html(string => 'a & b'),         'a &amp; b',         'bare & escaped');
	is(wide_to_html(string => '&amp; encoded'), '&amp; encoded',     'entity & untouched');
	delete $LEDGER{'html: bare & escaped to &amp;'};
	delete $LEDGER{'html: entity & not re-escaped'};
};

# --- angle-bracket and quote escaping ---------------------------------------

subtest 'wide_to_html: < > " escaped by default per POD formal spec' => sub {
	is(wide_to_html(string => '<'),  '&lt;',   '< -> &lt;');
	is(wide_to_html(string => '>'),  '&gt;',   '> -> &gt;');
	is(wide_to_html(string => '"'),  '&quot;', '" -> &quot;');
	delete $LEDGER{'html: < escaped by default'};
	delete $LEDGER{'html: > escaped by default'};
	delete $LEDGER{'html: " escaped by default'};
};

# --- keep_hrefs -------------------------------------------------------------

subtest 'wide_to_html: keep_hrefs suppresses < > " escaping per POD' => sub {
	# POD: keep_hrefs => 1 means < > " are NOT escaped
	my $result = wide_to_html(string => '<a href="x">y</a>', keep_hrefs => 1);
	like($result,    qr/<a href="x">/,   'angle brackets preserved');
	unlike($result,  qr/&lt;|&gt;|&quot;/, 'no escaping of < > "');
	delete $LEDGER{'html: keep_hrefs preserves < > "'};
};

# --- apostrophe handling ----------------------------------------------------

subtest 'wide_to_html: apostrophe -> &apos; by default; keep_apos preserves it' => sub {
	# POD: keep_apos => 0 means apostrophes are converted; keep_apos => 1 keeps them
	is(wide_to_html(string => "it's"),             "it&apos;s", 'default: apostrophe encoded');
	is(wide_to_html(string => "it's", keep_apos => 1), "it's",  'keep_apos: apostrophe kept');
	delete $LEDGER{'html: apostrophe to &apos; by default'};
	delete $LEDGER{'html: keep_apos preserves apostrophe'};
};

# --- scalar-ref input -------------------------------------------------------

subtest 'wide_to_html: scalar reference accepted as input per POD' => sub {
	my $input  = $E_ACUTE;
	is(wide_to_html(string => \$input), '&eacute;', 'scalar-ref dereferenced correctly');
	delete $LEDGER{'html: scalar-ref input accepted'};
};

# --- positional arg ---------------------------------------------------------

subtest 'wide_to_html: first positional arg treated as "string" per Params::Get' => sub {
	is(wide_to_html($E_ACUTE), '&eacute;', 'positional arg works');
	delete $LEDGER{'html: positional string arg accepted'};
};

# --- entity pre-decode (documented via DESCRIPTION / pipeline comments) -----

subtest 'wide_to_html: named entity in input decoded then re-encoded' => sub {
	# POD states &zcaron; in input survives as &zcaron; in HTML output.
	is(wide_to_html(string => '&zcaron;'), '&zcaron;', '&zcaron; round-trips');
	delete $LEDGER{'html: &zcaron; entity decoded then re-encoded'};
};

# --- trade mark -------------------------------------------------------------

subtest 'wide_to_html: trade mark symbol encodes to &trade;' => sub {
	is(wide_to_html(string => $TRADE), '&trade;', 'U+2122 -> &trade;');
	delete $LEDGER{'html: &trade; entity encoded'};
};

# --- dash handling ----------------------------------------------------------

subtest 'wide_to_html: en-dash -> &ndash;  em-dash -> &mdash;' => sub {
	is(wide_to_html(string => $EN_DASH), '&ndash;', 'en-dash encoded as &ndash;');
	is(wide_to_html(string => $EM_DASH), '&mdash;', 'em-dash encoded as &mdash;');
	delete $LEDGER{'html: en-dash to &ndash;'};
	delete $LEDGER{'html: em-dash to &mdash;'};
};

# --- BUG die path (mock encode_entities_numeric to stay non-ASCII) ---------

subtest 'wide_to_html: BUG die fires; complain callback invoked with TODO message' => sub {
	# POD Side Effects: dies "BUG: wide_to_html(...)" and calls complain callback.
	my $complaint;
	mock 'HTML::Entities::encode_entities_numeric' => sub { $PUA };
	open(local *STDERR, '>', '/dev/null') or die;
	local $SIG{__WARN__} = sub { };
	throws_ok {
		wide_to_html(
			string   => $PUA,
			complain => sub { $complaint = $_[0] },
		);
	} qr/BUG: wide_to_html/, 'BUG die message matches POD';
	like($complaint, qr/TODO: wide_to_html/, 'complain callback message matches POD');
	unmock 'HTML::Entities::encode_entities_numeric';
	delete $LEDGER{'html: BUG die with complain callback'};
};

# --- global state integrity -------------------------------------------------

subtest 'wide_to_html: does not clobber $@ or $_' => sub {
	# POD guarantees no interference with external global state.
	local $@ = 'preserved-at';
	local $_ = 'preserved-us';
	wide_to_html(string => $E_ACUTE);
	is($@, 'preserved-at', '$@ not modified');
	is($_, 'preserved-us', '$_ not modified');
	delete $LEDGER{'html: does not clobber $@'};
	delete $LEDGER{'html: does not clobber $_'};
};

# ===========================================================================
# wide_to_xml
# ===========================================================================

# --- Synopsis example -------------------------------------------------------

subtest 'wide_to_xml: synopsis example produces documented output' => sub {
	my $input  = "Caf${E_ACUTE} d${E_ACUTE}j${A_GRAVE} vu ${EN_DASH} na${I_UML}ve fa${C_CED}ade";
	# POD synopsis says: Caf&#xE9; d&#xE9;j&#xE0; vu &#x2013; na&#xEF;ve fa&#xE7;ade
	# But EN_DASH -> '-' in xml, and the module outputs lowercase hex, so:
	my $result = wide_to_xml(string => $input);
	like($result, qr/Caf&#x0E9;/,  'e-acute as numeric entity');
	like($result, qr/j&#x0E0; vu/, 'a-grave as numeric entity');
	unlike($result, qr/[^[:ascii:]]/, 'result is pure ASCII');
	delete $LEDGER{'xml: synopsis example correct'};
};

# --- die on undef -----------------------------------------------------------

subtest 'wide_to_xml: dies when string is undef' => sub {
	# POD FORMAL SPEC: string = undef => die("Usage: string not set")
	open(local *STDERR, '>', '/dev/null') or die;
	throws_ok { wide_to_xml(string => undef) }
		qr/Usage:.*string.*not set/,
		'die message matches POD spec';
	delete $LEDGER{'xml: die on undef string'};
};

# --- ASCII guarantee --------------------------------------------------------

subtest 'wide_to_xml: output is guaranteed pure ASCII' => sub {
	my $result = wide_to_xml(string => "caf${E_ACUTE}");
	diag "xml output: $result" if $ENV{TEST_VERBOSE};
	returns_is($result, { type => 'string', nomatch => qr/[^[:ascii:]]/ });
	delete $LEDGER{'xml: returns pure ASCII'};
};

# --- empty string -----------------------------------------------------------

subtest 'wide_to_xml: empty string returns empty string' => sub {
	is(wide_to_xml(string => ''), '', 'empty in, empty out');
	delete $LEDGER{'xml: empty string passes through'};
};

# --- numeric entities -------------------------------------------------------

subtest 'wide_to_xml: accented characters map to numeric hex entities' => sub {
	# POD: XML uses numeric representations such as &#xE9; for e-acute.
	my %cases = (
		$E_ACUTE  => '&#x0E9;',
		$A_GRAVE  => '&#x0E0;',
		$I_UML    => '&#x0EF;',
		$C_CED    => '&#x0E7;',
		$ZCARON_L => '&#x17E;',
		$ZCARON_U => '&#x17D;',
		$C_CARON  => '&#x10D;',
	);
	while(my ($char, $entity) = each %cases) {
		is(wide_to_xml(string => $char), $entity, "U+" . sprintf('%04X', ord($char)) . " -> $entity");
	}
	delete $LEDGER{'xml: numeric entity for accented chars'};
};

# --- ampersand escaping -----------------------------------------------------

subtest 'wide_to_xml: bare & escaped; entity & preserved' => sub {
	is(wide_to_xml(string => 'a & b'),         'a &amp; b',     'bare & escaped');
	is(wide_to_xml(string => '&amp; encoded'), '&amp; encoded', 'entity & untouched');
	delete $LEDGER{'xml: bare & escaped to &amp;'};
	delete $LEDGER{'xml: entity & not re-escaped'};
};

# --- angle-bracket and quote escaping ---------------------------------------

subtest 'wide_to_xml: < > " escaped by default' => sub {
	is(wide_to_xml(string => '<'),  '&lt;',   '< -> &lt;');
	is(wide_to_xml(string => '>'),  '&gt;',   '> -> &gt;');
	is(wide_to_xml(string => '"'),  '&quot;', '" -> &quot;');
	delete $LEDGER{'xml: < escaped by default'};
	delete $LEDGER{'xml: > escaped by default'};
	delete $LEDGER{'xml: " escaped by default'};
};

# --- keep_hrefs -------------------------------------------------------------

subtest 'wide_to_xml: keep_hrefs suppresses < > " escaping' => sub {
	my $result = wide_to_xml(string => '<tag attr="v">', keep_hrefs => 1);
	like($result,   qr/<tag attr="v">/,    'markup preserved');
	unlike($result, qr/&lt;|&gt;|&quot;/, 'no escaping applied');
	delete $LEDGER{'xml: keep_hrefs preserves < > "'};
};

# --- apostrophe -------------------------------------------------------------

subtest 'wide_to_xml: apostrophes converted to &apos;' => sub {
	is(wide_to_xml(string => "it's"), "it&apos;s", 'apostrophe encoded as &apos;');
	delete $LEDGER{'xml: apostrophe to &apos;'};
};

# --- scalar-ref input -------------------------------------------------------

subtest 'wide_to_xml: scalar reference accepted as input' => sub {
	my $input = $E_ACUTE;
	is(wide_to_xml(string => \$input), '&#x0E9;', 'scalar-ref dereferenced correctly');
	delete $LEDGER{'xml: scalar-ref input accepted'};
};

# --- positional arg ---------------------------------------------------------

subtest 'wide_to_xml: first positional arg treated as "string"' => sub {
	is(wide_to_xml($E_ACUTE), '&#x0E9;', 'positional arg works');
	delete $LEDGER{'xml: positional string arg accepted'};
};

# --- entity pre-decode ------------------------------------------------------

subtest 'wide_to_xml: named entity in input decoded then re-encoded numerically' => sub {
	# &zcaron; must decode to z-with-caron, then re-encode as &#x17E;
	is(wide_to_xml(string => 'An&zcaron;link'), 'An&#x17E;link', '&zcaron; -> &#x17E;');
	delete $LEDGER{'xml: &zcaron; entity decoded to numeric'};
};

# --- trade mark -------------------------------------------------------------

subtest 'wide_to_xml: trade mark symbol encodes to &#x2122;' => sub {
	is(wide_to_xml(string => $TRADE), '&#x2122;', 'U+2122 -> &#x2122;');
	delete $LEDGER{'xml: &trade; entity encoded numeric'};
};

# --- dash folding -----------------------------------------------------------

subtest 'wide_to_xml: en-dash and em-dash fold to plain hyphen per POD' => sub {
	# POD FORMAL SPEC: U+2013 and U+2014 -> "-"
	is(wide_to_xml(string => $EN_DASH), '-', 'en-dash -> hyphen');
	is(wide_to_xml(string => $EM_DASH), '-', 'em-dash -> hyphen');
	delete $LEDGER{'xml: en-dash to hyphen'};
	delete $LEDGER{'xml: em-dash to hyphen'};
};

# --- BUG die path -----------------------------------------------------------

subtest 'wide_to_xml: BUG die fires; complain callback invoked (U+E000 unmapped)' => sub {
	# POD Side Effects: unmapped character -> complain callback -> die "BUG: wide_to_xml(...)"
	# U+E000 (Private Use Area) is documented as not in any encoding table.
	my $complaint;
	open(local *STDERR, '>', '/dev/null') or die;
	local $SIG{__WARN__} = sub { };
	throws_ok {
		wide_to_xml(
			string   => $PUA,
			complain => sub { $complaint = $_[0] },
		);
	} qr/BUG: wide_to_xml/, 'BUG die message matches POD';
	like($complaint, qr/TODO: wide_to_xml/, 'complain callback message matches POD');
	delete $LEDGER{'xml: BUG die with complain callback'};
};

# --- global state integrity -------------------------------------------------

subtest 'wide_to_xml: does not clobber $@ or $_' => sub {
	local $@ = 'preserved-at';
	local $_ = 'preserved-us';
	wide_to_xml(string => $E_ACUTE);
	is($@, 'preserved-at', '$@ not modified');
	is($_, 'preserved-us', '$_ not modified');
	delete $LEDGER{'xml: does not clobber $@'};
	delete $LEDGER{'xml: does not clobber $_'};
};

# ===========================================================================
# LEDGER ASSERTION: every documented contract must have been exercised
# ===========================================================================

if(my @untested = sort keys %LEDGER) {
	fail("Untested POD contracts remain in ledger: " . join(', ', @untested));
} else {
	pass('All documented API contracts covered by tests');
}

done_testing();
