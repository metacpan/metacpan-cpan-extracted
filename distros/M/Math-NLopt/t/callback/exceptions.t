#! perl

use v5.12;
use Test2::Require::RealFork;
use Test2::V0;
use Test2::Tools::AsyncSubtest 'fork_subtest';
use Scalar::Util 'weaken';

use Math::NLopt qw(
  NLOPT_LD_CCSAQ
  NLOPT_LD_AUGLAG
  NLOPT_LD_MMA
  NLOPT_LD_SLSQP
  NLOPT_FORCED_STOP
);
use Math::NLopt::Exception;

## no critic (StringyEval Ambiguous)

# Callback exceptions must not unwind through NLopt's C stack. The XS
# callback proxies catch them, request a forced stop, and rethrow them after
# optimize returns. These tests verify exception identity and messages,
# forced-stop state, recovery, cleanup, and edge-case exception values.
# Each case runs in a real fork because a throw at the callback boundary
# must not terminate or corrupt the main test process.

sub run_in_fork {
    my ( $name, $code ) = @_;
    my $ast = fork_subtest $name => $code;
    $ast->finish;
}

#==================================================================================
# Exceptions in Objective callbacks

# default,
for my $method ( qw( set_min_objective set_max_objective ) ) {
    run_in_fork "$method exception is rethrown and recoverable" => sub {
        my $opt     = Math::NLopt->new( NLOPT_LD_MMA, 2 );
        my $calls   = 0;
        my $message = "objective $method callback threw";

        $opt->$method(
            sub {
                my ( $x, $gradient ) = @_;
                ++$calls == 1 and die Math::NLopt::Exception::ForcedStop->new( $message );
                $gradient and @{$gradient} = ( 2 * $x->[0], 2 * $x->[1] );
                return $x->[0]**2 + $x->[1]**2;
            } );
        $opt->set_maxeval( 2 );

        my $exception = dies { $opt->optimize( [ 2, 2 ] ) };
        isa_ok( $exception, ['Math::NLopt::Exception::ForcedStop'], 'objective exception class' );
        is( $exception->message,        $message,          'objective exception message' );
        is( $opt->last_optimize_result, NLOPT_FORCED_STOP, 'objective forces stop' );
        ok( $calls > 0,                           'objective was called before the exception' );
        ok( lives { $opt->optimize( [ 2, 2 ] ) }, 'optimizer remains usable' );
        ok( $calls > 1,                           'objective was called again after recovery' );
    };
}

# now check behavior when disabling exceptions; should still die
run_in_fork 'exceptions propagate with optimizer exceptions disabled' => sub {
    my $opt     = Math::NLopt->new( NLOPT_LD_MMA, 2 );
    my $message = 'objective callback threw with optimizer exceptions disabled';

    $opt->set_min_objective( sub { die Math::NLopt::Exception::ForcedStop->new( $message ) } );
    $opt->set_exceptions_enabled( 0 );

    my $exception = dies { $opt->optimize( [ 2, 2 ] ) };
    isa_ok( $exception, ['Math::NLopt::Exception::ForcedStop'], 'exception class' );
    is( $exception->message,        $message,          'exception message' );
    is( $opt->last_optimize_result, NLOPT_FORCED_STOP, 'callback forces stop' );
};

# Preconditioner callbacks use a separate XS callback path.
for my $method ( qw( set_precond_min_objective set_precond_max_objective ) ) {
    run_in_fork "$method preconditioner exception is rethrown and recoverable" => sub {
        my $opt       = Math::NLopt->new( NLOPT_LD_CCSAQ, 2 );
        my $pre_calls = 0;
        my $message   = "preconditioner $method callback threw";

        $opt->$method(
            sub {
                my ( $x, $gradient ) = @_;
                $gradient and @{$gradient} = ( 2 * $x->[0], 2 * $x->[1] );
                return $x->[0]**2 + $x->[1]**2;
            },
            sub {
                my ( $x, $v, $vpre ) = @_;
                ++$pre_calls == 1 and die Math::NLopt::Exception::ForcedStop->new( $message );
                @{$vpre} = ( $v->[0], $v->[1] );
            },
        );
        $opt->set_maxeval( 2 );

        my $exception = dies { $opt->optimize( [ 2, 2 ] ) };
        isa_ok( $exception, ['Math::NLopt::Exception::ForcedStop'], 'preconditioner exception class' );
        is( $exception->message,        $message,          'preconditioner exception message' );
        is( $opt->last_optimize_result, NLOPT_FORCED_STOP, 'preconditioner forces stop' );
        ok( $pre_calls > 0,                       'preconditioner was called before the exception' );
        ok( lives { $opt->optimize( [ 2, 2 ] ) }, 'optimizer remains usable' );
        ok( $pre_calls > 1,                       'preconditioner was called again after recovery' );
    };
}

