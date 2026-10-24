#!/usr/bin/env perl

# Tests for add_circle_marker()

use strict;
use warnings;

use Readonly;
use Scalar::Util ();
use Test::Most;
use Test::Mockingbird;
use HTML::OSM;

Readonly my %C => (
	LAT    => 51.5,
	LON    => -0.1,
	RADIUS => 20,
);

Readonly my $CIRCLE => qr/L\.circleMarker\(\[51\.5, -0\.1\], \{ radius: (\S+), color: '([^']*)', fillColor: '([^']*)', fillOpacity: 0\.7 \}\)/;

# Block accidental network calls
mock 'LWP::UserAgent::new' => sub {
	return bless {}, 'CM::FailUA';
};
{
	package CM::FailUA;
	sub get { die 'network access blocked in t/circle_marker.t' }
	sub default_header { }
	sub env_proxy { }
}
{
	package CM::Geocoder;
	sub new { return bless {}, shift }
	sub geocode { return { lat => 51.5, lon => -0.1 } }
}
{
	package CM::Point;
	sub new { return bless {}, shift }
	sub latitude { 51.5 }
	sub longitude { -0.1 }
}

# Render a map holding one circle added with %opts
sub one_circle
{
	my ($new_args, %opts) = @_;
	my $m = HTML::OSM->new(%{$new_args || {}});
	is($m->add_circle_marker([$C{LAT}, $C{LON}], %opts), 1, 'add_circle_marker returns 1');
	return ($m->onload_render())[1];
}

subtest 'basic circle with defaults' => sub {
	my $body = one_circle();
	like($body, $CIRCLE, 'L.circleMarker emitted');
	my ($radius, $color, $fill) = $body =~ $CIRCLE;
	is($radius, 8,         'default radius 8');
	is($color,  '#3388ff', 'default colour');
	is($fill,   '#3388ff', 'default fill colour');
	like($body, qr/fillOpacity: 0\.7 \}\)\.addTo\(map\);/, 'added straight to the map');
	unlike($body, qr/circleMarker[^\n]*bindPopup/, 'no popup without html');
};

subtest 'custom radius and colour' => sub {
	my $body = one_circle(undef, radius => $C{RADIUS}, colour => '#ff0000', html => 'London');
	my ($radius, $color, $fill) = $body =~ $CIRCLE;
	is($radius, 20,        'radius 20');
	is($color,  '#ff0000', 'colour');
	is($fill,   '#ff0000', 'fill colour');
	like($body, qr/fillOpacity: 0\.7 \}\)\.bindPopup\('London'\)\.addTo\(map\);/, 'popup bound');
};

subtest 'fractional radius' => sub {
	my $body = one_circle(undef, radius => sqrt(2) * 10);
	my ($radius) = $body =~ $CIRCLE;
	like($radius, qr/\A14\.14\d*\z/, 'fractional radius emitted with a dot');
};

subtest 'comma-decimal locale printing does not reach the radius' => sub {
	# Simulates perls that print numbers with the LC_NUMERIC decimal point
	my $body = one_circle(undef, radius => Scalar::Util::dualvar(12.5, '12,5'));
	my ($radius) = $body =~ $CIRCLE;
	is($radius, '12.5', 'radius written with a dot');
};

subtest 'colours are normalised to lower case' => sub {
	for my $in ('#f00', '#F00', '#FF0000', '#Ab12Cd') {
		my $body = one_circle(undef, colour => $in);
		my (undef, $color) = $body =~ $CIRCLE;
		is($color, lc($in), "$in stored as " . lc($in));
	}
};

subtest 'bad colours croak' => sub {
	my $m = HTML::OSM->new();
	for my $bad ('red', '#ff00', '#gggggg', 'ff0000', "#ff0000\n", "#f00'); alert(1); ('") {
		throws_ok { $m->add_circle_marker([$C{LAT}, $C{LON}], colour => $bad) }
			qr/add_circle_marker\(\): invalid colour: \Q$bad\E/, "'$bad' rejected";
	}
	throws_ok { $m->add_circle_marker([$C{LAT}, $C{LON}], colour => []) }
		qr/invalid colour/, 'ref rejected';
	ok(!$m->{circle_markers}, 'nothing stored');
};

subtest 'bad radii croak' => sub {
	my $m = HTML::OSM->new();
	for my $bad (0, -5, '-0.5', 'abc', '1e3', 1e6, '12; alert(1)') {
		throws_ok { $m->add_circle_marker([$C{LAT}, $C{LON}], radius => $bad) }
			qr/add_circle_marker\(\): radius must be a positive number/, "'$bad' rejected";
	}
};

subtest 'bad options croak even for a bad point' => sub {
	my $m = HTML::OSM->new();
	local $SIG{__WARN__} = sub { };
	throws_ok { $m->add_circle_marker([200, 0], radius => 0) } qr/radius/, 'radius checked';
};

