#! perl

use v5.12;
use Test2::V0;
use Scalar::Util 'weaken';

use Math::NLopt qw(
  NLOPT_LD_CCSAQ
  NLOPT_GN_ISRES
  NLOPT_LN_SBPLX
  NLOPT_FORCED_STOP
);

# Callbacks are compiled in a separate lexical scope.   If they
# are compiled directly in the test routine's scope, they seem
# to linger and still keep the weak references alive even
# when the strong reference is destroyed

for my $method ( qw( set_min_objective set_max_objective ) ) {
    subtest $method => sub {
        my $opt           = Math::NLopt->new( NLOPT_GN_ISRES, 2 );
        my $calls         = 0;
        my $data_is_valid = 0;

        my $objective = sub {
            my ( $x, $gradient, $callback_data ) = @_;
            ++$calls;
            $data_is_valid = ref( $callback_data ) eq 'HASH'
              && $callback_data->{name} eq $method;
            return $method eq 'set_min_objective'
              ? $x->[0] + $x->[1]
              : -$x->[0] - $x->[1];
        };
        my $data = { name => $method };

        $opt->$method( $objective, $data );
        undef $objective;
        undef $data;

        $opt->set_lower_bounds( [ -10, -10 ] );
        $opt->set_upper_bounds( [ 10,   10 ] );
        $opt->set_maxeval( 1 );

        ok( lives { $opt->optimize( [ 1, 1 ] ) }, 'optimization completes' );
        ok( $calls > 0,                           'objective was called' );
        ok( $data_is_valid,                       'objective received valid callback data' );
    };

    subtest "$method replacement" => sub {
        my $opt = Math::NLopt->new( NLOPT_GN_ISRES, 2 );

        my $weak_callback = my $callback = eval q{
            sub {
                my ( $x, $gradient, $callback_data ) = @_;
                return $x->[0] + $x->[1];
            }
        };
        my $weak_data = my $data = { name => "$method replacement" };
        weaken( $weak_callback );
        weaken( $weak_data );

        $opt->$method( $callback, $data );
        undef $callback;
        undef $data;

        ok( defined( $weak_callback ), 'active callback is retained' );
        ok( defined( $weak_data ),     'active callback data is retained' );

        $opt->$method( sub { 0 } );

        ok( !defined( $weak_callback ), 'replaced callback is released immediately' );
        ok( !defined( $weak_data ),     'replaced callback data is released immediately' );
        is( $opt->get_dimension, 2, 'optimizer remains alive after objective replacement' );
    };

    subtest "$method replaces a preconditioned objective" => sub {
        my $opt = Math::NLopt->new( NLOPT_LD_CCSAQ, 1 );

        my $weak_objective = my $objective = eval q{
            sub {
                my ( $x, $gradient, $data ) = @_;
                return $x->[0]**2;
            }
        };
        my $weak_preconditioner = my $preconditioner = eval q{
            sub {
                my ( $x, $v, $vpre, $data ) = @_;
                $vpre->[0] = $v->[0];
            }
        };
        my $weak_data = my $data = { name => 'preconditioned objective' };
        weaken( $weak_objective );
        weaken( $weak_preconditioner );
        weaken( $weak_data );

        $opt->set_precond_min_objective( $objective, $preconditioner, $data );
        undef $objective;
        undef $preconditioner;
        undef $data;

        $opt->$method( sub { 0 } );

        ok( !defined( $weak_objective ),      'replaced objective is released' );
        ok( !defined( $weak_preconditioner ), 'replaced preconditioner is released' );
        ok( !defined( $weak_data ),           'replaced callback data is released' );
        is( $opt->get_dimension, 1, 'optimizer remains alive after cross-family replacement' );
    };
}

subtest 'temporary callback data survives until invocation' => sub {
    my $opt;

    # Keep an anonymous data temporary alive through registration and until
    # NLopt invokes the objective callback.
    my $objective = sub {
        my ( $x, $gradient, $data ) = @_;
        my $force_stop = ref( $data ) eq 'HASH' && $data->{a} == 3 ? 1 : 2;
        $opt->set_force_stop( $force_stop );
    };

    $opt = Math::NLopt->new( NLOPT_LN_SBPLX, 1 );
    $opt->set_min_objective( $objective, { a => 3 } );

    eval { $opt->optimize( [0] ) };

    is( $opt->last_optimize_result, NLOPT_FORCED_STOP, 'temporary data callback stopped optimization' );
    is( $opt->get_force_stop,       1,                 'temporary callback data survived' );
};

done_testing;
