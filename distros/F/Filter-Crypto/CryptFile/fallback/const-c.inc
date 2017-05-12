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

#!C:\perl5\bin\perl.exe -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(CRYPT_MODE_AUTO CRYPT_MODE_DECRYPT CRYPT_MODE_DECRYPTED
	       CRYPT_MODE_ENCRYPT CRYPT_MODE_ENCRYPTED));

print constant_types(); # macro defs
foreach (C_constant ("Filter::Crypto::CryptFile", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("Filter::Crypto::CryptFile", $types);
__END__
   */

  switch (len) {
  case 15:
    if (memEQ(name, "CRYPT_MODE_AUTO", 15)) {
#ifdef CRYPT_MODE_AUTO
      *iv_return = CRYPT_MODE_AUTO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 18:
    /* Names all of length 18.  */
    /* CRYPT_MODE_DECRYPT CRYPT_MODE_ENCRYPT */
    /* Offset 11 gives the best switch position.  */
    switch (name[11]) {
    case 'D':
      if (memEQ(name, "CRYPT_MODE_DECRYPT", 18)) {
      /*                          ^             */
#ifdef CRYPT_MODE_DECRYPT
        *iv_return = CRYPT_MODE_DECRYPT;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'E':
      if (memEQ(name, "CRYPT_MODE_ENCRYPT", 18)) {
      /*                          ^             */
#ifdef CRYPT_MODE_ENCRYPT
        *iv_return = CRYPT_MODE_ENCRYPT;
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
    /* CRYPT_MODE_DECRYPTED CRYPT_MODE_ENCRYPTED */
    /* Offset 11 gives the best switch position.  */
    switch (name[11]) {
    case 'D':
      if (memEQ(name, "CRYPT_MODE_DECRYPTED", 20)) {
      /*                          ^               */
#ifdef CRYPT_MODE_DECRYPTED
        *iv_return = CRYPT_MODE_DECRYPTED;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'E':
      if (memEQ(name, "CRYPT_MODE_ENCRYPTED", 20)) {
      /*                          ^               */
#ifdef CRYPT_MODE_ENCRYPTED
        *iv_return = CRYPT_MODE_ENCRYPTED;
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

