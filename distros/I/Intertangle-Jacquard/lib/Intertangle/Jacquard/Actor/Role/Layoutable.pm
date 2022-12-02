use Renard::Incunabula::Common::Setup;
package Intertangle::Jacquard::Actor::Role::Layoutable;
# ABSTRACT: A role for actors that can layout their children
$Intertangle::Jacquard::Actor::Role::Layoutable::VERSION = '0.002';
use Moo::Role;

with qw(Intertangle::Jacquard::Actor::Role::Tree::TreeDAGNode::WithChildren);

has layout => (
	is => 'ro',
	predicate => 1,
);

after add_child => method( $actor, %options ) {
	if( $self->has_layout ) {
		$self->layout->add_actor( $actor,
			exists $options{layout} ? %{ $options{layout} } : ()
		);
	}
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Jacquard::Actor::Role::Layoutable - A role for actors that can layout their children

=head1 VERSION

version 0.002

=head1 CONSUMES

=over 4

=item * L<Intertangle::Jacquard::Actor::Role::DataPrinter>

=item * L<Intertangle::Jacquard::Actor::Role::Tree::TreeDAGNode::WithChildren>

=back

=head1 ATTRIBUTES

=head2 layout

The layout to use for the children actors.

Predicate: C<has_layout>

=head1 METHODS

=head2 has_layout

Predicate for C<layout> attribute.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
