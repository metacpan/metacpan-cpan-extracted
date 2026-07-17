#!/usr/bin/env perl
# Security regression tests for Encode::Wide.
# Covers the four vulnerabilities identified in the static security audit:
#   1. XSS via HTML::Entities::decode + keep_hrefs => 1
#   2. ReDoS via O(n^2) backtracking in the &amp; substitution
#   3. Removal of /e eval from _sub_map
#   4. Removal of /e eval from keep_hrefs substitutions

use strict;
use warnings;

use Test::Most tests => 12;
use Time::HiRes qw(time);

use Encode::Wide qw(wide_to_html wide_to_xml);

# ---------------------------------------------------------------------------
# 1. XSS — HTML::Entities::decode must NOT decode when keep_hrefs => 1
# ---------------------------------------------------------------------------
# If decode() runs before the keep_hrefs gate, encoded payloads like
# &lt;script&gt; become literal <script> and then bypass re-escaping.

subtest 'XSS: keep_hrefs suppresses entity-decode in wide_to_html' => sub {
	plan tests => 4;

	# Encoded XSS payload that must stay encoded in the output
	my $payload = '&lt;script&gt;alert(1)&lt;/script&gt;';
	my $out = wide_to_html(string => $payload, keep_hrefs => 1);

	unlike $out, qr/<script>/i,  'no raw <script> tag in output';
	unlike $out, qr{</script>}i, 'no raw </script> tag in output';
	like   $out, qr/&lt;/,       '&lt; preserved';
	like   $out, qr/&gt;/,       '&gt; preserved';
};

subtest 'XSS: keep_hrefs suppresses entity-decode in wide_to_xml' => sub {
	plan tests => 3;

	my $payload = '&lt;img src=x onerror=alert(1)&gt;';
	my $out = wide_to_xml(string => $payload, keep_hrefs => 1);

	# The word "onerror" will still appear in the output as text within the encoded
	# entity sequence -- that is safe.  What must NOT appear is a raw <img> tag.
	unlike $out, qr/<img/i, 'no raw <img tag in output';
	like   $out, qr/&lt;/,  '&lt; preserved (not decoded to <)';
	like   $out, qr/&gt;/,  '&gt; preserved (not decoded to >)';
};

subtest 'XSS: without keep_hrefs, decode+re-escape still produces safe output' => sub {
	plan tests => 2;

	# Without keep_hrefs the decode->re-escape round-trip is fine:
	# &lt;script&gt; -> <script> -> &lt;script&gt;
	my $out = wide_to_html(string => '&lt;script&gt;');
	unlike $out, qr/<script>/i, 'no raw tag even after decode+re-escape';
	like   $out, qr/&lt;/,      '&lt; appears in output';
};

subtest 'XSS: encoded img-onerror vector, no keep_hrefs' => sub {
	plan tests => 1;

	my $out = wide_to_html(string => '&lt;img src=x onerror=alert(1)&gt;');
	unlike $out, qr/<img/i, 'no raw <img in output';
};

# ---------------------------------------------------------------------------
# 2. ReDoS — possessive quantifier prevents catastrophic backtracking
#
# Strategy: pass a string of the form "&aaaaaa...X" (N ampersand-less chars
# after &, followed by a non-semicolon character) and time it.  With the old
# backtracking regex the runtime is O(n^2); with possessive ++ it is O(n).
# We pick N=1000 and assert it completes in under 1 second.
# ---------------------------------------------------------------------------
subtest 'ReDoS: wide_to_html & substitution does not backtrack on adversarial input' => sub {
	plan tests => 2;

	# Adversarial input: & followed by 1000 alpha chars and no semicolon.
	# The regex must NOT backtrack through all 1000 positions.
	my $adversarial = '&' . ('a' x 1000) . 'X';
	my $t0  = time();
	my $out = wide_to_html(string => $adversarial);
	my $elapsed = time() - $t0;

	like $out, qr/&amp;/, 'bare & was encoded to &amp;';
	cmp_ok $elapsed, '<', 1, 'completed in under 1 second (no O(n^2) backtracking)';
};

subtest 'ReDoS: wide_to_xml & substitution does not backtrack on adversarial input' => sub {
	plan tests => 2;

	my $adversarial = '&' . ('a' x 1000) . 'X';
	my $t0  = time();
	my $out = wide_to_xml(string => $adversarial);
	my $elapsed = time() - $t0;

	like $out, qr/&amp;/, 'bare & was encoded to &amp;';
	cmp_ok $elapsed, '<', 1, 'completed in under 1 second (no O(n^2) backtracking)';
};

# ---------------------------------------------------------------------------
# 3. /e eval removal — _sub_map hash lookup must still produce correct output
#
# These tests exercise _sub_map indirectly through the public API.
# If /e were still present, a crafted key containing Perl code would be
# executed; without /e the replacement is a plain hash value.
# ---------------------------------------------------------------------------
subtest '_sub_map: standard multi-byte UTF-8 conversion still works after /e removal' => sub {
	plan tests => 3;

	is wide_to_html(string => "\x{E9}"),     '&eacute;', 'e-acute HTML';
	is wide_to_html(string => "\x{E0}"),     '&agrave;', 'a-grave HTML';
	is wide_to_html(string => "\x{2013}"),   '&ndash;',  'en-dash HTML';
};

subtest '_sub_map: XML numeric entities correct after /e removal' => sub {
	plan tests => 3;

	# The module zero-pads to 3 hex digits (&#x0E9;, not &#xE9;)
	is wide_to_xml(string => "\x{E9}"),   '&#x0E9;',  'e-acute XML';
	is wide_to_xml(string => "\x{E0}"),   '&#x0E0;',  'a-grave XML';
	is wide_to_xml(string => "\x{A3}"),   '&#x0A3;',  'pound sign XML';
};

# ---------------------------------------------------------------------------
# 4. keep_hrefs substitution — %_HTML_ESCAPE hash replaces /e eval
# ---------------------------------------------------------------------------
subtest 'keep_hrefs=0: < > " are escaped without /e eval' => sub {
	plan tests => 3;

	is wide_to_html(string => '<'),  '&lt;',   '< escaped';
	is wide_to_html(string => '>'),  '&gt;',   '> escaped';
	is wide_to_html(string => '"'),  '&quot;', '" escaped';
};

subtest 'keep_hrefs=1: < > " are NOT escaped (caller trusts HTML)' => sub {
	plan tests => 3;

	is wide_to_html(string => '<',  keep_hrefs => 1), '<',  '< preserved';
	is wide_to_html(string => '>',  keep_hrefs => 1), '>',  '> preserved';
	is wide_to_html(string => '"',  keep_hrefs => 1), '"',  '" preserved';
};

# ---------------------------------------------------------------------------
# 5. Apos_map — alternation regex replaces (.) /gex
# ---------------------------------------------------------------------------
subtest 'apos_map: ASCII apostrophe encoded without /e eval' => sub {
	plan tests => 3;

	is wide_to_html(string => "it's"),                  "it&apos;s",  "ASCII apostrophe encoded";
	is wide_to_html(string => "\x{2018}quoted\x{2019}"), '&apos;quoted&apos;', 'curly quotes encoded';
	is wide_to_html(string => "it's", keep_apos => 1),  "it's",       'keep_apos suppresses encoding';
};

subtest 'apos_map: grave accent treated as apostrophe' => sub {
	plan tests => 1;

	is wide_to_html(string => "`"),  '&apos;', 'grave accent (U+0060) encodes to &apos;';
};
