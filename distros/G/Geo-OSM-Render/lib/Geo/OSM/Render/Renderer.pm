# Encoding and name #_{

=encoding utf8
=head1 NAME

Geo::OSM::Render::Renderer - Render OpenStreetMap data encaspulated via L<Geo::OSM::Primitive>, possibly stored in a L<Geo::OSM::DBI> database.

=cut
package Geo::OSM::Render::Renderer;
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


=cut
#_}
#_{ Overview

=head1 OVERVIEW

…

=cut

#_}
#_{ Methods

=head1 METHODS
=cut

sub new { #_{
#_{ POD

=head2 new

    my $proj = Geo::OSM::Render::Projection->new(); # Use derived class!
    my $vp   = Geo::OSM::Render::Viewport  ->new(); # Use derived class!

    my $osm_renderer = Geo::OSM::Render::Renderer->new(
       $proj,
       $vp
    );


=cut

#_}

  my $class = shift;

  my $self = {};
  bless $self, $class;

  croak "Wrong class $class" unless $self->isa('Geo::OSM::Render::Renderer');

  while (@_) {
    if ($_[0] -> isa('Geo::OSM::Render::Viewport')) {
      $self->{viewport} = shift;
      next;
    }
    if ($_[0] -> isa('Geo::OSM::Render::Projection')) {
      $self->{projection} = shift;
      next;
    }
    last;
  }

  return $self;

} #_}
sub render_node { #_{

#_{ POD

=head2 render_node

    $osm_svg_renderer->render_node($node);

Renders C<< $node>> which must be a L<Geo::OSM::Primitive::Node> (or derived from it)i.

=cut

#_}

  my $self  = shift;
  my $node  = shift;

  croak "$node is not a Node" unless $node->isa('Geo::OSM::Primitive::Node');

} #_}
sub render_way { #_{

#_{ POD

=head2 render_way

    $osm_svg_renderer->render_way($way);

Renders C<< $way>> which must be a L<Geo::OSM::Primitive::Way> (or derived from it)i.

=cut

#_}

  my $self  = shift;
  my $way   = shift;

  croak "$way is not a Way" unless $way->isa('Geo::OSM::Primitive::Way');

} #_}
sub lat_lon_to_map_coordinates { #_{
#_{ POD

=head2 lat_lon_to_map_coordinates

    my ($map_x, $map_y) = $osm_svg_renderer->lat_lon_to_map_coordinates($lat, $lon);

Convert the lattitude/longitude pair C<<$lat>> and C<<$lon>> to map coordinates and return them.

=cut

#_}
  
  my $self = shift;
# my $node = shift;
  my $lat  = shift;
  my $lon  = shift;

# croak "$node is not a node" unless $node->isa('Geo::OSM::Primitive::Node');

  my ($x    , $y    ) = $self->{projection}->lat_lon_to_x_y($lat        , $lon        );
# my ($x    , $y    ) = $self->{projection}->lat_lon_to_x_y($node->{lat}, $node->{lon});
  my ($x_map, $y_map) = $self->{viewport  }->x_y_to_map_x_y($x, $y);

  return ($x_map, $y_map);

} #_}
sub node_to_map_coordinates { #_{
#_{ POD

=head2 node_to_map_coordinates

    my ($map_x, $map_y) = $osm_svg_renderer->node_to_map_coordinates($node);

=cut

#_}
  
  my $self = shift;
  my $node = shift;

  croak "$node is not a node" unless $node->isa('Geo::OSM::Primitive::Node');

  return $self->lat_lon_to_map_coordinates($node->lat, $node->lon);

# my ($x    , $y    ) = $self->{projection}->lat_lon_to_x_y($node->{lat}, $node->{lon});
# my ($x_map, $y_map) = $self->{viewport  }->x_y_to_map_x_y($x, $y);

# return ($x_map, $y_map);

} #_}
#_}
#_{ POD: Author

=head1 AUTHOR

René Nyffenegger <rene.nyffenegger@adp-gmbh.ch>

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
