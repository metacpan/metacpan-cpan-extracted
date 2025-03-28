#! perl

use Test2::V0;

use Math::NLopt ':algorithms', ':results';

my $fail = 0;
foreach my $constname ( qw(
    NLOPT_AUGLAG NLOPT_AUGLAG_EQ NLOPT_FAILURE
    NLOPT_FORCED_STOP NLOPT_FTOL_REACHED NLOPT_GD_MLSL NLOPT_GD_MLSL_LDS
    NLOPT_GD_STOGO NLOPT_GD_STOGO_RAND NLOPT_GN_AGS NLOPT_GN_CRS2_LM
    NLOPT_GN_DIRECT NLOPT_GN_DIRECT_L NLOPT_GN_DIRECT_L_NOSCAL
    NLOPT_GN_DIRECT_L_RAND NLOPT_GN_DIRECT_L_RAND_NOSCAL
    NLOPT_GN_DIRECT_NOSCAL NLOPT_GN_ESCH NLOPT_GN_ISRES NLOPT_GN_MLSL
    NLOPT_GN_MLSL_LDS NLOPT_GN_ORIG_DIRECT NLOPT_GN_ORIG_DIRECT_L
    NLOPT_G_MLSL NLOPT_G_MLSL_LDS NLOPT_INVALID_ARGS NLOPT_LD_AUGLAG
    NLOPT_LD_AUGLAG_EQ NLOPT_LD_CCSAQ NLOPT_LD_LBFGS
    NLOPT_LD_MMA NLOPT_LD_SLSQP NLOPT_LD_TNEWTON NLOPT_LD_TNEWTON_PRECOND
    NLOPT_LD_TNEWTON_PRECOND_RESTART NLOPT_LD_TNEWTON_RESTART NLOPT_LD_VAR1
    NLOPT_LD_VAR2 NLOPT_LN_AUGLAG NLOPT_LN_AUGLAG_EQ NLOPT_LN_BOBYQA
    NLOPT_LN_COBYLA NLOPT_LN_NELDERMEAD NLOPT_LN_NEWUOA
    NLOPT_LN_NEWUOA_BOUND NLOPT_LN_PRAXIS NLOPT_LN_SBPLX
    NLOPT_MAXEVAL_REACHED NLOPT_MAXTIME_REACHED NLOPT_MINF_MAX_REACHED
    NLOPT_NUM_ALGORITHMS NLOPT_NUM_FAILURES NLOPT_NUM_RESULTS
    NLOPT_OUT_OF_MEMORY NLOPT_ROUNDOFF_LIMITED
    NLOPT_STOPVAL_REACHED NLOPT_SUCCESS NLOPT_XTOL_REACHED)
  )
{
    ok( lives { eval "my \$a = $constname; 1" }, $constname );
}

done_testing;
