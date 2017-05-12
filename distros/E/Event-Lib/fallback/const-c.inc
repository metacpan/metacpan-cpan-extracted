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
constant_10 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EVLIST_ALL EV_PERSIST EV_TIMEOUT */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'M':
    if (memEQ(name, "EV_TIMEOUT", 10)) {
    /*                    ^           */
#ifdef EV_TIMEOUT
      *iv_return = EV_TIMEOUT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "EV_PERSIST", 10)) {
    /*                    ^           */
#ifdef EV_PERSIST
      *iv_return = EV_PERSIST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "EVLIST_ALL", 10)) {
    /*                    ^           */
#ifdef EVLIST_ALL
      *iv_return = EVLIST_ALL;
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
constant_13 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EVBUFFER_READ EVLIST_ACTIVE EVLIST_SIGNAL */
  /* Offset 12 gives the best switch position.  */
  switch (name[12]) {
  case 'D':
    if (memEQ(name, "EVBUFFER_REA", 12)) {
    /*                           D      */
#ifdef EVBUFFER_READ
      *iv_return = EVBUFFER_READ;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "EVLIST_ACTIV", 12)) {
    /*                           E      */
#ifdef EVLIST_ACTIVE
      *iv_return = EVLIST_ACTIVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "EVLIST_SIGNA", 12)) {
    /*                           L      */
#ifdef EVLIST_SIGNAL
      *iv_return = EVLIST_SIGNAL;
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
constant_14 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EVBUFFER_ERROR EVBUFFER_WRITE EVLIST_TIMEOUT _EVENT_LOG_ERR _EVENT_LOG_MSG
     */
  /* Offset 12 gives the best switch position.  */
  switch (name[12]) {
  case 'O':
    if (memEQ(name, "EVBUFFER_ERROR", 14)) {
    /*                           ^        */
#ifdef EVBUFFER_ERROR
      *iv_return = EVBUFFER_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "_EVENT_LOG_ERR", 14)) {
    /*                           ^        */
#ifdef _EVENT_LOG_ERR
      *iv_return = _EVENT_LOG_ERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "_EVENT_LOG_MSG", 14)) {
    /*                           ^        */
#ifdef _EVENT_LOG_MSG
      *iv_return = _EVENT_LOG_MSG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "EVBUFFER_WRITE", 14)) {
    /*                           ^        */
#ifdef EVBUFFER_WRITE
      *iv_return = EVBUFFER_WRITE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "EVLIST_TIMEOUT", 14)) {
    /*                           ^        */
#ifdef EVLIST_TIMEOUT
      *iv_return = EVLIST_TIMEOUT;
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
constant_15 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EVLIST_INSERTED EVLIST_INTERNAL EVLOOP_NONBLOCK _EVENT_LOG_WARN */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'D':
    if (memEQ(name, "EVLIST_INSERTE", 14)) {
    /*                             D      */
#ifdef EVLIST_INSERTED
      *iv_return = EVLIST_INSERTED;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "EVLOOP_NONBLOC", 14)) {
    /*                             K      */
#ifdef EVLOOP_NONBLOCK
      *iv_return = EVLOOP_NONBLOCK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "EVLIST_INTERNA", 14)) {
    /*                             L      */
#ifdef EVLIST_INTERNAL
      *iv_return = EVLIST_INTERNAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "_EVENT_LOG_WAR", 14)) {
    /*                             N      */
#ifdef _EVENT_LOG_WARN
      *iv_return = _EVENT_LOG_WARN;
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
my @names = (qw(EVBUFFER_EOF EVBUFFER_ERROR EVBUFFER_READ EVBUFFER_TIMEOUT
	       EVBUFFER_WRITE EVLIST_ACTIVE EVLIST_ALL EVLIST_INIT
	       EVLIST_INSERTED EVLIST_INTERNAL EVLIST_SIGNAL EVLIST_TIMEOUT
	       EVLOOP_NONBLOCK EVLOOP_ONCE EV_PERSIST EV_READ EV_SIGNAL
	       EV_TIMEOUT EV_WRITE _EVENT_LOG_DEBUG _EVENT_LOG_ERR
	       _EVENT_LOG_MSG _EVENT_LOG_WARN));

print constant_types(); # macro defs
foreach (C_constant ("Event::Lib", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Event::Lib", $types);
__END__
   */

  switch (len) {
  case 7:
    if (memEQ(name, "EV_READ", 7)) {
#ifdef EV_READ
      *iv_return = EV_READ;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 8:
    if (memEQ(name, "EV_WRITE", 8)) {
#ifdef EV_WRITE
      *iv_return = EV_WRITE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 9:
    if (memEQ(name, "EV_SIGNAL", 9)) {
#ifdef EV_SIGNAL
      *iv_return = EV_SIGNAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 10:
    return constant_10 (aTHX_ name, iv_return);
    break;
  case 11:
    /* Names all of length 11.  */
    /* EVLIST_INIT EVLOOP_ONCE */
    /* Offset 4 gives the best switch position.  */
    switch (name[4]) {
    case 'O':
      if (memEQ(name, "EVLOOP_ONCE", 11)) {
      /*                   ^             */
#ifdef EVLOOP_ONCE
        *iv_return = EVLOOP_ONCE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'S':
      if (memEQ(name, "EVLIST_INIT", 11)) {
      /*                   ^             */
#ifdef EVLIST_INIT
        *iv_return = EVLIST_INIT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 12:
    if (memEQ(name, "EVBUFFER_EOF", 12)) {
#ifdef EVBUFFER_EOF
      *iv_return = EVBUFFER_EOF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
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
    /* Names all of length 16.  */
    /* EVBUFFER_TIMEOUT _EVENT_LOG_DEBUG */
    /* Offset 7 gives the best switch position.  */
    switch (name[7]) {
    case 'L':
      if (memEQ(name, "_EVENT_LOG_DEBUG", 16)) {
      /*                      ^               */
#ifdef _EVENT_LOG_DEBUG
        *iv_return = _EVENT_LOG_DEBUG;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'R':
      if (memEQ(name, "EVBUFFER_TIMEOUT", 16)) {
      /*                      ^               */
#ifdef EVBUFFER_TIMEOUT
        *iv_return = EVBUFFER_TIMEOUT;
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

