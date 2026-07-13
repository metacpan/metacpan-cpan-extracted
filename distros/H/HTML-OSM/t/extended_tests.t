#!/usr/bin/env perl

# Extended coverage tests for HTML::OSM targeting execution paths that are not
# exercised by the existing suite (function.t / unit.t / edge_cases.t).
# Strategy: identify every conditional branch in OSM.pm, confirm which are
# already hit, and write the smallest subtest that hits each remaining one.
# LCSAJ focus areas:
#   _html_json()          — never tested directly anywhere
#   logger callbacks      — add_marker / center / onload_render all have
#                           logger->error paths that were never exercised
#   all-invalid-coords    — onload_render "center() must be called" croak
#                           distinct from the "No map data provided" croak
#   icon + cluster        — onload_render icon branch with cluster=1
#   geocoder HASH escapes — {lat,lon} missing/partial, falls to carp
#   HTTP HASH response    — Nominatim direct-hash (not array-wrapped) path
#   HTTP no-lat           — 200 OK but response data lacks a lat field
#   HTTP invalid JSON     — 200 OK but body is not JSON (bug fix: now carp+undef)
#   rate-limit sleep      — Time::HiRes::sleep call when min_interval violated
#   key-value API styles  — zoom(zoom=>N) and add_marker(point=>[…]) branches
#   _validate edge cases  — explicit + prefix, whitespace in coord string
#   onload_render misc    — custom width/height, idempotency, height/width fallback
#   _js_string edge cases — standalone CR, Unicode pass-through
#   add_marker tuple      — html AND icon both stored in correct tuple slots
#   GeoJSON popup escaping — popup property name JS-escaped in rendered output

use strict;
use warnings;

use Readonly;
use Scalar::Util qw(blessed);
use Test::Mockingbird qw(mock restore_all);
use Test::Most;
use Test::Returns;
use Time::HiRes qw(time);

BEGIN { use_ok('HTML::OSM') }

Readonly my %C => (
	ZOOM_DEFAULT => 12,
	LAT_LONDON   => 51.5074,
	LON_LONDON   => -0.1278,
	LAT_PARIS    => 48.8566,
	LON_PARIS    =>  2.3522,
);

my $SILENCE = sub { };

# ── Global HTTP block ─────────────────────────────────────────────────────────
# Unique class names (EXT prefix) avoid collisions with other test files.
# NEVER call restore_all() inside a subtest — it removes this block.
{
	my $fail_resp = bless {}, 'EXTNetResp';
	mock 'EXTNetResp::is_success' => sub { 0 };
	my $fail_ua   = bless {}, 'EXTNetUA';
	mock 'EXTNetUA::default_header' => sub { };
	mock 'EXTNetUA::env_proxy'      => sub { };
	mock 'EXTNetUA::get'            => sub { $fail_resp };
	mock 'LWP::UserAgent::new'      => sub { $fail_ua };
}

# ─────────────────────────────────────────────────────────────────────────────
# 1. _html_json() — private function, never directly tested anywhere
#    All JSON embedded in <script> blocks must have </  escaped to <\/
#    to prevent the tag from closing the enclosing <script> element.
# ─────────────────────────────────────────────────────────────────────────────

subtest '_html_json: plain hashref produces valid JSON' => sub {
	my $json = HTML::OSM::_html_json({ color => 'red', weight => 2 });
	like($json, qr/"color"/, 'key present in output');
	like($json, qr/"red"/,   'value present in output');
	returns_ok($json, { type => 'string' }, 'return type is string');
};

subtest '_html_json: </script> in value is escaped to <\\/' => sub {
	# encode_json does NOT escape / by default, so "</script>" would close the
	# enclosing <script> block.  _html_json must post-process it.
	my $json = HTML::OSM::_html_json({ x => '</script>' });
	unlike($json, qr|</script>|,   'raw </script> not present in output');
	like($json,   qr|<\\/script>|, 'escaped form <\\/script> is present');
};

subtest '_html_json: arrayref input encodes to JSON array' => sub {
	my $json = HTML::OSM::_html_json([1, 2, 3]);
	is($json, '[1,2,3]', 'arrayref becomes JSON array literal');
};

