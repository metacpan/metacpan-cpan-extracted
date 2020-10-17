use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Transform::Affine2D::Scaling;
# ABSTRACT: A 2D affine scaling
$Intertangle::Taffeta::Transform::Affine2D::Scaling::VERSION = '0.001';
use Mu;
use Intertangle::Yarn::Graphene;
use Renard::Incunabula::Common::Types qw(InstanceOf);
use Intertangle::Yarn::Types qw(Vec2);

extends qw(Intertangle::Taffeta::Transform::Affine2D);

has scale => (
	is => 'ro',
	isa => Vec2,
	coerce => 1,
	required => 1,
);

lazy matrix => method() {
	my $matrix = Intertangle::Yarn::Graphene::Matrix->new;
	$matrix->init_scale( $self->scale->x, $self->scale->y, 1 );
	$matrix;
}, isa => InstanceOf['Intertangle::Yarn::Graphene::Matrix'];

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Transform::Affine2D::Scaling - A 2D affine scaling

=head1 VERSION

version 0.001

=head1 EXTENDS

=over 4

=item * L<Intertangle::Taffeta::Transform::Affine2D>

=back

=head1 ATTRIBUTES

=head2 scale

A C<Vec2> indicating the scaling amount in x and y respectively.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
