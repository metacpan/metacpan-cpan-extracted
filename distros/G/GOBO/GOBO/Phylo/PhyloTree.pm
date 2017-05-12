package GOBO::Phylo::PhyloTree;
use Moose;
use strict;
extends 'GOBO::Graph';

sub rooted {
}

1;

=head1 NAME

GOBO::Phylo::PhyloTree

=head1 SYNOPSIS

=head1 DESCRIPTION

An GOBO::Graph in which each node has at most 1 parents, and each node
is a GOBO::Phylo::PhyloNode

=head1 SEE ALSO

GOBO::Graph

=cut
