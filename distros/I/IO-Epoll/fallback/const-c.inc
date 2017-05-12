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
constant_8 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EPOLLERR EPOLLHUP EPOLLMSG EPOLLOUT EPOLLPRI */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'E':
    if (memEQ(name, "EPOLLERR", 8)) {
    /*                    ^        */
#ifdef EPOLLERR
      *iv_return = EPOLLERR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "EPOLLHUP", 8)) {
    /*                    ^        */
#ifdef EPOLLHUP
      *iv_return = EPOLLHUP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "EPOLLMSG", 8)) {
    /*                    ^        */
#ifdef EPOLLMSG
      *iv_return = EPOLLMSG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "EPOLLOUT", 8)) {
    /*                    ^        */
#ifdef EPOLLOUT
      *iv_return = EPOLLOUT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "EPOLLPRI", 8)) {
    /*                    ^        */
#ifdef EPOLLPRI
      *iv_return = EPOLLPRI;
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
constant_11 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EPOLLRDBAND EPOLLRDNORM EPOLLWRBAND EPOLLWRNORM */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'N':
    if (memEQ(name, "EPOLLRDBAND", 11)) {
    /*                        ^        */
#ifdef EPOLLRDBAND
      *iv_return = EPOLLRDBAND;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EPOLLWRBAND", 11)) {
    /*                        ^        */
#ifdef EPOLLWRBAND
      *iv_return = EPOLLWRBAND;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "EPOLLRDNORM", 11)) {
    /*                        ^        */
#ifdef EPOLLRDNORM
      *iv_return = EPOLLRDNORM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "EPOLLWRNORM", 11)) {
    /*                        ^        */
#ifdef EPOLLWRNORM
      *iv_return = EPOLLWRNORM;
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
     EPOLL_CTL_ADD EPOLL_CTL_DEL EPOLL_CTL_MOD */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'D':
    if (memEQ(name, "EPOLL_CTL_ADD", 13)) {
    /*                          ^        */
#ifdef EPOLL_CTL_ADD
      *iv_return = EPOLL_CTL_ADD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "EPOLL_CTL_DEL", 13)) {
    /*                          ^        */
#ifdef EPOLL_CTL_DEL
      *iv_return = EPOLL_CTL_DEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "EPOLL_CTL_MOD", 13)) {
    /*                          ^        */
#ifdef EPOLL_CTL_MOD
      *iv_return = EPOLL_CTL_MOD;
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
my @names = (qw(EPOLLERR EPOLLET EPOLLHUP EPOLLIN EPOLLMSG EPOLLOUT EPOLLPRI
	       EPOLLRDBAND EPOLLRDNORM EPOLLWRBAND EPOLLWRNORM EPOLL_CTL_ADD
	       EPOLL_CTL_DEL EPOLL_CTL_MOD));

print constant_types(); # macro defs
foreach (C_constant ("IO::Epoll", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("IO::Epoll", $types);
__END__
   */

  switch (len) {
  case 7:
    /* Names all of length 7.  */
    /* EPOLLET EPOLLIN */
    /* Offset 5 gives the best switch position.  */
    switch (name[5]) {
    case 'E':
      if (memEQ(name, "EPOLLET", 7)) {
      /*                    ^       */
#ifdef EPOLLET
        *iv_return = EPOLLET;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'I':
      if (memEQ(name, "EPOLLIN", 7)) {
      /*                    ^       */
#ifdef EPOLLIN
        *iv_return = EPOLLIN;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 8:
    return constant_8 (aTHX_ name, iv_return);
    break;
  case 11:
    return constant_11 (aTHX_ name, iv_return);
    break;
  case 13:
    return constant_13 (aTHX_ name, iv_return);
    break;
  }
  return PERL_constant_NOTFOUND;
}