subtest 'bad coordinates return 0' => sub {
	my $m = HTML::OSM->new();
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	is($m->add_circle_marker([200, 0]), 0, 'out-of-range latitude returns 0');
	like("@warnings", qr/Skipping invalid coordinate: \(200, 0\)/, 'warning given');
	is($m->add_circle_marker([1, 2, 3]), 0, 'three elements return 0');
	is($m->add_circle_marker(''), 0, 'empty address returns 0');
	ok(!$m->{circle_markers}, 'nothing stored');
};

subtest 'unknown point type croaks' => sub {
	my $m = HTML::OSM->new();
	throws_ok { $m->add_circle_marker(bless({}, 'CM::Nothing')) }
		qr/add_circle_marker\(\): unknown point type: CM::Nothing/, 'croaks with method name';
};

subtest 'address and object points' => sub {
	my $m = HTML::OSM->new();
	$m->{geocoder} = CM::Geocoder->new();
	is($m->add_circle_marker('London', radius => 5), 1, 'address accepted');
	is($m->add_circle_marker(CM::Point->new(), radius => 6), 1, 'object accepted');
	is($m->add_circle_marker(point => [$C{LAT}, $C{LON}], radius => 7), 1, 'key-value accepted');
	my (undef, $body) = $m->onload_render();
	is(() = $body =~ /L\.circleMarker\(\[51\.5, -0\.1\]/g, 3, 'three circles');
};

subtest 'clustering' => sub {
	my $body = one_circle({ cluster => 1 }, html => 'C');
	like($body, qr/var clusterGroup = L\.markerClusterGroup\(\);/, 'cluster group created for circle-only map');
	like($body, qr/clusterGroup\.addLayer\(L\.circleMarker\(/, 'circle added to cluster group');
	like($body, qr/map\.addLayer\(clusterGroup\);/, 'cluster group added to map');
	unlike($body, qr/circleMarker[^\n]*addTo\(map\)/, 'circle not added straight to the map');
};

subtest 'mixed pins and circles share one cluster group' => sub {
	my $m = HTML::OSM->new(cluster => 1);
	$m->add_marker([52, 0], html => 'HQ');
	$m->add_circle_marker([$C{LAT}, $C{LON}], html => 'Market');
	my (undef, $body) = $m->onload_render();
	is(() = $body =~ /L\.markerClusterGroup\(\)/g, 1, 'one cluster group');
	is(() = $body =~ /map\.addLayer\(clusterGroup\)/g, 1, 'added to the map once');
	like($body, qr/clusterGroup\.addLayer\(L\.marker\(\[52, 0\]\)/, 'pin in group');
	like($body, qr/clusterGroup\.addLayer\(L\.circleMarker\(/,       'circle in group');
	like($body, qr/addLayer\(L\.circleMarker.*\n\s*map\.addLayer\(clusterGroup\)/,
		'group added to the map after the circles');
};

subtest 'mixed pins and circles without clustering' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([52, 0], html => 'HQ');
	$m->add_circle_marker([$C{LAT}, $C{LON}]);
	my (undef, $body) = $m->onload_render();
	like($body, qr/L\.marker\(\[52, 0\]\)\.addTo\(map\)/, 'pin present');
	like($body, $CIRCLE, 'circle present');
	unlike($body, qr/clusterGroup/, 'no cluster group');
};

subtest 'circle-only map is centred on the circles' => sub {
	my $m = HTML::OSM->new();
	$m->add_circle_marker([50, -2]);
	$m->add_circle_marker([52, 2]);
	my (undef, $body);
	lives_ok { (undef, $body) = $m->onload_render() } 'renders without center()';
	like($body, qr/setView\(\[51, 0\], 12\)/, 'centre is the midpoint of the circles');
};

subtest 'centre covers pins and circles' => sub {
	my $m = HTML::OSM->new();
	$m->add_marker([50, -2]);
	$m->add_circle_marker([54, 2]);
	my (undef, $body) = $m->onload_render();
	like($body, qr/setView\(\[52, 0\], 12\)/, 'centre spans both kinds');
};

subtest 'popup labels are escaped' => sub {
	my $body = one_circle(undef, html => "it's </script><script>alert(1)");
	like($body, qr/bindPopup\('it\\'s <\\\/script>/, 'quote and </ escaped');
};

subtest 'values brought in by a clone are checked at render time' => sub {
	my $m = HTML::OSM->new(search => 0)->new(circle_markers => [
		[$C{LAT}, $C{LON}, 'ok', 'x); alert(1); (', "red'); alert(2); ('"],
		['1); alert(3); (', 0, 'bad point', 5, '#fff'],
	]);
	local $SIG{__WARN__} = sub { };
	my (undef, $body) = $m->onload_render();
	unlike($body, qr/alert/, 'nothing injected');
	my ($radius, $color) = $body =~ $CIRCLE;
	is($radius, 8,         'bad radius replaced by the default');
	is($color,  '#3388ff', 'bad colour replaced by the default');
	is(() = $body =~ /circleMarker/g, 1, 'bad point dropped');
};

restore_all();

done_testing();