subtest '_html_json: nested </script> at multiple nesting levels all escaped' => sub {
	# Nested structure — both levels must be post-processed.
	my $json = HTML::OSM::_html_json({ a => { b => '</script>' } });
	unlike($json, qr|</script>|, 'no raw </script> at any depth');
};

subtest '_html_json: empty hashref encodes to {}' => sub {
	is(HTML::OSM::_html_json({}), '{}', 'empty hashref → {}');
};

# ─────────────────────────────────────────────────────────────────────────────
# 2. Logger injection — all three logger->error call sites
#    The logger is a user-supplied object.  The module calls $logger->error(msg)
#    just before croaking.  We verify the message is forwarded.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'add_marker: logger->error forwarded for unknown ref type, then croaks' => sub {
	# Object::Configure always injects a Log::Abstraction default logger, so we
	# replace it directly on the object to intercept the ->error() call.
	my @msgs;
	my $logger = bless {}, 'EXTLog1';
	mock 'EXTLog1::error' => sub { push @msgs, $_[1] };

	my $m = HTML::OSM->new();
	$m->{logger} = $logger;    # replace injected default

	# Pass the unknown-ref object as the named 'point' param so it reaches
	# the unknown-type dispatch (not the positional-arg else branch).
	my $bad = bless {}, 'EXTBadRef1';
	throws_ok { $m->add_marker(point => $bad) }
		qr/add_marker\(\): unknown point type: EXTBadRef1/,
		'croak message correct';
	is(scalar @msgs, 1,            'logger->error called exactly once');
	like($msgs[0], qr/EXTBadRef1/, 'error message contains the ref type');
};

subtest 'center: logger->error forwarded for unknown ref type, then croaks' => sub {
	my @msgs;
	my $logger = bless {}, 'EXTLog2';
	mock 'EXTLog2::error' => sub { push @msgs, $_[1] };

	my $m = HTML::OSM->new();
	$m->{logger} = $logger;

	my $bad = bless {}, 'EXTBadRef2';
	throws_ok { $m->center($bad) }
		qr/center\(\): unknown point type: EXTBadRef2/,
		'croak message correct';
	is(scalar @msgs, 1,            'logger->error called exactly once');
	like($msgs[0], qr/EXTBadRef2/, 'error message contains the ref type');
};

subtest 'onload_render: logger->error forwarded when no map data, then croaks' => sub {
	my @msgs;
	my $logger = bless {}, 'EXTLog3';
	mock 'EXTLog3::error' => sub { push @msgs, $_[1] };

	my $m = HTML::OSM->new();
	$m->{logger} = $logger;

	throws_ok { $m->onload_render() }
		qr/No map data provided/,
		'croak message correct';
	is(scalar @msgs, 1,                      'logger->error called exactly once');
	like($msgs[0], qr/No map data provided/, 'error message matches croak');
};

# ─────────────────────────────────────────────────────────────────────────────
# 3. onload_render() — all pre-seeded coordinates fail _validate
#    When @$coordinates is non-empty but every entry is invalid,
#    @valid_coordinates ends up empty and no center can be computed.
#    This triggers "center() must be called …", NOT "No map data provided".
#    The two error messages are distinct code paths and must be tested separately.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'onload_render: all pre-seeded coordinates invalid → center() croak, not no-data croak' => sub {
	my $m = HTML::OSM->new();
	# Bypass add_marker validation by directly setting $self->{coordinates}.
	# All coordinates are out-of-range; _validate will discard them.
	$m->{coordinates} = [
		[999,  999,  'BadA', undef],
		[-999, -999, 'BadB', undef],
	];
	local $SIG{__WARN__} = $SILENCE;    # suppress _validate carps
	throws_ok { $m->onload_render() }
		qr/center\(\) must be called when no point markers are provided/,
		'all-invalid-coords: croak is about center, not about no data';
};

# ─────────────────────────────────────────────────────────────────────────────
# 4. onload_render() — icon marker with cluster=1
#    There are three branches for each marker in the render loop:
#      (a) icon_url && !cluster  → m.addTo(map)               [tested elsewhere]
#      (b) icon_url &&  cluster  → clusterGroup.addLayer(m)   [THIS test]
#      (c) !icon_url &&  cluster → clusterGroup.addLayer(L.marker(...))  [tested elsewhere]
#      (d) !icon_url && !cluster → L.marker(...).addTo(map)   [tested elsewhere]
# ─────────────────────────────────────────────────────────────────────────────

