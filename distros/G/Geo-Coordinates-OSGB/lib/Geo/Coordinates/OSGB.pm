package Geo::Coordinates::OSGB;
use base qw(Exporter);
use strict;
use warnings;
use Carp;
use File::Share ':all';
use 5.010;    # at least Perl 5.10 please

our $VERSION = '2.20';

our %EXPORT_TAGS = (
    all => [
        qw(
          ll_to_grid
          grid_to_ll

          ll_to_grid_helmert
          grid_to_ll_helmert

          get_ostn02_shift_pair
          set_default_shape
          )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{all} } );

use constant ELLIPSOIDS => {
    WGS84  => [ 6_378_137.000, 6_356_752.31424518, 298.257223563,  0.006694379990141316996137233540 ],
    ETRS89 => [ 6_378_137.000, 6_356_752.314140,   298.257222101,  0.006694380022900787625359114703 ],
    GRS80  => [ 6_378_137.000, 6_356_752.314140,   298.257222101,  0.006694380022900787625359114703 ],
    OSGB36 => [ 6_377_563.396, 6_356_256.909,      299.3249612665, 0.0066705400741492318211148938735613129751683486352306 ],
};

my $default_shape = 'WGS84';

sub set_default_shape {
    my $s = shift;
    croak "Unknown shape: $s" if !exists ELLIPSOIDS->{$s};
    $default_shape = $s;
    return;
}

# constants for OSGB mercator projection
use constant ORIGIN_LONGITUDE   => -2 / 57.29577951308232087679815481410517;
use constant ORIGIN_LATITUDE    => 49 / 57.29577951308232087679815481410517;
use constant ORIGIN_EASTING     => 400_000;
use constant ORIGIN_NORTHING    => -100_000;
use constant CONVERGENCE_FACTOR => 0.9996012717;

# constants for small distances
use constant TENTH_MM     => 0.0001;
use constant HUNDREDTH_MM => 0.00001;

# OSTN data
my $ostn_ee_file = dist_file('Geo-Coordinates-OSGB', 'ostn_east_shift_82140');
my $ostn_nn_file = dist_file('Geo-Coordinates-OSGB', 'ostn_north_shift_-84180');

use constant MIN_EE_SHIFT => 82140;
use constant MIN_NN_SHIFT => -84180;

sub _load_ostn_data {
    my $name = shift;
    open my $fh, '< :raw :bytes', $name;
    my $count = read $fh, my $data, 1753902;
    close $fh;
    return unpack "S<[$count]", $data;  # Note the byte order modifiers....
}

# Perl 5.08: I've use the byte order modifier "<" on the unpack command above
# because this means we are system independent and the binary data can be
# read of little endian and big endian machines.  But this needs Perl 5.10 or 
# better.  If you must have perl 5.08, then you will need to get a copy of 
# OSTN15 from the OSGB, modify "build/pack_ostn_data" to pack the data in your 
# native format, and then modify the "unpack" above to match.  

my @EE_SHIFTS = _load_ostn_data($ostn_ee_file);
my @NN_SHIFTS = _load_ostn_data($ostn_nn_file);

sub _llh_to_cartesian {
    my ( $lat, $lon, $H, $shape ) = @_;

    my ( $a, $b, $f, $ee ) = @{ ELLIPSOIDS->{$shape} };

    my $phi = $lat / 57.29577951308232087679815481410517;
    my $sp = sin $phi;
    my $cp = cos $phi;
    my $lam = $lon / 57.29577951308232087679815481410517;
    my $sl = sin $lam;
    my $cl = cos $lam;

    my $nu = $a / sqrt( 1 - $ee * $sp * $sp );

    my $x = ( $nu + $H ) * $cp * $cl;
    my $y = ( $nu + $H ) * $cp * $sl;
    my $z = ( ( 1 - $ee ) * $nu + $H ) * $sp;

    return ( $x, $y, $z );
}

