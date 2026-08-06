#! perl

use v5.12;
use Test2::V0;
use Test::LeakTrace qw(no_leaks_ok);

use Math::NLopt qw(
  NLOPT_LD_CCSAQ
);

for my $method ( qw( set_precond_min_objective set_precond_max_objective ) ) {
    no_leaks_ok {
        my $opt  = Math::NLopt->new( NLOPT_LD_CCSAQ, 1 );
        my $data = { name => $method };

        $opt->$method(
            sub {
                my ( $x, $gradient, $callback_data ) = @_;
                if ( defined $gradient ) {
                    $gradient->[0] = 2 * $x->[0];
                }
                return $method eq 'set_precond_min_objective'
                  ? $x->[0]**2
                  : -$x->[0]**2;
            },
            sub {
                my ( $x, $v, $vpre, $callback_data ) = @_;
                $vpre->[0] = $v->[0];
            },
            $data,
        );
        $opt->set_lower_bounds( [-10] );
        $opt->set_upper_bounds( [10] );
        $opt->set_maxeval( 2 );
        $opt->optimize( [1] );
    }
    "$method releases callback storage";
}

done_testing;
