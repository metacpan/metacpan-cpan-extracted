package Geo::Geocalc;

use 5.006;
use strict;
use warnings;
use Math::Trig;

=head1 NAME

Geo::Geocalc - operations on geographical coordinates.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Geo::Geocalc simple Perl module for coordinates processing. The basic assumptions of this module are: simple, light and clean as possible.

Some of the main functions (code snippets):

    use Geo::Geocalc;

	$distanceInKm = &getDistance($lat1,$lng1,$lat2,$lng2,$R) # calculate distance (km) between two points on Earth.

	$latitudeInDegree = &getLat($lat1,$lng1,$lng2,$distance,$R) # calculate latitude (deg) of the point based on other point and distance on Earth between them.

	$longitudeInDegree = &getLng($lat1,$lng1,$lat2,$distance,$R) # calculate longitude (deg) of the point based on other point and distance on Earth between them.

	&generateKMLPlacemarks($outputKmlFilename, @coordinates); # generate outputKmlFilename.kml with Placemarks based on an array of coordinates (deg) ($lat1, $lng1, $lat2, $lng2, ...)

	&generateKMLPolygons($outputKmlFilename, \%hashOfCoords); # generate outputKmlFilename.kml with Polygons based on an reference to hash of 0 -> @ of coordinates of corners (deg - $lat1, $lng1, $lat2, $lng2 ...) , recommended to use hash generated with generateGridCoordinates function

	&generateGridCoordinates($lat1, $lng1, $lat2, $lng2, $width, \%gridCoordinates, $R); # coordinates of opposite corners on Earth to be covered by the grid, size of grid in km, reference to hash of grid output coordinates and optional, Earth radius.

	($qLat, $qLng) = &Geo::Geocalc::randomPlacemarkInsidePolygon(@{$gridCoordinates{$sector}}); # generate random place (latitude and longitude values) inside provided Polygon - array of 4 corners coordinates ($lat1, $lng1, $lat2, $lng2, ...)

    ...

=head1 SUBROUTINES/METHODS

=head2 generateKMLPolygons

=cut

sub generateKMLPolygons {
	my $fileName = shift;
	my $polygonsHashRef = shift;

	open(FILE, ">$fileName") || die "Can not open file $fileName!";
	print FILE &getKMLHeader;
	print FILE "		<Folder>";
	print FILE "			<name>Polygons</name>";
	print FILE "			<description>Generated Polygons with generateKMLPolygons function</description>";

	foreach my $key (keys %{$polygonsHashRef}) {
		print FILE "			<Placemark>";
		print FILE "				<Polygon>";
		print FILE "					<altitudeMode>clampToGround</altitudeMode>";
		print FILE "					<outerBoundaryIs>";
		print FILE "						<LinearRing>";
		print FILE "							<coordinates>";

		print FILE "								${$polygonsHashRef}{$key}[1]," . ${$polygonsHashRef}{$key}[0];
		print FILE "								${$polygonsHashRef}{$key}[3]," . ${$polygonsHashRef}{$key}[2];
		print FILE "								${$polygonsHashRef}{$key}[5]," . ${$polygonsHashRef}{$key}[4];
		print FILE "								${$polygonsHashRef}{$key}[7]," . ${$polygonsHashRef}{$key}[6];

		print FILE "							</coordinates>";
		print FILE "						</LinearRing>";
		print FILE "					</outerBoundaryIs>";
		print FILE "				</Polygon>";
		print FILE "			</Placemark>";
	}

	print FILE "		</Folder>";
	print FILE &getKMLClose;
	close FILE;

};

=head2 generateKMLPlacemarks

=cut

sub generateKMLPlacemarks {
	my $fileName = shift;
	my @coordinates = @_;

	if(scalar(@coordinates)%2 == 0) {

		open(FILE, ">$fileName") || die "Can not open file $fileName!";
		print FILE &getKMLHeader;
		print FILE "		<Folder>";
		print FILE "			<name>Placemarks</name>";
		print FILE "			<description>Generated Placemarks with generateKMLPlacemarks function</description>";

		for(my $i = 0; $i < scalar(@coordinates); $i+=2) {
			print FILE "			<Placemark>";
			print FILE "				<Point>";
			print FILE "					<coordinates>" . $coordinates[$i+1] . ", " . $coordinates[$i] . "</coordinates>";
			print FILE "				</Point>";
			print FILE "			</Placemark>";
		}
		print FILE "		</Folder>";
		print FILE &getKMLClose;
		close FILE;
	} else {
		print "ERROR. Array must contain pairs of coords. Length of array is not an even number (".scalar(@coordinates).")."
	}
};

=head2 randomPlacemarkInsidePolygon

=cut

