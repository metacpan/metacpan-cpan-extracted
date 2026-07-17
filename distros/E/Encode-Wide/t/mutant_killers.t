#!/usr/bin/env perl
# Targeted mutant-killer tests for lib/Encode/Wide.pm.
#
# Each subtest names the mutation ID(s) it kills, explains WHY the named
# mutation would cause the test to fail, and uses the minimal assertion
# that distinguishes the live code from the mutant.
#
# Mutation ID reference (from mutation.json + xt/ stubs):
#
#   COND_INV_426_3  stub survivor -- phantom of COND_INV_502_2 (line shifted)
#   COND_INV_189_2  line 189  if(!defined($string))        wide_to_html undef guard
#   COND_INV_197_2  line 197  if(ref($string) eq 'SCALAR') wide_to_html scalarref
#   COND_INV_227_2  line 227  unless(keep_hrefs)           wide_to_html html-escaping
#   COND_INV_260_2  line 260  unless(keep_apos)            wide_to_html apos-encoding
#   COND_INV_282_2  line 282  if($string !~ /[^[:ascii:]]/) ASCII early-return html
#   BOOL_NEGATE_283_3 / RETURN_UNDEF_283_3  line 283  return $string (early return)
#   COND_INV_502_2  line 502  if($string =~ /[^[:ascii:]]/) fallback check html
#   COND_INV_504_3  line 504  if($string =~ /[^[:ascii:]]/) BUG-die check html
#   BOOL_NEGATE_524_2 / RETURN_UNDEF_524_2  line 524  return $string (final html)
#   COND_INV_604_2  line 604  if(!defined($string))        wide_to_xml undef guard
#   COND_INV_612_2  line 612  if(ref($string) eq 'SCALAR') wide_to_xml scalarref
#   COND_INV_645_2  line 645  unless(keep_hrefs)           wide_to_xml html-escaping
#   COND_INV_715_2  line 715  if($string !~ /[^[:ascii:]]/) ASCII early-return xml
#   BOOL_NEGATE_716_3 / RETURN_UNDEF_716_3  line 716  return $string (early return xml)
#   COND_INV_927_2  line 927  if($string =~ /[^[:ascii:]]/) BUG-die check xml
#   BOOL_NEGATE_946_2 / RETURN_UNDEF_946_2  line 946  return $string (final xml)
#   BOOL_NEGATE_966_2 / RETURN_UNDEF_966_2  line 966  return $string (_sub_map)

use strict;
use warnings;
use Test::Most;
use Test::Mockingbird qw(mock restore_all);
use Readonly;

Readonly::Scalar my $MODULE   => 'Encode::Wide';
Readonly::Scalar my $E_ACUTE  => "\x{00E9}";	# U+00E9 e-acute - in byte_map html+xml
Readonly::Scalar my $Z_CARON  => "\x{017E}";	# U+017E z-caron - in xml byte_map pass 2
Readonly::Scalar my $CYRILLIC => "\x{0410}";	# U+0410 Cyrillic A - NOT in any byte_map

use_ok($MODULE, qw(wide_to_html wide_to_xml));

# ---------------------------------------------------------------------------
# 1. COND_INV_426_3 (stub survivor) + COND_INV_502_2 + COND_INV_504_3
#
# The xt/ stub reported COND_INV_426_3 surviving at "line 426 in wide_to_html()".
# That line number was from an intermediate file revision; the mutated statement
# is currently at line 502: if($string =~ /[^[:ascii:]]/).
#
# COND_INV_502_2 kill strategy: inverting if($string =~ /[^[:ascii:]]/) to
# unless(...) means non-ASCII input that survived all byte_map passes would SKIP
# encode_entities_numeric and be returned as raw Unicode.  The unlike(non-ASCII)
# assertion below catches that.
#
# COND_INV_504_3 kill strategy: inverting the INNER if at line 504 to unless
# means the BUG-die fires whenever the string IS pure ASCII after encoding --
# i.e., for every successful conversion.  The lives_ok catches that.
#
# Cyrillic A (U+0410) is absent from all byte_maps and therefore exercises the
# encode_entities_numeric fallback path that both mutations target.
# ---------------------------------------------------------------------------
subtest 'COND_INV_426_3/502_2/504_3: unmapped char must reach encode_entities_numeric' => sub {
	plan tests => 4;

	my $result;
	lives_ok { $result = wide_to_html(string => $CYRILLIC) }
		'no BUG-die for char handled by encode_entities_numeric (kills COND_INV_504_3)';

	ok(defined($result), 'result is defined');
	unlike($result, qr/[^[:ascii:]]/,
		'result is pure ASCII -- raw char here kills COND_INV_502_2');
	like($result, qr/&#(?:\d+|x[0-9A-Fa-f]+);/,
		'result contains a numeric HTML entity');
};

