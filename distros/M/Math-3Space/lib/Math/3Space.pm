package Math::3Space;

our $VERSION = '0.006'; # VERSION
# ABSTRACT: 3D Coordinate math with an intuitive cross-space mapping API

use strict;
use warnings;
use Carp;

require XSLoader;
XSLoader::load('Math::3Space', $Math::3Space::VERSION);

use overload '""' => sub {
  my @vecs = map [$_[0]->$_->xyz], qw(xv yv zv origin);
  "[\n" . join('', map " [@$_]\n", @vecs) . "]\n";
};


{ package Math::3Space::Exports;
	use Exporter::Extensible -exporter_setup => 1;
	*vec3= *Math::3Space::Vector::vec3;
	*space= *Math::3Space::space;
	*frustum_projection= *Math::3Space::Projection::new_frustum;
	*perspective_projection= *Math::3Space::Projection::new_perspective;
	export qw( vec3 space frustum_projection perspective_projection );
}
sub import { shift; Math::3Space::Exports->import_into(scalar(caller), @_) }

sub parent { $_[0]{parent} }

# used by XS to avoid linking directly to PDL
sub _pdl_project_inplace {
	$_[0] -= $_[1] if defined $_[1];
	$_[0] .= $_[0] x $_[2];
	$_[0] += $_[3] if defined $_[3];
}

require Math::3Space::Vector;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Math::3Space - 3D Coordinate math with an intuitive cross-space mapping API

=head1 SYNOPSIS

  use Math::3Space 'vec3', 'space';
  
  my $boat= space;
  my $sailor= space($boat);
  my $dock= space;
  
  # boat moves, carrying sailor with it
  $boat->translate(0,0,1)->rotate(.001, [0,1,0]);
  
  # sailor walks onto the dock
  $sailor->translate(10,0,0);
  $sailor->reparent($dock);
  
  # The boat and dock are both floating
  for ($dock, $boat) {
    $_->translate(rand(.1), rand(.1), rand(.1))
      ->rotate(rand(.001), [1,0,0])
      ->rotate(rand(.001), [0,0,1]);
  }
  
  # Sailor is holding a rope at 1,1,1 relative to themself.
  # Where is the end of the rope in boat-space?
  my $rope_end= vec3(1,1,1);
  $sailor->unproject_inplace($rope_end);
  $dock->unproject_inplace($rope_end);
  $boat->project_inplace($rope_end);
  
  # Do the same thing in bulk with fewer calculations
  my $sailor_to_boat= space($boat)->reparent($sailor);
  @boat_points= $sailor_to_boat->project(@sailor_points);
  
  # Interoperate with OpenGL
  @float16= $boat->get_gl_matrix;

=head1 DESCRIPTION

This module implements the sort of 3D coordinate space math that would typically be done using
a 4x4 matrix, but instead uses a 3x4 matrix composed of axis vectors C<xv>, C<yv>, C<zv>
(i.e. vectors that point along the axes of the coordinate space) plus an origin point.
This results in significantly fewer math operations needed to project points, and gives you a
more useful mental model to work with, like being able to see which direction the coordinate
space is "facing", or which way is "up".

The coordinate spaces track their L</parent> coordinate space, so you can perform advanced
projections from a space inside a space out to a different space inside a space inside a space
without thinking about the details.

The coordinate spaces can be exported as 4x4 matrices for use with OpenGL or other common 3D
systems.

=head1 CONSTRUCTOR

=head2 space

  $space= Math::3Space::space();
  $space= Math::3Space::space($parent);
  $space= $parent->space;

Construct a space (optionally within C<$parent>) initialized to an identity:

  origin => [0,0,0],
  xv     => [1,0,0],
  yv     => [0,1,0],
  zv     => [0,0,1],

=head2 new

  $space= Math::3Space->new(%attributes)

Initialize a space from raw attributes.

=head1 VECTOR FORMATS

This module currently allows vectors to be specified as:

=over

=item L<Math::3Space::Vector>

This is a blessed scalar-ref of packed perl-floats (usually double, but perl can be compiled for long double)

=item Array-ref

C<< [X,Y,Z] >> or C<< [X,Y] >>

=item Hash-ref

C<< { x => $x, y => $y, z => $z } >>

=item PDL ndarray

To assign vectors, you need a 2-element or 3-element array slice:  C<< pdl($x,$y) >>
or C<< pdl($x,$y,$z) >>.  For the projection methods, you can specify higher dimensions as long
as the lowest dimension is 3.

=back

=head1 ATTRIBUTES

=head2 parent

Optional reference to parent coordinate space.  The origin and each of the axis vectors are
described in terms of the parent coordinate space.  A parent of C<undef> means the space is
described in terms of global absolute coordinates.

=head2 parent_count

Number of parent coordinate spaces above this one, i.e. the "depth" of this node in the
hierarchy.

=head2 origin

The C<< [x,y,z] >> vector (point) of this space's origin in terms of the parent space.

=head2 xv

The C<< [x,y,z] >> vector of the X axis (often named "I" in math text)

=head2 yv

The C<< [x,y,z] >> vector of the Y axis (often named "J" in math text)

=head2 zv

The C<< [x,y,z] >> vector of the Z axis (often named "K" in math text)

=head2 is_normal

Returns true if all axis vectors are unit-length and orthogonal to each other.

