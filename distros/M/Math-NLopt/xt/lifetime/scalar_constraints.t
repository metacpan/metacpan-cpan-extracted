#! perl

use v5.12;
use Test2::V0;
use Test::LeakTrace qw(no_leaks_ok);

use Math::NLopt qw(
  NLOPT_GN_ISRES
);

for my $method ( qw( add_equality_constraint add_inequality_constraint ) ) {
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
                my ( $x, $gradient, $callback_data ) = @_;
                return $x->[0] + $x->[1] - 1;
            },
            data => $data,
        );
        $opt->set_lower_bounds( [ -10, -10 ] );
        $opt->set_upper_bounds( [ 10,   10 ] );
        $opt->set_maxeval( 1 );
        $opt->optimize( [ 1, 1 ] );
    }
    "$method releases callback storage";
}

done_testing;
