#!/usr/bin/env perl

use v5.38;
use lib ( '../lib', 'lib' );
use Logic::Relational::Syntax;

# ==============================================================================
# SUBGOAL TABLING (MEMOIZATION) & CYCLIC GRAPH RESOLUTION
# ==============================================================================
# Demonstrating:
#   1. Declarative subgoal tabling ('table pred/arity;') for left-recursive
#      rules and cyclic graphs.
#   2. Query deduplication helpers ('distinct_values' and 'all_tuples').
#   3. The difference between automatic ancestor cycle pruning (always on)
#      and answer memoization via 'table' on diamond/cyclic networks.
# ==============================================================================

logic NetworkTopology {

    # Enable iterative fixpoint tabling for reachable/2
    table reachable / 2;

    # Cyclic + diamond network topology:
    #
    #   alpha <---> beta ---> delta ---> epsilon
    #     ^           |         ^
    #     |           v         |
    #     +-------- gamma ------+
    #
    # Plus an isolated island:
    #   zeta <---> eta
    facts {
        link( 'alpha', 'beta' );
        link( 'beta',  'alpha' );
        link( 'beta',  'gamma' );
        link( 'gamma', 'alpha' );
        link( 'beta',  'delta' );
        link( 'gamma', 'delta' );
        link( 'delta', 'epsilon' );

        # Disconnected cycle
        link( 'zeta', 'eta' );
        link( 'eta',  'zeta' );
    }

    # Base case: direct link
    rule reachable( $x, $y ) {
        link( $x, $y );
    }

    # Left-recursive transitive closure.
    # In standard SLD resolution without tabling, putting reachable($x, $y)
    # first in the body causes immediate infinite left-recursion.
    # With 'table reachable/2;', the engine computes the least fixpoint
    # and memoizes unique answers.
    rule reachable( $x, $z ) {
        fresh my $y;
        reachable( $x, $y );
        link( $y, $z );
    }

    # Right-recursive untabled predicate on the same cyclic/diamond graph
    # (relies on automatic ancestor cycle pruning, but explores every
    # distinct simple path unless tabled).
    rule path_via_ancestors( $x, $y ) {
        link( $x, $y );
    }

    rule path_via_ancestors( $x, $z ) {
        fresh my $y;
        link( $x, $y );
        path_via_ancestors( $y, $z );
    }
}

say "=" x 70;
say "   SUBGOAL TABLING & CYCLIC GRAPH DEMO";
say "=" x 70;

# ------------------------------------------------------------------------------
# Demo 1: Left-Recursive Transitive Closure on a Cyclic Graph
# ------------------------------------------------------------------------------
say "\n--- 1. Tabled Left-Recursive Reachability from 'alpha' ---";
say "  is_tabled('reachable/2') = "
  . ( $NetworkTopology::PROGRAM->is_tabled('reachable/2') ? 'YES' : 'NO' );

my $q_reach;
query NetworkTopology::reachable( 'alpha', fresh my $target )->$q_reach;
my @reachable_from_alpha = sort $q_reach->all_values($target);
say "  Nodes reachable from 'alpha': " . join( ', ', @reachable_from_alpha );
say
"  (Note: each node is returned exactly once despite cycles and diamond paths)";

# ------------------------------------------------------------------------------
# Demo 2: Enumerating All Connected Node Pairs with all_tuples()
# ------------------------------------------------------------------------------
say
"\n--- 2. All Reachable (Source -> Target) Pairs in Component {zeta, eta} ---";
my $q_pairs;
query NetworkTopology::reachable( fresh my $src, fresh my $dst )->$q_pairs;

my @island_pairs =
  grep { $_->[0] =~ /^(?:zeta|eta)$/x }
  sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] }
  $q_pairs->all_tuples( [ $src, $dst ] );

for my $pair (@island_pairs) {
    say sprintf( "  %s -> %s", $pair->[0], $pair->[1] );
}

# ------------------------------------------------------------------------------
# Demo 3: Ancestor Cycle Pruning vs. Subgoal Tabling (Diamond + Cycle Paths)
# ------------------------------------------------------------------------------
say "\n--- 3. Ancestor Cycle Pruning vs. Subgoal Tabling ---";

# Without tabling on path_via_ancestors/2:
# Ancestor cycle pruning automatically stops infinite loops (alpha -> beta -> alpha),
# but each distinct acyclic route (e.g. alpha->beta->delta->epsilon vs
# alpha->beta->gamma->delta->epsilon) produces a separate derivation.
my ( $q_untabled_raw, $q_untabled_dist );
query NetworkTopology::path_via_ancestors( 'alpha', fresh my $node1 )
  ->$q_untabled_raw;
query NetworkTopology::path_via_ancestors( 'alpha', fresh my $node1_dist )
  ->$q_untabled_dist;
my @raw_untabled      = $q_untabled_raw->all_values($node1);
my @distinct_untabled = $q_untabled_dist->distinct_values($node1_dist);

say "  Untabled 'path_via_ancestors(alpha, Target)':";
say "    Raw derivations (all_values)      : ["
  . join( ', ', @raw_untabled ) . "] ("
  . scalar(@raw_untabled)
  . " derivations)";
say "    Deduplicated (distinct_values)    : ["
  . join( ', ', sort @distinct_untabled ) . "] ("
  . scalar(@distinct_untabled)
  . " unique nodes)";

# Now dynamically enable tabling on path_via_ancestors/2 at runtime!
$NetworkTopology::PROGRAM->table('path_via_ancestors/2');

my $q_tabled;
query NetworkTopology::path_via_ancestors( 'alpha', fresh my $node2 )
  ->$q_tabled;
my @raw_tabled = $q_tabled->all_values($node2);

say "\n  After \$NetworkTopology::PROGRAM->table('path_via_ancestors/2'):";
say "    Raw derivations (all_values)      : ["
  . join( ', ', sort @raw_tabled ) . "] ("
  . scalar(@raw_tabled)
  . " memoized answers)";
say "";

