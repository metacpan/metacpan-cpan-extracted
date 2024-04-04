package Graph::Grammar;

# ABSTRACT: Grammar for graphs
our $VERSION = '0.1.1'; # VERSION

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

C<$vertex_condition> is a subroutine reference evaluating the center node.
The subroutine is called with the graph in C<$_[0]> and the vertex in <$_[1]>.
Subroutine should evaluate to true if condition is fulfilled.

C<@neighbour_conditions> is an array of subroutine references for the neighbours of the center node.
Inputs and outputs of each subroutine reference are the same as defined for C<$vertex_condition>.
Every condition has to match at least one of the neighbours (without overlaps).
Thus the rule will automatically fail if the number of neighbours is less than C<@neighbour_conditions>.
There can be more neighbours than C<@neighbour_conditions>, but if strict number of neighbours is needed, look below for C<NO_MORE_VERTICES>.
C<@neighbour_conditions> can be empty.

C<$action> can be either a subroutine reference, or anything else.
If C<$action> is a subroutine reference, then in the case of a match it is called with the graph in C<$_[0]> and remaining C<@_> members being graph vertices corresponding to rule conditions.
That is, C<$_[1]> is the center node, C<$_[2]> is a vertice matching the first neighbour condition and so on.
If C<$action> is not a subroutine reference, then it is cloned by L<Clone> and inserted instead of the center vertex.

There are two ways to request a particular number of neighbours for the central vertex.
First of them is to include an appropriate requirement into C<$vertex_condition>.
Second is to put C<NO_MORE_VERTICES> as the last element of C<@neighbour_conditions>, i.e.:

    [ sub { 1 }, ( sub { 1 } ) x 2, NO_MORE_VERTICES, sub { [ @_[1..3] ] } ]

=cut

use strict;
use warnings;

use parent Exporter::;
our @EXPORT = qw( NO_MORE_VERTICES parse_graph );

use Clone qw( clone );
use Graph::Grammar::Rule::NoMoreVertices;
use Graph::MoreUtils qw( graph_replace );
use List::Util qw( first );
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
            my $self_rule = shift @rule;
            my $action = pop @rule;

            VERTEX:
            for my $vertex ($graph->vertices) {
                next unless $self_rule->( $graph, $vertex );

                my @matching_neighbours;
                my $matching_neighbours = set();
                for my $i (0..$#rule) {
                    my $neighbour_rule = $rule[$i];
                    
                    if( ref $neighbour_rule eq 'CODE' ) {
                        my $match = first { !$matching_neighbours->has( $_ ) &&
                                            $neighbour_rule->( $graph, $_ ) }
                                          $graph->neighbours( $vertex );
                        next VERTEX unless $match;
                        push @matching_neighbours, $match;
                        $matching_neighbours->insert( $match );
                    } else { # FIXME: Check for Graph::Grammar::NoMoreVertices
                        next VERTEX unless $graph->degree( $vertex ) == @matching_neighbours;
                    }
                }

                print STDERR "apply rule $i\n" if $DEBUG;

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

=head2 C<NO_MORE_VERTICES>

When used before the rule action in a rule, restricts the number of center vertex neighbours to vertex conditions.

=cut

sub NO_MORE_VERTICES { return Graph::Grammar::Rule::NoMoreVertices->new }

=head1 AUTHORS

Andrius Merkys, E<lt>merkys@cpan.orgE<gt>

=cut

1;
