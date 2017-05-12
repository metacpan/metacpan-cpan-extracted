#!perl

use strict;
use warnings;

use Mojolicious::Lite;
use FindBin qw/ $Bin /;
use lib "$Bin/../lib";
use HTML::GoogleMaps::V3;

any '/map/#center/#marker/' => sub {
	my ( $c ) = @_;

	my $map = HTML::GoogleMaps::V3->new;
	$map->center( $c->param( 'center' ) );
	$map->add_marker(
		point => $c->param( 'marker' ),
		html  => '<div id="content"><h3 id="firstHeading" class="firstHeading">' . $c->param( 'marker' ) . '</h3></div>',
	);

	my ( $head,$map_div ) = $map->onload_render;

	$c->render(
		template => 'map',
		head     => $head,
		map      => $map_div,
	);
};

app->start;

__DATA__
@@ map.html.ep
<html>
	<head>
		<%== $head %>
	</head>
	<body onload="html_googlemaps_initialize()">
		<%== $map %>
	</body>
</html>
