package GOBO::TermNode;
use Moose;
use strict;
extends 'GOBO::ClassNode';
with 'GOBO::Definable';

1;

=head1 NAME

GOBO::TermNode

=head1 SYNOPSIS

  printf '%s "%s" def: "%s"', $n->id, $n->label, $n->definition;

=head1 DESCRIPTION

Core element in an ontology. 

=head1 SEE ALSO

GOBO::Graph

=cut


