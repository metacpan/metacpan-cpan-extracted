package GOBO::InferenceEngine;
use Moose;
use strict;
use GOBO::Statement;
use GOBO::Annotation;
use GOBO::Graph;
use GOBO::Node;
use GOBO::TermNode;
use GOBO::RelationNode;

has graph => (is=>'rw', isa=> 'GOBO::Graph');
has inferred_graph => (is=>'rw', isa=> 'GOBO::Graph', default=>sub{new GOBO::Graph});

sub backward_chain {
    my $self = shift;
    my $n = shift;
    my $g = $self->graph;
    my $ig = $self->inferred_graph;
    
    # initialize link set based on input node;
    # we will iteratively extend upwards
    my @links = @{$g->get_target_links($n)};
    my %outlink_h = ();
    my %link_closure_h = ();
    while (@links) {
       my $link = shift @links;
       next if $outlink_h{$link};
       $outlink_h{$link} = 1;
       my $r = $link->relation;
       my $t = $link->target;
       #my @extlinks = @{$g->linkset->about($t)};
       my $extlinks = $self->extend_link($link);
       if (@$extlinks) {
           push(@links,@$extlinks);
           #push(@outlinks,@$extlinks);
           map {$link_closure_h{$_}=1} @$extlinks;
       }
    }
    return [keys %outlink_h];
}

=head2 get_inferred_target_links (subject GOBO::Node, relation GOBO::RelationNode OPTIONAL)

given a subject (child), get inferred target (parent) links

if relation is specified, also filters results on relation

backward-chaining

=cut

sub get_inferred_target_links {
    my $self = shift;
    my $n = shift;
    my $g = $self->graph;
    my $ig = $self->inferred_graph;
    my $tlinks = $ig->get_target_links($n);
    if (@$tlinks) {
        # cached
        return $tlinks;
    }
    
    # initialize link set based on input node;
    # we will iteratively extend upwards
    my @links = @{$g->get_target_links($n)};
    #printf STDERR "target $n => @links\n";

    my %outlink_h = ();
    #my %link_closure_h = ();
    while (@links) {
       my $link = shift @links;
       next if $outlink_h{$link};
       $outlink_h{$link} = $link;
       my $r = $link->relation;
       my $t = $link->target;
       my $extlinks = $self->extend_link($link);

       foreach my $srel (@{$self->get_subrelation_closure($link->relation)}) {
           my $newlink = new GOBO::LinkStatement(node=>$link->node,
                                                 relation=>$srel,
                                                 target=>$link->target);
           push(@links,$newlink);
       }
       
       if (@$extlinks) {
           push(@links,@$extlinks);
           #push(@outlinks,@$extlinks);
           #map {$link_closure_h{$_}=1} @$extlinks;
       }
    }
    $ig->add_links([values %outlink_h]);
    return [values %outlink_h];
}

=head2 get_inferred_target_nodes (subject GOBO::Node, relation GOBO::RelationNode OPTIONAL)

given a subject (child), get inferred target (parent) nodes

if relation is specified, also filters results on relation

backward-chaining

=cut

sub get_inferred_target_nodes {
    my $self = shift;
    my %tn = ();
    foreach my $link (@{ $self->get_inferred_target_links(@_) }) {
        $tn{$link->target->id} = $link->target;
    }
    return [values %tn];
}

sub get_subrelation_reflexive_closure {
    my $self = shift;
    my $rel = shift;
    return [$rel,@{$self->get_inferred_target_nodes($rel,'is_a')}];
}

sub get_subrelation_closure {
    my $self = shift;
    my $rel = shift;
    return $self->get_inferred_target_nodes($rel,'is_a');
}

sub extend_link {
    my $self = shift;
    my $link = shift;
    my @newlinks = ();
    foreach my $rel_1 (@{$self->get_subrelation_reflexive_closure($link->relation)} ) {
        foreach my $xlink (@{$self->graph->get_target_links($link->target)}) {
            #printf STDERR "  XLINK: $xlink\n";
            my $rel_2 = $xlink->relation;
            my @rels = $self->relation_composition($rel_1, $rel_2);
            
            # R1 subrelation_of R2, x R1 y => x R2 y
            @rels = map { @{$self->get_subrelation_reflexive_closure($_)} } @rels;
            foreach my $rel (@rels) {
                my $newlink = new GOBO::LinkStatement(node=>$link->node,
                                                      relation=>$rel,
                                                      target=>$xlink->target);
                # todo - provenance/evidence of link
                push(@newlinks, $newlink);
            }
        }
    }
    return \@newlinks;
}

