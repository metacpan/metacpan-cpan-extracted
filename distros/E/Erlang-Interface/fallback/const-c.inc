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
     ERL_BIG ERL_NIL ERL_PID ERL_REF */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'D':
    if (memEQ(name, "ERL_PI", 6)) {
    /*                     D     */
#ifdef ERL_PID
      *iv_return = ERL_PID;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "ERL_RE", 6)) {
    /*                     F     */
#ifdef ERL_REF
      *iv_return = ERL_REF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "ERL_BI", 6)) {
    /*                     G     */
#ifdef ERL_BIG
      *iv_return = ERL_BIG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "ERL_NI", 6)) {
    /*                     L     */
#ifdef ERL_NIL
      *iv_return = ERL_NIL;
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
     ERL_ATOM ERL_CONS ERL_LIST ERL_PORT */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'N':
    if (memEQ(name, "ERL_CONS", 8)) {
    /*                     ^       */
#ifdef ERL_CONS
      *iv_return = ERL_CONS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "ERL_ATOM", 8)) {
    /*                     ^       */
#ifdef ERL_ATOM
      *iv_return = ERL_ATOM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "ERL_PORT", 8)) {
    /*                     ^       */
#ifdef ERL_PORT
      *iv_return = ERL_PORT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "ERL_LIST", 8)) {
    /*                     ^       */
#ifdef ERL_LIST
      *iv_return = ERL_LIST;
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
constant_9 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     ERL_FLOAT ERL_TUPLE ERL_UNDEF MAXREGLEN */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'D':
    if (memEQ(name, "ERL_UNDEF", 9)) {
    /*                     ^        */
#ifdef ERL_UNDEF
      *iv_return = ERL_UNDEF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "MAXREGLEN", 9)) {
    /*                     ^        */
#ifdef MAXREGLEN
      *iv_return = MAXREGLEN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "ERL_FLOAT", 9)) {
    /*                     ^        */
#ifdef ERL_FLOAT
      *iv_return = ERL_FLOAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "ERL_TUPLE", 9)) {
    /*                     ^        */
#ifdef ERL_TUPLE
      *iv_return = ERL_TUPLE;
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
     ERL_COMPOUND ERL_FUNCTION ERL_LONGLONG ERL_VARIABLE */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'D':
    if (memEQ(name, "ERL_COMPOUN", 11)) {
    /*                          D      */
#ifdef ERL_COMPOUND
      *iv_return = ERL_COMPOUND;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "ERL_VARIABL", 11)) {
    /*                          E      */
#ifdef ERL_VARIABLE
      *iv_return = ERL_VARIABLE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "ERL_LONGLON", 11)) {
    /*                          G      */
#ifdef ERL_LONGLONG
      *iv_return = ERL_LONGLONG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "ERL_FUNCTIO", 11)) {
    /*                          N      */
#ifdef ERL_FUNCTION
      *iv_return = ERL_FUNCTION;
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
my @names = (qw(ERL_ATOM ERL_BIG ERL_BINARY ERL_COMPOUND ERL_CONS
	       ERL_EMPTY_LIST ERL_FLOAT ERL_FUNCTION ERL_INTEGER ERL_LIST
	       ERL_LONGLONG ERL_NIL ERL_PID ERL_PORT ERL_REF ERL_SMALL_BIG
	       ERL_TUPLE ERL_UNDEF ERL_U_INTEGER ERL_U_LONGLONG ERL_U_SMALL_BIG
	       ERL_VARIABLE MAXREGLEN));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Erlang::Interface", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Erlang::Interface", $types);
__END__
   */

  switch (len) {
  case 7:
    return constant_7 (aTHX_ name, iv_return);
    break;
  case 8:
    return constant_8 (aTHX_ name, iv_return);
    break;
  case 9:
    return constant_9 (aTHX_ name, iv_return);
    break;
  case 10:
    if (memEQ(name, "ERL_BINARY", 10)) {
#ifdef ERL_BINARY
      *iv_return = ERL_BINARY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 11:
    if (memEQ(name, "ERL_INTEGER", 11)) {
#ifdef ERL_INTEGER
      *iv_return = ERL_INTEGER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 12:
    return constant_12 (aTHX_ name, iv_return);
    break;
  case 13:
    /* Names all of length 13.  */
    /* ERL_SMALL_BIG ERL_U_INTEGER */
    /* Offset 4 gives the best switch position.  */
    switch (name[4]) {
    case 'S':
      if (memEQ(name, "ERL_SMALL_BIG", 13)) {
      /*                   ^               */
#ifdef ERL_SMALL_BIG
        *iv_return = ERL_SMALL_BIG;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'U':
      if (memEQ(name, "ERL_U_INTEGER", 13)) {
      /*                   ^               */
#ifdef ERL_U_INTEGER
        *iv_return = ERL_U_INTEGER;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 14:
    /* Names all of length 14.  */
    /* ERL_EMPTY_LIST ERL_U_LONGLONG */
    /* Offset 6 gives the best switch position.  */
    switch (name[6]) {
    case 'L':
      if (memEQ(name, "ERL_U_LONGLONG", 14)) {
      /*                     ^              */
#ifdef ERL_U_LONGLONG
        *iv_return = ERL_U_LONGLONG;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'P':
      if (memEQ(name, "ERL_EMPTY_LIST", 14)) {
      /*                     ^              */
#ifdef ERL_EMPTY_LIST
        *iv_return = ERL_EMPTY_LIST;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 15:
    if (memEQ(name, "ERL_U_SMALL_BIG", 15)) {
#ifdef ERL_U_SMALL_BIG
      *iv_return = ERL_U_SMALL_BIG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

