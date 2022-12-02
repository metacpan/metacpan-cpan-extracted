use Renard::Incunabula::Common::Setup;
package Intertangle::Jacquard::Actor::Role::Tree::TreeDAGNode::WithChildren;
# ABSTRACT: A role for actors with child actors
$Intertangle::Jacquard::Actor::Role::Tree::TreeDAGNode::WithChildren::VERSION = '0.002';
use Moo::Role;
use Intertangle::Jacquard::Types qw(Actor);

requires '_tree_dag_node';

method add_child( (Actor) $actor, %options  ) {
	$self->_tree_dag_node->add_daughter(
		$actor->_tree_dag_node
	);
}

method number_of_children() {
	scalar $self->_tree_dag_node->daughters;
}

method children( $children = undef ) {
	if( defined $children ) {
		$self->_tree_dag_node->clear_daughters;
		$self->_tree_dag_node->add_daughters(
			map { $_->_tree_dag_node } @$children
		);
	} else {
		return [ map { $_->attributes->{actor} } $self->_tree_dag_node->daughters ];
	}
}

after BUILD => method( $args ) {
	$self->children( $args->{children} ) if exists $args->{children};
};

with qw(Intertangle::Jacquard::Actor::Role::DataPrinter);
method _data_printer_internal() { $self->children }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Jacquard::Actor::Role::Tree::TreeDAGNode::WithChildren - A role for actors with child actors

=head1 VERSION

version 0.002

=head1 CONSUMES

=over 4

=item * L<Intertangle::Jacquard::Actor::Role::DataPrinter>

=back

=head1 METHODS

=head2 add_child

Add a child actor.

=head2 number_of_children

Number of children for this actor.

=head2 children

Returns a C<ArrayRef> of the children of this actor.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
