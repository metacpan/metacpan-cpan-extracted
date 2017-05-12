package GOBO::ClassExpression::Intersection;
use Moose;
use strict;
extends 'GOBO::ClassExpression::BooleanExpression';

sub operator { ' AND ' }
sub operator_symbol { '^' }

=head1 NAME

GOBO::ClassExpression::Intersection

=head1 SYNOPSIS

=head1 DESCRIPTION

A GOBO::ClassExpression::BooleanExpression in which the set operator is one of intersection.

An Intersection that consists of arguments a1, ..., aN means the set
{x : x instance_of(a1), .... x instance_of(aN)}

It is conventional in GO and many OBO ontologies for class
intersections to follow the genus-differentia pattern. In this case,
exactly one of the arguments is an GOBO::TermNode (the genus), and all
the other arguments are of type
GOBO::ClassExpression::RelationalExpression

For example, after parsing the following OBO stanza into variable $class:

  [Term]
  id: GO:0043005 ! neuron projection
  intersection_of: GO:0042995 ! cell projection
  intersection_of: part_of CL:0000540 ! neuron

The following boolean expressions are all true

  $class->id eq 'GO:0043005';
  $class->logical_definion->isa('GOBO::ClassExpression::Intersection');
  $class->logical_definion->operator eq 'AND';
  scalar(@{$class->logical_definion->arguments}) == 2;
  grep { $_->id eq 'GO:0042995' } @{$class->logical_definion->arguments};
  grep { $_->isa('GOBO::ClassExpression::RelationalExpression') &&
             $_->relation->id eq 'part_of' &&
             $_->target->id eq 'CL:0000540'
             } @{$class->logical_definion->arguments};

The "" operator is overloaded, so the logical defition is written out as

  GO:0042995^part_of(CL:0000540)

=head2 OWL Translation

Same as intersectionOf description expressions in OWL

See:
http://www.w3.org/TR/2008/WD-owl2-syntax-20081202/#Intersection_of_Class_Expressions

=head2 Mapping to the GO Database schema

Any link in the GO database that has the 'completes' tag set to 1 is an intersection link

http://www.geneontology.org/GO.database.schema.shtml#go-graph.table.term2term

For example, the following term:

  [Term]
  id: GO:0043005 ! neuron projection
  intersection_of: GO:0042995 ! cell projection
  intersection_of: part_of CL:0000540 ! neuron

is stored as 2 links:

    term2=GO:0043005 term1=GO:0042995 relationship_type=is_a completes=1
    term2=GO:0043005 term1=CL:0000540 relationship_type=part_of completes=1

Historical note on the terminology: 'completes' comes from early
versions of OWL, in which sets of conditions were marked 'complete' if
they formed a set of necessary and sufficient conditions. The oboedit
model also uses the tag 'completes'

=head2 Mapping to the Chado schema

The current proposed mapping is rather complex as it is based on how
OWL class expressions are layered on a simple RDF graph model. This
results in a lot of anonymous classes (bNodes in RDF terminology).

A better solution would be to follow the GODB model and introduce
either a boolean field for intersection links. Or this could be
generalized, as it is done in the OBD schema

=head2 Mapping to the OBD schema

This generalizes the GODB schema to allow for other kinds of boolean operators

The combinator flag is used and set to 'I' if the link is an
intersection link

=cut

1; 