subtest 'onload_render: icon + cluster=1 uses clusterGroup.addLayer(m)' => sub {
	my $m = HTML::OSM->new(cluster => 1);
	$m->add_marker(
		[$C{LAT_LONDON}, $C{LON_LONDON}],
		html => 'London',
		icon => 'https://example.com/pin.png',
	);
	my (undef, $body) = $m->onload_render();
	like($body,   qr/clusterGroup\.addLayer\(m\)/, 'icon+cluster: uses clusterGroup.addLayer(m)');
	like($body,   qr/L\.icon/,                     'L.icon call still emitted');
	unlike($body, qr/m\.addTo\(map\)/,             'm.addTo(map) NOT used in cluster mode');
};

# ─────────────────────────────────────────────────────────────────────────────
# 5. _fetch_coordinates() — geocoder returns a HASH with no lat/lon/geometry
#    Branch: ref($rc) eq 'HASH' → lat/lon check fails → geometry check fails
#    → exits HASH block → ref($rc) eq 'ARRAY' fails → carp "unrecognised HASH"
#    This is distinct from the "unrecognised type" path tested in function.t
#    (which uses a blessed scalar ref, not an unrecognised HASH).
# ─────────────────────────────────────────────────────────────────────────────

subtest '_fetch_coordinates: geocoder HASH with neither lat/lon nor geometry → carp unrecognised HASH' => sub {
	my $m = HTML::OSM->new();
	mock 'EXTGeoHashOnly::geocode' => sub { { display_name => 'London' } };
	$m->{geocoder} = bless {}, 'EXTGeoHashOnly';

	my ($lat, $lon);
	warning_like {
		($lat, $lon) = $m->_fetch_coordinates('London');
	} qr/_fetch_coordinates: unrecognised geocoder result type: HASH/,
	  'carp emitted when HASH result has no lat/lon or geometry';
	ok(!defined $lat, 'lat is undef');
	ok(!defined $lon, 'lon is undef');
};

# ─────────────────────────────────────────────────────────────────────────────
# 6. _fetch_coordinates() — geocoder returns HASH with lat defined but lon undef
#    Branch: defined(lat) && defined(lon) → TRUE && FALSE → FALSE
#    → geometry check → undef → exits HASH block → carp "unrecognised HASH"
# ─────────────────────────────────────────────────────────────────────────────

subtest '_fetch_coordinates: geocoder HASH with lat defined but lon undef → carp unrecognised HASH' => sub {
	my $m = HTML::OSM->new();
	mock 'EXTGeoLatOnly::geocode' => sub {
		{ lat => $C{LAT_LONDON}, lon => undef }
	};
	$m->{geocoder} = bless {}, 'EXTGeoLatOnly';

	my ($lat, $lon);
	warning_like {
		($lat, $lon) = $m->_fetch_coordinates('London');
	} qr/_fetch_coordinates: unrecognised geocoder result type: HASH/,
	  'carp emitted when lon is undef in geocoder HASH result';
	ok(!defined $lat, 'lat is undef');
	ok(!defined $lon, 'lon is undef');
};

# ─────────────────────────────────────────────────────────────────────────────
# 7. _fetch_coordinates() — HTTP success with HASH (not array-wrapped) response
#    Branch: $data = decode_json(...) → HASH → ref($data) eq 'ARRAY' = FALSE
#    → $data unchanged → ref($data) eq 'HASH' && defined($data->{lat}) → returns
#    All existing HTTP success tests use the Nominatim array format [{"lat":…}].
#    Nominatim itself sometimes returns a bare hash for specific queries;
#    the module must handle both.
# ─────────────────────────────────────────────────────────────────────────────

