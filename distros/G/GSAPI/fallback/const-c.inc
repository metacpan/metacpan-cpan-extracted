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
     e_VMerror e_ioerror e_timeout */
  /* Offset 2 gives the best switch position.  */
  switch (name[2]) {
  case 'V':
    if (memEQ(name, "e_VMerror", 9)) {
    /*                 ^            */
#ifdef e_VMerror
      *iv_return = e_VMerror;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'i':
    if (memEQ(name, "e_ioerror", 9)) {
    /*                 ^            */
#ifdef e_ioerror
      *iv_return = e_ioerror;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 't':
    if (memEQ(name, "e_timeout", 9)) {
    /*                 ^            */
#ifdef e_timeout
      *iv_return = e_timeout;
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
     e_NeedInput e_NeedStdin e_VMreclaim e_interrupt e_invalidid e_typecheck
     e_undefined */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'h':
    if (memEQ(name, "e_typecheck", 11)) {
    /*                      ^          */
#ifdef e_typecheck
      *iv_return = e_typecheck;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'i':
    if (memEQ(name, "e_invalidid", 11)) {
    /*                      ^          */
#ifdef e_invalidid
      *iv_return = e_invalidid;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "e_undefined", 11)) {
    /*                      ^          */
#ifdef e_undefined
      *iv_return = e_undefined;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'l':
    if (memEQ(name, "e_VMreclaim", 11)) {
    /*                      ^          */
#ifdef e_VMreclaim
      *iv_return = e_VMreclaim;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'n':
    if (memEQ(name, "e_NeedInput", 11)) {
    /*                      ^          */
#ifdef e_NeedInput
      *iv_return = e_NeedInput;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'r':
    if (memEQ(name, "e_interrupt", 11)) {
    /*                      ^          */
#ifdef e_interrupt
      *iv_return = e_interrupt;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 't':
    if (memEQ(name, "e_NeedStdin", 11)) {
    /*                      ^          */
#ifdef e_NeedStdin
      *iv_return = e_NeedStdin;
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
     e_NeedStderr e_NeedStdout e_RemapColor e_limitcheck e_rangecheck */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'a':
    if (memEQ(name, "e_RemapColor", 12)) {
    /*                    ^             */
#ifdef e_RemapColor
      *iv_return = e_RemapColor;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'd':
    if (memEQ(name, "e_NeedStderr", 12)) {
    /*                    ^             */
#ifdef e_NeedStderr
      *iv_return = e_NeedStderr;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "e_NeedStdout", 12)) {
    /*                    ^             */
#ifdef e_NeedStdout
      *iv_return = e_NeedStdout;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'g':
    if (memEQ(name, "e_rangecheck", 12)) {
    /*                    ^             */
#ifdef e_rangecheck
      *iv_return = e_rangecheck;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'i':
    if (memEQ(name, "e_limitcheck", 12)) {
    /*                    ^             */
#ifdef e_limitcheck
      *iv_return = e_limitcheck;
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
     e_invalidexit e_invalidfont e_syntaxerror */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'i':
    if (memEQ(name, "e_invalidexit", 13)) {
    /*                          ^        */
#ifdef e_invalidexit
      *iv_return = e_invalidexit;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'n':
    if (memEQ(name, "e_invalidfont", 13)) {
    /*                          ^        */
#ifdef e_invalidfont
      *iv_return = e_invalidfont;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'o':
    if (memEQ(name, "e_syntaxerror", 13)) {
    /*                          ^        */
#ifdef e_syntaxerror
      *iv_return = e_syntaxerror;
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
constant_15 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DISPLAY_DEPTH_1 DISPLAY_DEPTH_2 DISPLAY_DEPTH_4 DISPLAY_DEPTH_8
     e_invalidaccess e_stackoverflow e_unmatchedmark */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case '1':
    if (memEQ(name, "DISPLAY_DEPTH_", 14)) {
    /*                             1      */
      *iv_return = DISPLAY_DEPTH_1;
      return PERL_constant_ISIV;
    }
    break;
  case '2':
    if (memEQ(name, "DISPLAY_DEPTH_", 14)) {
    /*                             2      */
      *iv_return = DISPLAY_DEPTH_2;
      return PERL_constant_ISIV;
    }
    break;
  case '4':
    if (memEQ(name, "DISPLAY_DEPTH_", 14)) {
    /*                             4      */
      *iv_return = DISPLAY_DEPTH_4;
      return PERL_constant_ISIV;
    }
    break;
  case '8':
    if (memEQ(name, "DISPLAY_DEPTH_", 14)) {
    /*                             8      */
      *iv_return = DISPLAY_DEPTH_8;
      return PERL_constant_ISIV;
    }
    break;
  case 'k':
    if (memEQ(name, "e_unmatchedmar", 14)) {
    /*                             k      */
#ifdef e_unmatchedmark
      *iv_return = e_unmatchedmark;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 's':
    if (memEQ(name, "e_invalidacces", 14)) {
    /*                             s      */
#ifdef e_invalidaccess
      *iv_return = e_invalidaccess;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'w':
    if (memEQ(name, "e_stackoverflo", 14)) {
    /*                             w      */
#ifdef e_stackoverflow
      *iv_return = e_stackoverflow;
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
     DISPLAY_555_MASK DISPLAY_DEPTH_12 DISPLAY_DEPTH_16 DISPLAY_TOPFIRST
     e_invalidcontext e_invalidrestore e_nocurrentpoint e_stackunderflow */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'F':
    if (memEQ(name, "DISPLAY_TOPFIRST", 16)) {
    /*                          ^           */
      *iv_return = DISPLAY_TOPFIRST;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "DISPLAY_DEPTH_12", 16)) {
    /*                          ^           */
      *iv_return = DISPLAY_DEPTH_12;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "DISPLAY_DEPTH_16", 16)) {
    /*                          ^           */
      *iv_return = DISPLAY_DEPTH_16;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "DISPLAY_555_MASK", 16)) {
    /*                          ^           */
#ifdef DISPLAY_555_MASK
      *iv_return = DISPLAY_555_MASK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'n':
    if (memEQ(name, "e_invalidcontext", 16)) {
    /*                          ^           */
#ifdef e_invalidcontext
      *iv_return = e_invalidcontext;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'p':
    if (memEQ(name, "e_nocurrentpoint", 16)) {
    /*                          ^           */
#ifdef e_nocurrentpoint
      *iv_return = e_nocurrentpoint;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'r':
    if (memEQ(name, "e_stackunderflow", 16)) {
    /*                          ^           */
#ifdef e_stackunderflow
      *iv_return = e_stackunderflow;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 's':
    if (memEQ(name, "e_invalidrestore", 16)) {
    /*                          ^           */
#ifdef e_invalidrestore
      *iv_return = e_invalidrestore;
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
constant_17 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DISPLAY_BIGENDIAN e_InterpreterExit e_undefinedresult */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case '_':
    if (memEQ(name, "DISPLAY_BIGENDIAN", 17)) {
    /*                      ^                */
      *iv_return = DISPLAY_BIGENDIAN;
      return PERL_constant_ISIV;
    }
    break;
  case 'i':
    if (memEQ(name, "e_undefinedresult", 17)) {
    /*                      ^                */
#ifdef e_undefinedresult
      *iv_return = e_undefinedresult;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'p':
    if (memEQ(name, "e_InterpreterExit", 17)) {
    /*                      ^                */
#ifdef e_InterpreterExit
      *iv_return = e_InterpreterExit;
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
constant_18 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DISPLAY_ALPHA_LAST DISPLAY_ALPHA_MASK DISPLAY_ALPHA_NONE
     DISPLAY_COLORS_RGB DISPLAY_DEPTH_MASK DISPLAY_NATIVE_555
     DISPLAY_NATIVE_565 gs_error_interrupt */
  /* Offset 17 gives the best switch position.  */
  switch (name[17]) {
  case '5':
    if (memEQ(name, "DISPLAY_NATIVE_55", 17)) {
    /*                                5      */
      *iv_return = DISPLAY_NATIVE_555;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "DISPLAY_NATIVE_56", 17)) {
    /*                                5      */
      *iv_return = DISPLAY_NATIVE_565;
      return PERL_constant_ISIV;
    }
    break;
  case 'B':
    if (memEQ(name, "DISPLAY_COLORS_RG", 17)) {
    /*                                B      */
      *iv_return = DISPLAY_COLORS_RGB;
      return PERL_constant_ISIV;
    }
    break;
  case 'E':
    if (memEQ(name, "DISPLAY_ALPHA_NON", 17)) {
    /*                                E      */
      *iv_return = DISPLAY_ALPHA_NONE;
      return PERL_constant_ISIV;
    }
    break;
  case 'K':
    if (memEQ(name, "DISPLAY_ALPHA_MAS", 17)) {
    /*                                K      */
#ifdef DISPLAY_ALPHA_MASK
      *iv_return = DISPLAY_ALPHA_MASK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DISPLAY_DEPTH_MAS", 17)) {
    /*                                K      */
#ifdef DISPLAY_DEPTH_MASK
      *iv_return = DISPLAY_DEPTH_MASK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "DISPLAY_ALPHA_LAS", 17)) {
    /*                                T      */
      *iv_return = DISPLAY_ALPHA_LAST;
      return PERL_constant_ISIV;
    }
    break;
  case 't':
    if (memEQ(name, "gs_error_interrup", 17)) {
    /*                                t      */
#ifdef gs_error_interrupt
      *iv_return = gs_error_interrupt;
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
constant_19 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DISPLAY_ALPHA_FIRST DISPLAY_BOTTOMFIRST DISPLAY_COLORS_CMYK
     DISPLAY_COLORS_GRAY DISPLAY_COLORS_MASK DISPLAY_ENDIAN_MASK
     DISPLAY_UNUSED_LAST e_dictstackoverflow e_execstackoverflow
     e_invalidfileaccess e_undefinedfilename e_undefinedresource */
  /* Offset 15 gives the best switch position.  */
  switch (name[15]) {
  case 'C':
    if (memEQ(name, "DISPLAY_COLORS_CMYK", 19)) {
    /*                              ^          */
      *iv_return = DISPLAY_COLORS_CMYK;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "DISPLAY_COLORS_GRAY", 19)) {
    /*                              ^          */
      *iv_return = DISPLAY_COLORS_GRAY;
      return PERL_constant_ISIV;
    }
    break;
  case 'I':
    if (memEQ(name, "DISPLAY_ALPHA_FIRST", 19)) {
    /*                              ^          */
      *iv_return = DISPLAY_ALPHA_FIRST;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "DISPLAY_BOTTOMFIRST", 19)) {
    /*                              ^          */
      *iv_return = DISPLAY_BOTTOMFIRST;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "DISPLAY_UNUSED_LAST", 19)) {
    /*                              ^          */
      *iv_return = DISPLAY_UNUSED_LAST;
      return PERL_constant_ISIV;
    }
    break;
  case 'M':
    if (memEQ(name, "DISPLAY_COLORS_MASK", 19)) {
    /*                              ^          */
#ifdef DISPLAY_COLORS_MASK
      *iv_return = DISPLAY_COLORS_MASK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DISPLAY_ENDIAN_MASK", 19)) {
    /*                              ^          */
#ifdef DISPLAY_ENDIAN_MASK
      *iv_return = DISPLAY_ENDIAN_MASK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'c':
    if (memEQ(name, "e_invalidfileaccess", 19)) {
    /*                              ^          */
#ifdef e_invalidfileaccess
      *iv_return = e_invalidfileaccess;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'f':
    if (memEQ(name, "e_dictstackoverflow", 19)) {
    /*                              ^          */
#ifdef e_dictstackoverflow
      *iv_return = e_dictstackoverflow;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "e_execstackoverflow", 19)) {
    /*                              ^          */
#ifdef e_execstackoverflow
      *iv_return = e_execstackoverflow;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'n':
    if (memEQ(name, "e_undefinedfilename", 19)) {
    /*                              ^          */
#ifdef e_undefinedfilename
      *iv_return = e_undefinedfilename;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'u':
    if (memEQ(name, "e_undefinedresource", 19)) {
    /*                              ^          */
#ifdef e_undefinedresource
      *iv_return = e_undefinedresource;
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
constant_20 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DISPLAY_LITTLEENDIAN DISPLAY_UNUSED_FIRST e_ExecStackUnderflow
     e_configurationerror e_dictstackunderflow */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case 'S':
    if (memEQ(name, "DISPLAY_UNUSED_FIRST", 20)) {
    /*                          ^               */
      *iv_return = DISPLAY_UNUSED_FIRST;
      return PERL_constant_ISIV;
    }
    break;
  case 'T':
    if (memEQ(name, "DISPLAY_LITTLEENDIAN", 20)) {
    /*                          ^               */
      *iv_return = DISPLAY_LITTLEENDIAN;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "e_ExecStackUnderflow", 20)) {
    /*                          ^               */
#ifdef e_ExecStackUnderflow
      *iv_return = e_ExecStackUnderflow;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 't':
    if (memEQ(name, "e_configurationerror", 20)) {
    /*                          ^               */
#ifdef e_configurationerror
      *iv_return = e_configurationerror;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'u':
    if (memEQ(name, "e_dictstackunderflow", 20)) {
    /*                          ^               */
#ifdef e_dictstackunderflow
      *iv_return = e_dictstackunderflow;
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
     DISPLAY_COLORS_NATIVE DISPLAY_FIRSTROW_MASK DISPLAY_VERSION_MAJOR
     DISPLAY_VERSION_MINOR */
  /* Offset 18 gives the best switch position.  */
  switch (name[18]) {
  case 'A':
    if (memEQ(name, "DISPLAY_FIRSTROW_MASK", 21)) {
    /*                                 ^         */
#ifdef DISPLAY_FIRSTROW_MASK
      *iv_return = DISPLAY_FIRSTROW_MASK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "DISPLAY_COLORS_NATIVE", 21)) {
    /*                                 ^         */
      *iv_return = DISPLAY_COLORS_NATIVE;
      return PERL_constant_ISIV;
    }
    break;
  case 'J':
    if (memEQ(name, "DISPLAY_VERSION_MAJOR", 21)) {
    /*                                 ^         */
#ifdef DISPLAY_VERSION_MAJOR
      *iv_return = DISPLAY_VERSION_MAJOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "DISPLAY_VERSION_MINOR", 21)) {
    /*                                 ^         */
#ifdef DISPLAY_VERSION_MINOR
      *iv_return = DISPLAY_VERSION_MINOR;
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

#!/usr/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(DISPLAY_555_MASK DISPLAY_ALPHA_MASK DISPLAY_COLORS_MASK
	       DISPLAY_DEPTH_MASK DISPLAY_ENDIAN_MASK DISPLAY_FIRSTROW_MASK
	       DISPLAY_VERSION_MAJOR DISPLAY_VERSION_MINOR e_ExecStackUnderflow
	       e_Fatal e_Info e_InterpreterExit e_NeedInput e_NeedStderr
	       e_NeedStdin e_NeedStdout e_Quit e_RemapColor e_VMerror
	       e_VMreclaim e_configurationerror e_dictfull e_dictstackoverflow
	       e_dictstackunderflow e_execstackoverflow e_interrupt
	       e_invalidaccess e_invalidcontext e_invalidexit
	       e_invalidfileaccess e_invalidfont e_invalidid e_invalidrestore
	       e_ioerror e_limitcheck e_nocurrentpoint e_rangecheck
	       e_stackoverflow e_stackunderflow e_syntaxerror e_timeout
	       e_typecheck e_undefined e_undefinedfilename e_undefinedresource
	       e_undefinedresult e_unknownerror e_unmatchedmark e_unregistered
	       gs_error_interrupt),
            {name=>"DISPLAY_ALPHA_FIRST", type=>"IV", macro=>"1"},
            {name=>"DISPLAY_ALPHA_LAST", type=>"IV", macro=>"1"},
            {name=>"DISPLAY_ALPHA_NONE", type=>"IV", macro=>"1"},
            {name=>"DISPLAY_BIGENDIAN", type=>"IV", macro=>"1"},
            {name=>"DISPLAY_BOTTOMFIRST", type=>"IV", macro=>"1"},
            {name=>"DISPLAY_COLORS_CMYK", type=>"IV", macro=>"1"},
            {name=>"DISPLAY_COLORS_GRAY", type=>"IV", macro=>"1"},
            {name=>"DISPLAY_COLORS_NATIVE", type=>"IV", macro=>"1"},
            {name=>"DISPLAY_COLORS_RGB", type=>"IV", macro=>"1"},
            {name=>"DISPLAY_DEPTH_1", type=>"IV", macro=>"1"},
            {name=>"DISPLAY_DEPTH_12", type=>"IV", macro=>"1"},
            {name=>"DISPLAY_DEPTH_16", type=>"IV", macro=>"1"},
            {name=>"DISPLAY_DEPTH_2", type=>"IV", macro=>"1"},
            {name=>"DISPLAY_DEPTH_4", type=>"IV", macro=>"1"},
            {name=>"DISPLAY_DEPTH_8", type=>"IV", macro=>"1"},
            {name=>"DISPLAY_LITTLEENDIAN", type=>"IV", macro=>"1"},
            {name=>"DISPLAY_NATIVE_555", type=>"IV", macro=>"1"},
            {name=>"DISPLAY_NATIVE_565", type=>"IV", macro=>"1"},
            {name=>"DISPLAY_TOPFIRST", type=>"IV", macro=>"1"},
            {name=>"DISPLAY_UNUSED_FIRST", type=>"IV", macro=>"1"},
            {name=>"DISPLAY_UNUSED_LAST", type=>"IV", macro=>"1"});

print constant_types(); # macro defs
foreach (C_constant ("GSAPI", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("GSAPI", $types);
__END__
   */

  switch (len) {
  case 6:
    /* Names all of length 6.  */
    /* e_Info e_Quit */
    /* Offset 4 gives the best switch position.  */
    switch (name[4]) {
    case 'f':
      if (memEQ(name, "e_Info", 6)) {
      /*                   ^       */
#ifdef e_Info
        *iv_return = e_Info;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'i':
      if (memEQ(name, "e_Quit", 6)) {
      /*                   ^       */
#ifdef e_Quit
        *iv_return = e_Quit;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 7:
    if (memEQ(name, "e_Fatal", 7)) {
#ifdef e_Fatal
      *iv_return = e_Fatal;
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
    if (memEQ(name, "e_dictfull", 10)) {
#ifdef e_dictfull
      *iv_return = e_dictfull;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
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
    /* Names all of length 14.  */
    /* e_unknownerror e_unregistered */
    /* Offset 8 gives the best switch position.  */
    switch (name[8]) {
    case 'n':
      if (memEQ(name, "e_unknownerror", 14)) {
      /*                       ^            */
#ifdef e_unknownerror
        *iv_return = e_unknownerror;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 's':
      if (memEQ(name, "e_unregistered", 14)) {
      /*                       ^            */
#ifdef e_unregistered
        *iv_return = e_unregistered;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 15:
    return constant_15 (aTHX_ name, iv_return);
    break;
  case 16:
    return constant_16 (aTHX_ name, iv_return);
    break;
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 18:
    return constant_18 (aTHX_ name, iv_return);
    break;
  case 19:
    return constant_19 (aTHX_ name, iv_return);
    break;
  case 20:
    return constant_20 (aTHX_ name, iv_return);
    break;
  case 21:
    return constant_21 (aTHX_ name, iv_return);
    break;
  }
  return PERL_constant_NOTFOUND;
}

