#! perl

use v5.12;
use POSIX qw( UINT_MAX );
use Test2::V0;

use constant UINT_MAX1      => UINT_MAX + 1;
use constant CHECK_UINT_MAX => UINT_MAX1 > UINT_MAX;

use Math::NLopt qw( :algorithms :results );

subtest 'constructor' => sub {

    subtest 'dimensions' => sub {
        my @dims = ( -1, 0 );
        push @dims, UINT_MAX1 if CHECK_UINT_MAX;

        for my $dim ( @dims ) {
            subtest $dim => sub {
                my $exception = dies { Math::NLopt->new( NLOPT_LD_MMA, $dim ) };
                isa_ok( $exception, ['Math::NLopt::Exception::InvalidArgs'], 'exception class' );
                like( $exception->message, qr/must be in range/, 'message' );
            };
        }

    };

    subtest 'algorithm' => sub {
        my @algorithms = ( -1, NLOPT_NUM_ALGORITHMS );

        for my $algorithm ( @algorithms ) {
            subtest $algorithm => sub {
                my $exception = dies { Math::NLopt->new( $algorithm, 3 ) };
                isa_ok( $exception, ['Math::NLopt::Exception::InvalidArgs'], 'exception class' );
                like( $exception->message, qr/invalid algorithm/, 'message' );
            };
        }

    };

};

subtest 'optimization state has defaults before optimize' => sub {
    my $opt = Math::NLopt->new( NLOPT_LD_MMA, 2 );

    is( $opt->last_optimize_result, NLOPT_FAILURE, 'initial optimization result is failure' );

    my $value = $opt->last_optimum_value;
    # test for NaN, which is not equal to itself
    ok( $value != $value, 'initial optimum value is NaN' );
};

subtest 'string APIs' => sub {
    subtest 'algorithm_from_string' => sub {
        is( Math::NLopt::algorithm_from_string( 'LD_MMA' ), NLOPT_LD_MMA, 'accepts a string', );
        is(
            Math::NLopt::algorithm_from_string( 'NOT_AN_ALGORITHM' ),
            -1, 'returns -1 for an unknown algorithm',
        );
    };

    subtest 'algorithm_to_string' => sub {
        is( Math::NLopt::algorithm_to_string( NLOPT_LD_MMA ), 'LD_MMA', 'returns a string', );
        is(
            Math::NLopt::algorithm_to_string( NLOPT_NUM_ALGORITHMS ),
            undef, 'returns undef for an invalid algorithm',
        );
    };

    subtest 'algorithm_name' => sub {
        my $name = Math::NLopt::algorithm_name( NLOPT_LD_MMA );
        ok( defined $name && !ref $name && length $name, 'returns a nonempty string' );
        is(
            Math::NLopt::algorithm_name( NLOPT_NUM_ALGORITHMS ),
            'UNKNOWN', 'returns UNKNOWN for an invalid algorithm',
        );
    };

    subtest 'result_from_string' => sub {
        is( Math::NLopt::result_from_string( 'SUCCESS' ), NLOPT_SUCCESS, 'accepts a string', );
        is(
            Math::NLopt::result_from_string( 'NOT_A_RESULT' ),
            NLOPT_FAILURE, 'returns failure for an unknown result',
        );
    };

    subtest 'result_to_string' => sub {
        is( Math::NLopt::result_to_string( NLOPT_SUCCESS ), 'SUCCESS', 'returns a string', );
        is(
            Math::NLopt::result_to_string( NLOPT_NUM_RESULTS ),
            undef, 'returns undef for an invalid result',
        );
    };

    subtest 'optimizer parameter names' => sub {
        my $opt = Math::NLopt->new( NLOPT_LD_MMA, 1 );

        $opt->set_param( 'test_parameter', 42 );
        ok( $opt->has_param( 'test_parameter' ), 'has_param accepts a string' );
        is( $opt->get_param( 'test_parameter', 0 ), 42,               'get_param accepts a string' );
        is( $opt->nth_param( 0 ),                   'test_parameter', 'nth_param returns a string' );
    };
};

