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
constant_13 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     FNV1_32A_INIT FNV1_64_LOWER FNV1_64_UPPER */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'I':
    if (memEQ(name, "FNV1_32A_INIT", 13)) {
    /*                        ^          */
#ifdef FNV1_32A_INIT
      *iv_return = FNV1_32A_INIT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "FNV1_64_LOWER", 13)) {
    /*                        ^          */
#ifdef FNV1_64_LOWER
      *iv_return = FNV1_64_LOWER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "FNV1_64_UPPER", 13)) {
    /*                        ^          */
#ifdef FNV1_64_UPPER
      *iv_return = FNV1_64_UPPER;
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
my @names = (qw(FNV0_32_INIT FNV1A_64_LOWER FNV1A_64_UPPER FNV1_32A_INIT
	       FNV1_32_INIT FNV1_64_LOWER FNV1_64_UPPER));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Digest::FNV", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Digest::FNV", $types);
__END__
   */

  switch (len) {
  case 12:
    /* Names all of length 12.  */
    /* FNV0_32_INIT FNV1_32_INIT */
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
      break;
    }
    break;
  case 13:
    return constant_13 (aTHX_ name, iv_return);
    break;
  case 14:
    /* Names all of length 14.  */
    /* FNV1A_64_LOWER FNV1A_64_UPPER */
    /* Offset 10 gives the best switch position.  */
    switch (name[10]) {
    case 'O':
      if (memEQ(name, "FNV1A_64_LOWER", 14)) {
      /*                         ^          */
#ifdef FNV1A_64_LOWER
        *iv_return = FNV1A_64_LOWER;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'P':
      if (memEQ(name, "FNV1A_64_UPPER", 14)) {
      /*                         ^          */
#ifdef FNV1A_64_UPPER
        *iv_return = FNV1A_64_UPPER;
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

