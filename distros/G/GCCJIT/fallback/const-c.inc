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
constant_17 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GCC_JIT_TYPE_BOOL GCC_JIT_TYPE_CHAR GCC_JIT_TYPE_LONG GCC_JIT_TYPE_VOID */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'D':
    if (memEQ(name, "GCC_JIT_TYPE_VOI", 16)) {
    /*                               D      */
      *iv_return = GCC_JIT_TYPE_VOID;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "GCC_JIT_TYPE_LON", 16)) {
    /*                               G      */
      *iv_return = GCC_JIT_TYPE_LONG;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "GCC_JIT_TYPE_BOO", 16)) {
    /*                               L      */
      *iv_return = GCC_JIT_TYPE_BOOL;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "GCC_JIT_TYPE_CHA", 16)) {
    /*                               R      */
      *iv_return = GCC_JIT_TYPE_CHAR;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_21 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GCC_JIT_COMPARISON_EQ GCC_JIT_COMPARISON_GE GCC_JIT_COMPARISON_GT
     GCC_JIT_COMPARISON_LE GCC_JIT_COMPARISON_LT GCC_JIT_COMPARISON_NE
     GCC_JIT_TYPE_FILE_PTR GCC_JIT_TYPE_VOID_PTR */
  /* Offset 19 gives the best switch position.  */
  switch (name[19]) {
  case 'E':
    if (memEQ(name, "GCC_JIT_COMPARISON_EQ", 21)) {
    /*                                  ^        */
      *iv_return = GCC_JIT_COMPARISON_EQ;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "GCC_JIT_COMPARISON_GE", 21)) {
    /*                                  ^        */
      *iv_return = GCC_JIT_COMPARISON_GE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "GCC_JIT_COMPARISON_GT", 21)) {
    /*                                  ^        */
      *iv_return = GCC_JIT_COMPARISON_GT;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "GCC_JIT_COMPARISON_LE", 21)) {
    /*                                  ^        */
      *iv_return = GCC_JIT_COMPARISON_LE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "GCC_JIT_COMPARISON_LT", 21)) {
    /*                                  ^        */
      *iv_return = GCC_JIT_COMPARISON_LT;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "GCC_JIT_COMPARISON_NE", 21)) {
    /*                                  ^        */
      *iv_return = GCC_JIT_COMPARISON_NE;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "GCC_JIT_TYPE_FILE_PTR", 21)) {
    /*                                  ^        */
      *iv_return = GCC_JIT_TYPE_FILE_PTR;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "GCC_JIT_TYPE_VOID_PTR", 21)) {
    /*                                  ^        */
      *iv_return = GCC_JIT_TYPE_VOID_PTR;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_22 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GCC_JIT_BINARY_OP_MULT GCC_JIT_BINARY_OP_PLUS GCC_JIT_TYPE_LONG_LONG
     GCC_JIT_UNARY_OP_MINUS */
  /* Offset 18 gives the best switch position.  */
  switch (name[18]) {
  case 'I':
    if (memEQ(name, "GCC_JIT_UNARY_OP_MINUS", 22)) {
    /*                                 ^          */
      *iv_return = GCC_JIT_UNARY_OP_MINUS;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "GCC_JIT_TYPE_LONG_LONG", 22)) {
    /*                                 ^          */
      *iv_return = GCC_JIT_TYPE_LONG_LONG;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "GCC_JIT_BINARY_OP_MULT", 22)) {
    /*                                 ^          */
      *iv_return = GCC_JIT_BINARY_OP_MULT;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "GCC_JIT_BINARY_OP_PLUS", 22)) {
    /*                                 ^          */
      *iv_return = GCC_JIT_BINARY_OP_PLUS;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_23 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GCC_JIT_BINARY_OP_MINUS GCC_JIT_GLOBAL_EXPORTED GCC_JIT_GLOBAL_IMPORTED
     GCC_JIT_GLOBAL_INTERNAL GCC_JIT_NUM_INT_OPTIONS GCC_JIT_NUM_STR_OPTIONS */
  /* Offset 16 gives the best switch position.  */
  switch (name[16]) {
  case 'M':
    if (memEQ(name, "GCC_JIT_GLOBAL_IMPORTED", 23)) {
    /*                               ^             */
      *iv_return = GCC_JIT_GLOBAL_IMPORTED;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "GCC_JIT_GLOBAL_INTERNAL", 23)) {
    /*                               ^             */
      *iv_return = GCC_JIT_GLOBAL_INTERNAL;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "GCC_JIT_NUM_INT_OPTIONS", 23)) {
    /*                               ^             */
      *iv_return = GCC_JIT_NUM_INT_OPTIONS;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "GCC_JIT_NUM_STR_OPTIONS", 23)) {
    /*                               ^             */
      *iv_return = GCC_JIT_NUM_STR_OPTIONS;
      return PERL_constant_ISIV;
    }
    break;
  case 'P':
    if (memEQ(name, "GCC_JIT_BINARY_OP_MINUS", 23)) {
    /*                               ^             */
      *iv_return = GCC_JIT_BINARY_OP_MINUS;
      return PERL_constant_ISIV;
    }
    break;
  case 'X':
    if (memEQ(name, "GCC_JIT_GLOBAL_EXPORTED", 23)) {
    /*                               ^             */
      *iv_return = GCC_JIT_GLOBAL_EXPORTED;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_24 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GCC_JIT_BINARY_OP_DIVIDE GCC_JIT_BINARY_OP_LSHIFT GCC_JIT_BINARY_OP_MODULO
     GCC_JIT_BINARY_OP_RSHIFT GCC_JIT_NUM_BOOL_OPTIONS GCC_JIT_TYPE_LONG_DOUBLE
     GCC_JIT_TYPE_SIGNED_CHAR */
  /* Offset 20 gives the best switch position.  */
  switch (name[20]) {
  case 'C':
    if (memEQ(name, "GCC_JIT_TYPE_SIGNED_CHAR", 24)) {
    /*                                   ^          */
      *iv_return = GCC_JIT_TYPE_SIGNED_CHAR;
      return PERL_constant_ISIV;
    }
    break;
  case 'D':
    if (memEQ(name, "GCC_JIT_BINARY_OP_MODULO", 24)) {
    /*                                   ^          */
      *iv_return = GCC_JIT_BINARY_OP_MODULO;
      return PERL_constant_ISIV;
    }
    break;
  case 'H':
    if (memEQ(name, "GCC_JIT_BINARY_OP_LSHIFT", 24)) {
    /*                                   ^          */
      *iv_return = GCC_JIT_BINARY_OP_LSHIFT;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "GCC_JIT_BINARY_OP_RSHIFT", 24)) {
    /*                                   ^          */
      *iv_return = GCC_JIT_BINARY_OP_RSHIFT;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "GCC_JIT_NUM_BOOL_OPTIONS", 24)) {
    /*                                   ^          */
      *iv_return = GCC_JIT_NUM_BOOL_OPTIONS;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "GCC_JIT_TYPE_LONG_DOUBLE", 24)) {
    /*                                   ^          */
      *iv_return = GCC_JIT_TYPE_LONG_DOUBLE;
      return PERL_constant_ISIV;
    }
    break;
  case 'V':
    if (memEQ(name, "GCC_JIT_BINARY_OP_DIVIDE", 24)) {
    /*                                   ^          */
      *iv_return = GCC_JIT_BINARY_OP_DIVIDE;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_25 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GCC_JIT_FUNCTION_EXPORTED GCC_JIT_FUNCTION_IMPORTED
     GCC_JIT_FUNCTION_INTERNAL GCC_JIT_TYPE_UNSIGNED_INT */
  /* Offset 17 gives the best switch position.  */
  switch (name[17]) {
  case 'E':
    if (memEQ(name, "GCC_JIT_FUNCTION_EXPORTED", 25)) {
    /*                                ^              */
      *iv_return = GCC_JIT_FUNCTION_EXPORTED;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "GCC_JIT_TYPE_UNSIGNED_INT", 25)) {
    /*                                ^              */
      *iv_return = GCC_JIT_TYPE_UNSIGNED_INT;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "GCC_JIT_FUNCTION_IMPORTED", 25)) {
    /*                                ^              */
      *iv_return = GCC_JIT_FUNCTION_IMPORTED;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "GCC_JIT_FUNCTION_INTERNAL", 25)) {
    /*                                ^              */
      *iv_return = GCC_JIT_FUNCTION_INTERNAL;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_26 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GCC_JIT_TYPE_COMPLEX_FLOAT GCC_JIT_TYPE_UNSIGNED_CHAR
     GCC_JIT_TYPE_UNSIGNED_LONG */
  /* Offset 25 gives the best switch position.  */
  switch (name[25]) {
  case 'G':
    if (memEQ(name, "GCC_JIT_TYPE_UNSIGNED_LON", 25)) {
    /*                                        G      */
      *iv_return = GCC_JIT_TYPE_UNSIGNED_LONG;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "GCC_JIT_TYPE_UNSIGNED_CHA", 25)) {
    /*                                        R      */
      *iv_return = GCC_JIT_TYPE_UNSIGNED_CHAR;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "GCC_JIT_TYPE_COMPLEX_FLOA", 25)) {
    /*                                        T      */
      *iv_return = GCC_JIT_TYPE_COMPLEX_FLOAT;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_27 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GCC_JIT_STR_OPTION_PROGNAME GCC_JIT_TYPE_COMPLEX_DOUBLE
     GCC_JIT_TYPE_CONST_CHAR_PTR GCC_JIT_TYPE_UNSIGNED_SHORT */
  /* Offset 25 gives the best switch position.  */
  switch (name[25]) {
  case 'L':
    if (memEQ(name, "GCC_JIT_TYPE_COMPLEX_DOUBLE", 27)) {
    /*                                        ^        */
      *iv_return = GCC_JIT_TYPE_COMPLEX_DOUBLE;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "GCC_JIT_STR_OPTION_PROGNAME", 27)) {
    /*                                        ^        */
      *iv_return = GCC_JIT_STR_OPTION_PROGNAME;
      return PERL_constant_ISIV;
    }
    break;
  case 'R':
    if (memEQ(name, "GCC_JIT_TYPE_UNSIGNED_SHORT", 27)) {
    /*                                        ^        */
      *iv_return = GCC_JIT_TYPE_UNSIGNED_SHORT;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "GCC_JIT_TYPE_CONST_CHAR_PTR", 27)) {
    /*                                        ^        */
      *iv_return = GCC_JIT_TYPE_CONST_CHAR_PTR;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_29 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GCC_JIT_BINARY_OP_BITWISE_AND GCC_JIT_BINARY_OP_BITWISE_XOR
     GCC_JIT_BINARY_OP_LOGICAL_AND GCC_JIT_BOOL_OPTION_DEBUGINFO
     GCC_JIT_OUTPUT_KIND_ASSEMBLER */
  /* Offset 24 gives the best switch position.  */
  switch (name[24]) {
  case 'E':
    if (memEQ(name, "GCC_JIT_BINARY_OP_BITWISE_AND", 29)) {
    /*                                       ^           */
      *iv_return = GCC_JIT_BINARY_OP_BITWISE_AND;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "GCC_JIT_BINARY_OP_BITWISE_XOR", 29)) {
    /*                                       ^           */
      *iv_return = GCC_JIT_BINARY_OP_BITWISE_XOR;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "GCC_JIT_BOOL_OPTION_DEBUGINFO", 29)) {
    /*                                       ^           */
      *iv_return = GCC_JIT_BOOL_OPTION_DEBUGINFO;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "GCC_JIT_BINARY_OP_LOGICAL_AND", 29)) {
    /*                                       ^           */
      *iv_return = GCC_JIT_BINARY_OP_LOGICAL_AND;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "GCC_JIT_OUTPUT_KIND_ASSEMBLER", 29)) {
    /*                                       ^           */
      *iv_return = GCC_JIT_OUTPUT_KIND_ASSEMBLER;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_31 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GCC_JIT_OUTPUT_KIND_OBJECT_FILE GCC_JIT_TYPE_UNSIGNED_LONG_LONG
     GCC_JIT_UNARY_OP_BITWISE_NEGATE GCC_JIT_UNARY_OP_LOGICAL_NEGATE */
  /* Offset 18 gives the best switch position.  */
  switch (name[18]) {
  case 'D':
    if (memEQ(name, "GCC_JIT_OUTPUT_KIND_OBJECT_FILE", 31)) {
    /*                                 ^                   */
      *iv_return = GCC_JIT_OUTPUT_KIND_OBJECT_FILE;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "GCC_JIT_UNARY_OP_BITWISE_NEGATE", 31)) {
    /*                                 ^                   */
      *iv_return = GCC_JIT_UNARY_OP_BITWISE_NEGATE;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "GCC_JIT_TYPE_UNSIGNED_LONG_LONG", 31)) {
    /*                                 ^                   */
      *iv_return = GCC_JIT_TYPE_UNSIGNED_LONG_LONG;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "GCC_JIT_UNARY_OP_LOGICAL_NEGATE", 31)) {
    /*                                 ^                   */
      *iv_return = GCC_JIT_UNARY_OP_LOGICAL_NEGATE;
      return PERL_constant_ISIV;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_32 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     GCC_JIT_BOOL_OPTION_DUMP_SUMMARY GCC_JIT_BOOL_OPTION_SELFCHECK_GC
     GCC_JIT_TYPE_COMPLEX_LONG_DOUBLE */
  /* Offset 22 gives the best switch position.  */
  switch (name[22]) {
  case 'L':
    if (memEQ(name, "GCC_JIT_BOOL_OPTION_SELFCHECK_GC", 32)) {
    /*                                     ^                */
      *iv_return = GCC_JIT_BOOL_OPTION_SELFCHECK_GC;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "GCC_JIT_BOOL_OPTION_DUMP_SUMMARY", 32)) {
    /*                                     ^                */
      *iv_return = GCC_JIT_BOOL_OPTION_DUMP_SUMMARY;
      return PERL_constant_ISIV;
    }
    break;
  case 'O':
    if (memEQ(name, "GCC_JIT_TYPE_COMPLEX_LONG_DOUBLE", 32)) {
    /*                                     ^                */
      *iv_return = GCC_JIT_TYPE_COMPLEX_LONG_DOUBLE;
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
            {name=>"GCC_JIT_BINARY_OP_BITWISE_AND", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_BINARY_OP_BITWISE_OR", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_BINARY_OP_BITWISE_XOR", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_BINARY_OP_DIVIDE", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_BINARY_OP_LOGICAL_AND", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_BINARY_OP_LOGICAL_OR", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_BINARY_OP_LSHIFT", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_BINARY_OP_MINUS", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_BINARY_OP_MODULO", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_BINARY_OP_MULT", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_BINARY_OP_PLUS", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_BINARY_OP_RSHIFT", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_BOOL_OPTION_DEBUGINFO", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_BOOL_OPTION_DUMP_EVERYTHING", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_BOOL_OPTION_DUMP_GENERATED_CODE", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_BOOL_OPTION_DUMP_INITIAL_GIMPLE", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_BOOL_OPTION_DUMP_INITIAL_TREE", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_BOOL_OPTION_DUMP_SUMMARY", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_BOOL_OPTION_KEEP_INTERMEDIATES", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_BOOL_OPTION_SELFCHECK_GC", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_COMPARISON_EQ", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_COMPARISON_GE", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_COMPARISON_GT", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_COMPARISON_LE", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_COMPARISON_LT", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_COMPARISON_NE", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_FUNCTION_ALWAYS_INLINE", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_FUNCTION_EXPORTED", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_FUNCTION_IMPORTED", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_FUNCTION_INTERNAL", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_GLOBAL_EXPORTED", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_GLOBAL_IMPORTED", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_GLOBAL_INTERNAL", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_INT_OPTION_OPTIMIZATION_LEVEL", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_NUM_BOOL_OPTIONS", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_NUM_INT_OPTIONS", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_NUM_STR_OPTIONS", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_OUTPUT_KIND_ASSEMBLER", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_OUTPUT_KIND_DYNAMIC_LIBRARY", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_OUTPUT_KIND_EXECUTABLE", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_OUTPUT_KIND_OBJECT_FILE", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_STR_OPTION_PROGNAME", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_TYPE_BOOL", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_TYPE_CHAR", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_TYPE_COMPLEX_DOUBLE", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_TYPE_COMPLEX_FLOAT", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_TYPE_COMPLEX_LONG_DOUBLE", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_TYPE_CONST_CHAR_PTR", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_TYPE_DOUBLE", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_TYPE_FILE_PTR", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_TYPE_FLOAT", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_TYPE_INT", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_TYPE_LONG", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_TYPE_LONG_DOUBLE", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_TYPE_LONG_LONG", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_TYPE_SHORT", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_TYPE_SIGNED_CHAR", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_TYPE_SIZE_T", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_TYPE_UNSIGNED_CHAR", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_TYPE_UNSIGNED_INT", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_TYPE_UNSIGNED_LONG", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_TYPE_UNSIGNED_LONG_LONG", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_TYPE_UNSIGNED_SHORT", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_TYPE_VOID", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_TYPE_VOID_PTR", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_UNARY_OP_ABS", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_UNARY_OP_BITWISE_NEGATE", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_UNARY_OP_LOGICAL_NEGATE", type=>"IV", macro=>"1"},
            {name=>"GCC_JIT_UNARY_OP_MINUS", type=>"IV", macro=>"1"});

print constant_types(), "\n"; # macro defs
foreach (C_constant ("GCCJIT", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("GCCJIT", $types);
__END__
   */

  switch (len) {
  case 16:
    if (memEQ(name, "GCC_JIT_TYPE_INT", 16)) {
      *iv_return = GCC_JIT_TYPE_INT;
      return PERL_constant_ISIV;
    }
    break;
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 18:
    /* Names all of length 18.  */
    /* GCC_JIT_TYPE_FLOAT GCC_JIT_TYPE_SHORT */
    /* Offset 14 gives the best switch position.  */
    switch (name[14]) {
    case 'H':
      if (memEQ(name, "GCC_JIT_TYPE_SHORT", 18)) {
      /*                             ^          */
        *iv_return = GCC_JIT_TYPE_SHORT;
        return PERL_constant_ISIV;
      }
      break;
    case 'L':
      if (memEQ(name, "GCC_JIT_TYPE_FLOAT", 18)) {
      /*                             ^          */
        *iv_return = GCC_JIT_TYPE_FLOAT;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 19:
    /* Names all of length 19.  */
    /* GCC_JIT_TYPE_DOUBLE GCC_JIT_TYPE_SIZE_T */
    /* Offset 16 gives the best switch position.  */
    switch (name[16]) {
    case 'B':
      if (memEQ(name, "GCC_JIT_TYPE_DOUBLE", 19)) {
      /*                               ^         */
        *iv_return = GCC_JIT_TYPE_DOUBLE;
        return PERL_constant_ISIV;
      }
      break;
    case 'E':
      if (memEQ(name, "GCC_JIT_TYPE_SIZE_T", 19)) {
      /*                               ^         */
        *iv_return = GCC_JIT_TYPE_SIZE_T;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 20:
    if (memEQ(name, "GCC_JIT_UNARY_OP_ABS", 20)) {
      *iv_return = GCC_JIT_UNARY_OP_ABS;
      return PERL_constant_ISIV;
    }
    break;
  case 21:
    return constant_21 (aTHX_ name, iv_return);
    break;
  case 22:
    return constant_22 (aTHX_ name, iv_return);
    break;
  case 23:
    return constant_23 (aTHX_ name, iv_return);
    break;
  case 24:
    return constant_24 (aTHX_ name, iv_return);
    break;
  case 25:
    return constant_25 (aTHX_ name, iv_return);
    break;
  case 26:
    return constant_26 (aTHX_ name, iv_return);
    break;
  case 27:
    return constant_27 (aTHX_ name, iv_return);
    break;
  case 28:
    /* Names all of length 28.  */
    /* GCC_JIT_BINARY_OP_BITWISE_OR GCC_JIT_BINARY_OP_LOGICAL_OR */
    /* Offset 19 gives the best switch position.  */
    switch (name[19]) {
    case 'I':
      if (memEQ(name, "GCC_JIT_BINARY_OP_BITWISE_OR", 28)) {
      /*                                  ^               */
        *iv_return = GCC_JIT_BINARY_OP_BITWISE_OR;
        return PERL_constant_ISIV;
      }
      break;
    case 'O':
      if (memEQ(name, "GCC_JIT_BINARY_OP_LOGICAL_OR", 28)) {
      /*                                  ^               */
        *iv_return = GCC_JIT_BINARY_OP_LOGICAL_OR;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 29:
    return constant_29 (aTHX_ name, iv_return);
    break;
  case 30:
    /* Names all of length 30.  */
    /* GCC_JIT_FUNCTION_ALWAYS_INLINE GCC_JIT_OUTPUT_KIND_EXECUTABLE */
    /* Offset 12 gives the best switch position.  */
    switch (name[12]) {
    case 'T':
      if (memEQ(name, "GCC_JIT_FUNCTION_ALWAYS_INLINE", 30)) {
      /*                           ^                        */
        *iv_return = GCC_JIT_FUNCTION_ALWAYS_INLINE;
        return PERL_constant_ISIV;
      }
      break;
    case 'U':
      if (memEQ(name, "GCC_JIT_OUTPUT_KIND_EXECUTABLE", 30)) {
      /*                           ^                        */
        *iv_return = GCC_JIT_OUTPUT_KIND_EXECUTABLE;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 31:
    return constant_31 (aTHX_ name, iv_return);
    break;
  case 32:
    return constant_32 (aTHX_ name, iv_return);
    break;
  case 35:
    /* Names all of length 35.  */
    /* GCC_JIT_BOOL_OPTION_DUMP_EVERYTHING GCC_JIT_OUTPUT_KIND_DYNAMIC_LIBRARY
       */
    /* Offset 17 gives the best switch position.  */
    switch (name[17]) {
    case 'N':
      if (memEQ(name, "GCC_JIT_OUTPUT_KIND_DYNAMIC_LIBRARY", 35)) {
      /*                                ^                        */
        *iv_return = GCC_JIT_OUTPUT_KIND_DYNAMIC_LIBRARY;
        return PERL_constant_ISIV;
      }
      break;
    case 'O':
      if (memEQ(name, "GCC_JIT_BOOL_OPTION_DUMP_EVERYTHING", 35)) {
      /*                                ^                        */
        *iv_return = GCC_JIT_BOOL_OPTION_DUMP_EVERYTHING;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 37:
    /* Names all of length 37.  */
    /* GCC_JIT_BOOL_OPTION_DUMP_INITIAL_TREE
       GCC_JIT_INT_OPTION_OPTIMIZATION_LEVEL */
    /* Offset 9 gives the best switch position.  */
    switch (name[9]) {
    case 'N':
      if (memEQ(name, "GCC_JIT_INT_OPTION_OPTIMIZATION_LEVEL", 37)) {
      /*                        ^                                  */
        *iv_return = GCC_JIT_INT_OPTION_OPTIMIZATION_LEVEL;
        return PERL_constant_ISIV;
      }
      break;
    case 'O':
      if (memEQ(name, "GCC_JIT_BOOL_OPTION_DUMP_INITIAL_TREE", 37)) {
      /*                        ^                                  */
        *iv_return = GCC_JIT_BOOL_OPTION_DUMP_INITIAL_TREE;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  case 38:
    if (memEQ(name, "GCC_JIT_BOOL_OPTION_KEEP_INTERMEDIATES", 38)) {
      *iv_return = GCC_JIT_BOOL_OPTION_KEEP_INTERMEDIATES;
      return PERL_constant_ISIV;
    }
    break;
  case 39:
    /* Names all of length 39.  */
    /* GCC_JIT_BOOL_OPTION_DUMP_GENERATED_CODE
       GCC_JIT_BOOL_OPTION_DUMP_INITIAL_GIMPLE */
    /* Offset 36 gives the best switch position.  */
    switch (name[36]) {
    case 'O':
      if (memEQ(name, "GCC_JIT_BOOL_OPTION_DUMP_GENERATED_CODE", 39)) {
      /*                                                   ^         */
        *iv_return = GCC_JIT_BOOL_OPTION_DUMP_GENERATED_CODE;
        return PERL_constant_ISIV;
      }
      break;
    case 'P':
      if (memEQ(name, "GCC_JIT_BOOL_OPTION_DUMP_INITIAL_GIMPLE", 39)) {
      /*                                                   ^         */
        *iv_return = GCC_JIT_BOOL_OPTION_DUMP_INITIAL_GIMPLE;
        return PERL_constant_ISIV;
      }
      break;
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

