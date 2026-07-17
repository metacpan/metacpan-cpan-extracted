#!/usr/bin/env perl

# End-to-end integration tests for Encode::Wide.
#
# These tests focus on cross-function workflows and multi-component
# interactions: how wide_to_html and wide_to_xml behave in sequence,
# how they interact with HTML::Entities::decode, and how they handle
# real-world passages.  Internal plumbing is left to function.t;
# per-API contract assertions live in unit.t.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird qw(mock restore_all);
use Test::Returns;
use Readonly;

# ---------------------------------------------------------------------------
# Character constants -- named so tests read as assertions, not magic values
# ---------------------------------------------------------------------------

Readonly::Scalar my $MODULE       => 'Encode::Wide';

Readonly::Scalar my $E_ACUTE      => "\x{00E9}";	# U+00E9 e-acute
Readonly::Scalar my $A_GRAVE      => "\x{00E0}";	# U+00E0 a-grave
Readonly::Scalar my $I_UML        => "\x{00EF}";	# U+00EF i-umlaut
Readonly::Scalar my $C_CED        => "\x{00E7}";	# U+00E7 c-cedilla
Readonly::Scalar my $EN_DASH      => "\x{2013}";	# U+2013 en-dash (folds to '-' in XML; lossy)
Readonly::Scalar my $EM_DASH      => "\x{2014}";	# U+2014 em-dash (folds to '-' in XML; lossy)
Readonly::Scalar my $TRADE        => "\x{2122}";	# U+2122 trade mark sign
Readonly::Scalar my $ZCARON_L     => "\x{017E}";	# U+017E z-with-caron lowercase
Readonly::Scalar my $ZCARON_U     => "\x{017D}";	# U+017D Z-with-caron uppercase
Readonly::Scalar my $C_CARON      => "\x{010D}";	# U+010D c-with-caron
Readonly::Scalar my $S_CARON      => "\x{0161}";	# U+0161 s-with-caron lowercase
Readonly::Scalar my $S_CARON_U    => "\x{0160}";	# U+0160 S-with-caron uppercase

# Representative real-world text fixtures
Readonly::Scalar my $FRENCH_PHRASE  => "Caf${E_ACUTE} d${E_ACUTE}j${A_GRAVE} vu ${EN_DASH} na${I_UML}ve fa${C_CED}ade";
Readonly::Scalar my $CROATIAN_NAME  => "SURN ${ZCARON_U}ganjar";
Readonly::Scalar my $GERMAN_PHRASE  => "Stra\x{00DF}e und M\x{00FC}nchen";	# U+00DF szlig, U+00FC u-umlaut

# ---------------------------------------------------------------------------
# Module load
# ---------------------------------------------------------------------------

use_ok($MODULE, qw(wide_to_html wide_to_xml));

# ===========================================================================
# Integration 1: Parallel encoding of the same input
# ---------------------------------------------------------------------------
# Both functions must consume the same Unicode string and each produce
# pure-ASCII output.  They differ in encoding style (named vs. numeric
# entities) but both must correctly represent every character.
# ===========================================================================

subtest 'Parallel encoding: same input, both outputs are pure ASCII' => sub {
	my @fixtures = ($FRENCH_PHRASE, $CROATIAN_NAME, $GERMAN_PHRASE);
	for my $i (0 .. $#fixtures) {
		my $input = $fixtures[$i];
		my $html = wide_to_html(string => $input);
		my $xml  = wide_to_xml(string  => $input);

		unlike($html, qr/[^[:ascii:]]/, "HTML output is pure ASCII (fixture $i)");
		unlike($xml,  qr/[^[:ascii:]]/, "XML output is pure ASCII (fixture $i)");

		diag "HTML: $html" if $ENV{TEST_VERBOSE};
		diag "XML:  $xml"  if $ENV{TEST_VERBOSE};
	}
};

subtest 'Parallel encoding: HTML uses named entities, XML uses numeric' => sub {
	# For a shared input both functions must agree on the character but differ on entity style.
	my $html = wide_to_html(string => "${E_ACUTE}${A_GRAVE}${I_UML}${C_CED}");
	my $xml  = wide_to_xml(string  => "${E_ACUTE}${A_GRAVE}${I_UML}${C_CED}");

	is($html, '&eacute;&agrave;&iuml;&ccedil;', 'HTML: named entities for all four chars');
	is($xml,  '&#x0E9;&#x0E0;&#x0EF;&#x0E7;',  'XML: numeric entities for all four chars');
};

