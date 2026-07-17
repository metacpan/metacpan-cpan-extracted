#!/usr/bin/env perl

# White-box function tests for Encode::Wide.
# Tests each public function and the internal _sub_map helper in isolation,
# exercising both the happy path and every documented failure mode.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird qw(mock unmock spy restore_all);
use Test::Returns;
use Test::Memory::Cycle;
use Readonly;

Readonly::Scalar my $MODULE => 'Encode::Wide';

# Characters used across subtests -- kept as constants to make intent clear
Readonly::Scalar my $E_ACUTE    => "\x{00E9}";	# e with acute accent
Readonly::Scalar my $TRADE_MARK => "\x{2122}";	# trade mark symbol
Readonly::Scalar my $EM_DASH    => "\x{2014}";	# em dash
Readonly::Scalar my $EN_DASH    => "\x{2013}";	# en dash
Readonly::Scalar my $PUA_CHAR   => "\x{E000}";	# private-use-area; no entry in any map

use_ok($MODULE, qw(wide_to_html wide_to_xml));

# ---------------------------------------------------------------------------
# _sub_map -- internal helper
# Accessed by full package path since it is not exported.
# ---------------------------------------------------------------------------

subtest '_sub_map: longest match wins over a shorter overlapping pattern' => sub {
	# If both 'ab' and 'a' are present the three-char alternation must prefer
	# the longer key so that 'abc' maps to 'Yc', not 'Xbc'.
	my @map = ( ['a', 'X'], ['ab', 'Y'] );
	my $result = Encode::Wide::_sub_map(\'abc', \@map);
	is($result, 'Yc', 'longest key takes priority');
};

subtest '_sub_map: multiple non-overlapping substitutions applied in one pass' => sub {
	my @map = ( ['a', '1'], ['b', '2'], ['c', '3'] );
	my $result = Encode::Wide::_sub_map(\'abc', \@map);
	is($result, '123', 'all three substitutions applied');
};

subtest '_sub_map: input string passed by reference is not modified' => sub {
	# _sub_map reads via scalar-ref and returns a fresh copy; the caller's
	# variable must remain unchanged.
	my $original = 'hello';
	Encode::Wide::_sub_map(\$original, [ ['hello', 'world'] ]);
	is($original, 'hello', 'original variable untouched');
};

subtest '_sub_map: no match leaves string unchanged' => sub {
	my @map = ( ['xyz', 'REPLACED'] );
	my $result = Encode::Wide::_sub_map(\'hello', \@map);
	is($result, 'hello', 'unmatched string passes through');
};

subtest '_sub_map: does not clobber $_ in the calling scope' => sub {
	# map/sort/grep inside _sub_map localize $_ automatically, but we verify
	# that the overall call does not bleed into the caller's $_.
	local $_ = 'sentinel';
	Encode::Wide::_sub_map(\'foo', [ ['foo', 'bar'] ]);
	is($_, 'sentinel', '$_ unchanged in caller after _sub_map');
};

subtest '_sub_map: spy confirms it returns a scalar string' => sub {
	my $spy = spy 'Encode::Wide::_sub_map';
	my $result = Encode::Wide::_sub_map(\'test', [ ['t', 'T'] ]);
	is($result, 'TesT', 'substitution still applied through spy');
	my @calls = $spy->();
	is(scalar @calls, 1, '_sub_map invoked exactly once');
	restore_all();
};

# ---------------------------------------------------------------------------
# wide_to_html -- exception paths
# ---------------------------------------------------------------------------

subtest 'wide_to_html: dies with correct message when string arg is absent' => sub {
	# Params::Get may throw its own "Usage:...string" error before the module's
	# own die fires; both are valid -- we just confirm a Usage error about "string".
	throws_ok { wide_to_html() }
		qr/Usage:.*string/,
		'missing string produces expected error';
};

subtest 'wide_to_html: dies when string is explicitly undef' => sub {
	throws_ok { wide_to_html(string => undef) }
		qr/Usage: wide_to_html\(\) string not set/,
		'undef string produces expected error';
};

# ---------------------------------------------------------------------------
# wide_to_html -- input forms
# ---------------------------------------------------------------------------

subtest 'wide_to_html: accepts a plain scalar reference as input' => sub {
	my $input = $E_ACUTE;
	my $result = wide_to_html(string => \$input);
	is($result, '&eacute;', 'scalar-ref input is dereferenced and encoded');
};

subtest 'wide_to_html: accepts positional (non-named) string argument' => sub {
	# Params::Get maps a single positional arg to the "string" parameter.
	my $result = wide_to_html("caf${E_ACUTE}");
	is($result, 'caf&eacute;', 'positional arg treated as string parameter');
};

# ---------------------------------------------------------------------------
# wide_to_html -- ASCII early-exit path
# ---------------------------------------------------------------------------

