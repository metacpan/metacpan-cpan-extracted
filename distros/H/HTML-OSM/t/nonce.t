#!/usr/bin/env perl

# nonce => '...' puts the same nonce on every <script> onload_render() writes,
# in the head and in the body, so a page whose Content-Security-Policy allows
# scripts only by nonce draws the map.  Without it there is none, and a value
# that could end the attribute is refused by new() and, for a clone or a
# config file, by onload_render().

use strict;
use warnings;

use Test::Most;

use HTML::OSM;

my $NONCE = 'r4nd0m+/Nonce_-=';

sub scripts_of {
	my ($map) = @_;
	my ($head, $body) = $map->onload_render();
	return ($head . $body) =~ /(<script\b[^>]*>)/g;
}

sub full_map {
	my (%args) = @_;
	my $map = HTML::OSM->new(search => 0, cluster => 1, %args);
	$map->add_marker([51.5074, -0.1278], html => 'London');
	$map->add_marker([48.8566, 2.3522],  html => 'Paris');
	$map->add_heatmap([[51.5074, -0.1278, 0.9]]);
	$map->add_gpx('https://example.com/route.gpx');
	return $map;
}

subtest 'every script carries the nonce' => sub {
	my @tags = scripts_of(full_map(nonce => $NONCE));
	cmp_ok(scalar(@tags), '>=', 5, 'Leaflet, cluster, heat, GPX and the map script');
	is(scalar(grep { /\bnonce="\Q$NONCE\E"/ } @tags), scalar(@tags), 'each has the nonce')
		or diag(join "\n", @tags);
};

subtest 'with search on too' => sub {
	my $map = HTML::OSM->new(nonce => $NONCE);
	$map->add_marker([51.5074, -0.1278], html => 'London');
	my @tags = scripts_of($map);
	is(scalar(grep { /\bnonce="\Q$NONCE\E"/ } @tags), scalar(@tags), 'each has the nonce');
};

subtest 'none unless asked for' => sub {
	my ($head, $body) = full_map()->onload_render();
	unlike($head . $body, qr/\bnonce=/, 'no nonce attribute');
};

subtest 'the nonce is checked' => sub {
	for my $bad (q{a"b}, q{a'b}, 'a b', 'a>b', '', "a\nb") {
		dies_ok { HTML::OSM->new(nonce => $bad) } "new() refuses '$bad'";
	}
	lives_ok { HTML::OSM->new(nonce => 'AbC123') } 'base64 is accepted';

	# A clone skips new()'s schema, so onload_render() has to check it.
	my $clone = full_map()->new(nonce => '"><script>alert(1)</script>');
	throws_ok { $clone->onload_render() } qr/invalid nonce/, 'onload_render() refuses a bad cloned nonce';
};

subtest 'a clone keeps it' => sub {
	my $clone = full_map(nonce => $NONCE)->new(zoom => 5);
	my @tags = scripts_of($clone);
	is(scalar(grep { /\bnonce="\Q$NONCE\E"/ } @tags), scalar(@tags), 'each has the nonce');
};

done_testing();
