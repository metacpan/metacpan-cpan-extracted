# Copyrights 2011 by Sorin Alexandru Pop.
# For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.

package Geo::Calc;

use vars '$VERSION';
$VERSION = '0.12';

use Moose;
use MooseX::FollowPBP;
use MooseX::Method::Signatures;

use Math::Trig qw(:pi asin acos tan deg2rad rad2deg);
use Math::BigFloat;
use Math::BigInt;
use Math::Units qw(convert);
use POSIX qw(modf fmod);

=head1 NAME

Geo::Calc - simple geo calculator for points and distances

=head1 SYNOPSIS

 use Geo::Calc;

 my $gc            = Geo::Calc->new( lat => 40.417875, lon => -3.710205 );
 my $distance      = $gc->distance_to( { lat => 40.422371, lon => -3.704298 }, -6 );
 my $brng          = $gc->bearing_to( { lat => 40.422371, lon => -3.704298 }, -6 );
 my $f_brng        = $gc->final_bearing_to( { lat => 40.422371, lon => -3.704298 }, -6 );
 my $midpoint      = $gc->midpoint_to( { lat => 40.422371, lon => -3.704298 }, -6 );
 my $destination   = $gc->destination_point( 90, 1, -6 );
 my $bbox          = $gc->boundry_box( 3, 4, -6 );
 my $r_distance    = $gc->rhumb_distance_to( { lat => 40.422371, lon => -3.704298 }, -6 );
 my $r_brng        = $gc->rhumb_bearing_to( { lat => 40.422371, lon => -3.704298 }, -6 );
 my $r_destination = $gc->rhumb_destination_point( 30, 1, -6 );
 my $point         = $gc->intersection( 90, { lat => 40.422371, lon => -3.704298 }, 180, -6 );

=head1 DESCRIPTION

C<Geo::Calc> implements a variety of calculations for latitude/longitude points

All these formulare are for calculations on the basis of a spherical earth
(ignoring ellipsoidal effects) which is accurate enough* for most purposes.

[ In fact, the earth is very slightly ellipsoidal; using a spherical model
gives errors typically up to 0.3% ].

=head1 Geo::Calc->new()

 $gc = Geo::Calc->new( lat => 40.417875, lon => -3.710205 ); # Somewhere in Madrid
 $gc = Geo::Calc->new( lat => 51.503269, lon => 0, units => 'k-m' ); # The O2 Arena in London

Creates a new Geo::Calc object from a latitude and longitude. The default
deciaml precision is -6 for all functions => meaning by default it always
returns the results with 6 deciamls.

The default unit distance is 'm' (meter), but you cand define another unit using 'units'.
Accepted values are: 'm' (meters), 'k-m' (kilometers), 'yd' (yards), 'ft' (feet) and 'mi' (miles)

Returns ref to a Geo::Calc object.

=head2 Parameters

=over 4

=item lat

C<>=> latitude of the point ( required )

=item lon

C<>=> longitude of the point ( required )

=item radius

C<>=> earth radius in km ( defaults to 6371 )

=back

=cut

has 'lat' => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
);

has 'lon' => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
);

has 'radius' => (
    is       => 'ro',
    isa      => 'Num',
    default  => '6371',
);

has 'supported_units' => (
    is       => 'ro',
    isa      => 'ArrayRef',
    lazy     => 0,
    builder  => '_build_supported_units',
);

has 'units' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 0,
    builder  => '_build_default_unit',
);

sub _build_supported_units {
    my $self = shift;

    return [ 'm', 'k-m', 'yd', 'ft', 'mi' ];
}

sub _build_default_unit {
    my $self = shift;

    if ( !defined( $self->{units} ) ) {
        return 'm'; # Defaults to meters
    } else { # As smartmatch does not work on 5.x < 10
        foreach( @{ $self->get_supported_units() } ) {
            return $_ if( $_ eq $self->{units} );
        }
        die sprintf( 'Unsupported unit "%s"! Supported units are: %s', $self->{units}, join(', ', @{$self->get_supported_units()} ) );
    }
}