# ---------------------------------------------------------------------------
# 2. COND_INV_189_2 -- undefined-string guard in wide_to_html (line 189)
#
# Mutation: if(!defined($string)) → unless(!defined($string))
#         = if(defined($string))
# Effect:  guard fires on DEFINED strings, skips for undef -- every normal
#          call would die, undef calls would silently proceed and crash later.
#
# Kill A (true-branch): die fires when string IS undef.
# Kill B (false-branch): die does NOT fire for a defined string (mutation fires).
# ---------------------------------------------------------------------------
subtest 'COND_INV_189_2: undef-string guard in wide_to_html' => sub {
	plan tests => 2;

	throws_ok { wide_to_html(string => undef) }
		qr/Usage: wide_to_html\(\) string not set/,
		'undef string triggers die (true-branch confirmed)';

	lives_ok { wide_to_html(string => 'x') }
		'defined string does not die (kills COND_INV_189_2 mutation)';
};

# ---------------------------------------------------------------------------
# 3. COND_INV_197_2 -- scalar-ref deref in wide_to_html (line 197)
#
# Mutation: if(ref($string) eq 'SCALAR') → unless(ref($string) eq 'SCALAR')
# Effect:  scalar-refs are NOT dereferenced; plain strings ARE (crash or "SCALAR(0x..)").
#
# Kill: passing a scalar-ref must produce the same output as passing the string.
# With the mutation the ref is used as-is ("SCALAR(0x...)") and diverges.
# ---------------------------------------------------------------------------
subtest 'COND_INV_197_2: scalar-ref is dereferenced in wide_to_html' => sub {
	plan tests => 1;

	my $s = $E_ACUTE;
	is(wide_to_html(string => \$s), wide_to_html(string => $s),
		'scalar-ref and plain-string produce identical output (kills COND_INV_197_2)');
};

# ---------------------------------------------------------------------------
# 4. COND_INV_227_2 -- keep_hrefs gate in wide_to_html (line 227)
#
# Mutation: unless(keep_hrefs) → if(keep_hrefs)
# Effect:  keep_hrefs=1 ENABLES escaping; omitting keep_hrefs SKIPS escaping.
#          Both sides of the branch must be observed to kill the mutant.
# ---------------------------------------------------------------------------
subtest 'COND_INV_227_2: keep_hrefs controls angle-bracket escaping in wide_to_html' => sub {
	plan tests => 2;

	Readonly::Scalar my $TAG => '<b>bold</b>';

	like(wide_to_html(string => $TAG),
		qr/&lt;b&gt;/,
		'no keep_hrefs: angle brackets escaped (true branch of unless)');
	like(wide_to_html(string => $TAG, keep_hrefs => 1),
		qr/<b>/,
		'keep_hrefs=1: angle brackets preserved (false branch; mutation reverses this)');
};

# ---------------------------------------------------------------------------
# 5. COND_INV_260_2 -- keep_apos gate in wide_to_html (line 260)
#
# Mutation: unless(keep_apos) → if(keep_apos)
# Effect:  keep_apos=1 ENABLES apos replacement; no keep_apos SKIPS it.
#
# The straight ASCII apostrophe (0x27) is handled exclusively by the
# unless(keep_apos) entity_map and not by the earlier byte_map pass, so it is
# the cleanest discriminator: without keep_apos it becomes &apos;, with it stays.
# ---------------------------------------------------------------------------
subtest 'COND_INV_260_2: keep_apos controls apostrophe encoding in wide_to_html' => sub {
	plan tests => 2;

	Readonly::Scalar my $APOS => "it's";	# straight ASCII apostrophe 0x27

	like(wide_to_html(string => $APOS),
		qr/it&apos;s/,
		'no keep_apos: straight apostrophe encoded to &apos;');
	like(wide_to_html(string => $APOS, keep_apos => 1),
		qr/it's/,
		"keep_apos=1: straight apostrophe preserved (mutation reverses this)");
};

