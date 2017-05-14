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
constant_9 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LUA_NOREF LUA_TNONE LUA_YIELD */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case 'D':
    if (memEQ(name, "LUA_YIEL", 8)) {
    /*                       D     */
#ifdef LUA_YIELD
      *iv_return = LUA_YIELD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "LUA_TNON", 8)) {
    /*                       E     */
#ifdef LUA_TNONE
      *iv_return = LUA_TNONE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'F':
    if (memEQ(name, "LUA_NORE", 8)) {
    /*                       F     */
#ifdef LUA_NOREF
      *iv_return = LUA_NOREF;
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
constant_10 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LUA_ERRERR LUA_ERRMEM LUA_ERRRUN LUA_GCSTEP LUA_GCSTOP LUA_REFNIL
     LUA_TTABLE */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'E':
    if (memEQ(name, "LUA_TTABL", 9)) {
    /*                        E     */
#ifdef LUA_TTABLE
      *iv_return = LUA_TTABLE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "LUA_REFNI", 9)) {
    /*                        L     */
#ifdef LUA_REFNIL
      *iv_return = LUA_REFNIL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "LUA_ERRME", 9)) {
    /*                        M     */
#ifdef LUA_ERRMEM
      *iv_return = LUA_ERRMEM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "LUA_ERRRU", 9)) {
    /*                        N     */
#ifdef LUA_ERRRUN
      *iv_return = LUA_ERRRUN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "LUA_GCSTE", 9)) {
    /*                        P     */
#ifdef LUA_GCSTEP
      *iv_return = LUA_GCSTEP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LUA_GCSTO", 9)) {
    /*                        P     */
#ifdef LUA_GCSTOP
      *iv_return = LUA_GCSTOP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "LUA_ERRER", 9)) {
    /*                        R     */
#ifdef LUA_ERRERR
      *iv_return = LUA_ERRERR;
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
     LUA_ERRFILE LUA_GCCOUNT LUA_HOOKRET LUA_MASKRET LUA_MULTRET LUA_TNUMBER
     LUA_TSTRING LUA_TTHREAD */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'C':
    if (memEQ(name, "LUA_GCCOUNT", 11)) {
    /*                     ^           */
#ifdef LUA_GCCOUNT
      *iv_return = LUA_GCCOUNT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "LUA_TTHREAD", 11)) {
    /*                     ^           */
#ifdef LUA_TTHREAD
      *iv_return = LUA_TTHREAD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "LUA_MULTRET", 11)) {
    /*                     ^           */
#ifdef LUA_MULTRET
      *iv_return = LUA_MULTRET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "LUA_HOOKRET", 11)) {
    /*                     ^           */
#ifdef LUA_HOOKRET
      *iv_return = LUA_HOOKRET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "LUA_ERRFILE", 11)) {
    /*                     ^           */
#ifdef LUA_ERRFILE
      *iv_return = LUA_ERRFILE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "LUA_MASKRET", 11)) {
    /*                     ^           */
#ifdef LUA_MASKRET
      *iv_return = LUA_MASKRET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "LUA_TSTRING", 11)) {
    /*                     ^           */
#ifdef LUA_TSTRING
      *iv_return = LUA_TSTRING;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "LUA_TNUMBER", 11)) {
    /*                     ^           */
#ifdef LUA_TNUMBER
      *iv_return = LUA_TNUMBER;
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
     LUA_GCCOUNTB LUA_HOOKCALL LUA_HOOKLINE LUA_MASKCALL LUA_MASKLINE
     LUA_MINSTACK LUA_TBOOLEAN */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'B':
    if (memEQ(name, "LUA_GCCOUNT", 11)) {
    /*                          B      */
#ifdef LUA_GCCOUNTB
      *iv_return = LUA_GCCOUNTB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "LUA_HOOKLIN", 11)) {
    /*                          E      */
#ifdef LUA_HOOKLINE
      *iv_return = LUA_HOOKLINE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LUA_MASKLIN", 11)) {
    /*                          E      */
#ifdef LUA_MASKLINE
      *iv_return = LUA_MASKLINE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "LUA_MINSTAC", 11)) {
    /*                          K      */
#ifdef LUA_MINSTACK
      *iv_return = LUA_MINSTACK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "LUA_HOOKCAL", 11)) {
    /*                          L      */
#ifdef LUA_HOOKCALL
      *iv_return = LUA_HOOKCALL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LUA_MASKCAL", 11)) {
    /*                          L      */
#ifdef LUA_MASKCALL
      *iv_return = LUA_MASKCALL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "LUA_TBOOLEA", 11)) {
    /*                          N      */
#ifdef LUA_TBOOLEAN
      *iv_return = LUA_TBOOLEAN;
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
     LUA_ERRSYNTAX LUA_GCCOLLECT LUA_GCRESTART LUA_HOOKCOUNT LUA_MASKCOUNT
     LUA_TFUNCTION LUA_TUSERDATA */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'A':
    if (memEQ(name, "LUA_ERRSYNTAX", 13)) {
    /*                          ^        */
#ifdef LUA_ERRSYNTAX
      *iv_return = LUA_ERRSYNTAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "LUA_GCCOLLECT", 13)) {
    /*                          ^        */
#ifdef LUA_GCCOLLECT
      *iv_return = LUA_GCCOLLECT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "LUA_HOOKCOUNT", 13)) {
    /*                          ^        */
#ifdef LUA_HOOKCOUNT
      *iv_return = LUA_HOOKCOUNT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "LUA_MASKCOUNT", 13)) {
    /*                          ^        */
#ifdef LUA_MASKCOUNT
      *iv_return = LUA_MASKCOUNT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "LUA_TFUNCTION", 13)) {
    /*                          ^        */
#ifdef LUA_TFUNCTION
      *iv_return = LUA_TFUNCTION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "LUA_GCRESTART", 13)) {
    /*                          ^        */
#ifdef LUA_GCRESTART
      *iv_return = LUA_GCRESTART;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "LUA_TUSERDATA", 13)) {
    /*                          ^        */
#ifdef LUA_TUSERDATA
      *iv_return = LUA_TUSERDATA;
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
constant_16 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     LUA_ENVIRONINDEX LUA_GCSETSTEPMUL LUA_GLOBALSINDEX */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'N':
    if (memEQ(name, "LUA_ENVIRONINDEX", 16)) {
    /*                         ^            */
#ifdef LUA_ENVIRONINDEX
      *iv_return = LUA_ENVIRONINDEX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "LUA_GLOBALSINDEX", 16)) {
    /*                         ^            */
#ifdef LUA_GLOBALSINDEX
      *iv_return = LUA_GLOBALSINDEX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "LUA_GCSETSTEPMUL", 16)) {
    /*                         ^            */
#ifdef LUA_GCSETSTEPMUL
      *iv_return = LUA_GCSETSTEPMUL;
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

#!/proj/axaf/ots/pkgs/perl-5.12/x86_64-linux_debian-5.0/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(LUA_ENVIRONINDEX LUA_ERRERR LUA_ERRFILE LUA_ERRMEM LUA_ERRRUN
	       LUA_ERRSYNTAX LUA_GCCOLLECT LUA_GCCOUNT LUA_GCCOUNTB
	       LUA_GCRESTART LUA_GCSETPAUSE LUA_GCSETSTEPMUL LUA_GCSTEP
	       LUA_GCSTOP LUA_GLOBALSINDEX LUA_HOOKCALL LUA_HOOKCOUNT
	       LUA_HOOKLINE LUA_HOOKRET LUA_HOOKTAILRET LUA_MASKCALL
	       LUA_MASKCOUNT LUA_MASKLINE LUA_MASKRET LUA_MINSTACK LUA_MULTRET
	       LUA_NOREF LUA_REFNIL LUA_REGISTRYINDEX LUA_TBOOLEAN
	       LUA_TFUNCTION LUA_TLIGHTUSERDATA LUA_TNIL LUA_TNONE LUA_TNUMBER
	       LUA_TSTRING LUA_TTABLE LUA_TTHREAD LUA_TUSERDATA LUA_VERSION_NUM
	       LUA_YIELD));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Lua::API", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Lua::API", $types);