subtest 'unsigned setter ranges' => sub {
    skip_all 'Perl cannot represent a value above C unsigned maximum'
      unless CHECK_UINT_MAX;

    for my $case (
        [ set_population     => sub { $_[0]->set_population( UINT_MAX1 ) } ],
        [ set_vector_storage => sub { $_[0]->set_vector_storage( UINT_MAX1 ) } ],
      )
    {
        my ( $method, $setter ) = @{$case};
        subtest $method => sub {
            my $opt = Math::NLopt->new( NLOPT_GN_ISRES, 1 );
            isa_ok(
                dies { $setter->( $opt ) },
                ['Math::NLopt::Exception::InvalidArgs'],
                "$method rejects values above UINT_MAX",
            );
        };
    }
};

subtest 'objective setters' => sub {
    for my $method ( qw( set_min_objective set_max_objective ) ) {
        subtest $method => sub {
            my $opt  = Math::NLopt->new( NLOPT_GN_ISRES, 2 );
            my $data = { name => $method };
            my $seen;

            $opt->$method(
                sub {
                    my ( $x, $gradient, $callback_data ) = @_;
                    $seen = $callback_data;
                    return $x->[0] + $x->[1];
                },
                $data,
            );
            $opt->set_lower_bounds( [ -10, -10 ] );
            $opt->set_upper_bounds( [ 10,   10 ] );
            $opt->set_maxeval( 1 );

            ok( lives { $opt->optimize( [ 2, 2 ] ) }, 'optimization completes' );
            is( $seen, $data, 'optional data reaches the callback' );
        };
    }
};

subtest 'preconditioned objective setters' => sub {
    for my $method ( qw( set_precond_min_objective set_precond_max_objective ) ) {
        subtest $method => sub {
            my $opt            = Math::NLopt->new( NLOPT_LD_CCSAQ, 1 );
            my $objective_data = { name => "$method objective" };
            my $objective_seen;
            my $preconditioner_seen;
            my $objective_calls      = 0;
            my $preconditioner_calls = 0;

            $opt->$method(
                sub {
                    my ( $x, $gradient, $data ) = @_;
                    ++$objective_calls;
                    $objective_seen = $data;
                    $gradient->[0] = 2 * $x->[0] if $gradient;
                    return $x->[0]**2;
                },
                sub {
                    my ( $x, $v, $vpre, $data ) = @_;
                    ++$preconditioner_calls;
                    $preconditioner_seen = $data;
                    $vpre->[0] = $v->[0];
                },
                $objective_data,
            );
            $opt->set_lower_bounds( [-10] );
            $opt->set_upper_bounds( [10] );
            $opt->set_maxeval( 2 );

            ok( lives { $opt->optimize( [1] ) }, 'optimization completes' );
            ok( $objective_calls > 0,            'objective was called' );
            ok( $preconditioner_calls > 0,       'preconditioner was called' );
            is( $objective_seen,      $objective_data, 'objective data reaches the callback' );
            is( $preconditioner_seen, $objective_data, 'preconditioner sees the same data payload' );
        };
    }
};


