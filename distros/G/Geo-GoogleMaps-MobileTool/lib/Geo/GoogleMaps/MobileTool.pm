package Geo::GoogleMaps::MobileTool;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.1');

use Math::Trig;
use base 'Exporter';

our @EXPORT = qw(
    lnglat2pixel
    pixel2lnglat
    deltapixel2lnglat
    deltalnglat_perpixel
);

my $zmbase = 128;
my @zmmax;
my $offproj;

sub import {
    my ( $class, $opt ) = @_;

    $offproj = ( $opt && $opt eq 'unableProj' ) ? 1 : 0;
    unless ( $offproj ) {
        eval { require Geo::Proj };
        if ( $@ ) {
            $offproj = 1;
        } else {
            Geo::Proj->import();
        }
    }

    foreach my $zm (0..20) {
        $zmmax[$zm] = $zmbase * 2 ** $zm;
        unless ( $offproj ) {
            my $name    = "gmapzm$zm";
            my $r       = $zmmax[$zm] / pi;
            my $proj    = "+proj=merc +a=$r +b=$r +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=\@null +no
_defs";
            Geo::Proj->new(
                nick  => $name,
                proj4 => $proj,
            );
        }
    }

    local $Exporter::ExportLevel = $Exporter::ExportLevel + 1;

    $class->SUPER::import();
}

sub lnglat2pixel {
    my ( $lng, $lat, $zm, $intoff ) = @_;

    my ( $x, $y );

    if ( $offproj ) {
        $x = $lng / 180.0 * $zmmax[$zm];
        $y = log( tan( pi * ( 0.25 + $lat / 360.0 ) ) ) / pi * $zmmax[$zm];
    } else {
        my $pt = Geo::Proj->to( 'wgs84', "gmapzm$zm", [ $lng, $lat ] );
        ( $x, $y ) = @{ $pt };
    }

    $x  += $zmmax[$zm];
    $y  =  -1.0 * ( $y - $zmmax[$zm] );

    ( $x, $y ) = map { int( $_ ) } ( $x, $y ) unless ( $intoff );

    return wantarray ? ( $x, $y ) : [ $x, $y ];
}

sub pixel2lnglat {
    my ( $x, $y, $zm, $intoff ) = @_;

    ( $x, $y ) = map { $_ + 0.5 } ( $x, $y ) unless ( $intoff );

    $x -= $zmmax[$zm];
    $y =  -1.0 * $y + $zmmax[$zm];

    my ( $lng, $lat );

    if ( $offproj ) {
        $lng   = $x / $zmmax[$zm] * 180.0;
        $lat   = atan( sinh( $y / $zmmax[$zm] * pi ) ) / pi *180.0;
    } else {
        my $pt = Geo::Proj->to( "gmapzm$zm", 'wgs84', [ $x, $y ] );
        ( $lng, $lat ) = @{$pt};
    }
   
    return wantarray ? ( $lng, $lat ) : [ $lng, $lat ];
}

sub deltapixel2lnglat {
    my ( $lng, $lat, $dpxx, $dpxy, $zm ) = @_;

    my ( $fx, $fy ) = lnglat2pixel( $lng, $lat, $zm, 1 );

    $fx += $dpxx;

    $fy += $dpxy;

    return pixel2lnglat( $fx, $fy, $zm, 1 );
}

sub deltalnglat_perpixel {
    my ( $lng, $lat, $zm ) = @_;

    my $dpx_plng = $zmmax[$zm] / 180.0;
    my $dpy_plat = sec( $lat / 180.0 * pi ) * $zmmax[$zm] / 180.0;

    return map { 1.0 / $_ } ( $dpx_plng, $dpy_plat );
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Geo::GoogleMaps::MobileTool - Provide some functions useful for using GoogleMaps Static API on mobile sites


=head1 VERSION

This document describes Geo::GoogleMaps::MobileTool version 0.0.1


=head1 SYNOPSIS

    use Geo::GoogleMaps::MobileTool;

    #Convert longitude/latitude to GoogleMaps' pixel coordinate
    #on specified zoom level
    my ( $x, $y ) = lnglat2pixel( $lng, $lat, $zoom );

    #Convert GoogleMaps' pixel coordinate on specified zoom level
    #longitude/latitude
    my ( $lng, $lat ) = pixel2lnglat( $x, $y, $zoom );

    #Calcurate longitude/latitude from base-point's longitude/latitude
    #and delta pixels on specified zoom level
    my ( $tlng, $tlat ) = deltapixel2lnglat( $flng, $flat, $deltax, $deltay, $zoom );

    #Calcurate differential longitude/latitude value per pixel on
    #specified longitude/latitude and zoom level.
    my ( $dlng, $dlat ) = deltalnglat_perpixel( $lng, $lat, $zoom );

    #This module use Geo::Proj if it is installed, but you want nnot to use
    #it, call this module like this:
    use Geo::GoogleMaps::MobileTool qw(unableProj);


=head1 About GoogleMaps pixel coordinates

    Google pixel coordinate is specified as

    ( 0, 0 ) => ( 256 * 2 ** $zoom - 1, 256 * 2 ** $zoom - 1 )

    longitude/latitude -180.00000000, 85.05112878 are convert into
    ( 0, 0 ), and 179.99999999..., -85.05223877... are convert 
    into ( 256 * 2 ** $zoom - 1, 256 * 2 ** $zoom - 1 ).


=head1 EXPORT 

=over

=item C<< lnglat2pixel >>

=item C<< pixel2lnglat >>

=item C<< deltapixel2lnglat >>

=item C<< deltalnglat_perpixel >>

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
Geo::GoogleMaps::MobileTool requires no configuration files or environment variables.


=head1 DEPENDENCIES

Math::Trig
Exporter


=head1 AUTHOR

OHTSUKA Ko-hei  C<< <nene@kokogiko.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, OHTSUKA Ko-hei C<< <nene@kokogiko.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
