package Graph::Matching;

require 5.006;

use warnings;
use strict;
use Carp::Assert;
use Exporter qw(import);

our $VERSION = 0.02;
our @EXPORT_OK = qw(max_weight_matching edges_from_Graph);

=head1 NAME

Graph::Matching - Maximum Matching in Graphs

=head1 SYNOPSIS

Computes maximum matchings in general weighted graphs.

A matching is a subset of edges in which no node occurs more than once.
The cardinality of a matching is the number of matched edges.
The weight of a matching is the sum of the weights of its edges.

Example:

    use Graph::Matching qw(max_weight_matching);
    my $graph = [ [ 1, 2, 14 ], [ 2, 3, 18 ] ];
    my %matching = max_weight_matching($graph);

=head1 FUNCTION

=head2 %m = max_weight_matching($graph [, $maxcardinality ])

Compute a maximum-weighted matching in the undirected, weighted graph $graph.
If $maxcardinality is true, compute the maximum-cardinality matching
with maximum weight among all maximum-cardinality matchings.

The graph $graph should be a reference to an array of edges.  An edge
is described by an arrayref S<[ $v, $w, $weight ]>, containing the two nodes
and the weight of the edge.  Edges are undirected (usable in both directions).
A pair of nodes may have at most one edge between them.

The matching is returned as a hash %m, such that $m{$v} == $w if node $v
is matched to node $w.  Unmatched nodes will not occur as keys of %m.

This function takes time O(number_of_nodes ** 3).

If all edge weights are integers, the algorithm uses only integer
computations.  If floating point weights are used, the algorithm could
return a slightly suboptimal matching due to numeric precision errors.

=head2 $graph = edges_from_Graph($g)

Extract a reference to an array of edges, suitable for passing to the
max_weight_matching function, from an instance $g of the CPAN Graph module.

=head1 NOTES

The algorithm is taken from "Efficient Algorithms for Finding Maximum
Matching in Graphs" by Zvi Galil, ACM Computing Surveys, 1986.
It is based on the "blossom" method for finding augmenting paths and
the "primal-dual" method for finding a matching of maximum weight, both
methods invented by Jack Edmonds.  Some ideas were taken from "Implementation
of algorithms for maximum matching on non-bipartite graphs" by H.J. Gabow,
Stanford Ph.D. thesis, 1973.

=cut


# Verify optimized delta2/delta3 computation after every substage;
# only works on integer weights; slows down algorithm.
our $CHECK_DELTA = 0;

# Check optimality of solution before returning; only works on integer weights.
our $CHECK_OPTIMUM = 1;

# Print lots of debugging messages.
our $DBG = 0;
sub DBG { print STDERR "DEBUG: ", @_, "\n"; }