for my $method ( qw( add_equality_mconstraint add_inequality_mconstraint ) ) {
    subtest $method => sub {
        my $func = sub {
            my ( $result ) = @_;
            @{$result} = ( 0, 0 );
        };

        subtest 'documented argument forms' => sub {
            for my $case (
                [ 'm only',    [ m   => 2 ] ],
                [ 'tol only',  [ tol => [ 1e-8, 1e-8 ] ] ],
                [ 'm and tol', [ m   => 2, tol  => [ 1e-8, 1e-8 ] ] ],
                [ 'data',      [ m   => 2, data => { name => 'constraint' } ] ],
              )
            {
                my ( $name, $args ) = @{$case};
                my $opt = Math::NLopt->new( NLOPT_GN_ISRES, 2 );

                ok( lives { $opt->$method( $func, @{$args} ) }, $name, );
            }
        };

        subtest 'runtime behavior' => sub {

            subtest 'tol-only infers the result length' => sub {
                my $opt         = Math::NLopt->new( NLOPT_GN_ISRES, 2 );
                my $calls       = 0;
                my $result_len  = 0;
                my $gradient_is = 1;

                $opt->set_min_objective(
                    sub {
                        my ( $x ) = @_;
                        return $x->[0] + $x->[1];
                    } );
                $opt->$method(
                    sub {
                        my ( $result, $x, $gradient ) = @_;
                        ++$calls;
                        $result_len  = @{$result};
                        $gradient_is = defined $gradient;
                        @{$result} = ( $x->[0] - 1, $x->[1] - 1 );
                    },
                    tol => [ 1e-8, 1e-8 ],
                );
                $opt->set_lower_bounds( [ -10, -10 ] );
                $opt->set_upper_bounds( [ 10,   10 ] );
                $opt->set_maxeval( 1 );

                ok( lives { $opt->optimize( [ 2, 2 ] ) }, 'optimization completes' );
                ok( $calls > 0,                           'constraint was called' );
                is( $result_len, 2, 'result length follows tol' );
                ok( !$gradient_is, 'gradient is not requested' );
            };

            subtest 'explicit m remains independent of problem dimension' => sub {
                my $algorithm = $method eq 'add_equality_mconstraint' ? NLOPT_LN_COBYLA : NLOPT_LD_MMA;
                for my $m ( 1, 2, 3 ) {
                    subtest "m = $m" => sub {
                        my $opt        = Math::NLopt->new( $algorithm, 2 );
                        my $result_len = 0;

                        $opt->set_min_objective(
                            sub {
                                my ( $x ) = @_;
                                return $x->[0]**2 + $x->[1]**2;
                            } );
                        $opt->$method(
                            sub {
                                my ( $result, $x, $gradient ) = @_;
                                $result_len = @{$result};
                                @{$result}   = map { $x->[0] + $x->[1] - $_ } 1 .. $m;
                                @{$gradient} = map { [ 1, 1 ] } 1 .. $m if $gradient;
                            },
                            m   => $m,
                            tol => [ ( 1e-8 ) x $m ],
                        );
                        $opt->set_maxeval( 1 );

                        ok( lives { $opt->optimize( [ 2, 2 ] ) }, 'optimization completes' );
                        is( $result_len, $m, 'result length follows m' );
                    };
                }
            };

            subtest 'callback data is passed through' => sub {
                my $opt  = Math::NLopt->new( NLOPT_GN_ISRES, 2 );
                my $data = { name => 'constraint' };
                my $seen;

                $opt->set_min_objective(
                    sub {
                        my ( $x ) = @_;
                        return $x->[0] + $x->[1];
                    } );
                $opt->$method(
                    sub {
                        my ( $result, $x, $gradient, $callback_data ) = @_;
                        $seen = $callback_data;
                        @{$result} = ( $x->[0] - 1, $x->[1] - 1 );
                    },
                    m    => 2,
                    data => $data,
                );
                $opt->set_lower_bounds( [ -10, -10 ] );
                $opt->set_upper_bounds( [ 10,   10 ] );
                $opt->set_maxeval( 1 );

                ok( lives { $opt->optimize( [ 2, 2 ] ) }, 'optimization completes' );
                is( $seen, $data, 'optional data reaches the callback' );
            };

            subtest 'gradient remains undef for derivative-free algorithms' => sub {
                my $opt            = Math::NLopt->new( NLOPT_GN_ISRES, 2 );
                my $gradient_undef = 0;

                $opt->set_min_objective(
                    sub {
                        my ( $x ) = @_;
                        return $x->[0] + $x->[1];
                    } );
                $opt->$method(
                    sub {
                        my ( $result, $x, $gradient ) = @_;
                        $gradient_undef = !defined $gradient;
                        @{$result} = ( $x->[0] - 1, $x->[1] - 1 );
                    },
                    m   => 2,
                    tol => [ 1e-8, 1e-8 ],
                );
                $opt->set_lower_bounds( [ -10, -10 ] );
                $opt->set_upper_bounds( [ 10,   10 ] );
                $opt->set_maxeval( 1 );

                ok( lives { $opt->optimize( [ 2, 2 ] ) }, 'optimization completes' );
                ok( $gradient_undef,                      'gradient is not requested' );
            };
        };


        subtest 'invalid arguments' => sub {
            my @cases = (
                [ 'missing m and tol',    [$func], 'Math::NLopt::Exception::MissingParameter' ],
                [ 'non-coderef callback', [ 'not a callback', m => 2 ],    'Math::NLopt::Exception::InvalidArgs' ],
                [ 'unknown option',       [ $func, m => 2, unknown => 1 ], 'Math::NLopt::Exception::InvalidArgs' ],
                [ 'positional option',    [ $func, 2, undef ],             'Math::NLopt::Exception::InvalidArgs' ],
                [ 'option without value', [ $func, m => 2, 'tol' ],        'Math::NLopt::Exception::InvalidArgs' ],
                [ 'tol is not an arrayref',   [ $func, tol => 1e-8 ],  'Math::NLopt::Exception::InvalidArgs' ],
                [ 'm is fractional',          [ $func, m   => 1.5 ],   'Math::NLopt::Exception::InvalidArgs' ],
                [ 'm is a fractional string', [ $func, m   => '2.5' ], 'Math::NLopt::Exception::InvalidArgs' ],
                [ 'm is nonnumeric',          [ $func, m   => 'two' ], 'Math::NLopt::Exception::InvalidArgs' ],
                [ 'm is a reference',         [ $func, m   => [] ],    'Math::NLopt::Exception::InvalidArgs' ],
                [ 'm < 1',                    [ $func, m   => 0 ],     'Math::NLopt::Exception::InvalidArgs' ],
                (
                    CHECK_UINT_MAX
                    ? ( [ 'm too large', [ $func, m => UINT_MAX1 ], 'Math::NLopt::Exception::InvalidArgs' ] )
                    : (),
                ),
                [
                    'm does not match tol length',
                    [ $func, m => 1, tol => [ 1e-8, 1e-8 ] ],
                    'Math::NLopt::Exception::InvalidArgs'
                ],
            );

            for my $case ( @cases ) {
                my ( $name, $args, $exception ) = @{$case};
                subtest $name => sub {
                    isa_ok( dies { Math::NLopt->new( NLOPT_GN_ISRES, 2 )->$method( @{$args} ) }, $exception );
                };
            }
        };
    };
}

