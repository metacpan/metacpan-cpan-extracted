#define FATAL_LOG_LEVEL (L4CP_FATAL_LOG_LEVEL)
#define ERROR_LOG_LEVEL (L4CP_ERROR_LOG_LEVEL)
#define WARN_LOG_LEVEL (L4CP_WARN_LOG_LEVEL)
#define INFO_LOG_LEVEL (L4CP_INFO_LOG_LEVEL)
#define DEBUG_LOG_LEVEL (L4CP_DEBUG_LOG_LEVEL)
#define TRACE_LOG_LEVEL (L4CP_TRACE_LOG_LEVEL)
#define OFF_LOG_LEVEL (L4CP_OFF_LOG_LEVEL)
#define ALL_LOG_LEVEL (L4CP_ALL_LOG_LEVEL)
#define NOT_SET_LOG_LEVEL (L4CP_NOT_SET_LOG_LEVEL)
#define CRITICAL_LOG_LEVEL ((L4CP_ERROR_LOG_LEVEL+L4CP_FATAL_LOG_LEVEL)/2)
#define NOTICE_LOG_LEVEL ((L4CP_INFO_LOG_LEVEL+L4CP_WARN_LOG_LEVEL)/2)
#define EMERGENCY_LOG_LEVEL (L4CP_FATAL_LOG_LEVEL)
#define EMERG_LOG_LEVEL (L4CP_FATAL_LOG_LEVEL)
#define PANIC_LOG_LEVEL (L4CP_FATAL_LOG_LEVEL)
#define BASIC_LOG_LEVEL (L4CP_INFO_LOG_LEVEL+1)
#define WARNING_LOG_LEVEL (L4CP_WARN_LOG_LEVEL)
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
constant_15 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BASIC_LOG_LEVEL DEBUG_LOG_LEVEL EMERG_LOG_LEVEL ERROR_LOG_LEVEL
     FATAL_LOG_LEVEL PANIC_LOG_LEVEL TRACE_LOG_LEVEL */
  /* Offset 2 gives the best switch position.  */
  switch (name[2]) {
  case 'A':
    if (memEQ(name, "TRACE_LOG_LEVEL", 15)) {
    /*                 ^                   */
#ifdef TRACE_LOG_LEVEL
      *iv_return = TRACE_LOG_LEVEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "DEBUG_LOG_LEVEL", 15)) {
    /*                 ^                   */
#ifdef DEBUG_LOG_LEVEL
      *iv_return = DEBUG_LOG_LEVEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "EMERG_LOG_LEVEL", 15)) {
    /*                 ^                   */
#ifdef EMERG_LOG_LEVEL
      *iv_return = EMERG_LOG_LEVEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "PANIC_LOG_LEVEL", 15)) {
    /*                 ^                   */
#ifdef PANIC_LOG_LEVEL
      *iv_return = PANIC_LOG_LEVEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "ERROR_LOG_LEVEL", 15)) {
    /*                 ^                   */
#ifdef ERROR_LOG_LEVEL
      *iv_return = ERROR_LOG_LEVEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "BASIC_LOG_LEVEL", 15)) {
    /*                 ^                   */
#ifdef BASIC_LOG_LEVEL
      *iv_return = BASIC_LOG_LEVEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "FATAL_LOG_LEVEL", 15)) {
    /*                 ^                   */
#ifdef FATAL_LOG_LEVEL
      *iv_return = FATAL_LOG_LEVEL;
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

#!/Users/sno/perl5/perlbrew/perls/perl-5.30.0/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(ALL_LOG_LEVEL BASIC_LOG_LEVEL CRITICAL_LOG_LEVEL
	       DEBUG_LOG_LEVEL EMERGENCY_LOG_LEVEL EMERG_LOG_LEVEL
	       ERROR_LOG_LEVEL FATAL_LOG_LEVEL INFO_LOG_LEVEL NOTICE_LOG_LEVEL
	       NOT_SET_LOG_LEVEL OFF_LOG_LEVEL PANIC_LOG_LEVEL TRACE_LOG_LEVEL
	       WARNING_LOG_LEVEL WARN_LOG_LEVEL));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Lib::Log4cplus", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Lib::Log4cplus", $types);
__END__
   */

  switch (len) {
  case 13:
    /* Names all of length 13.  */
    /* ALL_LOG_LEVEL OFF_LOG_LEVEL */
    /* Offset 1 gives the best switch position.  */
    switch (name[1]) {
    case 'F':
      if (memEQ(name, "OFF_LOG_LEVEL", 13)) {
      /*                ^                  */
#ifdef OFF_LOG_LEVEL
        *iv_return = OFF_LOG_LEVEL;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'L':
      if (memEQ(name, "ALL_LOG_LEVEL", 13)) {
      /*                ^                  */
#ifdef ALL_LOG_LEVEL
        *iv_return = ALL_LOG_LEVEL;
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
    /* INFO_LOG_LEVEL WARN_LOG_LEVEL */
    /* Offset 3 gives the best switch position.  */
    switch (name[3]) {
    case 'N':
      if (memEQ(name, "WARN_LOG_LEVEL", 14)) {
      /*                  ^                 */
#ifdef WARN_LOG_LEVEL
        *iv_return = WARN_LOG_LEVEL;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'O':
      if (memEQ(name, "INFO_LOG_LEVEL", 14)) {
      /*                  ^                 */
#ifdef INFO_LOG_LEVEL
        *iv_return = INFO_LOG_LEVEL;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 15:
    return constant_15 (aTHX_ name, iv_return);
    break;
  case 16:
    if (memEQ(name, "NOTICE_LOG_LEVEL", 16)) {
#ifdef NOTICE_LOG_LEVEL
      *iv_return = NOTICE_LOG_LEVEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 17:
    /* Names all of length 17.  */
    /* NOT_SET_LOG_LEVEL WARNING_LOG_LEVEL */
    /* Offset 2 gives the best switch position.  */
    switch (name[2]) {
    case 'R':
      if (memEQ(name, "WARNING_LOG_LEVEL", 17)) {
      /*                 ^                     */
#ifdef WARNING_LOG_LEVEL
        *iv_return = WARNING_LOG_LEVEL;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'T':
      if (memEQ(name, "NOT_SET_LOG_LEVEL", 17)) {
      /*                 ^                     */
#ifdef NOT_SET_LOG_LEVEL
        *iv_return = NOT_SET_LOG_LEVEL;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 18:
    if (memEQ(name, "CRITICAL_LOG_LEVEL", 18)) {
#ifdef CRITICAL_LOG_LEVEL
      *iv_return = CRITICAL_LOG_LEVEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 19:
    if (memEQ(name, "EMERGENCY_LOG_LEVEL", 19)) {
#ifdef EMERGENCY_LOG_LEVEL
      *iv_return = EMERGENCY_LOG_LEVEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

