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
constant_5 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GPIOA GPIOB GPPUA GPPUB INPUT INTFA INTFB IOCON IPOLA IPOLB OLATA OLATB */
  /* Offset 2 gives the best switch position.  */
  switch (name[2]) {
  case 'A':
    if (memEQ(name, "OLATA", 5)) {
    /*                 ^        */
      *iv_return = OLATA;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "OLATB", 5)) {
    /*                 ^        */
      *iv_return = OLATB;
      return PERL_constant_ISIV;
    }
    break;
  case 'C':
    if (memEQ(name, "IOCON", 5)) {
    /*                 ^        */
      *iv_return = IOCON;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "GPIOA", 5)) {
    /*                 ^        */
      *iv_return = GPIOA;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "GPIOB", 5)) {
    /*                 ^        */
      *iv_return = GPIOB;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "IPOLA", 5)) {
    /*                 ^        */
      *iv_return = IPOLA;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "IPOLB", 5)) {
    /*                 ^        */
      *iv_return = IPOLB;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "GPPUA", 5)) {
    /*                 ^        */
      *iv_return = GPPUA;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "GPPUB", 5)) {
    /*                 ^        */
      *iv_return = GPPUB;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "INPUT", 5)) {
    /*                 ^        */
      *iv_return = INPUT;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "INTFA", 5)) {
    /*                 ^        */
      *iv_return = INTFA;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "INTFB", 5)) {
    /*                 ^        */
      *iv_return = INTFB;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_6 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     IODIRA IODIRB ODR_ON OUTPUT */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'A':
    if (memEQ(name, "IODIR", 5)) {
    /*                    A     */
      *iv_return = IODIRA;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "IODIR", 5)) {
    /*                    B     */
      *iv_return = IODIRB;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "ODR_O", 5)) {
    /*                    N     */
      *iv_return = ODR_ON;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "OUTPU", 5)) {
    /*                    T     */
      *iv_return = OUTPUT;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_7 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BANK_ON DEFVALA DEFVALB HAEN_ON INTCAPA INTCAPB INTCONA INTCONB ODR_OFF */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'F':
    if (memEQ(name, "ODR_OFF", 7)) {
    /*                    ^       */
      *iv_return = ODR_OFF;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "DEFVALA", 7)) {
    /*                    ^       */
      *iv_return = DEFVALA;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "DEFVALB", 7)) {
    /*                    ^       */
      *iv_return = DEFVALB;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "INTCONA", 7)) {
    /*                    ^       */
      *iv_return = INTCONA;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "INTCONB", 7)) {
    /*                    ^       */
      *iv_return = INTCONB;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "BANK_ON", 7)) {
    /*                    ^       */
      *iv_return = BANK_ON;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HAEN_ON", 7)) {
    /*                    ^       */
      *iv_return = HAEN_ON;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "INTCAPA", 7)) {
    /*                    ^       */
      *iv_return = INTCAPA;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "INTCAPB", 7)) {
    /*                    ^       */
      *iv_return = INTCAPB;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_8 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BANK_OFF GPINTENA GPINTENB HAEN_OFF READ_CMD SEQOP_ON */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'A':
    if (memEQ(name, "GPINTEN", 7)) {
    /*                      A     */
      *iv_return = GPINTENA;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "GPINTEN", 7)) {
    /*                      B     */
      *iv_return = GPINTENB;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "READ_CM", 7)) {
    /*                      D     */
      *iv_return = READ_CMD;
      return PERL_constant_ISIV;
    }
    break;
  case 'F':
    if (memEQ(name, "BANK_OF", 7)) {
    /*                      F     */
      *iv_return = BANK_OFF;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "HAEN_OF", 7)) {
    /*                      F     */
      *iv_return = HAEN_OFF;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "SEQOP_O", 7)) {
    /*                      N     */
      *iv_return = SEQOP_ON;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_9 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DISSLW_ON SEQOP_OFF WRITE_CMD */
  /* Offset 3 gives the best switch position.  */
  switch (name[3]) {
  case 'O':
    if (memEQ(name, "SEQOP_OFF", 9)) {
    /*                  ^           */
      *iv_return = SEQOP_OFF;
      return PERL_constant_ISIV;
    }
    break;
  case 'S':
    if (memEQ(name, "DISSLW_ON", 9)) {
    /*                  ^           */
      *iv_return = DISSLW_ON;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "WRITE_CMD", 9)) {
    /*                  ^           */
      *iv_return = WRITE_CMD;
      return PERL_constant_ISIV;
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
my @names = (qw(),
            {name=>"BANK_OFF", type=>"IV", macro=>"1"},
            {name=>"BANK_ON", type=>"IV", macro=>"1"},
            {name=>"DEFVALA", type=>"IV", macro=>"1"},
            {name=>"DEFVALB", type=>"IV", macro=>"1"},
            {name=>"DISSLW_OFF", type=>"IV", macro=>"1"},
            {name=>"DISSLW_ON", type=>"IV", macro=>"1"},
            {name=>"GPINTENA", type=>"IV", macro=>"1"},
            {name=>"GPINTENB", type=>"IV", macro=>"1"},
            {name=>"GPIOA", type=>"IV", macro=>"1"},
            {name=>"GPIOB", type=>"IV", macro=>"1"},
            {name=>"GPIO_INTERRUPT_PIN", type=>"IV", macro=>"1"},
            {name=>"GPPUA", type=>"IV", macro=>"1"},
            {name=>"GPPUB", type=>"IV", macro=>"1"},
            {name=>"HAEN_OFF", type=>"IV", macro=>"1"},
            {name=>"HAEN_ON", type=>"IV", macro=>"1"},
            {name=>"INPUT", type=>"IV", macro=>"1"},
            {name=>"INTCAPA", type=>"IV", macro=>"1"},
            {name=>"INTCAPB", type=>"IV", macro=>"1"},
            {name=>"INTCONA", type=>"IV", macro=>"1"},
            {name=>"INTCONB", type=>"IV", macro=>"1"},
            {name=>"INTFA", type=>"IV", macro=>"1"},
            {name=>"INTFB", type=>"IV", macro=>"1"},
            {name=>"INTPOL_HIGH", type=>"IV", macro=>"1"},
            {name=>"INTPOL_LOW", type=>"IV", macro=>"1"},
            {name=>"INT_MIRROR_OFF", type=>"IV", macro=>"1"},
            {name=>"INT_MIRROR_ON", type=>"IV", macro=>"1"},
            {name=>"IOCON", type=>"IV", macro=>"1"},
            {name=>"IODIRA", type=>"IV", macro=>"1"},
            {name=>"IODIRB", type=>"IV", macro=>"1"},
            {name=>"IPOLA", type=>"IV", macro=>"1"},
            {name=>"IPOLB", type=>"IV", macro=>"1"},
            {name=>"ODR_OFF", type=>"IV", macro=>"1"},
            {name=>"ODR_ON", type=>"IV", macro=>"1"},
            {name=>"OLATA", type=>"IV", macro=>"1"},
            {name=>"OLATB", type=>"IV", macro=>"1"},
            {name=>"OUTPUT", type=>"IV", macro=>"1"},
            {name=>"READ_CMD", type=>"IV", macro=>"1"},
            {name=>"SEQOP_OFF", type=>"IV", macro=>"1"},
            {name=>"SEQOP_ON", type=>"IV", macro=>"1"},
            {name=>"WRITE_CMD", type=>"IV", macro=>"1"});

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Device::PiFace", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Device::PiFace", $types);
__END__
   */

  switch (len) {
  case 5:
    return constant_5 (aTHX_ name, iv_return);
    break;
  case 6:
    return constant_6 (aTHX_ name, iv_return);
    break;
  case 7:
    return constant_7 (aTHX_ name, iv_return);
    break;
  case 8:
    return constant_8 (aTHX_ name, iv_return);
    break;
  case 9:
    return constant_9 (aTHX_ name, iv_return);
    break;
  case 10:
    /* Names all of length 10.  */
    /* DISSLW_OFF INTPOL_LOW */
    /* Offset 2 gives the best switch position.  */
    switch (name[2]) {
    case 'S':
      if (memEQ(name, "DISSLW_OFF", 10)) {
      /*                 ^              */
        *iv_return = DISSLW_OFF;
        return PERL_constant_ISIV;
      }
      break;
    case 'T':
      if (memEQ(name, "INTPOL_LOW", 10)) {
      /*                 ^              */
        *iv_return = INTPOL_LOW;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 11:
    if (memEQ(name, "INTPOL_HIGH", 11)) {
      *iv_return = INTPOL_HIGH;
      return PERL_constant_ISIV;
    }
    break;
  case 13:
    if (memEQ(name, "INT_MIRROR_ON", 13)) {
      *iv_return = INT_MIRROR_ON;
      return PERL_constant_ISIV;
    }
    break;
  case 14:
    if (memEQ(name, "INT_MIRROR_OFF", 14)) {
      *iv_return = INT_MIRROR_OFF;
      return PERL_constant_ISIV;
    }
    break;
  case 18:
    if (memEQ(name, "GPIO_INTERRUPT_PIN", 18)) {
      *iv_return = GPIO_INTERRUPT_PIN;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

