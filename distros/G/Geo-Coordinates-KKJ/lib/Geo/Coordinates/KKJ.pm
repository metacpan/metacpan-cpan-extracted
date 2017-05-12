package Geo::Coordinates::KKJ;

use 5.008006;
use strict;
use warnings;
use Carp;
use Math::Trig;

require Exporter;

our $VERSION = '0.01';

our @ISA = qw(Exporter);

our @EXPORT = qw(
    KKJxy_to_WGS84lalo
    WGS84lalo_to_KKJxy
    KKJxy_to_KKJlalo
    KKJlalo_to_KKJxy
    KKJlalo_to_WGS84lalo
    WGS84lalo_to_KKJlalo
    KKJ_Zone_I
    KKJ_Zone_Lo
);

my $KKJ_ZONE_INFO = {
    '0' => [ '18.0', '500_000.0' ],
    '1' => [ '21.0', '1_500_000.0' ],
    '2' => [ '24.0', '2_500_000.0' ],
    '3' => [ '27.0', '3_500_000.0' ],
    '4' => [ '30.0', '4_500_000.0' ],
    '5' => [ '33.0', '5_500_000.0' ],
};

sub KKJxy_to_WGS84lalo {
    croak 'Geo::Coordinates::KKJ::KKJxy_to_WGS84lalo needs two arguments'
        if @_ != 2;

    my ( $x,    $y )    = @_;
    my ( $lat,  $lon )  = KKJxy_to_KKJlalo( $x, $y );
    my ( $wlat, $wlon ) = KKJlalo_to_WGS84lalo( $lat, $lon );

    return ( $wlat, $wlon );
}

sub WGS84lalo_to_KKJxy {
    croak 'Geo::Coordinates::KKJ::WGS84lalo_to_KKJxy needs two arguments'
        if @_ != 2;

    my ( $lat, $lon ) = @_;
    my ( $kkjlat, $kkjlon ) = WGS84lalo_to_KKJlalo( $lat, $lon );

    my $zone = KKJ_Zone_Lo($kkjlon);

    my $LALO = {
        'La' => $kkjlat,
        'Lo' => $kkjlon,
    };

    my $foo = KKJlalo_to_KKJxy( $LALO, $zone );

    return ( $foo->{'P'}, $foo->{'I'} );

}

sub KKJxy_to_KKJlalo {
    croak 'Geo::Coordinates::KKJ::KKJxy_to_KKJlalo needs two arguments'
        if @_ != 2;

    my ( $p, $i ) = @_;

    croak "Wrong coordenates" if ( $p < $i );

    my $zone = KKJ_Zone_I($i);
    my $LALO = {};

    my $min_la = deg2rad('59.0');
    my $max_la = deg2rad('70.5');
    my $min_lo = deg2rad('18.5');
    my $max_lo = deg2rad('32.0');

    #Scan iteratively the target area, until find matching
    #KKJ coordinate value.  Area is defined with Hayford Ellipsoid.
    for ( my $count = 1 ; $count < 35 ; $count++ ) {
        my $delta_la = $max_la - $min_la;
        my $delta_lo = $max_lo - $min_lo;

        $LALO->{'La'} = rad2deg( $min_la + 0.5 * $delta_la );
        $LALO->{'Lo'} = rad2deg( $min_lo + 0.5 * $delta_lo );

        my $KKJt = KKJlalo_to_KKJxy( $LALO, $zone );

        if ( $KKJt->{'P'} < $p ) {
            $min_la = $min_la + 0.45 * $delta_la;
        }
        else {
            $max_la = $min_la + 0.55 * $delta_la;
        }

        if ( $KKJt->{'I'} < $i ) {
            $min_lo = $min_lo + 0.45 * $delta_lo;
        }
        else {
            $max_lo = $min_lo + 0.55 * $delta_lo;
        }
    }

    return ( $LALO->{'La'}, $LALO->{'Lo'} );
}

