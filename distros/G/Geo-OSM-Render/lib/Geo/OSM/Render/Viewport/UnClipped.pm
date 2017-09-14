# Encoding and name #_{

=encoding utf8
=head1 NAME

Geo::OSM::Render::Viewport::UnClipped - Use an ounbounded L<<viewport | Geo::OSM::Render::Viewport >> to create a map.

=cut
package Geo::OSM::Render::Viewport::UnClipped;
#_}
#_{ use …
use warnings;
use strict;

use utf8;
use Carp;
use Geo::OSM::Render::Viewport;
our @ISA = qw(Geo::OSM::Render::Viewport);

#_}
our $VERSION = 0.01;
#_{ Synopsis

=head1 SYNOPSIS

This class derives from L<<Geo::OSM::Render::Viewporrt>>.

=cut
#_}
#_{ Overview

=head1 OVERVIEW

See L<Geo::OSM::Render::Viewport/OVERVIEW>.

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

    my $vp = Geo::OSM::Render::Viewport::UnClipped->new();


=cut

#_}

  my $class = shift;
  my $self  = $class->SUPER::new();
  return $self;

} #_}
sub x_y_to_map_x_y { #_{
#_{ POD

=head2 x_y_to_map_x_y

    my ($map_x, $map_y) = $projection->x_y_to_map_x_y($x, $y);

=cut

#_}

  my $self = shift;

# The viewport is unbounded so the passed coordinates need not
# be 'viewported':
  return @_;

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
