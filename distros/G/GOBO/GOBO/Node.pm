package GOBO::Node;
use Moose;
use strict;
extends 'GOBO::Base';
with 'GOBO::Identified';
with 'GOBO::Labeled';
with 'GOBO::Attributed';
use Moose::Util::TypeConstraints;

coerce 'GOBO::Node'
      => from 'Str'
      => via { new GOBO::Node(id=>$_) };

has 'source' => (is => 'rw', isa => 'GOBO::Node');
has 'full_name' => (is => 'rw', isa => 'Str');  # e.g. for genes. TBD - make this wrap to synonyms?

use overload ('""' => 'as_string');

sub as_string {
    my $self = shift;
    if ($self->label) {
        return sprintf('%s "%s"',$self->id,$self->label);
    }
    if ($self->id) {
        return $self->id;
    }
    return $self;
}

sub equals {
    my $self = shift;
    my $n = shift;
    return 0 unless $n->id;
    return $n->id eq $self->id;
}

1;

=head1 NAME

GOBO::Node

=head1 SYNOPSIS

  printf '%s "%s"', $n->id, $n->label;

=head1 DESCRIPTION

 A unit in a graph. The Node class hierarchy:

 * L<GOBO::ClassNode>
 ** L<GOBO::TermNode>
 ** L<GOBO::ClassExpression>
 * L<GOBO::RelationNode>
 * L<GOBO::InstanceNode>

With a simple ontology graph, the core units are TermNodes.

=back

=head1 SEE ALSO

L<GOBO::Graph>

=cut