sub _cartesian_to_llh {
    my ( $x, $y, $z, $shape ) = @_;

    my ( $a, $b, $f, $ee ) = @{ ELLIPSOIDS->{$shape} };

    my $p = sqrt($x*$x+$y*$y);
    my $lam = atan2 $y, $x;
    my $phi = atan2 $z, $p*(1-$ee);

    my ( $nu, $oldphi, $sp );
    while (1) {
        $sp = sin $phi;
        $nu = $a / sqrt(1 - $ee*$sp*$sp);
        $oldphi = $phi;
        $phi = atan2 $z+$ee*$nu*$sp, $p;
        last if abs($oldphi-$phi) < 1E-12;
    }

    my $lat = $phi * 57.29577951308232087679815481410517;
    my $lon = $lam * 57.29577951308232087679815481410517;
    my $H   = $p / cos($phi) - $nu;

    return ( $lat, $lon, $H );
}

sub _small_Helmert_transform_for_OSGB {
    my ($direction, $xa, $ya, $za) = @_;
    my $tx = $direction * -446.448;
    my $ty = $direction * +125.157;
    my $tz = $direction * -542.060;
    my $sp = $direction * 0.0000204894 + 1;
    my $rx = ($direction * -0.1502/3600) / 57.29577951308232087679815481410517;
    my $ry = ($direction * -0.2470/3600) / 57.29577951308232087679815481410517;
    my $rz = ($direction * -0.8421/3600) / 57.29577951308232087679815481410517;
    my $xb = $tx + $sp*$xa - $rz*$ya + $ry*$za;
    my $yb = $ty + $rz*$xa + $sp*$ya - $rx*$za;
    my $zb = $tz - $ry*$xa + $rx*$ya + $sp*$za;
    return ($xb, $yb, $zb);
}

sub _shift_ll_from_osgb36_to_wgs84 {
    my ($lat, $lon) = @_;
    my ($xa, $ya, $za) = _llh_to_cartesian($lat, $lon, 0, 'OSGB36' );
    my ($xb, $yb, $zb) = _small_Helmert_transform_for_OSGB(-1,$xa, $ya, $za);
    my ($latx, $lonx, $junk) = _cartesian_to_llh($xb, $yb, $zb, 'WGS84');
    return ($latx, $lonx);
}

sub _shift_ll_from_wgs84_to_osgb36 {
    my ($lat, $lon) = @_;
    my ($xa, $ya, $za) = _llh_to_cartesian($lat, $lon, 0, 'WGS84');
    my ($xb, $yb, $zb) = _small_Helmert_transform_for_OSGB(+1,$xa, $ya, $za);
    my ($latx, $lonx, $junk) = _cartesian_to_llh($xb, $yb, $zb, 'OSGB36');
    return ($latx, $lonx);
}

sub ll_to_grid {

    my ( $lat, $lon, $options ) = @_;

    # we might have been passed a hash as the first argument
    if (ref $lat && defined $lat->{lat} && defined $lat->{lon}) {
        $options = $lat;
        $lat = $options->{lat};
        $lon = $options->{lon};
    }

    # correct reversed arguments, this is always valid in OSGB area
    if ($lat < $lon) {
        ($lat, $lon) = ($lon, $lat)
    }

    my $shape = exists $options->{shape} ? $options->{shape} : $default_shape;
    croak "Unknown shape: $shape" if !exists ELLIPSOIDS->{$shape};

    my ($e,$n) = _project_onto_grid($lat, $lon, $shape);

    my @out;
    # If we were using LL from OS maps, then we are done
    if ($shape eq 'OSGB36') {
        @out = map { sprintf '%.3f', $_ } ($e, $n);
        return wantarray ? @out : "@out";
    }

    # now shape is WGS84 etc so we must adjust
    my ($dx, $dy) = _find_OSTN_shifts_at($e,$n);
    if ($dx) {
        @out = map { sprintf '%.3f', $_ } ($e + $dx, $n + $dy);
        return wantarray ? @out : "@out";
    }

    # still here? Then do Helmert shift into OSGB36 and re-project
    return ll_to_grid_helmert($lat, $lon)
}

