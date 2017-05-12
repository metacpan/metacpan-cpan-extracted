package HTTP::MobileAgent::Plugin::Location::LocationObject;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.2');
use base qw/Class::Data::Inheritable Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/accuracy mode method/);

sub __create_coord{
    my $class = shift;

    if (HTTP::MobileAgent->_use_geopoint) {
        require HTTP::MobileAgent::Plugin::Location::LocationObject::GP;
        $class = "HTTP::MobileAgent::Plugin::Location::LocationObject::GP";
    } elsif (HTTP::MobileAgent->_use_geocoordinate) {
        require HTTP::MobileAgent::Plugin::Location::LocationObject::GCC;
        $class = "HTTP::MobileAgent::Plugin::Location::LocationObject::GCC";
    } else {
        require HTTP::MobileAgent::Plugin::Location::LocationObject::LG;
        $class = "HTTP::MobileAgent::Plugin::Location::LocationObject::LG";
    }

    $class->create_coord(@_);
}

sub mesh7{
    my $self = shift;

    my ($lat,$lon);

    if (HTTP::MobileAgent->_use_geopoint) {
        my $point = $self->transform('tokyo');
        ($lat,$lon) =  map { int ($_ * 3600000) } ( $point->lat, $point->long );
    } elsif (HTTP::MobileAgent->_use_geocoordinate) {
        my $point = $self->convert( degree => 'tokyo' );
        ($lat,$lon) = map { int ($_ * 3600000) } ($point->lat,$point->lng);
    } else {
        ($lat,$lon) = map { int ($_ * 1000) } $self->datum_tokyo->format_second->array;
    }

    my @mesh = ();
    my $ab = int($lat / 2400000);
    my $cd = int($lon / 3600000) - 100;
    my $x1 = ($cd +100) * 3600000;
    my $y1 = $ab * 2400000;
    my $e = int(($lat - $y1) / 300000);
    my $f = int(($lon - $x1) / 450000);
    $mesh[0] = $ab.$cd.$e.$f;
    my $x2 = $x1 + $f * 450000;
    my $y2 = $y1 + $e * 300000;
    my $l3 = int(($lon - $x2) / 225000);
    my $m3 = int(($lat - $y2) / 150000);
    my $g = $l3 + $m3 * 2;
    $mesh[1] = $mesh[0].$g;  
    my $x3 = $x2 + $l3 * 225000;
    my $y3 = $y2 + $m3 * 150000;
    my $l4 = int(($lon - $x3) / 112500);
    my $m4 = int(($lat - $y3) / 75000);
    my $h = $l4 + $m4 * 2;
    $mesh[2] = $mesh[1].$h;  
    my $x4 = $x3 + $l4 * 112500;
    my $y4 = $y3 + $m4 * 75000;
    my $l5 = int(($lon - $x4) / 56250);
    my $m5 = int(($lat - $y4) / 37500);
    my $i = $l5 + $m5 * 2;
    $mesh[3] = $mesh[2].$i;  
    my $x5 = $x4 + $l5 * 56250;
    my $y5 = $y4 + $m5 * 37500;
    my $l6 = int(($lon - $x5) / 28125);
    my $m6 = int(($lat - $y5) / 18750);
    my $j = $l6 + $m6 * 2;
    $mesh[4] = $mesh[3].$j;
    my $x6 = $x5 + $l6 * 28125;
    my $y6 = $y5 + $m6 * 18750;
    my $l7 = int(($lon - $x6) / 14062.5);
    my $m7 = int(($lat - $y6) / 9375);
    my $k = $l7 + $m7 * 2;
    $mesh[5] = $mesh[4].$k;

    return $mesh[5];
}


1;

=head1 NAME

HTTP::MobileAgent::Plugin::Location::LocationObject - Object for handling location object


=head1 VERSION

This document describes HTTP::MobileAgent::Plugin::Location::LocationObject version 0.0.1


=head1 SYNOPSIS

  use HTTP::MobileAgent::Plugin::Location;
  
  my $ma = HTTP::MobileAgent->new;
  $ma->parse_location;
  my $loc = $ma->location;
  
  # If $loc is not undef, it is L<HTTP::MobileAgent::Plugin::Location::LocationObject> object.
  # More detail information of above sequence, see L<HTTP::MobileAgent::Plugin::Location>.
  
  # This class is subclass of L<Location::GeoTool> on default, or subclass of 
  # L<Geo::Coordinates::Converter> on optional. 
  # So see L<Location::GeoTool> or L<Geo::Coordinates::Converter> to know basic methods and properties.

  if ($loc->mode eq "gps") { ... }
  
  # Get location requested mode by B<mode> method.
  # It returns "gps" or "sector".

  if ($loc->accuracy eq "gps") { ... }
  
  # Get Accuracy of returned location by B<accuracy> method.
  # It returns "gps", "hybrid" or "sector".
  # Real accuracy value is different by carrears and generations, but almost like below:
  #   gps:      0m -  50m
  #   hybrid:  50m - 300m
  #   sector: 300m -

  my $mesh7 = $loc->mesh7;
  
  # Get 7th mesh code of i-Area specification.
  # See more detail on L<http://www.nttdocomo.co.jp/service/imode/make/content/iarea/>.


=head1 NOTE

Value of B<mode> and B<accuracy> is sometimes not same.
Even if User want to get gps level accuracy data, but terminal cannot access gps satellite,
it fallback to hyblid or sector level accuracy.


=head1 METHOD

=over

=item L<mesh7>

=back


=head1 DEPENDENCIES

=over

=item L<Class::Data::Inheritable>

=item L<Class::Accessor::Fast>

=item L<HTTP::MobileAgent::Plugin::Location::LocationObject::GCC>

=item L<HTTP::MobileAgent::Plugin::Location::LocationObject::LG>

=item L<HTTP::MobileAgent::Plugin::Location::LocationObject::GP>

=back


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to C<nene@kokogiko.net>.


=head1 AUTHOR

OHTSUKA Ko-hei  C<< <nene@kokogiko.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, OHTSUKA Ko-hei C<< <nene@kokogiko.net> >>. All rights reserved.

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
