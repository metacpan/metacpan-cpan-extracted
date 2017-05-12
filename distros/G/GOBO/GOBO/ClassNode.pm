package GOBO::ClassNode;
use Moose;
use strict;
extends 'GOBO::Node';

use Moose::Util::TypeConstraints;

coerce 'GOBO::ClassNode'
      => from 'Str'
      => via { new GOBO::ClassNode(id=>$_) };

has disjoint_from_list => (is => 'rw', isa => 'ArrayRef[GOBO::ClassNode]');

sub add_disjoint_from {
    my $self = shift;
    $self->disjoint_from_list([]) unless $self->disjoint_from_list([]);
    push(@{$self->disjoint_from_list},@_);
}

1;


=head1 NAME

GOBO::ClassNode

=head1 SYNOPSIS

  printf '%s "%s"', $n->id, $n->label;

=head1 DESCRIPTION

Formally, a class is a collection of instances. However, in many cases these are not instantiated in perl.

ClassNodes can either be explicitly named (GOBO::TermNode) or they can be logical boolean expressions (GOBO::ClassExpression)

          +--- InstanceNode
          |                 +--- ClassExpression
          |                 |
  Node ---+--- ClassNode ---+
          |                 |
          |                 +--- TermNode
          +--- RelationNode

=head2 Terminological note

Note the parallel terminology: ontology formalisms consist of classes
(types) and instances (particulars). These should NOT be confused with
their object-oriented counterparts. An instance of the GO type
"nucleus" is an actual cell nucleus. These are almost never
"instantiated" in the object-oriented sense, but in reality there are
trillions of these instances. ClassNodes can be thought of as sets,
and InstanceNodes for their extension.

Here we use the term "ClassNode" and "InstanceNode" to denote elements
of the perl object model.

=head1 SEE ALSO

GOBO::Graph

=cut
