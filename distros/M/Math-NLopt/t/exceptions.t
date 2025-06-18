#! perl

use v5.10;
use Test2::V0;
use Math::NLopt 'NLOPT_LD_MMA', ':results';

my $opt = Math::NLopt->new( NLOPT_LD_MMA, 2 );

isa_ok( dies { $opt->_validate_result( NLOPT_FAILURE ) }, "Math::NLopt::Exception::Failure" );
isa_ok( dies { $opt->_validate_result( NLOPT_OUT_OF_MEMORY ) },
    "Math::NLopt::Exception::OutOfMemory" );
isa_ok( dies { $opt->_validate_result( NLOPT_INVALID_ARGS ) },
    "Math::NLopt::Exception::InvalidArgs" );
isa_ok( dies { $opt->_validate_result( NLOPT_ROUNDOFF_LIMITED ) },
    "Math::NLopt::Exception::RoundoffLimited" );
isa_ok( dies { $opt->_validate_result( NLOPT_FORCED_STOP ) },
    "Math::NLopt::Exception::ForcedStop" );

for my $result (
    NLOPT_SUCCESS,         NLOPT_STOPVAL_REACHED, NLOPT_FTOL_REACHED, NLOPT_XTOL_REACHED,
    NLOPT_MAXEVAL_REACHED, NLOPT_MAXTIME_REACHED,
  )
{
    is( $opt->_validate_result( $result ), $result );
}

done_testing;
