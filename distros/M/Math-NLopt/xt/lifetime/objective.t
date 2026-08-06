#! perl

use v5.12;
use Test2::V0;
use Test::LeakTrace qw(no_leaks_ok);

use Math::NLopt qw(
  NLOPT_GN_ISRES
);

for my $method ( qw( set_min_objective set_max_objective ) ) {
    no_leaks_ok {
        my $opt  = Math::NLopt->new( NLOPT_GN_ISRES, 2 );
        my $data = { name => $method };

        $opt->$method(
            sub {
                my ( $x, $gradient, $callback_data ) = @_;
                return $x->[0] + $x->[1];
            },
            $data,
        );
        $opt->set_lower_bounds( [ -10, -10 ] );
        $opt->set_upper_bounds( [ 10,   10 ] );
        $opt->set_maxeval( 1 );
        $opt->optimize( [ 1, 1 ] );
    }
    "$method releases callback storage";
}

done_testing;