for my $method ( qw( add_equality_constraint add_inequality_constraint ) ) {
    subtest $method => sub {
        my $func = sub {
            my ( $x ) = @_;
            return $x->[0];
        };

        subtest 'documented argument forms' => sub {
            for my $case (
                [ 'no options',   [] ],
                [ 'tol',          [ tol  => 1e-8 ] ],
                [ 'data',         [ data => { name => 'constraint' } ] ],
                [ 'tol and data', [ tol  => 1e-8, data => { name => 'constraint' } ] ],
              )
            {
                my ( $name, $args ) = @{$case};
                my $opt = Math::NLopt->new( NLOPT_GN_ISRES, 2 );

                ok( lives { $opt->$method( $func, @{$args} ) }, $name, );
            }
        };

        subtest 'invalid arguments' => sub {
            my @cases = (
                [ 'non-coderef callback', ['not a callback'],       'Math::NLopt::Exception::InvalidArgs' ],
                [ 'unknown option',       [ $func, unknown => 1 ],  'Math::NLopt::Exception::InvalidArgs' ],
                [ 'positional option',    [ $func, 1e-8, undef ],   'Math::NLopt::Exception::InvalidArgs' ],
                [ 'option without value', [ $func, 'tol' ],         'Math::NLopt::Exception::InvalidArgs' ],
                [ 'tol is a reference',   [ $func, tol => [1e-8] ], 'Math::NLopt::Exception::InvalidArgs' ],
            );

            for my $case ( @cases ) {
                my ( $name, $args, $exception ) = @{$case};
                subtest $name => sub {
                    isa_ok( dies { Math::NLopt->new( NLOPT_GN_ISRES, 2 )->$method( @{$args} ) }, $exception );
                };
            }
        };
    };
}

