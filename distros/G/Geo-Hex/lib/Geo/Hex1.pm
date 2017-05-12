package Geo::Hex1;

use warnings;
use strict;
use Carp;

use POSIX       qw/floor ceil/;
use Math::Round qw/round/;

use version; our $VERSION = qv('0.0.2');
use vars qw(@ISA @EXPORT);
use Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(latlng2geohex geohex2latlng geohex2polygon geohex2distance distance2geohexes);

# Constants

my $h_key       = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWX';
my @h_key       = split( //, $h_key );
my $h_customize = 0;
my $h_grid      = 1000;
my $h_size      = 0.5;
my $min_x_lon   = 122930; #与那国島
my $min_x_lat   = 24448;
my $min_y_lon   = 141470; #南硫黄島
my $min_y_lat   = 24228;

# Some internal functions

sub __geohex2level {
    my $code = shift;
    
    my @code     = split( //, $code );
    my $c_length = @code or croak 'GeoHex code must be set';
    my $level;

    if ( $c_length > 4 ) {
        $level = index( $h_key, shift @code );
        croak 'Code format is something wrong' if ( $level == -1 );
        $level = 60 if ( $level == 0 );
    } else {
        $level = 7;
    }
    return ( $level, $c_length, @code );
}

sub __geohex2hyhx {
    my $code = shift;

    my ( $level, $c_length, @code ) = eval { __geohex2level( $code ) };
    croak $@ if ( $@ );

    my $unit_x = 6.0 * $level * $h_size;
    my $unit_y = 2.8 * $level * $h_size;
    my $h_k    = ( round( ( 1.4 / 3 ) * $h_grid ) ) / $h_grid;
    my $base_x = floor( ( $min_x_lon + $min_x_lat / $h_k ) / $unit_x );
    my $base_y = floor( ( $min_y_lat - $h_k * $min_y_lon ) / $unit_y );

    my ( $h_x, $h_y );
    if ( $c_length > 5 ) {
        $h_x = index( $h_key, $code[0] ) * 3600 + index( $h_key, $code[2] ) * 60 + index( $h_key, $code[4] );
        $h_y = index( $h_key, $code[1] ) * 3600 + index( $h_key, $code[3] ) * 60 + index( $h_key, $code[5] );
    } else {
        $h_x = index( $h_key, $code[0] ) * 60   + index( $h_key, $code[2] );
        $h_y = index( $h_key, $code[1] ) * 60   + index( $h_key, $code[3] );
    }
    
    return ( $h_y, $h_x, $level, $unit_x, $unit_y, $h_k, $base_x, $base_y );
}

sub __hyhx2geohex {
    my ( $h_y, $h_x, $level ) = @_;

    my $h_x_100 = floor( $h_x / 3600);
    my $h_x_10  = floor(($h_x % 3600) / 60);
    my $h_x_1   = floor(($h_x % 3600) % 60);
    my $h_y_100 = floor( $h_y / 3600);
    my $h_y_10  = floor(($h_y % 3600) / 60);
    my $h_y_1   = floor(($h_y % 3600) % 60);

    my $code;
    if ( $level < 7 ) {
        $code = $h_key[ $level % 60 ] . $h_key[ $h_x_100 ] . $h_key[ $h_y_100 ] . $h_key[ $h_x_10 ] . $h_key[ $h_y_10 ] . $h_key[ $h_x_1 ] . $h_key[ $h_y_1 ];
    } elsif ( $level == 7 ) {
        $code = $h_key[ $h_x_10 ] . $h_key[ $h_y_10 ] . $h_key[ $h_x_1 ] . $h_key[ $h_y_1 ];
    } else {
        $code = $h_key[ $level % 60 ] . $h_key[ $h_x_10 ] . $h_key[ $h_y_10 ] . $h_key[ $h_x_1 ] . $h_key[ $h_y_1 ];
    }
    return $code;
}

# Export function for GeoHex

sub latlng2geohex {
    my $lat   = shift;
    my $lon   = shift;
    my $level = shift;

    $level = defined( $level ) ? $level : 7;
    croak 'Level must be between 1 and 60' if ( $level !~ /^\d+$/ || $level < 1 || $level > 60 );

    my $lon_grid = $lon * $h_grid;
    my $lat_grid = $lat * $h_grid;
    my $unit_x   = 6.0  * $level * $h_size;
    my $unit_y   = 2.8  * $level * $h_size;
    my $h_k      = ( round( (1.4 / 3) * $h_grid) ) / $h_grid;
    my $base_x   = floor( ($min_x_lon + $min_x_lat / $h_k      ) / $unit_x);
    my $base_y   = floor( ($min_y_lat - $h_k       * $min_y_lon) / $unit_y);
    my $h_pos_x  = ( $lon_grid + $lat_grid / $h_k     ) / $unit_x - $base_x;
    my $h_pos_y  = ( $lat_grid - $h_k      * $lon_grid) / $unit_y - $base_y;
    my $h_x_0    = floor($h_pos_x);
    my $h_y_0    = floor($h_pos_y);
    my $h_x_q    = floor(($h_pos_x - $h_x_0) * 100) / 100;
    my $h_y_q    = floor(($h_pos_y - $h_y_0) * 100) / 100;
    my $h_x      = round($h_pos_x);
    my $h_y      = round($h_pos_y);
    if ( $h_y_q > -$h_x_q + 1 ) {
        if( ($h_y_q < 2 * $h_x_q ) && ( $h_y_q > 0.5 * $h_x_q ) ){
            $h_x = $h_x_0 + 1;
            $h_y = $h_y_0 + 1;
       }
    } elsif ( $h_y_q < -$h_x_q + 1 ) {
        if( ($h_y_q > (2 * $h_x_q ) - 1 ) && ( $h_y_q < ( 0.5 * $h_x_q ) + 0.5 ) ) {
            $h_x = $h_x_0;
            $h_y = $h_y_0;
        }
    }

    return __hyhx2geohex( $h_y, $h_x, $level );
}

sub geohex2latlng{
    my $code = shift;

    my ( $lat, $lon );
    my ( $h_y, $h_x, $level, $unit_x, $unit_y, $h_k, $base_x, $base_y ) = eval { __geohex2hyhx( $code ) };
    croak $@ if ( $@ );
    
    my $h_lat = ( $h_k   * ( $h_x + $base_x ) * $unit_x + ( $h_y + $base_y ) * $unit_y ) / 2;
    my $h_lon = ( $h_lat - ( $h_y + $base_y ) * $unit_y ) / $h_k;
    $lat      = $h_lat / $h_grid;
    $lon      = $h_lon / $h_grid;

    return ( $lat, $lon, $level );
}


sub geohex2polygon{
    my $code = shift;
    my ( $lat, $lon, $level ) = geohex2latlng( $code );

    my $d = $level * $h_size / $h_grid;
    
    return [
        [ $lat           , $lon - 2.0 * $d ],
        [ $lat + 1.4 * $d, $lon - 1.0 * $d ],
        [ $lat + 1.4 * $d, $lon + 1.0 * $d ],
        [ $lat           , $lon + 2.0 * $d ],
        [ $lat - 1.4 * $d, $lon + 1.0 * $d ],
        [ $lat - 1.4 * $d, $lon - 1.0 * $d ],
        [ $lat           , $lon - 2.0 * $d ],
    ];
}

sub geohex2distance {
    my ( $code1, $code2 ) = @_;
    
    my ( $h_y1, $h_x1, $level1 ) = eval { __geohex2hyhx( $code1 ) };
    croak $@ if ( $@ );
    my ( $h_y2, $h_x2, $level2 ) = eval { __geohex2hyhx( $code2 ) };
    croak $@ if ( $@ );
    croak 'Level of codes are must same value' unless ( $level1 == $level2 );
    
    my $dh_y = $h_y1 - $h_y2;
    my $dh_x = $h_x1 - $h_x2;
    my $ah_y = abs( $dh_y );
    my $ah_x = abs( $dh_x );
        
    if ( $dh_y * $dh_x > 0 ) {
        return $ah_x > $ah_y ? $ah_x : $ah_y;
    } else {
        return $ah_x + $ah_y;
    }
}

sub distance2geohexes {
    my ( $code, $dist ) = @_;
    
    my ( $h_y, $h_x, $level ) = eval { __geohex2hyhx( $code ) };
    croak $@ if ( $@ );
    
    my @results;
    foreach my $d_y ( -1 * $dist .. $dist ) {
        my $dh_y  = $h_y + $d_y;
        my $dmn_x = $d_y > 0 ? -1 * $dist + $d_y : -1 * $dist;
        my $dmx_x = $d_y < 0 ? $dist + $d_y      : $dist;
        
        foreach my $d_x ( $dmn_x .. $dmx_x ) {
            next if ( $d_y == 0 && $d_x == 0 );
        
            push @results, __hyhx2geohex( $h_y + $d_y, $h_x + $d_x, $level );
        }
    }
    
    return \@results;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Geo::Hex1 - Convert between latitude/longitude and GeoHex code version 1


=head1 SYNOPSIS

    use Geo::Hex1;
    
    # From latitude/longitude to hex code
    
    my $code = latlng2geohex( $lat, $lng, $level );
    
    # From hex code to center latitude/longitude
    
    my ( $center_lat, $center_lng, $level ) = geohex2latlng( $code );
    
    # From hex code to hex polygon
    
    my $poly = geohex2polygon( $code );

    my ( $wlat,  $wlng  ) = @{$poly->[0]}; # West point
    my ( $nwlat, $nwlng ) = @{$poly->[1]}; # North west point
    my ( $nelat, $nelng ) = @{$poly->[2]}; # North east point
    my ( $elat,  $elng  ) = @{$poly->[3]}; # East point
    my ( $selat, $selng ) = @{$poly->[4]}; # South east point
    my ( $swlat, $swlng ) = @{$poly->[5]}; # South west point
    my ( $wlat,  $wlng  ) = @{$poly->[6]}; # West point again ( Same with 0 )

    # Get hex distance between two hex codes
    
    my $dist = geohex2distance('wknR','wkmO'); # 3
    
    # Get all hex codes list include in given hex distance
    
    my $list = distance2geohexes('8sijg',2); 
    foreach my $code (@{$list}) { print $code . "\n" }
    # 8sijh
    # 8siig
    # 8siif
    # 8sijf
    # 8sikg
    # 8sikh
    # 8sili
    # 8siki
    # 8siji
    # 8siih
    # 8sihg
    # 8sihf
    # 8sihe
    # 8siie
    # 8sije
    # 8sikf
    # 8silg
    # 8silh

=head1 EXPORT

=over

=item C<< latlng2geohex( $lat, $lng ) >>

Convert latitude/longitude to GeoHex version 1 code.

=item C<< geohex2latlng( $hex ) >>

Convert GeoHex version 1 code to center latitude/longitude, and level value.

=item C<< geohex2polygon( $hex ) >>

Convert GeoHex version 1 code to polygon points.

=item C<< geohex2distance( $hex1, $hex2 ) >>

Get hex distance between two GeoHex version 1 codes.

=item C<< distance2geohexes( $hex, $distance ) >>

Get GeoHex version 1 codes list within given hex distance.

=back


=head1 DEPENDENCIES

Exporter
POSIX
Math::Round
Math::Trig

=head1 AUTHOR

OHTSUKA Ko-hei  C<< <nene@kokogiko.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009-2010, OHTSUKA Ko-hei C<< <nene@kokogiko.net> >>. All rights reserved.

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
