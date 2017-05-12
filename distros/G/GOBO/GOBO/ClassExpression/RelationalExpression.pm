package GOBO::ClassExpression::RelationalExpression;
use Moose;
use strict;
extends 'GOBO::ClassExpression';
use GOBO::Statement;
use GOBO::RelationNode;
use GOBO::Node;

##delegation+constructors don't play well
##has 'statement' => (is=>'ro', isa=>'GOBO::Statement',handles=>['relation','target']);

has relation => (is=>'ro', isa=>'GOBO::RelationNode', coerce=>1);
has target => (is=>'ro', isa=>'GOBO::Node', coerce=>1);
has cardinality => (is=>'ro', isa=>'Int');
has max_cardinality => (is=>'ro', isa=>'Int');
has min_cardinality => (is=>'ro', isa=>'Int');

use overload ('""' => 'as_string');
sub as_string {
    my $self = shift;
    return sprintf('%s(%s)',$self->relation,$self->target);
}

1; 

=head1 NAME

GOBO::ClassExpression::RelationalExpression

=head1 SYNOPSIS

=head1 DESCRIPTION

An GOBO::ClassExpression in which the members are constructed by
applying a relation. For example, "the set of all things that are
part_of an oocyte". In this expression, the relation is part_of and
the target is oocyte.

=head2 Syntax

 REL(TARGET)

For example:

  part_of(CL:0001234)

=head2 OWL Translation

Same as a Class Restriction in OWL

=cut