subtest '_fetch_coordinates: HTTP success with direct HASH JSON response (no array wrapper)' => sub {
	my $m    = HTML::OSM->new();
	my $json = '{"lat":"48.8566","lon":"2.3522","display_name":"Paris, France"}';

	my $resp = bless {}, 'EXTHTTPHashResp';
	mock 'EXTHTTPHashResp::is_success'      => sub { 1 };
	mock 'EXTHTTPHashResp::decoded_content' => sub { $json };
	my $ua = bless {}, 'EXTHTTPHashUA';
	mock 'EXTHTTPHashUA::default_header' => sub { };
	mock 'EXTHTTPHashUA::env_proxy'      => sub { };
	mock 'EXTHTTPHashUA::get'            => sub { $resp };
	$m->{ua} = $ua;

	my ($lat, $lon) = $m->_fetch_coordinates('Paris');
	is($lat, '48.8566', 'lat extracted from direct HASH HTTP response');
	is($lon, '2.3522',  'lon extracted from direct HASH HTTP response');
};

# ─────────────────────────────────────────────────────────────────────────────
# 8. _fetch_coordinates() — HTTP success but response data has no lat field
#    Branch: ref($data) eq 'HASH' && defined($data->{lat}) → FALSE → returns (undef, undef)
# ─────────────────────────────────────────────────────────────────────────────

subtest '_fetch_coordinates: HTTP 200 but no lat field in response data → (undef, undef)' => sub {
	my $m    = HTML::OSM->new();
	my $json = '[{"error":"Place not found","importance":0}]';

	my $resp = bless {}, 'EXTHTTPNoLatResp';
	mock 'EXTHTTPNoLatResp::is_success'      => sub { 1 };
	mock 'EXTHTTPNoLatResp::decoded_content' => sub { $json };
	my $ua = bless {}, 'EXTHTTPNoLatUA';
	mock 'EXTHTTPNoLatUA::default_header' => sub { };
	mock 'EXTHTTPNoLatUA::env_proxy'      => sub { };
	mock 'EXTHTTPNoLatUA::get'            => sub { $resp };
	$m->{ua} = $ua;

	my ($lat, $lon) = $m->_fetch_coordinates('Imaginaryland');
	ok(!defined $lat, 'lat is undef when no lat field in 200 response');
	ok(!defined $lon, 'lon is undef when no lat field in 200 response');
};

# ─────────────────────────────────────────────────────────────────────────────
# 9. _fetch_coordinates() — HTTP 200 but response body is not valid JSON
#    Bug fixed in this session: decode_json would die uncaught; now wrapped in
#    eval with carp+return (undef, undef) so callers are not surprised.
# ─────────────────────────────────────────────────────────────────────────────

subtest '_fetch_coordinates: HTTP 200 with non-JSON body carps and returns (undef, undef)' => sub {
	my $m = HTML::OSM->new();

	my $resp = bless {}, 'EXTHTTPBadJSONResp';
	mock 'EXTHTTPBadJSONResp::is_success'      => sub { 1 };
	mock 'EXTHTTPBadJSONResp::decoded_content' => sub {
		'<html>Rate limit exceeded, please slow down.</html>'
	};
	my $ua = bless {}, 'EXTHTTPBadJSONUA';
	mock 'EXTHTTPBadJSONUA::default_header' => sub { };
	mock 'EXTHTTPBadJSONUA::env_proxy'      => sub { };
	mock 'EXTHTTPBadJSONUA::get'            => sub { $resp };
	$m->{ua} = $ua;

	my ($lat, $lon);
	# Must not die — the eval guard catches the JSON parse error.
	warning_like {
		($lat, $lon) = $m->_fetch_coordinates('London');
	} qr/failed to decode Nominatim response/,
	  'carp emitted for unparseable HTTP body';
	ok(!defined $lat, 'lat is undef after parse failure');
	ok(!defined $lon, 'lon is undef after parse failure');
};

# ─────────────────────────────────────────────────────────────────────────────
# 10. _fetch_coordinates() — rate-limit sleep branch
#     Branch: elapsed < min_interval → Time::HiRes::sleep(remaining) called.
#     We set last_request to a "future" timestamp so elapsed is negative (always
#     < any positive min_interval), confirm sleep is called with the right delta.
# ─────────────────────────────────────────────────────────────────────────────

