use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';

use lib ( '../lib', 'lib' );
use Test2::V0 '!call';
use Logic::Relational::Program;
use Logic::Relational qw(variable call all);

# ---------------------------------------------------------------------------
# 1. Default max_steps and Query-Level Override
# ---------------------------------------------------------------------------
subtest 'Query enforces max_steps execution limit' => sub {
    my $prog = Logic::Relational::Program->new;

    # Peano arithmetic generating an infinite sequence of natural numbers:
    # nat(0). nat(s(N)) :- nat(N).
    $prog->fact( 'nat', 0 );
    my $n = variable('N');
    $prog->rule(
        head => call( 'nat', [ 's', $n ] ),
        body => call( 'nat', $n ),
    );

    # Default max_steps is 100_000
    my $q_default = $prog->query( call( 'nat', variable('X') ) );
    is( $q_default->max_steps,  100_000, 'Default max_steps is 100,000' );
    is( $q_default->step_count, 0,       'Initial step_count is 0' );

    # Query with a tight step limit (e.g. 50 steps)
    my $q_tight =
      $prog->query( call( 'nat', variable('X') ), max_steps => 50, );
    is( $q_tight->max_steps, 50, 'Query max_steps overridden to 50' );

    my $caught_error;
    try {
        while ( my $sol = $q_tight->next ) {

            # Loop will run until max_steps is exceeded
        }
    }
    catch ($e) {
        $caught_error = $e;
    }

    ok( $caught_error, 'Exception thrown when query exceeds max_steps' );
    like(
        $caught_error,
        qr/Query exceeded maximum resolution steps of 50/,
        'Exception message specifies limit and guidance'
    );
    ok( $q_tight->step_count > 50,
        'Step count accurately tracks resolution steps' );
};

# ---------------------------------------------------------------------------
# 2. Program-Level max_steps Configuration
# ---------------------------------------------------------------------------
subtest 'Program-level max_steps configuration and inheritance' => sub {
    my $prog = Logic::Relational::Program->new( max_steps => 120 );
    is( $prog->max_steps, 120, 'Program constructor sets max_steps' );

    $prog->fact( 'nat', 0 );
    my $n = variable('N');
    $prog->rule(
        head => call( 'nat', [ 's', $n ] ),
        body => call( 'nat', $n ),
    );

    # Inherited from program
    my $q = $prog->query( call( 'nat', variable('Out') ) );
    is( $q->max_steps, 120, 'Query inherits max_steps from program' );

    # Mutator on program
    $prog->max_steps(250);
    is( $prog->max_steps, 250, 'Program accessor updates max_steps' );

    my $q2 = $prog->query( call( 'nat', variable('Out') ) );
    is( $q2->max_steps, 250,
        'Subsequent queries inherit updated program max_steps' );
};

# ---------------------------------------------------------------------------
# 3. Unlimited Execution (max_steps => 0)
# ---------------------------------------------------------------------------
subtest 'Unlimited execution with max_steps => 0' => sub {
    my $prog = Logic::Relational::Program->new;

    # Generator producing a sequence of numbers
    $prog->generator(
        'count_up',
        1,
        sub ($start) {
            my $curr = $start;
            return sub {
                return [ $curr++ ];
            };
        }
    );

    # Setting max_steps => 0 disables step limiting
    my $num = variable('Num');
    my $q   = $prog->query( call( 'count_up', $num ), max_steps => 0 );
    is( $q->max_steps, 0, 'max_steps => 0 signifies unlimited' );

    my $fetched = 0;
    while ( my $sol = $q->next ) {
        $fetched++;
        last if $fetched >= 150;
    }

    is( $fetched, 150,
        'Successfully fetched 150 solutions without hitting a limit' );
    ok( $q->step_count >= 150, 'step_count is tracked even when unlimited' );
};

done_testing;