# Scalar and vector constraint callbacks must be tested individually
for my $kind ( qw( equality inequality ) ) {
    my $method    = "add_${kind}_constraint";
    my $algorithm = { equality => NLOPT_LD_SLSQP, inequality => NLOPT_LD_MMA }->{$kind};

    run_in_fork "$method exception is rethrown and recoverable" => sub {
        my $opt     = Math::NLopt->new( $algorithm, 2 );
        my $calls   = 0;
        my $message = "scalar $kind constraint callback threw";

        $opt->set_min_objective( sub { my ( $x ) = @_; $x->[0]**2 + $x->[1]**2 } );
        $opt->$method(
            sub {
                my ( $x, $gradient ) = @_;
                ++$calls == 1 and die Math::NLopt::Exception::ForcedStop->new( $message );
                $gradient and @{$gradient} = ( 2 * $x->[0], 2 * $x->[1] );
                return $x->[0] + $x->[1] - 1;
            } );
        $opt->set_maxeval( 2 );

        my $exception = dies { $opt->optimize( [ 2, 2 ] ) };
        isa_ok( $exception, ['Math::NLopt::Exception::ForcedStop'], 'scalar constraint exception class' );
        is( $exception->message,        $message,          'scalar constraint exception message' );
        is( $opt->last_optimize_result, NLOPT_FORCED_STOP, 'scalar constraint forces stop' );
        ok( $calls > 0,                           'scalar constraint was called before the exception' );
        ok( lives { $opt->optimize( [ 2, 2 ] ) }, 'optimizer remains usable' );
        ok( $calls > 1,                           'scalar constraint was called again after recovery' );
    };
}

for my $kind ( qw( equality inequality ) ) {
    my $method    = "add_${kind}_mconstraint";
    my $algorithm = { equality => NLOPT_LD_SLSQP, inequality => NLOPT_LD_MMA }->{$kind};

    run_in_fork "$method exception is rethrown and recoverable" => sub {
        my $opt     = Math::NLopt->new( $algorithm, 2 );
        my $calls   = 0;
        my $message = "vector $kind constraint callback threw";

        $opt->set_min_objective( sub { my ( $x ) = @_; $x->[0]**2 + $x->[1]**2 } );
        $opt->$method(
            sub {
                my ( $result, $x, $gradient ) = @_;
                ++$calls == 1 and die Math::NLopt::Exception::ForcedStop->new( $message );
                $result->[0] = $x->[0] + $x->[1] - 1;
                $gradient and @{$gradient} = ( [ 1, 1 ] );
            },
            m   => 1,
            tol => [1e-8],
        );
        $opt->set_maxeval( 2 );

        my $exception = dies { $opt->optimize( [ 2, 2 ] ) };
        isa_ok( $exception, ['Math::NLopt::Exception::ForcedStop'], 'vector constraint exception class' );
        is( $exception->message,        $message,          'vector constraint exception message' );
        is( $opt->last_optimize_result, NLOPT_FORCED_STOP, 'vector constraint forces stop' );
        ok( $calls > 0,                           'vector constraint was called before the exception' );
        ok( lives { $opt->optimize( [ 2, 2 ] ) }, 'optimizer remains usable' );
        ok( $calls > 1,                           'vector constraint was called again after recovery' );
    };
}

#=================================================================================
# callbacks which threw must release their retained  data.

# Callbacks are compiled in a separate lexical scope.   If they
# are compiled directly in the test routine's scope, they seem
# to linger and still keep the weak references alive even
# when the strong reference is destroyed


