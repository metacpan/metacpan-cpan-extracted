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

#!/usr/bin/perl5.8.8 -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(SANE_STATUS_ACCESS_DENIED SANE_STATUS_CANCELLED
	       SANE_STATUS_COVER_OPEN SANE_STATUS_DEVICE_BUSY SANE_STATUS_EOF
	       SANE_STATUS_GOOD SANE_STATUS_INVAL SANE_STATUS_IO_ERROR
	       SANE_STATUS_JAMMED SANE_STATUS_NO_DOCS SANE_STATUS_NO_MEM
	       SANE_STATUS_UNSUPPORTED));

print constant_types(); # macro defs
foreach (C_constant ("Graphics::SANE", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Graphics::SANE", $types);
__END__
   */

  switch (len) {
  case 15:
    if (memEQ(name, "SANE_STATUS_EOF", 15)) {
      *iv_return = SANE_STATUS_EOF;
      return PERL_constant_ISIV;
    }
    break;
  case 16:
    if (memEQ(name, "SANE_STATUS_GOOD", 16)) {
      *iv_return = SANE_STATUS_GOOD;
      return PERL_constant_ISIV;
    }
    break;
  case 17:
    if (memEQ(name, "SANE_STATUS_INVAL", 17)) {
      *iv_return = SANE_STATUS_INVAL;
      return PERL_constant_ISIV;
    }
    break;
  case 18:
    /* Names all of length 18.  */
    /* SANE_STATUS_JAMMED SANE_STATUS_NO_MEM */
    /* Offset 12 gives the best switch position.  */
    switch (name[12]) {
    case 'J':
      if (memEQ(name, "SANE_STATUS_JAMMED", 18)) {
      /*                           ^            */
        *iv_return = SANE_STATUS_JAMMED;
        return PERL_constant_ISIV;
      }
      break;
    case 'N':
      if (memEQ(name, "SANE_STATUS_NO_MEM", 18)) {
      /*                           ^            */
        *iv_return = SANE_STATUS_NO_MEM;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 19:
    if (memEQ(name, "SANE_STATUS_NO_DOCS", 19)) {
      *iv_return = SANE_STATUS_NO_DOCS;
      return PERL_constant_ISIV;
    }
    break;
  case 20:
    if (memEQ(name, "SANE_STATUS_IO_ERROR", 20)) {
      *iv_return = SANE_STATUS_IO_ERROR;
      return PERL_constant_ISIV;
    }
    break;
  case 21:
    if (memEQ(name, "SANE_STATUS_CANCELLED", 21)) {
      *iv_return = SANE_STATUS_CANCELLED;
      return PERL_constant_ISIV;
    }
    break;
  case 22:
    if (memEQ(name, "SANE_STATUS_COVER_OPEN", 22)) {
      *iv_return = SANE_STATUS_COVER_OPEN;
      return PERL_constant_ISIV;
    }
    break;
  case 23:
    /* Names all of length 23.  */
    /* SANE_STATUS_DEVICE_BUSY SANE_STATUS_UNSUPPORTED */
    /* Offset 20 gives the best switch position.  */
    switch (name[20]) {
    case 'T':
      if (memEQ(name, "SANE_STATUS_UNSUPPORTED", 23)) {
      /*                                   ^         */
        *iv_return = SANE_STATUS_UNSUPPORTED;
        return PERL_constant_ISIV;
      }
      break;
    case 'U':
      if (memEQ(name, "SANE_STATUS_DEVICE_BUSY", 23)) {
      /*                                   ^         */
        *iv_return = SANE_STATUS_DEVICE_BUSY;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 25:
    if (memEQ(name, "SANE_STATUS_ACCESS_DENIED", 25)) {
      *iv_return = SANE_STATUS_ACCESS_DENIED;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

