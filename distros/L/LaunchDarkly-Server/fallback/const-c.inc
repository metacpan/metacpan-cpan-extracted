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
     LD_LOG_DEBUG LD_LOG_ERROR LD_LOG_FATAL LD_LOG_TRACE */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'E':
    if (memEQ(name, "LD_LOG_TRAC", 11)) {
    /*                          E      */
      *iv_return = LD_LOG_TRACE;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "LD_LOG_DEBU", 11)) {
    /*                          G      */
      *iv_return = LD_LOG_DEBUG;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "LD_LOG_FATA", 11)) {
    /*                          L      */
      *iv_return = LD_LOG_FATAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "LD_LOG_ERRO", 11)) {
    /*                          R      */
      *iv_return = LD_LOG_ERROR;
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
     LD_FALLTHROUGH LD_LOG_WARNING LD_STORE_ERROR */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'N':
    if (memEQ(name, "LD_LOG_WARNING", 14)) {
    /*                         ^          */
      *iv_return = LD_LOG_WARNING;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "LD_FALLTHROUGH", 14)) {
    /*                         ^          */
      *iv_return = LD_FALLTHROUGH;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "LD_STORE_ERROR", 14)) {
    /*                         ^          */
      *iv_return = LD_STORE_ERROR;
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

#!/usr/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(),
            {name=>"LD_CLIENT_NOT_READY", type=>"IV", macro=>"1"},
            {name=>"LD_CLIENT_NOT_SPECIFIED", type=>"IV", macro=>"1"},
            {name=>"LD_ERROR", type=>"IV", macro=>"1"},
            {name=>"LD_FALLTHROUGH", type=>"IV", macro=>"1"},
            {name=>"LD_FLAG_NOT_FOUND", type=>"IV", macro=>"1"},
            {name=>"LD_LOG_CRITICAL", type=>"IV", macro=>"1"},
            {name=>"LD_LOG_DEBUG", type=>"IV", macro=>"1"},
            {name=>"LD_LOG_ERROR", type=>"IV", macro=>"1"},
            {name=>"LD_LOG_FATAL", type=>"IV", macro=>"1"},
            {name=>"LD_LOG_INFO", type=>"IV", macro=>"1"},
            {name=>"LD_LOG_TRACE", type=>"IV", macro=>"1"},
            {name=>"LD_LOG_WARNING", type=>"IV", macro=>"1"},
            {name=>"LD_MALFORMED_FLAG", type=>"IV", macro=>"1"},
            {name=>"LD_NULL_KEY", type=>"IV", macro=>"1"},
            {name=>"LD_OFF", type=>"IV", macro=>"1"},
            {name=>"LD_OOM", type=>"IV", macro=>"1"},
            {name=>"LD_PREREQUISITE_FAILED", type=>"IV", macro=>"1"},
            {name=>"LD_RULE_MATCH", type=>"IV", macro=>"1"},
            {name=>"LD_STORE_ERROR", type=>"IV", macro=>"1"},
            {name=>"LD_TARGET_MATCH", type=>"IV", macro=>"1"},
            {name=>"LD_UNKNOWN", type=>"IV", macro=>"1"},
            {name=>"LD_USER_NOT_SPECIFIED", type=>"IV", macro=>"1"},
            {name=>"LD_WRONG_TYPE", type=>"IV", macro=>"1"});

