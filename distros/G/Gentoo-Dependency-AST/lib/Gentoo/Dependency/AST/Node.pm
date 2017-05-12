
use strict;
use warnings;

package Gentoo::Dependency::AST::Node;
BEGIN {
  $Gentoo::Dependency::AST::Node::AUTHORITY = 'cpan:KENTNL';
}
{
  $Gentoo::Dependency::AST::Node::VERSION = '0.001001';
}

# ABSTRACT: An Abstract Syntax Tree Node



use Class::Tiny {
  children => sub { [] }
};


sub add_dep {
  my ( $self, $state, $dep ) = @_;
  push @{ $self->children }, $dep;
  return;
}


sub enter_notuse_group {
  my ( $self, $state, $group ) = @_;
  push @{ $self->children }, $group;
  $state->_pushstack($group);
  return;
}


sub enter_use_group {
  my ( $self, $state, $group ) = @_;
  push @{ $self->children }, $group;
  $state->_pushstack($group);
  return;
}


sub enter_or_group {
  my ( $self, $state, $group ) = @_;
  push @{ $self->children }, $group;
  $state->_pushstack($group);
  return;
}


sub enter_and_group {
  my ( $self, $state, $group ) = @_;
  push @{ $self->children }, $group;
  $state->_pushstack($group);
  return;
}


sub exit_group {
  my ( $self, $state ) = @_;
  $state->_popstack;
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Gentoo::Dependency::AST::Node - An Abstract Syntax Tree Node

=head1 VERSION

version 0.001001

=head1 METHODS

=head2 C<add_dep>

Tell C<$node> that a dependency C<$dep_object> has been seen.

    $node->add_dep( $state_object, $dep_object );

=head2 C<enter_notuse_group>

Tell C<$node> that a child C<!use?> group C<$notuse_object> has been seen,
and pass tree construction to that object.

    $node->enter_notuse_group( $state_object, $notuse_object );

=head2 C<enter_use_group>

Tell C<$node> that a child C<use?> group C<$use_object> has been seen,
and to pass tree construction to that object.

    $node->enter_use_group( $state_object, $use_object );

=head2 C<enter_or_group>

Tell C<$node> that a child C<|| ()> group C<$or_object> has been seen,
and to pass tree construction to that object.

    $node->enter_or_group( $state_object, $or_object );

=head2 C<enter_and_group>

Tell C<$node> that a child C<()> group C<$and_object> has been seen,
and to pass tree construction to that object.

    $node->enter_and_group( $state_object, $and_object );

=head2 C<exit_group>

Tell C<$node> that a group terminator has been seen, so
finalize the present node, and defer tree construction to the parent object.

    $node->enter_and_group( $state_object );

=head1 ATTRIBUTES

=head2 C<children>

Contains the child nodes of this node. May not be relevant for some node types.

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Gentoo::Dependency::AST::Node",
    "interface":"class",
    "inherits":"Class::Tiny::Object"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