sub randomPlacemarkInsidePolygon {
	my @polygon = @_;
	my ($maxLat, $maxLng, $minLat, $minLng) = 0;
	my ($randLat, $randLng) = 0;

	# check if PMR is belong to rectangle
	# 
	#
	#	D ---------- C
	#	|	         |
	#	|	         |
	#	|	         |
	#	|	         |
	#	A ---------- B
	#
	# A(0,1) B(2,3) C(4,5) D(6,7)
	# lat lower than lat of D and greater than lat of A
	# lng lower than lng of C and greater than lng of D

	$maxLat = $polygon[6];
	$minLat = $polygon[0];
	$maxLng = $polygon[5];
	$minLng = $polygon[7];

	$randLat = $minLat + rand($maxLat - $minLat);
	$randLng = $minLng + rand($maxLng - $minLng);

	($randLat, $randLng);
};

=head2 generateGridCoordinates

=cut

sub generateGridCoordinates {
	my ($startLat, $startLng, $stopLat, $stopLng, $width, $tmpLat, $tmpLng, $gridHashRef, $counter, $R, $startSectorId) = 0;
	($startLat, $startLng, $stopLat, $stopLng, $width, $gridHashRef, $R, $startSectorId) = @_;

	$R //= 6371; #//
	$startSectorId //= 1; #//

	my $maxLat = &getMax(($startLat, $stopLat));
	my $maxLng = &getMax(($startLng, $stopLng));
	my $minLat = &getMin(($startLat, $stopLat));
	my $minLng = &getMin(($startLng, $stopLng));

	$tmpLng = $minLng;

	$counter = $startSectorId;

	while($tmpLng < $maxLng) {

		$tmpLat = $minLat;

		while($tmpLat < $maxLat) {
			#A
			${$gridHashRef}{$counter}[0] = $tmpLat;
			${$gridHashRef}{$counter}[1] = $tmpLng;
			#B
			${$gridHashRef}{$counter}[2] = ${$gridHashRef}{$counter}[0];
			${$gridHashRef}{$counter}[3] = &getLng(${$gridHashRef}{$counter}[0], ${$gridHashRef}{$counter}[1], ${$gridHashRef}{$counter}[0], $width, $R);
			#C
			${$gridHashRef}{$counter}[4] = &getLat(${$gridHashRef}{$counter}[2], ${$gridHashRef}{$counter}[3], ${$gridHashRef}{$counter}[3], $width, $R);
			${$gridHashRef}{$counter}[5] = ${$gridHashRef}{$counter}[3]; 
			#D
			${$gridHashRef}{$counter}[6] = &getLat(${$gridHashRef}{$counter}[0], ${$gridHashRef}{$counter}[1], ${$gridHashRef}{$counter}[0], $width, $R);
			${$gridHashRef}{$counter}[7] = ${$gridHashRef}{$counter}[1];

			$tmpLat = ${$gridHashRef}{$counter}[4];
			$counter++;
		}
		$tmpLng = ${$gridHashRef}{($counter-1)}[3];
	}
};


=head2 getDistance

=cut

sub getDistance {
	my ($lat1, $lng1, $lat2, $lng2, $R) = 0;
	($lat1, $lng1, $lat2, $lng2, $R) = @_;

	return acos(sin(deg2rad($lat1))*sin(deg2rad($lat2))+cos(deg2rad($lat1))*cos(deg2rad($lat2))*cos(deg2rad($lng1)-deg2rad($lng2)))*$R;
};

=head2 getLat

=cut

sub getLat {
	my ($lat1, $lng1, $lng2, $dist, $R) = 0;
	($lat1, $lng1, $lng2, $dist, $R) = @_;
	
	return (rad2deg(asin(sin(deg2rad($lat1))*cos($dist/$R)+cos(deg2rad($lat1))*sin($dist/$R)*cos(0))));
};

=head2 getLng

=cut

sub getLng {
	my ($lat1, $lng1, $lat2, $dist, $R) = 0;
	($lat1, $lng1, $lat2, $dist, $R) = @_;

	return (rad2deg(deg2rad($lng1) + atan2(sin(90)*sin($dist/$R)*cos(deg2rad($lat1)), cos($dist/$R)-sin(deg2rad($lat1))*sin(deg2rad($lat2)))));
};


=head2 getKMLHeader

=cut

sub getKMLHeader {
	"<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<kml xmlns=\"http://www.opengis.net/kml/2.2\">
	<Document>"
};

=head2 getKMLClose

=cut

sub getKMLClose {
	"	</Document>
</kml>"
};

=head2 getMax

=cut

sub getMax {
	my $max = $_[0];

	foreach my $tmp (@_) {
		if($max < $tmp) {
			$max = $tmp;
		}
	}
	$max;
};

=head2 getMin

=cut

sub getMin {
	my $min = $_[0];

	foreach my $tmp (@_) {
		if($min > $tmp) {
			$min = $tmp;
		}
	}
	$min;
};

=head1 AUTHOR

Mecin, C<< <mecin at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-geo-geocalc at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-Geocalc>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Geocalc


You can also look for information at:

https://github.com/Mecin/geoQGen

and

https://github.com/Mecin/geoQGame

or contact me directly.


=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Geocalc>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Geocalc>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Geocalc>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Geocalc/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Mecin.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Geo::Geocalc