subtest 'wide_to_html: pure ASCII text triggers early return unchanged' => sub {
	# After the first byte_map pass (which only touches typographic chars and !)
	# a string with none of those chars is still ASCII and should short-circuit.
	my $result = wide_to_html(string => 'Hello world');
	is($result, 'Hello world', 'ASCII-only string passes through untouched');
	returns_is($result, { type => 'string', nomatch => qr/[^[:ascii:]]/ });
};

subtest 'wide_to_html: _sub_map called once on ASCII input (early-return path)' => sub {
	# Spying lets us confirm the pipeline short-circuits after the first
	# byte_map pass; the second and third passes should never be reached.
	my $spy = spy 'Encode::Wide::_sub_map';
	wide_to_html(string => 'hello');
	my @calls = $spy->();
	is(scalar @calls, 1, '_sub_map called exactly once for ASCII early-return');
	restore_all();
};

subtest 'wide_to_html: _sub_map called three times for non-ASCII input' => sub {
	my $spy = spy 'Encode::Wide::_sub_map';
	wide_to_html(string => $E_ACUTE);
	my @calls = $spy->();
	is(scalar @calls, 3, '_sub_map called three times when early-return does not fire');
	restore_all();
};

# ---------------------------------------------------------------------------
# wide_to_html -- ampersand escaping
# ---------------------------------------------------------------------------

subtest 'wide_to_html: bare & is escaped to &amp;' => sub {
	my $result = wide_to_html(string => 'foo & bar');
	is($result, 'foo &amp; bar', 'bare ampersand escaped');
};

subtest 'wide_to_html: & that is part of a valid entity is left alone' => sub {
	# The lookahead in the escaping regex must preserve already-encoded entities.
	my $result = wide_to_html(string => '&amp; already encoded');
	is($result, '&amp; already encoded', 'entity ampersand not double-escaped');
};

# ---------------------------------------------------------------------------
# wide_to_html -- angle-bracket and quote escaping
# ---------------------------------------------------------------------------

subtest 'wide_to_html: < > and " are escaped by default' => sub {
	my $result = wide_to_html(string => '<b>"x"</b>');
	is($result, '&lt;b&gt;&quot;x&quot;&lt;/b&gt;', 'markup chars escaped');
};

subtest 'wide_to_html: keep_hrefs suppresses < > " escaping' => sub {
	my $result = wide_to_html(string => '<a href="x">y</a>', keep_hrefs => 1);
	# The ! in 'y' is unaffected; there is no ! here, so we just check hrefs.
	is($result, '<a href="x">y</a>', 'angle brackets and quotes preserved');
};

# ---------------------------------------------------------------------------
# wide_to_html -- apostrophe handling
# ---------------------------------------------------------------------------

subtest 'wide_to_html: apostrophe converted to &apos; by default' => sub {
	my $result = wide_to_html(string => "it's");
	is($result, "it&apos;s", 'ASCII apostrophe encoded');
};

subtest 'wide_to_html: keep_apos suppresses apostrophe conversion' => sub {
	my $result = wide_to_html(string => "it's", keep_apos => 1);
	is($result, "it's", 'apostrophe left alone when keep_apos is set');
};

# ---------------------------------------------------------------------------
# wide_to_html -- entity_map pre-decode (the bug-fix regression)
# These entities are NOT decoded by HTML::Entities::decode, so the module
# must handle them manually via the $entity_re alternation.
# ---------------------------------------------------------------------------

subtest 'wide_to_html: &zcaron; in input round-trips to &zcaron; in output' => sub {
	my $result = wide_to_html(string => '&zcaron;');
	is($result, '&zcaron;', '&zcaron; decoded to character then re-encoded as named entity');
};

subtest 'wide_to_html: &Zcaron; in input round-trips to &Zcaron; in output' => sub {
	my $result = wide_to_html(string => '&Zcaron;');
	is($result, '&Zcaron;', '&Zcaron; decoded then re-encoded');
};

subtest 'wide_to_html: &ccaron; in input round-trips to &ccaron; in output' => sub {
	my $result = wide_to_html(string => '&ccaron;');
	is($result, '&ccaron;', '&ccaron; decoded then re-encoded');
};

subtest 'wide_to_html: &Scaron; in input round-trips to &Scaron; in output' => sub {
	my $result = wide_to_html(string => '&Scaron;');
	is($result, '&Scaron;', '&Scaron; decoded then re-encoded');
};

# ---------------------------------------------------------------------------
# wide_to_html -- named entity encoding for key characters
# ---------------------------------------------------------------------------

subtest 'wide_to_html: U+00E9 encodes to &eacute;' => sub {
	is(wide_to_html(string => $E_ACUTE), '&eacute;', 'e-acute encoded as named entity');
};