=head1 METHODS

=head2 distance_to

 $gc->distance_to( $point[, $precision] )
 $gc->distance_to( { lat => 40.422371, lon => -3.704298 } )

This uses the "haversine" formula to calculate great-circle distances between
the two points - that is, the shortest distance over the earth's surface -
giving an `as-the-crow-flies` distance between the points (ignoring any hills!)

The haversine formula `remains particularly well-conditioned for numerical
computation even at small distances` - unlike calculations based on the spherical
law of cosines. It was published by R W Sinnott in Sky and Telescope, 1984,
though known about for much longer by navigators. (For the curious, c is the
angular distance in radians, and a is the square of half the chord length between
the points).

Returns with the distance using the precision defined or -6
( -6 = 6 decimals ( eg 4.000001 ) )

=cut

method distance_to( HashRef[Num] $point!, Int $precision? = -6 ) returns (Num) {
    my ( $lat1, $lon1, $lat2, $lon2 ) = (
            Math::Trig::deg2rad( $self->get_lat() ),
            Math::Trig::deg2rad( $self->get_lon() ),
            Math::Trig::deg2rad( $point->{lat} ),
            Math::Trig::deg2rad( $point->{lon} ),
    );

    my $t = sin( ($lat2 - $lat1)/2 ) ** 2 + ( cos( $lat1 ) ** 2 ) * ( sin( ( $lon2 - $lon1 )/2 ) ** 2 );
    my $d = $self->get_radius * ( 2 * atan2( sqrt($t), sqrt(1-$t) ) );

    # Convert from kilometers to the desired distance unit
    return $self->_precision( Math::Units::convert( $d, 'k-m', $self->get_units() ), $precision );
}

=head2 bearing_to

 $gc->bearing_to( $point[, $precision] );
 $gc->bearing_to( { lat => 40.422371, lon => -3.704298 }, -6 );

In general, your current heading will vary as you follow a great circle path
(orthodrome); the final heading will differ from the initial heading by varying
degrees according to distance and latitude (if you were to go from say 35N,45E
(Baghdad) to 35N,135E (Osaka), you would start on a heading of 60 and end up on
a heading of 120!).

This formula is for the initial bearing (sometimes referred to as forward
azimuth) which if followed in a straight line along a great-circle arc will take
you from the start point to the end point

Returns the (initial) bearing from this point to the supplied point, in degrees
with the specified pricision

see http://williams.best.vwh.net/avform.htm#Crs

=cut

method bearing_to( HashRef[Num] $point!, Int $precision? = -6 ) returns (Num) {
    my ( $lat1, $lat2, $dlon ) = (
            Math::Trig::deg2rad( $self->get_lat() ),
            Math::Trig::deg2rad( $point->{lat} ),
            Math::Trig::deg2rad( $self->get_lon() - $point->{lon} ),
    );

    my $brng = atan2( sin( $dlon ) * cos( $lat2 ), ( cos( $lat1 ) * sin( $lat2 ) ) - ( sin( $lat1 ) * cos( $lat2 ) * cos( $dlon ) ) );

    return $self->_ib_precision( $brng, $precision, -1 );
}

=head2 final_bearing_to

 my $f_brng = $gc->final_bearing_to( $point[, $precision] );
 my $f_brng = $gc->final_bearing_to( { lat => 40.422371, lon => -3.704298 } );

Returns final bearing arriving at supplied destination point from this point;
the final bearing will differ from the initial bearing by varying degrees
according to distance and latitude

=cut

method final_bearing_to( HashRef[Num] $point!, Int $precision? = -6 ) returns (Num) {

    my ( $lat1, $lat2, $dlon ) = (
            Math::Trig::deg2rad( $point->{lat} ),
            Math::Trig::deg2rad( $self->get_lat() ),
            - Math::Trig::deg2rad( $point->{lon} - $self->get_lon() )
    );

    my $brng = atan2( sin( $dlon ) * cos( $lat2 ), ( cos( $lat1 ) * sin( $lat2 ) ) - ( sin( $lat1 ) * cos( $lat2 ) * cos( $dlon ) ) );

    return $self->_fb_precision( $brng, $precision );
}

