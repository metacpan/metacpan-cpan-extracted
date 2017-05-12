package GOBO::Statement;
use Moose;
use strict;
with 'GOBO::Attributed';
with 'GOBO::Identified';

use GOBO::Node;
use GOBO::RelationNode;

has 'node' => ( is=>'rw', isa=>'GOBO::Node', coerce=>1 );
has 'relation' => ( is=>'rw', isa=>'GOBO::RelationNode', coerce=>1 );
#has 'target' => ( is=>'rw', isa=>'Item');
has 'inferred' => ( is=>'rw', isa=>'Bool');
has 'negated' => ( is=>'rw', isa=>'Bool'); # TODO: use this or NegatedStatement?
has 'is_intersection' => ( is=>'rw', isa=>'Bool');
has 'is_union' => ( is=>'rw', isa=>'Bool');
has 'sub_statements' => ( is=>'rw', isa=>'ArrayRef[GOBO::Statement]');

use overload ('""' => 'as_string');
sub as_string {
    my $self = shift;
    return sprintf("(%s --[%s]-->%s)",$self->node || '?',$self->relation || '?', $self->can('target') ? $self->target : '?' );
}


sub matches {
    my $self = shift;
    my %h = @_;
    foreach my $k (keys %h) {
        my $v = $self->$k;
        return 0 unless $v->id eq $h{$k};
    }
    return 1;
}

=head1 NAME

GOBO::Statement

=head1 SYNOPSIS

  printf '%s --[%s]--> %s', $s->node, $s->relation, $->target;

=head1 DESCRIPTION

A type of GOBO::Statement that connects an GOBO::Node object to another
entity via a GOBO::RelationNode object. This can be thought of as a
sentence or statement about a node.

In RDF and Chado terminology, the node can be thought of as the
"subject", and the target the "object". The terms "subject" and
"object" are avoided due to being overloaded.

The two subtypes are GOBO::LinkStatement (edges) or
GOBO::LiteralStatement (tag-values). For most bio-ontologies, the
Statements will be LinkStatements.

Statements have the roles GOBO::Attributed and GOBO::Identified. This
means they can have metadata attached. For example, who made the
statement and when.


=cut

1;