subtest 'wide_to_html: U+2122 trade mark encodes to &trade;' => sub {
	is(wide_to_html(string => $TRADE_MARK), '&trade;', 'trade mark encodes to &trade;');
};

subtest 'wide_to_html: exclamation mark encodes to &excl; (first-pass, before ASCII check)' => sub {
	# ! is ASCII but is deliberately encoded early so it survives the pipeline.
	is(wide_to_html(string => '!'), '&excl;', 'exclamation converted to &excl;');
};

subtest 'wide_to_html: U+2014 em-dash encodes to &mdash;' => sub {
	is(wide_to_html(string => $EM_DASH), '&mdash;', 'em-dash encoded');
};

subtest 'wide_to_html: U+2013 en-dash encodes to &ndash;' => sub {
	is(wide_to_html(string => $EN_DASH), '&ndash;', 'en-dash encoded');
};

# ---------------------------------------------------------------------------
# wide_to_html -- BUG die path (requires mocking encode_entities_numeric)
# The BUG die can only be reached if encode_entities_numeric fails to produce
# pure ASCII -- an impossible condition in production, so we mock it.
# ---------------------------------------------------------------------------

subtest 'wide_to_html: BUG die fires and complain callback is invoked when encode_entities_numeric returns non-ASCII' => sub {
	my $complaint;
	mock 'HTML::Entities::encode_entities_numeric' => sub { return $PUA_CHAR };

	# Suppress the STDERR noise the BUG path emits unconditionally.
	open(local *STDERR, '>', '/dev/null') or die "Cannot redirect STDERR: $!";
	local $SIG{__WARN__} = sub { };

	throws_ok {
		wide_to_html(
			string   => $PUA_CHAR,
			complain => sub { $complaint = $_[0] },
		);
	} qr/BUG: wide_to_html/, 'dies with BUG prefix in message';

	like($complaint, qr/TODO: wide_to_html/, 'complain callback received TODO message');

	unmock 'HTML::Entities::encode_entities_numeric';
};

# ---------------------------------------------------------------------------
# wide_to_html -- return-value invariants
# ---------------------------------------------------------------------------

subtest 'wide_to_html: output is always pure ASCII' => sub {
	my $result = wide_to_html(string => "caf${E_ACUTE}");
	diag "wide_to_html output: $result" if $ENV{TEST_VERBOSE};
	returns_is($result, { type => 'string', min => 1, nomatch => qr/[^[:ascii:]]/ });
};

subtest 'wide_to_html: return value contains no memory cycles' => sub {
	my $result = wide_to_html(string => $E_ACUTE);
	memory_cycle_ok(\$result, 'no cycle in scalar return value');
};

# ---------------------------------------------------------------------------
# wide_to_xml -- exception paths
# ---------------------------------------------------------------------------

subtest 'wide_to_xml: dies with correct message when string arg is absent' => sub {
	# Params::Get may throw its own "Usage:...string" error before the module's
	# own die fires; both are valid -- we just confirm a Usage error about "string".
	throws_ok { wide_to_xml() }
		qr/Usage:.*string/,
		'missing string produces expected error';
};

subtest 'wide_to_xml: dies when string is explicitly undef' => sub {
	throws_ok { wide_to_xml(string => undef) }
		qr/Usage: wide_to_xml\(\) string not set/,
		'undef string produces expected error';
};

# ---------------------------------------------------------------------------
# wide_to_xml -- input forms
# ---------------------------------------------------------------------------

subtest 'wide_to_xml: accepts a plain scalar reference as input' => sub {
	my $input = $E_ACUTE;
	my $result = wide_to_xml(string => \$input);
	is($result, '&#x0E9;', 'scalar-ref input is dereferenced and encoded');
};

subtest 'wide_to_xml: accepts positional (non-named) string argument' => sub {
	my $result = wide_to_xml("caf${E_ACUTE}");
	is($result, 'caf&#x0E9;', 'positional arg treated as string parameter');
};

# ---------------------------------------------------------------------------
# wide_to_xml -- ASCII early-exit path
# ---------------------------------------------------------------------------

subtest 'wide_to_xml: pure ASCII text returns unchanged' => sub {
	my $result = wide_to_xml(string => 'Hello world');
	is($result, 'Hello world', 'ASCII-only string passes through untouched');
	returns_is($result, { type => 'string', nomatch => qr/[^[:ascii:]]/ });
};

# ---------------------------------------------------------------------------
# wide_to_xml -- ampersand escaping
# ---------------------------------------------------------------------------

subtest 'wide_to_xml: bare & is escaped to &amp;' => sub {
	my $result = wide_to_xml(string => 'foo & bar');
	is($result, 'foo &amp; bar', 'bare ampersand escaped');
};

subtest 'wide_to_xml: & that is part of a valid entity is left alone' => sub {
	my $result = wide_to_xml(string => '&amp; already encoded');
	is($result, '&amp; already encoded', 'entity ampersand not double-escaped');
};