sub KKJlalo_to_KKJxy {
    croak 'Geo::Coordinates::KKJ::KKJlalo_to_KKJxy needs two arguments'
        if @_ != 2;

    my ( $INP, $zone ) = @_;

    my $Lo = deg2rad( $INP->{'Lo'} ) - deg2rad( $KKJ_ZONE_INFO->{$zone}->[0] );

    # Hayford ellipsoid
    my $a = '6378388.0';
    my $f = 1 / 297.0;

    my $b  = ( 1.0 - $f ) * $a;
    my $bb = $b * $b;
    my $c  = ( $a / $b ) * $a;
    my $ee = ( $a * $a - $bb ) / $bb;
    my $n  = ( $a - $b ) / ( $a + $b );
    my $nn = $n * $n;

    my $cosLa = cos( deg2rad( $INP->{'La'} ) );

    my $NN = $ee * $cosLa * $cosLa;

    my $LaF =
      Math::Trig::atan( Math::Trig::tan( deg2rad( $INP->{'La'} ) ) /
          cos( $Lo * sqrt( 1 + $NN ) ) );

    my $cosLaF = cos($LaF);

    my $t =
      ( Math::Trig::tan($Lo) * $cosLaF ) / sqrt( 1 + $ee * $cosLaF * $cosLaF );

    my $A  = $a / ( 1 + $n );
    my $A1 = $A * ( 1 + $nn / 4 + $nn * $nn / 64 );
    my $A2 = $A * 1.5 * $n *     ( 1 - $nn / 8 );
    my $A3 = $A * 0.9375 * $nn * ( 1 - $nn / 4 );
    my $A4 = $A * 35 / 48.0 * $nn * $n;

    my $OUT = {};

    $OUT->{'P'} =
      $A1 * $LaF -
      $A2 * sin( 2 * $LaF ) +
      $A3 * sin( 4 * $LaF ) -
      $A4 * sin( 6 * $LaF );

    $OUT->{'I'} =
      $c * log( $t + sqrt( 1 + $t * $t ) ) + 500_000.0 + $zone * 1_000_000.0;

    return $OUT;
}

sub KKJlalo_to_WGS84lalo {
    croak 'Geo::Coordinates::KKJ::KKJlalo_to_WGS84lalo needs two arguments'
        if @_ != 2;

    my ( $La, $Lo ) = @_;

    my $d_la =
      deg2rad( 0.124867E+01 +
          -0.269982E+00 * $La +
          0.191330E+00 * $Lo +
          0.356119E-02 * $La * $La +
          -0.122312E-02 * $La * $Lo +
          -0.335514E-03 * $Lo * $Lo ) / 3600.0;

    my $d_lo =
      deg2rad( -0.286111E+02 +
          0.114183E+01 * $La +
          -0.581428E+00 * $Lo +
          -0.152421E-01 * $La * $La +
          0.118177E-01 * $La * $Lo +
          0.826646E-03 * $Lo * $Lo ) / 3600.0;

    my $WGS = {};
    $WGS->{'La'} = rad2deg( deg2rad($La) + $d_la );
    $WGS->{'Lo'} = rad2deg( deg2rad($Lo) + $d_lo );

    return ( $WGS->{'La'}, $WGS->{'Lo'} );
}

sub WGS84lalo_to_KKJlalo {
    croak 'Geo::Coordinates::KKJ::WGS84lalo_to_KKJlalo needs two arguments'
        if @_ != 2;

    my ( $La, $Lo ) = @_;
    croak "Wrong parameters"
        if ( $La < $Lo );

    my $d_la =
      deg2rad( -0.124766E+01 +
          0.269941E+00 * $La +
          -0.191342E+00 * $Lo +
          -0.356086E-02 * $La * $La +
          0.122353E-02 * $La * $Lo +
          0.335456E-03 * $Lo * $Lo ) / 3600.0;

    my $d_lo =
      deg2rad( 0.286008E+02 +
          -0.114139E+01 * $La +
          0.581329E+00 * $Lo +
          0.152376E-01 * $La * $La +
          -0.118166E-01 * $La * $Lo +
          -0.826201E-03 * $Lo * $Lo ) / 3600.0;

    my $KKJ = {};
    $KKJ->{'La'} = rad2deg( deg2rad($La) + $d_la );
    $KKJ->{'Lo'} = rad2deg( deg2rad($Lo) + $d_lo );

    return ( $KKJ->{'La'}, $KKJ->{'Lo'} );
}

