#! perl

use v5.10;
use Test2::V0;
use Math::NLopt 'NLOPT_LD_MMA', ':results';

my $opt = Math::NLopt->new( NLOPT_LD_MMA, 2 );

subtest 'assert_result always throws for failures' => sub {
    $opt->set_exceptions_enabled( 0 );
    isa_ok( dies { $opt->_assert_result( NLOPT_FAILURE ) }, 'Math::NLopt::Exception::Failure' );
    $opt->set_exceptions_enabled( 1 );
};

# ensure that NLopt failure return values cause an exception.
for my $case (
    [ Failure         => NLOPT_FAILURE ],
    [ OutOfMemory     => NLOPT_OUT_OF_MEMORY ],
    [ InvalidArgs     => NLOPT_INVALID_ARGS ],
    [ RoundoffLimited => NLOPT_ROUNDOFF_LIMITED ],
    [ ForcedStop      => NLOPT_FORCED_STOP ],
  )
{
    my ( $class, $result ) = @$case;
    my $full_class = "Math::NLopt::Exception::$class";

    isa_ok( dies { $opt->_assert_result( $result ) }, $full_class );
    isa_ok( $full_class->new( 'status' ),             $full_class );
}

# ensure that NLopt success return values are returned.
for my $result (
    NLOPT_SUCCESS,         NLOPT_STOPVAL_REACHED, NLOPT_FTOL_REACHED, NLOPT_XTOL_REACHED,
    NLOPT_MAXEVAL_REACHED, NLOPT_MAXTIME_REACHED, NLOPT_MINF_MAX_REACHED,
  )
{
    is( $opt->_assert_result( $result ), $result, 'successful result is returned' );
}

# these are the Perl side exceptions.
for my $class ( qw(
    InvalidDimensions
    InvalidReturn
    InvalidUse
    MissingParameter
    ) )
{
    my $full_class = "Math::NLopt::Exception::$class";
    isa_ok( $full_class->new( 'status' ), $full_class );
}

done_testing;
