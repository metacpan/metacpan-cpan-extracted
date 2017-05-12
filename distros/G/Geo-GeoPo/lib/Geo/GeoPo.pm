package Geo::GeoPo;

use strict;
use warnings;
use Carp;

use version; our $VERSION = '0.0.1';
use vars qw(@ISA @EXPORT);
use Exporter;
@ISA = qw(Exporter);
@EXPORT      = qw(latlng2geopo geopo2latlng);

# 64characters (number + big and small letter + hyphen + underscore)
my $chars = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-_";

# GeoPo Encode in Perl
sub latlng2geopo {
    my ( $lat, $lng, $scale, $arg ) = @_;
    my $geopo = "";
    $arg ||= {};

    # Change a degree measure to a decimal number
    $lat = ($lat + 90)  / 180 * 8 ** 10;
    $lng = ($lng + 180) / 360 * 8 ** 10;

    # Compute a GeoPo code from head and concatenate
    for( my $i = 0; $i < $scale; $i++) {
        $geopo .= substr($chars, int($lat / 8 ** (9 - $i) % 8) + int($lng / 8 ** (9 - $i) % 8) * 8, 1);
    }
    
    $geopo = "http://geopo.at/$geopo" if ($arg->{as_url});

    return $geopo;
}

# GeoPo Decode in Perl
sub geopo2latlng {
    my $geopo = shift;

    $geopo =~ s!http://geopo.at/!!;
    my ( $lat, $lng, $scale ) = ( 0, 0, length($geopo) );
   
    for ( my $i = 0; $i < $scale; $i++ ) {
        # What number of character that equal to a GeoPo code (0-63)
        my $order = index($chars, substr($geopo, $i, 1));
        
        # Lat/Lng plus geolocation value of scale 
        $lat += $order % 8 * 8 ** (9 - $i);
        $lng += int($order / 8) * 8 ** (9 - $i);
    }

    # Change a decimal number to a degree measure, and plus revised value that shift center of area
    $lat = $lat * 180 / 8 ** 10 - 90  + 180 / 8 ** $scale / 2;
    $lng = $lng * 360 / 8 ** 10 - 180 + 360 / 8 ** $scale / 2;

    return ( $lat, $lng, $scale );
}	

1;
__END__

=head1 NAME

Geo::GeoPo - Simple encoder/decoder of GeoPo format

=head1 SYNOPSIS

  use Geo::GeoPo;

  my ( $lat, $lng, $scale ) = geopo2latlng('Z4RHXX');
  # 35.658578, 139.745447, 6

  my ( $lat, $lng, $scale ) = geopo2latlng('http://geopo.at/Z4RHXX');
  # Same result

  my $geopo = latlng2geopo( 35.658578, 139.745447, 6 );
  # Z4RHXX

  my $geopo = latlng2geopo( 35.658578, 139.745447, 6, { as_url => 1 } );
  # http://geopo.at/Z4RHXX

=head1 DESCRIPTION

GeoPo is a web service that shrink geolocation(latitude and longitude) to 
short URL. Then browser of receiver can display the map matched to browse 
environment. Everyone can use GeoPo for free, and no registration. 

You can get more information on L<http://geopo.at/intl/en/>.

Geo::GeoPo is simple encoder/decoder of GeoPo.


=head1 METHOD

=over

=item * geopo2latlng

=item * latlng2geopo

=back


=head1 AUTHOR

Original programmed by Shintaro Inagaki

Module packaged by OHTSUKA Ko-hei E<lt>nene@kokogiko.netE<gt>


=head1 SEE ALSO

L<http://geopo.at/intl/ja/developer/sample_code.html#perl>


=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
