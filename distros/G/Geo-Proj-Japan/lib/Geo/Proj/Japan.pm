package Geo::Proj::Japan;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.2');

use Geo::Proj;

sub import {
    my $tproj = '+proj=latlong +ellps=bessel +towgs84=-146.336,506.832,680.254';
    Geo::Proj->new(
        nick  => 'tokyo', 
        proj4 => $tproj,
    );
    Geo::Proj->new(
        nick  => 'tokyo97', 
        proj4 => $tproj,
    );
    Geo::Proj->new( 
        nick  => 'jgd2000', 
        proj4 => '+proj=latlong +ellps=GRS80',
        srid  => 4612,
    );
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Geo::Proj::Japan - Add famous Japanese datums to Geo::Proj


=head1 VERSION

This document describes Geo::Proj::Japan version 0.0.2


=head1 SYNOPSIS

  use Geo::Proj::Japan;
  
  # After this, You can use tokyo97, tokyo(alias of tokyo97), jgd2000
  my $point_tokyo = Geo::Point->latlong($lat, $lng, 'tokyo');

=head1 DEPENDENCIES

Geo::Proj


=head1 SEE ALSO

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