=head2 midpoint_to

 $gc->midpoint_to( $point[, $precision] );
 $gc->midpoint_to( { lat => 40.422371, lon => -3.704298 } );

Returns the midpoint along a great circle path between the initial point and
the supplied point.

see http://mathforum.org/library/drmath/view/51822.html for derivation

=cut

method midpoint_to( HashRef[Num] $point!, Int $precision? = -6 ) returns (HashRef[Num]) {
    my ( $lat1, $lon1, $lat2, $dlon ) = (
            Math::Trig::deg2rad( $self->get_lat() ),
            Math::Trig::deg2rad( $self->get_lon() ),
            Math::Trig::deg2rad( $point->{lat} ),
            Math::Trig::deg2rad( $point->{lon} - $self->get_lon() ),
    );

    my $bx = cos( $lat2 ) * cos( $dlon );
    my $by = cos( $lat2 ) * sin( $dlon );

    my $lat3 = atan2( sin( $lat1 ) + sin ( $lat2 ), sqrt( ( ( cos( $lat1 ) + $bx ) ** 2 ) + ( $by ** 2 ) ) );
    my $lon3 = POSIX::fmod( $lon1 + atan2( $by, cos( $lat1 ) + $bx ) + ( pi * 3 ), pi2 ) - pi;

    return {
        lat => $self->_precision( Math::Trig::rad2deg($lat3), $precision ),
        lon => $self->_precision( Math::Trig::rad2deg($lon3), $precision ),
    };
}

=head2 destination_point

 $gc->destination_point( $bearing, $distance[, $precision] );
 $gc->destination_point( 90, 1 );

Returns the destination point and the final bearing using Vincenty inverse
formula for ellipsoids.

=cut

method destination_point ( Num $brng!, Num $s!, Int $precision? = -6 ) returns (HashRef[Num]) {
    my $lat1 = $self->get_lat();
    my $lon1 = $self->get_lon();

    $s = Math::Units::convert( $s, $self->get_units(), 'm' );

    my $r_major = 6378137;           # Equatorial Radius, WGS84
    my $r_minor = 6356752.314245179; # defined as constant
    my $f       = 1/298.257223563;   # 1/f=( $r_major - $r_minor ) / $r_major

    my $alpha1 = Math::Trig::deg2rad( $brng );
    my $sinAlpha1 = sin( $alpha1 );
    my $cosAlpha1 = cos( $alpha1 );

    my $tanU1 = ( 1 - $f ) * tan( Math::Trig::deg2rad( $lat1 ) );

    my $cosU1 = 1 / sqrt( (1 + $tanU1*$tanU1) );
    my $sinU1 = $tanU1 * $cosU1;
    my $sigma1 = atan2( $tanU1, $cosAlpha1 );
    my $sinAlpha = $cosU1 * $sinAlpha1;
    my $cosSqAlpha = 1 - $sinAlpha*$sinAlpha;

    my $uSq = $cosSqAlpha * ( ( $r_major * $r_major ) - ( $r_minor * $r_minor ) ) / ( $r_minor * $r_minor );
    my $A = 1 + $uSq/16384*(4096+$uSq*(-768+$uSq*(320-175*$uSq)));
    my $B = $uSq/1024 * (256+$uSq*(-128+$uSq*(74-47*$uSq)));

    my $sigma = $s / ($r_minor*$A);
    my $sigmaP = pi2;

    my $cos2SigmaM = cos(2*$sigma1 + $sigma);
    my $sinSigma = sin($sigma);
    my $cosSigma = cos($sigma);

    while ( abs($sigma-$sigmaP) > 1e-12 ) {
        $cos2SigmaM = cos(2*$sigma1 + $sigma);
        $sinSigma = sin($sigma);
        $cosSigma = cos($sigma);

        my $deltaSigma = $B*$sinSigma*($cos2SigmaM+$B/4*($cosSigma*(-1+2*$cos2SigmaM*$cos2SigmaM)-
          $B/6*$cos2SigmaM*(-3+4*$sinSigma*$sinSigma)*(-3+4*$cos2SigmaM*$cos2SigmaM)));
        $sigmaP = $sigma;
        $sigma = $s / ($r_minor*$A) + $deltaSigma;
    }

    my $tmp = $sinU1*$sinSigma - $cosU1*$cosSigma*$cosAlpha1;
    my $lat2 = atan2( $sinU1*$cosSigma + $cosU1*$sinSigma*$cosAlpha1, (1-$f)*sqrt($sinAlpha*$sinAlpha + $tmp*$tmp) );

    my $lambda = atan2($sinSigma*$sinAlpha1, $cosU1*$cosSigma - $sinU1*$sinSigma*$cosAlpha1);
    my $C = $f/16*$cosSqAlpha*(4+$f*(4-3*$cosSqAlpha));
    my $L = $lambda - (1-$C) * $f * $sinAlpha * ($sigma + $C*$sinSigma*($cos2SigmaM+$C*$cosSigma*(-1+2*$cos2SigmaM*$cos2SigmaM)));

    # Normalize longitude so that its in range -PI to +PI
    my $lon2 = POSIX::fmod( Math::Trig::deg2rad( $lon1 ) + $L + ( pi * 3 ), pi2 ) - pi;
    my $revAz = atan2($sinAlpha, -$tmp);  # final bearing, if required

    return {
        lat => $self->_precision( Math::Trig::rad2deg($lat2), $precision ),
        lon => $self->_precision( Math::Trig::rad2deg($lon2), $precision ),
        final_bearing => $self->_precision( Math::Trig::rad2deg($revAz), $precision ),
    };
}