sub ll_to_grid_helmert {
    my ($lat, $lon) = @_;
    my @out = map { sprintf '%.0f', $_ } # round to metres
              _project_onto_grid( _shift_ll_from_wgs84_to_osgb36($lat, $lon), 'OSGB36' );
    return wantarray ? @out : "@out";
}

sub _project_onto_grid {

    my ( $lat, $lon, $shape ) = @_;

    my ($a,$b,$f,$e2) = @{ ELLIPSOIDS->{$shape} };

    my $n = ($a-$b)/($a+$b);
    my $af = $a * CONVERGENCE_FACTOR;

    my $phi = $lat / 57.29577951308232087679815481410517;
    my $lam = $lon / 57.29577951308232087679815481410517;

    my $cp = cos $phi; my $sp = sin $phi;
    my $sp2 = $sp*$sp;
    my $tp  = $sp/$cp; # cos phi cannot be zero in GB
    my $tp2 = $tp*$tp;
    my $tp4 = $tp2*$tp2;

    my $splat = 1 - $e2 * $sp2;
    my $sqrtsplat = sqrt $splat;
    my $nu  = $af / $sqrtsplat;
    my $rho = $af * (1 - $e2) / ($splat*$sqrtsplat);
    my $eta2 = $nu/$rho - 1;

    my $p_plus  = $phi + ORIGIN_LATITUDE;
    my $p_minus = $phi - ORIGIN_LATITUDE;
    my $M = $b * CONVERGENCE_FACTOR * (
           (1 + $n * (1 + 5/4*$n*(1 + $n)))*$p_minus
         - 3*$n*(1+$n*(1+7/8*$n))  * sin(  $p_minus) * cos(  $p_plus)
         + (15/8*$n * ($n*(1+$n))) * sin(2*$p_minus) * cos(2*$p_plus)
         - 35/24*$n**3             * sin(3*$p_minus) * cos(3*$p_plus)
           );

    my $I    = $M + ORIGIN_NORTHING;
    my $II   = $nu/2  * $sp * $cp;
    my $III  = $nu/24 * $sp * $cp**3 * (5-$tp2+9*$eta2);
    my $IIIA = $nu/720* $sp * $cp**5 *(61-58*$tp2+$tp4);

    my $IV   = $nu*$cp;
    my $V    = $nu/6   * $cp**3 * ($nu/$rho-$tp2);
    my $VI   = $nu/120 * $cp**5 * (5-18*$tp2+$tp4+14*$eta2-58*$tp2*$eta2);

    my $dl = $lam - ORIGIN_LONGITUDE;
    my $north =            $I + ( $II + ( $III + $IIIA * $dl * $dl ) * $dl * $dl ) * $dl * $dl;
    my $east = ORIGIN_EASTING + ( $IV + ( $V   + $VI   * $dl * $dl ) * $dl * $dl ) * $dl;

    return ($east, $north);
}

sub _find_OSTN_shifts_at {

    my ($easting, $northing) = @_;

    return if $easting < 0;
    return if $easting > 700000;
    return if $northing < 0;
    return if $northing > 1250000;

    my $east_km = int($easting / 1000);
    my $north_km = int($northing / 1000);

    my $lle = (MIN_EE_SHIFT + $EE_SHIFTS[$east_km + $north_km * 701])/1000;
    my $lre = (MIN_EE_SHIFT + $EE_SHIFTS[$east_km + $north_km * 701 + 1])/1000;
    my $ule = (MIN_EE_SHIFT + $EE_SHIFTS[$east_km + $north_km * 701 + 701])/1000;
    my $ure = (MIN_EE_SHIFT + $EE_SHIFTS[$east_km + $north_km * 701 + 702])/1000;

    my $lln = (MIN_NN_SHIFT + $NN_SHIFTS[$east_km + $north_km * 701])/1000;
    my $lrn = (MIN_NN_SHIFT + $NN_SHIFTS[$east_km + $north_km * 701 + 1])/1000;
    my $uln = (MIN_NN_SHIFT + $NN_SHIFTS[$east_km + $north_km * 701 + 701])/1000;
    my $urn = (MIN_NN_SHIFT + $NN_SHIFTS[$east_km + $north_km * 701 + 702])/1000;

    my $t = ($easting / 1000) - $east_km;
    my $u = ($northing / 1000) - $north_km;

    return (
        (1-$t) * (1-$u) * $lle + $t * (1-$u) * $lre + (1-$t) * $u * $ule + $t * $u * $ure,
        (1-$t) * (1-$u) * $lln + $t * (1-$u) * $lrn + (1-$t) * $u * $uln + $t * $u * $urn
    );
}

