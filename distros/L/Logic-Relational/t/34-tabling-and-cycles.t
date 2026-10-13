use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';

use lib ( '../lib', 'lib' );
use Test2::V0 '!call';
use Logic::Relational::Syntax;
use Logic::Relational::Program;
use Logic::Relational qw(variable call all);

# ---------------------------------------------------------------------------
# 1. Automatic Ancestor Cycle Pruning (Cyclic Graph without explicit table)
# ---------------------------------------------------------------------------
logic CyclicFriends {
    facts {
        # Inline comments and propositional facts mixed with relational facts
        network_active;     # 0-arity propositional fact
        person('Alice');    # first person
        person('Bob');      # second person
        person('Clara');
        person('David');

        friend( 'Alice', 'Bob' );
        friend( 'Bob',   'Alice' );    # mutual cycle Alice <-> Bob
        friend( 'Bob',   'David' );
        friend( 'Clara', 'David' );
        friend( 'David', 'Bob' );      # mutual cycle Bob <-> David

        stressed('David');
    }

    rule system_ready {
        network_active;
    }

    rule smokes($x) {
        stressed($x);
    }

    rule smokes($x) {
        fresh my $y;
        friend( $x, $y );
        smokes($y);
    }
}

subtest 'Automatic ancestor cycle pruning & 0-arity/comment syntax' => sub {
    my $q_ready;
    query CyclicFriends::system_ready->$q_ready;
    ok( $q_ready->is_true,
        '0-arity rule and 0-arity fact in facts block work' );

    # Even with mutual cycles (Alice <-> Bob, Bob <-> David), querying smokes
    # terminates cleanly and finds everyone who can reach stressed('David'):
    fresh my $who;
    my $q_smokes;
    query CyclicFriends::smokes($who)->$q_smokes;

    my @smokers = sort $q_smokes->distinct_values($who);
    is(
        \@smokers,
        [ 'Alice', 'Bob', 'Clara', 'David' ],
        'Cyclic recursion terminates and finds all 4 connected people'
    );
};

# ---------------------------------------------------------------------------
# 2. Tabled Left-Recursive and Doubly-Recursive Rules on Cyclic Graph
# ---------------------------------------------------------------------------
logic LeftRecursiveGraph {
    table path / 2;

    facts {
        edge( 'a', 'b' );
        edge( 'b', 'c' );
        edge( 'c', 'a' );    # 3-cycle a -> b -> c -> a
        edge( 'c', 'd' );
    }

    # Left-recursive rule placed FIRST (would infinite-loop in standard Prolog)
    rule path( $x, $z ) {
        fresh my $y;
        path( $x, $y );
        edge( $y, $z );
    }

    rule path( $x, $y ) {
        edge( $x, $y );
    }
}

subtest 'Tabled left-recursive path on cyclic graph' => sub {
    fresh my $dest;
    my $q;
    query LeftRecursiveGraph::path( 'a', $dest )->$q;

    my @reachable = sort $q->distinct_values($dest);
    is(
        \@reachable,
        [ 'a', 'b', 'c', 'd' ],
        'Left-recursive tabled rule computes full transitive closure over cycle'
    );

    # Test all_tuples helper
    fresh my ( $u, $v );
    my $q_all;
    query LeftRecursiveGraph::path( $u, $v )->$q_all;
    my @tuples = $q_all->all_tuples( [ $u, $v ] );
    is( scalar(@tuples), 12, '12 distinct (u, v) pairs in transitive closure' );
};

# ---------------------------------------------------------------------------
# 3. Subgoal Answer Memoization Verification (Call Count Reduction)
# ---------------------------------------------------------------------------
subtest 'Tabled subgoal answer memoization avoids redundant evaluation' => sub {
    my $prog       = Logic::Relational::Program->new;
    my $eval_count = 0;

    $prog->generator(
        'expensive_step',
        2,
        sub ( $in, $out ) {
            $eval_count++;
            my $done = 0;
            return sub {
                return () if $done++;
                return [ $in, $in * 10 ];
            };
        }
    );

    my $x = variable('X');
    my $y = variable('Y');
    $prog->rule(
        head => call( 'compute',        $x, $y ),
        body => call( 'expensive_step', $x, $y ),
    );

    # Rule calling compute(5, A) and compute(5, B) twice
    my $a = variable('A');
    my $b = variable('B');
    $prog->rule(
        head => call( 'double_check', $x, $a, $b ),
        body => all( call( 'compute', $x, $a ), call( 'compute', $x, $b ), ),
    );

    # Without tabling: expensive_step is called twice
    $eval_count = 0;
    my $q_untabled =
      $prog->query( call( 'double_check', 5, variable('R1'), variable('R2') ) );
    my $sol1 = $q_untabled->next;
    ok( $sol1, 'Untabled query succeeded' );
    is( $eval_count, 2, 'Untabled query evaluated generator twice' );

    # With tabling: expensive_step is called only once and memoized
    $prog->table( 'compute', 2 );
    $eval_count = 0;
    my $q_tabled =
      $prog->query( call( 'double_check', 5, variable('R1'), variable('R2') ) );
    my $sol2 = $q_tabled->next;
    ok( $sol2, 'Tabled query succeeded' );
    is( $eval_count, 1,
        'Tabled query evaluated generator only once (memoized)' );
};

done_testing;
