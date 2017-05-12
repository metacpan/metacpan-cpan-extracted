
#  Copyright (c) 1995, 1996, 1997 by Steffen Beyer. All rights reserved.
#  This package is free software; you can redistribute it and/or modify
#  it under the same terms as Perl itself.

package Graph::Kruskal;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
            $number_of_edges $number_of_vortices @V @E @T);

require Exporter;

@ISA = qw(Exporter);

@EXPORT = qw();

@EXPORT_OK = qw(define_vortices define_edges
                heapify makeheap heapsort
                find union kruskal example);

%EXPORT_TAGS = (all => [@EXPORT_OK]);

$VERSION = '2.0';

use Carp;

$number_of_vortices = 0;
$number_of_edges = 0;

sub example
{
    my($costs) = 0;
    my($k);

    print "\n";
    print "+++ Kruskal's Algorithm for Minimal Spanning Trees in Graphs +++";
    print "\n";

    &define_vortices(2,3,5,7,11,13,17,19,23,29,31);

    print "\nVortices:\n\n";

    for ( $k = 1; $k <= $#V; ++$k )
    {
        if (defined $V[$k]) { print "$k\n"; }
    }

    &define_edges( 2,13,3, 3,13,2, 5,13,1, 3,5,2, 3,29,21, 23,29,3,
     23,31,2, 5,31,15, 5,7,10, 2,11,2, 7,11,2, 7,19,5, 11,19,2,
     7,31,4, 3,17,3, 17,23,3, 7,17,3 );

    print "\nEdges:\n\n";

    for ( $k = 1; $k <= $#E; ++$k )
    {
        print ${$E[$k]}{'from'}, " <-> ", ${$E[$k]}{'to'}, " = ",
            ${$E[$k]}{'cost'}, "\n";
    }

    &kruskal();

    print "\nEdges in minimal spanning tree:\n\n";

    for ( $k = 1; $k <= $#T; ++$k )
    {
        print ${$T[$k]}{'from'}, " <-> ", ${$T[$k]}{'to'}, " = ",
            ${$T[$k]}{'cost'}, "\n";
        $costs += ${$T[$k]}{'cost'};
    }

    print "\nTotal costs: $costs\n\n";
}

sub define_vortices
{
    undef @V;
    $number_of_vortices = 0;
    foreach (@_)
    {
        ($_ > 0) || croak "Graph::Kruskal::define_vortices(): vortex number not positive\n";
        $V[$_] = -1;
        ++$number_of_vortices;
    }
}

sub define_edges
{
    my($from,$to,$cost);

    undef @E;
    $number_of_edges = 0;
    while (@_)
    {
        $from = shift || croak "Graph::Kruskal::define_edges(): missing 'from' vortex number\n";
        $to   = shift || croak "Graph::Kruskal::define_edges(): missing 'to' vortex number\n";
        $cost = shift || croak "Graph::Kruskal::define_edges(): missing edge 'cost' value\n";
        defined $V[$from] || croak "Graph::Kruskal::define_edges(): vortex '$from' not previously defined\n";
        defined $V[$to]   || croak "Graph::Kruskal::define_edges(): vortex '$to' not previously defined\n";
        ($from != $to)    || croak "Graph::Kruskal::define_edges(): vortices 'from' and 'to' are the same\n";
        $E[++$number_of_edges] =
            { 'from' => $from, 'to' => $to, 'cost' => $cost };
    }
}

sub heapify             # complexity: O(ld n)
{
    my($i,$n) = @_;
    my($i2,$i21,$j,$swap);

    while ($i < $n)
    {
        $j   = $i;
        $i2  = $i * 2;
        $i21 = $i2 + 1;
        if ($i2 <= $n)
        {
            if (${$E[$i]}{'cost'} > ${$E[$i2]}{'cost'})
            {
                $j = $i2;
                if ($i21 <= $n)
                {
                    if (${$E[$i2]}{'cost'} > ${$E[$i21]}{'cost'}) { $j = $i21; }
                }
            }
            else
            {
                if ($i21 <= $n)
                {
                    if (${$E[$i]}{'cost'} > ${$E[$i21]}{'cost'}) { $j = $i21; }
                }
            }
        }
        if ($i != $j)
        {
            $swap  = $E[$i];
            $E[$i] = $E[$j];
            $E[$j] = $swap;
            $i = $j;
        }
        else { $i = $n; }
    }
}

sub makeheap            # complexity: O(n ld n)
{
    my($n) = @_;
    my($k);

    for ( $k = $n - 1; $k > 0; --$k ) { &heapify($k, $n); }
}

# The following subroutine isn't used by this algorithm, it is only included
# here for the sake of completeness:

sub heapsort            # complexity: O(n ld n)
{
    my($n) = @_;
    my($k,$swap);

    for ( $k = $n - 1; $k > 0; --$k ) { &heapify($k, $n); }

    for ( $k = $n; $k > 1; --$k )
    {
        $swap  = $E[1];
        $E[1]  = $E[$k];
        $E[$k] = $swap;
        &heapify(1, $k - 1);
    }
}

sub find
{
    my($i) = @_;
    my($j,$k,$t);

    $j = $i;
    while ($V[$j] > 0) { $j = $V[$j]; } # find root element (= set identifier)
    $k = $i;
    while ($k != $j)                    # height compression of the tree
    {
        $t = $V[$k];
        $V[$k] = $j;
        $k = $t;
    }
    return($j);
}

sub union
{
    my($i,$j) = @_;
    my($x);

    $x = $V[$i] + $V[$j];    # calculate number of elements in resulting set
    if ($V[$i] > $V[$j])     # which of the two sets contains more elements?
    {
        $V[$i] = $j;         # merge them
        $V[$j] = $x;         # update number of elements
    }
    else
    {
        $V[$j] = $i;         # merge them
        $V[$i] = $x;         # update number of elements
    }
}

sub kruskal             # complexity: O(n ld n)   ( where n := |{ Edges }| )
{
    my($n) = $number_of_edges;
    my($v) = $number_of_vortices;
    my($i,$j,$swap);
    my($t) = 0;

    undef @T;
    &makeheap($number_of_edges);        # complexity: O(n ld n)
    while (($v > 1) && ($n > 0))
    {
        $swap  = $E[1];
        $E[1]  = $E[$n];
        $E[$n] = $swap;
        &heapify(1, $n - 1);            # complexity: n O(ld n) = O(n ld n)
        $i = find(${$E[$n]}{'from'});   # complexity: n ( 2 find + 1 union ) =
        $j = find(${$E[$n]}{'to'});     #             O( G(n) n ) <= O(n ld n)
        if ($i != $j)
        {
            union($i,$j);
            $T[++$t] = $E[$n];
            --$v;
        }
        --$n;
    }
    return(@T);
}

1;

__END__

=head1 NAME

Graph::Kruskal - Kruskal's Algorithm for Minimal Spanning Trees in Graphs

Computes the Minimal Spanning Tree of a given graph according to
some cost function defined on the edges of the graph.

=head1 SYNOPSIS

=over 4

=item *

C<use Graph::Kruskal qw(define_vortices define_edges>
C<heapify makeheap heapsort find union kruskal example);>

=item *

C<use Graph::Kruskal qw(:all);>

=item *

C<&define_vortices(2,3,5,7,11,13,17,19,23,29,31);>

Define a list of vortices (integers > 0)

=item *

C<&define_edges( 2,13,3, 3,13,2, 5,13,1, 3,5,2, 3,29,21 );>

Define (non-directed) edges on the vortices previously defined (always
in triplets: "from" vortice, "to" vortice and cost of that edge)

=item *

C<&heapify($i,$n);>

Main subroutine for sorting the edges according to their costs

=item *

C<&makeheap($n);>

Routine to initialize sorting of the edges

=item *

C<&heapsort($n);>

The famous heapsort algorithm (not needed for Kruskal's algorithm as a whole
but included here for the sake of completeness) for sorting the edges
according to their costs

=item *

C<&find($i);>

=item *

C<&union($i,$j);>

Disjoint (!) sets are stored as trees in an array in this algorithm. Each
element of some set (a cell in the array) contains a pointer to (the number
of) another element, up to the root element that does not point anywhere,
but contains the (negative) number of elements the set contains. The number
of the root element is also used as an identifier for the set.

Example:

            i  : |  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |
    -------------+-----+-----+-----+-----+-----+-----+-----+-----+
     parent[i] : | -4  | -3  |  1  |  2  |  1  | -1  |  3  |  4  |

This array contains the three sets S1, S2 and S6:

                    1           2           6
                   / \          |
                  3   5         4
                 /              |
                7               8

"find" returns the number of the root element (= the identifier of the set)
of the tree in which the given element is contained:

      find(a) := i  so that  a in Si

It also reduces the height of that tree by changing all the pointers from
the given element up to the root element to point DIRECTLY to the root
element.

Example:

    find(7) returns "1" and modifies the array as follows:

            i  : |  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |
    -------------+-----+-----+-----+-----+-----+-----+-----+-----+
     parent[i] : | -4  | -3  |  1  |  2  |  1  | -1  |  1  |  4  |

                    1           2           6
                   /|\          |
                  3 5 7         4
                                |
                                8

"union" takes the identifiers of two sets (= the numbers of their respective
root elements) and merges the two sets by appending one of the two trees to
the other. It always appends the SMALLER set to the LARGER one (to keep the
height of the resulting tree as small as possible) and updates the number of
elements contained in the resulting set which is stored in the root element's
cell of the array.

Example:

    union(2,6) does the following:

            i  : |  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |
    -------------+-----+-----+-----+-----+-----+-----+-----+-----+
     parent[i] : | -4  | -4  |  1  |  2  |  1  |  2  |  1  |  4  |

                    1           2
                   /|\         / \
                  3 5 7       4   6
                              |
                              8

    complexity for O(n) "find" operations: O( G(n) n )

    complexity for one "union" operation: O(1)

    complexity for O(n) ( "find" + "union" ) operations: O( G(n) n )

    where  G(n) := min{ j | F(j) >= n }

    and    F(j) := 1            for j = 0
           F(j) := 2 ^ F(j-1)   for j > 0

    also,  G(n) <= ld n         for all n

=item *

C<&kruskal();>

This routine carries out the computations associated with Kruskal's algorithm.

Returns an array of hashes (each hash containing the keys "from", "to" and
"cost" and the corresponding values) representing the minimal spanning tree
of the graph previously defined by calls to "define_vortices" and
"define_edges".

The result can also be found in @Graph::Kruskal::T.

See the implementation of the subroutine "example" to see how to access this
array directly (remember to fully qualify the name of this array in your
program, i.e., use "@Graph::Kruskal::T" instead of just "@T", since this array
is not exported - or your program will not work!)

=item *

C<&example();>

Demonstrates how to use the various subroutines in this module.

Computes the minimal spanning tree of a sample graph.

Just say "use Graph::Kruskal qw(example);" and "&example();" in a little
Perl script to see it "in action".

=back

=head1 DESCRIPTION

This algorithm computes the Minimal Spanning Tree of a given graph
according to some cost function defined on the edges of that graph.

Input: A set of vortices which constitute a graph (some cities on a map,
for example), a set of edges (i.e., roads) between the vortices of the
(non-directed and connected) graph (i.e., the edges can be traveled in
either direction, and a path must exist between any two vortices), and
the cost of each edge (for instance, the geographical distance).

Output: A set of edges forming a spanning tree (i.e., a set of edges linking
all vortices, so that a path exists between any two vortices) which is free
of circles (because it's a tree) and which is minimal in terms of the cost
function defined on the set of edges.

See Aho, Hopcroft, Ullman, "The Design and Analysis of Computer Algorithms"
for more details on the algorithm.

=head1 SEE ALSO

Math::MatrixBool(3), Math::MatrixReal(3), DFA::Kleene(3),
Set::IntegerRange(3), Set::IntegerFast(3), Bit::Vector(3).

=head1 VERSION

This man page documents "Graph::Kruskal" version 2.0.

=head1 AUTHOR

Steffen Beyer <sb@sdm.de>.

=head1 COPYRIGHT

Copyright (c) 1995, 1996, 1997 by Steffen Beyer. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