# ===========================================================================
# Integration 2: HTML -> XML chaining idempotency
# ---------------------------------------------------------------------------
# The HTML output (with named entities like &eacute;) fed into wide_to_xml
# must produce the same result as feeding the original Unicode string
# directly into wide_to_xml.  This exercises the entity pre-decode pipeline
# in wide_to_xml (HTML::Entities::decode + custom entity_map alternation).
# ===========================================================================

subtest 'HTML-then-XML chaining equals direct XML encoding' => sub {
	# All inputs below are safe for this test because HTML::Entities::decode
	# will fully restore the named entities produced by wide_to_html.
	my @inputs = (
		$FRENCH_PHRASE,
		$CROATIAN_NAME,
		$GERMAN_PHRASE,
		"na${I_UML}ve ${C_CED}af${E_ACUTE}",
		"${ZCARON_U}ganjar${C_CARON}",
		"Widget${TRADE}",
	);

	for my $i (0 .. $#inputs) {
		my $input         = $inputs[$i];
		my $html_then_xml = wide_to_xml(string => wide_to_html(string => $input));
		my $direct_xml    = wide_to_xml(string => $input);

		is($html_then_xml, $direct_xml,
			"HTML->XML chain equals direct XML (input $i)");
		unlike($html_then_xml, qr/[^[:ascii:]]/, "Chain result is pure ASCII (input $i)");
	}
};

# ===========================================================================
# Integration 3: XML -> HTML chaining idempotency
# ---------------------------------------------------------------------------
# The XML output (&#x0E9; etc.) fed into wide_to_html must produce the same
# result as feeding the original string directly into wide_to_html.
# HTML::Entities::decode handles &#xNN; numeric references.
#
# NOTE: Inputs containing en-dash/em-dash are intentionally excluded.
# wide_to_xml folds those to '-' (a lossy transformation documented in the
# POD formal spec), so the reverse chain would produce '-' rather than
# '&ndash;'.  That is correct behavior, not a bug.
# ===========================================================================

subtest 'XML-then-HTML chaining equals direct HTML encoding (non-dash inputs)' => sub {
	my @inputs = (
		"na${I_UML}ve ${C_CED}af${E_ACUTE}",
		"${ZCARON_U}ganjar${C_CARON}",
		"Widget${TRADE}",
		"${E_ACUTE}${A_GRAVE}${I_UML}${C_CED}",
		$GERMAN_PHRASE,
	);

	for my $i (0 .. $#inputs) {
		my $input         = $inputs[$i];
		my $xml_then_html = wide_to_html(string => wide_to_xml(string => $input));
		my $direct_html   = wide_to_html(string => $input);

		is($xml_then_html, $direct_html,
			"XML->HTML chain equals direct HTML (input $i)");
		unlike($xml_then_html, qr/[^[:ascii:]]/, "Chain result is pure ASCII (input $i)");
	}
};

# ===========================================================================
# Integration 4: wide_to_html idempotency (double-encoding is safe)
# ---------------------------------------------------------------------------
# Calling wide_to_html twice on the same string must yield the same result
# as calling it once.  This is the core guarantee of the entity pre-decode
# step: &eacute; in input -> decoded -> re-encode to &eacute;.
# ===========================================================================

subtest 'wide_to_html is idempotent: second call gives same output as first' => sub {
	my @inputs = (
		$FRENCH_PHRASE,
		$CROATIAN_NAME,
		"Hello & world",
		'"quoted"',
		'<tag>',
		"it's done",
		"Widget${TRADE}",
		"${EN_DASH} and ${EM_DASH}",
	);

	for my $i (0 .. $#inputs) {
		my $input = $inputs[$i];
		my $once  = wide_to_html(string => $input);
		my $twice = wide_to_html(string => $once);
		is($twice, $once, "Idempotent wide_to_html double-call (input $i)");
	}
};

# ===========================================================================
# Integration 5: wide_to_xml idempotency (double-encoding is safe)
# ---------------------------------------------------------------------------
# Same guarantee for the XML pipeline.  wide_to_xml output contains only
# &#xNN; numeric entities and ASCII; feeding it back through wide_to_xml
# must produce the exact same string.
# ===========================================================================

