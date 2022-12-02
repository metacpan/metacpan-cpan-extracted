use Renard::Incunabula::Common::Setup;
package Intertangle::Jacquard::Role::Render::QnD::Bounds::Group;
# ABSTRACT: Quick-and-dirty group bounds
$Intertangle::Jacquard::Role::Render::QnD::Bounds::Group::VERSION = '0.002';
use Moo::Role;
use Intertangle::Yarn::Graphene;
use Intertangle::Yarn::Types qw(Point Size);

method bounds() {
	my $rect = Intertangle::Yarn::Graphene::Rect->new(
		origin => $self->children->[0]->origin_point,
		size => $self->children->[0]->size,
	);
	for my $child (@{ $self->children }) {
		$rect = $rect->union( $child->bounds );
	}

	$rect;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Jacquard::Role::Render::QnD::Bounds::Group - Quick-and-dirty group bounds

=head1 VERSION

version 0.002

=head1 METHODS

=head2 bounds

...

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