sub max_weight_matching($;$) {
    my ($graph, $maxcardinality) = @_;

    $maxcardinality = defined($maxcardinality) && $maxcardinality;

    #
    # Vertices are numbered 0 .. ($nvertex-1).
    # Non-trivial blossoms are numbered nvertex .. (2*$nvertex-1)
    #
    # Edges are numbered 0 .. ($nedge-1).
    # Edge endpoints are numbered 0 .. (2*$nedge-1), such that endpoints
    # (2*k) and (2*k+1) both belong to the edge with index k.
    #
    # Many terms used in the comments come from the paper by Galil.
    # You will probably need the paper to make sense of this code.
    #

    # Don't bother with empty graphs.
    my $nedge = scalar(@{$graph});
    return ( ) if (!$nedge);

    # Count vertices; map vertices to integers; find maximum edge weight;
    my @nodelist;
    my %nodemap;
    my $maxweight = 0;
    my $all_integer_weights = 1;
    foreach (@{$graph}) {
        my ($v, $w, $wt) = @{$_};
        foreach ($v, $w) {
            if (!defined($nodemap{$_})) {
                push @nodelist, $_;
                $nodemap{$_} = $#nodelist;
            }
        }
        $maxweight = $wt if ($wt > $maxweight);
        $all_integer_weights = $all_integer_weights && ($wt == int($wt));
    }
    my $nvertex = $#nodelist + 1;

    # If $p is an endpoint index,
    # $endpoint[$p] is the vertex index to which endpoint $p is attached.
    my @endpoint;
    $#endpoint = 2*$nedge-1;
    for (my $k = $nedge - 1; $k >= 0; $k--) {
        $endpoint[2*$k]   = $nodemap{$graph->[$k]->[0]};
        $endpoint[2*$k+1] = $nodemap{$graph->[$k]->[1]};
    }

    # If $v is a vertex index,
    # $neighbend[$v] refers to an array of remote endpoints attached to $v.
    my @neighbend;
    $#neighbend = $nvertex-1;
    for (my $k = $nedge - 1; $k >= 0; $k--) {
        my $v = $endpoint[2*$k];
        my $w = $endpoint[2*$k+1];
        assert($v != $w);
        push @{$neighbend[$v]}, 2*$k + 1;
        push @{$neighbend[$w]}, 2*$k;
    }

    # If $v is a vertex index,
    # $mate[$v] is the remote endpoint of its matched edge, or -1 if $v
    # is single. (i.e. $endpoint[$mate[$v]] is $v's partner vertex)
    # Initially all vertices are single.
    my @mate = ( -1 ) x $nvertex;

    # If $b is a top-level blossom,
    # $label[$b] is 0 if $b is unlabeled (free);
    #               1 if $b is an S-vertex/blossom;
    #               2 if $b is a T-vertex/blossom.
    # The label of a vertex is found by looking at the label of its top-level
    # containing blossom.
    # If $v is a vertex inside a T-blossom,
    # $label[$v] is 2 iff $v is reachable from an S-vertex outside the blossom.
    # Labels are assigned during a stage and reset after each augmentation.
    my @label = ( 0 ) x (2*$nvertex);

    # If $b is a labeled top-level blossom,
    # $labelend[$b] is the remote endpoint of the edge through which b obtained
    # its label, or -1 if $b's base vertex is single.
    # If $v is a vertex inside a T-blossom and $label[$v] == 2,
    # $labelend[$v] is the remote endpoint of the edge through which $v is
    # reachable from outside the blossom.
    my @labelend = ( undef ) x (2*$nvertex);

    # If $v is a vertex,
    # $inblossom[$v] is the top-level blossom to which $v belongs.
    # If $v is a top-level vertex, $v is itself a blossom (a trivial blossom)
    # and $inblossom[$v] == $v.
    # Initially all vertices are top-level trivial blossoms.
    my @inblossom = (0 .. ($nvertex-1));

    # If $b is a sub-blossom,
    # $blossomparent[$b] is its immediate parent (sub-)blossom.
    # If $b is a top-level blossom, $blossomparent[$b] is -1.
    my @blossomparent = ( ( -1 ) x $nvertex, ( undef ) x $nvertex );

    # If $b is a non-trivial (sub-)blossom,
    # $blossomchilds[$b] refers to an ordered array of its sub-blossoms,
    # starting with the base and going round the blossom.
    my @blossomchilds = ( undef ) x (2*$nvertex);

    # If $b is a (sub-)blossom,
    # $blossombase[$b] is its base VERTEX (i.e. recursive sub-blossom).\
    my @blossombase = ( 0 .. ($nvertex-1), ( undef ) x $nvertex );

    # If $b is a non-trivial (sub-)blossom,
    # $blossomendps[$b] refers to an array of endpoints on its connecting
    # edges, such that $blossomendps[$b]->[$i] is the local endpoint of
    # $blossomchilds[$b]->[$i] on the edge that connects it to
    # $blossomchilds[$b]->[wrap($i+1)].
    my @blossomendps = ( undef ) x (2*$nvertex);

    # If $v is a free vertex (or an unreached vertex inside a T-blossom),
    # $bestedge[$v] is the remote endpoint on a least-slack edge to an S-vertex
    # or -1 if there is no such edge.
    # If $b is a (possibly trivial) top-level S-blossom,
    # $bestedge[$b] is the remote endpoint on a least-slack edge to a
    # different S-blossom, or -1 if there is no such edge.
    # This is used for efficient computation of delta2 and delta3.
    my @bestedge = ( -1 ) x (2*$nvertex);

    # If $b is a non-trivial top-level S-blossom,
    # $blossombestedges[$b] refers to an array of remote endpoints on
    # least-slack edges to neighbouring S-blossoms, or is undef() if no
    # such list has been computed yet.
    # This is used for efficient computation of delta3.
    my @blossombestedges = ( undef ) x (2*$nvertex);

    # List of currently unused blossom numbers.
    my @unusedblossoms = ( $nvertex .. (2*$nvertex-1) );

    # If $v is a vertex,
    # $dualvar[$v] = 2 * u($v) where u($v) is $v's variable in the dual
    # optimization problem (multiplication by two ensures integer values
    # throughout the algorithm if all edge weights are integers).
    # If $b is a non-trivial blossom,
    # $dualvar[$b] = z($b) where z($b) is $b's variable in the dual
    # optimization problem.
    my @dualvar = ( ( $maxweight ) x $nvertex, ( 0 ) x $nvertex );

    # If $allowedge[$k] is true, edge $k has zero slack in the optimization
    # problem; if $allowedge[$k] is false, the edge's slack may or may not
    # be zero.
    my @allowedge = ( 0 ) x $nedge;

    # Queue of newly discovered S-vertices.
    my @queue;

    # slack($k)
    # returns 2 * slack of edge $k (does not work inside blossoms).
    local *slack = sub {
        my ($k) = @_;
        my $v = $endpoint[2*$k];
        my $w = $endpoint[2*$k+1];
        my $weight = $graph->[$k]->[2];
        return $dualvar[$v] + $dualvar[$w] - 2 * $weight;
    };

    # blossomleaves($b)
    # returns a list of leaf vertices of (sub-)blossom $b.
    local *blossomleaves = sub {
        my ($b) = @_;
        if ($b < $nvertex) {
            return @_;
        } else {
            my @leaves = @{$blossomchilds[$b]};
            my $n = 0;
            while ($n <= $#leaves) {
                $b = shift(@leaves);
                if ($b < $nvertex) {
                    push @leaves, $b;
                    $n++;
                } else {
                    unshift @leaves, @{$blossomchilds[$b]};
                }
            }
            return @leaves;
        }
    };

    # assignlabel($w, $t, $p)
    # assigns label $t to the top-level blossom containing vertex $w
    # and record the fact that $w was reached through the edge with
    # remote endpoint $p.
    local *assignlabel = sub {
        my ($w, $t, $p) = @_;
        DBG("assignlabel($w,$t,$p)") if ($DBG);
        my $b = $inblossom[$w];
        assert($label[$w] == 0 && $label[$b] == 0);
        $label[$w] = $t;
        $label[$b] = $t;
        $labelend[$w] = $p;
        $labelend[$b] = $p;
        $bestedge[$w] = -1;
        $bestedge[$b] = -1;
        if ($t == 1) {
            # $b became an S-blossom; add it(s vertices) to the queue
            push @queue, blossomleaves($b);
            DBG('PUSH ', join(',', blossomleaves($b))) if ($DBG);
        } else {
            # $b became a T-blossom; assign label S to its mate.
            # (If b is a non-trivial blossom, its base is the only vertex
            # with an external mate.)
            my $base = $blossombase[$b];
            assert($mate[$base] >= 0);
            assignlabel($endpoint[$mate[$base]], 1, $mate[$base] ^ 1);
        }
    };

    # scanblossom($v, $w)
    # traces back from vertices $v and $w to discover either a new blossom
    # or an augmenting path; returns the base vertex of the new blossom or -1.
    local *scanblossom = sub {
        my ($v, $w) = @_;
        DBG("scanblossom($v,$w)") if ($DBG);
        # Trace back from $v and $w, placing breadcrumbs as we go.
        my @path;
        my $base = -1;
        while ($v != -1) {
            # Look for a breadcrumb in $v's blossom or put a new breadcrumb.
            my $b = $inblossom[$v];
            if ($label[$b] & 4) {
                $base = $blossombase[$b];
                last;
            }
            assert($label[$b] == 1);
            push @path, $b;
            $label[$b] = 5;
            # Trace one step back.
            assert($labelend[$b] == $mate[$blossombase[$b]]);
            if ($labelend[$b] == -1) {
                # The base of blossom $b is single; stop tracing this path.
                $v = -1;
            } else {
                $v = $endpoint[$labelend[$b]];
                $b = $inblossom[$v];
                # $b is a T-blossom; trace one more step back.
                assert($label[$b] == 2);
                assert($labelend[$b] >= 0);
                $v = $endpoint[$labelend[$b]];
            }
            # Swap v and w so that we alternate between both paths.
            if ($w != -1) {
                my $t = $v;
                $v = $w;
                $w = $t;
            }
        }
        # Remove breadcrumbs.
        foreach (@path) {
            $label[$_] = 1;
        }
        # Return base vertex, if we found one.
        return $base;
    };

    # addblossom($base, $k)
    # constructs a new blossom with given base, containing edge $k which
    # connects a pair of S vertices; labels the new blossom as S; sets its dual
    # variable to zero; relabels its T-vertices to S and adds them to the queue.
    local *addblossom = sub {
        my ($base, $k) = @_;
        my $v = $endpoint[2*$k];
        my $w = $endpoint[2*$k+1];
        my $bb = $inblossom[$base];
        my $bv = $inblossom[$v];
        my $bw = $inblossom[$w];
        # Create blossom.
        my $b = pop(@unusedblossoms);
        DBG("addblossom($base,$k) v=$v w=$w -> b=$b") if ($DBG);
        $blossombase[$b] = $base;
        $blossomparent[$b] = -1;
        $blossomparent[$bb] = $b;
        # Build lists of sub-blossoms and their interconnecting edge endpoints.
        my @path;
        my @endps;
        # Trace back from $v to $base.
        while ($bv != $bb) {
            # Add $bv to the new blossom.
            $blossomparent[$bv] = $b;
            unshift @path, $bv;
            unshift @endps, $labelend[$bv];
            # Trace one step back.
            assert($label[$bv] == 2 || ($label[$bv] == 1 && $labelend[$bv] == $mate[$blossombase[$bv]]));
            assert($labelend[$bv] >= 0);
            $v = $endpoint[$labelend[$bv]];
            $bv = $inblossom[$v];
        }
        # Add the base sub-blossom;
        # add the edge that connects the pair of S vertices.
        unshift @path, $bb;
        push @endps, (2*$k);
        # Trace back from $w to $base.
        while ($bw != $bb) {
            # Add $bw to the new blossom.
            $blossomparent[$bw] = $b;
            push @path, $bw;
            push @endps, ($labelend[$bw] ^ 1);
            # Trace one step back.
            assert($label[$bw] == 2 || ($label[$bw] == 1 && $labelend[$bw] == $mate[$blossombase[$bw]]));
            assert($labelend[$bw] >= 0);
            $w = $endpoint[$labelend[$bw]];
            $bw = $inblossom[$w];
        }
        $blossomchilds[$b] = \@path;
        $blossomendps[$b] = \@endps;
        # Set new blossom's label to S.
        assert($label[$bb] == 1);
        $label[$b] = 1;
        $labelend[$b] = $labelend[$bb];
        # Set dual variable to zero.
        $dualvar[$b] = 0;
        # Relabel vertices.
        foreach $v (blossomleaves($b)) {
            if ($label[$inblossom[$v]] == 2) {
                # This T-vertex now turns into an S-vertex because it becomes
                # part of an S-blossom; add it to the queue.
                push @queue, $v;
            }
            $inblossom[$v] = $b;
        }
        # Compute $blossombestedges[$b].
        my @bestedgeto = ( -1 ) x (2*$nvertex);
        foreach $bv (@path) {
            if (!defined($blossombestedges[$bv])) {
                # This subblossom does not have a list of least-slack edges;
                # get the information from the vertices.
                foreach (blossomleaves($bv)) {
                    foreach my $p (@{$neighbend[$_]}) {
                        my $j = $endpoint[$p];
                        my $bj = $inblossom[$j];
                        if ($bj != $b && $label[$bj] == 1 &&
                            ($bestedgeto[$bj] == -1 ||
                             slack($p>>1) < slack($bestedgeto[$bj]>>1))) {
                            $bestedgeto[$bj] = $p;
                        }
                    }
                }
            } else {
                # Walk this subblossom's least-slack edges.
                foreach my $p (@{$blossombestedges[$bv]}) {
                    my $j = $endpoint[$p];
                    my $bj = $inblossom[$j];
                    if ($bj != $b && $label[$bj] == 1 &&
                        ($bestedgeto[$bj] == -1 ||
                         slack($p>>1) < slack($bestedgeto[$bj]>>1))) {
                        $bestedgeto[$bj] = $p;
                    }
                }
            }
            # Forget about least-slack edges of the subblossom.
            $blossombestedges[$bv] = undef;
            $bestedge[$bv] = -1;
        }
        @bestedgeto = grep { $_ != -1 } @bestedgeto;
        $blossombestedges[$b] = \@bestedgeto;
        # Select bestedge[b].
        $bestedge[$b] = -1;
        foreach my $p (@bestedgeto) {
            if ($bestedge[$b] == -1 ||
                slack($p>>1) < slack($bestedge[$b]>>1)) {
                $bestedge[$b] = $p;
            }
        }
        DBG("blossomchilds[$b] = ", join(',', @path)) if ($DBG);
        DBG("blossomendps[$b]  = ", join('; ', map { $endpoint[$_] . "," . $endpoint[$_^1] } @{$blossomendps[$b]})) if ($DBG);
    };

    # expandblossom($b, $endstage)
    # expands the given top-level blossom.
    local *expandblossom = sub {
        my ($b, $endstage) = @_;
        DBG("expandblossom($b,$endstage) ", join(',', @{$blossomchilds[$b]})) if ($DBG);
        # Convert sub-blossoms into top-level blossoms.
        foreach my $s (@{$blossomchilds[$b]}) {
            $blossomparent[$s] = -1;
            if ($s < $nvertex) {
                $inblossom[$s] = $s;
            } elsif ($endstage && $dualvar[$s] == 0) {
                # Recursively expand this sub-blossom.
                expandblossom($s, $endstage);
            } else {
                foreach (blossomleaves($s)) {
                    $inblossom[$_] = $s;
                }
            }
        }
        # If we expand a T-blossom during a stage, its sub-blossoms must be
        # relabeled.
        if (!$endstage && $label[$b] == 2) {
            # Start at the sub-blossom through which the expanding
            # blossom obtained its label, and relabel sub-blossoms until
            # we reach the base.
            # Figure out through which sub-blossom the expanding blossom
            # obtained its label initially.
            assert($labelend[$b] >= 0);
            my $entrychild = $inblossom[$endpoint[$labelend[$b] ^ 1]];
            # Decide in which direction we will go round the blossom.
            my $j = 0;
            my $jstep;
            $j++ until ($blossomchilds[$b]->[$j] == $entrychild);
            if ($j & 1) {
                # Start index is odd; go forward and wrap.
                $j -= scalar(@{$blossomchilds[$b]});
                $jstep = 1;
            } else {
                # Start index is even; go backward.
                $jstep = -1;
            }
            # Move along the blossom until we get to the base.
            my $p = $labelend[$b];
            while ($j != 0) {
                # Relabel the T-sub-blossom.
                my $q = ($jstep == 1) ? ($blossomendps[$b]->[$j]) :
                                        ($blossomendps[$b]->[$j-1]^1);
                $label[$endpoint[$p^1]] = 0;
                $label[$endpoint[$q^1]] = 0;
                assignlabel($endpoint[$p^1], 2, $p);
                # Step to the next S-sub-blossom and note its forward endpoint.
                $allowedge[$q>>1] = 1;
                $j += $jstep;
                $p = ($jstep == 1) ? ($blossomendps[$b]->[$j]) :
                                     ($blossomendps[$b]->[$j-1]^1);
                # Step to the next T-sub-blossom.
                $allowedge[$p>>1] = 1;
                $j += $jstep;
            }
            # Relabel the base T-sub-blossom WITHOUT stepping through to
            # its mate (so don't call assignlabel).
            my $bv = $blossomchilds[$b]->[$j];
            $label[$endpoint[$p^1]] = 2;
            $label[$bv] = 2;
            $labelend[$endpoint[$p^1]] = $p;
            $labelend[$bv] = $p;
            $bestedge[$bv] = -1;
            # Continue along the blossom until we get back to entrychild.
            $j += $jstep;
            while ($blossomchilds[$b]->[$j] != $entrychild) {
                # Examine the vertices of the sub-blossom to see whether
                # it is reachable from a neighbouring S-vertex outside the
                # expanding blossom.
                $bv = $blossomchilds[$b]->[$j];
                if ($label[$bv] == 1) {
                    # This sub-blossom just got label S through one of its
                    # neighbours; leave it.
                    $j += $jstep;
                    next;
                }
                my $v;
                foreach (blossomleaves($bv)) {
                    if ($label[$_] != 0) {
                        $v = $_;
                        last;
                    }
                }
                # If the sub-blossom contains a reachable vertex, assign
                # label T to the sub-blossom.
                if (defined($v)) {
                    assert($label[$v] == 2);
                    assert($inblossom[$v] == $bv);
                    $label[$v] = 0;
                    $label[$endpoint[$mate[$blossombase[$bv]]]] = 0;
                    assignlabel($v, 2, $labelend[$v]);
                }
                $j += $jstep;
            }
        }
        # Recycle the blossom number.
        $label[$b] = undef;
        $labelend[$b] = undef;
        $blossomparent[$b] = undef;
        $blossomchilds[$b] = undef;
        $blossomendps[$b] = undef;
        $blossombase[$b] = undef;
        $blossombestedges[$b] = undef;
        $bestedge[$b] = undef;
        push @unusedblossoms, $b;
    };

    # augmentblossom($b, $v)
    # swaps matched/unmatched edges over an alternating path through blossom $b
    # between vertex $v and the base vertex; keeps blossom structure consistent.
    local *augmentblossom = sub {
        my ($b, $v) = @_;
        DBG("augmentblossom($b,$v)") if ($DBG);
        # Bubble up through the blossom tree from vertex v to an immediate
        # sub-blossom of b.
        my $t = $v;
        $t = $blossomparent[$t] until ($blossomparent[$t] == $b);
        # Recursively deal with the first sub-blossom.
        augmentblossom($t, $v) if ($t >= $nvertex);
        # Decide in which direction we will go round the blossom.
        my $i = 0;
        $i++ until ($blossomchilds[$b]->[$i] == $t);
        my $j = $i;
        my $jstep;
        if ($i & 1) {
            # Start index is odd; go forward and wrap.
            $j -= scalar(@{$blossomchilds[$b]});
            $jstep = 1;
        } else {
            # Start index is even; go backward.
            $jstep = -1;
        }  
        # Move along the blossom until we get to the base.
        while ($j != 0) {
            # Step to the next sub-blossom and augment it recursively.
            $j += $jstep;
            $t = $blossomchilds[$b]->[$j];
            my $p = ($jstep == 1) ? ($blossomendps[$b]->[$j]) :
                                    ($blossomendps[$b]->[$j-1]^1);
            augmentblossom($t, $endpoint[$p]) if ($t >= $nvertex);
            # Step to the next sub-blossom and augment it recursively.
            $j += $jstep;
            $t = $blossomchilds[$b]->[$j];
            augmentblossom($t, $endpoint[$p^1]) if ($t >= $nvertex);
            # Match the edge connecting those sub-blossoms.
            $mate[$endpoint[$p]] = $p ^ 1;
            $mate[$endpoint[$p^1]] = $p;
            DBG("PAIR ", $endpoint[$p], " ", $endpoint[$p^1], " k=", $p>>1) if ($DBG);
        }
        # Rotate the list of sub-blossoms to put the new base at the front.
        my $n = scalar(@{$blossomchilds[$b]});
        $blossomchilds[$b] = [ @{$blossomchilds[$b]}[$i .. ($n-1)],
                               @{$blossomchilds[$b]}[0 .. ($i-1)] ];
        $blossomendps[$b]  = [ @{$blossomendps[$b]}[$i .. ($n-1)],
                               @{$blossomendps[$b]}[0 .. ($i-1)] ];
        $blossombase[$b] = $blossombase[$blossomchilds[$b]->[0]];
        assert($blossombase[$b] == $v);
    };

    # augmentmatching($k)
    # swaps matched/unmatched edges over an alternating path between two
    # single vertices; the augmenting path runs through edge $k, which
    # connects a pair of S vertices.
    local *augmentmatching = sub {
        my ($k) = @_;
        my $v = $endpoint[2*$k];
        my $w = $endpoint[2*$k+1];
        DBG("augmentmatching($k) v=$v w=$w") if ($DBG);
        DBG("PAIR $v $w k=$k") if ($DBG);
        foreach my $p (2*$k+1, 2*$k) {
            my $s = $endpoint[$p^1];
            # Match vertex s to remote endpoint p. Then trace back from s
            # until we find a single vertex, swapping matched and unmatched
            # edges as we go.
            while (1) {
                my $bs = $inblossom[$s];
                assert($label[$bs] == 1 &&
                       $labelend[$bs] == $mate[$blossombase[$bs]]);
                # Augment through the S-blossom from s to base.
                augmentblossom($bs, $s) if ($bs >= $nvertex);
                # Update $mate[$s]
                $mate[$s] = $p;
                # Trace one step back.
                last if ($labelend[$bs] == -1); # stop at single vertex
                my $t = $endpoint[$labelend[$bs]];
                my $bt = $inblossom[$t];
                assert($label[$bt] == 2);
                # Trace one step back.
                assert($labelend[$bt] >= 0);
                $s = $endpoint[$labelend[$bt]];
                my $j = $endpoint[$labelend[$bt] ^ 1];
                # Augment through the T-blossom from j to base.
                assert($blossombase[$bt] == $t);
                augmentblossom($bt, $j) if ($bt >= $nvertex);
                # Update $mate[$j]
                $mate[$j] = $labelend[$bt];
                # Keep the opposite endpoint;
                # it will be assigned to $mate[$s] in the next step.
                $p = $labelend[$bt] ^ 1;
                DBG("PAIR $s $t k=", $p>>1) if ($DBG);
            }
        }
    };

    # Verify that the optimum solution has been reached.
    local *verifyoptimum = sub {
        my $vdualoffset = 0;
        if ($maxcardinality) {
            # Vertices may have negative dual;
            # find a constant non-negative number to add to all vertex duals.
            foreach (@dualvar[0..($nvertex-1)]) {
                $vdualoffset = -$_ if ($_ < -$vdualoffset);
            }
        }
        # 0. all dual variables are non-negative
        foreach (@dualvar[0 .. ($nvertex-1)]) {
            assert($_ + $vdualoffset >= 0);
        }
        foreach (@dualvar[$nvertex .. (2*$nvertex-1)]) {
            assert(!defined($_) || $_ >= 0);
        }
        # 0. all edges have non-negative slack and
        # 1. all matched edges have zero slack;
        foreach my $k (0 .. ($nedge-1)) {
            my $v = $endpoint[2*$k];
            my $w = $endpoint[2*$k+1];
            my $weight = $graph->[$k]->[2];
            my $s = $dualvar[$v] + $dualvar[$w] - 2 * $weight;
            my @vblossoms = ( $v );
            my @wblossoms = ( $w );
            push @vblossoms, $blossomparent[$vblossoms[-1]]
                until ($blossomparent[$vblossoms[-1]] == -1);
            push @wblossoms, $blossomparent[$wblossoms[-1]]
                until ($blossomparent[$wblossoms[-1]] == -1);
            while ($#vblossoms >= 0 && $#wblossoms >= 0) {
                my $bv = pop(@vblossoms);
                my $bw = pop(@wblossoms);
                last if ($bv != $bw);
                $s += 2 * $dualvar[$bv];
            }
            assert($s >= 0);
            if ($mate[$v]>>1 == $k || $mate[$w]>>1 == $k) {
                assert($mate[$v]>>1 == $k && $mate[$w]>>1 == $k);
                assert($s == 0);
            }
        }
        # 2. all single vertices have zero dual value;
        foreach my $v (0 .. ($nvertex-1)) {
            assert($mate[$v] >= 0 || $dualvar[$v] + $vdualoffset == 0);
        }
        # 3. all blossoms with positive dual value are full.
        foreach my $b ($nvertex .. (2*$nvertex-1)) {
            if (defined($blossombase[$b]) && $dualvar[$b] > 0) {
                assert((scalar(@{$blossomendps[$b]}) & 1) == 1);
                for (my $j = 1; $j <= $#{$blossomendps[$b]}; $j += 2) {
                    my $p = $blossomendps[$b]->[$j];
                    assert($mate[$endpoint[$p]] == ($p^1));
                    assert($mate[$endpoint[$p^1]] == $p);
                }
            }
        }
        # Ok.
    };

    # Check optimized delta2 against a trivial computation.
    local *checkdelta2 = sub {
        foreach my $v (0 .. ($nvertex-1)) {
            if ($label[$inblossom[$v]] == 0) {
                my $bd;
                foreach my $p (@{$neighbend[$v]}) {
                    my $w = $endpoint[$p];
                    if ($label[$inblossom[$w]] == 1) {
                        my $d = slack($p >> 1);
                        $bd = $d if (!defined($bd) || $d < $bd);
                    }
                }
                assert((!defined($bd) && $bestedge[$v] == -1) || ($bestedge[$v] != -1 && $bd == slack($bestedge[$v]>>1)));
            }
        }
    };

    # Check optimized delta3 against a trivial computation.
    local *checkdelta3 = sub {
        my ($bd, $tbd);
        foreach my $b (0 .. (2*$nvertex-1)) {
            if (defined($blossomparent[$b]) && $blossomparent[$b] == -1 &&
                $label[$b] == 1) {
                foreach my $v (blossomleaves($b)) {
                    foreach my $p (@{$neighbend[$v]}) {
                        my $w = $endpoint[$p];
                        if ($inblossom[$w] != $b && $label[$inblossom[$w]] == 1) {
                            my $d = slack($p>>1);
                            $bd = $d if (!defined($bd) || $d < $bd);
                        }
                    }
                }
                if ($bestedge[$b] != -1) {
                    my $w = $endpoint[$bestedge[$b]];
                    my $v = $endpoint[$bestedge[$b]^1];
                    assert($inblossom[$v] == $b);
                    assert($inblossom[$w] != $b);
                    assert($label[$inblossom[$w]] == 1 && $label[$inblossom[$v]] == 1);
                    my $d = slack($bestedge[$b]>>1);
                    $tbd = $d if (!defined($tbd) || $d < $tbd);
                }
            }
        }
        assert((!defined($bd) && !defined($tbd)) || ($bd == $tbd));
    };

    # Main loop: continue until no further improvement is possible.
    for (my $t = 0; ; $t++) {

        # Each iteration of this loop is a "stage".
        # A stage finds an augmenting path and uses that to improve
        # the matching.
        DBG("STAGE $t") if ($DBG);

        # Remove labels from top-level blossoms/vertices.
        foreach (@label) { $_ = 0 if (defined($_)); }

        # Forget all about least-slack edges.
        foreach (@bestedge) { $_ = -1 if (defined($_)); }
        foreach (@blossombestedges) { $_ = undef; }

        # Loss of labeling means that we can not be sure that currently
        # allowable edges remain allowable througout this stage.
        foreach (@allowedge) { $_ = 0; }

        # Make queue empty.
        @queue = ( );
 
        # Label single blossoms/vertices with S and put them in the queue.
        for (my $v = 0; $v < $nvertex; $v++) {
            if ($mate[$v] == -1 && $label[$inblossom[$v]] == 0) {
                assignlabel($v, 1, -1);
            }
        }

        # Loop until we succeed in augmenting the matching.
        my $augmented = 0;
        while (1) {

            # Each iteration of this loop is a "substage".
            # A substage tries to find an augmenting path;
            # if found, the path is used to improve the matching and
            # the stage ends. If there is no augmenting path, the
            # primal-dual method is used to pump some slack out of
            # the dual variables.
            DBG("SUBSTAGE") if ($DBG);

            # Continue labeling until all vertices which are reachable
            # through an alternating path have got a label.
            while (@queue && !$augmented) {

                # Take an S vertex from the queue.
                my $v = pop(@queue);
                DBG("POP v=$v") if ($DBG);
                assert($label[$inblossom[$v]] == 1);

                # Scan its neighbours:
                foreach my $p (@{$neighbend[$v]}) {
                    # w is a neighbour to v
                    my $w = $endpoint[$p];
                    # ignore blossom-internal edges
                    next if ($inblossom[$v] == $inblossom[$w]);
                    # check whether edge has zero slack
                    my $kslack;
                    if (!$allowedge[$p>>1]) {
                        $kslack = slack($p>>1);
                        $allowedge[$p>>1] = ($kslack == 0);
                    }
                    if ($allowedge[$p>>1]) {
                        if ($label[$inblossom[$w]] == 0) {
                            # (C1) w is a free vertex;
                            # label w with T and label its mate with S (R12).
                            assignlabel($w, 2, $p ^ 1);
                        } elsif ($label[$inblossom[$w]] == 1) {
                            # (C2) w is an S-vertex (not in the same blossom);
                            # follow back-links to discover either an
                            # augmenting path or a new blossom.
                            my $base = scanblossom($v, $w);
                            if ($base >= 0) {
                                # Found a new blossom; add it to the blossom
                                # bookkeeping and turn it into an S-blossom.
                                addblossom($base, $p>>1);
                            } else {
                                # Found an augmenting path; augment the
                                # matching and end this stage.
                                augmentmatching($p>>1);
                                $augmented = 1;
                                last;
                            }
                        } elsif ($label[$w] == 0) {
                            # w is inside a T-blossom, but w itself has not
                            # yet been reached from outside the blossom;
                            # mark it as reached (we need this to relabel
                            # during T-blossom expansion).
                            assert($label[$inblossom[$w]] == 2);
                            $label[$w] = 2;
                            $labelend[$w] = $p ^ 1;
                        }
                    } elsif ($label[$inblossom[$w]] == 1) {
                        # keep track of the least-slack non-allowable edge to
                        # a different S-blossom.
                        my $b = $inblossom[$v];
                        if ($bestedge[$b] == -1 ||
                            $kslack < slack($bestedge[$b]>>1)) {
                            $bestedge[$b] = $p;
                        }
                    } elsif ($label[$w] == 0) {
                        # w is a free vertex (or an unreached vertex inside
                        # a T-blossom) but we can not reach it yet;
                        # keep track of the least-slack edge that reaches w.
                        if ($bestedge[$w] == -1 ||
                            $kslack < slack($bestedge[$w]>>1)) {
                            $bestedge[$w] = $p ^ 1;
                        }
                    }
                }

            }

            last if ($augmented);

            # There is no augmenting path under these constraints;
            # compute delta and reduce slack in the optimization problem.
            # (Note that our vertex dual variables, edge slacks and delta's
            # are pre-multiplied by two.)
            my $deltatype = -1;
            my ($delta, $deltaedge, $deltablossom);

            # Verify data structures for delta2/delta3 computation.
            checkdelta2() if ($CHECK_DELTA);
            checkdelta3() if ($CHECK_DELTA);

            # Compute delta1: the minumum value of any vertex dual.
            if (!$maxcardinality) {
                $deltatype = 1;
                $delta = $dualvar[0];
                foreach (@dualvar[0 .. ($nvertex-1)]) {
                    $delta = $_ if ($_ < $delta);
                }
            }

            # Compute delta2: the minimum slack on any edge between
            # an S-vertex and a free vertex.
            for (my $v = 0; $v < $nvertex; $v++) {
                if ($label[$inblossom[$v]] == 0 && $bestedge[$v] != -1) {
                    my $d = slack($bestedge[$v]>>1);
                    if ($deltatype == -1 || $d < $delta) {
                        $deltatype = 2;
                        $delta = $d;
                        $deltaedge = $bestedge[$v];
                    }
                }
            }

            # Compute delta3: half the minimum slack on any edge between
            # a pair of S-blossoms.
            for (my $b = 0; $b < 2*$nvertex; $b++) {
                if (defined($blossomparent[$b]) && $blossomparent[$b] == -1 &&
                    $label[$b] == 1 && $bestedge[$b] != -1) {
                    my $d = slack($bestedge[$b]>>1) / 2;
                    if ($deltatype == -1 || $d < $delta) {
                        $deltatype = 3;
                        $delta = $d;
                        $deltaedge = $bestedge[$b];
                    }
                }
            }

            # Compute delta4: minimum z variable of any T-blossom.
            for (my $b = $nvertex; $b < 2*$nvertex; $b++) {
                if (defined($blossombase[$b]) && $blossomparent[$b] == -1 &&
                    $label[$b] == 2 &&
                    ($deltatype == -1 || $dualvar[$b] < $delta)) {
                    $deltatype = 4;
                    $delta = $dualvar[$b];
                    $deltablossom = $b;
                }
            }

            if ($deltatype == -1) {
                # No further improvement possible; max-cardinality optimum
                # reached. Do a final delta update to make the optimum
                # verifyable.
                assert($maxcardinality);
                $deltatype = 1;
                $delta = $dualvar[0];
                foreach (@dualvar[0 .. ($nvertex-1)]) {
                    $delta = $_ if ($_ < $delta);
                }
                $delta = 0 if ($delta < 0);
            }

            # Update dual variables according to delta.
            for (my $v = 0; $v < $nvertex; $v++) {
                if ($label[$inblossom[$v]] == 1) {
                    # S-vertex: 2*u = 2*u - 2*delta
                    $dualvar[$v] -= $delta;
                } elsif  ($label[$inblossom[$v]] == 2) {
                    # T-vertex: 2*u = 2*u + 2*delta
                    $dualvar[$v] += $delta;
                }
            }
            for (my $b = $nvertex; $b < 2*$nvertex; $b++) {
                if (defined($blossombase[$b]) && $blossomparent[$b] == -1) {
                    if ($label[$b] == 1) {
                        # top-level S-blossom: z = z + 2*delta
                        $dualvar[$b] += $delta;
                    } elsif ($label[$b] == 2) {
                        # top-level T-blossom: z = z - 2*delta
                        $dualvar[$b] -= $delta;
                    }
                }
            }

            # Take action at the point where minimum delta occurred.
            DBG("delta$deltatype=$delta") if ($DBG);
            if ($deltatype == 1) { 
                # No further improvement possible; optimum reached.
                last;
            } elsif ($deltatype == 2) {
                # Use the least-slack edge to continue the search.
                $allowedge[$deltaedge>>1] = 1;
                my $v = $endpoint[$deltaedge];
                assert($label[$inblossom[$v]] == 1);
                push @queue, $v;
            } elsif ($deltatype == 3) {
                # Use the least-slack edge to continue the search.
                $allowedge[$deltaedge>>1] = 1;
                my $v = $endpoint[$deltaedge];
                assert($label[$inblossom[$v]] == 1);
                DBG("PUSH $v") if ($DBG);
                push @queue, $v;
            } elsif ($deltatype == 4) {
                # Expand the least-z blossom.
                expandblossom($deltablossom, 0);
            }

            # End of a this substage.
        }

        # Stop when no more augmenting path can be found.
        last if (!$augmented);

        # End of a stage; expand all S-blossoms which have dualvar = 0.
        for (my $b = $nvertex; $b < 2*$nvertex; $b++) {
            if (defined($blossombase[$b]) && $blossomparent[$b] == -1 &&
                $label[$b] == 1 && $dualvar[$b] == 0) {
                expandblossom($b, 1);
            }
        }

    }

    # Verify that we reached the optimum solution.
    verifyoptimum() if ($CHECK_OPTIMUM && $all_integer_weights);

    # Return %ret such that $ret[$v] is the vertex to which $v is paired.
    my %ret;
    for (my $v = 0; $v < $nvertex; $v++) {
        if ($mate[$v] != -1) {
            assert($endpoint[$mate[$endpoint[$mate[$v]]]] == $v);
            $ret{$nodelist[$v]} = $nodelist[$endpoint[$mate[$v]]];
        }
    }

    undef @nodelist;
    undef %nodemap;
    undef @endpoint;
    undef @neighbend;
    undef @mate;
    undef @label;
    undef @labelend;
    undef @inblossom;
    undef @blossomparent;
    undef @blossomchilds;
    undef @blossombase;
    undef @blossomendps;

    return %ret;
}


sub edges_from_Graph {
    my ($g) = @_;
    assert(!$g->is_multi_graph, "Graph must not be a multigraph");
    assert($g->is_undirected, "Graph must be undirected");
    my @edges;
    foreach ($g->edges) {
        assert($#{$_} == 1);
        my ($v, $w) = @{$_};
        assert($v ne $w, "Graph must not contain self loops");
        my $weight = $g->get_edge_weight($v, $w);
        $weight = 1 if (!defined($weight));
        push @edges, [ $v, $w, $weight ];
    }
    return \@edges;
}

1; # End of Graph::Matching