subtest 'validate length of Perl arrays passed to NLopt' => sub {

    my $opt = Math::NLopt->new( NLOPT_GN_ISRES, 2 );

    subtest 'invalid arguments' => sub {
        my @methods = qw(
          optimize
          set_initial_step
          get_initial_step
          set_lower_bounds
          set_upper_bounds
          set_x_weights
          set_xtol_abs
        );

        for my $length ( qw( short long ) ) {
            my @args = $length eq 'short' ? ( 1 ) : ( 1 .. 3 );
            for my $method ( @methods ) {
                subtest "$method ($length)" => sub {
                    isa_ok( dies { Math::NLopt->new( NLOPT_GN_ISRES, 2 )->$method( \@args ) },
                        ['Math::NLopt::Exception::InvalidDimensions'] );
                };
            }
        }
    };

};

subtest 'callback output lengths' => sub {
    for my $case (
        [ 'no objective return value',        sub { return; } ],
        [ 'multiple objective return values', sub { return ( 1, 2 ); } ],
      )
    {
        my ( $name, $callback ) = @{$case};
        subtest $name => sub {
            my $opt = Math::NLopt->new( NLOPT_LD_MMA, 2 );
            $opt->set_min_objective( $callback );
            $opt->set_lower_bounds( [ -10, -10 ] );
            $opt->set_upper_bounds( [ 10,   10 ] );
            $opt->set_maxeval( 1 );

            my $exception = dies { $opt->optimize( [ 1, 1 ] ) };
            isa_ok( $exception, ['Math::NLopt::Exception::InvalidReturn'], 'invalid return exception class' );
            is( $opt->last_optimize_result, NLOPT_FORCED_STOP, 'invalid return forces stop' );
        };
    }

    for my $length ( qw( short long ) ) {
        subtest "objective gradient is $length" => sub {
            my $opt = Math::NLopt->new( NLOPT_LD_MMA, 2 );
            $opt->set_min_objective(
                sub {
                    my ( $x, $gradient ) = @_;
                    @{$gradient} = $length eq 'short' ? ( 1 ) : ( 1, 1, 1 )
                      if $gradient;
                    return $x->[0] + $x->[1];
                } );
            $opt->set_lower_bounds( [ -10, -10 ] );
            $opt->set_upper_bounds( [ 10,   10 ] );
            $opt->set_maxeval( 1 );

            my $exception = dies { $opt->optimize( [ 1, 1 ] ) };
            isa_ok(
                $exception,
                ['Math::NLopt::Exception::InvalidDimensions'],
                'invalid gradient exception class'
            );
            is( $opt->last_optimize_result, NLOPT_FORCED_STOP, 'invalid gradient forces stop' );
        };
    }

    for my $method ( qw( add_equality_mconstraint add_inequality_mconstraint ) ) {
        my $algorithm = $method eq 'add_equality_mconstraint' ? NLOPT_LD_SLSQP : NLOPT_LD_MMA;

        for my $length ( qw( short long ) ) {
            subtest "$method result is $length" => sub {
                my $opt = Math::NLopt->new( $algorithm, 2 );
                $opt->set_min_objective( sub { 0 } );
                $opt->$method(
                    sub {
                        my ( $result ) = @_;
                        @{$result} = $length eq 'short' ? ( 0 ) : ( 0, 0, 0 );
                    },
                    m   => 2,
                    tol => [ 1e-8, 1e-8 ],
                );
                $opt->set_maxeval( 1 );

                my $exception = dies { $opt->optimize( [ 1, 1 ] ) };
                isa_ok(
                    $exception,
                    ['Math::NLopt::Exception::InvalidDimensions'],
                    'invalid result exception class'
                );
                is( $opt->last_optimize_result, NLOPT_FORCED_STOP, 'invalid result forces stop' );
            };

            subtest "$method gradient is $length" => sub {
                my $opt = Math::NLopt->new( $algorithm, 2 );
                $opt->set_min_objective( sub { 0 } );
                $opt->$method(
                    sub {
                        my ( $result, $x, $gradient ) = @_;
                        @{$result} = ( 0, 0 );
                        @{$gradient}
                          = $length eq 'short'
                          ? ( [ 1, 1 ] )
                          : ( [ 1, 1 ], [ 1, 1 ], [ 1, 1 ] )
                          if $gradient;
                    },
                    m   => 2,
                    tol => [ 1e-8, 1e-8 ],
                );
                $opt->set_maxeval( 1 );

                my $exception = dies { $opt->optimize( [ 1, 1 ] ) };
                isa_ok(
                    $exception,
                    ['Math::NLopt::Exception::InvalidDimensions'],
                    'invalid gradient exception class'
                );
                is( $opt->last_optimize_result, NLOPT_FORCED_STOP, 'invalid gradient forces stop' );
            };
        }
    }

    for my $length ( qw( short long ) ) {
        subtest "preconditioner output is $length" => sub {
            my $opt                  = Math::NLopt->new( NLOPT_LD_CCSAQ, 2 );
            my $preconditioner_calls = 0;
            $opt->set_precond_min_objective(
                sub {
                    my ( $x, $gradient ) = @_;
                    $gradient->[0] = 2 * $x->[0];
                    $gradient->[1] = 2 * $x->[1];
                    return $x->[0]**2 + $x->[1]**2;
                },
                sub {
                    my ( $x, $v, $vpre ) = @_;
                    ++$preconditioner_calls;
                    @{$vpre} = $length eq 'short' ? ( 1 ) : ( 1, 1, 1 );
                },
            );
            $opt->set_lower_bounds( [ -10, -10 ] );
            $opt->set_upper_bounds( [ 10,   10 ] );
            $opt->set_maxeval( 2 );

            my $exception = dies { $opt->optimize( [ 2, 2 ] ) };
            isa_ok(
                $exception,
                ['Math::NLopt::Exception::InvalidDimensions'],
                'invalid preconditioner exception class'
            );
            is( $opt->last_optimize_result, NLOPT_FORCED_STOP, 'invalid preconditioner forces stop' );
            ok( $preconditioner_calls > 0, 'preconditioner was called' );
        };
    }
};

