use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Transform::Affine2D::Rotation;
# ABSTRACT: A 2D affine rotation
$Intertangle::Taffeta::Transform::Affine2D::Rotation::VERSION = '0.001';
use Mu;
use Intertangle::Yarn::Graphene;
use Renard::Incunabula::Common::Types qw(InstanceOf);
use Intertangle::Yarn::Types qw(Point AngleDegrees);

extends qw(Intertangle::Taffeta::Transform::Affine2D);

has angle => (
	is => 'ro',
	isa => AngleDegrees,
	required => 1,
);

lazy _axis => method() {
	Intertangle::Yarn::Graphene::Vec3->new(
		x => 0,
		y => 0,
		z => 1
	);
}, isa => InstanceOf['Intertangle::Yarn::Graphene::Vec3'];

lazy matrix => method() {
	my $rot_matrix = Intertangle::Yarn::Graphene::Matrix->new;
	$rot_matrix->init_rotate( $self->angle, $self->_axis );

	# Fix rotation to be 2D
	my $matrix = Intertangle::Yarn::Graphene::Matrix->new;
	$matrix->init_from_vec4(
		$rot_matrix->get_row(0),
		$rot_matrix->get_row(1),
		Intertangle::Yarn::Graphene::Vec4::z_axis(),
		$rot_matrix->get_row(3),
	);

	$matrix;
}, isa => InstanceOf['Intertangle::Yarn::Graphene::Matrix'];

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Transform::Affine2D::Rotation - A 2D affine rotation

=head1 VERSION

version 0.001

=head1 EXTENDS

=over 4

=item * L<Intertangle::Taffeta::Transform::Affine2D>

=back

=head1 ATTRIBUTES

=head2 angle

Angle in degrees.

Positive value for clockwise rotation and negative for counterclockwise
rotation.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
