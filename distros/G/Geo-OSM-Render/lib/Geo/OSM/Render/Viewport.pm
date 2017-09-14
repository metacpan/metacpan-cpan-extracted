# Encoding and name #_{

=encoding utf8
=head1 NAME

Geo::OSM::Render::Viewport - Project OSM latitudes and longitudes into x, y coordinate pairs to be rendered by L<Geo::OSM::Render>.

=cut
package Geo::OSM::Render::Viewport;
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

After projecting OSM coordinates onto a coordinate system with L<< Geo::OSM::Render::Projection >>, the resulting
coordinates migth be translated onto the coordinate system of the map.
This can be done with an instance of C<< viewport >>.

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

    my $vp = Geo::OSM::Render::Viewport->new();

Create an instance of a viewport. Use it in a derived class.

=cut

#_}

  my $class = shift;
  my $self  = {};
  bless $self, $class;

} #_}
sub x_y_to_map_x_y { #_{
#_{ POD

=head2 x_y_to_map_x_y

    my ($map_x, $map_y) = $vp->x_y_to_map_x_y($x, $$y);

Because this is an abstract base class, calling this method on C<<Geo::OSM::Render::Viewport>> just
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
