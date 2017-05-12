package HTTP::MobileAgent::Plugin::Location::LocationObject::GP;

use warnings;
use strict;
use Carp;

use vars qw(@ISA);
use version; our $VERSION = qv('0.0.1');
use base qw/HTTP::MobileAgent::Plugin::Location::LocationObject Geo::Point/;
use Geo::Proj::Japan;
use Geo::Point::Plugin::Transform;

sub create_coord{
    my $class = shift;
    my ($lat,$lng,$datum,$format) = @_;

    if ($format eq "gpsone") {
        ( $lat, $lng ) = map { 
            my $s = $_; 
            $s =~ s/([\+\-]?\d+)\.(\d+)\.(\d+(?:\.\d+)?)/$1d$2m$3/; 
            Geo::Point->dms2deg($s); 
        } ( $lat, $lng );
    }

    my $self = Geo::Point->latlong( $lat, $lng, $datum );

    bless $self, $class;
}

1;

=head1 NAME

HTTP::MobileAgent::Plugin::Location::LocationObject::GP - Object for handling location object based on Geo::Point


=head1 VERSION

This document describes HTTP::MobileAgent::Plugin::Location::LocationObject::GP version 0.0.1


=head1 SYNOPSIS

  # In default, L<HTTP::MobileAgent::Plugin::Location::LocationObject> is subclass of
  # L<Location::GeoTool>.
  # If you want to use L<Geo::Point>, import L<HTTP::MobileAgent::Plugin::Location>
  # with option B<use_geopoint>.
  
  use HTTP::MobileAgent::Plugin::Location qw(use_geopoint);
  
  my $ma = HTTP::MobileAgent->new;
  $ma->parse_location;
  my $loc = $ma->location;
  
  # This $loc is subclass of L<Geo::Point>, so you can do like below:
  
  my $proj = $loc->proj;

  # See more detail on L<Geo::Point>.


=head1 CONSTRUCTOR

=over

=item L<create_coord>

=back


=head1 DEPENDENCIES

=over

=item L<HTTP::MobileAgent::Plugin::Location::LocationObject>

=item L<Geo::Point>

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