sub grid_to_ll {

    my ($e, $n, $options) = @_;

    if (ref $e && defined $e->{e} && defined $e->{n}) {
        $options = $e;
        $e = $options->{e};
        $n = $options->{n};
    }

    my $shape = exists $options->{shape} ? $options->{shape} : $default_shape;

    croak "Unknown shape: $shape" if !exists ELLIPSOIDS->{$shape};

    my ($os_lat, $os_lon) = _reverse_project_onto_ellipsoid($e, $n, 'OSGB36');

    # if we want OS map LL we are done
    if ($shape eq 'OSGB36') {
        return ($os_lat, $os_lon)
    }

    # If we want WGS84 LL, we must adjust to pseudo grid if we can
    my ($dx, $dy) = _find_OSTN_shifts_at($e,$n);
    if ($dx) {
        my $in_ostn02_polygon = 1;
        my ($x,$y) = ($e-$dx, $n-$dy);
        my ($last_dx, $last_dy) = ($dx, $dy);
        APPROX:
        for (1..20) {
            ($dx, $dy) = _find_OSTN_shifts_at($x,$y);

            if (!$dx) {
                # we have been shifted off the edge
                $in_ostn02_polygon = 0;
                last APPROX
            }

            ($x,$y) = ($e-$dx, $n-$dy);
            last APPROX if abs($dx-$last_dx) < TENTH_MM
                        && abs($dy-$last_dy) < TENTH_MM;
            ($last_dx, $last_dy) = ($dx, $dy);
        }
        if ($in_ostn02_polygon ) {
            return _reverse_project_onto_ellipsoid($e-$dx, $n-$dy, 'WGS84')
        }
    }

    # If we get here, we must use the Helmert approx
    return _shift_ll_from_osgb36_to_wgs84($os_lat, $os_lon)
}

sub grid_to_ll_helmert {
    my ($e, $n) = @_;
    my ($os_lat, $os_lon) = _reverse_project_onto_ellipsoid($e, $n, 'OSGB36');
    return _shift_ll_from_osgb36_to_wgs84($os_lat, $os_lon)
}