=head2 destination_point_hs

 $gc->destination_point_hs( $bearing, $distance[, $precision] );
 $gc->destination_point_hs( 90, 1 );

Returns the destination point from this point having travelled the given
distance on the given initial bearing (bearing may vary before destination is
reached)

see http://williams.best.vwh.net/avform.htm#LL

=cut

method destination_point_hs( Num $brng!, Num $dist!, Int $precision? = -6 ) returns (HashRef[Num]) {
    $dist = Math::Units::convert( $dist, $self->get_units(), 'k-m' );

    $dist = $dist / $self->get_radius();
    $brng = Math::Trig::deg2rad( $brng );
    my $lat1 = Math::Trig::deg2rad( $self->get_lat() );
    my $lon1 = Math::Trig::deg2rad( $self->get_lon() );

    my $lat2 = asin( sin( $lat1 ) * cos( $dist ) + cos( $lat1 ) * sin( $dist ) * cos( $brng ) );
    my $lon2 = $lon1 + atan2( sin( $brng ) * sin( $dist ) * cos( $lat1 ), cos( $dist ) - sin( $lat1 ) * sin ( $lat2 ) );

    # Normalize longitude so that its in range -PI to +PI
    $lon2 = POSIX::fmod( Math::Trig::deg2rad( $lon2 ) + ( pi * 3 ), pi2 ) - pi;

    return {
        lat => $self->_precision( Math::Trig::rad2deg($lat2), $precision ),
        lon => $self->_precision( Math::Trig::rad2deg($lon2), $precision ),
    };
}

=head2 boundry_box

 $gc->boundry_box( $width[, $height[, $precision]] ); # in km
 $gc->boundry_box( 3, 4 ); # will generate a 3x4m box around the point
 $gc->boundry_box( 1 ); # will generate a 2x2m box around the point (radius)

Returns the boundry box min/max having the initial point defined as the center
of the boundry box, given the widht and height

=cut

