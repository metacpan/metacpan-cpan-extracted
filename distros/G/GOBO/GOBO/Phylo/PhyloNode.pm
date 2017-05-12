package GOBO::Phylo::PhyloNode;
use Moose;
use strict;
extends 'GOBO::Node';

use Moose::Util::TypeConstraints;

coerce 'GOBO::Phylo::PhyloNode'
    => from 'GOBO::Node'
    => via { new GOBO::Phylo::PhyloNode(represents=>$_) };

#has 'represents' => (is=>'ro', isa=>'GOBO::Statement',handles=>qr/.*/);
has 'represents' => (is=>'ro', isa=>'GOBO::Statement');
has 'parent' => (is=>'ro', isa=>'GOBO::Phylo::PhyloNode');
has 'tree' => (is=>'ro', isa=>'GOBO::Phylo::PhyloTree');

coerce 'GOBO::PhyloNode'
      => from 'Str'
      => via { new GOBO::PhyloNode(id=>$_) };

1;

=head1 NAME

GOBO::Phylo::PhyloNode

=head1 SYNOPSIS

  printf '%s "%s"', $n->id, $n->label;

=head1 DESCRIPTION

An GOBO::Node in a phylogenetic tree that represents some kind of evolvable entity

Note that the same entity (e.g. gene, species) can be present in
multiple GOBO::Phylo::PhyloTree. It may have different parents in each.

This necessitates having a separate object to represent both (a) the
node in the tree, together with its hypothetical placements and (b)
the entity it represents. The 'represents' accessor links these.

=head2 TBD

The parent attribute can also be obtained from the tree
object. Redundancy? Frame-style vs axiom-style

=cut
