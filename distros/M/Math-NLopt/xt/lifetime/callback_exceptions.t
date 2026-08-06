#! perl

use v5.12;
use Test2::V0;
use Test::LeakTrace qw(no_leaks_ok);

use Math::NLopt qw(
  NLOPT_LD_CCSAQ
  NLOPT_LD_MMA
);
use Math::NLopt::Exception;

## no critic (IntializationForLocalVars ReturnValueOfEval)

no_leaks_ok {
    my $opt = Math::NLopt->new( NLOPT_LD_MMA, 2 );
    $opt->set_min_objective(
        sub {
            my ( $x, $gradient, $data ) = @_;
            ++$data->{calls} == 1
              and die Math::NLopt::Exception::ForcedStop->new( 'leak objective' );
            return 0;
        },
        { calls => 0 },
    );
    $opt->set_lower_bounds( [ -10, -10 ] );
    $opt->set_upper_bounds( [ 10,   10 ] );
    $opt->set_maxeval( 1 );
    {
        local $@;
        eval { $opt->optimize( [ 2, 2 ] ) };
    }
}
'objective exception leaves no Perl leaks';

no_leaks_ok {
    my $opt = Math::NLopt->new( NLOPT_LD_CCSAQ, 2 );
    $opt->set_precond_min_objective(
        sub {
            my ( $x, $gradient ) = @_;
            $gradient and @{$gradient} = ( 2 * $x->[0], 2 * $x->[1] );
            return $x->[0]**2 + $x->[1]**2;
        },
        sub {
            my ( $x, $v, $vpre, $data ) = @_;
            ++$data->{calls} == 1
              and die Math::NLopt::Exception::ForcedStop->new( 'leak preconditioner' );
        },
        { calls => 0 },
    );
    $opt->set_lower_bounds( [ -10, -10 ] );
    $opt->set_upper_bounds( [ 10,   10 ] );
    $opt->set_maxeval( 1 );
    {
        local $@;
        eval { $opt->optimize( [ 2, 2 ] ) };
    }
}
'preconditioner exception leaves no Perl leaks';

no_leaks_ok {
    my $opt = Math::NLopt->new( NLOPT_LD_MMA, 2 );
    $opt->set_min_objective( sub { 0 } );
    $opt->add_inequality_constraint(
        sub {
            my ( $x, $gradient, $data ) = @_;
            ++$data->{calls} == 1
              and die Math::NLopt::Exception::ForcedStop->new( 'leak scalar constraint' );
            return 0;
        },
        data => { calls => 0 },
    );
    $opt->set_lower_bounds( [ -10, -10 ] );
    $opt->set_upper_bounds( [ 10,   10 ] );
    $opt->set_maxeval( 1 );
    {
        local $@;
        eval { $opt->optimize( [ 2, 2 ] ) };
    }
}
'scalar constraint exception leaves no Perl leaks';

no_leaks_ok {
    my $opt = Math::NLopt->new( NLOPT_LD_MMA, 2 );
    $opt->set_min_objective( sub { 0 } );
    $opt->add_inequality_mconstraint(
        sub {
            my ( $result, $x, $gradient, $data ) = @_;
            ++$data->{calls} == 1
              and die Math::NLopt::Exception::ForcedStop->new( 'leak vector constraint' );
            $result->[0] = 0;
        },
        m    => 1,
        tol  => [1e-8],
        data => { calls => 0 },
    );
    $opt->set_lower_bounds( [ -10, -10 ] );
    $opt->set_upper_bounds( [ 10,   10 ] );
    $opt->set_maxeval( 1 );
    {
        local $@;
        eval { $opt->optimize( [ 2, 2 ] ) };
    }
}
'vector constraint exception leaves no Perl leaks';

done_testing;