method boundry_box( Num $width!, Maybe[Num] $height?, Int $precision? = -6 ) returns (HashRef[Num]) {
    if( !defined( $precision ) ) {
        $width *= 2;
        $height = $width;
        $precision = -6;
    } elsif( !defined( $height ) ) {
        $width *= 2;
        $height = $width;
    }

    my @points = ();
    push @points, $self->destination_point( 0,   $height / 2, $precision );
    push @points, $self->destination_point( 90,  $width  / 2, $precision );
    push @points, $self->destination_point( 180, $height / 2, $precision );
    push @points, $self->destination_point( 270, $width  / 2, $precision );

    return {
        lat_min => $points[2]->{lat},
        lon_min => $points[3]->{lon},
        lat_max => $points[0]->{lat},
        lon_max => $points[1]->{lon},
    };
}

=head2 rhumb_distance_to

 $gc->rhumb_distance_to( $point[, $precision] );
 $gc->rhumb_distance_to( { lat => 40.422371, lon => -3.704298 } );

Returns the distance from this point to the supplied point, in km, travelling
along a rhumb line.

A 'rhumb line' (or loxodrome) is a path of constant bearing, which crosses all
meridians at the same angle.

Sailors used to (and sometimes still) navigate along rhumb lines since it is
easier to follow a constant compass bearing than to be continually adjusting
the bearing, as is needed to follow a great circle. Rhumb lines are straight
lines on a Mercator Projection map (also helpful for navigation).

Rhumb lines are generally longer than great-circle (orthodrome) routes. For
instance, London to New York is 4% longer along a rhumb line than along a
great circle . important for aviation fuel, but not particularly to sailing
vessels. New York to Beijing . close to the most extreme example possible
(though not sailable!) . is 30% longer along a rhumb line.

see http://williams.best.vwh.net/avform.htm#Rhumb

=cut

method rhumb_distance_to( HashRef[Num] $point!, Int $precision? = -6 ) returns (Num) {
    my ( $lat1, $lat2, $dlat, $dlon ) = (
            Math::Trig::deg2rad( $self->get_lat() ),
            Math::Trig::deg2rad( $point->{lat} ),
            Math::Trig::deg2rad( $point->{lat} - $self->get_lat() ),
            abs( Math::Trig::deg2rad( $point->{lon} - $self->get_lon() ) ),
    );

    my $dphi = log( tan( $lat2/2 + pip4 ) / tan( $lat1/2 + pip4 ) );
    my $q = ( $dphi != 0 ) ? $dlat/$dphi : cos($lat1);# E-W line gives dPhi=0
    $dlon = pi2 - $dlon if ( $dlon > pi );

    my $dist = sqrt( ( $dlat ** 2 ) + ( $q ** 2 ) * ( $dlon ** 2 ) ) * $self->get_radius();

    return $self->_precision( Math::Units::convert( $dist, 'k-m', $self->get_units() ), $precision );
}

=head2 rhumb_bearing_to

 $gc->rhumb_bearing_to( $point[, $precision] );
 $gc->rhumb_bearing_to( { lat => 40.422371, lon => -3.704298 } );

Returns the bearing from this point to the supplied point along a rhumb line,
in degrees

=cut

method rhumb_bearing_to( HashRef[Num] $point!, Int $precision? = -6 ) returns (Num) {
    my ( $lat1, $lat2, $dlon ) = (
            Math::Trig::deg2rad( $self->get_lat() ),
            Math::Trig::deg2rad( $point->{lat} ),
            Math::Trig::deg2rad( $point->{lon} - $self->get_lon() ),
    );

    my $dphi = log( tan( $lat2/2 + pip4 ) / tan( $lat1/2 + pip4 ) );
    if( abs( $dlon ) > pi ) {
        $dlon = ( $dlon > 0 ) ? -(pi2-$dlon) : (pi2+$dlon);
    }

    return $self->_ib_precision( atan2( $dlon, $dphi ), $precision, 1 );
#    return $self->_ib_precision( Math::Trig::rad2deg( atan2( $dlon, $dphi ) ), $precision );
}

