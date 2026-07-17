#!/usr/bin/env perl

# Destructive, boundary, and security edge-case tests for Encode::Wide.
#
# Strategy: feed hostile, malformed, or pathological inputs to every code
# path and verify the module either handles them gracefully (no crash, no
# state corruption, pure-ASCII output) or dies with a clearly documented
# error.  All tests assert INTENDED behaviour per the POD, not accidental
# behaviour.  Coverage already in edge.t / unit.t / integration.t is not
# repeated here.

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
Readonly::Scalar my $A_GRAVE  => "\x{00E0}";	# U+00A0 a-grave
Readonly::Scalar my $NBSP     => "\x{00A0}";	# U+00A0 non-breaking space
Readonly::Scalar my $BOM      => "\x{FEFF}";	# U+FEFF byte-order mark
Readonly::Scalar my $ELLIPSIS => "\x{2026}";	# U+2026 horizontal ellipsis
Readonly::Scalar my $BULLET   => "\x{25CF}";	# U+25CF black circle
Readonly::Scalar my $LSQUO    => "\x{2018}";	# U+2018 left single quotation mark
Readonly::Scalar my $RSQUO    => "\x{2019}";	# U+2019 right single quotation mark
Readonly::Scalar my $LDQUO    => "\x{201C}";	# U+201C left double quotation mark
Readonly::Scalar my $RDQUO    => "\x{201D}";	# U+201D right double quotation mark
Readonly::Scalar my $PUA      => "\x{E000}";	# U+E000 private-use (unmapped -> BUG die)
Readonly::Scalar my $LARGE_N  => 10_000;	# repeat count for stress tests

use_ok($MODULE, qw(wide_to_html wide_to_xml));

# ===========================================================================
# 1. Numerically-false but defined scalars
# ---------------------------------------------------------------------------
# The POD says string must be *defined*.  "0" and integer 0 are defined and
# must pass through without dying, returning pure ASCII.
# ===========================================================================

subtest 'Numerically false string "0" is not treated as undef' => sub {
	# If the module checked `if(!$string)` rather than `if(!defined($string))`
	# it would incorrectly die for "0".
	lives_ok { wide_to_html(string => '0') } 'html: string "0" does not die';
	lives_ok { wide_to_xml(string  => '0') } 'xml:  string "0" does not die';
	is(wide_to_html(string => '0'), '0', 'html: string "0" returns "0"');
	is(wide_to_xml(string  => '0'), '0', 'xml:  string "0" returns "0"');
};

subtest 'Integer 0 as string argument is not treated as undef' => sub {
	lives_ok { wide_to_html(string => 0) } 'html: integer 0 does not die';
	lives_ok { wide_to_xml(string  => 0) } 'xml:  integer 0 does not die';
	is(wide_to_html(string => 0), '0', 'html: integer 0 returns "0"');
	is(wide_to_xml(string  => 0), '0', 'xml:  integer 0 returns "0"');
};

subtest 'Single-space string is not treated as undef' => sub {
	is(wide_to_html(string => ' '), ' ', 'html: space string returns " "');
	is(wide_to_xml(string  => ' '), ' ', 'xml:  space string returns " "');
};

# ===========================================================================
# 2. NUL and DEL characters (ASCII boundary codepoints)
# ---------------------------------------------------------------------------
# U+0000 (NUL) and U+007F (DEL) are ASCII.  They are not wide characters,
# so neither pipeline should alter them.
# ===========================================================================

subtest 'NUL byte (U+0000) passes through unchanged' => sub {
	my $nul = "\x{0000}";
	is(wide_to_html(string => $nul),         $nul,       'html: bare NUL unchanged');
	is(wide_to_xml(string  => $nul),         $nul,       'xml:  bare NUL unchanged');
	is(wide_to_html(string => "a${nul}b"),   "a${nul}b", 'html: NUL in middle unchanged');
	is(wide_to_xml(string  => "a${nul}b"),   "a${nul}b", 'xml:  NUL in middle unchanged');
};

subtest 'DEL character (U+007F) passes through unchanged' => sub {
	my $del = "\x{007F}";
	is(wide_to_html(string => $del), $del, 'html: DEL unchanged');
	is(wide_to_xml(string  => $del), $del, 'xml:  DEL unchanged');
};

