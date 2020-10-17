use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Transform::Affine2D::Translation;
# ABSTRACT: A 2D affine translation
$Intertangle::Taffeta::Transform::Affine2D::Translation::VERSION = '0.001';
use Mu;
use Intertangle::Yarn::Graphene;
use Renard::Incunabula::Common::Types qw(InstanceOf);
use Intertangle::Yarn::Types qw(Point);

extends qw(Intertangle::Taffeta::Transform::Affine2D);

has translate => (
	is => 'ro',
	isa => Point,
	coerce => 1,
	required => 1,
);

lazy matrix => method() {
	my $matrix = Intertangle::Yarn::Graphene::Matrix->new;
	$matrix->init_translate( $self->translate->to_Point3D );
	$matrix;
}, isa => InstanceOf['Intertangle::Yarn::Graphene::Matrix'];

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Transform::Affine2D::Translation - A 2D affine translation

=head1 VERSION

version 0.001

=head1 EXTENDS

=over 4

=item * L<Intertangle::Taffeta::Transform::Affine2D>

=back

=head1 ATTRIBUTES

=head2 translate

A C<Point> indicating where to translate to.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
