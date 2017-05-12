package Geo::Point::Plugin::Transform;

use warnings;
use strict;
use Carp;

use version;our $VERSION = qv('0.0.2');

use Geo::Point;
use Geo::Proj;

package # hide from PAUSE
        Geo::Point;

sub transform {
    my ($self,$tproj) = @_;

    my $pt = Geo::Proj->to($self->proj, $tproj, [$self->x, $self->y]);

    return Geo::Point->xy(@{$pt},$tproj);
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Geo::Point::Plugin::Transform - Add transforming projection method to Geo::Point


=head1 VERSION

This document describes Geo::Point::Plugin::Transform version 0.0.2


=head1 SYNOPSIS

  use Geo::Point::Plugin::Transform;
  
  my $pt_wgs84 = Geo::Point->longlat(135.00,35.00,"wgs84");
  my $pt_clrk  = $pt_wgs84->transform('clark66');   # Geo::Point object


=head1 METHOD 

Method is mprementing as object method of Geo::Point class.

B<transform>(PROJECTION)

Transform point to given projection, and create new Geo::Point object.


=head1 DEPENDENCIES

Geo::Point
Geo::Proj


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