# ===========================================================================
# 3. Byte-Order Mark (U+FEFF)
# ---------------------------------------------------------------------------
# BOM is non-ASCII and not in any known byte_map entry.  It should reach the
# HTML::Entities::encode_entities_numeric fallback and become a numeric entity.
# At minimum the output must be pure ASCII.
# ===========================================================================

subtest 'BOM (U+FEFF) is handled per documented pipeline behaviour' => sub {
	# HTML: encode_entities_numeric covers U+FEFF -> numeric entity -> pure ASCII.
	my $html_bom;
	open(local *STDERR, '>', '/dev/null') or die;
	local $SIG{__WARN__} = sub { };
	lives_ok { $html_bom = wide_to_html(string => $BOM) } 'html: BOM does not die';
	unlike($html_bom, qr/[^[:ascii:]]/, 'html: BOM result is pure ASCII');
	diag "html BOM: $html_bom" if $ENV{TEST_VERBOSE};

	# XML: U+FEFF is not in any XML byte_map entry; the documented BUG path fires.
	open(local *STDERR, '>', '/dev/null') or die;
	local $SIG{__WARN__} = sub { };
	throws_ok { wide_to_xml(string => $BOM) }
		qr/BUG: wide_to_xml/,
		'xml: BOM (unmapped in XML maps) triggers documented BUG die';
};

# ===========================================================================
# 4. Hostile reference types
# ---------------------------------------------------------------------------
# Passing ARRAYREF, HASHREF, or CODEREF as string is outside the POD contract.
# The module must not produce non-ASCII output, must not execute injected code,
# and must not hang or corrupt memory.  It may die.
# ===========================================================================

subtest 'ARRAYREF as string: terminates, no non-ASCII output' => sub {
	my $aref = [1, 2, 3];
	for my $fn (qw(wide_to_html wide_to_xml)) {
		no strict 'refs';
		my $result;
		eval { $result = $fn->(string => $aref) };
		if($@) {
			diag "$fn: arrayref caused die (acceptable): $@" if $ENV{TEST_VERBOSE};
			pass("$fn: arrayref input terminated (die acceptable)");
		} else {
			unlike($result, qr/[^[:ascii:]]/, "$fn: arrayref stringification is ASCII");
		}
	}
};

subtest 'HASHREF as string: terminates, no non-ASCII output' => sub {
	my $href = { key => 'val' };
	for my $fn (qw(wide_to_html wide_to_xml)) {
		no strict 'refs';
		my $result;
		eval { $result = $fn->(string => $href) };
		if($@) {
			pass("$fn: hashref input terminated (die acceptable)");
		} else {
			unlike($result, qr/[^[:ascii:]]/, "$fn: hashref stringification is ASCII");
		}
	}
};

subtest 'CODEREF as string: terminates, no non-ASCII output' => sub {
	my $cref = sub { 42 };
	for my $fn (qw(wide_to_html wide_to_xml)) {
		no strict 'refs';
		my $result;
		eval { $result = $fn->(string => $cref) };
		if($@) {
			pass("$fn: coderef input terminated (die acceptable)");
		} else {
			unlike($result, qr/[^[:ascii:]]/, "$fn: coderef stringification is ASCII");
		}
	}
};

# ===========================================================================
# 5. Circular scalar reference (must not infinite-loop)
# ---------------------------------------------------------------------------
# A scalar variable that references itself is hostile input that could cause
# an infinite deref loop in naive code.  The module must terminate within a
# reasonable time because it only follows one level of SCALARREF dereference.
# ===========================================================================

subtest 'Circular scalar ref terminates and does not hang' => sub {
	my $x;
	$x = \$x;	# ref($x) eq 'REF', so the SCALARREF branch is not taken

	local $SIG{ALRM} = sub { die "TIMEOUT\n" };
	alarm(5);
	eval { wide_to_html(string => $x) };
	alarm(0);
	ok(!($@ && $@ eq "TIMEOUT\n"), 'html: circular ref did not time out');

	alarm(5);
	eval { wide_to_xml(string => $x) };
	alarm(0);
	ok(!($@ && $@ eq "TIMEOUT\n"), 'xml: circular ref did not time out');
};

# ===========================================================================
# 6. Pathological ampersand sequences
# ---------------------------------------------------------------------------
# The lookahead regex `s/&(?![A-Za-z#0-9]+;)/&amp;/g` has several boundary
# conditions: consecutive bare &, trailing &, &; (empty name), and a very
# long fake entity name that could trigger backtracking.
# ===========================================================================