__END__
   */

  switch (len) {
  case 8:
    if (memEQ(name, "LUA_TNIL", 8)) {
#ifdef LUA_TNIL
      *iv_return = LUA_TNIL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 9:
    return constant_9 (aTHX_ name, iv_return);
    break;
  case 10:
    return constant_10 (aTHX_ name, iv_return);
    break;
  case 11:
    return constant_11 (aTHX_ name, iv_return);
    break;
  case 12:
    return constant_12 (aTHX_ name, iv_return);
    break;
  case 13:
    return constant_13 (aTHX_ name, iv_return);
    break;
  case 14:
    if (memEQ(name, "LUA_GCSETPAUSE", 14)) {
#ifdef LUA_GCSETPAUSE
      *iv_return = LUA_GCSETPAUSE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 15:
    /* Names all of length 15.  */
    /* LUA_HOOKTAILRET LUA_VERSION_NUM */
    /* Offset 6 gives the best switch position.  */
    switch (name[6]) {
    case 'O':
      if (memEQ(name, "LUA_HOOKTAILRET", 15)) {
      /*                     ^               */
#ifdef LUA_HOOKTAILRET
        *iv_return = LUA_HOOKTAILRET;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'R':
      if (memEQ(name, "LUA_VERSION_NUM", 15)) {
      /*                     ^               */
#ifdef LUA_VERSION_NUM
        *iv_return = LUA_VERSION_NUM;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 16:
    return constant_16 (aTHX_ name, iv_return);
    break;
  case 17:
    if (memEQ(name, "LUA_REGISTRYINDEX", 17)) {
#ifdef LUA_REGISTRYINDEX
      *iv_return = LUA_REGISTRYINDEX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 18:
    if (memEQ(name, "LUA_TLIGHTUSERDATA", 18)) {
#ifdef LUA_TLIGHTUSERDATA
      *iv_return = LUA_TLIGHTUSERDATA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

