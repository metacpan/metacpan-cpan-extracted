#! perl

use v5.12;
use Test2::V0;
use Test::LeakTrace qw(no_leaks_ok);

use Math::NLopt qw(
  NLOPT_GN_ISRES
);

for my $method ( qw( add_equality_mconstraint add_inequality_mconstraint ) ) {
    no_leaks_ok {
        my $opt  = Math::NLopt->new( NLOPT_GN_ISRES, 2 );
        my $data = { name => $method };

        $opt->set_min_objective(
            sub {
                my ( $x ) = @_;
                return $x->[0]**2 + $x->[1]**2;
            } );
        $opt->$method(
            sub {
                my ( $result, $x, $gradient, $callback_data ) = @_;
                @{$result} = ( $x->[0] + $x->[1] - 1, $x->[0] - $x->[1] );
            },
            m    => 2,
            tol  => [ 1e-8, 1e-8 ],
            data => $data,
        );
        $opt->set_lower_bounds( [ -10, -10 ] );
        $opt->set_upper_bounds( [ 10,   10 ] );
        $opt->set_maxeval( 1 );
        $opt->optimize( [ 2, 2 ] );
    }
    "$method releases callback storage";
}

done_testing;
