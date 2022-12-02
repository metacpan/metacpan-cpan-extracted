use Renard::Incunabula::Common::Setup;
package Intertangle::Jacquard::Role::Geometry::Position2D;
# ABSTRACT: A 2-D geometry with variable position
$Intertangle::Jacquard::Role::Geometry::Position2D::VERSION = '0.002';
use Mu::Role;
use Intertangle::Punchcard::Attributes;
use Intertangle::Yarn::Graphene;

variable x =>;
variable y =>;

method origin_point() {
	Intertangle::Yarn::Graphene::Point->new(
		x => $self->x->value,
		y => $self->y->value,
	);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Jacquard::Role::Geometry::Position2D - A 2-D geometry with variable position

=head1 VERSION

version 0.002

=head1 METHODS

=head2 origin_point

...

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