subtest 'callback and data are released after an exception' => sub {
    my $assert_released = sub {
        my ( $opt_ref, $callback_ref, $data_ref ) = @_;
        my $weak_callback = $$callback_ref;
        my $weak_data     = $$data_ref;
        weaken( $weak_callback );
        weaken( $weak_data );

        ok( dies { $$opt_ref->optimize( [ 2, 2 ] ) }, 'exception is caught' );

        undef $$callback_ref;
        undef $$data_ref;
        undef $$opt_ref;
        ok( !defined( $weak_callback ), 'callback is released after exception' );
        ok( !defined( $weak_data ),     'callback data is released after exception' );
    };

    subtest 'objective callback' => sub {
        run_in_fork 'objective callback cleanup' => sub {
            my $opt      = Math::NLopt->new( NLOPT_LD_MMA, 2 );
            my $data     = { calls => 0 };
            my $callback = eval q{
                sub {
                    my ( $x, $gradient, $data ) = @_;
                    ++$data->{calls} == 1
                      and die Math::NLopt::Exception::ForcedStop->new('cleanup objective');
                    return 0;
                }
            } or die;
            $opt->set_min_objective( $callback, $data );
            $assert_released->( \$opt, \$callback, \$data );
        };
    };

    subtest 'preconditioner callback' => sub {
        run_in_fork 'preconditioner callback cleanup' => sub {
            my $opt      = Math::NLopt->new( NLOPT_LD_CCSAQ, 2 );
            my $data     = { calls => 0 };
            my $callback = eval q{
                sub {
                    my ( $x, $v, $vpre, $data ) = @_;
                    ++$data->{calls} == 1
                      and die Math::NLopt::Exception::ForcedStop->new('cleanup preconditioner');
                }
            } or die;
            my $objective = sub {
                my ( $x, $gradient ) = @_;
                $gradient and @{$gradient} = ( 2 * $x->[0], 2 * $x->[1] );
                return $x->[0]**2 + $x->[1]**2;
            };
            $opt->set_precond_min_objective( $objective, $callback, $data );
            $assert_released->( \$opt, \$callback, \$data );
        };
    };

    subtest 'scalar constraint callback' => sub {
        run_in_fork 'scalar constraint callback cleanup' => sub {
            my $opt      = Math::NLopt->new( NLOPT_LD_MMA, 2 );
            my $data     = { calls => 0 };
            my $callback = eval q{
                sub {
                    my ( $x, $gradient, $data ) = @_;
                    ++$data->{calls} == 1
                      and die Math::NLopt::Exception::ForcedStop->new('cleanup scalar');
                    return 0;
                }
            } or die;
            $opt->set_min_objective( sub { 0 } );
            $opt->add_inequality_constraint( $callback, data => $data );
            $assert_released->( \$opt, \$callback, \$data );
        };
    };

    subtest 'vector constraint callback' => sub {
        run_in_fork 'vector constraint callback cleanup' => sub {
            my $opt      = Math::NLopt->new( NLOPT_LD_MMA, 2 );
            my $data     = { calls => 0 };
            my $callback = eval q{
                sub {
                    my ( $result, $x, $gradient, $data ) = @_;
                    ++$data->{calls} == 1
                      and die Math::NLopt::Exception::ForcedStop->new('cleanup vector');
                    $result->[0] = 0;
                }
            } or die;
            $opt->set_min_objective( sub { 0 } );
            $opt->add_inequality_mconstraint( $callback, m => 1, tol => [1e-8], data => $data );
            $assert_released->( \$opt, \$callback, \$data );
        };
    };
};

