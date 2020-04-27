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
constant_11 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     MAGIC_CHECK MAGIC_DEBUG MAGIC_ERROR */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'C':
    if (memEQ(name, "MAGIC_CHECK", 11)) {
    /*                     ^           */
#ifdef MAGIC_CHECK
      *iv_return = MAGIC_CHECK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "MAGIC_DEBUG", 11)) {
    /*                     ^           */
#ifdef MAGIC_DEBUG
      *iv_return = MAGIC_DEBUG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "MAGIC_ERROR", 11)) {
    /*                     ^           */
#ifdef MAGIC_ERROR
      *iv_return = MAGIC_ERROR;
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
constant_21 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     MAGIC_PARAM_BYTES_MAX MAGIC_PARAM_INDIR_MAX MAGIC_PARAM_REGEX_MAX */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'R':
    if (memEQ(name, "MAGIC_PARAM_INDIR_MAX", 21)) {
    /*                               ^           */
#ifdef MAGIC_PARAM_INDIR_MAX
      *iv_return = MAGIC_PARAM_INDIR_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "MAGIC_PARAM_BYTES_MAX", 21)) {
    /*                               ^           */
#ifdef MAGIC_PARAM_BYTES_MAX
      *iv_return = MAGIC_PARAM_BYTES_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "MAGIC_PARAM_REGEX_MAX", 21)) {
    /*                               ^           */
#ifdef MAGIC_PARAM_REGEX_MAX
      *iv_return = MAGIC_PARAM_REGEX_MAX;
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
constant_25 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     MAGIC_PARAM_ELF_NOTES_MAX MAGIC_PARAM_ELF_PHNUM_MAX
     MAGIC_PARAM_ELF_SHNUM_MAX */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'N':
    if (memEQ(name, "MAGIC_PARAM_ELF_NOTES_MAX", 25)) {
    /*                               ^               */
#ifdef MAGIC_PARAM_ELF_NOTES_MAX
      *iv_return = MAGIC_PARAM_ELF_NOTES_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "MAGIC_PARAM_ELF_PHNUM_MAX", 25)) {
    /*                               ^               */
#ifdef MAGIC_PARAM_ELF_PHNUM_MAX
      *iv_return = MAGIC_PARAM_ELF_PHNUM_MAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "MAGIC_PARAM_ELF_SHNUM_MAX", 25)) {
    /*                               ^               */
#ifdef MAGIC_PARAM_ELF_SHNUM_MAX
      *iv_return = MAGIC_PARAM_ELF_SHNUM_MAX;
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

#!/home/autarch/perl5/perlbrew/perls/perl-5.30.1/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(MAGIC_CHECK MAGIC_COMPRESS MAGIC_CONTINUE MAGIC_DEBUG
	       MAGIC_DEVICES MAGIC_ERROR MAGIC_MIME MAGIC_NONE
	       MAGIC_PARAM_BYTES_MAX MAGIC_PARAM_ELF_NOTES_MAX
	       MAGIC_PARAM_ELF_PHNUM_MAX MAGIC_PARAM_ELF_SHNUM_MAX
	       MAGIC_PARAM_INDIR_MAX MAGIC_PARAM_NAME_MAX MAGIC_PARAM_REGEX_MAX
	       MAGIC_PRESERVE_ATIME MAGIC_RAW MAGIC_SYMLINK));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("File::LibMagic", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("File::LibMagic", $types);
__END__
   */

  switch (len) {
  case 9:
    if (memEQ(name, "MAGIC_RAW", 9)) {
#ifdef MAGIC_RAW
      *iv_return = MAGIC_RAW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 10:
    /* Names all of length 10.  */
    /* MAGIC_MIME MAGIC_NONE */
    /* Offset 6 gives the best switch position.  */
    switch (name[6]) {
    case 'M':
      if (memEQ(name, "MAGIC_MIME", 10)) {
      /*                     ^          */
#ifdef MAGIC_MIME
        *iv_return = MAGIC_MIME;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'N':
      if (memEQ(name, "MAGIC_NONE", 10)) {
      /*                     ^          */
#ifdef MAGIC_NONE
        *iv_return = MAGIC_NONE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 11:
    return constant_11 (aTHX_ name, iv_return);
    break;
  case 13:
    /* Names all of length 13.  */
    /* MAGIC_DEVICES MAGIC_SYMLINK */
    /* Offset 9 gives the best switch position.  */
    switch (name[9]) {
    case 'I':
      if (memEQ(name, "MAGIC_DEVICES", 13)) {
      /*                        ^          */
#ifdef MAGIC_DEVICES
        *iv_return = MAGIC_DEVICES;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'L':
      if (memEQ(name, "MAGIC_SYMLINK", 13)) {
      /*                        ^          */
#ifdef MAGIC_SYMLINK
        *iv_return = MAGIC_SYMLINK;
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
    /* MAGIC_COMPRESS MAGIC_CONTINUE */
    /* Offset 8 gives the best switch position.  */
    switch (name[8]) {
    case 'M':
      if (memEQ(name, "MAGIC_COMPRESS", 14)) {
      /*                       ^            */
#ifdef MAGIC_COMPRESS
        *iv_return = MAGIC_COMPRESS;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'N':
      if (memEQ(name, "MAGIC_CONTINUE", 14)) {
      /*                       ^            */
#ifdef MAGIC_CONTINUE
        *iv_return = MAGIC_CONTINUE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 20:
    /* Names all of length 20.  */
    /* MAGIC_PARAM_NAME_MAX MAGIC_PRESERVE_ATIME */
    /* Offset 13 gives the best switch position.  */
    switch (name[13]) {
    case 'A':
      if (memEQ(name, "MAGIC_PARAM_NAME_MAX", 20)) {
      /*                            ^             */
#ifdef MAGIC_PARAM_NAME_MAX
        *iv_return = MAGIC_PARAM_NAME_MAX;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'E':
      if (memEQ(name, "MAGIC_PRESERVE_ATIME", 20)) {
      /*                            ^             */
#ifdef MAGIC_PRESERVE_ATIME
        *iv_return = MAGIC_PRESERVE_ATIME;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 21:
    return constant_21 (aTHX_ name, iv_return);
    break;
  case 25:
    return constant_25 (aTHX_ name, iv_return);
    break;
  }
  return PERL_constant_NOTFOUND;
}

