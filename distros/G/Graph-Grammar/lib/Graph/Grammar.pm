package Graph::Grammar;

# ABSTRACT: Grammar for graphs
our $VERSION = '0.2.0'; # VERSION

=head1 NAME

Graph::Grammar - Graph grammar, i.e. rewriting method

=head1 SYNOPSIS

    use Graph::Grammar;
    use Graph::Undirected;

    my $graph = Graph::Undirected->new;

    # Create graph here

    my @rules = (
        [ sub { 1 }, ( sub { 1 } ) x 2, NO_MORE_VERTICES, sub { [ @_[1..3] ] } ],
    );

    parse_graph( $graph, @rules );

=head1 DESCRIPTION

Graph::Grammar is a Perl implementation of a graph rewriting method (a.k.a. graph grammar).
Much of the API draws inspiration from L<Parse::Yapp>, but instead of acting on text streams Graph::Grammar is oriented at graphs, as implemented in Perl's L<Graph> module.
Graph::Grammar implements a single method C<parse_graph()> which accepts an instance of L<Graph> and an array of rules.
Every rule is evaluated for each vertex in a graph and, if a match is found, an action associated with the rule is executed.
A rule generally looks like this:

    [ $vertex_condition, @neighbour_conditions, $action ]

Where:

C<$vertex_condition> is a subroutine reference evaluating the center vertex.
The subroutine is called with the graph in C<$_[0]> and the vertex in <$_[1]>.
Subroutine should evaluate to true if condition is fulfilled.

C<@neighbour_conditions> is an array of subroutine references for the neighbours of the center vertex.
Inputs and outputs of each subroutine reference are the same as defined for C<$vertex_condition>.
Every condition has to match at least one of the neighbours (without overlaps).
Thus the rule will automatically fail if the number of neighbours is less than C<@neighbour_conditions>.
There can be more neighbours than C<@neighbour_conditions>, but if strict number of neighbours is needed, look below for C<NO_MORE_VERTICES>.
C<@neighbour_conditions> can be empty.

C<$action> can be either a subroutine reference, or anything else.
If C<$action> is a subroutine reference, then in the case of a match it is called with the graph in C<$_[0]> and remaining C<@_> members being graph vertices corresponding to rule conditions.
That is, C<$_[1]> is the center vertex, C<$_[2]> is a vertex matching the first neighbour condition and so on.
If C<$action> is not a subroutine reference, then it is cloned by L<Clone> and inserted instead of the center vertex.

There are two ways to request a particular number of neighbours for the central vertex.
First of them is to include an appropriate requirement into C<$vertex_condition>.
Second is to put C<NO_MORE_VERTICES> as the last element of C<@neighbour_conditions>, i.e.:

    [ sub { 1 }, ( sub { 1 } ) x 2, NO_MORE_VERTICES, sub { [ @_[1..3] ] } ]

Edge conditions are also supported and they always act on the center vertex and its neighbours matching their individual conditions, i.e.:

    [ $vertex_condition,
        EDGE { $edge_condition1->( @_ ) }, $vertex_condition1,
        EDGE { $edge_condition2->( @_ ) }, $vertex_condition2,
        # ...
        $action ]

=cut

use strict;
use warnings;

use parent Exporter::;
our @EXPORT = qw( EDGE NO_MORE_VERTICES parse_graph );

use Clone qw( clone );
use Graph::Grammar::Rule::Edge;
use Graph::Grammar::Rule::NoMoreVertices;
use Graph::MoreUtils qw( graph_replace );
use List::Util qw( first );
use Scalar::Util qw( blessed );
use Set::Object qw( set );

our $DEBUG = 0;

=head1 METHODS

=head2 C<parse_graph( $graph, @rules )>

Perform graph rewriting of C<$graph>.
Modifies the supplied graph and returns it upon completion.

=cut

sub parse_graph
{
    my( $graph, @rules ) = @_;

    my $changes = 1;

    MAIN:
    while( $changes ) {
        $changes = 0;

        for my $i (0..$#rules) {
            my $rule = $rules[$i];
            my @rule = @$rule;
            my $rule_name;
            my $self_rule = shift @rule;

            # First element in the rule could be a rule name
            if( !ref $self_rule ) {
                $rule_name = $self_rule;
                $self_rule = shift @rule;
            }

            my $action = pop @rule;
            my $no_more_vertices;
            if( @rule && blessed $rule[-1] && $rule[-1]->isa( Graph::Grammar::Rule::NoMoreVertices:: ) ) {
                $no_more_vertices = 1;
                pop @rule;
            }

            my $neighbours = grep { ref $_ eq 'CODE' } @rule;

            my $affected_vertices = set();

            VERTEX:
            for my $vertex ($graph->vertices) {
                next unless $self_rule->( $graph, $vertex );
                next unless defined $graph->degree( $vertex );
                next if $graph->degree( $vertex ) < $neighbours;
                next if $no_more_vertices && $graph->degree( $vertex ) > $neighbours;

                my @matching_neighbours;
                my $matching_neighbours = set();
                for my $i (0..$#rule) {
                    my $neighbour_rule = $rule[$i];
                    next if blessed $neighbour_rule && $neighbour_rule->isa( Graph::Grammar::Rule::Edge:: ); # Edge rules are evaluated separately

                    my $match;
                    if( $i && blessed $rule[$i-1] && $rule[$i-1]->isa( Graph::Grammar::Rule::Edge:: ) ) {
                        # With edge condition
                        $match = first { !$matching_neighbours->has( $_ ) &&
                                         $neighbour_rule->( $graph, $_ ) &&
                                         $rule[$i-1]->matches( $graph, $vertex, $_ ) }
                                       $graph->neighbours( $vertex );
                    } else {
                        # Without edge condition
                        $match = first { !$matching_neighbours->has( $_ ) &&
                                         $neighbour_rule->( $graph, $_ ) }
                                       $graph->neighbours( $vertex );
                    }
                    next VERTEX unless $match;

                    push @matching_neighbours, $match;
                    $matching_neighbours->insert( $match );
                }

                if( $DEBUG ) {
                    print STDERR defined $rule_name ? "apply rule $i: $rule_name\n" : "apply rule $i\n";
                }

                my $overlaps = ($affected_vertices * $matching_neighbours)->size +
                                $affected_vertices->has( $vertex );
                if( $DEBUG && $overlaps ) {
                    print STDERR "$overlaps overlapping vertices\n";
                }
                $affected_vertices->insert( $vertex, @matching_neighbours );

                if( ref $action eq 'CODE' ) {
                    $action->( $graph, $vertex, @matching_neighbours );
                } else {
                    graph_replace( $graph, clone( $action ), $vertex );
                }
                $changes++;
            }
        }
    }

    return $graph;
}

=head2 C<EDGE>

When used before a neighbour condition, places a condition on edge connecting the center vertex with a neighbour matched by the following rule.
Accepts a block or sub {}, i.e.:

    EDGE { $_[0]->get_edge_attribute( $_[1], $_[2], 'color' ) eq 'red' }

Subroutine is evaluated with three parameters: graph, center vertex and its neighbour matching the following neighbour condition.
Subroutine should evaluate to true if condition is fulfilled.

=cut

sub EDGE(&) { Graph::Grammar::Rule::Edge->new( $_[0] ) }

=head2 C<NO_MORE_VERTICES>

When used before the rule action in a rule, restricts the number of center vertex neighbours to vertex conditions.

=cut

sub NO_MORE_VERTICES { Graph::Grammar::Rule::NoMoreVertices->new }

=head1 AUTHORS

Andrius Merkys, E<lt>merkys@cpan.orgE<gt>

=cut

1;