subtest '_fetch_coordinates: sleep called when min_interval not yet elapsed' => sub {
	Readonly my $INTERVAL => 60;

	my @sleep_args;
	mock 'Time::HiRes::sleep' => sub { push @sleep_args, $_[0] };

	# HTTP mock that returns a valid geocoded result.
	my $json  = '[{"lat":"51.5074","lon":"-0.1278"}]';
	my $resp  = bless {}, 'EXTRLResp';
	mock 'EXTRLResp::is_success'      => sub { 1 };
	mock 'EXTRLResp::decoded_content' => sub { $json };
	my $ua = bless {}, 'EXTRLUA';
	mock 'EXTRLUA::default_header' => sub { };
	mock 'EXTRLUA::env_proxy'      => sub { };
	mock 'EXTRLUA::get'            => sub { $resp };

	my $m = HTML::OSM->new(min_interval => $INTERVAL, ua => $ua);
	# Pretend the last request happened "now + 30 seconds in the future".
	# elapsed = current_time - last_request ≈ current - (current + 30) = -30
	# -30 < 60 → sleep(60 - (-30)) = sleep(90)
	$m->{last_request} = time() + 30;

	$m->_fetch_coordinates('London');

	ok(scalar @sleep_args > 0, 'sleep was called when min_interval not elapsed');
	cmp_ok($sleep_args[0], '>', 0, 'sleep duration is positive');
	diag("slept for $sleep_args[0] simulated seconds") if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# 11. zoom() — key-value calling style: zoom(zoom => N)
#     Params::Get::get_params('zoom', \@_) handles both positional (zoom(14))
#     and named (zoom(zoom => 14)).  The named form has never been tested.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'zoom: key-value style zoom(zoom => N) accepted' => sub {
	my $m = HTML::OSM->new();
	my $z = $m->zoom(zoom => 7);
	is($z,        7, 'key-value setter returns new zoom level');
	is($m->zoom(), 7, 'getter confirms zoom stored correctly');
};

# ─────────────────────────────────────────────────────────────────────────────
# 12. add_marker() — key-value style: add_marker(point => [lat, lon], …)
#     The else-branch fires when the first arg is a plain string AND the total
#     arg count is even — i.e. add_marker(point => $val, html => $label).
#     The result is identical to the positional arrayref form but uses a
#     distinct code path (Params::Get extracts 'point' by name).
# ─────────────────────────────────────────────────────────────────────────────

subtest 'add_marker: key-value point => [lat, lon] style works correctly' => sub {
	my $m = HTML::OSM->new();
	my $r = $m->add_marker(
		point => [$C{LAT_LONDON}, $C{LON_LONDON}],
		html  => 'London',
	);
	is($r, 1, 'key-value add_marker returns 1');
	is($m->{coordinates}[0][0], $C{LAT_LONDON}, 'lat stored correctly');
	is($m->{coordinates}[0][1], $C{LON_LONDON}, 'lon stored correctly');
	is($m->{coordinates}[0][2], 'London',        'html label stored correctly');
};

# ─────────────────────────────────────────────────────────────────────────────
# 13. _validate() — explicit + sign prefix
#     The regex ^-?(?:…)$ allows an optional leading minus but NOT a leading plus.
#     "+51.5" must be rejected.  This is an obscure but real case: some geocoder
#     libraries prefix positive coords with + and a module user might pass them.
# ─────────────────────────────────────────────────────────────────────────────

subtest '_validate: explicit + prefix is rejected (regex only allows optional -)' => sub {
	local $SIG{__WARN__} = $SILENCE;
	is(HTML::OSM::_validate('+51.5', '-0.1'), 0, '+lat rejected');
	is(HTML::OSM::_validate('51.5', '+0.1'),  0, '+lon rejected');
	is(HTML::OSM::_validate('+0',   '+0'),    0, 'both +0 rejected');
};

# ─────────────────────────────────────────────────────────────────────────────
# 14. _validate() — whitespace in coordinate strings
#     The anchored regex requires the entire string to match.  Leading or
#     trailing whitespace must be rejected; accepting "51.5 " would produce
#     malformed JavaScript when the value is embedded literally.
# ─────────────────────────────────────────────────────────────────────────────