subtest 'wide_to_xml is idempotent: second call gives same output as first' => sub {
	my @inputs = (
		$FRENCH_PHRASE,
		$CROATIAN_NAME,
		$GERMAN_PHRASE,
		"Hello & world",
		'"quoted"',
		'<tag>',
		"Widget${TRADE}",
		"${EN_DASH}${EM_DASH}",
	);

	for my $i (0 .. $#inputs) {
		my $input = $inputs[$i];
		my $once  = wide_to_xml(string => $input);
		my $twice = wide_to_xml(string => $once);
		is($twice, $once, "Idempotent wide_to_xml double-call (input $i)");
	}
};

# ===========================================================================
# Integration 6: Named entity input decoded and re-encoded by both pipelines
# ---------------------------------------------------------------------------
# When the input already contains named HTML entities (e.g. from a CMS or
# template), both functions must decode them and re-emit in their own style.
# This tests the combined action of HTML::Entities::decode (for standard
# entities) and the custom entity_map alternation (for ccaron/zcaron etc.).
# ===========================================================================

subtest 'Named entity input: decoded and re-encoded correctly by both functions' => sub {
	# Standard entities handled by HTML::Entities::decode
	is(wide_to_html(string => '&eacute;'),  '&eacute;',  'HTML: &eacute; round-trips');
	is(wide_to_xml(string  => '&eacute;'),  '&#x0E9;',   'XML: &eacute; -> numeric &#x0E9;');

	is(wide_to_html(string => '&agrave;'),  '&agrave;',  'HTML: &agrave; round-trips');
	is(wide_to_xml(string  => '&agrave;'),  '&#x0E0;',   'XML: &agrave; -> numeric &#x0E0;');

	is(wide_to_html(string => '&iuml;'),    '&iuml;',    'HTML: &iuml; round-trips');
	is(wide_to_xml(string  => '&iuml;'),    '&#x0EF;',   'XML: &iuml; -> numeric &#x0EF;');

	is(wide_to_html(string => '&trade;'),   '&trade;',   'HTML: &trade; round-trips');
	is(wide_to_xml(string  => '&trade;'),   '&#x2122;',  'XML: &trade; -> numeric &#x2122;');

	# Custom entities that HTML::Entities::decode does NOT handle (entity_map path)
	is(wide_to_html(string => '&zcaron;'),  '&zcaron;',  'HTML: &zcaron; round-trips via entity_map');
	is(wide_to_xml(string  => '&zcaron;'),  '&#x17E;',   'XML: &zcaron; -> &#x17E; via entity_map');

	is(wide_to_html(string => '&Zcaron;'),  '&Zcaron;',  'HTML: &Zcaron; round-trips via entity_map');
	is(wide_to_xml(string  => '&Zcaron;'),  '&#x17D;',   'XML: &Zcaron; -> &#x17D; via entity_map');

	is(wide_to_html(string => '&ccaron;'),  '&ccaron;',  'HTML: &ccaron; round-trips via entity_map');
	is(wide_to_xml(string  => '&ccaron;'),  '&#x10D;',   'XML: &ccaron; -> &#x10D; via entity_map');

	is(wide_to_html(string => '&Scaron;'),  '&Scaron;',  'HTML: &Scaron; round-trips via entity_map');
	is(wide_to_xml(string  => '&Scaron;'),  '&#x160;',   'XML: &Scaron; -> &#x160; via entity_map');

	# Entity embedded in surrounding text
	is(wide_to_html(string => 'An&zcaron;link'), 'An&zcaron;link', 'HTML: entity in context preserved');
	is(wide_to_xml(string  => 'An&zcaron;link'), 'An&#x17E;link',  'XML: entity in context re-encoded');
};

# ===========================================================================
# Integration 7: keep_hrefs interacts correctly with character encoding
# ---------------------------------------------------------------------------
# The markup-preservation flag must affect only < > " escaping, never the
# character encoding stage.  With keep_hrefs, hyperlinks survive intact
# while all Unicode chars in the URL or text are still encoded.
# ===========================================================================

