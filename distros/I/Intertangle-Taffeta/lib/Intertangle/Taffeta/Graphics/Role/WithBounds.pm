use Renard::Incunabula::Common::Setup;
package Intertangle::Taffeta::Graphics::Role::WithBounds;
# ABSTRACT: A role for the bounds of a graphic object
$Intertangle::Taffeta::Graphics::Role::WithBounds::VERSION = '0.001';
use Moo::Role;
use Intertangle::Yarn::Graphene;

use Renard::Incunabula::Common::Types qw(InstanceOf);
use Intertangle::Yarn::Types qw(Point Size);

has identity_bounds => (
	is => 'lazy', # _build_identity_bounds
	isa => InstanceOf['Intertangle::Yarn::Graphene::Rect'],
);

method _build_identity_bounds() {
	Intertangle::Yarn::Graphene::Rect->new(
		origin => $self->origin,
		size   => $self->size,
	);
}

has origin => (
	is => 'ro',
	isa => Point,
	coerce => 1,
	default => sub { Intertangle::Yarn::Graphene::Point->new( x => 0, y => 0 ) },
);

has size => (
	is => 'lazy', # _build_size
	isa => Size,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Taffeta::Graphics::Role::WithBounds - A role for the bounds of a graphic object

=head1 VERSION

version 0.001

=head1 ATTRIBUTES

=head2 identity_bounds

A C<Intertangle::Yarn::Graphene::Rect> that represents the bounds of this graphics
object when the transform is the identity matrix.

=head2 origin

A C<Point> that represents the origin of this graphics
object.

The default is at C<(0, 0)>.

=head2 size

A C<Size> that represents the size of this graphics
object.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