subtest 'vector constraint gradient is an m by n array' => sub {
    my $opt = Math::NLopt->new( NLOPT_LD_MMA, 2 );
    my ( $gradient_m, $gradient_n );

    $opt->set_min_objective( sub { 0 } );
    $opt->add_inequality_mconstraint(
        sub {
            my ( $result, $x, $gradient ) = @_;
            $gradient_m = @{$gradient};
            $gradient_n = [ map { scalar @{$_} } @{$gradient} ];
            @{$result}   = ( 0, 0 );
            @{$gradient} = ( [ 1, 0 ], [ 0, 1 ] );
        },
        m   => 2,
        tol => [ 1e-8, 1e-8 ],
    );
    $opt->set_maxeval( 1 );

    ok( lives { $opt->optimize( [ 1, 1 ] ) }, 'optimization completes' );
    is( $gradient_m, 2,        'gradient outer dimension is m' );
    is( $gradient_n, [ 2, 2 ], 'gradient inner dimension is n' );
};

subtest 'vector constraint tolerance lengths' => sub {
    for my $method ( qw( _add_equality_mconstraint _add_inequality_mconstraint ) ) {
        for my $length ( qw( short long ) ) {
            subtest "$method rejects $length tolerance arrays" => sub {
                my $opt  = Math::NLopt->new( NLOPT_GN_ISRES, 2 );
                my $func = sub { };
                my $tol  = $length eq 'short' ? [1e-8] : [ 1e-8, 1e-8, 1e-8 ];

                isa_ok(
                    dies { $opt->$method( $func, 2, $tol, undef ) },
                    ['Math::NLopt::Exception::InvalidDimensions'],
                    'mismatched tolerance length throws an exception object',
                );
            };
        }
    }
};

done_testing;
