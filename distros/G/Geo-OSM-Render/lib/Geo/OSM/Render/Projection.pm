# Encoding and name #_{

=encoding utf8
=head1 NAME

Geo::OSM::Render::Projection - Project OSM latitudes and longitudes into x, y coordinate pairs to be rendered by L<Geo::OSM::Render>.

=cut
package Geo::OSM::Render::Projection;
#_}
#_{ use …
use warnings;
use strict;

use utf8;
use Carp;

#_}
our $VERSION = 0.01;
#_{ Synopsis

=head1 SYNOPSIS

This is an abstract base class. So, I am hard pressed to write a synopsis here.


=cut
#_}
#_{ Overview

=head1 OVERVIEW

Before OpenStreetMap data can be rendered, the OSM coordinates must be projected into a suitable x/y coordinate system.
Descendents of this class should (must...) provide the conversion function C<<lat_lon_to_x_y>> which performce
this projection.

Currently, two classes are derived from this class:
L<< Geo::OSM::Render::Projection::CH_LV03 >> and
L<< Geo::OSM::Render::Projection::Ident >>.

=cut

#_}
#_{ Methods
#_{ POD
=head1 METHODS
=cut
#_}
sub new { #_{
#_{ POD

=head2 new

    my $proj = Geo::OSM::Render::Projection->new();

Create an instance of a projection. Use it in a derived class.

=cut

#_}

  my $class = shift;
  my $self  = {};
  bless $self, $class;

} #_}
sub lat_lon_to_x_y { #_{
#_{ POD

=head2 lat_lon_to_x_y

    my ($x, $y) = $projection->lat_lon_to_x_y($lat, $lon);

Because this is an abstract base class, calling this method on C<<Geo::OSM::Render::Projection>> just
croaks.

=cut

#_}

  croak ('Override this method in a descendant');

} #_}
#_}
#_{ POD: Author

=head1 AUTHOR

René Nyffenegger <rene.nyffenegger at adp-gmbh.ch>

=cut

#_}
#_{ POD: Copyright and License

=head1 COPYRIGHT AND LICENSE
Copyright © 2017 René Nyffenegger, Switzerland. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at: L<http://www.perlfoundation.org/artistic_license_2_0>
=cut

#_}
#_{ POD: Source Code

=head1 Source Code

The source code is on L<< github|https://github.com/ReneNyffenegger/perl-Geo-OSM-Render >>. Meaningful pull requests are welcome.

=cut

#_}

'tq84';
