#!/usr/bin/env perl

# generate a dynamic labeled OLC grid for Google Earth

use strict;
use CGI qw(:standard);
use Geo::OLC qw(encode decode);

# calculate size of grid for each length (lat/lon differ after 10)
#
my @LAT;
my @LON;
my $m = 20;
foreach my $i (2,4,6,8,10) {
	$LAT[$i] = $m;
	$LON[$i] = $m;
	$m /= 20;
}
foreach my $i (11..16) {
	$LAT[$i] = $LAT[$i-1]/5;
	$LON[$i] = $LON[$i-1]/4;
}

#text-scaling fudge factor for each length
#
my %FUDGE = (
	2=>1.0,
	4=>0.9,
	6=>0.7,
	8=>0.525,
	10=>0.35,
	11=>0.4,
	12=>0.4,
	13=>0.4,
);

my ($west,$south,$east,$north) = split(/,/,param("BBOX"));

# auto-calc appropriate length based on window latitude range
# TODO: tweak this until the zoom levels feel right
#
my $latdiff = $north - $south;
my $length=2;
my $latnum;
foreach my $size (4,6,8,10,11,12,13,14,15,16) {
	last if ($latdiff / $LAT[$size]) > 12;
	$latnum = $latdiff / $LAT[$size];
	$length=$size;
}

# TODO: fix 2-digit display when zoomed way out; sometimes draws
# grids for the wrong side of the globe. Maybe I should export
# _norm/_denorm from Geo::OLC to canonicalize lat/lon

# find the grid cells covered by the window.
#
my ($llat,$llon) = @{decode(encode($south,$west,$length))->{lower}};
my ($ulat,$ulon) = @{decode(encode($north,$east,$length))->{lower}};

printheader();
foreach my $latoff (0..(($ulat - $llat)/$LAT[$length])+1) {
	foreach my $lonoff (0..(($ulon - $llon)/$LON[$length])+1) {
		my $lat = $llat + $latoff * $LAT[$length];
		my $lon = $llon + $lonoff * $LON[$length];
		my $code = encode($lat+$LAT[$length]/2,$lon+$LON[$length]/2,$length);
		placemark($lat,$lon,$lat+$LAT[$length],$lon+$LON[$length],
			$code,12/($latnum+1)*$FUDGE{$length});
	}
}
printtrailer();
exit 0;

sub printheader {
	print header("application/vnd.google-earth.kml+xml");
	print <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>
<Style id="grid">
	<IconStyle>
		<scale>0</scale>
	</IconStyle>
	<LabelStyle>
		<scale>0.6</scale>
		<color>ffFFFFFF</color>
	</LabelStyle>
	<LineStyle>
		<width>5</width>
		<color>FFBF00BF</color>
		<gx:labelVisibility>1</gx:labelVisibility>
	</LineStyle>
	<PolyStyle>
		<color>00ffffff</color>
	</PolyStyle>
</Style>
EOF
}

# TODO: scale the label at different scales, which will require a
# fair amount of manual tweaking.
# Ditto for line width; needs to be thinner for 11+ digits
#
sub placemark {
	my ($llat,$llon,$ulat,$ulon,$grid,$textscale) = @_;
	my ($lat,$lon) = (($ulat+$llat)/2,($ulon+$llon)/2);
	my $shortgrid = $grid;
	$shortgrid =~ tr/+0//d if length($shortgrid) < 10;
# TODO: account for zero-padding, so you don't shorten to '0000+'
# only display the last four digits
#	if ($shortgrid !~ /\+$/) {
#		$shortgrid =~ s/^.*\+/+/;
#	}else{
#		$shortgrid = substr($shortgrid,length($shortgrid) - 5);
#	}
	print <<EOF;
<Placemark>
	<name>$shortgrid</name>
	<description>$grid $llat,$llon</description>
	<styleUrl>#grid</styleUrl>
	<Style><LabelStyle><scale>$textscale</scale></LabelStyle></Style>
	<MultiGeometry>
		<Point><coordinates>$lon,$lat,0</coordinates></Point>
		<Polygon>
			<tessellate>1</tessellate><outerBoundaryIs><LinearRing>
			<coordinates>
			$llon,$llat,0
			$llon,$ulat,0
			$ulon,$ulat,0
			$ulon,$llat,0
			$llon,$llat,0
			</coordinates>
			</LinearRing></outerBoundaryIs>
		</Polygon>
	</MultiGeometry>
</Placemark>
EOF
}

sub printtrailer {
	print "</Document></kml>\n";
}

sub errorout {
	my ($error) = @_;
	print header("application/vnd.google-earth.kml+xml");
	my ($lon,$lat) = (($east + $west)/2,($north + $south)/2);
	print <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document><Placemark><name>$error</name>
<Point><coordinates>$lon,$lat,0</coordinates>
</Point></Placemark></Document></kml>
EOF
	exit 0;
}
