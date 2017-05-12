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
     DBX_DATA_READ DBX_FLAG_BODY DBX_ITEMCOUNT DBX_NEWS_ITEM DBX_TYPE_NEWS
     DBX_TYPE_VOID */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'B':
    if (memEQ(name, "DBX_FLAG_BODY", 13)) {
    /*                        ^          */
#ifdef DBX_FLAG_BODY
      *iv_return = DBX_FLAG_BODY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "DBX_NEWS_ITEM", 13)) {
    /*                        ^          */
#ifdef DBX_NEWS_ITEM
      *iv_return = DBX_NEWS_ITEM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "DBX_TYPE_NEWS", 13)) {
    /*                        ^          */
#ifdef DBX_TYPE_NEWS
      *iv_return = DBX_TYPE_NEWS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "DBX_ITEMCOUNT", 13)) {
    /*                        ^          */
#ifdef DBX_ITEMCOUNT
      *iv_return = DBX_ITEMCOUNT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "DBX_DATA_READ", 13)) {
    /*                        ^          */
#ifdef DBX_DATA_READ
      *iv_return = DBX_DATA_READ;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "DBX_TYPE_VOID", 13)) {
    /*                        ^          */
#ifdef DBX_TYPE_VOID
      *iv_return = DBX_TYPE_VOID;
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
     DBX_INDEXCOUNT DBX_INDEX_READ DBX_TYPE_EMAIL */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'M':
    if (memEQ(name, "DBX_TYPE_EMAIL", 14)) {
    /*                         ^          */
#ifdef DBX_TYPE_EMAIL
      *iv_return = DBX_TYPE_EMAIL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "DBX_INDEXCOUNT", 14)) {
    /*                         ^          */
#ifdef DBX_INDEXCOUNT
      *iv_return = DBX_INDEXCOUNT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "DBX_INDEX_READ", 14)) {
    /*                         ^          */
#ifdef DBX_INDEX_READ
      *iv_return = DBX_INDEX_READ;
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

#!/usr/opt/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(DBX_BADFILE DBX_DATA_READ DBX_EMAIL_FLAG_ISSEEN DBX_FLAG_BODY
	       DBX_INDEXCOUNT DBX_INDEX_OVERREAD DBX_INDEX_READ
	       DBX_INDEX_UNDERREAD DBX_ITEMCOUNT DBX_NEWS_ITEM DBX_NOERROR
	       DBX_TYPE_EMAIL DBX_TYPE_FOLDER DBX_TYPE_NEWS DBX_TYPE_VOID));

print constant_types(); # macro defs
foreach (C_constant ("Mail::Transport::Dbx", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Mail::Transport::Dbx", $types);
__END__
   */

  switch (len) {
  case 11:
    /* Names all of length 11.  */
    /* DBX_BADFILE DBX_NOERROR */
    /* Offset 6 gives the best switch position.  */
    switch (name[6]) {
    case 'D':
      if (memEQ(name, "DBX_BADFILE", 11)) {
      /*                     ^           */
#ifdef DBX_BADFILE
        *iv_return = DBX_BADFILE;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'E':
      if (memEQ(name, "DBX_NOERROR", 11)) {
      /*                     ^           */
#ifdef DBX_NOERROR
        *iv_return = DBX_NOERROR;
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
    return constant_14 (aTHX_ name, iv_return);
    break;
  case 15:
    if (memEQ(name, "DBX_TYPE_FOLDER", 15)) {
#ifdef DBX_TYPE_FOLDER
      *iv_return = DBX_TYPE_FOLDER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 18:
    if (memEQ(name, "DBX_INDEX_OVERREAD", 18)) {
#ifdef DBX_INDEX_OVERREAD
      *iv_return = DBX_INDEX_OVERREAD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 19:
    if (memEQ(name, "DBX_INDEX_UNDERREAD", 19)) {
#ifdef DBX_INDEX_UNDERREAD
      *iv_return = DBX_INDEX_UNDERREAD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 21:
    if (memEQ(name, "DBX_EMAIL_FLAG_ISSEEN", 21)) {
#ifdef DBX_EMAIL_FLAG_ISSEEN
      *iv_return = DBX_EMAIL_FLAG_ISSEEN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

