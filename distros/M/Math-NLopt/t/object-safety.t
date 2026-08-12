#! perl

use v5.12;
use Test2::Require::RealFork;
use Test2::V0;
use Test2::Tools::AsyncSubtest 'fork_subtest';
use Scalar::Util 'weaken';

use Math::NLopt qw( NLOPT_LD_MMA NLOPT_LD_LBFGS );

# Callbacks are compiled in a separate lexical scope.   If they
# are compiled directly in the test routine's scope, they seem
# to linger and still keep the weak references alive even
# when the strong reference is destroyed

{
    my $ast = fork_subtest 'destruction is idempotent' => sub {
        my $opt = Math::NLopt->new( NLOPT_LD_MMA, 1 );
        $opt->DESTROY;

        ok( lives { $opt->DESTROY }, 'repeated destruction is safe' );
        undef $opt;
    };
    $ast->finish;
}

{
    my $ast = fork_subtest 'methods reject a destroyed object' => sub {
        my $opt = Math::NLopt->new( NLOPT_LD_MMA, 1 );
        $opt->DESTROY;

        isa_ok(
            dies { $opt->get_algorithm },
            ['Math::NLopt::Exception::InvalidUse'],
            'NLopt-backed method rejects an explicitly destroyed object',
        );
        isa_ok(
            dies { $opt->set_min_objective( sub { 0 } ) },
            ['Math::NLopt::Exception::InvalidUse'],
            'operational method rejects an explicitly destroyed object',
        );
        undef $opt;
    };
    $ast->finish;
}

for my $method ( qw( set_precond_min_objective set_precond_max_objective ) ) {
    my $ast = fork_subtest "failed $method registration releases its callback cache" => sub {
        my $opt = Math::NLopt->new( NLOPT_LD_MMA, 1 );

        my $weak_data = my $data = { kind => $method };
        my $weak_pre  = my $pre  = eval q{sub { }};
        weaken( $weak_data );
        weaken( $weak_pre );

        my $exception = dies { $opt->$method( 1, $pre, $data ) };
        isa_ok(
            $exception,
            ['Math::NLopt::Exception::InvalidArgs'],
            'invalid preconditioned objective callback throws InvalidArgs',
        );

        undef $data;
        ok( !defined( $weak_data ), 'failed registration does not retain callback data' );
        undef $pre;
        ok( !defined( $weak_pre ), 'failed registration does not retain the preconditioner' );
        undef $opt;
    };
    $ast->finish;
}

{
    my $ast = fork_subtest 'failed objective replacement preserves the active callback' => sub {
        my $opt   = Math::NLopt->new( NLOPT_LD_MMA, 1 );
        my $calls = 0;

        $opt->set_min_objective(
            sub {
                my ( $x ) = @_;
                ++$calls;
                return $x->[0]**2;
            } );

        isa_ok(
            dies { $opt->set_min_objective( 1 ) },
            ['Math::NLopt::Exception::InvalidArgs'],
            'invalid replacement throws InvalidArgs',
        );

        $opt->set_lower_bounds( [-1] );
        $opt->set_upper_bounds( [1] );
        $opt->set_maxeval( 1 );

        ok( lives { $opt->optimize( [0.5] ) }, 'optimization remains safe after failed replacement' );
        ok( $calls > 0,                        'the original objective remains active' );
    };
    $ast->finish;
}

subtest 'scalar constraint' => sub {
    for my $method ( qw( add_equality_constraint add_inequality_constraint ) ) {
        my $ast = fork_subtest "failed $method registration releases its callback cache" => sub {
            my $opt       = Math::NLopt->new( NLOPT_LD_LBFGS, 1 );
            my $weak_data = my $data = { kind => 'scalar constraint' };
            my $weak_func = my $func = eval q{sub { 0 }};
            weaken( $weak_data );
            weaken( $weak_func );

            my $exception = dies { $opt->$method( $func, data => $data ) };
            isa_ok(
                $exception,
                ['Math::NLopt::Exception::InvalidArgs'],
                'unsupported registration throws InvalidArgs',
            );

            undef $data;
            ok( !defined( $weak_data ), 'failed registration does not retain callback data' );
            undef $func;
            ok( !defined( $weak_func ), 'failed registration does not retain the callback' );
            undef $opt;
        };
        $ast->finish;
    }
};

subtest 'vector constraint' => sub {
    for my $method ( qw( add_equality_mconstraint add_inequality_mconstraint ) ) {
        my $ast = fork_subtest "failed $method registration releases its callback cache" => sub {
            my $opt = Math::NLopt->new( NLOPT_LD_LBFGS, 1 );

            my $weak_data = my $data = { kind => 'vector constraint' };
            my $weak_func = my $func = eval q{sub { }};
            weaken( $weak_data );
            weaken( $weak_func );

            my $exception = dies {
                $opt->$method(
                    $func,
                    m    => 1,
                    tol  => [1],
                    data => $data,
                )
            };
            isa_ok(
                $exception,
                ['Math::NLopt::Exception::InvalidArgs'],
                'unsupported registration throws InvalidArgs',
            );

            undef $data;
            ok( !defined( $weak_data ), 'failed registration does not retain callback data' );
            undef $func;
            ok( !defined( $weak_func ), 'failed registration does not retain the callback' );
            undef $opt;
        };
        $ast->finish;
    }
};

done_testing;
