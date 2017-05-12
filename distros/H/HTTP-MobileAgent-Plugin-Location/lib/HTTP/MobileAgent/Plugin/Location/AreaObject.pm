package HTTP::MobileAgent::Plugin::Location::AreaObject;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.2');
use base qw/Location::Area::DoCoMo::iArea/;

sub __create_coord{
    my $class = shift;
    my $self; 

    if (HTTP::MobileAgent->_use_geopoint) {
        my $loc = shift;
        my $p   = $loc->transform('tokyo');

        $self = $class->create_coord($p->lat, $p->long, "tokyo", "degree");
    } elsif (HTTP::MobileAgent->_use_geocoordinate) {
        my $loc = shift;
        my $p   = $loc->convert(degree => 'tokyo');

        $self = $class->create_coord($p->lat, $p->lng, "tokyo", "degree");
    } else {
        $self = $class->create_coord(@_);
    }

    $self;
}

1;


=head1 NAME

HTTP::MobileAgent::Plugin::Location::AreaObject - Object for handling i-Area object


=head1 VERSION

This document describes HTTP::MobileAgent::Plugin::Location::AreaObject version 0.0.1


=head1 SYNOPSIS
  
  use HTTP::MobileAgent::Plugin::Location qw(use_area);
  
  my $ma = HTTP::MobileAgent->new;
  $ma->parse_location;
  my $area = $ma->area;
  
  # This $area is L<HTTP::MobileAgent::Plugin::Location::AreaObject>'s object.

  # L<HTTP::MobileAgent::Plugin::Location::AreaObject> is subclass of L<Location::Area::DoCoMo::iArea>,
  # so you can do like below:
  
  my $id = $area->id;

  # See more detail on L<Location::Area::DoCoMo::iArea>.


=head1 DEPENDENCIES

=over

=item L<Location::Area::DoCoMo::iArea>

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