sub _reverse_project_onto_ellipsoid {

    my ( $easting, $northing, $shape ) = @_;

    my ( $a, $b, $f, $e2 ) = @{ ELLIPSOIDS->{$shape} };

    my $n = ( $a - $b ) / ( $a + $b );
    my $af = $a * CONVERGENCE_FACTOR;

    my $dn = $northing - ORIGIN_NORTHING;
    my $de = $easting - ORIGIN_EASTING;

    my $phi = ORIGIN_LATITUDE + $dn/$af;
    my $lam = ORIGIN_LONGITUDE; 

    my ($M, $p_plus, $p_minus);
    while (1) {
        $p_plus  = $phi + ORIGIN_LATITUDE;
        $p_minus = $phi - ORIGIN_LATITUDE;
        $M = $b * CONVERGENCE_FACTOR * (
               (1 + $n * (1 + 5/4*$n*(1 + $n)))*$p_minus
             - 3*$n*(1+$n*(1+7/8*$n))  * sin(  $p_minus) * cos(  $p_plus)
             + (15/8*$n * ($n*(1+$n))) * sin(2*$p_minus) * cos(2*$p_plus)
             - 35/24*$n**3             * sin(3*$p_minus) * cos(3*$p_plus)
               );
        last if abs($dn-$M) < HUNDREDTH_MM;
        $phi = $phi + ($dn-$M)/$af;
    }

    my $cp = cos $phi; 
    my $sp = sin $phi; 
    my $tp  = $sp / $cp; # cos phi cannot be zero in GB

    my $splat = 1 - $e2 * $sp * $sp;
    my $sqrtsplat = sqrt $splat;
    my $nu  = $af / $sqrtsplat;
    my $rho = $af * (1 - $e2) / ( $splat * $sqrtsplat );
    my $eta2 = $nu / $rho - 1;

    my $VII  = $tp / (2 * $rho * $nu);
    my $VIII = $tp / (24 * $rho * $nu**3) * (5 + $eta2 + ( 3 - 9 * $eta2 ) * $tp * $tp );
    my $IX   = $tp / (720 * $rho * $nu**5) * (61 + ( 90 + 45 * $tp * $tp ) * $tp * $tp );

    my $secp = 1/$cp;

    my $X    = $secp / $nu;
    my $XI   = $secp / (    6 * $nu**3 ) * ( $nu / $rho + 2 * $tp * $tp );
    my $XII  = $secp / (  120 * $nu**5 ) * ( 5 + ( 28 + 24 * $tp * $tp ) * $tp * $tp );
    my $XIIA = $secp / ( 5040 * $nu**7 ) * ( 61 + ( 662 + ( 1320 + 720 * $tp * $tp ) * $tp * $tp ) * $tp * $tp );

    $phi = $phi +        ( -$VII + ( $VIII - $IX * $de * $de ) * $de * $de) * $de * $de;
    $lam = $lam + ( $X + ( -$XI + ( $XII - $XIIA * $de * $de ) * $de * $de) * $de * $de) * $de;

    # now put into degrees & return
    return ($phi * 57.29577951308232087679815481410517,
            $lam * 57.29577951308232087679815481410517);
}

1;

=pod

=head1 NAME

Geo::Coordinates::OSGB - Convert coordinates between Lat/Lon and the British National Grid

An implementation of co-ordinate conversion for England, Wales, and Scotland
based on formulae and data published by the Ordnance Survey of Great Britain.

=head1 VERSION

2.20

=for HTML <a href="https://travis-ci.org/thruston/perl-geo-coordinates-osgb">
<img src="https://travis-ci.org/thruston/perl-geo-coordinates-osgb.svg?branch=master"></a>

=head1 SYNOPSIS

  use Geo::Coordinates::OSGB qw(ll_to_grid grid_to_ll);

  ($easting,$northing) = ll_to_grid($lat,$lon);
  ($lat,$lon) = grid_to_ll($easting,$northing);

=head1 DESCRIPTION

These modules convert accurately between OSGB national grid references and
coordinates given in latitude and longitude.

The default "ellipsoid model" used for the conversions is the I<de facto>
international standard WGS84.  This means that you can take latitude and
longitude readings from your GPS receiver, or read them from Wikipedia, or
Google Earth, or your car's sat-nav, and use this module to convert them to
accurate British National grid references for use with one of the Ordnance
Survey's paper maps.  And I<vice versa>, of course.

The module is implemented purely in Perl, and should run on any platform with
Perl version 5.8 or better.

In this description, the abbreviations `OS' and `OSGB' mean `the Ordnance
Survey of Great Britain': the British government agency that produces the
standard maps of England, Wales, and Scotland.  Any mention of `sheets' or
`maps' refers to one or more of the map sheets defined in the accompanying maps
module.

This code is written for the British national grid system.  It is of no use
outside Britain.  In fact it's only really useful in the areas covered by the
OS's main series of maps, which exclude the Channel Islands and Northern
Ireland.

=head1 SUBROUTINES/METHODS

The following functions can be exported from the
C<Geo::Coordinates::OSGB> module:

    grid_to_ll 
    ll_to_grid

Neither of these is exported by default.

=head2 Main subroutines

=head3 C<ll_to_grid(lat, lon)>

