#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNO	4
#define PERL_constant_ISNV	5
#define PERL_constant_ISPV	6
#define PERL_constant_ISPVN	7
#define PERL_constant_ISSV	8
#define PERL_constant_ISUNDEF	9
#define PERL_constant_ISUV	10
#define PERL_constant_ISYES	11

#ifndef NVTYPE
typedef double NV; /* 5.6 and later define NVTYPE, and typedef NV to it.  */
#endif
#ifndef aTHX_
#define aTHX_ /* 5.6 or later define this for threading support.  */
#endif
#ifndef pTHX_
#define pTHX_ /* 5.6 or later define this for threading support.  */
#endif

static int
constant_12 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     NLOPT_AUGLAG NLOPT_GN_AGS NLOPT_G_MLSL NLOPT_LD_MMA */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'A':
    if (memEQ(name, "NLOPT_LD_MM", 11)) {
    /*                          A      */
      *iv_return = NLOPT_LD_MMA;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "NLOPT_AUGLA", 11)) {
    /*                          G      */
      *iv_return = NLOPT_AUGLAG;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "NLOPT_G_MLS", 11)) {
    /*                          L      */
      *iv_return = NLOPT_G_MLSL;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "NLOPT_GN_AG", 11)) {
    /*                          S      */
      *iv_return = NLOPT_GN_AGS;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_13 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     NLOPT_FAILURE NLOPT_GD_MLSL NLOPT_GN_ESCH NLOPT_GN_MLSL NLOPT_LD_VAR1
     NLOPT_LD_VAR2 NLOPT_STDCALL NLOPT_SUCCESS */
  /* Offset 12 gives the best switch position.  */
  switch (name[12]) {
  case '1':
    if (memEQ(name, "NLOPT_LD_VAR", 12)) {
    /*                           1      */
      *iv_return = NLOPT_LD_VAR1;
      return PERL_constant_ISIV;
    }
    break;
  case '2':
    if (memEQ(name, "NLOPT_LD_VAR", 12)) {
    /*                           2      */
      *iv_return = NLOPT_LD_VAR2;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "NLOPT_FAILUR", 12)) {
    /*                           E      */
      *iv_return = NLOPT_FAILURE;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "NLOPT_GN_ESC", 12)) {
    /*                           H      */
      *iv_return = NLOPT_GN_ESCH;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "NLOPT_GD_MLS", 12)) {
    /*                           L      */
      *iv_return = NLOPT_GD_MLSL;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "NLOPT_GN_MLS", 12)) {
    /*                           L      */
      *iv_return = NLOPT_GN_MLSL;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "NLOPT_SUCCES", 12)) {
    /*                           S      */
      *iv_return = NLOPT_SUCCESS;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_14 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     NLOPT_GD_STOGO NLOPT_GN_ISRES NLOPT_LD_CCSAQ NLOPT_LD_LBFGS NLOPT_LD_SLSQP
     NLOPT_LN_SBPLX */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case 'O':
    if (memEQ(name, "NLOPT_GD_STOG", 13)) {
    /*                            O      */
      *iv_return = NLOPT_GD_STOGO;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "NLOPT_LD_SLSQ", 13)) {
    /*                            P      */
      *iv_return = NLOPT_LD_SLSQP;
      return PERL_constant_ISIV;
    }
    break;
  case 'Q':
    if (memEQ(name, "NLOPT_LD_CCSA", 13)) {
    /*                            Q      */
      *iv_return = NLOPT_LD_CCSAQ;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "NLOPT_GN_ISRE", 13)) {
    /*                            S      */
      *iv_return = NLOPT_GN_ISRES;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "NLOPT_LD_LBFG", 13)) {
    /*                            S      */
      *iv_return = NLOPT_LD_LBFGS;
      return PERL_constant_ISIV;
    }
    break;
  case 'X':
    if (memEQ(name, "NLOPT_LN_SBPL", 13)) {
    /*                            X      */
      *iv_return = NLOPT_LN_SBPLX;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_15 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     NLOPT_AUGLAG_EQ NLOPT_GN_DIRECT NLOPT_LD_AUGLAG NLOPT_LN_AUGLAG
     NLOPT_LN_BOBYQA NLOPT_LN_COBYLA NLOPT_LN_NEWUOA NLOPT_LN_PRAXIS */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'A':
    if (memEQ(name, "NLOPT_LD_AUGLAG", 15)) {
    /*                        ^            */
      *iv_return = NLOPT_LD_AUGLAG;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "NLOPT_LN_AUGLAG", 15)) {
    /*                        ^            */
      *iv_return = NLOPT_LN_AUGLAG;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "NLOPT_LN_BOBYQA", 15)) {
    /*                        ^            */
      *iv_return = NLOPT_LN_BOBYQA;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "NLOPT_LN_COBYLA", 15)) {
    /*                        ^            */
      *iv_return = NLOPT_LN_COBYLA;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "NLOPT_GN_DIRECT", 15)) {
    /*                        ^            */
      *iv_return = NLOPT_GN_DIRECT;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "NLOPT_AUGLAG_EQ", 15)) {
    /*                        ^            */
      *iv_return = NLOPT_AUGLAG_EQ;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "NLOPT_LN_NEWUOA", 15)) {
    /*                        ^            */
      *iv_return = NLOPT_LN_NEWUOA;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "NLOPT_LN_PRAXIS", 15)) {
    /*                        ^            */
      *iv_return = NLOPT_LN_PRAXIS;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_16 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     NLOPT_GN_CRS2_LM NLOPT_G_MLSL_LDS NLOPT_LD_TNEWTON */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'D':
    if (memEQ(name, "NLOPT_G_MLSL_LDS", 16)) {
    /*                             ^        */
      *iv_return = NLOPT_G_MLSL_LDS;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "NLOPT_GN_CRS2_LM", 16)) {
    /*                             ^        */
      *iv_return = NLOPT_GN_CRS2_LM;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "NLOPT_LD_TNEWTON", 16)) {
    /*                             ^        */
      *iv_return = NLOPT_LD_TNEWTON;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_17 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     NLOPT_FORCED_STOP NLOPT_GD_MLSL_LDS NLOPT_GN_DIRECT_L NLOPT_GN_MLSL_LDS
     NLOPT_NUM_RESULTS */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'E':
    if (memEQ(name, "NLOPT_FORCED_STOP", 17)) {
    /*                         ^             */
      *iv_return = NLOPT_FORCED_STOP;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "NLOPT_GN_DIRECT_L", 17)) {
    /*                         ^             */
      *iv_return = NLOPT_GN_DIRECT_L;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "NLOPT_GD_MLSL_LDS", 17)) {
    /*                         ^             */
      *iv_return = NLOPT_GD_MLSL_LDS;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "NLOPT_GN_MLSL_LDS", 17)) {
    /*                         ^             */
      *iv_return = NLOPT_GN_MLSL_LDS;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "NLOPT_NUM_RESULTS", 17)) {
    /*                         ^             */
      *iv_return = NLOPT_NUM_RESULTS;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_18 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     NLOPT_FTOL_REACHED NLOPT_INVALID_ARGS NLOPT_LD_AUGLAG_EQ
     NLOPT_LN_AUGLAG_EQ NLOPT_NUM_FAILURES NLOPT_XTOL_REACHED */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'F':
    if (memEQ(name, "NLOPT_FTOL_REACHED", 18)) {
    /*                     ^                  */
      *iv_return = NLOPT_FTOL_REACHED;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "NLOPT_INVALID_ARGS", 18)) {
    /*                     ^                  */
      *iv_return = NLOPT_INVALID_ARGS;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "NLOPT_LD_AUGLAG_EQ", 18)) {
    /*                     ^                  */
      *iv_return = NLOPT_LD_AUGLAG_EQ;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "NLOPT_LN_AUGLAG_EQ", 18)) {
    /*                     ^                  */
      *iv_return = NLOPT_LN_AUGLAG_EQ;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "NLOPT_NUM_FAILURES", 18)) {
    /*                     ^                  */
      *iv_return = NLOPT_NUM_FAILURES;
      return PERL_constant_ISIV;
    }
    break;
  case 'X':
    if (memEQ(name, "NLOPT_XTOL_REACHED", 18)) {
    /*                     ^                  */
      *iv_return = NLOPT_XTOL_REACHED;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_19 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     NLOPT_GD_STOGO_RAND NLOPT_LN_NELDERMEAD NLOPT_OUT_OF_MEMORY */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'G':
    if (memEQ(name, "NLOPT_GD_STOGO_RAND", 19)) {
    /*                     ^                   */
      *iv_return = NLOPT_GD_STOGO_RAND;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "NLOPT_LN_NELDERMEAD", 19)) {
    /*                     ^                   */
      *iv_return = NLOPT_LN_NELDERMEAD;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "NLOPT_OUT_OF_MEMORY", 19)) {
    /*                     ^                   */
      *iv_return = NLOPT_OUT_OF_MEMORY;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_21 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     NLOPT_LN_NEWUOA_BOUND NLOPT_MAXEVAL_REACHED NLOPT_MAXTIME_REACHED
     NLOPT_STOPVAL_REACHED */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'E':
    if (memEQ(name, "NLOPT_MAXEVAL_REACHED", 21)) {
    /*                        ^                  */
      *iv_return = NLOPT_MAXEVAL_REACHED;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "NLOPT_LN_NEWUOA_BOUND", 21)) {
    /*                        ^                  */
      *iv_return = NLOPT_LN_NEWUOA_BOUND;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "NLOPT_STOPVAL_REACHED", 21)) {
    /*                        ^                  */
      *iv_return = NLOPT_STOPVAL_REACHED;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "NLOPT_MAXTIME_REACHED", 21)) {
    /*                        ^                  */
      *iv_return = NLOPT_MAXTIME_REACHED;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_22 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     NLOPT_GN_DIRECT_L_RAND NLOPT_GN_DIRECT_NOSCAL NLOPT_GN_ORIG_DIRECT_L
     NLOPT_LD_LBFGS_NOCEDAL NLOPT_MINF_MAX_REACHED NLOPT_ROUNDOFF_LIMITED */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'E':
    if (memEQ(name, "NLOPT_MINF_MAX_REACHED", 22)) {
    /*                               ^            */
#ifdef NLOPT_MINF_MAX_REACHED
      *iv_return = NLOPT_MINF_MAX_REACHED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "NLOPT_ROUNDOFF_LIMITED", 22)) {
    /*                               ^            */
      *iv_return = NLOPT_ROUNDOFF_LIMITED;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "NLOPT_GN_DIRECT_L_RAND", 22)) {
    /*                               ^            */
      *iv_return = NLOPT_GN_DIRECT_L_RAND;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "NLOPT_GN_DIRECT_NOSCAL", 22)) {
    /*                               ^            */
      *iv_return = NLOPT_GN_DIRECT_NOSCAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "NLOPT_LD_LBFGS_NOCEDAL", 22)) {
    /*                               ^            */
      *iv_return = NLOPT_LD_LBFGS_NOCEDAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "NLOPT_GN_ORIG_DIRECT_L", 22)) {
    /*                               ^            */
      *iv_return = NLOPT_GN_ORIG_DIRECT_L;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_24 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     NLOPT_GN_DIRECT_L_NOSCAL NLOPT_LD_TNEWTON_PRECOND NLOPT_LD_TNEWTON_RESTART
     */
  /* Offset 18 gives the best switch position.  */
  switch (name[18]) {
  case 'E':
    if (memEQ(name, "NLOPT_LD_TNEWTON_RESTART", 24)) {
    /*                                 ^            */
      *iv_return = NLOPT_LD_TNEWTON_RESTART;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "NLOPT_GN_DIRECT_L_NOSCAL", 24)) {
    /*                                 ^            */
      *iv_return = NLOPT_GN_DIRECT_L_NOSCAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "NLOPT_LD_TNEWTON_PRECOND", 24)) {
    /*                                 ^            */
      *iv_return = NLOPT_LD_TNEWTON_PRECOND;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant (pTHX_ const char *name, STRLEN len, IV *iv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!/home/dj/.plenv/versions/5.38.2/bin/perl5.38.2 -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(NLOPT_MINF_MAX_REACHED ),
            {name=>"NLOPT_AUGLAG", type=>"IV", macro=>"1"},
            {name=>"NLOPT_AUGLAG_EQ", type=>"IV", macro=>"1"},
            {name=>"NLOPT_FAILURE", type=>"IV", macro=>"1"},
            {name=>"NLOPT_FORCED_STOP", type=>"IV", macro=>"1"},
            {name=>"NLOPT_FTOL_REACHED", type=>"IV", macro=>"1"},
            {name=>"NLOPT_GD_MLSL", type=>"IV", macro=>"1"},
            {name=>"NLOPT_GD_MLSL_LDS", type=>"IV", macro=>"1"},
            {name=>"NLOPT_GD_STOGO", type=>"IV", macro=>"1"},
            {name=>"NLOPT_GD_STOGO_RAND", type=>"IV", macro=>"1"},
            {name=>"NLOPT_GN_AGS", type=>"IV", macro=>"1"},
            {name=>"NLOPT_GN_CRS2_LM", type=>"IV", macro=>"1"},
            {name=>"NLOPT_GN_DIRECT", type=>"IV", macro=>"1"},
            {name=>"NLOPT_GN_DIRECT_L", type=>"IV", macro=>"1"},
            {name=>"NLOPT_GN_DIRECT_L_NOSCAL", type=>"IV", macro=>"1"},
            {name=>"NLOPT_GN_DIRECT_L_RAND", type=>"IV", macro=>"1"},
            {name=>"NLOPT_GN_DIRECT_L_RAND_NOSCAL", type=>"IV", macro=>"1"},
            {name=>"NLOPT_GN_DIRECT_NOSCAL", type=>"IV", macro=>"1"},
            {name=>"NLOPT_GN_ESCH", type=>"IV", macro=>"1"},
            {name=>"NLOPT_GN_ISRES", type=>"IV", macro=>"1"},
            {name=>"NLOPT_GN_MLSL", type=>"IV", macro=>"1"},
            {name=>"NLOPT_GN_MLSL_LDS", type=>"IV", macro=>"1"},
            {name=>"NLOPT_GN_ORIG_DIRECT", type=>"IV", macro=>"1"},
            {name=>"NLOPT_GN_ORIG_DIRECT_L", type=>"IV", macro=>"1"},
            {name=>"NLOPT_G_MLSL", type=>"IV", macro=>"1"},
            {name=>"NLOPT_G_MLSL_LDS", type=>"IV", macro=>"1"},
            {name=>"NLOPT_INVALID_ARGS", type=>"IV", macro=>"1"},
            {name=>"NLOPT_LD_AUGLAG", type=>"IV", macro=>"1"},
            {name=>"NLOPT_LD_AUGLAG_EQ", type=>"IV", macro=>"1"},
            {name=>"NLOPT_LD_CCSAQ", type=>"IV", macro=>"1"},
            {name=>"NLOPT_LD_LBFGS", type=>"IV", macro=>"1"},
            {name=>"NLOPT_LD_LBFGS_NOCEDAL", type=>"IV", macro=>"1"},
            {name=>"NLOPT_LD_MMA", type=>"IV", macro=>"1"},
            {name=>"NLOPT_LD_SLSQP", type=>"IV", macro=>"1"},
            {name=>"NLOPT_LD_TNEWTON", type=>"IV", macro=>"1"},
            {name=>"NLOPT_LD_TNEWTON_PRECOND", type=>"IV", macro=>"1"},
            {name=>"NLOPT_LD_TNEWTON_PRECOND_RESTART", type=>"IV", macro=>"1"},
            {name=>"NLOPT_LD_TNEWTON_RESTART", type=>"IV", macro=>"1"},
            {name=>"NLOPT_LD_VAR1", type=>"IV", macro=>"1"},
            {name=>"NLOPT_LD_VAR2", type=>"IV", macro=>"1"},
            {name=>"NLOPT_LN_AUGLAG", type=>"IV", macro=>"1"},
            {name=>"NLOPT_LN_AUGLAG_EQ", type=>"IV", macro=>"1"},
            {name=>"NLOPT_LN_BOBYQA", type=>"IV", macro=>"1"},
            {name=>"NLOPT_LN_COBYLA", type=>"IV", macro=>"1"},
            {name=>"NLOPT_LN_NELDERMEAD", type=>"IV", macro=>"1"},
            {name=>"NLOPT_LN_NEWUOA", type=>"IV", macro=>"1"},
            {name=>"NLOPT_LN_NEWUOA_BOUND", type=>"IV", macro=>"1"},
            {name=>"NLOPT_LN_PRAXIS", type=>"IV", macro=>"1"},
            {name=>"NLOPT_LN_SBPLX", type=>"IV", macro=>"1"},
            {name=>"NLOPT_MAXEVAL_REACHED", type=>"IV", macro=>"1"},
            {name=>"NLOPT_MAXTIME_REACHED", type=>"IV", macro=>"1"},
            {name=>"NLOPT_NUM_ALGORITHMS", type=>"IV", macro=>"1"},
            {name=>"NLOPT_NUM_FAILURES", type=>"IV", macro=>"1"},
            {name=>"NLOPT_NUM_RESULTS", type=>"IV", macro=>"1"},
            {name=>"NLOPT_OUT_OF_MEMORY", type=>"IV", macro=>"1"},
            {name=>"NLOPT_ROUNDOFF_LIMITED", type=>"IV", macro=>"1"},
            {name=>"NLOPT_STOPVAL_REACHED", type=>"IV", macro=>"1"},
            {name=>"NLOPT_SUCCESS", type=>"IV", macro=>"1"},
            {name=>"NLOPT_XTOL_REACHED", type=>"IV", macro=>"1"});

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Math::NLopt", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Math::NLopt", $types);
__END__
   */

  switch (len) {
  case 12:
    return constant_12 (aTHX_ name, iv_return);
    break;
  case 13:
    return constant_13 (aTHX_ name, iv_return);
    break;
  case 14:
    return constant_14 (aTHX_ name, iv_return);
    break;
  case 15:
    return constant_15 (aTHX_ name, iv_return);
    break;
  case 16:
    return constant_16 (aTHX_ name, iv_return);
    break;
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 18:
    return constant_18 (aTHX_ name, iv_return);
    break;
  case 19:
    return constant_19 (aTHX_ name, iv_return);
    break;
  case 20:
    /* Names all of length 20.  */
    /* NLOPT_GN_ORIG_DIRECT NLOPT_NUM_ALGORITHMS */
    /* Offset 19 gives the best switch position.  */
    switch (name[19]) {
    case 'S':
      if (memEQ(name, "NLOPT_NUM_ALGORITHM", 19)) {
      /*                                  S      */
        *iv_return = NLOPT_NUM_ALGORITHMS;
        return PERL_constant_ISIV;
      }
      break;
    case 'T':
      if (memEQ(name, "NLOPT_GN_ORIG_DIREC", 19)) {
      /*                                  T      */
        *iv_return = NLOPT_GN_ORIG_DIRECT;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 21:
    return constant_21 (aTHX_ name, iv_return);
    break;
  case 22:
    return constant_22 (aTHX_ name, iv_return);
    break;
  case 24:
    return constant_24 (aTHX_ name, iv_return);
    break;
  case 29:
    if (memEQ(name, "NLOPT_GN_DIRECT_L_RAND_NOSCAL", 29)) {
      *iv_return = NLOPT_GN_DIRECT_L_RAND_NOSCAL;
      return PERL_constant_ISIV;
    }
    break;
  case 32:
    if (memEQ(name, "NLOPT_LD_TNEWTON_PRECOND_RESTART", 32)) {
      *iv_return = NLOPT_LD_TNEWTON_PRECOND_RESTART;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