subtest 'keep_hrefs preserves markup while character encoding continues' => sub {
	my $input = "<a href=\"http://example.com/caf${E_ACUTE}\">${TRADE}</a>";

	my $html_keep   = wide_to_html(string => $input, keep_hrefs => 1);
	my $html_escape = wide_to_html(string => $input);
	my $xml_keep    = wide_to_xml(string  => $input, keep_hrefs => 1);
	my $xml_escape  = wide_to_xml(string  => $input);

	# Markup intact, Unicode encoded
	like($html_keep, qr{<a href="http://example\.com/caf&eacute;">&trade;</a>},
		'HTML keep_hrefs: markup intact, e-acute and trade-mark encoded');
	like($xml_keep,  qr{<a href="http://example\.com/caf&#x0E9;">&#x2122;</a>},
		'XML keep_hrefs: markup intact, e-acute and trade-mark numeric');

	# No keep_hrefs: markup escaped
	like($html_escape, qr/&lt;a href=&quot;/, 'HTML default: < and " escaped');
	like($xml_escape,  qr/&lt;a href=&quot;/, 'XML default: < and " escaped');

	# Pure ASCII check either way
	unlike($html_keep,   qr/[^[:ascii:]]/, 'HTML keep_hrefs: pure ASCII output');
	unlike($xml_keep,    qr/[^[:ascii:]]/, 'XML keep_hrefs: pure ASCII output');
	unlike($html_escape, qr/[^[:ascii:]]/, 'HTML escaped: pure ASCII output');
	unlike($xml_escape,  qr/[^[:ascii:]]/, 'XML escaped: pure ASCII output');
};

# ===========================================================================
# Integration 8: keep_apos + keep_hrefs combined in wide_to_html
# ---------------------------------------------------------------------------
# Tests all four flag combinations in a single pass.  wide_to_xml has no
# keep_apos parameter, so this subtest is HTML-only.
# ===========================================================================

subtest 'wide_to_html: keep_apos and keep_hrefs interact independently' => sub {
	my $input = "<p class='note'>it's ${E_ACUTE}</p>";

	my $both_off  = wide_to_html(string => $input, keep_hrefs => 0, keep_apos => 0);
	my $apos_only = wide_to_html(string => $input, keep_hrefs => 0, keep_apos => 1);
	my $href_only = wide_to_html(string => $input, keep_hrefs => 1, keep_apos => 0);
	my $both_on   = wide_to_html(string => $input, keep_hrefs => 1, keep_apos => 1);

	# Both off: everything escaped
	like($both_off, qr/&lt;p class=&apos;note&apos;&gt;/,
		'both off: < and apostrophes escaped');
	like($both_off, qr/it&apos;s &eacute;&lt;\/p&gt;/,
		'both off: apostrophe in word escaped, e-acute encoded');

	# keep_apos only: apostrophes survive, markup escaped
	like($apos_only, qr/&lt;p class='note'&gt;it's &eacute;&lt;\/p&gt;/,
		"keep_apos: apostrophes survive, markup still escaped");

	# keep_hrefs only: markup survives, apostrophes escaped
	like($href_only, qr{<p class=&apos;note&apos;>it&apos;s &eacute;</p>},
		'keep_hrefs: markup survives, apostrophes still escaped');

	# Both on: markup and apostrophes survive
	like($both_on, qr{<p class='note'>it's &eacute;</p>},
		'both on: markup and apostrophes survive intact');

	# All four outputs are pure ASCII
	unlike($_, qr/[^[:ascii:]]/, 'output is pure ASCII') for ($both_off, $apos_only, $href_only, $both_on);
};

# ===========================================================================
# Integration 9: Real-world French passage
# ---------------------------------------------------------------------------
# A realistic multi-word French sentence exercises the full multi-pass
# pipeline: e-acute, a-grave, i-umlaut, c-cedilla, and an en-dash.
# ===========================================================================

subtest 'Real-world French passage: full pipeline for HTML and XML' => sub {
	my $html = wide_to_html(string => $FRENCH_PHRASE);
	my $xml  = wide_to_xml(string  => $FRENCH_PHRASE);

	is($html,
		'Caf&eacute; d&eacute;j&agrave; vu &ndash; na&iuml;ve fa&ccedil;ade',
		'French phrase: correct HTML with named entities');
	is($xml,
		'Caf&#x0E9; d&#x0E9;j&#x0E0; vu - na&#x0EF;ve fa&#x0E7;ade',
		'French phrase: correct XML with numeric entities (en-dash folded to -)');

	unlike($html, qr/[^[:ascii:]]/, 'HTML output is pure ASCII');
	unlike($xml,  qr/[^[:ascii:]]/, 'XML output is pure ASCII');
};

# ===========================================================================
# Integration 10: Real-world Croatian name
# ---------------------------------------------------------------------------
# Tests the Z-caron (upper and lower) pathway (passes 1, 2, and 3 in both functions)
# with a proper noun that looks realistic in production data.
# ===========================================================================

subtest 'Real-world Croatian name: Zcaron pathway end-to-end' => sub {
	my $html = wide_to_html(string => $CROATIAN_NAME);
	my $xml  = wide_to_xml(string  => $CROATIAN_NAME);

	is($html, 'SURN &Zcaron;ganjar', 'Croatian name: HTML &Zcaron;');
	is($xml,  'SURN &#x17D;ganjar',  'Croatian name: XML &#x17D;');

	# Also verify lowercase z-caron (U+017E) variant
	is(wide_to_html(string => $ZCARON_L), '&zcaron;', 'HTML: U+017E -> &zcaron;');
	is(wide_to_xml(string  => $ZCARON_L), '&#x17E;',  'XML: U+017E -> &#x17E;');
};

# ===========================================================================
# Integration 11: XML en-dash / em-dash folding is a documented lossy step
# ---------------------------------------------------------------------------
# The POD formal spec states that U+2013 and U+2014 collapse to '-' in XML.
# Verify this and contrast with the HTML behaviour (which preserves them as
# &ndash; / &mdash;).
# ===========================================================================

subtest 'Dash folding: XML collapses dashes, HTML preserves them as named entities' => sub {
	is(wide_to_html(string => $EN_DASH), '&ndash;', 'HTML: en-dash -> &ndash;');
	is(wide_to_html(string => $EM_DASH), '&mdash;', 'HTML: em-dash -> &mdash;');

	is(wide_to_xml(string => $EN_DASH),  '-',        'XML: en-dash folded to -');
	is(wide_to_xml(string => $EM_DASH),  '-',        'XML: em-dash folded to -');

	# Named dash entities in input also fold in XML
	is(wide_to_xml(string => '&ndash;'), '-',         'XML: &ndash; input -> -');
	is(wide_to_xml(string => '&mdash;'), '-',         'XML: &mdash; input -> -');

	# But wide_to_html round-trips them
	is(wide_to_html(string => '&ndash;'), '&ndash;',  'HTML: &ndash; input round-trips');
	is(wide_to_html(string => '&mdash;'), '&mdash;',  'HTML: &mdash; input round-trips');
};

# ===========================================================================
# Integration 12: Ampersand escaping does not double-encode existing entities
# ---------------------------------------------------------------------------
# Bare & must be escaped; entity & must be preserved.  The pipeline achieves
# this via the negative-lookahead regex: s/&(?![A-Za-z#0-9]+;)/&amp;/g.
# ===========================================================================

subtest 'No double-encoding: existing entities survive both pipelines unchanged' => sub {
	my @survive_html = qw(&amp; &lt; &gt; &quot; &eacute; &trade; &ndash; &mdash;);
	for my $entity (@survive_html) {
		is(wide_to_html(string => $entity), $entity,
			"HTML: $entity survives unchanged");
	}

	# XML decodes named entities and re-encodes them numerically (expected)
	is(wide_to_xml(string => '&amp;'),   '&amp;',    'XML: &amp; survives unchanged');
	is(wide_to_xml(string => '&lt;'),    '&lt;',     'XML: &lt; survives unchanged');
	is(wide_to_xml(string => '&gt;'),    '&gt;',     'XML: &gt; survives unchanged');
	is(wide_to_xml(string => '&quot;'),  '&quot;',   'XML: &quot; survives unchanged');
	is(wide_to_xml(string => '&eacute;'), '&#x0E9;', 'XML: &eacute; decoded -> &#x0E9;');
};

# ===========================================================================
# Integration 13: State isolation between consecutive calls
# ---------------------------------------------------------------------------
# Consecutive calls with different flag combinations must not bleed state.
# The module uses only lexically scoped variables; this verifies that.
# ===========================================================================

subtest 'State isolation: flags from one call do not affect the next' => sub {
	# Call with keep_hrefs=1, then without
	my $with_hrefs    = wide_to_html(string => '<b>', keep_hrefs => 1);
	my $without_hrefs = wide_to_html(string => '<b>');
	is($with_hrefs,    '<b>',       'keep_hrefs=1: < preserved');
	is($without_hrefs, '&lt;b&gt;', 'Next call (no keep_hrefs): < escaped (no state bleed)');

	# Call with keep_apos=1, then without
	my $with_apos    = wide_to_html(string => "it's", keep_apos => 1);
	my $without_apos = wide_to_html(string => "it's");
	is($with_apos,    "it's",      'keep_apos=1: apostrophe preserved');
	is($without_apos, "it&apos;s", 'Next call (no keep_apos): apostrophe encoded (no state bleed)');

	# Interleave XML then HTML calls
	my $xml_result  = wide_to_xml(string  => $FRENCH_PHRASE);
	my $html_result = wide_to_html(string => $FRENCH_PHRASE);
	like($xml_result,  qr/&#x0E9;/,  'XML call correct after HTML calls');
	like($html_result, qr/&eacute;/, 'HTML call correct after XML call');
};

# ===========================================================================
# Integration 14: No shared state - independent concurrent call simulation
# ---------------------------------------------------------------------------
# All state is lexically scoped within each function call.  Verify that
# interleaving many calls with different inputs produces correct results
# with no cross-contamination.
# ===========================================================================

subtest 'No shared state: interleaved calls produce correct independent results' => sub {
	my @jobs = (
		{ in => "${E_ACUTE}",   html => '&eacute;',   xml => '&#x0E9;'  },
		{ in => "${A_GRAVE}",   html => '&agrave;',   xml => '&#x0E0;'  },
		{ in => "${I_UML}",     html => '&iuml;',     xml => '&#x0EF;'  },
		{ in => "${C_CED}",     html => '&ccedil;',   xml => '&#x0E7;'  },
		{ in => "${ZCARON_L}",  html => '&zcaron;',   xml => '&#x17E;'  },
		{ in => "${ZCARON_U}",  html => '&Zcaron;',   xml => '&#x17D;'  },
		{ in => "${C_CARON}",   html => '&ccaron;',   xml => '&#x10D;'  },
		{ in => "${TRADE}",     html => '&trade;',    xml => '&#x2122;' },
	);

	# Interleave HTML and XML calls to surface any shared-state dependency
	for my $i (0 .. $#jobs) {
		my $j = $jobs[$i];
		is(wide_to_html(string => $j->{in}), $j->{html}, "html job $i");
		is(wide_to_xml(string  => $j->{in}), $j->{xml},  "xml job $i");
	}
};

# ===========================================================================
# Integration 15: HTML::Entities::decode is invoked for entity pre-processing
# ---------------------------------------------------------------------------
# Both functions must call HTML::Entities::decode on every input.  We wrap it
# with a mock that records calls while still executing the original function.
# ===========================================================================

subtest 'HTML::Entities::decode is called on every invocation of both functions' => sub {
	my @decode_calls;
	my $orig_decode = \&HTML::Entities::decode;
	mock 'HTML::Entities::decode' => sub {
		push @decode_calls, $_[0];	# record the input
		return $orig_decode->(@_);	# call through to the real implementation
	};

	wide_to_html(string => 'caf&eacute;');
	is(scalar @decode_calls, 1, 'wide_to_html: decode called exactly once');
	is($decode_calls[0], 'caf&eacute;', 'wide_to_html: decode received the input string');

	@decode_calls = ();
	wide_to_xml(string => 'caf&eacute;');
	is(scalar @decode_calls, 1, 'wide_to_xml: decode called exactly once');
	is($decode_calls[0], 'caf&eacute;', 'wide_to_xml: decode received the input string');

	restore_all();

	# Sanity: after restore_all, both functions still work correctly
	is(wide_to_html(string => "caf${E_ACUTE}"), 'caf&eacute;', 'HTML still works after restore_all');
	is(wide_to_xml(string  => "caf${E_ACUTE}"), 'caf&#x0E9;',  'XML still works after restore_all');
};

# ===========================================================================
# Integration 16: Scalar-ref input gives same result as plain scalar
# ---------------------------------------------------------------------------
# Both functions accept a ref-to-scalar per the POD.  The result must be
# byte-identical to the result of passing the same value as a plain scalar.
# ===========================================================================

subtest 'Scalar-ref input is equivalent to plain scalar for both functions' => sub {
	my @inputs = ($FRENCH_PHRASE, $CROATIAN_NAME, "Widget${TRADE}");

	for my $i (0 .. $#inputs) {
		my $input = $inputs[$i];
		is(wide_to_html(string => \$input), wide_to_html(string => $input),
			"wide_to_html: scalar-ref matches scalar (input $i)");
		is(wide_to_xml(string => \$input), wide_to_xml(string => $input),
			"wide_to_xml: scalar-ref matches scalar (input $i)");
	}
};

# ===========================================================================
# Integration 17: Positional string arg is equivalent to named arg
# ---------------------------------------------------------------------------
# Params::Get maps the first positional argument to 'string'.  The result
# must match the named-parameter invocation.
# ===========================================================================

subtest 'Positional arg is equivalent to named arg for both functions' => sub {
	my @inputs = ($FRENCH_PHRASE, "Widget${TRADE}", $CROATIAN_NAME);

	for my $i (0 .. $#inputs) {
		my $input = $inputs[$i];
		is(wide_to_html($input), wide_to_html(string => $input),
			"wide_to_html positional == named (input $i)");
		is(wide_to_xml($input),  wide_to_xml(string  => $input),
			"wide_to_xml positional == named (input $i)");
	}
};

# ===========================================================================
# Integration 18: complain callback coordinates with die in both functions
# ---------------------------------------------------------------------------
# The 'complain' callback is invoked with a TODO message immediately before
# the BUG die.  Verify the callback fires and receives a matching message
# before the die propagates, across both functions.
# ===========================================================================

subtest 'complain callback fires before BUG die in wide_to_html' => sub {
	my $complaint;
	my $orig_encode = \&HTML::Entities::encode_entities_numeric;
	mock 'HTML::Entities::encode_entities_numeric' => sub {
		# Return the char unchanged so the BUG check triggers
		return $_[0];
	};

	open(local *STDERR, '>', '/dev/null') or die;
	local $SIG{__WARN__} = sub { };
	throws_ok {
		wide_to_html(
			string   => "\x{E000}",
			complain => sub { $complaint = $_[0] },
		);
	} qr/BUG: wide_to_html/, 'wide_to_html dies with BUG message';

	like($complaint, qr/TODO: wide_to_html/, 'complain callback received TODO message');
	restore_all();
};

subtest 'complain callback fires before BUG die in wide_to_xml' => sub {
	# U+E000 is in the Private Use Area and has no entry in any byte map,
	# so it always reaches the BUG die in wide_to_xml without mocking.
	my $complaint;

	open(local *STDERR, '>', '/dev/null') or die;
	local $SIG{__WARN__} = sub { };
	throws_ok {
		wide_to_xml(
			string   => "\x{E000}",
			complain => sub { $complaint = $_[0] },
		);
	} qr/BUG: wide_to_xml/, 'wide_to_xml dies with BUG message';

	like($complaint, qr/TODO: wide_to_xml/, 'complain callback received TODO message');
};

# ===========================================================================
# Integration 19: HTML::Entities is a hard dependency - not optional
# ---------------------------------------------------------------------------
# No optional dependency fallback exists in this module; all three 'use'
# statements are unconditional.  Verify that Encode::Wide refuses to load
# in a fresh process when HTML::Entities is hidden.  We use a subprocess
# so the main test process (which already loaded the module) is unaffected.
# ===========================================================================

subtest 'HTML::Entities absence prevents module load (required dependency)' => sub {
	my $exit = system(
		$^X, '-I', 'lib',
		'-e', 'use Test::Without::Module "HTML::Entities"; use Encode::Wide; print "OK\n"'
	);
	isnt($exit, 0, 'Encode::Wide fails to load when HTML::Entities is absent');
};

subtest 'Params::Get absence prevents module load (required dependency)' => sub {
	my $exit = system(
		$^X, '-I', 'lib',
		'-e', 'use Test::Without::Module "Params::Get"; use Encode::Wide; print "OK\n"'
	);
	isnt($exit, 0, 'Encode::Wide fails to load when Params::Get is absent');
};

done_testing();