=head2 get_nonredundant_set (nodes ArrayRef[GOBO::Node], OPTIONAL set2 ArrayRef[GOBO::Node])

TODO: allow specification of relations

returns all nodes n in set1 such that there is no n' in (set1 U set2)
such that no relationship nRn' can be inferred

=cut

sub get_nonredundant_set {
    my $self = shift;
    my $nodes = shift;
    my $set2 = shift || [];
    #print STDERR "Finding NR set for @$nodes\n";
    my %nh = map { ($_ => $_) } @$nodes;
    foreach my $node (@$nodes) {
        my $targets = $self->get_inferred_target_nodes($node);
        foreach (@$targets) {
            delete $nh{$_->id};
        }
    }
    foreach my $node (@$set2) {
        my $targets = $self->get_inferred_target_nodes($node);
        delete $nh{$node};
        foreach (@$targets) {
            delete $nh{$_->id};
        }
    }
    # TODO
    return [values %nh];
}

=head2 relation_composition

 Arguments: GOBO::RelationNode r1 GOBO::RelationNode r2
 Returns: ArrayRef[GOBO::RelationNode]

Given two relations r1 and r2, returns the list of relations that hold
true between x and z where x r1 y and y r2 z holds

Formal definition:

  (R1 o R2 -> R3) implies ( x R1 y, y R2 z -> x R3 z)

Examples:

  part_of o part_of -> part_of (if part_of is declared transitive)
  regulates o part_of -> regulates (if regulates is declared transitive_over part_of)

See also:

http://geneontology.org/GO.ontology-ext.relations.shtml

http://wiki.geneontology.org/index.php/Relation_composition

=cut

sub relation_composition {
    my $self = shift;
    my $r1 = shift;
    my $r2 = shift;
    if ($r1->equals($r2) && $r1->transitive) {
        return ($r1);
    }
    if ($r1->is_subsumption && $r2->propagates_over_is_a) {
        return ($r2);
    }
    if ($r2->is_subsumption && $r1->propagates_over_is_a) {
        return ($r1);
    }
    if ($r1->transitive_over && $r1->transitive_over->equals($r2)) {
        return ($r1);
    }
    # TODO: arbitrary chains
    return ();
}

sub forward_chain {
    my $self = shift;
    my $g = $self->graph;
    my $ig = new GOBO::Graph;
    $ig->copy_from($g);
    $self->inferred_graph($ig);
    $self->calculate_deductive_closure;
    
}

sub calculate_deductive_closure {
    my $self = shift;
    my $g = $self->graph;
    my $ig = $self->inferred_graph;
    
    my $saturated = 0;
    while (!$saturated) {
        
    }
}

=head2 subsumed_by

c1 subsumed_by c2 if any only if every member of c1 is a member of c2

The following rules are used in the decision procedure:

=head3 Relation Composition

=head3 Intersections

See GOBO::ClassExpression::Intersection

if c2 = a ∩ b AND c1 is subsumed by a AND c1 is subsumed by b THEN c1 is subsumed by c2

=head3 Unions

See GOBO::ClassExpression::Union

if c2 = a ∪ b AND (c1 is subsumed by a OR c1 is subsumed by b) THEN c1 is subsumed by c2

=head3 Relational Expressions

See GOBO::ClassExpression::RelationalExpression

if c2 = <r y> AND c1 r y THEN c1 is subsumed by c2

=cut

