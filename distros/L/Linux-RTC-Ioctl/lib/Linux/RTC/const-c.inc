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
constant_6 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     RTC_AF RTC_PF RTC_UF */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'A':
    if (memEQ(name, "RTC_AF", 6)) {
    /*                   ^       */
#ifdef RTC_AF
      *iv_return = (IV)RTC_AF;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "RTC_PF", 6)) {
    /*                   ^       */
#ifdef RTC_PF
      *iv_return = (IV)RTC_PF;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "RTC_UF", 6)) {
    /*                   ^       */
#ifdef RTC_UF
      *iv_return = (IV)RTC_UF;
      return PERL_constant_ISUV;
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
     RTC_AIE_ON RTC_PIE_ON RTC_UIE_ON RTC_VL_CLR RTC_WIE_ON */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'A':
    if (memEQ(name, "RTC_AIE_ON", 10)) {
    /*                   ^            */
#ifdef RTC_AIE_ON
      *iv_return = (IV)RTC_AIE_ON;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "RTC_PIE_ON", 10)) {
    /*                   ^            */
#ifdef RTC_PIE_ON
      *iv_return = (IV)RTC_PIE_ON;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "RTC_UIE_ON", 10)) {
    /*                   ^            */
#ifdef RTC_UIE_ON
      *iv_return = (IV)RTC_UIE_ON;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "RTC_VL_CLR", 10)) {
    /*                   ^            */
#ifdef RTC_VL_CLR
      *iv_return = (IV)RTC_VL_CLR;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "RTC_WIE_ON", 10)) {
    /*                   ^            */
#ifdef RTC_WIE_ON
      *iv_return = (IV)RTC_WIE_ON;
      return PERL_constant_ISUV;
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
     RTC_AIE_OFF RTC_ALM_SET RTC_PIE_OFF RTC_PLL_GET RTC_PLL_SET RTC_RD_TIME
     RTC_UIE_OFF RTC_VL_READ RTC_WIE_OFF */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'A':
    if (memEQ(name, "RTC_AIE_OFF", 11)) {
    /*                   ^             */
#ifdef RTC_AIE_OFF
      *iv_return = (IV)RTC_AIE_OFF;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "RTC_ALM_SET", 11)) {
    /*                   ^             */
#ifdef RTC_ALM_SET
      *iv_return = (IV)RTC_ALM_SET;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "RTC_PIE_OFF", 11)) {
    /*                   ^             */
#ifdef RTC_PIE_OFF
      *iv_return = (IV)RTC_PIE_OFF;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "RTC_PLL_GET", 11)) {
    /*                   ^             */
#ifdef RTC_PLL_GET
      *iv_return = (IV)RTC_PLL_GET;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "RTC_PLL_SET", 11)) {
    /*                   ^             */
#ifdef RTC_PLL_SET
      *iv_return = (IV)RTC_PLL_SET;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "RTC_RD_TIME", 11)) {
    /*                   ^             */
#ifdef RTC_RD_TIME
      *iv_return = (IV)RTC_RD_TIME;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "RTC_UIE_OFF", 11)) {
    /*                   ^             */
#ifdef RTC_UIE_OFF
      *iv_return = (IV)RTC_UIE_OFF;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "RTC_VL_READ", 11)) {
    /*                   ^             */
#ifdef RTC_VL_READ
      *iv_return = (IV)RTC_VL_READ;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "RTC_WIE_OFF", 11)) {
    /*                   ^             */
#ifdef RTC_WIE_OFF
      *iv_return = (IV)RTC_WIE_OFF;
      return PERL_constant_ISUV;
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
     RTC_ALM_READ RTC_IRQP_SET RTC_MAX_FREQ RTC_SET_TIME RTC_WKALM_RD */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'A':
    if (memEQ(name, "RTC_MAX_FREQ", 12)) {
    /*                    ^             */
#ifdef RTC_MAX_FREQ
      *iv_return = (IV)RTC_MAX_FREQ;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "RTC_SET_TIME", 12)) {
    /*                    ^             */
#ifdef RTC_SET_TIME
      *iv_return = (IV)RTC_SET_TIME;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "RTC_WKALM_RD", 12)) {
    /*                    ^             */
#ifdef RTC_WKALM_RD
      *iv_return = (IV)RTC_WKALM_RD;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "RTC_ALM_READ", 12)) {
    /*                    ^             */
#ifdef RTC_ALM_READ
      *iv_return = (IV)RTC_ALM_READ;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "RTC_IRQP_SET", 12)) {
    /*                    ^             */
#ifdef RTC_IRQP_SET
      *iv_return = (IV)RTC_IRQP_SET;
      return PERL_constant_ISUV;
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
     RTC_EPOCH_SET RTC_IRQP_READ RTC_WKALM_SET */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'K':
    if (memEQ(name, "RTC_WKALM_SET", 13)) {
    /*                    ^              */
#ifdef RTC_WKALM_SET
      *iv_return = (IV)RTC_WKALM_SET;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "RTC_EPOCH_SET", 13)) {
    /*                    ^              */
#ifdef RTC_EPOCH_SET
      *iv_return = (IV)RTC_EPOCH_SET;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "RTC_IRQP_READ", 13)) {
    /*                    ^              */
#ifdef RTC_IRQP_READ
      *iv_return = (IV)RTC_IRQP_READ;
      return PERL_constant_ISUV;
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

#!/usr/bin/perl5.22.2 -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(UV)};
my @names = (qw(RTC_AF RTC_AIE_OFF RTC_AIE_ON RTC_ALM_READ RTC_ALM_SET
	       RTC_EPOCH_READ RTC_EPOCH_SET RTC_IRQF RTC_IRQP_READ RTC_IRQP_SET
	       RTC_MAX_FREQ RTC_PF RTC_PIE_OFF RTC_PIE_ON RTC_PLL_GET
	       RTC_PLL_SET RTC_RD_TIME RTC_SET_TIME RTC_UF RTC_UIE_OFF
	       RTC_UIE_ON RTC_VL_CLR RTC_VL_READ RTC_WIE_OFF RTC_WIE_ON
	       RTC_WKALM_RD RTC_WKALM_SET));

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Linux::RTC::Ioctl", 'constant', 'UV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Linux::RTC::Ioctl", $types);
__END__
   */

  switch (len) {
  case 6:
    return constant_6 (aTHX_ name, iv_return);
    break;
  case 8:
    if (memEQ(name, "RTC_IRQF", 8)) {
#ifdef RTC_IRQF
      *iv_return = (IV)RTC_IRQF;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
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
    if (memEQ(name, "RTC_EPOCH_READ", 14)) {
#ifdef RTC_EPOCH_READ
      *iv_return = (IV)RTC_EPOCH_READ;
      return PERL_constant_ISUV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 15:
    if (memEQ(name, "RTC_RECORD_SIZE", 15)) {
	*iv_return = (IV)(sizeof(unsigned long));
	return PERL_constant_ISUV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

