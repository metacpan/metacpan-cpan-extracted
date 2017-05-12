package GOBO::LinkStatement;
use Moose;
use strict;
extends 'GOBO::Statement';
use GOBO::Node;

has 'target' => ( is=>'rw', isa=>'GOBO::Node', coerce=>1 );
has 'distance_index' => ( is=>'rw', isa=>'HashRef[Number]', coerce=>1 );

sub equals {
    my $self = shift;
    my $s = shift;
    my $neq = $self->node->id() eq $s->node->id();
    return 0 unless $neq;

    return 0 unless $self->relation();
    return 0 unless $s->relation();
    my $req =  $self->relation->id() eq $s->relation->id();
    return 0 unless $req;

    my $teq =  $self->target->id() eq $s->target->id();
    return 0 unless $teq;

    return $self->is_intersection() if $s->is_intersection();
    return $s->is_intersection() if $self->is_intersection();

    return 1;
}

=head1 NAME

GOBO::LinkStatement

=head1 SYNOPSIS

  printf '%s --[%s]--> %s', $s->node->id, $s->relation, $->target->id;

=head1 DESCRIPTION

A type of GOBO::Statement that connects two GOBO::Node objects via a GOBO::RelationNode object.

Can also be thought of as an "edge" in an GOBO::Graph

LiteralStatements inherit the roles GOBO::Attributed and
GOBO::Identified (via GOBO::Statement). This means they can have
metadata attached. For example, who created the edge, when and why.

=head2 Subtypes

An important subtype of this class is GOBO::Annotation, which attaches
evidence to edges.

This class could conceivably be extended to add accessors for distance
etc for phylogenetic trees

=cut

1;