sub subsumed_by {
    my $self = shift;
    my $child = shift;  # GOBO::Class
    my $parent = shift; # GOBO::Class

    my $subsumes = 0;

    # reflexivity of subsumption relation
    if ($child->equals($parent)) {
        return 1;
    }

    if ($parent->isa('GOBO::TermNode')) {
        # TODO: equiv test for roles?
        if ( $parent->logical_definition) {
            return $self->subsumed_by($child,$parent->logical_definition);
        }
        if ( $parent->union_definition) {
            return $self->subsumed_by($child,$parent->union_definition);
        }

    }
    if (grep {$_->id eq $parent->id} @{$self->get_inferred_target_nodes($child, new GOBO::RelationNode(id=>'is_a'))}) {
        return 1;
    }

    # class subsumption over boolean expressions
    if ($parent->isa('GOBO::ClassExpression')) {
        if ($parent->isa('GOBO::ClassExpression::RelationalExpression')) {
            if (grep {$_->id eq $parent->target} @{$self->get_inferred_target_links($child, $parent->relation)}) {
                return 1;
            }
        }
        elsif ($parent->isa('GOBO::ClassExpression::BooleanExpression')) {
            my $args = $parent->arguments;
            if ($parent->isa('GOBO::ClassExpression::Intersection')) {
                $subsumes = 1;
                foreach my $arg (@$args) {
                    if (!$self->subsumed_by($child, $arg)) {
                        $subsumes = 0;
                        last;
                    }
                }
            }
            elsif ($parent->isa('GOBO::ClassExpression::Union')) {
                foreach my $arg (@$args) {
                    if ($self->subsumed_by($child, $arg)) {
                        $subsumes = 1;
                        last;
                    }
                }
            }
            else {
                $self->throw("cannot infer with $parent");
            }
        }
        else {
            
        }
    }
    return $subsumes;
}

# TODO
#sub disjoint_from_violations {
#    my $self = shift;
#    
#}

=head1 NAME

GOBO::InferenceEngine

=head1 SYNOPSIS

NOT FULLY IMPLEMENTED

=head1 DESCRIPTION

An GOBO::Graph is a collection of GOBO::Statements. These statements can
be either 'asserted' or 'inferred'. Inferred statements are created by
an Inference Engine. An InferenceEngine object provides two accessors,
'graph' for the source graph and 'inferred_graph' for the set of
statements derived from the source graph after applying rules that
take into account properties of the relations in the statements.

The notion of transitive closure in a graph can be expressed in terms
of the deductive closure of a graph of links in which each
GOBO::RelationNode has the property 'transitive'. The notion of
ancestry in a graph can be thought of as the inferred links where the
relations are transitive.

=head2 Rules

Rules are horn rules with sets of statements in the antecedent and
typically a single statement in the consequent.

In the notation below, subject and target nodes are indicated with
lower case variables (x, y, z, ...) and relations (GOBO::RelationNode)
are indicated with upper case (R, R1, R2, ...). Each statement is
written in this order:

  $s->node $->relation $s->target

=head3 Transitivity

  x R y, y R z => x R z (where $R->transitive)

=head3 Propagation over and under is_a

  x R y, y is_a z => x R z (where $R->propagates_over_is_a)
  x is_a y, y R z => x R z (where $R->propagates_over_is_a)

=head3 Link composition

  x R1 y, y R2 z => x R z (where R=R1.R2)

The above two rules are degenerate cases of this one.

The notion R = R1.R2 is used to specify these compositions. See $r->holds_over_chain_list

=head3 Reflexivity

 x ? ? => x R x (where $R->reflexive)

ie where x exists, x stands in relation R to itself

=head3 Symmetry

 x R y => y R x (where $R->symmetric)

Note that the type level adjacenct_to relation is not transitive

=head3 Inverses

 x R1 y => y R2 x (where $R1->inverse_of_list contains $R2 or vice versa)

Note that the type level part_of relation is not the inverse of has_part

=head3 Inference over GOBO::ClassExpressions

class expressions define sets of entities. We can infer the existing
of subset/subsumption relationships between these sets.

TODO

=head2 Inference strategies

=head3 Backward chaining

Starting for a given node, find all inferred Statements related to
that node by applying rules. Ancestors statements: all statements in
which this node plays the role of subject. Descendants statements: all
statements in which this node plays the role of target.

Can be combined with memoization, in which case subsequent queries can
retrieve cached results.

=head3 Forward chaining

Starting with a graph of asserted statements, iteratively keep
applying rules and adding resulting statements to the inferred graph,
until no new statements are added.

=head1 STATUS

PRE-ALPHA!!!

=cut

1;
