#!/usr/bin/env perl

# Tests for the search and max_zoom constructor options

use strict;
use warnings;

use Readonly;
use Test::Most;
use Test::Mockingbird;
use HTML::OSM;

Readonly my %C => (
	LAT      => 51.5074,
	LON      => -0.1278,
	MAX_ZOOM => 16,
	CEILING  => 28,
);

# Block accidental network calls
mock 'LWP::UserAgent::new' => sub {
	return bless {}, 'OPT::FailUA';
};
{
	package OPT::FailUA;
	sub get { die 'network access blocked in t/options.t' }
	sub default_header { }
	sub env_proxy { }
}

# Render a one-marker map built with %args
sub render
{
	my %args = @_;
	my $m = HTML::OSM->new(%args);
	$m->add_marker([$C{LAT}, $C{LON}], html => 'London');
	return $m->onload_render();
}

# The options passed to L.tileLayer(...)
sub tile_options
{
	my $body = shift;
	my ($opts) = $body =~ /L\.tileLayer\('[^']*',\s*(\{.*?\})\)/s;
	return $opts // '';
}

# ── search ────────────────────────────────────────────────────────────────────

subtest 'search is on by default' => sub {
	my ($head, $body) = render();
	like($body, qr/<input type="text" id="search-box"/, 'search box present');
	like($body, qr/id="clear-search-button"/,            'clear button present');
	like($body, qr/nominatim\.openstreetmap\.org/,       'Nominatim URL present');
	like($body, qr/var searchMarkers = \[\];/,           'searchMarkers declared');
	like($head, qr/#search-box \{/,                      'search CSS present');
};

subtest 'search => 1 keeps the search box' => sub {
	my ($head, $body) = render(search => 1);
	like($body, qr/id="search-box"/,               'search box present');
	like($body, qr/id="clear-search-button"/,      'clear button present');
	like($body, qr/nominatim\.openstreetmap\.org/, 'Nominatim URL present');
};

subtest 'search => 0 removes the search box and its script' => sub {
	my ($head, $body) = render(search => 0);
	unlike($body, qr/search-box/,          'no search box');
	unlike($body, qr/clear-search-button/, 'no clear button');
	unlike($body, qr/nominatim/i,          'no Nominatim URL');
	unlike($body, qr/searchMarkers/,       'no searchMarkers variable');
	unlike($body, qr/\bfetch\(/,           'no fetch call');
	unlike($head, qr/search-box|clear-search-button/, 'search CSS pruned');
	like($head, qr/#map \{ width: 600px; height: 400px; \}/, 'map CSS kept');
	like($head, qr/#reset-button \{/,      'reset button CSS kept');
};

subtest 'search => 0 keeps the reset button' => sub {
	my ($head, $body) = render(search => 0);
	like($body, qr/<button id="reset-button">Reset Map<\/button>/, 'reset button present');
	like($body, qr/getElementById\('reset-button'\)\.addEventListener/, 'reset handler present');
	like($body, qr/map\.setView\(\[51\.5074, -0\.1278\], 12\);\s*\}\);/, 'reset handler calls setView');
	is(() = $body =~ /<script>/g,  1, 'one opening script tag');
	is(() = $body =~ /<\/script>/g, 1, 'one closing script tag');
};

subtest 'search => "false" is off' => sub {
	my ($head, $body) = render(search => 'false');
	unlike($body, qr/search-box/, 'no search box');
};

subtest 'config-file style string values are honoured at render time' => sub {
	for my $word (qw(false no off FALSE Off)) {
		my $m = HTML::OSM->new();
		$m->{search} = $word;
		$m->add_marker([$C{LAT}, $C{LON}]);
		my (undef, $body) = $m->onload_render();
		unlike($body, qr/search-box/, "'$word' turns search off");
	}
};

subtest 'a clone inherits search => 0' => sub {
	my $orig  = HTML::OSM->new(search => 0);
	my $clone = $orig->new();
	$clone->add_marker([$C{LAT}, $C{LON}]);
	my (undef, $body) = $clone->onload_render();
	unlike($body, qr/search-box/, 'clone has no search box');

	my $clone2 = HTML::OSM->new()->new(search => 0);
	$clone2->add_marker([$C{LAT}, $C{LON}]);
	(undef, $body) = $clone2->onload_render();
	unlike($body, qr/search-box/, 'clone override turns search off');
};

subtest 'search must be a boolean' => sub {
	throws_ok { HTML::OSM->new(search => 'maybe') } qr/boolean/i, 'non-boolean rejected';
};

# ── max_zoom ──────────────────────────────────────────────────────────────────

subtest 'no max_zoom: no maxZoom option' => sub {
	my (undef, $body) = render();
	unlike(tile_options($body), qr/maxZoom/, 'maxZoom absent');
};

subtest 'max_zoom values reach the tile layer' => sub {
	for my $level (0, $C{MAX_ZOOM}, 19, $C{CEILING}) {
		my (undef, $body) = render(max_zoom => $level);
		like(tile_options($body), qr/maxZoom: $level\s*\}/, "maxZoom: $level emitted");
	}
};

subtest 'max_zoom out of range is rejected' => sub {
	throws_ok { HTML::OSM->new(max_zoom => $C{CEILING} + 1) } qr/max_zoom/, '29 rejected';
	throws_ok { HTML::OSM->new(max_zoom => -1) } qr/max_zoom/, '-1 rejected';
	throws_ok { HTML::OSM->new(max_zoom => 1.5) } qr/max_zoom/, '1.5 rejected';
};

subtest 'a clone inherits max_zoom' => sub {
	my $clone = HTML::OSM->new()->new(max_zoom => $C{MAX_ZOOM});
	$clone->add_marker([$C{LAT}, $C{LON}]);
	my (undef, $body) = $clone->onload_render();
	like(tile_options($body), qr/maxZoom: 16/, 'clone emits maxZoom');
};

subtest 'an invalid max_zoom from a clone is ignored with a warning' => sub {
	for my $bad ('16}); alert(1); ({', 29, 'abc', '') {
		my $m = HTML::OSM->new()->new(max_zoom => $bad);
		$m->add_marker([$C{LAT}, $C{LON}]);
		my @warnings;
		local $SIG{__WARN__} = sub { push @warnings, @_ };
		my (undef, $body) = $m->onload_render();
		unlike(tile_options($body), qr/maxZoom/, "'$bad' not emitted");
		unlike($body, qr/alert\(1\)/, "'$bad' not injected");
		like("@warnings", qr/onload_render: invalid max_zoom '\Q$bad\E', ignoring it/, "'$bad' warns");
	}
};

subtest 'search => 0 and max_zoom together' => sub {
	my ($head, $body) = render(search => 0, max_zoom => $C{MAX_ZOOM});
	unlike($body, qr/search-box/, 'no search box');
	like(tile_options($body), qr/maxZoom: 16/, 'maxZoom emitted');
	like(tile_options($body), qr/attribution: '/, 'attribution kept');
};

restore_all();

done_testing();