subtest '_validate: leading or trailing whitespace in coord string is rejected' => sub {
	# Bug fixed: _validate now uses \z (not $) so a trailing \n is rejected.
	# With $, "0\n" matched because $ permits a final newline in Perl regex.
	# That would allow a newline-embedded coord to be inserted raw into JS output.
	local $SIG{__WARN__} = $SILENCE;
	is(HTML::OSM::_validate(' 51.5',  '-0.1'),  0, 'leading space in lat rejected');
	is(HTML::OSM::_validate('51.5',   ' -0.1'), 0, 'leading space in lon rejected');
	is(HTML::OSM::_validate("51.5\t", '0'),     0, 'trailing tab in lat rejected');
	is(HTML::OSM::_validate('51.5',   "0\n"),   0, 'trailing newline in lon now rejected (\\z fix)');
};

# ─────────────────────────────────────────────────────────────────────────────
# 15. onload_render() — custom width and height appear in the <style> block
#     width and height are interpolated directly into the CSS inside $head.
#     Default values (400px / 600px) are covered by other tests; this confirms
#     that non-default values are propagated correctly.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'onload_render: custom width and height appear in <style> block in head' => sub {
	my $m = HTML::OSM->new(width => '800px', height => '550px');
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	my ($head, undef) = $m->onload_render();
	like($head, qr/width:\s*800px/,  'custom width in CSS');
	like($head, qr/height:\s*550px/, 'custom height in CSS');
};

# ─────────────────────────────────────────────────────────────────────────────
# 16. onload_render() — height/width fallback when the stored value is falsy
#     The code uses `|| '400px'` / `|| '600px'`.  Setting the hash slots to ''
#     exercises the || fallback path without going through the constructor.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'onload_render: empty height/width strings fall back to defaults in CSS' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	# Bypass constructor to test the || fallback inside onload_render.
	$m->{height} = '';
	$m->{width}  = '';
	my ($head, undef) = $m->onload_render();
	like($head, qr/width:\s*600px/,  'default width (600px) used via || fallback');
	like($head, qr/height:\s*400px/, 'default height (400px) used via || fallback');
};

# ─────────────────────────────────────────────────────────────────────────────
# 17. onload_render() — idempotency
#     The method reads $self state and builds a string; it should not mutate
#     object state in a way that changes the output on subsequent calls.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'onload_render: calling twice produces identical output' => sub {
	my $m = HTML::OSM->new(zoom => 10);
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}], html => 'London');
	$m->add_marker([$C{LAT_PARIS},  $C{LON_PARIS}],  html => 'Paris');
	my ($head1, $body1) = $m->onload_render();
	my ($head2, $body2) = $m->onload_render();
	is($head1, $head2, 'head identical on second call (idempotent)');
	is($body1, $body2, 'body identical on second call (idempotent)');
};

# ─────────────────────────────────────────────────────────────────────────────
# 18. _js_string() — standalone CR without LF
#     The regex s/\r?\n/\\n/g requires a LF to match.  A bare \r (carriage
#     return only, as produced by old Mac line endings) is NOT replaced.
#     This documents current behavior; a future hardening pass might change it.
# ─────────────────────────────────────────────────────────────────────────────

subtest '_js_string: standalone CR (without LF) is NOT escaped' => sub {
	my $got = HTML::OSM::_js_string("a\rb");
	is($got, "a\rb", 'standalone \\r passes through unchanged (no LF → no match)');
};

# ─────────────────────────────────────────────────────────────────────────────
# 19. _js_string() — Unicode characters pass through unchanged
#     _js_string escapes backslash, single quote, CRLF/LF, and </script>.
#     It must NOT mangle multi-byte Unicode sequences.
# ─────────────────────────────────────────────────────────────────────────────

subtest '_js_string: Unicode characters pass through without alteration' => sub {
	# U+4E2D U+6587 = "中文" (Chinese). U+00E9 = "é" (Latin-1 supplement).
	my $chinese = "\x{4e2d}\x{6587}";
	my $accented = "caf\x{e9}";
	is(HTML::OSM::_js_string($chinese),  $chinese,  'CJK characters unchanged');
	is(HTML::OSM::_js_string($accented), $accented, 'accented Latin unchanged');
};

