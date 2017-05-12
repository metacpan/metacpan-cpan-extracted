package GOBO::ClassExpression::Union;
use Moose;
use strict;
extends 'GOBO::ClassExpression::BooleanExpression';

sub operator { ' OR ' }
sub operator_symbol { '|' }

=head1 NAME

GOBO::ClassExpression::Union

=head1 SYNOPSIS

  $prok = GOBO::ClassExpression->parse_idexpr('bacteria|archaea');

=head1 DESCRIPTION

An GOBO::ClassExpression::BooleanExpression in which the set operator is one of union.

Example: the class "prokaryote" is the union of "bacteria" and "archaea".

The semantics of this are: (a) if x is an instance of bacteria or x is
an instance of archae, then x is an instance of prokaryote (b) if x is
an instance of prokaryote then it is either the case that x is an
instance of bacteria or x is an instance of archae

In OBO Format:

  [Term]
  id: prok
  union_of: bacteria
  union_of: archaea

Formally:

  forall x : prok(x) <-> bacteria(x) | archaea(x)

The union expression can also be written as:

  bacteria|archaea

In the above example the following all hold if $prok is the class with the above definition

  $prok->id eq 'prok';
  $prok->logical_definion->isa('GOBO::ClassExpression::Union');
  $prok->logical_definion->operator eq 'OR';
  scalar(@{$prok->logical_definion->arguments}) == 2;
  grep { $_->id eq 'bacteria' } @{$prok->logical_definion->arguments};
  grep { $_->id eq 'archaea' } @{$prok->logical_definion->arguments};

unions could also be used in defining GO slims  

=head2 OWL Translation

Same as unionOf description expressions in OWL

http://www.w3.org/TR/2008/WD-owl2-syntax-20081202/#Union_of_Class_Expressions


=cut

1; 
