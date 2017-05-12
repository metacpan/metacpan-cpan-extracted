package Ham::WorldMap;

use 5.006;
use strict;
use warnings;

use File::ShareDir ':ALL';

use DateTime;
use Ham::Locator;
use Imager;
use POSIX;
use Math::Trig;

=head1 NAME

Ham::WorldMap - Creates an Imager image containing an equirectangular projection of the world map, with optional
Maidenhead locator grid and day/night illumination showing the area of enhanced propagation known as the 'grey line'.
Also utility methods for adding dots at locator positions or lat/long coords, and filling grid squares with colour
to provide a 'heat map' of activity from these squares.

A sample map:

=begin HTML

<p><img src="https://bitbucket.org/devzendo/ham-worldmap/raw/default/Ham-WorldMap/example-map.png" width="960"
height="512" alt="Example map"/></p>

=end HTML

=head1 ACKNOWLEDGEMENTS

The map used in this module came from Wikimedia commons:
https://commons.wikimedia.org/wiki/File:BlankMap-World6-Equirectangular.svg
and is in the public domain.

(I resized it to have a width of 1920 pixels, shifted it right a little to match other amateur locator maps, took off
the odd pixels at each side, and exported it as a PNG in InkScape. The code to do that is in another project that you
don't need, but that also contains examples of the use of this module: https://bitbucket.org/devzendo/gridmapper )


The day/night illumination code is ported from John Walker's Earth and Moon viewer, at
https://www.fourmilab.ch/earthview/details.html
I do not profess to understand the maths behind this, but John's description should suffice:

  How do you calculate the day and night regions of the Earth?
    The position of the Sun with respect to the Earth is calculated by the algorithm given in Jean Meeus's "Astronomical
    Algorithms". Once the position of the Sun is known, the terminator (line separating day and night) is simply the
    circle where the plane perpendicular to the Earth-Sun vector and passing through the centre of the Earth intersects
    the globe, which is straightforward to calculate. Then it's simply a matter of colouring the hemisphere away from
    the Sun in subdued shades.


=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

To create a map with a station location, grid squares, and night/day boundary:

    use Ham::WorldMap;

    # By default, an OSX-specific font will be used for drawing text. If you're not on OSX, supply the name of a
    # font file...
    my $map = Ham::WorldMap->new();  # fine on OSX, uses Lucida Console.
    my $map = Ham::WorldMap->new('fontFile' => "C:\\Windows\\Fonts\\Arial.ttf");  # Windows, not tested.

    # The map now has the world on it.

    my $colour = Imager::Color->new(16, 16, 192);
    my $radius = 20;
    $map->dotAtLocator("JO01EE", $radius, $colour); # M0CUV is here!

    # World plus dot.

    my $dt = DateTime->new(
        year       => 2016,
        month      => 6,
        day        => 5,
        hour       => 0,
        minute     => 0,
        second     => 0,
        nanosecond => 0,
        time_zone  => 'UTC',
    );
    $map->drawNightRegions($dt);

    # The world plus dot, with day/night on top.

    $map->drawLocatorGrid();

    # The grid is on top of the world/dot/day/night.

    $map->write("map.png");



=head1 EXPORT

No functions exported; this has a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 new

The constructor; takes a hash of arguments, returns a blessed hash.

Currently the only data in the argument hash is fontFile, the name of a TTF font. This code was written on OSX, and if
not specified, Lucida Console.ttf will be used; you'll need to specify this on non-OSX.

    my $map = Ham::WorldMap->new('fontFile' => "C:\\Windows\\Fonts\\Arial.ttf");  # Windows, not tested.

Some instance data in the hash that you might find useful: I should probably expose these via methods:
        'height'  => the map image height
        'width'   => the map image width
        'image'   => the Imager image of the map
        'gridx'   => the width of each grid square
        'gridy'   => the height of each grid square


=head2 dotAtLocator($self, $gridLocation, $radius, $colour)

Takes a grid location at any granularity (e.g. 'JO', 'JO01', 'JO01EE'), a radius in pixels, and an Imager colour, then
draws that dot.

=head2 locatorToXY($self, $gridLocation) = ($x, $y)

Converts a grid location of any granularity into X,Y coordinates for that location on the map image.

=head2 drawLocatorGrid($self)

Draws the locator grid, large-granularity grid square identifiers (2 character, e.g. JO) on the map image.

=head2 heatMapGridSquare($self, $twoCharGridSquare, $proportion)

Colour a 2-char grid square (e.g. JO for South-East England) from a heat map, according to the proportion, which is
in the range [0.0 .. 1.0]. 0.0 indicates 'no signals in this square'; 1.0 indicates 'all signals in this square'.

=head2 write($self, $filename)

Writes the map image to a file; e.g. "map.png".

=head2 drawNightRegions($self, $dateTime)

Draw the night regions onto the map, for a given UTC time/date. This is not a fast operation; it's computationally
heavy.

=head2 createNightRegions($self, $dateTime) = $map

Create an Imager image of the day/night boundary, for a given UTC time/date. Does not modify current map image, gives
back a new one that can be composed transparently onto the main image (you may just want to use drawNightRegions -
this is a bit 'internal').


=head1 AUTHOR

Matt Gumbley, M0CUV C<< <devzendo at cpan.org> >>
@mattgumbley on twitter

=head1 SOURCE CODE

The Mercurial source repository for this module is kindly hosted by Bitbucket, at:
https://devzendo@bitbucket.org/devzendo/ham-worldmap

=head1 BUGS

Please report any bugs or feature requests to C<bug-ham-worldmap at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ham-WorldMap>.  I will be notified, and then
you'll automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ham::WorldMap


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Ham-WorldMap>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Ham-WorldMap>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Ham-WorldMap>

=item * Search CPAN

L<http://search.cpan.org/dist/Ham-WorldMap/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Matt Gumbley.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


=cut


# Hate that Perl doesn't define these....
use constant TRUE => 1;
use constant FALSE => 0;


sub new {
    my $class = shift;
    my %init = @_;

    my $mapPngFile = dist_file('Ham-WorldMap', 'grey-map.png');
    die "Cannot locate shared data file $mapPngFile" unless -f $mapPngFile;

    my $mapImage = Imager->new();
    $mapImage->read(file => $mapPngFile) or die "Could not read map $mapPngFile: " . $mapImage->errstr;
    $mapImage = $mapImage->convert(preset => 'addalpha');

    my $locator = Ham::Locator->new();

    my $grey = Imager::Color->new(64, 64, 64);

    my $fontFile = $init{'fontFile'} || "/Library/Fonts/Microsoft/Lucida Console.ttf";

    my $font = Imager::Font->new(file => $fontFile);

    my $obj = {
        'height' => $mapImage->getheight(),
        'width' => $mapImage->getwidth(),
        'image' => $mapImage,
        'gridx' => $mapImage->getwidth() / 18,
        'gridy' => $mapImage->getheight() / 18,
        'locator' => $locator,
        'grey' => $grey,
        'font' => $font,
    };

    bless $obj, $class;
    return $obj;
}

sub dotAtLocator {
    my ($self, $gridLocation, $radius, $colour) = @_;

    my ($x, $y) = $self->locatorToXY($gridLocation);

    my ($r, $g, $b, $a) = $colour->rgba();
    my $grey = Imager::Color->new(192, 192, 192, $a);
    $self->{image}->circle(color => $grey, r => $radius, x => $x, y => $y, aa => 1);

    $self->{image}->circle(color => $colour, r => $radius - 1, x => $x, y => $y, aa => 1);
}

sub locatorToXY {
    my ($self, $gridLocation) = @_;

    $self->{locator}->set_loc($gridLocation);
    my ($latitude, $longitude) = $self->{locator}->loc2latlng;

    my $x = $longitude; # -180 .. 180
    $x += 180; # 0 .. 360
    $x *= ($self->{width} / 360); # 0 .. width

    my $y = - $latitude; # -90 .. 90
    $y += 90; # 0 .. 180
    $y *= ($self->{height} / 180); # 0 .. height

    return ($x, $y);
}

sub drawLocatorGrid {
    my $self = shift;
    my $map = $self->{image};
    my $grey = $self->{grey};
    my $xinc = $self->{gridx};
    my $yinc = $self->{gridy};
    my $font = $self->{font};
    $map->box(color => $grey, xmin => 0, ymin => 0, xmax => $self->{width} - 1, ymax => $self->{height} - 1, filled => 0);
    my $x;
    my $y;
    for ($x = 0; $x <= 18; $x++) {
        for ($y = 0; $y <= 18; $y++) {
            $map->box(color => $grey, xmin => $x * $xinc, ymin => $y * $yinc, xmax => ($x + 1) * $xinc, ymax => ($y + 1) * $yinc, filled => 0);
            my $sq = chr(65 + $x) . chr(65 + (17 - $y));
            $map->align_string(x => ($x * $xinc) + ($xinc / 2), y => ($y * $yinc) + ($yinc / 2),
                font => $font,
                string => $sq,
                color => $grey,
                halign=>'center',
                valign=>'center',
                size => 30,
                aa => 1);
        }
    }
}

# Colour a 2-char grid square (e.g. JO for South-East England) from a heat map, according to the proportion, which is
# in the range [0.0 .. 1.0]. 0.0 indicates 'no signals in this square'; 1.0 indicates 'all signals in this square'.
sub heatMapGridSquare {
    my ($self, $twoCharGridSquare, $proportion) = @_;

    my ($x, $y) = $self->locatorToXY($twoCharGridSquare);

    my $map = $self->{image};
    my $xinc = $self->{gridx};
    my $yinc = $self->{gridy};

    my $gX = int($x / $xinc) * $xinc;
    my $gY = int($y / $yinc) * $yinc;

    # HSV, with SV fixed. H from 0 (red [proportion=0.0]) to 64 (yellow [proportion=1.0)
    my $h = 64 - int($proportion * 64);
    my $color = Imager::Color->new(h => $h, s => 40, v => 80);
    printf ("proportion %3.2f%% h [0..64] $h\n", $proportion * 100);

    my $box = Imager->new(ysize => $yinc, xsize => $xinc);
    $box = $box->convert(preset => 'addalpha');

    $box->box(color => $color, xmin => 0, ymin => 0, xmax => $xinc - 1, ymax => $yinc - 1, filled => 1);

    $self->{image}->compose(src => $box, tx => $gX + 1, ty => $gY + 1, opacity => 0.5);
    #$map->box(color => $color, xmin => $gX + 1, ymin => $gY + 1, xmax => $gX + $xinc - 1, ymax => $gY + $yinc - 1, filled => 1);
}

sub write {
    my ($self, $filename) = @_;
    $self->{image}->write(file => $filename) or die "Could not write map $filename: " . $self->{image}->errstr;
}

# The code used below was ported from John Walker's Earth and Moon Viewer. Thank you, John!

use constant JulianCentury => 36525.0;                    # Days in Julian century
use constant J2000 => 2451545.0;                          # Julian day of J2000 epoch
use constant AstronomicalUnit => 149597870.0;             # Astronomical unit in kilometres
use constant SunSMAX => (AstronomicalUnit * 1.000001018); # Semi-major axis of Earth's orbit
use constant EarthRad => 6378.14;                         # Earth's equatorial radius, km (IAU 1976)

# Draw the night regions onto the map, for a given UTC time/date.
sub drawNightRegions {
    my ($self, $dateTime) = @_;
    my $night = $self->createNightRegions($dateTime);
    $self->{image}->compose(src => $night, opacity => 0.2);
}

# Create an image of the night, for a given UTC time/date. Does not modify current map, gives back a new one that can
# be composed transparently.
sub createNightRegions {
    my ($self, $dateTime) = @_;

    # Convert the given UTC Unix date and time (DateTime) structure to astronomical Julian time (i.e. Julian date plus
    # day fraction, expressed as a double).
    my $jt = $dateTime->jd();

    my ($sunra, $sundec, $sunrv, $sunlong) = _sunpos($jt, FALSE);

    my $gt = _gmst($jt);

    my $subslong = ($gt * 15) - $sunra;
    if ($subslong > 180) {
        $subslong = -(360 - $subslong);
    } elsif ($subslong < -180) {
        $subslong += 360;
    }
    my $vlat = deg2rad($sundec);
    my $vlon = deg2rad($subslong);
    my $valt = $sunrv * SunSMAX - EarthRad;

    # Allocate the projected illumination width tables.
    my $wtabsize = $self->{height};
    my @wtab = (-1) x $wtabsize;
    my @wtab1 = (-1) x $wtabsize;

    _projillum(\@wtab, $self->{width}, $self->{height}, $sundec);
    my @wtabs = @wtab;
    @wtab = @wtab1;
    @wtab1 = @wtabs;

    $sunlong = _fixangle(180.0 + ($sunra - ($gt * 15)));
    my $xl = int(($sunlong * ($self->{width} / 360.0)));

    # If the subsolar point has moved at least one pixel, update the illuminated area on the image.
    my $illumMap = _moveterm(\@wtab1, $xl, $self->{width}, $self->{height});

    return $illumMap;
}

# Extract sign
sub _sgn {
    my $x = shift;
    return ($x <=> 0);
}

# _projillum(wtab, xdots, ydots, dec) - project illuminated area on the map
use constant TERMINC => 100; # Circle segments for terminator
sub _projillum {
    my ($wtab, $xdots, $ydots, $dec) = @_;

    my $i;
    my $ftf = TRUE;
    my ($ilon, $ilat, $lilon, $lilat, $xt);
    my ($m, $x, $y, $z, $th, $lon, $lat, $s, $c);

    # Clear unoccupied cells in width table
    for ($i = 0; $i < $ydots; $i++) {
	    $wtab->[$i] = -1;
    }

    # Build transformation for declination
    $s = sin(-deg2rad($dec));
    $c = cos(-deg2rad($dec));

    # Increment over a semicircle of illumination
    for ($th = -(pi / 2); $th <= pi / 2 + 0.001; $th += pi / TERMINC) {

        # Transform the point through the declination rotation.
        $x = -$s * sin($th);
        $y = cos($th);
        $z = $c * sin($th);

        # Transform the resulting co-ordinate through the map projection to obtain screen co-ordinates.
        $lon = ($y == 0 && $x == 0) ? 0.0 : rad2deg(atan2($y, $x));
        $lat = rad2deg(asin($z));

        $ilat = int(($ydots - ($lat + 90) * ($ydots / 180.0)));
        $ilon = int(($lon * ($xdots / 360.0)));

        if ($ftf) {
            # First time.  Just save start co-ordinate.
            $lilon = $ilon;
            $lilat = $ilat;
            $ftf = FALSE;
        } else {
            # Trace out the line and set the width table.
            if ($lilat == $ilat) {
                $wtab->[($ydots - 1) - $ilat] = 2 * ($ilon == 0 ? 1 : $ilon);
            } else {
                $m = ($ilon - $lilon) / ($ilat - $lilat);
                for ($i = $lilat; $i != $ilat; $i += _sgn($ilat - $lilat)) {
                    $xt = int(($lilon + POSIX::floor(($m * ($i - $lilat)) + 0.5)));
                    $wtab->[($ydots - 1) - $i] = 2 * ($xt == 0 ? 1 : $xt);
                }
            }
            $lilon = $ilon;
            $lilat = $ilat;
        }
    }

    # Now tweak the widths to generate full illumination for the correct pole. */
    if ($dec < 0.0) {
        $ilat = $ydots - 1;
        $lilat = -1;
    } else {
        $ilat = 0;
        $lilat = 1;
    }

    for ($i = $ilat; $i != $ydots / 2; $i += $lilat) {
        if ($wtab->[$i] != -1) {
            while (TRUE) {
                $wtab->[$i] = $xdots;
                if ($i == $ilat) {
                    last;
                }
                $i -= $lilat;
            }
            last;
        }
    }
}

# _moveterm(wtab, noon, width, height) - update illuminated portion of the globe.
sub _moveterm {
    my ($wtab, $noon, $width, $height) = @_;
    my $illumMap = Imager->new(ysize => $height, xsize => $width);
    $illumMap = $illumMap->convert(preset => 'addalpha');
    my $day = Imager::Color->new(255, 255, 255, 10);
    my ($i, $j, $oh, $nl, $nh);

    for ($i = 0; $i < $height; $i++) {
        if ($wtab->[$i] >= 0) {
            $nl = (($noon - ($wtab->[$i] / 2)) + $width) % $width;
            $nh = ($nl + $wtab->[$i]) - 1;

            $oh = ($nh - $nl) + 1;
            if (($nl + $oh) > $width) {
                for ($j = $nl; $j < $width; $j++) {
                    $illumMap->setpixel(x => $j, y => $i, color => $day);
                }
                for ($j = 0; $j < ((($nl + $oh) - $width) + 1); $j++) {
                    $illumMap->setpixel(x => $j, y => $i, color => $day);
                }
            } else {
                for ($j = $nl; $j < (($nl + $oh) + 1); $j++) {
                    $illumMap->setpixel(x => $j, y => $i, color => $day);
                }
            }
        }
    }

    return $illumMap;
}

# _gmst(jd) - Calculate Greenwich Mean Siderial Time for a given instant expressed as a Julian date and fraction.
sub _gmst {
    my $jd = shift;
    my ($t, $theta0);

    # Time, in Julian centuries of 36525 ephemeris days, measured from the epoch 1900 January 0.5 ET.
    $t = ((POSIX::floor($jd + 0.5) - 0.5) - 2415020.0) / JulianCentury;

    $theta0 = 6.6460656 + 2400.051262 * $t + 0.00002581 * $t * $t;

    $t = ($jd + 0.5) - (POSIX::floor($jd + 0.5));

    $theta0 += ($t * 24.0) * 1.002737908;

    $theta0 = ($theta0 - 24.0 * (POSIX::floor($theta0 / 24.0)));

    return $theta0;
}

# Fix angle
sub _fixangle {
    my $angle = shift;
    return (($angle) - 360.0 * (POSIX::floor(($angle) / 360.0)));
}

# _kepler(ma, ecc) - Solve Kepler's equation
use constant Epsilon => 1E-6;
sub _kepler {
    my ($ma, $ecc) = @_;
    my ($e, $delta);

    $e = $ma = deg2rad($ma);
    do {
	    $delta = $e - $ecc * sin($e) - $ma;
        $e -= $delta / (1 - $ecc * cos($e));
    } while (abs($delta) > Epsilon);
    return $e;
}

# _obliquq(jd) - Calculate the obliquity of the ecliptic for a given Julian date.
# This uses Laskar's tenth-degree polynomial fit (J. Laskar, Astronomy and Astrophysics, Vol. 157, page 68 [1986])
# which is accurate to within 0.01 arc second between AD 1000 and AD 3000, and within a few seconds of arc for +/-10000
# years around AD 2000. If we're outside the range in which this fit is valid (deep time) we simply return the J2000
# value of the obliquity, which happens to be almost precisely the mean.
sub _obliqeq {
    my $jd = shift;
    my @oterms = (
        asec(-4680.93),
        asec(	-1.55),
        asec( 1999.25),
        asec(  -51.38),
        asec( -249.67),
        asec(  -39.05),
        asec(	 7.12),
        asec(	27.87),
        asec(	 5.79),
        asec(	 2.45)
    );
    my $eps = 23 + (26 / 60.0) + (21.448 / 3600.0);
    my ($u, $v, $i);

    $v = $u = ($jd - J2000) / (JulianCentury * 100);

    if (abs($u) < 1.0) {
        for ($i = 0; $i < 10; $i++) {
            $eps += $oterms[$i] * $v;
            $v *= $u;
        }
    }
    return $eps;
}

# _sunpos(jd, apparent) : (ra, dec, rv, long) - Calculate position of the Sun.
# jd is the Julian date of the instant for which the position is desired and apparent should be true if the apparent
# position (corrected for nutation and aberration) is desired.
# The Sun's co-ordinates are returned in ra and dec, both specified in degrees (divide ra by 15 to obtain hours).
# The radius vector to the Sun in astronomical units is returned in rv and the Sun's longitude (true or apparent, as
# desired) is returned as degrees in long.
sub _sunpos {
    my ($jd, $apparent) = @_;
    my ($t, $t2, $t3, $l, $m, $e, $ea, $v, $theta, $omega, $eps);

    # Time, in Julian centuries of 36525 ephemeris days, measured from the epoch 1900 January 0.5 ET.
    $t = ($jd - 2415020.0) / JulianCentury;
    $t2 = $t * $t;
    $t3 = $t2 * $t;

    # Geometric mean longitude of the Sun, referred to the mean equinox of the date.
    $l = _fixangle(279.69668 + 36000.76892 * $t + 0.0003025 * $t2);

    # Sun's mean anomaly.
    $m = _fixangle(358.47583 + 35999.04975 * $t - 0.000150 * $t2 - 0.0000033 * $t3);

    # Eccentricity of the Earth's orbit.
    $e = 0.01675104 - 0.0000418 * $t - 0.000000126 * $t2;

    # Eccentric anomaly.
    $ea = _kepler($m, $e);

    # True anomaly
    $v = _fixangle(2 * rad2deg(atan(sqrt((1 + $e) / (1 - $e))  * tan($ea / 2))));

    # Sun's true longitude.
    $theta = $l + $v - $m;

    # Obliquity of the ecliptic.
    $eps = _obliqeq($jd);

    # Corrections for Sun's apparent longitude, if desired.
    if ($apparent) {
        $omega = _fixangle(259.18 - 1934.142 * $t);
        $theta = $theta - 0.00569 - 0.00479 * sin(deg2rad($omega));
        $eps += 0.00256 * cos(deg2rad($omega));
    }

    # Return Sun's longitude and radius vector
    my $long = $theta;
    my $rv = (1.0000002 * (1 - $e * $e)) / (1 + $e * cos(deg2rad($v)));

    # Determine solar co-ordinates.
    my $ra = _fixangle(rad2deg(atan2(cos(deg2rad($eps)) * sin(deg2rad($theta)), cos(deg2rad($theta)))));
    my $dec = rad2deg(asin(sin(deg2rad($eps)) * sin(deg2rad($theta))));
    return ($ra, $dec, $rv, $long);
}


1; # End of Ham::WorldMap
