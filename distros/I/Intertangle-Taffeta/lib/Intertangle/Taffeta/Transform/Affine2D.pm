use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Transform::Affine2D;
# ABSTRACT: A 2D affine transform
$Intertangle::Taffeta::Transform::Affine2D::VERSION = '0.001';
use Mu;
use Renard::Incunabula::Common::Types qw(InstanceOf Str Bool);
use Intertangle::Yarn::Types qw(Point);
use Intertangle::Yarn::Graphene;
use List::AllUtils qw(all);

has matrix => (
	is => 'ro',
	isa => InstanceOf['Intertangle::Yarn::Graphene::Matrix'],
	default => sub {
		my $m = Intertangle::Yarn::Graphene::Matrix->new;
		$m->init_identity;
		$m;
	},
);

lazy cairo_matrix => method() {
	require Cairo;

	my (
		$is_2d_affine,
		$xx, $yx,
		$xy, $yy,
		$x0, $y0
	) = $self->matrix->to_2d;

	die "Not a 2D affine matrix" unless $is_2d_affine;

	my $cairo_matrix = Cairo::Matrix->init(
		$xx, $yx,
		$xy, $yy,
		$x0, $y0
	);

	$cairo_matrix;
}, isa => InstanceOf['Cairo::Matrix'];

lazy svg_transform => method() {
	# / a c e \
	# | b d f |
	# \ 0 0 1 /
	my (
		$is_2d_affine,
		$xx, $yx,  # a c
		$xy, $yy,  # b d

		$x0,  # e
		$y0   # f
	) = $self->matrix->to_2d;

	die "Not a 2D affine matrix" unless $is_2d_affine;

	my (
	$m_a , $m_c,
	$m_b , $m_d,

	$m_e,
	$m_f
	) = (
		$xx, $yx,
		$xy, $yy,

		$x0,
		$y0
	);

	return sprintf("matrix(%f, %f, %f, %f, %f, %f)",
		$m_a, $m_b,
		$m_c, $m_d,
		$m_e, $m_f,
	);
}, isa => Str;

lazy is_identity => method() {
	$self->matrix->is_identity;
}, isa => Bool;

around BUILDARGS => fun( $orig, $class, %args ) {
	my $matrix;

	my $matrix_set = 0;

	if( exists $args{matrix} ) {
		if( $matrix_set ) {
			die "Can not use multiple approaches to construct matrix";
		} else {
			$matrix_set = 1;
		}

		#$class->_is_matrix_affine( $args{matrix} );
		$matrix = $args{matrix};
	}

	if( exists $args{matrix_abcdef} ) {
		if( $matrix_set ) {
			die "Can not use multiple approaches to construct matrix";
		} else {
			$matrix_set = 1;
		}

		$matrix = Intertangle::Yarn::Graphene::Matrix->new;
		$matrix->init_from_2d(
			$args{matrix_abcdef}{a} // 1, $args{matrix_abcdef}{c} // 0,
			$args{matrix_abcdef}{b} // 0, $args{matrix_abcdef}{d} // 1,

			$args{matrix_abcdef}{e} // 0 , $args{matrix_abcdef}{f} // 0,
		);
	}

	if( exists $args{matrix_xy} ) {
		if( $matrix_set ) {
			die "Can not use multiple approaches to construct matrix";
		} else {
			$matrix_set = 1;
		}

		$matrix = Intertangle::Yarn::Graphene::Matrix->new;
		$matrix->init_from_2d(
			$args{matrix_xy}{xx} // 1,
			$args{matrix_xy}{yx} // 0,
			$args{matrix_xy}{xy} // 0,
			$args{matrix_xy}{yy} // 1,
			$args{matrix_xy}{x0} // 0,
			$args{matrix_xy}{y0} // 0,
		);
	}

	$args{matrix} = $matrix if defined $matrix;

	return $class->$orig(%args);
};

classmethod _is_matrix_affine( $matrix ) {
	$class->_is_matrix_affine_graphene( $matrix );
}

classmethod _is_matrix_affine_graphene( $matrix ) {
	die "Not a 2D affine matrix" unless $matrix->is_2d;
}

classmethod _is_matrix_affine_exact( $matrix ) {
	my $ma = $matrix->to_ArrayRef;
	# NOTE this uses exact checking instead of floating point
	# approximation. This should be fine because these are values
	# that are set by the user.
	unless(
		(
			all { $_ == 0 } (
				$ma->[0][2], $ma->[0][3],
				$ma->[1][2], $ma->[1][3],
				$ma->[2][0], $ma->[2][1],
				$ma->[3][2], $ma->[2][3],
			)
		)
		&&
		(
			all { $_ == 1 } (
				$ma->[2][2], $ma->[3][3],
			)
		)
	) {
		die "Not a 2D affine transform matrix";
	}
}

method compose( $transform ) {
	Intertangle::Taffeta::Transform::Affine2D->new(
		matrix => ( $self->matrix x $transform->matrix ),
	);
}

method compose_premultiply( $transform ) {
	Intertangle::Taffeta::Transform::Affine2D->new(
		matrix => ( $transform->matrix x $self->matrix ),
	);
}

method apply_to_bounds( $bounds ) {
	$self->matrix->transform_bounds( $bounds );
}

method apply_to_point( (Point->coercibles) $point ) {
	$self->matrix->transform_point( Point->coerce($point) );
}

method apply_to_vec3( $vec ) {
	$self->matrix->transform_vec3( $vec );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Transform::Affine2D - A 2D affine transform

=head1 VERSION

version 0.001

=head1 EXTENDS

=over 4

=item * L<Moo::Object>

=back

=head1 ATTRIBUTES

=head2 matrix

The C<Intertangle::Yarn::Graphene::Matrix> matrix representing the affine transform.

This matrix is the identity matrix by default.

=head2 cairo_matrix

A C<Cairo::Matrix> representation of the affine transform.

=head2 svg_transform

A C<Str> representation of the affine transform that can be used with
C<transform> attribute for SVG elements such as C<< <g> >> or graphics
elements.

See L<https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/transform>.

=head1 METHODS

=head2 BUILDARGS

matrix_abcdef

   [
       a c 0 0
       b d 0 0
       0 0 1 0
       e f 0 1
   ]

matrix_xy

  [
     xx yx  0  0
     xy yy  0  0
      0  0  1  0
     x0 y0  0  1
  ]

If keys are not given for either approach, the default values for the identity
matrix are used:

  a, d : 1
  b, c : 0
  e, f : 0

  xx, yy : 1
  yx, xy : 0
  x0, y0 : 0

=head2 compose

Compose the transform with another transform by using matrix multiplication: (C<this x that>).

=head2 compose_premultiply

Compose the transform with another transform by using matrix multiplication: (C<that x this>).

=head2 apply_to_bounds

Apply the transformation to a C<Intertangle::Yarn::Graphene::Rect>.

=head2 apply_to_point

Apply the transformation to a C<Intertangle::Yarn::Graphene::Point>.

=head2 apply_to_vec3

Apply the transformation to a C<Intertangle::Yarn::Graphene::Vec3>.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