C<ll_to_grid> translates a latitude and longitude pair into a grid
easting and northing pair.

When called in a list context, C<ll_to_grid> returns the easting and
northing as a list of two.  When called in a scalar context, it returns
a single string with the numbers separated by a space.

The arguments should be supplied as real numbers representing
decimal degrees, like this:

    my ($e,$n) = ll_to_grid(51.5, -2.1); # (393154.801, 177900.605)

Following the normal mathematical convention, positive arguments mean North or
East, negative South or West.

If you have data with degrees, minutes, and seconds, you can convert them
to decimals like this:

    my ($e,$n) = ll_to_grid(51+25/60, 0-5/60-2/3600);

If you have trouble remembering the order of the arguments, or the returned
values, note that latitude comes before longitude in the alphabet too, as
easting comes before northing.  However, since reasonable latitudes for the
OSGB are in the range 49 to 61, and reasonable longitudes in the range -9 to
+2, C<ll_to_grid> accepts the arguments in either order; if your longitude is
larger than your latitude, then the values of the arguments will be silently
swapped.

You can also supply the arguments as named keywords (but be sure to use
the curly braces so that you pass them as a reference):

    my ($e,$n) = ll_to_grid( { lat => 51.5, lon => -2.1 } );

The easting and northing will be returned as the orthogonal distances in metres
from the `false point of origin' of the British Grid (which is a point some way
to the south-west of the Scilly Isles).  The returned pair refers to a point on
the usual OSGB grid, which extends from the Scilly Isles in the south west to
the Shetlands in the north.

    my ($e,$n) = ll_to_grid(51.5, -2.1); # (393154.807, 177900.595)
    my $s      = ll_to_grid(51.5, -2.1); # "393154.807 177900.595"

If the coordinates you supply are in the area covered by the OSTN
transformation data, then the results will be rounded to 3 decimal places,
which corresponds to the nearest millimetre.  If they are outside the coverage
then the conversion is automagically done using a Helmert transformation
instead of the OSTN data.  The results will be rounded to the nearest metre
in this case, although you probably should not rely on the results being more
accurate than about 5m.

With the older OSTN02 dataset, coverage extended only to about 3km offshore, 
but the current OSTN15 dataset extends coverage to the whole grid area 
from (0,0) to (700000, 1250000), so you have be really far away to get 
whole metres.  Even points well away from land, like this one:

   # A point in the sea, to the north-west of Coll
   my $s = ll_to_grid(56.75,-7);

will get an accurate conversion.  With OSTN02 that returned C<94471 773206>
but with OSTN15 you get C<94469.597 773209.464>.  For your sake, I hope you are
never in a situation at sea off Coll where the 3 metres difference is important.

The numbers returned may be negative if your latitude and longitude are
far enough south and west, but beware that the transformation is less
and less accurate or useful the further you get from the British Isles.

If you want the result presented in a more traditional grid reference
format you should pass the results to one of the grid formatting
routines from L<Grid.pm|Geo::Coordinates::OSGB::Grid>.  Like this.

    my $s = ll_to_grid(51.5, -2.1);              # "393154.807 177900.595"
    $s = format_grid(ll_to_grid(51.5,-2.1));     # "ST 931 779"
    $s = format_grid_GPS(ll_to_grid(51.5,-2.1)); # "ST 93154 77900"
    $s = format_grid_map(ll_to_grid(51.5,-2.1)); # "ST 931 779 on A:173, B:156, C:157"

C<ll_to_grid()> also takes an optional argument that sets the ellipsoid
model to use.  This defaults to `WGS84', the name of the normal model
for working with normal GPS coordinates, but if you want to work with
the traditional latitude and longitude values printed around the edges of
OS maps before 2015 then you should add an optional shape parameter like this:

    my ($e, $n) = ll_to_grid(49,-2, {shape => 'OSGB36'});

