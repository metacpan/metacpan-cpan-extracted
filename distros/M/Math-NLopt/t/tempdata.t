#! perl

use Test2::V0;

use Math::NLopt 'NLOPT_FORCED_STOP';

use constant ALGORITHM => Math::NLopt::NLOPT_LN_SBPLX();

my $opt;

sub myfunc {
    my ( $x, $grad, $data ) = @_;

    my $success = ref( $data ) eq 'HASH' && $data->{a} == 3 ? 1 : 2;
    $opt->set_force_stop( $success );
}

subtest 'temporary data' => sub {

    # ensure that temporaries aren't GC'd too early

    $opt = Math::NLopt->new( ALGORITHM, 1 );
    $opt->set_min_objective( \&myfunc, { a => 3 } );

    eval { $opt->optimize( [0] ); };

    is( $opt->last_optimize_result, NLOPT_FORCED_STOP, 'stopped' );
    is( $opt->get_force_stop,       1,                 'temp data survived' );

};


done_testing;
