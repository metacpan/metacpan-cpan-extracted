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
     JIT_PROT_NONE JIT_PROT_READ jit_abi_cdecl */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'N':
    if (memEQ(name, "JIT_PROT_NONE", 13)) {
    /*                        ^          */
      *iv_return = JIT_PROT_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "JIT_PROT_READ", 13)) {
    /*                        ^          */
      *iv_return = JIT_PROT_READ;
      return PERL_constant_ISIV;
    }
    break;
  case 'd':
    if (memEQ(name, "jit_abi_cdecl", 13)) {
    /*                        ^          */
      *iv_return = jit_abi_cdecl;
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
            {name=>"JIT_PROT_EXEC_READ", type=>"IV", macro=>"1"},
            {name=>"JIT_PROT_EXEC_READ_WRITE", type=>"IV", macro=>"1"},
            {name=>"JIT_PROT_NONE", type=>"IV", macro=>"1"},
            {name=>"JIT_PROT_READ", type=>"IV", macro=>"1"},
            {name=>"JIT_PROT_READ_WRITE", type=>"IV", macro=>"1"},
            {name=>"jit_abi_cdecl", type=>"IV", macro=>"1"},
            {name=>"jit_abi_fastcall", type=>"IV", macro=>"1"},
            {name=>"jit_abi_stdcall", type=>"IV", macro=>"1"},
            {name=>"jit_abi_vararg", type=>"IV", macro=>"1"},
            {name=>"jit_label_undefined", type=>"IV", macro=>"1"});

print constant_types(), "\n"; # macro defs
foreach (C_constant ("LibJIT", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("LibJIT", $types);
__END__
   */

  switch (len) {
  case 13:
    return constant_13 (aTHX_ name, iv_return);
    break;
  case 14:
    if (memEQ(name, "jit_abi_vararg", 14)) {
      *iv_return = jit_abi_vararg;
      return PERL_constant_ISIV;
    }
    break;
  case 15:
    if (memEQ(name, "jit_abi_stdcall", 15)) {
      *iv_return = jit_abi_stdcall;
      return PERL_constant_ISIV;
    }
    break;
  case 16:
    if (memEQ(name, "jit_abi_fastcall", 16)) {
      *iv_return = jit_abi_fastcall;
      return PERL_constant_ISIV;
    }
    break;
  case 18:
    if (memEQ(name, "JIT_PROT_EXEC_READ", 18)) {
      *iv_return = JIT_PROT_EXEC_READ;
      return PERL_constant_ISIV;
    }
    break;
  case 19:
    /* Names all of length 19.  */
    /* JIT_PROT_READ_WRITE jit_label_undefined */
    /* Offset 13 gives the best switch position.  */
    switch (name[13]) {
    case '_':
      if (memEQ(name, "JIT_PROT_READ_WRITE", 19)) {
      /*                            ^            */
        *iv_return = JIT_PROT_READ_WRITE;
        return PERL_constant_ISIV;
      }
      break;
    case 'e':
      if (memEQ(name, "jit_label_undefined", 19)) {
      /*                            ^            */
        *iv_return = jit_label_undefined;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 24:
    if (memEQ(name, "JIT_PROT_EXEC_READ_WRITE", 24)) {
      *iv_return = JIT_PROT_EXEC_READ_WRITE;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

