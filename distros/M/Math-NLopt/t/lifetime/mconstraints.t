#! perl

use v5.12;
use Test2::V0;
use Scalar::Util 'weaken';

use Math::NLopt qw(
  NLOPT_GN_ISRES
);

# Callbacks are compiled in a separate lexical scope.   If they
# are compiled directly in the test routine's scope, they seem
# to linger and still keep the weak references alive even
# when the strong reference is destroyed

for my $method ( qw( add_equality_mconstraint add_inequality_mconstraint ) ) {
    subtest $method => sub {
        my $opt   = Math::NLopt->new( NLOPT_GN_ISRES, 2 );
        my @calls = ( 0, 0 );

        my $objective = sub {
            my ( $x ) = @_;
            return $x->[0] + $x->[1];
        };

        $opt->set_min_objective( $objective );
        my @constraints;
        push @constraints, sub {
            my ( $result, $x, $gradient, $callback_data ) = @_;
            ++$calls[0];
            @{$result} = ( $x->[0] + $x->[1] - 1, $x->[0] - $x->[1] );
        };
        $opt->$method(
            $constraints[-1],
            m    => 2,
            tol  => [ 1e-8, 1e-8 ],
            data => { name => "$method first" },
        );
        push @constraints, sub {
            my ( $result, $x, $gradient, $callback_data ) = @_;
            ++$calls[1];
            @{$result} = ( $x->[0] + 2 * $x->[1] - 1 );
        };
        $opt->$method(
            $constraints[-1],
            m    => 1,
            tol  => [1e-8],
            data => { name => "$method second" },
        );
        undef @constraints;

        $opt->set_lower_bounds( [ -10, -10 ] );
        $opt->set_upper_bounds( [ 10,   10 ] );
        $opt->set_maxeval( 1 );

        ok( lives { $opt->optimize( [ 1, 1 ] ) }, 'optimization completes' );
        ok( $calls[0] > 0,                        'first constraint callback was invoked' );
        ok( $calls[1] > 0,                        'second constraint callback was invoked' );

        undef $opt;
    };
}

for my $kind ( qw( equality inequality ) ) {
    my $add_method    = "add_${kind}_mconstraint";
    my $remove_method = "remove_${kind}_constraints";

    subtest $remove_method => sub {
        my $opt = Math::NLopt->new( NLOPT_GN_ISRES, 2 );

        my $weak_callback = my $callback = eval q{
            sub {
                my ( $result, $x, $gradient, $callback_data ) = @_;
                @{$result} = ( $x->[0] + $x->[1] - 1 );
            }
        };
        my $weak_data = my $data = { name => $add_method };
        weaken( $weak_callback );
        weaken( $weak_data );

        $opt->$add_method(
            $callback,
            m    => 1,
            tol  => [1e-8],
            data => $data,
        );
        undef $callback;
        undef $data;

        ok( defined( $weak_callback ), "$add_method retains its callback" );
        ok( defined( $weak_data ),     "$add_method retains its callback data" );

        $opt->$remove_method;

        ok( !defined( $weak_callback ), 'callback is released immediately' );
        ok( !defined( $weak_data ),     'callback data is released immediately' );
        is( $opt->get_dimension, 2, 'optimizer remains alive after constraint removal' );
    };
}

done_testing;