# ---------------------------------------------------------------------------
# 6. COND_INV_282_2 + BOOL_NEGATE_283_3 + RETURN_UNDEF_283_3
#    -- ASCII early-return path in wide_to_html (lines 282-283)
#
# COND_INV_282_2: if($string !~ /[^[:ascii:]]/) → unless(...)
#   True branch: pure ASCII returns early. Mutation inverts so:
#   - pure ASCII strings would NOT early-return (redundant processing but OK)
#   - wide-char strings WOULD early-return (returned as raw non-ASCII -- BROKEN)
#   Kill via #7: wide char must be encoded, not returned raw.
#
# BOOL_NEGATE_283_3: return $string → return !$string → returns "" or "1"
# RETURN_UNDEF_283_3: return $string → return undef
#   Kill: pure-ASCII input must be returned EXACTLY as the input string.
# ---------------------------------------------------------------------------
subtest 'COND_INV_282_2 + BOOL_NEGATE/RETURN_UNDEF_283: ASCII early-return in wide_to_html' => sub {
	plan tests => 3;

	Readonly::Scalar my $ASCII => 'plain text 42';

	my $result = wide_to_html(string => $ASCII);
	is($result, $ASCII,
		'pure ASCII returned unchanged (exact match kills negate and undef mutations)');
	ok(defined($result),
		'result is defined (kills RETURN_UNDEF_283_3)');
	isnt($result, '',
		'result is not empty string (kills BOOL_NEGATE_283_3 when input is non-empty)');
};

# ---------------------------------------------------------------------------
# 7. BOOL_NEGATE_524_2 + RETURN_UNDEF_524_2 -- final return of wide_to_html (line 524)
#
# Mutation: return $string → return !$string (→ "1" for non-empty) or return undef.
# Kill: a wide-char conversion must return the EXACT expected entity string.
# "1" or undef would fail the is() equality check.
# ---------------------------------------------------------------------------
subtest 'BOOL_NEGATE/RETURN_UNDEF_524: final return value of wide_to_html' => sub {
	plan tests => 3;

	my $result = wide_to_html(string => $E_ACUTE);
	is($result, '&eacute;',
		'e-acute -> &eacute; exact match (kills negate/undef mutations at line 524)');
	ok(defined($result),
		'result is defined (kills RETURN_UNDEF_524_2)');
	isnt($result, '1',
		'result is not boolean 1 (kills BOOL_NEGATE_524_2)');
};

# ---------------------------------------------------------------------------
# 8. COND_INV_604_2 -- undefined-string guard in wide_to_xml (line 604)
#
# Same structure as #2 but for wide_to_xml.  Note the die message differs.
# ---------------------------------------------------------------------------
subtest 'COND_INV_604_2: undef-string guard in wide_to_xml' => sub {
	plan tests => 2;

	throws_ok { wide_to_xml(string => undef) }
		qr/Usage: wide_to_xml\(\) string not set/,
		'undef string triggers die in wide_to_xml (true-branch confirmed)';

	lives_ok { wide_to_xml(string => 'x') }
		'defined string does not die (kills COND_INV_604_2 mutation)';
};

# ---------------------------------------------------------------------------
# 9. COND_INV_612_2 -- scalar-ref deref in wide_to_xml (line 612)
# ---------------------------------------------------------------------------
subtest 'COND_INV_612_2: scalar-ref is dereferenced in wide_to_xml' => sub {
	plan tests => 1;

	my $s = $E_ACUTE;
	is(wide_to_xml(string => \$s), wide_to_xml(string => $s),
		'scalar-ref and plain-string produce identical output in xml (kills COND_INV_612_2)');
};

# ---------------------------------------------------------------------------
# 10. COND_INV_645_2 -- keep_hrefs gate in wide_to_xml (line 645)
# ---------------------------------------------------------------------------
subtest 'COND_INV_645_2: keep_hrefs controls angle-bracket escaping in wide_to_xml' => sub {
	plan tests => 2;

	Readonly::Scalar my $TAG => '<item/>';

	like(wide_to_xml(string => $TAG),
		qr/&lt;item/,
		'no keep_hrefs: angle brackets escaped in xml');
	like(wide_to_xml(string => $TAG, keep_hrefs => 1),
		qr/<item/,
		'keep_hrefs=1: angle brackets preserved in xml (mutation reverses this)');
};

# ---------------------------------------------------------------------------
# 11. COND_INV_715_2 + BOOL_NEGATE_716_3 + RETURN_UNDEF_716_3
#     -- ASCII early-return in wide_to_xml (lines 715-716)
# ---------------------------------------------------------------------------
subtest 'COND_INV_715_2 + BOOL_NEGATE/RETURN_UNDEF_716: ASCII early-return in wide_to_xml' => sub {
	plan tests => 3;

	Readonly::Scalar my $ASCII => 'plain xml 42';

	my $result = wide_to_xml(string => $ASCII);
	is($result, $ASCII,
		'pure ASCII returned unchanged from wide_to_xml (exact match)');
	ok(defined($result),
		'result is defined (kills RETURN_UNDEF_716_3)');
	isnt($result, '',
		'result is not empty string (kills BOOL_NEGATE_716_3)');
};

