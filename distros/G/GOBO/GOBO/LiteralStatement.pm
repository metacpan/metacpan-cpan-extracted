package GOBO::LiteralStatement;
use Moose;
use strict;
extends 'GOBO::Statement';
use GOBO::Node;

has 'target' => ( is=>'ro', isa=>'Value');

sub equals {
    my $self = shift;
    my $s = shift;
    my $neq = $self->node->id() eq $s->node->id();
    return 0 unless $neq;

    return 0 unless $self->relation();
    return 0 unless $s->relation();
    my $req =  $self->relation->id() eq $s->relation->id();
    return 0 unless $req;

    my $teq =  $self->target() eq $s->target();
    return 0 unless $teq;

    return $self->is_intersection() == $s->is_intersection();

    return 0;
}

# TODO -- use this or use frame-style? both

=head1 NAME

GOBO::LiteralStatement

=head1 SYNOPSIS

  printf '%s --[%s]--> %s', $s->node, $s->relation, $->target;

=head1 DESCRIPTION

LiteralStatements are one of two basic types of
GOBO::Statement. Whereas an GOBO::LinkStatement will connect a node to
another node, a literal statement connects a node to a "literal", or
Value which can be a a string, number of other kind of moose Value.

=head2 What's this for?

LiteralStatements inherit the roles GOBO::Attributed and
GOBO::Identified (via GOBO::Statement). This means they can have
metadata attached, in the same way as edges in a graph. This stands in
contrast to implementing the tag-values as accessors on the node
itself. The difference between these styles is sometimes called
"Axiom-style" vs "Frame-style", depending on whether the statement or
the node is the primary entity of interest.

At this stage the object model allows both styles.... It may even be
possible to use the Moose machinery to allow seamless switching
between both...?

=cut


1;
