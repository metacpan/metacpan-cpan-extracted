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
constant_7 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     FNV0_32 FNV0_64 FNV1_32 FNV1_64 */
  /* Offset 3 gives the best switch position.  */
  switch (name[3]) {
  case '0':
    if (memEQ(name, "FNV0_32", 7)) {
    /*                  ^         */
#ifdef FNV0_32
      *iv_return = FNV0_32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "FNV0_64", 7)) {
    /*                  ^         */
#ifdef FNV0_64
      *iv_return = FNV0_64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '1':
    if (memEQ(name, "FNV1_32", 7)) {
    /*                  ^         */
#ifdef FNV1_32
      *iv_return = FNV1_32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "FNV1_64", 7)) {
    /*                  ^         */
#ifdef FNV1_64
      *iv_return = FNV1_64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_8 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     FNV1a_32 FNV1a_64 FNV_NONE */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case '2':
    if (memEQ(name, "FNV1a_3", 7)) {
    /*                      2     */
#ifdef FNV1a_32
      *iv_return = FNV1a_32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '4':
    if (memEQ(name, "FNV1a_6", 7)) {
    /*                      4     */
#ifdef FNV1a_64
      *iv_return = FNV1a_64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "FNV_NON", 7)) {
    /*                      E     */
#ifdef FNV_NONE
      *iv_return = FNV_NONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_12 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     FNV0_32_INIT FNV0_64_INIT FNV1_32_INIT FNV1_64_INIT */
  /* Offset 3 gives the best switch position.  */
  switch (name[3]) {
  case '0':
    if (memEQ(name, "FNV0_32_INIT", 12)) {
    /*                  ^               */
#ifdef FNV0_32_INIT
      *iv_return = FNV0_32_INIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "FNV0_64_INIT", 12)) {
    /*                  ^               */
#ifdef FNV0_64_INIT
      *iv_return = FNV0_64_INIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '1':
    if (memEQ(name, "FNV1_32_INIT", 12)) {
    /*                  ^               */
#ifdef FNV1_32_INIT
      *iv_return = FNV1_32_INIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "FNV1_64_INIT", 12)) {
    /*                  ^               */
#ifdef FNV1_64_INIT
      *iv_return = FNV1_64_INIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
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

#!/usr/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(FNV0_32 FNV0_32_INIT FNV0_64 FNV0_64_INIT FNV1A_64_INIT FNV1_32
	       FNV1_32A_INIT FNV1_32_INIT FNV1_64 FNV1_64_INIT FNV1a_32
	       FNV1a_64 FNV_NONE));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Digest::FNV", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Digest::FNV", $types);
__END__
   */

  switch (len) {
  case 7:
    return constant_7 (aTHX_ name, iv_return);
    break;
  case 8:
    return constant_8 (aTHX_ name, iv_return);
    break;
  case 12:
    return constant_12 (aTHX_ name, iv_return);
    break;
  case 13:
    /* Names all of length 13.  */
    /* FNV1A_64_INIT FNV1_32A_INIT */
    /* Offset 6 gives the best switch position.  */
    switch (name[6]) {
    case '2':
      if (memEQ(name, "FNV1_32A_INIT", 13)) {
      /*                     ^             */
#ifdef FNV1_32A_INIT
        *iv_return = FNV1_32A_INIT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case '6':
      if (memEQ(name, "FNV1A_64_INIT", 13)) {
      /*                     ^             */
#ifdef FNV1A_64_INIT
        *iv_return = FNV1A_64_INIT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

