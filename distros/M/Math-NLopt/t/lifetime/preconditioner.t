#! perl

use v5.12;
use Test2::V0;
use Scalar::Util 'weaken';

use Math::NLopt qw(
  NLOPT_LD_CCSAQ
);

# Callbacks are compiled in a separate lexical scope.   If they
# are compiled directly in the test routine's scope, they seem
# to linger and still keep the weak references alive even
# when the strong reference is destroyed

for my $method ( qw( set_precond_min_objective set_precond_max_objective ) ) {
    subtest $method => sub {
        my $opt                  = Math::NLopt->new( NLOPT_LD_CCSAQ, 1 );
        my $objective_calls      = 0;
        my $preconditioner_calls = 0;
        my $data_is_valid        = 0;

        my $objective = sub {
            my ( $x, $gradient, $callback_data ) = @_;
            ++$objective_calls;
            $data_is_valid = ref( $callback_data ) eq 'HASH'
              && $callback_data->{name} eq $method;
            $gradient->[0] = 2 * $x->[0] if $gradient;
            return $method eq 'set_precond_min_objective' ? $x->[0]**2 : -$x->[0]**2;
        };
        my $preconditioner = sub {
            my ( $x, $v, $vpre, $callback_data ) = @_;
            ++$preconditioner_calls;
            $vpre->[0] = $v->[0];
        };
        my $data = { name => $method };

        $opt->$method( $objective, $preconditioner, $data );
        undef $objective;
        undef $preconditioner;
        undef $data;

        $opt->set_lower_bounds( [-10] );
        $opt->set_upper_bounds( [10] );
        $opt->set_maxeval( 2 );

        ok( lives { $opt->optimize( [1] ) }, 'preconditioned optimization completes' );
        ok( $objective_calls > 0,            'objective was called' );
        ok( $preconditioner_calls > 0,       'preconditioner was called' );
        ok( $data_is_valid,                  'objective received valid callback data' );
    };

    subtest "$method replacement" => sub {
        my $opt = Math::NLopt->new( NLOPT_LD_CCSAQ, 1 );

        my $weak_objective = my $objective = eval q{
            sub {
                my ( $x, $gradient, $callback_data ) = @_;
                return $x->[0]**2;
            }
        };
        my $weak_preconditioner = my $preconditioner = eval q{
            sub {
                my ( $x, $v, $vpre, $callback_data ) = @_;
                $vpre->[0] = $v->[0];
            }
        };
        my $weak_data = my $data = { name => "$method replacement" };
        weaken( $weak_objective );
        weaken( $weak_preconditioner );
        weaken( $weak_data );

        $opt->$method( $objective, $preconditioner, $data );
        undef $objective;
        undef $preconditioner;
        undef $data;

        ok( defined( $weak_objective ),      'active objective is retained' );
        ok( defined( $weak_preconditioner ), 'active preconditioner is retained' );
        ok( defined( $weak_data ),           'active callback data is retained' );

        $opt->$method( sub { 0 }, sub { } );

        ok( !defined( $weak_objective ),      'replaced objective is released immediately' );
        ok( !defined( $weak_preconditioner ), 'replaced preconditioner is released immediately', );
        ok( !defined( $weak_data ),           'replaced callback data is released immediately' );
        is( $opt->get_dimension, 1, 'optimizer remains alive after objective replacement' );
    };

    subtest "$method replaces an ordinary objective" => sub {
        my $opt = Math::NLopt->new( NLOPT_LD_CCSAQ, 1 );

        my $weak_objective = my $objective = eval q{
            sub {
                my ( $x, $gradient, $data ) = @_;
                return $x->[0]**2;
            }
        };
        my $weak_data = my $data = { name => 'ordinary objective' };
        weaken( $weak_objective );
        weaken( $weak_data );

        $opt->set_min_objective( $objective, $data );
        undef $objective;
        undef $data;

        $opt->$method( sub { 0 }, sub { } );

        ok( !defined( $weak_objective ), 'replaced objective is released' );
        ok( !defined( $weak_data ),      'replaced callback data is released' );
        is( $opt->get_dimension, 1, 'optimizer remains alive after cross-family replacement' );
    };
}

done_testing;
