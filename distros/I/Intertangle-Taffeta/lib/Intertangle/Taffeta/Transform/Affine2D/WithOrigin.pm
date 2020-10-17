use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Transform::Affine2D::WithOrigin;
# ABSTRACT: An affine 2D transformation about an origin
$Intertangle::Taffeta::Transform::Affine2D::WithOrigin::VERSION = '0.001';
use Mu;

extends qw(Intertangle::Taffeta::Transform::Affine2D);

use Intertangle::Yarn::Types qw(Point);
use Intertangle::Taffeta::Transform::Affine2D::Translation;

has affine2d => (
	is => 'ro',
	required => 1,

);

has origin => (
	is => 'ro',
	isa => Point,
	coerce => 1,
);

lazy matrix => method() {
	my $back = Intertangle::Taffeta::Transform::Affine2D::Translation->new(
		translate => - $self->origin,
	);
	my $forward = Intertangle::Taffeta::Transform::Affine2D::Translation->new(
		translate => $self->origin,
	);

	$back->matrix x $self->affine2d->matrix x $forward->matrix;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Transform::Affine2D::WithOrigin - An affine 2D transformation about an origin

=head1 VERSION

version 0.001

=head1 EXTENDS

=over 4

=item * L<Intertangle::Taffeta::Transform::Affine2D>

=back

=head1 ATTRIBUTES

=head2 affine2d

The affine 2D transform to use with origin [0,0].

=head2 origin

A C<Point> that is the origin of the transform.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