Incidentally, if you make this call above you will get back
C<(400000, -100000)> which are the coordinates of the `true point of origin'
of the British grid.  You should get back an easting of 400000 for any
point with longitude 2W since this is the central meridian used for the
OSGB projection.  However you will get a slightly different value unless
you specify C<< {shape => 'OSGB36'} >> because the WGS84 meridians are not
quite the same as OSGB36.

=head3 C<grid_to_ll(e,n)>

The routine C<grid_to_ll()> takes an easting and northing pair
representing the distance in metres from the `false point of origin' of
the OSGB grid and returns a pair of real numbers representing the
equivalent longitude and latitude coordinates in the WGS84 model.

Following convention, positive results are North of the equator and East
of the prime meridian, negative numbers are South and West.  The
fractional parts of the results represent decimal fractions of degrees.

No special processing is done in scalar context because there is no
obvious assumption about how to round the results.  You will just get
the length of the list returned, which is 2.

The arguments must be an (easting, northing) pair representing the
absolute grid reference in metres from the point of origin.  You can get
these from a traditional grid reference string by calling
C<parse_grid()> first.

    my ($lat, $lon) = grid_to_ll(parse_grid('SM 349 231'))

An optional last argument defines the ellipsoid model to use just as it
does for C<ll_to_grid()>.  This is only necessary is you are working
with an ellipsoid model other than WGS84.  Pass the argument as a hash
ref with a `shape' key.

    my ($lat, $lon) = grid_to_ll(400000, 300000, {shape => 'OSGB36'});

If you like named arguments then you can use a single hash ref for all
of them (this is strictly optional):

    my ($lat, $lon) = grid_to_ll({ e => 400000, n => 300000, shape => 'OSGB36'});

The results returned will be floating point numbers with the default
Perl precision.  Unless you are running with long double precision
floats you will get 13 decimal places for latitude and 14 places for
longitude;  but this does not mean that the calculations are accurate to
that many places.  The OS online conversion tools return decimal degrees
to only 6 places.  A difference of 1 in the sixth decimal place
represents a distance on the ground of about 10 cm.  This is probably a
good rule of thumb for the reliability of these calculations, but all
the available decimal places are returned so that you can choose the
rounding that is appropriate for your application.  Here's one way to do
that:

    my ($lat, $lon) = map { sprintf "%.6f", $_ } grid_to_ll(431234, 312653);


=head2 Additional subroutines

=head3 C<set_default_shape(shape)>

The default ellipsoid shape used for conversion to and from latitude and
longitude is `WGS84' as used in the international GPS system.  This
default is set every time that  you load the module.  If you want to
process or produce a large number latitude and longitude coordinates in
the British Ordnance Survey system (as printed round the edges of OS
Landranger and Explorer maps before 2015) you can use C<< set_default_shape('OSGB36'); >> to
set the default shape to OSGB36.  This saves you having to add C<< {
shape => 'OSGB36' } >> to every call of C<ll_to_grid> or C<grid_to_ll>.

You can use C<< set_default_shape('WGS84'); >> to set the default shape back
to WGS84 again when finished with OSGB36 coordinates.

=head3 C<ll_to_grid_helmert(lat, lon)>

You can use this function to do a conversion from WGS84 lat/lon
to the OS grid without using the whole OSTN data set.  The algorithm
used is known as a Helmert transformation.  This is the usual coordinate
conversion algorithm implemented in most consumer-level GPS devices, which 
generally do not have enough memory space for the whole of OSTN.  It
is based on parameters supplied by the OS; they suggest that in most of
the UK this conversion is accurate to within about 5m.

    my ($e, $n) = ll_to_grid_helmert(51.477811, -0.001475);  # RO Greenwich

The input must be decimal degrees in the WGS84 model, with latitude
first and longitude second.  The results are rounded to the nearest
whole metre.  They can be used with C<format_grid> in the same way as
the results from C<ll_to_grid>.

This function is called automatically by C<ll_to_grid> if your
coordinates are WGS84 and lie outside the OSTN polygon.

=head3 C<grid_to_ll_helmert(e,n)>