=head2 rhumb_destination_point

 $gc->rhumb_destination_point( $brng, $distance[, $precision] );
 $gc->rhumb_destination_point( 30, 1 );

Returns the destination point from this point having travelled the given distance
(in km) on the given bearing along a rhumb line.

=cut

method rhumb_destination_point( Num $brng!, Num $dist!, Int $precision? = -6 ) returns (HashRef[Num]) {
    $dist = Math::Units::convert( $dist, $self->get_units(), 'k-m' );

    my $d = $dist / $self->get_radius();
    my ( $lat1, $lon1 );
    ( $lat1, $lon1 , $brng ) = ( 
            Math::Trig::deg2rad( $self->get_lat() ),
            Math::Trig::deg2rad( $self->get_lon() ),
            Math::Trig::deg2rad( $brng ),
    );

    my $lat2 = $lat1 + ( $d * cos( $brng ) );

    my $dlat = $lat2 - $lat1;
    my $dphi = log( tan( $lat2/2 + pip4 ) / tan( $lat1/2 + pip4 ) );
    my $q = ( $dphi != 0 ) ? $dlat/$dphi : cos($lat1);# E-W line gives dPhi=0
    my $dlon = $d * sin( $brng ) / $q;

    # check for some daft bugger going past the pole
    if ( abs( $lat2 ) > pip2 ) {
        $lat2 = ( $lat2 > 0 ) ? pi-$lat2 : -(pi-$lat2);
    }
    my $lon2 = POSIX::fmod( $lon1 + $dlon + ( pi * 3 ), pi2 ) - pi;

    return {
        lat => $self->_precision( Math::Trig::rad2deg($lat2), $precision ),
        lon => $self->_precision( Math::Trig::rad2deg($lon2), $precision ),
    };
}


=head2 intersection

 $gc->intersection( $brng1, $point, $brng2[, $precision] );
 $gc->intersection( 90, { lat => 40.422371, lon => -3.704298 }, 180 );

Returns the point of intersection of two paths defined by point and bearing

see http://williams.best.vwh.net/avform.htm#Intersection

=cut

method intersection( Num $brng1!, HashRef[Num] $point!, Num $brng2!, Int $precision? = -6 ) returns (HashRef[Num]) {
    my ( $lat1, $lon1, $lat2, $lon2, $brng13, $brng23 ) = (
            Math::Trig::deg2rad( $self->get_lat() ),
            Math::Trig::deg2rad( $self->get_lon() ),
            Math::Trig::deg2rad( $point->{lat} ),
            Math::Trig::deg2rad( $point->{lon} ),
            Math::Trig::deg2rad( $brng1 ),
            Math::Trig::deg2rad( $brng2 ),
    );
    my $dlat = $lat2 - $lat1;
    my $dlon = $lon2 - $lon1;

    my $dist12 = 2 * asin( sqrt( ( sin( $dlat/2 ) ** 2 ) + cos( $lat1 ) * cos( $lat2 ) * ( sin( $dlon/2 ) ** 2 ) ) );
    return undef if( $dist12 == 0 );

    #initial/final bearings between points
    my $brnga = acos( ( sin( $lat2 ) - sin( $lat1 ) * cos( $dist12 ) ) / ( sin( $dist12 ) * cos( $lat1 ) ) ) || 0;
    my $brngb = acos( ( sin( $lat1 ) - sin( $lat2 ) * cos( $dist12 ) ) / ( sin( $dist12 ) * cos( $lat2 ) ) ) || 0;

    my ( $brng12, $brng21 );
    if( sin( $dlon ) > 0 ) {
        $brng12 = $brnga;
        $brng21 = pi2 - $brngb;
    } else {
        $brng12 = pi2 - $brnga;
        $brng21 = $brngb;
    }

    my $alpha1 = POSIX::fmod( $brng13 - $brng12 + ( pi * 3 ), pi2 ) - pi;
    my $alpha2 = POSIX::fmod( $brng21 - $brng23 + ( pi * 3 ), pi2 ) - pi;

    return undef if( ( sin( $alpha1 ) == 0 ) and ( sin( $alpha2 ) == 0 ) ); #infinite intersections
    return undef if( sin( $alpha1 ) * sin( $alpha2 ) < 0 ); #ambiguous intersection

    my $alpha3 = acos( -cos( $alpha1 ) * cos( $alpha2 ) + sin( $alpha1 ) * sin( $alpha2 ) * cos( $dist12 ) );
    my $dist13 = atan2( sin( $dist12 ) * sin( $alpha1 ) * sin( $alpha2 ), cos( $alpha2 ) + cos( $alpha1 ) * cos( $alpha3 ) );
    my $lat3 = asin( sin( $lat1 ) * cos( $dist13 ) + cos( $lat1 ) * sin( $dist13 ) * cos( $brng13 ) );
    my $dlon13 = atan2( sin( $brng13 ) * sin( $dist13 ) * cos( $lat1 ), cos( $dist13 ) - sin( $lat1 ) * sin( $lat3 ) );
    my $lon3 = POSIX::fmod( $lon1 + $dlon13 + ( pi * 3 ), pi2 ) - pi;

    return {
        lat => $self->_precision( Math::Trig::rad2deg($lat3), $precision ),
        lon => $self->_precision( Math::Trig::rad2deg($lon3), $precision ),
    };
}

