use Renard::Incunabula::Common::Setup;
package Intertangle::Jacquard::Actor::Role::Tree::TreeDAGNode;
# ABSTRACT: Store in Tree::DAG_Node
$Intertangle::Jacquard::Actor::Role::Tree::TreeDAGNode::VERSION = '0.001';
use Moo::Role;

use Renard::Incunabula::Common::Types qw(InstanceOf);
use Tree::DAG_Node;

has _tree_dag_node => (
	is => 'ro',
	isa => InstanceOf['Tree::DAG_Node'],
	default => method() {
		Tree::DAG_Node->new({ attributes => { actor => $self } })
	},
);


method parent() {
	my $parent_dag = $self->_tree_dag_node->mother;
	return defined $parent_dag
		? $parent_dag->attributes->{actor}
		: undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Intertangle::Jacquard::Actor::Role::Tree::TreeDAGNode - Store in Tree::DAG_Node

=head1 VERSION

version 0.001

=head1 ATTRIBUTES

=head2 _tree_dag_node

Use delegation to C<Tree::DAG_Node> to build scene graph.

=head1 METHODS

=head2 parent

Returns the parent of this actor.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
