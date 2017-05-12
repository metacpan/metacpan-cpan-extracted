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
     CLONE_NEWIPC CLONE_NEWNET CLONE_NEWUTS CLONE_THREAD */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'E':
    if (memEQ(name, "CLONE_THREAD", 12)) {
    /*                        ^         */
#ifdef CLONE_THREAD
      *iv_return = CLONE_THREAD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "CLONE_NEWIPC", 12)) {
    /*                        ^         */
#ifdef CLONE_NEWIPC
      *iv_return = CLONE_NEWIPC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "CLONE_NEWNET", 12)) {
    /*                        ^         */
#ifdef CLONE_NEWNET
      *iv_return = CLONE_NEWNET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "CLONE_NEWUTS", 12)) {
    /*                        ^         */
#ifdef CLONE_NEWUTS
      *iv_return = CLONE_NEWUTS;
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
my @names = (qw(CLONE_FILES CLONE_FS CLONE_NEWIPC CLONE_NEWNET CLONE_NEWNS
	       CLONE_NEWUTS CLONE_SIGHAND CLONE_SYSVSEM CLONE_THREAD CLONE_VM));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Linux::Unshare", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Linux::Unshare", $types);
__END__
   */

  switch (len) {
  case 8:
    /* Names all of length 8.  */
    /* CLONE_FS CLONE_VM */
    /* Offset 7 gives the best switch position.  */
    switch (name[7]) {
    case 'M':
      if (memEQ(name, "CLONE_V", 7)) {
      /*                      M     */
#ifdef CLONE_VM
        *iv_return = CLONE_VM;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'S':
      if (memEQ(name, "CLONE_F", 7)) {
      /*                      S     */
#ifdef CLONE_FS
        *iv_return = CLONE_FS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 11:
    /* Names all of length 11.  */
    /* CLONE_FILES */
    /* Offset 7 gives the best switch position.  */
    case 'I':
      if (memEQ(name, "CLONE_FILES", 11)) {
      /*                      ^          */
#ifdef CLONE_FILES
        *iv_return = CLONE_FILES;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 12:
    return constant_12 (aTHX_ name, iv_return);
    break;
  case 13:
    /* Names all of length 13.  */
    /* CLONE_SIGHAND CLONE_SYSVSEM CLONE_NEWNS CLONE_NEWUSER */
    /* Offset 12 gives the best switch position.  */
    switch (name[12]) {
    case 'D':
      if (memEQ(name, "CLONE_SIGHAN", 12)) {
      /*                           D      */
#ifdef CLONE_SIGHAND
        *iv_return = CLONE_SIGHAND;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'N':
      if (memEQ(name, "CLONE_NEWNS", 12)) {
      /*                        ^        */
#ifdef CLONE_NEWNS
        *iv_return = CLONE_NEWNS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
	  break;
    case 'M':
      if (memEQ(name, "CLONE_SYSVSE", 12)) {
      /*                           M      */
#ifdef CLONE_SYSVSEM
        *iv_return = CLONE_SYSVSEM;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'U':
      if (memEQ(name, "CLONE_NEWUS", 12)) {
      /*                        ^        */
#ifdef CLONE_NEWSER
        *iv_return = CLONE_NEWUSER;
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