# ─────────────────────────────────────────────────────────────────────────────
# 20. add_marker() — html AND icon both provided
#     The coordinate tuple is [lat, lon, label, icon_url].  When both html and
#     icon params are supplied, both must land in the correct slots.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'add_marker: html and icon both stored in correct tuple slots' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker(
		[$C{LAT_LONDON}, $C{LON_LONDON}],
		html => 'London',
		icon => 'https://example.com/pin.png',
	);
	my $t = $m->{coordinates}[0];
	is($t->[2], 'London',                   'html in tuple slot [2]');
	is($t->[3], 'https://example.com/pin.png', 'icon in tuple slot [3]');
};

# ─────────────────────────────────────────────────────────────────────────────
# 21. onload_render() — GeoJSON popup property name JS-escaped
#     The property name passed to popup => '…' is interpolated via _js_string
#     into the onEachFeature callback.  A single quote in the prop name would
#     break the JS string if not escaped.
# ─────────────────────────────────────────────────────────────────────────────

subtest "onload_render: GeoJSON popup property name with single quote is JS-escaped" => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->add_geojson(
		{ type => 'FeatureCollection', features => [] },
		popup => "o'malley",    # property name containing a single quote
	);
	my (undef, $body) = $m->onload_render();
	unlike($body, qr/properties\['o'malley'\]/, "raw quote not in property name");
	like($body,   qr/o\\'malley/,               "quote escaped in popup property name");
};

# ─────────────────────────────────────────────────────────────────────────────
# 22. onload_render() — choropleth key name JS-escaped in rendered callback
#     The choropleth key (feature property name used for lookup) passes through
#     _js_string before embedding.  A quote in the key would break the JS.
# ─────────────────────────────────────────────────────────────────────────────

subtest "onload_render: choropleth key with single quote is JS-escaped" => sub {
	my $m = HTML::OSM->new();
	$m->center([$C{LAT_LONDON}, $C{LON_LONDON}]);
	$m->add_choropleth(
		[{ type => 'Feature', properties => { "prop'name" => 'X' },
		   geometry => { type => 'Point', coordinates => [0,0] } }],
		{ X => 100 },
		key => "prop'name",
	);
	my (undef, $body) = $m->onload_render();
	like($body, qr/prop\\'name/, "choropleth key with quote is JS-escaped in body");
};

# ─────────────────────────────────────────────────────────────────────────────
# 23. new() — function-style with undef-ish first arg
#     Calling HTML::OSM::new() function-style with no args detects that $class
#     is 'HTML::OSM' (not a blessed ref), proceeds through normal constructor.
#     Calling HTML::OSM::new(zoom => 5) — $class = 'zoom', which is not a
#     blessed ref and does not isa HTML::OSM — triggers the unshift path.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'new: function-style with args uses unshift path correctly' => sub {
	# 'zoom' is the first element: !blessed && !isa HTML::OSM → unshifted back.
	my $m = HTML::OSM::new(zoom => 8);
	isa_ok($m, 'HTML::OSM', 'function-style new with args returns HTML::OSM');
	is($m->zoom(), 8, 'zoom arg respected via function-style call');
};

# ─────────────────────────────────────────────────────────────────────────────
# 24. add_marker() — geo object with NO icon (icon slot is undef in tuple)
#     This confirms the tuple always has 4 slots even when icon is not supplied.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'add_marker: no icon supplied → tuple slot [3] is undef' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([$C{LAT_LONDON}, $C{LON_LONDON}], html => 'London');
	is(scalar @{$m->{coordinates}[0]}, 4,     'tuple always has 4 elements');
	ok(!defined $m->{coordinates}[0][3],       'icon slot [3] is undef when not supplied');
};

# ─────────────────────────────────────────────────────────────────────────────
# 25. center() — [lat, lon] with undef elements returns 0 without storing
#     Exercises the `return 0 unless defined($lat) && defined($lon)` guard
#     inside center() for the ARRAY path specifically.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'center: [undef, undef] arrayref returns 0 and does not store center' => sub {
	my $m = HTML::OSM->new();
	is($m->center([undef, undef]), 0, 'returns 0');
	ok(!defined $m->{center}, 'center not stored on failure');
};

restore_all();
done_testing();