# A later optimization must preserve its own exception rather than rethrowing
# the exception saved by an earlier optimization.
subtest 'repeated callback exceptions are captured independently' => sub {

    my $assert_repeated = sub {
        my ( $opt, $messages ) = @_;
        my $ctx = context();

        subtest 'first' => sub {
            my $exception = dies { $opt->optimize( [ 2, 2 ] ) };
            isa_ok( $exception, ['Math::NLopt::Exception::ForcedStop'], 'class' );
            is( $exception->message,        $messages->[0],    'preserved' );
            is( $opt->last_optimize_result, NLOPT_FORCED_STOP, 'result is forced stop' );
        };

        subtest 'second' => sub {
            # The first optimization may invoke a callback more than once,
            # especially when the callback is a preconditioner.  We want
            # to start comparisons with the next set of messages.
            my $message_index = @{$messages};
            my $exception     = dies { $opt->optimize( [ 2, 2 ] ) };
            isa_ok( $exception, ['Math::NLopt::Exception::ForcedStop'], 'class' );
            ok( grep { $_ eq $exception->message } @{$messages}[ $message_index .. $#{$messages} ],
                'preserved independently' );
            isnt( $exception->message, $messages->[0], 'is not stale' );
            is( $opt->last_optimize_result, NLOPT_FORCED_STOP, 'result is forced stop' );
        };
        $ctx->release;
    };

    subtest 'objective callback' => sub {
        run_in_fork 'repeated objective exceptions' => sub {
            my $opt = Math::NLopt->new( NLOPT_LD_MMA, 2 );
            my @messages;
            my $callback = sub {
                my $message = 'objective throws ' . ( @messages + 1 );
                push @messages, $message;
                die Math::NLopt::Exception::ForcedStop->new( $message );
            };
            $opt->set_min_objective( $callback );
            $assert_repeated->( $opt, \@messages );
        };
    };

    subtest 'preconditioner callback' => sub {
        run_in_fork 'repeated preconditioner exceptions' => sub {
            my $opt = Math::NLopt->new( NLOPT_LD_CCSAQ, 2 );
            my @messages;
            my $callback = sub {
                my $message = 'preconditioner throws ' . ( @messages + 1 );
                push @messages, $message;
                die Math::NLopt::Exception::ForcedStop->new( $message );
            };
            $opt->set_precond_min_objective(
                sub {
                    my ( $x, $gradient ) = @_;
                    $gradient and @{$gradient} = ( 2 * $x->[0], 2 * $x->[1] );
                    return $x->[0]**2 + $x->[1]**2;
                },
                $callback,
            );
            $opt->set_maxeval( 2 );
            $assert_repeated->( $opt, \@messages );
        };
    };

    subtest 'scalar constraint callback' => sub {
        run_in_fork 'scalar constraint exceptions' => sub {
            my $opt = Math::NLopt->new( NLOPT_LD_MMA, 2 );
            my @messages;
            my $callback = sub {
                my $message = 'scalar throws ' . ( @messages + 1 );
                push @messages, $message;
                die Math::NLopt::Exception::ForcedStop->new( $message );
            };
            $opt->set_min_objective( sub { 0 } );
            $opt->add_inequality_constraint( $callback );
            $assert_repeated->( $opt, \@messages );
        };
    };

    subtest 'vector constraint callback' => sub {
        run_in_fork 'vector constraint exceptions' => sub {
            my $opt = Math::NLopt->new( NLOPT_LD_MMA, 2 );
            my @messages;
            my $callback = sub {
                my $message = 'vector throws ' . ( @messages + 1 );
                push @messages, $message;
                die Math::NLopt::Exception::ForcedStop->new( $message );
            };
            $opt->set_min_objective( sub { 0 } );
            $opt->add_inequality_mconstraint( $callback, m => 1, tol => [1e-8] );
            $assert_repeated->( $opt, \@messages );
        };
    };
};

# exceptions must also cross nested optimizer calls correctly.
run_in_fork 'nested optimizer preserves exception and forced-stop status' => sub {
    my $opt     = Math::NLopt->new( NLOPT_LD_AUGLAG, 2 );
    my $local   = Math::NLopt->new( NLOPT_LD_MMA,    2 );
    my $calls   = 0;
    my $message = 'nested objective callback threw';

    $opt->set_local_optimizer( $local );
    $opt->set_min_objective(
        sub {
            my ( $x, $gradient ) = @_;
            ++$calls == 1 and die Math::NLopt::Exception::ForcedStop->new( $message );
            $gradient and @{$gradient} = ( 2 * $x->[0], 2 * $x->[1] );
            return $x->[0]**2 + $x->[1]**2;
        } );
    my $exception = dies { $opt->optimize( [ 2, 2 ] ) };
    isa_ok( $exception, ['Math::NLopt::Exception::ForcedStop'], 'nested exception class' );
    is( $exception->message, $message, 'nested exception message' );
    ok( $calls > 0, 'nested objective was called' );
    is( $opt->last_optimize_result, NLOPT_FORCED_STOP, 'nested result is forced stop' );
};

# Exercise exception objects with unusual boolean/string overloads, as well as
# plain string exceptions.
{
    package Math::NLopt::Test::FalseBoolException;
    use overload
      bool     => sub { 0 },
      '""'     => sub { ${ $_[0] } },
      fallback => 1;

    sub new {
        my ( $class, $message ) = @_;
        return bless \$message, $class;
    }

    sub message { ${ $_[0] } }
}

for my $case ( [
        'false boolean exception object',
        Math::NLopt::Test::FalseBoolException->new( 'false boolean class' ),
        'Math::NLopt::Test::FalseBoolException',
        'false boolean class',
    ],
    [
        'empty string exception message',     Math::NLopt::Exception::ForcedStop->new( q{} ),
        'Math::NLopt::Exception::ForcedStop', q{},
    ],
    [ 'empty string exception', "\n", undef, "\n", ],
  )
{
    my ( $name, $thrown, $class, $message ) = @{$case};
    run_in_fork "$name is preserved" => sub {
        my $opt = Math::NLopt->new( NLOPT_LD_MMA, 2 );
        $opt->set_min_objective( sub { die $thrown } );
        # Capture directly so Test2 does not warn about the deliberately
        # false boolean overload on the exception object.
        eval { $opt->optimize( [ 2, 2 ] ); 1; } and die;
        my $exception = $@;
        if ( defined $class ) {
            isa_ok( $exception, [$class], 'class' );
            is( $exception->message, $message, 'message' );
        }
        else {
            is( $exception, $message, 'string exception is preserved' );
        }
    };
}

done_testing;