# ---------------------------------------------------------------------------
# wide_to_xml -- angle-bracket and quote escaping
# ---------------------------------------------------------------------------

subtest 'wide_to_xml: < > and " are escaped by default' => sub {
	my $result = wide_to_xml(string => '<b>"x"</b>');
	is($result, '&lt;b&gt;&quot;x&quot;&lt;/b&gt;', 'markup chars escaped');
};

subtest 'wide_to_xml: keep_hrefs suppresses < > " escaping' => sub {
	my $result = wide_to_xml(string => '<a href="x">y</a>', keep_hrefs => 1);
	is($result, '<a href="x">y</a>', 'angle brackets and quotes preserved');
};

# ---------------------------------------------------------------------------
# wide_to_xml -- entity_map pre-decode (the bug-fix regression)
# Unlike HTML, XML uses numeric entities, so pre-decoded characters must be
# re-encoded as &#xNN; rather than round-tripping to their named form.
# ---------------------------------------------------------------------------

subtest 'wide_to_xml: &zcaron; in input decodes to numeric &#x17E;' => sub {
	my $result = wide_to_xml(string => 'An&zcaron;link');
	is($result, 'An&#x17E;link', '&zcaron; decoded then re-encoded as numeric entity');
};

subtest 'wide_to_xml: &Zcaron; in input decodes to numeric &#x17D;' => sub {
	my $result = wide_to_xml(string => '&Zcaron;');
	is($result, '&#x17D;', '&Zcaron; decoded then re-encoded');
};

subtest 'wide_to_xml: &ccaron; in input decodes to numeric &#x10D;' => sub {
	my $result = wide_to_xml(string => '&ccaron;');
	is($result, '&#x10D;', '&ccaron; decoded then re-encoded');
};

subtest 'wide_to_xml: &Scaron; in input decodes to numeric &#x160;' => sub {
	my $result = wide_to_xml(string => '&Scaron;');
	is($result, '&#x160;', '&Scaron; decoded then re-encoded');
};

# ---------------------------------------------------------------------------
# wide_to_xml -- numeric entity encoding for key characters
# ---------------------------------------------------------------------------

subtest 'wide_to_xml: U+00E9 encodes to &#x0E9;' => sub {
	is(wide_to_xml(string => $E_ACUTE), '&#x0E9;', 'e-acute encoded as hex entity');
};

subtest 'wide_to_xml: U+2122 trade mark encodes to &#x2122;' => sub {
	is(wide_to_xml(string => $TRADE_MARK), '&#x2122;', 'trade mark encoded as numeric entity');
};

subtest 'wide_to_xml: em-dash and en-dash become plain hyphens (not entities)' => sub {
	# XML convention in this module is to collapse dashes to a plain hyphen.
	my $result = wide_to_xml(string => "${EM_DASH} and ${EN_DASH}");
	is($result, '- and -', 'both dashes collapsed to hyphens');
};

subtest 'wide_to_xml: apostrophes converted to &apos;' => sub {
	my $result = wide_to_xml(string => "it's");
	is($result, "it&apos;s", 'apostrophe encoded as &apos;');
};

# ---------------------------------------------------------------------------
# wide_to_xml -- BUG die path
# Unlike wide_to_html, wide_to_xml has no fallback to encode_entities_numeric;
# any character that survives all three _sub_map passes causes an immediate die.
# U+E000 (Private Use Area) is not in any map, so it reliably reaches this path.
# ---------------------------------------------------------------------------

subtest 'wide_to_xml: BUG die fires and complain callback is invoked for unmapped character' => sub {
	my $complaint;

	open(local *STDERR, '>', '/dev/null') or die "Cannot redirect STDERR: $!";
	local $SIG{__WARN__} = sub { };

	throws_ok {
		wide_to_xml(
			string   => $PUA_CHAR,
			complain => sub { $complaint = $_[0] },
		);
	} qr/BUG: wide_to_xml/, 'dies with BUG prefix in message';

	like($complaint, qr/TODO: wide_to_xml/, 'complain callback received TODO message');
};

# ---------------------------------------------------------------------------
# wide_to_xml -- return-value invariants
# ---------------------------------------------------------------------------

subtest 'wide_to_xml: output is always pure ASCII' => sub {
	my $result = wide_to_xml(string => "caf${E_ACUTE}");
	diag "wide_to_xml output: $result" if $ENV{TEST_VERBOSE};
	returns_is($result, { type => 'string', min => 1, nomatch => qr/[^[:ascii:]]/ });
};

subtest 'wide_to_xml: return value contains no memory cycles' => sub {
	my $result = wide_to_xml(string => $E_ACUTE);
	memory_cycle_ok(\$result, 'no cycle in scalar return value');
};

done_testing();