subtest 'Consecutive bare ampersands are each individually escaped' => sub {
	is(wide_to_html(string => '&&'),    '&amp;&amp;',             'html: && -> &amp;&amp;');
	is(wide_to_xml(string  => '&&'),    '&amp;&amp;',             'xml:  && -> &amp;&amp;');
	is(wide_to_html(string => '&&&'),   '&amp;&amp;&amp;',        'html: &&& triple escaped');
	is(wide_to_html(string => 'a&&b'),  'a&amp;&amp;b',           'html: && in context');
};

subtest 'Trailing bare & at end of string is escaped' => sub {
	is(wide_to_html(string => 'foo&'), 'foo&amp;', 'html: trailing & escaped');
	is(wide_to_xml(string  => 'foo&'), 'foo&amp;', 'xml:  trailing & escaped');
};

subtest '&; (bare & with empty entity name) is escaped' => sub {
	# '&;' does NOT match `[A-Za-z#0-9]+;` (empty name fails +), so & is escaped.
	my $html = wide_to_html(string => '&;');
	like($html, qr/&amp;;/, 'html: &; -> &amp;; (& escaped, ; left)');
};

subtest 'Very long fake entity name does not cause catastrophic backtracking' => sub {
	my $long_entity = '&' . ('a' x 1000) . ';';
	local $SIG{ALRM} = sub { die "TIMEOUT\n" };
	alarm(5);
	my $html = eval { wide_to_html(string => $long_entity) };
	alarm(0);
	ok(!($@ && $@ eq "TIMEOUT\n"), 'html: 1000-char entity name does not time out');
	unlike($html // '', qr/[^[:ascii:]]/, 'html: output is pure ASCII') unless $@;

	alarm(5);
	my $xml = eval { wide_to_xml(string => $long_entity) };
	alarm(0);
	ok(!($@ && $@ eq "TIMEOUT\n"), 'xml: 1000-char entity name does not time out');
};

subtest 'Bare & immediately adjacent to < is escaped correctly' => sub {
	is(wide_to_html(string => '&<'), '&amp;&lt;', 'html: &< both escaped');
	is(wide_to_xml(string  => '&<'), '&amp;&lt;', 'xml:  &< both escaped');
};

# ===========================================================================
# 7. Regex metacharacters in input
# ---------------------------------------------------------------------------
# _sub_map builds alternation patterns using quotemeta on each entry, so
# input metacharacters must be treated as literals, not as regex operators.
# A failure here would cause incorrect replacements or Perl regex errors.
# ===========================================================================

subtest 'Regex metacharacters in input are not interpreted as pattern operators' => sub {
	# '.*+?|[](){}\\^$' -- if quotemeta fails, the alternation pattern would break
	my $re_chars = '.*+?[](){}^$';
	my $html;
	lives_ok { $html = wide_to_html(string => $re_chars, keep_hrefs => 1) }
		'html: regex metacharacters in input do not cause die';
	unlike($html // '', qr/[^[:ascii:]]/, 'html: output is pure ASCII');

	my $xml;
	lives_ok { $xml = wide_to_xml(string => $re_chars, keep_hrefs => 1) }
		'xml: regex metacharacters in input do not cause die';
	unlike($xml // '', qr/[^[:ascii:]]/, 'xml: output is pure ASCII');
};

subtest 'Backslash in input is not interpreted as regex escape' => sub {
	my $back = 'a\\b';
	is(wide_to_html(string => $back), $back, 'html: backslash passes through unchanged');
	is(wide_to_xml(string  => $back), $back, 'xml:  backslash passes through unchanged');
};

subtest 'Alternation pipe | in input does not corrupt matching' => sub {
	is(wide_to_html(string => 'a|b'), 'a|b', 'html: pipe char unchanged');
	is(wide_to_xml(string  => 'a|b'), 'a|b', 'xml:  pipe char unchanged');
};

# ===========================================================================
# 8. List context (scalar expected)
# ---------------------------------------------------------------------------
# Both functions must return a single scalar.  In list context the caller
# might receive multiple elements if the function returns a list accidentally.
# ===========================================================================

subtest 'wide_to_html returns a single element in list context' => sub {
	my @result = wide_to_html(string => $E_ACUTE);
	is(scalar @result, 1,          'html: list context returns exactly one element');
	is($result[0],     '&eacute;', 'html: list context element is correct value');
};

subtest 'wide_to_xml returns a single element in list context' => sub {
	my @result = wide_to_xml(string => $E_ACUTE);
	is(scalar @result, 1,         'xml: list context returns exactly one element');
	is($result[0],     '&#x0E9;', 'xml: list context element is correct value');
};

# ===========================================================================
# 9. Global state integrity under hostile conditions
# ---------------------------------------------------------------------------
# Ensure $_, $@, $!, and SIGALRM are not corrupted when the byte_map passes
# are triggered (those passes run grep { $_ ... } which aliases $_ internally).
# ===========================================================================

subtest 'wide_to_html: $_ not clobbered when byte_map passes run' => sub {
	# Use a wide char to ensure the byte_map substitution passes fire.
	local $_ = 'canary_html';
	wide_to_html(string => $E_ACUTE);
	is($_, 'canary_html', '$_ is unchanged after byte_map-triggering wide_to_html call');
};

subtest 'wide_to_xml: $_ not clobbered when byte_map passes run' => sub {
	local $_ = 'canary_xml';
	wide_to_xml(string => $E_ACUTE);
	is($_, 'canary_xml', '$_ is unchanged after byte_map-triggering wide_to_xml call');
};

subtest 'wide_to_html: $@ not clobbered during normal encoding' => sub {
	local $@ = 'sentinel-html';
	wide_to_html(string => $E_ACUTE);
	is($@, 'sentinel-html', '$@ is unchanged after wide_to_html');
};

subtest 'wide_to_xml: $@ not clobbered during normal encoding' => sub {
	local $@ = 'sentinel-xml';
	wide_to_xml(string => $E_ACUTE);
	is($@, 'sentinel-xml', '$@ is unchanged after wide_to_xml');
};

subtest 'Neither function clears a pending alarm' => sub {
	# alarm() is not implemented on Windows; skip rather than fail.
	if($^O eq 'MSWin32') {
		plan skip_all => 'alarm() not supported on Windows';
		return;
	}
	# If either function accidentally calls alarm(0), remaining time drops to 0.
	local $SIG{ALRM} = sub { die "alarm-fired\n" };
	alarm(10);
	wide_to_html(string => $E_ACUTE);
	wide_to_xml(string  => $E_ACUTE);
	my $remaining = alarm(0);	# clear and read remaining seconds
	ok($remaining > 0, 'alarm remaining time > 0: neither function cleared it');
};

# ===========================================================================
# 10. Upstream mock failures (HTML::Entities::decode)
# ---------------------------------------------------------------------------
# Mock HTML::Entities::decode to return hostile values and verify the module
# either fails safely or recovers without producing non-ASCII output.
# ===========================================================================

subtest 'Mock: decode returns empty string -- both functions return empty' => sub {
	mock 'HTML::Entities::decode' => sub { return '' };
	is(wide_to_html(string => 'anything'), '', 'html: decode->empty yields empty output');
	restore_all();

	mock 'HTML::Entities::decode' => sub { return '' };
	is(wide_to_xml(string => 'anything'), '', 'xml: decode->empty yields empty output');
	restore_all();
};

subtest 'Mock: decode returns a wide char -- module still encodes to pure ASCII' => sub {
	# decode returning a Unicode char exercises the byte_map passes
	mock 'HTML::Entities::decode' => sub { return $E_ACUTE };
	my $html = wide_to_html(string => 'anything');
	unlike($html, qr/[^[:ascii:]]/, 'html: injected e-acute is encoded to ASCII');
	restore_all();

	mock 'HTML::Entities::decode' => sub { return $E_ACUTE };
	my $xml = wide_to_xml(string => 'anything');
	unlike($xml, qr/[^[:ascii:]]/, 'xml: injected e-acute is encoded to ASCII');
	restore_all();
};

subtest 'Mock: decode returns undef -- module dies without producing non-ASCII' => sub {
	# Returning undef causes the subsequent regex ops to operate on an undef string.
	# The module may die; it must not produce non-ASCII.
	mock 'HTML::Entities::decode' => sub { return undef };
	local $SIG{__WARN__} = sub { };	# suppress "uninitialized value" warnings
	my $result;
	eval { $result = wide_to_html(string => 'test') };
	if($@) {
		pass('html: decode->undef causes an acceptable die');
		diag "die message: $@" if $ENV{TEST_VERBOSE};
	} else {
		unlike($result // '', qr/[^[:ascii:]]/, 'html: decode->undef, result is ASCII');
	}
	restore_all();
};

# ===========================================================================
# 11. complain callback edge cases
# ---------------------------------------------------------------------------
# The 'complain' callback is called when a BUG is detected.  Verify what
# happens when the callback itself throws an exception, and when something
# other than a coderef is passed.
# ===========================================================================

subtest 'complain callback that throws: exception propagates, does not silently swallow' => sub {
	# Arrange: mock encode_entities_numeric to leave the char unencoded -> BUG path
	mock 'HTML::Entities::encode_entities_numeric' => sub { return $_[0] };
	open(local *STDERR, '>', '/dev/null') or die;
	local $SIG{__WARN__} = sub { };

	eval {
		wide_to_html(
			string   => $PUA,
			complain => sub { die "callback-exploded\n" },
		);
	};
	ok($@, 'exception from complain callback is not swallowed');
	restore_all();
};

subtest 'complain not provided: BUG die still fires for wide_to_xml' => sub {
	# No 'complain' param -- the die must still propagate (complain is optional).
	open(local *STDERR, '>', '/dev/null') or die;
	local $SIG{__WARN__} = sub { };
	throws_ok { wide_to_xml(string => $PUA) }
		qr/BUG: wide_to_xml/,
		'xml: BUG die fires even without complain callback';
};

# ===========================================================================
# 12. Security: XSS injection vectors
# ---------------------------------------------------------------------------
# Verify that the module neutralises the most common XSS payloads in its
# default (safe) mode.  With keep_hrefs=1, angle brackets survive by design
# (the caller accepted that trade-off); we confirm the default is safe.
# ===========================================================================

subtest 'Security: <script> tag is neutralised in default mode' => sub {
	my $xss  = '<script>alert(1)</script>';
	my $html = wide_to_html(string => $xss);
	my $xml  = wide_to_xml(string  => $xss);

	unlike($html, qr/<script>/i,        'html: <script> absent in output');
	like($html,   qr/&lt;script&gt;/i,  'html: script tag escaped as &lt;...&gt;');
	unlike($xml,  qr/<script>/i,        'xml: <script> absent in output');
	unlike($html, qr/[^[:ascii:]]/,     'html: XSS output is pure ASCII');
};

subtest 'Security: event-handler attribute injection is neutralised' => sub {
	# The tag and quotes are escaped; onerror= survives as text but " are &quot;
	# so the injected handler cannot be interpreted as markup by a browser.
	my $ev   = '<img src=x onerror="alert(1)">';
	my $html = wide_to_html(string => $ev);
	unlike($html, qr/<img/i,           'html: <img tag is escaped (no raw <)');
	like($html,   qr/onerror=&quot;/,  'html: onerror value delimiters are escaped');
	unlike($html, qr/[^[:ascii:]]/,    'html: output is pure ASCII');
};

subtest 'Security: HTML double-decode attack does not produce a raw <' => sub {
	# HTML::Entities::decode("&amp;lt;") -> "&lt;"  (one decode level)
	# Then the & in &lt; passes the lookahead ([A-Za-z#0-9]+; matches "lt;"),
	# so it is preserved as-is.  Output is "&lt;" which renders as the glyph <
	# but is NOT a markup tag -- safe.
	my $html = wide_to_html(string => '&amp;lt;');
	is($html, '&lt;', 'html: &amp;lt; decodes one level to the safe entity &lt;');
	unlike($html, qr/[^[:ascii:]]/, 'html: output is pure ASCII');
	# Crucially, a raw < character must not appear in the output.
	unlike($html, qr/(?<!&lt)</, 'html: no raw < in output');
};

subtest 'Security: &amp;lt;&amp;gt; combination does not yield <...>' => sub {
	my $html = wide_to_html(string => '&amp;lt;script&amp;gt;');
	unlike($html, qr/<script>/i, 'html: encoded script tag does not survive as markup');
};

# ===========================================================================
# 13. Numeric entity inputs (&#xNN; and &#NNN;)
# ---------------------------------------------------------------------------
# Numeric references in input must be decoded by HTML::Entities::decode and
# re-encoded in the appropriate style.  They must not be double-decoded.
# ===========================================================================

subtest 'Hex numeric entity &#xE9; in input is decoded then re-encoded' => sub {
	is(wide_to_html(string => '&#xE9;'),  '&eacute;', 'html: &#xE9; -> &eacute;');
	is(wide_to_xml(string  => '&#xE9;'),  '&#x0E9;',  'xml:  &#xE9; -> &#x0E9;');
};

subtest 'Decimal numeric entity &#233; in input is decoded then re-encoded' => sub {
	is(wide_to_html(string => '&#233;'),  '&eacute;', 'html: &#233; -> &eacute;');
	is(wide_to_xml(string  => '&#233;'),  '&#x0E9;',  'xml:  &#233; -> &#x0E9;');
};

subtest '&#xE9; does not get double-encoded on second pass' => sub {
	# First pass: &#xE9; -> decoded -> e-acute -> &eacute;
	# Second pass: &eacute; -> decoded -> e-acute -> &eacute; (idempotent)
	my $once  = wide_to_html(string => '&#xE9;');
	my $twice = wide_to_html(string => $once);
	is($twice, $once, 'html: &#xE9; is idempotent across two passes');
};

# ===========================================================================
# 14. Non-breaking space (U+00A0) -> regular space
# ---------------------------------------------------------------------------
# The byte_map maps U+00A0 (NBSP) to a plain ASCII space.  Verify this
# across different input representations and in surrounding context.
# ===========================================================================

subtest 'NBSP (U+00A0) converts to regular ASCII space' => sub {
	is(wide_to_html(string => $NBSP),           ' ',   'html: bare NBSP -> space');
	is(wide_to_xml(string  => $NBSP),           ' ',   'xml:  bare NBSP -> space');
	is(wide_to_html(string => "a${NBSP}b"),     'a b', 'html: NBSP in context -> space');
	is(wide_to_xml(string  => "a${NBSP}b"),     'a b', 'xml:  NBSP in context -> space');
	# named entity form
	is(wide_to_html(string => '&nbsp;'),        ' ',   'html: &nbsp; entity -> space');
	is(wide_to_xml(string  => '&nbsp;'),        ' ',   'xml:  &nbsp; entity -> space');
};

# ===========================================================================
# 15. Ellipsis (U+2026) converts to three ASCII dots
# ---------------------------------------------------------------------------
# The byte_map has ["\N{U+2026}", '...'] entries.  This tests both the
# Unicode codepoint form and the named entity form of the input.
# ===========================================================================

subtest 'Ellipsis (U+2026) encodes to "..." in both pipelines' => sub {
	is(wide_to_html(string => $ELLIPSIS), '...', 'html: U+2026 -> ...');
	is(wide_to_xml(string  => $ELLIPSIS), '...', 'xml:  U+2026 -> ...');
	# Named entity form in input
	is(wide_to_html(string => '&hellip;'), '...', 'html: &hellip; -> ...');
	is(wide_to_xml(string  => '&hellip;'), '...', 'xml:  &hellip; -> ...');
};

# ===========================================================================
# 16. Typographic curly quotes (U+2018/2019/201C/201D)
# ---------------------------------------------------------------------------
# These four characters appear in the byte_map mapped to &quot; or &apos;.
# Verify each one produces pure ASCII.
# ===========================================================================

subtest 'Typographic curly quotes produce pure-ASCII output' => sub {
	for my $char ($LSQUO, $RSQUO, $LDQUO, $RDQUO) {
		my $cp   = sprintf 'U+%04X', ord($char);
		my $html = wide_to_html(string => $char);
		my $xml  = wide_to_xml(string  => $char);
		unlike($html, qr/[^[:ascii:]]/, "html: $cp is pure ASCII");
		unlike($xml,  qr/[^[:ascii:]]/, "xml:  $cp is pure ASCII");
		diag "$cp html=$html xml=$xml" if $ENV{TEST_VERBOSE};
	}
};

# ===========================================================================
# 17. Bullet (U+25CF) encodes to &#x25CF; in both pipelines
# ===========================================================================

subtest 'Black circle bullet (U+25CF) encodes to &#x25CF;' => sub {
	is(wide_to_html(string => $BULLET), '&#x25CF;', 'html: U+25CF -> &#x25CF;');
	is(wide_to_xml(string  => $BULLET), '&#x25CF;', 'xml:  U+25CF -> &#x25CF;');
};

# ===========================================================================
# 18. Raw byte 0x98 (Windows-1252 apostrophe-like)
# ---------------------------------------------------------------------------
# The byte_map contains "\x98" => '&apos;' in the HTML pipeline and
# "\x98" => '&#039;' in the XML pipeline.  Verify this raw byte is
# handled without producing non-ASCII output.
# ===========================================================================

subtest 'Raw byte 0x98 produces pure-ASCII output in both pipelines' => sub {
	my $x98  = "\x98";
	my $html = wide_to_html(string => $x98);
	my $xml  = wide_to_xml(string  => $x98);
	unlike($html, qr/[^[:ascii:]]/, 'html: 0x98 is pure ASCII');
	unlike($xml,  qr/[^[:ascii:]]/, 'xml:  0x98 is pure ASCII');
	diag "html 0x98: $html" if $ENV{TEST_VERBOSE};
	diag "xml  0x98: $xml"  if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# 19. String ending in raw byte 0x80 (the \x80\$ entry in byte_map)
# ---------------------------------------------------------------------------
# The pass-3 byte_map in both functions contains ["\x80\$", ' '], where \$
# in the string literal is a literal dollar sign.  This means the entry
# matches the two-character sequence "\x80$" (0x80 followed by dollar).
# Verify that a string ending in 0x80 (without $) and a string containing
# the two-char sequence are both handled without non-ASCII output.
# ===========================================================================

subtest 'String ending in raw 0x80 (U+0080): HTML encodes, XML fires BUG die' => sub {
	my $x80_end = "abc\x80";	# U+0080 PADDING CHARACTER

	# HTML: encode_entities_numeric provides a numeric-entity fallback.
	open(local *STDERR, '>', '/dev/null') or die;
	local $SIG{__WARN__} = sub { };
	my $html = eval { wide_to_html(string => $x80_end) };
	if($@) {
		pass('html: 0x80 terminated (die or encode both acceptable)');
	} else {
		unlike($html, qr/[^[:ascii:]]/, 'html: trailing 0x80 result is pure ASCII');
	}

	# XML: U+0080 is not in any XML byte_map; the documented BUG die fires.
	open(local *STDERR, '>', '/dev/null') or die;
	local $SIG{__WARN__} = sub { };
	throws_ok { wide_to_xml(string => $x80_end) }
		qr/BUG: wide_to_xml/,
		'xml: U+0080 (unmapped in XML) triggers documented BUG die';
};

subtest 'String with chr(128) followed by $ tests the [\\x80$, " "] byte_map entry' => sub {
	# byte_map pass 3 contains ["\x80\$", ' '] -- two-char sequence chr(128).'$'
	my $x80_dollar = "abc\x80\$def";

	open(local *STDERR, '>', '/dev/null') or die;
	local $SIG{__WARN__} = sub { };
	my $html = eval { wide_to_html(string => $x80_dollar) };
	if(!$@) {
		unlike($html, qr/[^[:ascii:]]/, 'html: chr(128).$  result is pure ASCII');
		diag "html chr(128).\$: $html" if $ENV{TEST_VERBOSE};
	} else {
		pass('html: chr(128).$ terminated (die acceptable)');
	}

	open(local *STDERR, '>', '/dev/null') or die;
	local $SIG{__WARN__} = sub { };
	my $xml = eval { wide_to_xml(string => $x80_dollar) };
	if(!$@) {
		unlike($xml, qr/[^[:ascii:]]/, 'xml: chr(128).$ result is pure ASCII');
	} else {
		pass('xml: chr(128).$ terminated (BUG die for unmapped byte is acceptable)');
	}
};

# ===========================================================================
# 20. undef via positional argument form
# ---------------------------------------------------------------------------
# The named-arg form `string => undef` is tested in unit.t.  Here we verify
# the positional shorthand `wide_to_html(undef)` triggers the same die.
# ===========================================================================

subtest 'undef via positional arg form triggers the documented die' => sub {
	open(local *STDERR, '>', '/dev/null') or die;
	throws_ok { wide_to_html(undef) }
		qr/Usage:.*wide_to_html.*string not set/,
		'html: positional undef -> same die as named undef';
	throws_ok { wide_to_xml(undef) }
		qr/Usage:.*string.*not set/,
		'xml: positional undef -> same die as named undef';
};

# ===========================================================================
# 21. Stress: very large pure-ASCII string (O(n) early-exit path)
# ---------------------------------------------------------------------------
# After the first byte_map pass the module checks `if($string !~ /[^[:ascii:]]/)
# and returns early.  A huge ASCII string must complete quickly.
# ===========================================================================

subtest 'Stress: 10k ASCII chars complete within 10 seconds' => sub {
	my $big_ascii = 'Hello World ' x ($LARGE_N / 12);
	local $SIG{ALRM} = sub { die "TIMEOUT\n" };
	alarm(10);
	my $html = eval { wide_to_html(string => $big_ascii) };
	alarm(0);
	ok(!($@ && $@ eq "TIMEOUT\n"), 'html: large ASCII string did not time out');
	is($html, $big_ascii, 'html: large ASCII string returned unchanged') unless $@;

	alarm(10);
	my $xml = eval { wide_to_xml(string => $big_ascii) };
	alarm(0);
	ok(!($@ && $@ eq "TIMEOUT\n"), 'xml: large ASCII string did not time out');
	is($xml, $big_ascii, 'xml: large ASCII string returned unchanged') unless $@;
};

subtest 'Stress: 10k e-acute chars complete within 30 seconds' => sub {
	my $big_wide = $E_ACUTE x $LARGE_N;
	local $SIG{ALRM} = sub { die "TIMEOUT\n" };
	alarm(30);
	my $html = eval { wide_to_html(string => $big_wide) };
	alarm(0);
	ok(!($@ && $@ eq "TIMEOUT\n"), 'html: large wide string did not time out');
	if(!$@) {
		unlike($html, qr/[^[:ascii:]]/, 'html: 10k e-acute output is pure ASCII');
		is($html, '&eacute;' x $LARGE_N,  'html: each e-acute encoded as &eacute;');
	}

	alarm(30);
	my $xml = eval { wide_to_xml(string => $big_wide) };
	alarm(0);
	ok(!($@ && $@ eq "TIMEOUT\n"), 'xml: large wide string did not time out');
	if(!$@) {
		unlike($xml, qr/[^[:ascii:]]/, 'xml: 10k e-acute output is pure ASCII');
	}
};

# ===========================================================================
# 22. Repeated idempotency (beyond two passes tested in integration.t)
# ---------------------------------------------------------------------------
# Five successive applications of wide_to_html and wide_to_xml must each
# produce the same output as the previous pass.  Any encoding instability
# (a char not correctly encoded first time, then encoded differently next
# time) would manifest here.
# ===========================================================================

subtest 'wide_to_html is idempotent across 5 successive passes' => sub {
	my $input = "caf${E_ACUTE} ${A_GRAVE} & <b> \"it&apos;s\"";
	my $prev  = wide_to_html(string => $input);
	for my $n (2 .. 5) {
		my $next = wide_to_html(string => $prev);
		is($next, $prev, "html: pass $n matches pass " . ($n - 1));
		$prev = $next;
	}
};

subtest 'wide_to_xml is idempotent across 5 successive passes' => sub {
	my $input = "caf${E_ACUTE} ${A_GRAVE} & \"it's\"";
	my $prev  = wide_to_xml(string => $input);
	for my $n (2 .. 5) {
		my $next = wide_to_xml(string => $prev);
		is($next, $prev, "xml: pass $n matches pass " . ($n - 1));
		$prev = $next;
	}
};

# ===========================================================================
# 23. Mixed hostile string: regex metacharacters + wide chars together
# ---------------------------------------------------------------------------
# When a string contains both regex metacharacters AND wide characters, the
# byte_map regex in _sub_map must not mis-match or corrupt either part.
# ===========================================================================

subtest 'Regex metacharacters mixed with wide chars: each part encoded correctly' => sub {
	# '.*' adjacent to e-acute -- the .* must survive as-is, e-acute encoded
	my $mixed = ".*${E_ACUTE}+?";
	my $html  = wide_to_html(string => $mixed);
	like($html, qr/\.\*&eacute;\+\?/, 'html: metacharacters pass through, e-acute encoded');
	unlike($html, qr/[^[:ascii:]]/, 'html: mixed string is pure ASCII');

	my $xml = wide_to_xml(string => $mixed);
	like($xml, qr/\.\*&#x0E9;\+\?/, 'xml: metacharacters pass through, e-acute encoded');
	unlike($xml, qr/[^[:ascii:]]/, 'xml: mixed string is pure ASCII');
};

done_testing();
