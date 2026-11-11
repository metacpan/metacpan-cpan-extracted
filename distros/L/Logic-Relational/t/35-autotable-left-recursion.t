use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';

use lib ( '../lib', 'lib' );
use Test2::V0 '!call';
use Logic::Relational::Program;
use Logic::Relational::Syntax;
use Logic::Relational qw(variable call all);

# ---------------------------------------------------------------------------
# 1. OOP Interface: Auto-tabling and Warning on Direct Left-Recursion
# ---------------------------------------------------------------------------
subtest 'OOP API auto-tables direct left-recursion with warning' => sub {
    my $prog = Logic::Relational::Program->new;

    $prog->fact( 'edge', 'a', 'b' );
    $prog->fact( 'edge', 'b', 'c' );
    $prog->fact( 'edge', 'c', 'a' );    # cycle a -> b -> c -> a
    $prog->fact( 'edge', 'c', 'd' );

    my $x = variable('X');
    my $y = variable('Y');
    my $z = variable('Z');

    my @warnings;
    {
        local $SIG{__WARN__} = sub ($msg) { push @warnings, $msg };

    # Direct left-recursive rule (first subgoal is path/2, matching head path/2)
        $prog->rule(
            head => call( 'path', $x, $z ),
            body => all( call( 'path', $x, $y ), call( 'edge', $y, $z ), ),
        );

        # Base case
        $prog->rule(
            head => call( 'path', $x, $y ),
            body => call( 'edge', $x, $y ),
        );
    }

    is( scalar(@warnings), 1, 'Exactly one warning emitted' );
    like(
        $warnings[0],
        qr/Direct left-recursion detected in rule for 'path\/2'/,
        'Warning message clearly identifies predicate and auto-tabling action'
    );

    ok( $prog->is_tabled( 'path', 2 ),
        'Predicate path/2 is now marked as tabled' );

# Verify that query over the cyclic graph terminates and computes all reachable nodes
    my $dest      = variable('Dest');
    my $q         = $prog->query( call( 'path', 'a', $dest ) );
    my @reachable = sort $q->all_values($dest);
    is(
        \@reachable,
        [ 'a', 'b', 'c', 'd' ],
        'Auto-tabled left-recursive query evaluates to fixpoint and terminates'
    );
};

# ---------------------------------------------------------------------------
# 2. Already-Tabled Rules Do Not Produce Redundant Warnings
# ---------------------------------------------------------------------------
subtest 'Explicitly tabled predicate does not produce duplicate warning' =>
  sub {
    my $prog = Logic::Relational::Program->new;

    $prog->fact( 'edge', '1', '2' );
    $prog->fact( 'edge', '2', '3' );

    # Pre-emptively tabled by user
    $prog->table( 'reach', 2 );
    ok( $prog->is_tabled( 'reach', 2 ), 'Explicitly tabled reach/2' );

    my $x = variable('X');
    my $y = variable('Y');
    my $z = variable('Z');

    my @warnings;
    {
        local $SIG{__WARN__} = sub ($msg) { push @warnings, $msg };
        $prog->rule(
            head => call( 'reach', $x, $z ),
            body => all( call( 'reach', $x, $y ), call( 'edge', $y, $z ), ),
        );
    }

    is( scalar(@warnings), 0,
        'No warning emitted when predicate was already tabled' );
  };

# ---------------------------------------------------------------------------
# 3. Non-Left-Recursive Rules Do Not Trigger Auto-Tabling
# ---------------------------------------------------------------------------
subtest 'Right-recursive and base rules do not trigger auto-tabling' => sub {
    my $prog = Logic::Relational::Program->new;

    my $x = variable('X');
    my $y = variable('Y');
    my $z = variable('Z');

    my @warnings;
    {
        local $SIG{__WARN__} = sub ($msg) { push @warnings, $msg };

        # Right-recursive: first goal is edge/2, not ancestor/2
        $prog->rule(
            head => call( 'ancestor', $x, $z ),
            body => all( call( 'edge', $x, $y ), call( 'ancestor', $y, $z ), ),
        );
    }

    is( scalar(@warnings), 0, 'No warning for right-recursive rule' );
    ok(
        !$prog->is_tabled( 'ancestor', 2 ),
        'ancestor/2 is not automatically tabled'
    );
};

# ---------------------------------------------------------------------------
# 4. Declarative Syntax (logic block) Auto-Tabling
# ---------------------------------------------------------------------------
logic AutoTableSyntaxTest {
    facts {
        hop( 'p', 'q' );
        hop( 'q', 'r' );
        hop( 'r', 'p' );    # cycle
    }

    # Left-recursive rule without explicit 'table' statement
    rule route( $a, $c ) {
        fresh my $b;
        route( $a, $b );
        hop( $b, $c );
    }

    rule route( $a, $b ) {
        hop( $a, $b );
    }
}

subtest 'Declarative syntax auto-tables left-recursive rules' => sub {
    ok(
        $AutoTableSyntaxTest::PROGRAM->is_tabled( 'route', 2 ),
        'route/2 was auto-tabled during logic block compilation'
    );

    fresh my $target;
    my $q;
    query AutoTableSyntaxTest::route( 'p', $target )->$q;

    my @targets = sort $q->all_values($target);
    is(
        \@targets,
        [ 'p', 'q', 'r' ],
        'Declarative left-recursive query succeeds across cyclic graph'
    );
};

done_testing;
