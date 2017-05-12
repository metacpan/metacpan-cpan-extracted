=head1 NAME

GOBO::ClassExpression

=head1 SYNOPSIS

  my $xp = GOBO::ClassExpression->parse_idexpr('GO:0005737^part_of(CL:0000023)');

=head1 DESCRIPTION

A class expression is an GOBO::ClassNode whose members are identified
by a boolean or relational expression. For example, the class 'nuclei
of cardiac cells' is expressed as the intersection (an
GOBO::ClassExpression::Intersection) between the set 'nucleus' (an
GOBO::TermNode) and the set of all things that stand in the part_of
relation to 'class node' (a GOBO::ClassExpression::RelationalExpression).

Simple ontologies do not include class expressions. They can often be
ignored for many purposes.

An GOBO::TermNode can be formally and logically defined by stating
equivalence to a GOBO::ClassExpression

  [Term]
  id: GO:new
  name: oocyte cytoplasm
  intersection_of: GO:0005737 ! cytoplasm
  intersection_of: part_of CL:0000023 ! oocyte 

This can also be thought of as necessary and sufficient conditions for
membership of a class.

On parsing the above using GOBO::Parsers::OBOParer, the following should hold

  $t->label eq 'oocyte cytoplasm';
  $t->logical_definition->isa('GOBO::ClassExpression');

=head2 Example files

The xp version of SO includes intersection-based class expressions.
See http://sequenceontology.org

The extended version of GO will soon include these for regulation terms. See also

http://wiki.geneontology.org/index.php/Category:Cross_Products

=head2 Mapping to OWL

The notion of ClassExpression here is largely borrowed from OWL and
Description Logics. See

http://www.w3.org/TR/2008/WD-owl2-syntax-20081202/#Class_Expressions

Note that not everything in OWL is expressable in OBO format or the
GOBO model.

Conversely, this model and OBO format can express things not in OWL,
such as relation expressions involving intersection and union.

=head2 Mapping to the GO Database schema

Currently the GO database is not able to store the full range of class
expressions. It can only store logical definitions to
GOBO::ClassExpression::Intersection objects. See the POD docs for this
class for details.

=head2 Mapping to the Chado schema

Currently the GO database is not able to store the full range of class
expressions. It can only store logical definitions to
GOBO::ClassExpression::Intersection objects. See the POD docs for this
class for details.

=cut

package GOBO::ClassExpression;
use Moose;
use strict;
extends 'GOBO::ClassNode';
use GOBO::ClassExpression::RelationalExpression;
use GOBO::ClassExpression::Intersection;
use GOBO::ClassExpression::Union;

# abstract class - no accessors

# utility methods follow...

=head2 ID Expressions

A class expression can be expressed as an ID expression. See:

http://www.geneontology.org/GO.format.obo-1_3.shtml#S.1.6

For example:
  GO:0005737^part_of(CL:0000023) 

The set of all cytoplasm (GO:0005737) instances that are part_of some oocyte (CL:0000023)


=head3 parse_idexpr

Generates a GOBO::ClassExpression based on an ID expression string

  Usage - $xp = GOBO::ClassExpression->parse_idexpr('GO:0005737^part_of(CL:0000023)');

The grammar for ID expressions is:

  GOBO::ClassExpression = GOBO::BooleanExpression | GOBO::RelationalExpression | GOBO::TermNode
  GOBO::BooleanExpression = GOBO::Intersection | GOBO::Union
  GOBO::Intersection = GOBO::ClassExpression '^' GOBO::ClassExpression
  GOBO::Union = GOBO::ClassExpression '|' GOBO::ClassExpression
  GOBO::RelationalExpression = GOBO::RelationNode '(' GOBO::ClassExpression ')'


=cut

sub parse_idexpr {
    my $self = shift;
    my $g = shift;
    my $expr = shift;
    return unless $expr;
    #print STDERR "Parsing: $expr\n";
    my @toks = split(/([\(\)\^\|])/,$expr);
    @toks = grep {$_} @toks;
    my $x = _parse_idexpr_toks($g,\@toks);
    $x->normalize if $x->can('normalize');
    return $x;
}

sub _parse_idexpr_toks {
    my $g = shift;
    my $toks = shift;
    #printf STDERR "Parsing tokens: %s\n", join(',',@$toks);
    if (!@$toks) {
        return;
    }
    my $tok = shift @$toks;
    while (@$toks && !$tok) {
        # process null tokens
        $tok = shift @$toks;
    }
    #print STDERR "tok: $tok;; rest=@$toks\n";

    # RETURN: atom
    if (!@$toks) {
        #printf STDERR "atom: $tok\n";
        #return $tok;
        return $g->noderef($tok);
    }
    my $this;
    if ($toks->[0] eq '(') {
        # relational expression
        shift @$toks;
        #printf STDERR "parsing relational expr from @$toks\n";
        my $filler = _parse_idexpr_toks($g,$toks);
        $this = new GOBO::ClassExpression::RelationalExpression(relation=>$tok,target=>$filler);
        #printf STDERR "relexpr $tok $filler ==> $this ;; remaining = @$toks\n";
    }
    else {
        #printf STDERR "atom: $tok\n";
        $this = $g->noderef($tok);
    }

    if (@$toks) {
        my $combo;
        my $op = shift @$toks;
        #printf STDERR "op: '$op';; rest=@$toks\n";

        if ($op eq ')') {
            # TODO: check balance
            #printf STDERR "end-brace: $this\n";
            return $this;
        }

        my $next = _parse_idexpr_toks($g,$toks);
        if ($op eq '^') {
            #printf STDERR "intersection: $this $next\n";
            $combo = new GOBO::ClassExpression::Intersection(arguments=>[$this,$next]);
        }
        elsif ($op eq '|') {
            #printf STDERR "union: $this $next\n";
            $combo = new GOBO::ClassExpression::Union(arguments=>[$this,$next]);
        }
        else {
        }
        return $combo; # TODO -- DNF
    }
    #printf STDERR "return: $this\n";
    return $this;
}

=head2 normalize 

A or (B or C) ==> A or B or C
A and (B and C) ==> A and B and C


=cut

sub normalize {
    my $self = shift;
    return;
}

1;

