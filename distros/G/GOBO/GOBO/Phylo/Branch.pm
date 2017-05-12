package GOBO::Phylo::Branch;
use Moose;
use strict;
extends 'GOBO::LinkStatement';
use GOBO::Evidence;

has distance => ( is=>'rw', isa=>'float');

=head1 NAME

GOBO::Phylo::Branch

=head1 SYNOPSIS

  printf '%s --[%s]--> %s branchlen: %s', $s->node->id, $s->relation, $s->target->id,$s->distance ;

=head1 DESCRIPTION

An edge in a Phylogenetic tree. Extends GOBO::LinkStatement with distances

=cut

1;