=head2 distance_at

Returns the distance in meters for 1deg of latitude and longitude at the
specified latitude

 my $m_distance = $self->distance_at([$precision]);
 my $m_distance = $self->distance_at();
 # at lat 2 with precision -6 returns { m_lat => 110575.625009, m_lon => 111252.098718 }

=cut

method distance_at(Int $precision? = -6 ) returns (HashRef[Num]) {
    my $lat = deg2rad( $self->get_lat() );

    # Set up "Constants"
    my $m1 = 111132.92; # latitude calculation term 1
    my $m2 = -559.82;   # latitude calculation term 2
    my $m3 = 1.175;     # latitude calculation term 3
    my $m4 = -0.0023;   # latitude calculation term 4
    my $p1 = 111412.84; # longitude calculation term 1
    my $p2 = -93.5;     # longitude calculation term 2
    my $p3 = 0.118;     # longitude calculation term 3 

    return {
        m_lat => $self->_precision( $m1 + ($m2 * cos(2 * $lat)) + ($m3 * cos(4 * $lat)) + ( $m4 * cos(6 * $lat) ), $precision ),
        m_lon => $self->_precision( ( $p1 * cos($lat)) + ($p2 * cos(3 * $lat)) + ($p3 * cos(5 * $lat) ), $precision ),
    }
}

sub _precision {
    my ( $self, $number, $precision ) = @_;

    die "Error: Private method called" unless (caller)[0]->isa( ref($self) );

    my $mbf = Math::BigFloat->new( $number );
    $mbf->precision( $precision );

    return $mbf->bstr() + 0;
}

sub _ib_precision {
    my ( $self, $brng, $precision, $mul ) = @_;

    $mul ||= 1;

    die "Error: Private method called" unless (caller)[0]->isa( ref($self) );

    my $mbf = Math::BigFloat->new( POSIX::fmod( $mul * ( Math::Trig::rad2deg( $brng ) ) + 360, 360 ) );
    $mbf->precision( $precision );

    return $mbf->bstr() + 0;
}

sub _fb_precision {
    my ( $self, $brng, $precision ) = @_;

    die "Error: Private method called" unless (caller)[0]->isa( ref($self) );

    my $mbf = Math::BigFloat->new( POSIX::fmod( ( Math::Trig::rad2deg( $brng ) ) + 180, 360 ) );
    $mbf->precision( $precision );

    return $mbf->bstr() + 0;
}

no Moose;
__PACKAGE__->meta->make_immutable;

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception.

Please report any bugs through the web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Sorin Alexandru Pop C<< <asp@cpan.org> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

__END__

1;