sub KKJ_Zone_I {
    croak 'Geo::Coordinates::KKJ::KKJ_Zone_I needs one argument'
        if @_ != 1;

    my $i    = shift;
    my $zone = int( $i / 1_000_000.0 );
    croak "Zone value ($zone) invalid."
        if ( $zone < 0 || $zone > 5 );
    return $zone;
}

sub KKJ_Zone_Lo {
    croak 'Geo::Coordinates::KKJ::KKJ_Zone_Lo needs one argument'
        if @_ != 1;

    my $Lo   = shift;

    croak 'Longitude is undefined' unless defined($Lo);

    my $zone = 5;
    while ( $zone >= 0 ) {
        if ( abs( $Lo - $KKJ_ZONE_INFO->{$zone}->[0] ) <= 1.5 ) {
            last;
        }
        $zone--;
    }

    if ( $zone >= 0 && $zone <= 5 ) {
        return $zone;
    }
    else {
        croak "Zone outside range";
    }
}

1;

__END__

=head1 NAME

Geo::Coordinates::KKJ - converts Finnish Coordinate System from/to WGS84 coordinate system

=head1 SYNOPSIS

  use Geo::Coordinates::KKJ;

  # KKJ Basic Coordinate System to WGS84 coordinates
  my ( $lat, $lon ) = KKJxy_to_WGS84lalo('6717563', '2545107');

  # WGS84 coordinates to KKJ Basic Coordinate System
  my ( $x, $y ) = WGS84lalo_to_KKJxy('60.22543759', '24.85437044');

=head1 DESCRIPTION

This module converts WGS84 coordinate system to/from KKJ Basic Coordinate System (in Finnish 'Peruskoordinaatisto')

For more information about the Finnish coordinate system please visit http://www.kolumbus.fi/eino.uikkanen/geodocsgb/ficoords.htm

The Perl module has been adapted from a Python module from Olli Lammi http://aapo.rista.net/tmp/coordinates.py
Olli's module is in turn based on Matti Aarnio's work http://www.viestikallio.fi/tools/kkj-wgs84.php?LANG=en

=head2 Precision

The transformation might contain a precision error of about 0.5m - 2m

=head1 FUNCTIONS

=over 8

=item KKJxy_to_WGS84lalo(x, y)

    Transforms KKJ Basic Coordinate System to WGS84 coordinates

=item WGS84lalo_to_KKJxy(lat, lon)

    Transforms WGS84 coordinates to KKJ Basic Coordinate System

=item KKJxy_to_KKJlalo(x, y)

    Transforms from KKJ Basic Coordinate System to KKJ geographic coordinates

=item KKJlalo_to_KKJxy(lat, lon)

    Transforms from KKJ geographic coordinates to KKJ Basic Coordinate System

=item KKJlalo_to_WGS84lalo(lat, lon)

    Transforms KKJ geographic coordinates to WGS84 coordinates

=item WGS84lalo_to_KKJlalo(lat, lon)

    Transforms from WGS84 coordinates to KKJ geographic coordinates

=item KKJ_Zone_I(y)

    Determines the correct KKJ-grid zone

=item KKJ_Zone_Lo(lon)

    Determine the zonenumber from KKJ easting
    takes KKJ zone which has center meridian
    longitude nearest (in math value) to
    the given KKJ longitude

=back

=head1 SEE ALSO

Good explanation about the finnish coordinate system and its history
http://www.kolumbus.fi/eino.uikkanen/geodocsgb/ficoords.htm (in English)

Transforming between different coordinate systems
http://kansalaisen.karttapaikka.fi/koordinaatit/koordinaatit.html?lang=en


=head1 AUTHOR

Josep Roca, <quelcom@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Josep Roca

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