print constant_types(), "\n"; # macro defs
foreach (C_constant ("LaunchDarkly::Server", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("LaunchDarkly::Server", $types);
__END__
   */

  switch (len) {
  case 6:
    /* Names all of length 6.  */
    /* LD_OFF LD_OOM */
    /* Offset 5 gives the best switch position.  */
    switch (name[5]) {
    case 'F':
      if (memEQ(name, "LD_OF", 5)) {
      /*                    F     */
        *iv_return = LD_OFF;
        return PERL_constant_ISIV;
      }
      break;
    case 'M':
      if (memEQ(name, "LD_OO", 5)) {
      /*                    M     */
        *iv_return = LD_OOM;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 8:
    if (memEQ(name, "LD_ERROR", 8)) {
      *iv_return = LD_ERROR;
      return PERL_constant_ISIV;
    }
    break;
  case 10:
    if (memEQ(name, "LD_UNKNOWN", 10)) {
      *iv_return = LD_UNKNOWN;
      return PERL_constant_ISIV;
    }
    break;
  case 11:
    /* Names all of length 11.  */
    /* LD_LOG_INFO LD_NULL_KEY */
    /* Offset 9 gives the best switch position.  */
    switch (name[9]) {
    case 'E':
      if (memEQ(name, "LD_NULL_KEY", 11)) {
      /*                        ^        */
        *iv_return = LD_NULL_KEY;
        return PERL_constant_ISIV;
      }
      break;
    case 'F':
      if (memEQ(name, "LD_LOG_INFO", 11)) {
      /*                        ^        */
        *iv_return = LD_LOG_INFO;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 12:
    return constant_12 (aTHX_ name, iv_return);
    break;
  case 13:
    /* Names all of length 13.  */
    /* LD_RULE_MATCH LD_WRONG_TYPE */
    /* Offset 12 gives the best switch position.  */
    switch (name[12]) {
    case 'E':
      if (memEQ(name, "LD_WRONG_TYP", 12)) {
      /*                           E      */
        *iv_return = LD_WRONG_TYPE;
        return PERL_constant_ISIV;
      }
      break;
    case 'H':
      if (memEQ(name, "LD_RULE_MATC", 12)) {
      /*                           H      */
        *iv_return = LD_RULE_MATCH;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 14:
    return constant_14 (aTHX_ name, iv_return);
    break;
  case 15:
    /* Names all of length 15.  */
    /* LD_LOG_CRITICAL LD_TARGET_MATCH */
    /* Offset 7 gives the best switch position.  */
    switch (name[7]) {
    case 'C':
      if (memEQ(name, "LD_LOG_CRITICAL", 15)) {
      /*                      ^              */
        *iv_return = LD_LOG_CRITICAL;
        return PERL_constant_ISIV;
      }
      break;
    case 'E':
      if (memEQ(name, "LD_TARGET_MATCH", 15)) {
      /*                      ^              */
        *iv_return = LD_TARGET_MATCH;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 17:
    /* Names all of length 17.  */
    /* LD_FLAG_NOT_FOUND LD_MALFORMED_FLAG */
    /* Offset 6 gives the best switch position.  */
    switch (name[6]) {
    case 'F':
      if (memEQ(name, "LD_MALFORMED_FLAG", 17)) {
      /*                     ^                 */
        *iv_return = LD_MALFORMED_FLAG;
        return PERL_constant_ISIV;
      }
      break;
    case 'G':
      if (memEQ(name, "LD_FLAG_NOT_FOUND", 17)) {
      /*                     ^                 */
        *iv_return = LD_FLAG_NOT_FOUND;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 19:
    if (memEQ(name, "LD_CLIENT_NOT_READY", 19)) {
      *iv_return = LD_CLIENT_NOT_READY;
      return PERL_constant_ISIV;
    }
    break;
  case 21:
    if (memEQ(name, "LD_USER_NOT_SPECIFIED", 21)) {
      *iv_return = LD_USER_NOT_SPECIFIED;
      return PERL_constant_ISIV;
    }
    break;
  case 22:
    if (memEQ(name, "LD_PREREQUISITE_FAILED", 22)) {
      *iv_return = LD_PREREQUISITE_FAILED;
      return PERL_constant_ISIV;
    }
    break;
  case 23:
    if (memEQ(name, "LD_CLIENT_NOT_SPECIFIED", 23)) {
      *iv_return = LD_CLIENT_NOT_SPECIFIED;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