# ---------------------------------------------------------------------------
# 12. COND_INV_927_2 -- BUG-die check in wide_to_xml (line 927)
#
# Normal:   if($string =~ /[^[:ascii:]]/) -- fires only when non-ASCII SURVIVES maps.
# Mutation: unless($string =~ /[^[:ascii:]]/) -- fires when string IS pure ASCII,
#           i.e., after every successful conversion!
#
# Kill A: a mapped char (e-acute) must convert without dying.
#   Without mutation: post-map string is pure ASCII, condition false, no die.
#   With mutation:    post-map string is pure ASCII, unless(0)=true, BUG-die fires.
#   The lives_ok + is() together catch this.
#
# Kill B: a genuinely unmapped char (Cyrillic A) MUST trigger BUG-die.
#   Without mutation: non-ASCII survives maps, condition true, die fires.
#   With mutation:    non-ASCII survives, unless(1)=false, die SKIPPED, raw char returned.
#   The throws_ok catches the missing die in the mutant case.
# ---------------------------------------------------------------------------
subtest 'COND_INV_927_2: BUG-die check for unmapped chars in wide_to_xml' => sub {
	plan tests => 3;

	# Kill A: mapped char must convert without dying (mutation causes every conversion to die)
	my $result;
	lives_ok { $result = wide_to_xml(string => $E_ACUTE) }
		'mapped char does not trigger BUG-die in wide_to_xml (kills mutation where die fires on pure-ASCII)';
	is($result, '&#x0E9;',
		'e-acute -> &#x0E9; (exact output confirms correct path taken)');

	# Kill B: unmapped char must trigger BUG-die (mutation skips die for non-ASCII)
	throws_ok { wide_to_xml(string => $CYRILLIC) }
		qr/BUG: wide_to_xml/,
		'unmapped Cyrillic A triggers BUG-die (kills mutation where die is skipped for non-ASCII)';
};

# ---------------------------------------------------------------------------
# 13. BOOL_NEGATE_946_2 + RETURN_UNDEF_946_2 -- final return of wide_to_xml (line 946)
#
# The return at line 946 is the normal exit of wide_to_xml after all maps succeed.
# Mutation: return $string → return !$string (→ "1") or return undef.
# Kill: exact entity string expected; "1" or undef diverges.
# ---------------------------------------------------------------------------
subtest 'BOOL_NEGATE/RETURN_UNDEF_946: final return value of wide_to_xml' => sub {
	plan tests => 3;

	my $result = wide_to_xml(string => $Z_CARON);
	is($result, '&#x17E;',
		'z-caron -> &#x17E; exact match (kills negate/undef mutations at line 946)');
	ok(defined($result),
		'result is defined (kills RETURN_UNDEF_946_2)');
	isnt($result, '1',
		'result is not boolean 1 (kills BOOL_NEGATE_946_2)');
};

# ---------------------------------------------------------------------------
# 14. BOOL_NEGATE_966_2 + RETURN_UNDEF_966_2 -- _sub_map return value (line 966)
#
# _sub_map is the internal byte-map engine used by both functions.
# Mutation: return $string → return !$string (→ "1" or "") or return undef.
# Effect:  ALL byte_map substitutions in both functions would produce "1"/undef
#          instead of the processed string, breaking every single conversion.
#
# Kill: any end-to-end conversion through a byte_map path fails if _sub_map
# returns wrong value.  We test both functions to catch the mutation regardless
# of which call path is exercised first.
# ---------------------------------------------------------------------------
subtest 'BOOL_NEGATE/RETURN_UNDEF_966: _sub_map internal return value' => sub {
	plan tests => 4;

	my $html = wide_to_html(string => $E_ACUTE);
	is($html, '&eacute;',
		'wide_to_html via _sub_map returns correct entity (kills negate/undef at line 966)');
	ok(defined($html), '_sub_map result is defined for html path');

	my $xml = wide_to_xml(string => $E_ACUTE);
	is($xml, '&#x0E9;',
		'wide_to_xml via _sub_map returns correct entity (kills negate/undef at line 966)');
	ok(defined($xml), '_sub_map result is defined for xml path');
};

done_testing();