You can use this function to do a slightly quicker conversion from OS grid
references to WGS84 latitude and longitude coordinates without using the
whole OSTN data set.  The algorithm used is known as a Helmert
transformation.  This is the usual coordinate conversion algorithm
implemented in most consumer-level GPS devices.  It is based on
parameters supplied by the OS; they suggest that in most of the UK this
conversion is accurate to within about 5m.

    my ($lat, $lon) = grid_to_ll_helmert(538885, 177322);

The input must be in metres from false point of origin (as produced by
C<parse_grid>) and the results are in decimal degrees using the WGS84
model.

The results are returned with the full Perl precision in the same way as
C<grid_to_ll> so that you can choose an appropriate rounding for your
needs.  Four or five decimal places is probably appropriate in most
cases.  This represents somewhere between 1 and 10 m on the ground.

This function is called automatically by C<grid_to_ll> if the grid reference
you supply lies outside the OSTN polygon.  (All such spots are far out to sea).
The results are only useful close to mainland Britain.

=head3 Importing all the functions

You can import all the functions defined in C<OSGB.pm> with an C<:all> tag.

    use Geo::Coordinates::OSGB ':all';

=head1 EXAMPLES

  use Geo::Coordinates::OSGB qw/ll_to_grid grid_to_ll/;

  # Latitude and longitude according to the WGS84 model
  ($lat, $lon) = grid_to_ll($e, $n);

  # and to go the other way
  ($e, $n) = ll_to_grid($lat,$lon);

See the test files for more examples of usage.

=head1 BUGS AND LIMITATIONS

The formulae supplied by the OS and used for the conversion routines are
specifically designed to be close floating-point approximations rather
than exact mathematical equivalences.  So after round-trips like these:

  ($lat1,$lon1) = grid_to_ll(ll_to_grid($lat0,$lon0));
  ($e1,$n1)     = ll_to_grid(grid_to_ll($e0,$n0));

neither C<$lat1 == $lat0> nor C<$lon1 == $lon0> nor C<$e1 == $e0> nor
C<$n1 == $n0> exactly.  However the differences should be very small.

The OS formulae were designed to give an accuracy of about 1 mm of
error.  This means that you can rely on the third decimal place for grid
references and about the seventh or eighth for latitude and longitude
(although the OS themselves only provide six decimal places in their
results).

For all of England, Wales, Scotland, and the Isle of Man the error will be
tiny.  All other areas, like Northern Ireland, the Channel Islands or Rockall,
and any areas of sea more than a few miles off shore, are outside the coverage
of OSTN, so the simpler, less accurate transformation is used.  The OS state
that this is accurate to about 5m but that the parameters used are only valid
in the reasonably close vicinity of the British Isles.

Not enough testing has been done.  I am always grateful for the feedback
I get from users, but especially for problem reports that help me to
make this a better module.

=head1 DIAGNOSTICS

The only error message you will get from this module is about the
ellipsoid shape used for the transformation.  If you try to set C<<
{shape => 'blah'} >> the module will croak with a message saying
C<Unknown shape: blah>.  The shape should be one of the shapes defined:
WGS84 or OSGB36.

Should this software not do what you expect, then please first read this
documentation, secondly verify that you have installed it correctly and
that it passes all the installation tests on your set up, thirdly study
the source code to see what it's supposed to be doing, fourthly get in
touch to ask me about it.

=head1 CONFIGURATION AND ENVIRONMENT

There is no configuration required either of these modules or your
environment.  It should work on any recent version of Perl, on any
platform.

=head1 DEPENDENCIES

Perl 5.10 or better.

=head1 INCOMPATIBILITIES

None known.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2002-2017 Toby Thurston

OSTN transformation data included in this module is freely available
from the Ordnance Survey but remains Crown Copyright (C) 2002

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=head1 AUTHOR

Toby Thurston -- 29 Oct 2017 

toby@cpan.org

=head1 SEE ALSO

See L<Geo::Coordinates::OSGB::Grid> for routines to format grid references.

The UK Ordnance Survey's explanations on their web pages.

See L<Geo::Coordinates::Convert> for a general approach (not based on the OSGB).

=cut

