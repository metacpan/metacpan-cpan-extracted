package Math::3Space::Projection;

our $VERSION = '0.008'; # VERSION
# ABSTRACT: Object wrapping a 4D projection, for use in OpenGL rendering

# All methods handled by XS
require Math::3Space;

sub new_frustum     { shift if !ref $_[0] && $_[0] eq __PACKAGE__; &_frustum }
sub new_perspective { shift if !ref $_[0] && $_[0] eq __PACKAGE__; &_perspective }

use overload '""' => sub { "[@{[$_[0]->matrix_colmajor]}]" };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Math::3Space::Projection - Object wrapping a 4D projection, for use in OpenGL rendering

=head1 SYNOPSIS

  use Math::3Space qw/ space perspective /;
  
  my $projection= perspective(1/5, 4/3, 1, 10000);
  my $modelview= space;
  glLoadMatrixf_p($projection->matrix_colmajor($modelview));
  # or
  glLoadMatrixf_s($projection->matrix_pack_float($modelview));

=head1 DESCRIPTION

While the 3Space objects can represent all 3D affine coordinate transformations, they cannot
represent the final 4D transformation that OpenGL uses for a perspective projection.  The
perspective transformation stretches the near-Z coordinates while squashing the far-Z
coordinates, which can't be described by 3D eigenvectors.  This is the reason all the typical
3D math is using 4x4 matrices.

But, in keeping with the theme of this module collection, you can in fact take a 3x4 Space
matrix and multiply it by a (logically) 4x4 projection matrix in many fewer multiplications
than invoking the full 4x4 matrix math.  Multiplying two 4x4 matrices is nominally 64
multiplications, but this module does it in 20, or 12 for a centered frustum!

=head1 CONSTRUCTORS

=head2 new_perspective

  $projection= Math::3Space::Projection->new_perspective(
    $vertical_field_of_view, $aspect, $near_z, $far_z
  );

C<$vertical_field_of_view> is in "revolutions", not radians.  This saves you from needing to
mention Pi in your parameter.

C<$aspect> is the typical "4/3" or "16/9" ratio of width over height.

C<$near_z> and C<far_z> are the range of Z coordinates of the space to be projected.

=head2 new_frustum

  $perspective= Math::3Space::Projection->new_frustum(
    $left, $right, $bottom, $top, $near_z, $far_z
  );

Same as OpenGL's L<glFrustum|https://docs.gl/gl3/glFrustum>.  It describes the edges of the
near face of a stretched box where the sides of the box are planes that pass through the origin
and the edge of the viewport at C<$near_z>, continuing outward until they reach C<$far_z>.

=head1 METHODS

=head2 matrix_colmajor

  @mat16= $projection->matrix_colmajor;         # the matrix of the projection itself
  @mat16= $projection->matrix_colmajor($space); # the space transformed by the projection

Returns the 16 floating point values of the 4x4 matrix, in column-major order as used by OpenGL.

=head2 matrix_pack_float

  $gl_float_buffer= $projection->matrix_pack_float;
  $gl_float_buffer= $projection->matrix_pack_float($space);

Same as C<matrix>, but pack the numbers into a scalar of floats.

=head2 matrix_pack_double

  $gl_double_buffer= $projection->matrix_pack_double;
  $gl_double_buffer= $projection->matrix_pack_double($space);

Same as C<matrix>, but pack the numbers into a scalar of doubles.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 VERSION

version 0.008

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
