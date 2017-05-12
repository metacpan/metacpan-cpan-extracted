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
my @names = (qw(CP_ALLOW_PRIVATE_ACCESS CP_BUFFER_BYTES CP_VERSION_MAJOR
	       CP_VERSION_MINOR CP_VERSION_RELEASE cpcalloc cpfree cprealloc));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Games::Chipmunk", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Games::Chipmunk", $types);
__END__
   */

  switch (len) {
  case 6:
    if (memEQ(name, "cpfree", 6)) {
#ifdef cpfree
      *iv_return = cpfree;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 8:
    if (memEQ(name, "cpcalloc", 8)) {
#ifdef cpcalloc
      *iv_return = cpcalloc;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 9:
    if (memEQ(name, "cprealloc", 9)) {
#ifdef cprealloc
      *iv_return = cprealloc;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 15:
    if (memEQ(name, "CP_BUFFER_BYTES", 15)) {
#ifdef CP_BUFFER_BYTES
      *iv_return = CP_BUFFER_BYTES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 16:
    /* Names all of length 16.  */
    /* CP_VERSION_MAJOR CP_VERSION_MINOR */
    /* Offset 13 gives the best switch position.  */
    switch (name[13]) {
    case 'J':
      if (memEQ(name, "CP_VERSION_MAJOR", 16)) {
      /*                            ^         */
#ifdef CP_VERSION_MAJOR
        *iv_return = CP_VERSION_MAJOR;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'N':
      if (memEQ(name, "CP_VERSION_MINOR", 16)) {
      /*                            ^         */
#ifdef CP_VERSION_MINOR
        *iv_return = CP_VERSION_MINOR;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 18:
    if (memEQ(name, "CP_VERSION_RELEASE", 18)) {
#ifdef CP_VERSION_RELEASE
      *iv_return = CP_VERSION_RELEASE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 23:
    if (memEQ(name, "CP_ALLOW_PRIVATE_ACCESS", 23)) {
#ifdef CP_ALLOW_PRIVATE_ACCESS
      *iv_return = CP_ALLOW_PRIVATE_ACCESS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