=head1 METHODS

=head2 clone

Return a new space with the same values, including same parent.

=head2 space

Return a new space describing an identity, with the current object as its parent.

=head2 reparent

Project this coordinate space into a different parent coordinate space.  After the projection,
this space still refers to the same absolute global coordinates as it did before, but it is
described in terms of a different parent coordinate space.

For example, in a 3D game where a player is riding in a vehicle, the parent of the player's
3D space is the vehicle, and the parent space of the vehicle is the ground.
If the player jumps off the vehicle, you would call C<< $player->reparent($ground); >> to keep
the player at their current position, but begin describing them in terms of the ground.

Setting C<$parent> to C<undef> means "global coordinates".

=head2 project

  @local_points= $space->project( @parent_points );
  @parent_points= $space->unproject( @local_points );
  @local_vectors= $space->project_vector( @parent_vectors );
  $space->project_inplace( @points );
  $space->project_vector_inplace( @vectors );

Project one or more points (or vectors) into (or out of) this coordinate space.

The C<project> and C<unproject> methods operate on points, meaning that they subtract or add
the Space's C<origin> to the result in addition to (un)projecting along each of the
C<(xv, yv, zv)> axes.

The C<_vector> variants do not add/subtract L</origin>, so vectors that were acting as
directional indicators will still be indicating that direction afterward regardless of this
space's C<origin>.

The C<_inplace> variants modify the points or vectors and return C<$self> for method chaining.

Each parameter is another vector to process.  The projected vectors are returned in a list the
same length and format as the list passed to this function, e.g. if you supply
L<Math::3Space::Vector> objects you get back C<Vector> objects.  If you supply C<[x,y,z]>
arrayrefs you get back arrayrefs.

Variants:

=over

=item project

=item project_inplace

=item project_vector

=item project_vector_inplace

=item unproject

=item unproject_inplace

=item unproject_vector

=item unproject_vector_inplace

=back

=head2 normalize

Ensure that the C<xv>, C<yv>, and C<zv> axis vectors are unit length and orthogonal to
each other, like proper eigenvectors.  The algorithm is:

  * make zv a unit vector
  * xv = yv cross zv, and make it a unit vector
  * yv = xv cross zv, and make it a unit vector

=head2 translate

  $space->translate($x, $y, $z);
  $space->translate([$x, $y, $z]);
  $space->translate($vec);
  # alias 'tr'
  $space->tr(...);

Translate the origin of the coordinate space, in terms of parent coordinates.

=for Pod::Coverage tr

=head2 travel

  $space->travel($x, $y, $z);
  $space->travel([$x, $y, $z]);
  $space->travel($vec);
  # alias 'go'
  $space->go(...);

Translate the origin of the coordinate space in terms of its own coordinates.
e.g. if your L</zv> vector is being used as "forward", you can make an object travel
forward with C<< $space->travel(0,0,1) >>.

=for Pod::Coverage go

=head2 set_scale

  $space->set_scale($uniform);
  $space->set_scale($x, $y, $z);
  $space->set_scale([$x, $y, $z]);
  $space->set_scale($vector);

Reset the scale of the axes of this space.  For instance, C<< ->set_scale(1) >> normalizes the
vectors so that the scale is identical to the parent coordinate space.

=head2 scale

  $space->scale($uniform);
  $space->scale($x, $y, $z);
  $space->scale([$x, $y, $z]);
  $space->scale($vector);

Scale the axes of this space by a multiplier to the existing scale.

=head2 rotate

  $space->rotate($revolutions, $x, $y, $z);
  $space->rotate($revolutions, [$x, $y, $z]);
  $space->rotate($revolutions, $vec);
  
  $space->rot($revolutions => ...); # alias for 'rotate'
  
  $space->rot_x($revolutions);      # optimized for specific vectors
  $space->rot_xv($revolutions);

This rotates the C<xv>, C<yv>, and C<zv> axes by an angle around some other vector.  The angle
is measured in revolutions rather than degrees or radians, so C<1> is a full rotation back to
where you started, and .25 is a quarter rotation.  The vector is defined in terms of the parent
coordinate space.  If you want to rotate around an arbitrary vector defined in *local*
coordinates, just unproject it out to the parent coordinate space first.

The following (more efficient) variants are available for rotating about the parent's axes or
this space's own axes:

=for Pod::Coverage rot

=over

=item rot_x

=item rot_y

=item rot_z

=item rot_xv

=item rot_yv

=item rot_zv

=back

=head2 get_gl_matrix

  @float16= $space->get_gl_matrix();
  $space->get_gl_matrix($buffer);

Get an OpenGL-compatible 16-element array representing a 4x4 matrix that would perform the same
projection as this space.  This can either be returned as 16 perl floats, or written into a
packed buffer of 16 doubles.

=head1 SEE ALSO

=over

=item L<PDL>, L<PDL::Graphics::TriD>

PDL has many tools for working with vectors and crunching numbers in parallel.
The TriD library defines a number of objects for grouping polygon meshes and ways to
visualize them.

=item L<OpenGL::Sandbox>

OpenGL::Sandbox provides handy wrappers around OpenGL textures, shaders, fonts, etc.

=back

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 CONTRIBUTOR

=for stopwords Ed J

Ed J <mohawk2@users.noreply.github.com>

=head1 VERSION

version 0.006

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
