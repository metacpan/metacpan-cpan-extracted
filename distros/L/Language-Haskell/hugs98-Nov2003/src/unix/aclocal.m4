dnl ################################################################
dnl Macros
dnl (hard-core autoconf hackers only)
dnl ################################################################

dnl Like AC_SUBST but with a default value in case var is undefined
dnl typically usage from cshell:  env EXE=".exe" ./configure

dnl AC_SUBST_DEF(varname,defaultvalue)

AC_DEFUN(AC_SUBST_DEF,[
$1=${$1=$2}
AC_SUBST($1)
])

dnl Generalisation of AC_CHECK_TYPE which let's us specify which
dnl header files to search.

dnl AC_CHECK_TYPE_IN(TYPE, DEFAULT, HEADERS)

AC_DEFUN(AC_CHECK_TYPE_IN,
[dnl
AC_MSG_CHECKING(for $1)
AC_CACHE_VAL(ac_cv_type_$1,
[AC_EGREP_CPP($1, [$3], ac_cv_type_$1=yes, ac_cv_type_$1=no)])dnl
AC_MSG_RESULT($ac_cv_type_$1)
if test $ac_cv_type_$1 = no; then
  AC_DEFINE($1, $2)
fi
])


dnl Based on AC_TRY_LINK - run iftrue if links cleanly with no warning

dnl AC_TRY_LINK_NOWARN(flags,main?,iftrue,iffalse)

AC_DEFUN(AC_TRY_LINK_NOWARN,
[
ac_save_LIBS="$LIBS"
LIBS=[$1];
cat > conftest.$ac_ext <<EOF
dnl This sometimes fails to find confdefs.h, for some reason.
dnl [#]line __oline__ "[$]0"
[#]line __oline__ "configure"
#include "confdefs.h"
[$2]
int t() { return 0; }
EOF
if AC_TRY_EVAL(ac_link); then
  ifelse([$3], , :, [
    LIBS="$ac_save_LIBS"
    rm -rf conftest*
    $3])
  ifelse([$4], , , [else
    LIBS="$ac_save_LIBS"
    rm -rf conftest*
    $4
])dnl
fi
rm -f conftest*
]
)

dnl Loosely based on AC_CHECK_LIB in acgeneral.m4 in autoconf distribution

dnl AC_CHECK_FLAG_NOWARN(NAME, FLAG, CODE, iftrue, iffalse)

AC_DEFUN(AC_CHECK_FLAG_NOWARN,
[AC_MSG_CHECKING([for $1])
 AC_CACHE_VAL(ac_cv_flag_$1,
   [AC_TRY_LINK_NOWARN("$2", [main() { $3; exit(0); } ],
     eval "ac_cv_flag_$1=yes",
     eval "ac_cv_flag_$1=no"
   )]
 )
if eval "test \"`echo '$ac_cv_flag_'$1`\" = yes"; then
  AC_MSG_RESULT(yes)
  LIBS="$2 $LIBS"
  $4
else
  AC_MSG_RESULT(no)
  $5
fi
])

dnl AC_CHECK_LIB_NOWARN(LIBRARY, FUNCTION)

AC_DEFUN(AC_CHECK_LIB_NOWARN,
[AC_CHECK_FLAG_NOWARN([function_$2],[],[extern char $2(); $2();],
,dnl The function is present without needing the library
[AC_CHECK_FLAG_NOWARN([library_$1],[-l$1],[extern char $2(); $2();],
[changequote(, )dnl
  ac_tr_lib=HAVE_LIB`echo $1 | tr 'abcdefghijklmnopqrstuvwxyz' 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'`
 changequote([, ])dnl
 AC_DEFINE_UNQUOTED($ac_tr_lib)
],
[]
)])]
)


dnl copied from acspecific.m4 (part of autoconf distribution)
dnl
dnl AC_DEFUN(AC_STACK_DIRECTION,
dnl [AC_CACHE_CHECK(stack direction for C alloca, ac_cv_c_stack_direction,
dnl [AC_TRY_RUN([find_stack_direction ()
dnl {
dnl   static char *addr = 0;
dnl   auto char dummy;
dnl   if (addr == 0)
dnl 	{
dnl 	  addr = &dummy;
dnl 	  return find_stack_direction ();
dnl 	}
dnl   else
dnl 	return (&dummy > addr) ? 1 : -1;
dnl }
dnl main ()
dnl {
dnl   exit (find_stack_direction() < 0);
dnl }], ac_cv_c_stack_direction=1, ac_cv_c_stack_direction=-1,
dnl   ac_cv_c_stack_direction=0)])
dnl AC_DEFINE_UNQUOTED(STACK_DIRECTION, $ac_cv_c_stack_direction)
dnl ])


dnl On some machines, you cannot take the address of a jmp_buf
dnl
AC_DEFUN(AC_C_JMPBUF_ARRAY,
[AC_CACHE_CHECK(for arrays of jmp_bufs, ac_cv_c_jmp_buf_array,
[AC_TRY_COMPILE([
#include <setjmp.h>
int test1() {
    jmp_buf jb[1];
    jmp_buf *jbp = jb;
    return (setjmp(jb[0]) == 0);
}
],
[int i;], 
ac_cv_c_jmp_buf_array=yes,
ac_cv_c_jmp_buf_array=no)])
if test "$ac_cv_c_jmp_buf_array" = yes; then
AC_DEFINE(JMPBUF_ARRAY)
fi
])


dnl POSIX systems prefer "diff -C 1"; SunOS4 prefers "diff -c1".
dnl
AC_DEFUN(AC_PROG_DIFF,
[AC_PATH_PROG(DIFF,diff)
AC_CACHE_CHECK(whether to use "diff -c1" or "diff -C 1", CONTEXT_DIFF,
if AC_TRY_COMMAND(diff -C 1 config.log config.log); then
  CONTEXT_DIFF="$DIFF -C 1"
else
  if AC_TRY_COMMAND(diff -c1 config.log config.log); then
    CONTEXT_DIFF="$DIFF -c1"
  else
    CONTEXT_DIFF="$DIFF"
  fi
fi
)
AC_SUBST(CONTEXT_DIFF)
])

dnl check for prototypes
dnl
AC_DEFUN([AC_C_PROTOTYPES],
[AC_CACHE_CHECK([prototypes], ac_cv_prototypes,
[AC_TRY_COMPILE([
void foo(int);
void foo(i)
int i; { 
return;
}
],
[int i;], 
ac_cv_prototypes=yes,
ac_cv_prototypes=no)])
if test "$ac_cv_prototypes" = yes; then
AC_DEFINE(HAVE_PROTOTYPES)
fi
])

dnl check for gcc's "labels as values" feature
AC_DEFUN(AC_C_LABELS_AS_VALUES,
[AC_CACHE_CHECK([labels as values], ac_cv_labels_as_values,
[AC_TRY_COMPILE([
int foo(int);
int foo(i)
int i; { 
static void *label[] = { &&l1, &&l2 };
goto *label[i];
l1: return 1;
l2: return 2;
}
],
[int i;], 
ac_cv_labels_as_values=yes,
ac_cv_labels_as_values=no)])
if test "$ac_cv_labels_as_values" = yes; then
AC_DEFINE(HAVE_LABELS_AS_VALUES)
fi
])


dnl *** Is altzone available? ***
dnl 
dnl (copied from the fptools/ configure script)
AC_DEFUN(FPTOOLS_HAVE_ALTZONE,
[AC_CACHE_CHECK([altzone], fptools_cv_altzone,
[AC_TRY_LINK([#if TIME_WITH_SYS_TIME
# include <sys/time.h>
# include <time.h>
#else
# if HAVE_SYS_TIME_H
#  include <sys/time.h>
# else
#  include <time.h>
# endif
#endif
], [return altzone;], 
fptools_cv_altzone=yes, fptools_cv_altzone=no)])
if test "$fptools_cv_altzone" = yes; then
  AC_DEFINE(HAVE_ALTZONE)
fi
])

dnl
dnl Is timezone around? (in a header file)
dnl 
dnl (copied from the fptools/ configure script)
AC_DEFUN(FPTOOLS_HAVE_TIMEZONE,
[AC_CACHE_CHECK([timezone], fptools_cv_have_timezone,
[AC_TRY_COMPILE([#if TIME_WITH_SYS_TIME
# include <sys/time.h>
# include <time.h>
#else
# if HAVE_SYS_TIME_H
#  include <sys/time.h>
# else
#  include <time.h>
# endif
#endif
], [return timezone/1;], 
fptools_cv_have_timezone=yes, fptools_cv_have_timezone=no)])
if test "$fptools_cv_have_timezone" = yes; then
  AC_DEFINE(HAVE_TIMEZONE)
fi
])


# FP_COMPUTE_INT(EXPRESSION, VARIABLE, INCLUDES, IF-FAILS)
# ---------------------------------------------------------
# Assign VARIABLE the value of the compile-time EXPRESSION using INCLUDES for
# compilation. Execute IF-FAILS when unable to determine the value. Works for
# cross-compilation, too.
#
# Implementation note: We are lazy and use an internal autoconf macro, but it
# is supported in autoconf versions 2.50 up to the actual 2.57, so there is
# little risk.
AC_DEFUN([FP_COMPUTE_INT],
[_AC_COMPUTE_INT([$1], [$2], [$3], [$4])[]dnl
])# FP_COMPUTE_INT


# FP_CHECK_ALIGNMENT(TYPE, [IGNORED], [INCLUDES = DEFAULT-INCLUDES])
# ------------------------------------------------------------------
# A variation of AC_CHECK_SIZEOF for computing the alignment restrictions of a
# given type. Defines ALIGNMENT_TYPE.
AC_DEFUN([FP_CHECK_ALIGNMENT],
[AS_LITERAL_IF([$1], [],
               [AC_FATAL([$0: requires literal arguments])])[]dnl
AC_CHECK_TYPE([$1], [], [], [$3])[]dnl
m4_pushdef([fp_Cache], [AS_TR_SH([fp_cv_alignment_$1])])[]dnl
AC_CACHE_CHECK([alignment of $1], [fp_Cache],
[if test "$AS_TR_SH([ac_cv_type_$1])" = yes; then
  FP_COMPUTE_INT([(long) (&((struct { char c; $1 ty; } *)0)->ty)],
                 [fp_Cache],
                 [AC_INCLUDES_DEFAULT([$3])],
                 [AC_MSG_ERROR([cannot compute alignment ($1)
See `config.log' for more details.], [77])])
else
  fp_Cache=0
fi])[]dnl
AC_DEFINE_UNQUOTED(AS_TR_CPP(alignment_$1), $fp_Cache, [The alignment of a `$1'.])[]dnl
m4_popdef([fp_Cache])[]dnl
])# FP_CHECK_ALIGNMENT


dnl ** Map an arithmetic C type to a Haskell type.
dnl    Based on autconf's AC_CHECK_SIZEOF.

dnl FPTOOLS_CHECK_HTYPE(TYPE [, DEFAULT_VALUE, [, VALUE-FOR-CROSS-COMPILATION])
AC_DEFUN(FPTOOLS_CHECK_HTYPE,
[changequote(<<, >>)dnl
dnl The name to #define.
define(<<AC_TYPE_NAME>>, translit(htype_$1, [a-z *], [A-Z_P]))dnl
dnl The cache variable name.
define(<<AC_CV_NAME>>, translit(fptools_cv_htype_$1, [ *], [_p]))dnl
define(<<AC_CV_NAME_supported>>, translit(fptools_cv_htype_sup_$1, [ *], [_p]))dnl
changequote([, ])dnl
AC_MSG_CHECKING(Haskell type for $1)
AC_CACHE_VAL(AC_CV_NAME,
[AC_CV_NAME_supported=yes
fp_check_htype_save_cppflags="$CPPFLAGS"
CPPFLAGS="$CPPFLAGS $X_CFLAGS"
AC_TRY_RUN([#include <stdio.h>
#include <stddef.h>

#if HAVE_SYS_TYPES_H
# include <sys/types.h>
#endif

#if HAVE_UNISTD_H
# include <unistd.h>
#endif

#if HAVE_SYS_STAT_H
# include <sys/stat.h>
#endif

#if HAVE_FCNTL_H
# include <fcntl.h>
#endif

#if HAVE_SIGNAL_H
# include <signal.h>
#endif

#if HAVE_TIME_H
# include <time.h>
#endif

#if HAVE_TERMIOS_H
# include <termios.h>
#endif

#if HAVE_STRING_H
# include <string.h>
#endif

#if HAVE_CTYPE_H
# include <ctype.h>
#endif

#if defined(HAVE_GL_GL_H)
# include <GL/gl.h>
#elif defined(HAVE_OPENGL_GL_H)
# include <OpenGL/gl.h>
#endif

#if defined(HAVE_AL_ALC_H)
# include <AL/alc.h>
#elif defined(HAVE_OPENAL_ALC_H)
# include <OpenAL/alc.h>
#endif

#if HAVE_SYS_RESOURCE_H
# include <sys/resource.h>
#endif

typedef $1 testing;

main() {
  FILE *f=fopen("conftestval", "w");
  if (!f) exit(1);
  if (((testing)((int)((testing)1.4))) == ((testing)1.4)) {
    fprintf(f, "%s%d\n",
           ((testing)(-1) < (testing)0) ? "Int" : "Word",
           sizeof(testing)*8);
  } else {
    fprintf(f,"%s\n",
           (sizeof(testing) >  sizeof(double)) ? "LDouble" :
           (sizeof(testing) == sizeof(double)) ? "Double"  : "Float");
  }
  fclose(f);
  exit(0);
}],AC_CV_NAME=`cat conftestval`,
ifelse([$2], , [AC_CV_NAME=NotReallyAType; AC_CV_NAME_supported=no], AC_CV_NAME=$2),
ifelse([$3], , [AC_CV_NAME=NotReallyATypeCross; AC_CV_NAME_supported=no], AC_CV_NAME=$3))]) dnl
CPPFLAGS="$fp_check_htype_save_cppflags"
if test "$AC_CV_NAME_supported" = yes; then
  AC_MSG_RESULT($AC_CV_NAME)
  AC_DEFINE_UNQUOTED(AC_TYPE_NAME, $AC_CV_NAME, [Define to Haskell type for $1])
else
  AC_MSG_RESULT([not supported])
fi
undefine([AC_TYPE_NAME])dnl
undefine([AC_CV_NAME])dnl
undefine([AC_CV_NAME_supported])dnl
])

dnl ** figure out whether C compiler supports 'long long's
dnl    (Closely based on Andreas Zeller's macro for testing
dnl     for this under C++)
dnl
dnl    If the C compiler supports `long long' types,
dnl    define `HAVE_LONG_LONG'.
dnl
AC_DEFUN(FPTOOLS_C_LONG_LONG,
[
AC_REQUIRE([AC_PROG_CC])
AC_MSG_CHECKING(whether ${CC} supports long long types)
AC_CACHE_VAL(fptools_cv_have_long_long,
[
AC_LANG_SAVE
AC_LANG_C
AC_TRY_COMPILE(,[long long a;],
fptools_cv_have_long_long=yes,
fptools_cv_have_long_long=no)
AC_LANG_RESTORE
])
AC_MSG_RESULT($fptools_cv_have_long_long)
if test "$fptools_cv_have_long_long" = yes; then
AC_DEFINE(HAVE_LONG_LONG)
fi
])


# FP_CHECK_CONST(EXPRESSION, [INCLUDES = DEFAULT-INCLUDES], [VALUE-IF-FAIL = -1])
# ---------------------------------------------------------------------------------
# Defines CONST_EXPRESSION to the value of the compile-time EXPRESSION, using
# INCLUDES. If the value cannot be determined, use VALUE-IF-FAIL.
AC_DEFUN([FP_CHECK_CONST],
[AS_VAR_PUSHDEF([fp_Cache], [fp_cv_const_$1])[]dnl
AC_CACHE_CHECK([value of $1], fp_Cache,
[FP_COMPUTE_INT([$1], fp_check_const_result, [AC_INCLUDES_DEFAULT([$2])],
                [fp_check_const_result=m4_default([$3], ['-1'])])
AS_VAR_SET(fp_Cache, [$fp_check_const_result])])[]dnl
AC_DEFINE_UNQUOTED(AS_TR_CPP([CONST_$1]), AS_VAR_GET(fp_Cache), [The value of $1.])[]dnl
AS_VAR_POPDEF([fp_Cache])[]dnl
])# FP_CHECK_CONST


# FP_CHECK_CONSTS_TEMPLATE(EXPRESSION...)
# ----------------------------------
# autoheader helper for FP_CHECK_CONSTS
m4_define([FP_CHECK_CONSTS_TEMPLATE],
[AC_FOREACH([fp_Const], [$1],
  [AH_TEMPLATE(AS_TR_CPP(CONST_[]fp_Const),
               [The value of ]fp_Const[.])])[]dnl
])# FP_CHECK_CONSTS_TEMPLATE


# FP_CHECK_CONSTS(EXPRESSION..., [INCLUDES = DEFAULT-INCLUDES], [VALUE-IF-FAIL = -1])
# -------------------------------------------------------------------------------------
# List version of FP_CHECK_CONST
AC_DEFUN(FP_CHECK_CONSTS,
[FP_CHECK_CONSTS_TEMPLATE([$1])dnl
for fp_const_name in $1
do
FP_CHECK_CONST([$fp_const_name], [$2], [$3])
done
])# FP_CHECK_CONSTS


dnl ** Try building and loading a dynamically loadable library using
dnl    the specified flags.
dnl
AC_DEFUN(HUGS_TRY_DYNLINK,
dnl AC_BEFORE([$0], [AC_C_PROTOTYPES])
[AC_MSG_CHECKING(if '$1' builds loadable libraries)
AC_CACHE_VAL(ac_cv_dll_flags,
[
  cat > conftest_dl.c <<EOF
int x = 0;    /* global */
int y;        /* common */
static int z; /* static */
static int test2() { return (test() + x + y + z); }
int test() { return test2(); }
EOF

  ac_mkdll='${CC-cc} $1 conftest_dl.c -o conftest_dl.so 1>&AC_FD_CC'

  if AC_TRY_EVAL(ac_mkdll) && test -s conftest_dl.so 
  then dnl compiling and linking loadee succeeded

    cat > conftest.c << EOF
#include "confdefs.h"
#if HAVE_PROTOTYPES       /* To enable use of prototypes whenever possible */
#define Args(x) x
#else
#define Args(x) ()
#endif

#define SYMBOL1 "test"
#define SYMBOL2 "_test"

#define CANTRUN  1
#define CANTOPEN 2
#define SYM1_OK  3
#define SYM2_OK  4
#define CANTFIND 5

#if HAVE_DLFCN_H /* eg LINUX, SOLARIS, ULTRIX */

#include <stdio.h>
#include <dlfcn.h>

main()
{
    void *instance;
    void *sym;

    instance = dlopen("./conftest_dl.so",1);
    if (instance==0) exit(CANTOPEN);
      
    sym = dlsym(instance,SYMBOL1);
    if (sym != 0) exit(SYM1_OK);

    sym = dlsym(instance,SYMBOL2);
    if (sym != 0) exit(SYM2_OK);

    exit(CANTFIND);
}

#elif HAVE_DL_H /* eg HPUX */

#include <dl.h>

main()
{
    shl_t instance;
    void* r;

    instance = shl_load("./conftest_dl.so",BIND_IMMEDIATE,0L);
    if (instance == 0) exit(CANTOPEN);
    
    if (0 == shl_findsym(&instance,SYMBOL1,TYPE_PROCEDURE,&r)) exit(SYM1_OK);

    if (0 == shl_findsym(&instance,SYMBOL2,TYPE_PROCEDURE,&r)) exit(SYM2_OK);

    exit(CANTFIND);
}

#elif HAVE_MACH_O_DYLD_H         /* MacOS X */

#include <stdio.h>
#include <mach-o/dyld.h>

main()
{
    NSObjectFileImage ofile;
    NSModule handle = NULL;
    void* addr;
    NSSymbol sym;

    if (NSCreateObjectFileImageFromFile("./conftest_dl.so",&ofile) != NSObjectFileImageSuccess)
        exit(CANTOPEN);

    handle = NSLinkModule(ofile,"./conftest_dl.so",NSLINKMODULE_OPTION_PRIVATE);
    if (handle == 0) exit(CANTOPEN);
    
    sym = NSLookupSymbolInModule(handle, SYMBOL1); 
    if (sym != 0) exit(SYM1_OK);
    
    sym = NSLookupSymbolInModule(handle, SYMBOL2); 
    if (sym != 0) exit(SYM2_OK);
    
    exit(CANTFIND);
}

#elif HAVE_WINDOWS_H

#include <windows.h>

main()
{
    HINSTANCE instance;
    void* sym;

    instance = LoadLibrary("conftest_dl.so");
    if (instance ==0) exit(CANTOPEN);

    sym = (void*)GetProcAddress(instance,SYMBOL1);
    if (sym != 0) exit(SYM1_OK);

    sym = (void*)GetProcAddress(instance,SYMBOL2);
    if (sym != 0) exit(SYM2_OK);

    exit(CANTFIND);
}

#else

main()
{
  exit(CANTRUN);
}

#endif
EOF


if AC_TRY_EVAL(ac_link) && test -s conftest${ac_exeext} 
then dnl compiling and linking loader succeeded

  ./conftest 2>/dev/null
  ac_result=$?
  if test $ac_result = 3; then
    ac_cv_dll_flags='$1'
    ac_cv_leading_underscore=no
  fi
  if test $ac_result = 4; then
    ac_cv_dll_flags='$1'
    ac_cv_leading_underscore=yes
  fi

fi dnl compiling and linking loader succeeded
fi dnl compiling and linking loadee succeeded

rm -fr conftest* a.out
]) dnl close AC_CACHE_VAL
AC_MSG_RESULT($ac_cv_dll_flags)]
)

dnl
dnl Check to see whether 'struct msghdr' contains msg_control
dnl 
AC_DEFUN(FPTOOLS_MSGHDR_MSG_CONTROL,
[AC_CACHE_CHECK([for msg_control in struct msghdr], fptools_cv_struct_msghdr_msg_control,
[AC_TRY_COMPILE([#include <sys/types.h>
#include <sys/uio.h>
#include <sys/socket.h>], [struct msghdr m; m.msg_control;],
fptools_cv_struct_msghdr_msg_control=yes, fptools_cv_struct_msghdr_msg_control=no)])
if test $fptools_cv_struct_msghdr_msg_control = yes; then
  AC_DEFINE(HAVE_STRUCT_MSGHDR_MSG_CONTROL)
fi
AC_SUBST(HAVE_STRUCT_MSGHDR_MSG_CONTROL)dnl
])

dnl
dnl Check to see whether 'struct msghdr' contains msg_accrights
dnl 
AC_DEFUN(FPTOOLS_MSGHDR_MSG_ACCRIGHTS,
[AC_CACHE_CHECK([for msg_accrights in struct msghdr], fptools_cv_struct_msghdr_msg_accrights,
[AC_TRY_COMPILE([#include <sys/types.h>
#include <sys/uio.h>
#include <sys/socket.h>], [struct msghdr m; m.msg_accrights;],
fptools_cv_struct_msghdr_msg_accrights=yes, fptools_cv_struct_msghdr_msg_accrights=no)])
if test $fptools_cv_struct_msghdr_msg_accrights = yes; then
  AC_DEFINE(HAVE_STRUCT_MSGHDR_MSG_ACCRIGHTS)
fi
AC_SUBST(HAVE_STRUCT_MSGHDR_MSG_ACCRIGHTS)dnl
])

dnl ######################################################################
dnl FPTOOLS_SEARCH_LIBS(INCLUDES, FUNCTION, SEARCH-LIBS [, ACTION-IF-FOUND
dnl                     [, ACTION-IF-NOT-FOUND [, OTHER-LIBRARIES]]])
dnl Search for a library defining FUNC, if it's not already available.
dnl This is almost the same as AC_SEARCH_LIBS, but the INCLUDES can be
dnl specified.
dnl ######################################################################

AC_DEFUN(FPTOOLS_SEARCH_LIBS,
[AC_PREREQ([2.13])
AC_CACHE_CHECK([for library containing $2], [ac_cv_search_$2],
[ac_func_search_save_LIBS="$LIBS"
ac_cv_search_$2="no"
AC_TRY_LINK([$1], [$2()], [ac_cv_search_$2="none required"])
test "$ac_cv_search_$2" = "no" && for i in $3; do
LIBS="-l$i $6 $ac_func_search_save_LIBS"
AC_TRY_LINK([$1], [$2()],
[ac_cv_search_$2="-l$i"
break])
done
LIBS="$ac_func_search_save_LIBS"])
if test "$ac_cv_search_$2" != "no"; then
  test "$ac_cv_search_$2" = "none required" || LIBS="$ac_cv_search_$2 $LIBS"
  $4
else :
  $5
fi])

dnl ####################### -*- Mode: M4 -*- ###########################
dnl Copyright (C) 98, 1999 Matthew D. Langston <langston@SLAC.Stanford.EDU>
dnl
dnl This file is free software; you can redistribute it and/or modify it
dnl under the terms of the GNU General Public License as published by
dnl the Free Software Foundation; either version 2 of the License, or
dnl (at your option) any later version.
dnl
dnl This file is distributed in the hope that it will be useful, but
dnl WITHOUT ANY WARRANTY; without even the implied warranty of
dnl MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
dnl General Public License for more details.
dnl
dnl You should have received a copy of the GNU General Public License
dnl along with this file; if not, write to:
dnl
dnl   Free Software Foundation, Inc.
dnl   Suite 330
dnl   59 Temple Place
dnl   Boston, MA 02111-1307, USA.
dnl ####################################################################


dnl @synopsis FPTOOLS_CHECK_LIBM
dnl 
dnl Search for math library (typically -lm).
dnl
dnl The variable LIBM (which is not an output variable by default) is
dnl set to a value which is suitable for use in a Makefile (for example,
dnl in make's LOADLIBES macro) provided you AC_SUBST it first.
dnl
dnl @author Matthew D. Langston <langston@SLAC.Stanford.EDU>

# FPTOOLS_CHECK_LIBM - check for math library
AC_DEFUN(FPTOOLS_CHECK_LIBM,
[AC_REQUIRE([AC_CANONICAL_HOST])dnl
LIBM=
case "$host" in
*-*-beos*)
  # These system don't have libm
  ;;
*-ncr-sysv4.3*)
  AC_CHECK_LIB(mw, _mwvalidcheckl, LIBM="-lmw")
  AC_CHECK_LIB(m, main, LIBM="$LIBM -lm")
  ;;
*)
  AC_CHECK_LIB(m, main, LIBM="-lm")
  ;;
esac
])

dnl ######################################################################
dnl Note: Caching has been completely rewritten, but is still no perfect yet.
dnl ######################################################################

dnl ########################### -*- Mode: M4 -*- #######################
dnl Copyright (C) 98, 1999 Matthew D. Langston <langston@SLAC.Stanford.EDU>
dnl
dnl This file is free software; you can redistribute it and/or modify it
dnl under the terms of the GNU General Public License as published by
dnl the Free Software Foundation; either version 2 of the License, or
dnl (at your option) any later version.
dnl
dnl This file is distributed in the hope that it will be useful, but
dnl WITHOUT ANY WARRANTY; without even the implied warranty of
dnl MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
dnl General Public License for more details.
dnl
dnl You should have received a copy of the GNU General Public License
dnl along with this file; if not, write to:
dnl
dnl   Free Software Foundation, Inc.
dnl   Suite 330
dnl   59 Temple Place
dnl   Boston, MA 02111-1307, USA.
dnl ####################################################################

dnl @synopsis FPTOOLS_HAVE_OPENGL
dnl 
dnl Search for OpenGL.  We search first for Mesa (a GPL'ed version of
dnl OpenGL) before a vendor's version of OpenGL if we were specifically
dnl asked to with `--with-Mesa=yes' or `--with-Mesa'.
dnl
dnl The four "standard" OpenGL libraries are searched for: "-lGL",
dnl "-lGLU", "-lGLX" (or "-lMesaGL", "-lMesaGLU" as the case may be) and
dnl "-lglut".
dnl
dnl All of the libraries that are found (since "-lglut" or "-lGLX" might
dnl be missing) are added to the shell output variable "GL_LIBS", along
dnl with any other libraries that are necessary to successfully link an
dnl OpenGL application (e.g. the X11 libraries).  Care has been taken to
dnl make sure that all of the libraries in "GL_LIBS" are listed in the
dnl proper order.
dnl
dnl Additionally, the shell output variable "GL_CFLAGS" is set to any
dnl flags (e.g. "-I" flags) that are necessary to successfully compile
dnl an OpenGL application.
dnl
dnl The following shell variable (which are not output variables) are
dnl also set to either "yes" or "no" (depending on which libraries were
dnl found) to help you determine exactly what was found.
dnl
dnl   have_GL
dnl   have_GLU
dnl   have_GLX
dnl   have_glut
dnl
dnl A complete little toy "Automake `make distcheck'" package of how to
dnl use this macro is available at:
dnl
dnl   ftp://ftp.slac.stanford.edu/users/langston/autoconf/ac_opengl-0.01.tar.gz
dnl
dnl Please note that as the ac_opengl macro and the toy example evolves,
dnl the version number increases, so you may have to adjust the above
dnl URL accordingly.
dnl
dnl @author Matthew D. Langston <langston@SLAC.Stanford.EDU>

AC_DEFUN(FPTOOLS_HAVE_OPENGL,
[
  AC_REQUIRE([AC_PROG_CC])
  AC_REQUIRE([AC_PATH_X])
  AC_REQUIRE([AC_PATH_XTRA])
  AC_REQUIRE([FPTOOLS_CHECK_LIBM])

dnl Check for Mesa first if we were asked to.
  AC_ARG_ENABLE(Mesa,
    AC_HELP_STRING([--enable-mesa],
                   [prefer Mesa over a vendor's native OpenGL library (default=no)]),
    use_Mesa=$enableval,
    use_Mesa=no)

  if test x"$use_Mesa" = xyes; then
     GL_search_list="MesaGL  GL  opengl32"
    GLU_search_list="MesaGLU GLU glu32"
    GLX_search_list="MesaGLX GLX"
  else
     GL_search_list="GL  opengl32 MesaGL"
    GLU_search_list="GLU glu32    MesaGLU"
    GLX_search_list="GLX          MesaGLX"
  fi      

  AC_LANG_SAVE
  AC_LANG_C

dnl If we are running under X11 then add in the appropriate libraries.
  if test x"$no_x" != xyes; then
dnl Add everything we need to compile and link X programs to GL_CFLAGS
dnl and GL_X_LIBS/GLUT_X_LIBS.
    GL_CFLAGS="$CPPFLAGS $X_CFLAGS"
    GL_X_LIBS="$X_LIBS $X_PRE_LIBS -lXext -lX11 $X_EXTRA_LIBS $LIBM"
    GLUT_X_LIBS="$X_LIBS $X_PRE_LIBS -lXmu -lXt -lXi -lXext -lX11 $X_EXTRA_LIBS $LIBM"
  fi
  GL_save_CPPFLAGS="$CPPFLAGS"
  CPPFLAGS="$GL_CFLAGS"

  GL_save_LIBS="$LIBS"
  LIBS="$GL_X_LIBS"

  FPTOOLS_SEARCH_LIBS([#include <GL/gl.h>],   glEnd,         $GL_search_list,  have_GL=yes,   have_GL=no)
  FPTOOLS_SEARCH_LIBS([#include <GL/glu.h>],  gluNewQuadric, $GLU_search_list, have_GLU=yes,  have_GLU=no)
  FPTOOLS_SEARCH_LIBS([#include <GL/glx.h>],  glXWaitX,      $GLX_search_list, have_GLX=yes,  have_GLX=no)

  if test -n "$LIBS"; then
    GL_LIBS="$LDFLAGS $LIBS"
  else
    GL_LIBS="$LDFLAGS"
    GL_CFLAGS=
  fi

  dnl Keep the GL/GLU/GLX libs, but expand the rest to what GLUT needs.
  dnl (Some systems, like OpenBSD, need the GL/GLU libs.)
  LIBS=`echo "$LIBS" | sed "s@$GL_X_LIBS@$GLUT_X_LIBS@"`

  FPTOOLS_SEARCH_LIBS([#include <GL/glut.h>], glutMainLoop,  glut32 glut,      have_glut=yes, have_glut=no)

  if test -n "$LIBS"; then
    GLUT_LIBS="$LDFLAGS $LIBS"
  fi

  AC_CACHE_CHECK([OpenGL flags], mdl_cv_gl_cflags, [mdl_cv_gl_cflags="$GL_CFLAGS"])
  GL_CFLAGS="$mdl_cv_gl_cflags"
  AC_SUBST(GL_CFLAGS)
  AC_CACHE_CHECK([OpenGL libs],  mdl_cv_gl_libs,   [mdl_cv_gl_libs="$GL_LIBS"])
  GL_LIBS="$mdl_cv_gl_libs"
  AC_SUBST(GL_LIBS)
  AC_CACHE_CHECK([GLUT libs],  mdl_cv_glut_libs,   [mdl_cv_glut_libs="$GLUT_LIBS"])
  GLUT_LIBS="$mdl_cv_glut_libs"
  AC_SUBST(GLUT_LIBS)

dnl Reset GL_X_LIBS/GLUT_X_LIBS regardless, since they were just temporary variables
dnl and we don't want to be global namespace polluters.
  GL_X_LIBS=
  GLUT_X_LIBS=

  LIBS="$GL_save_LIBS"
  CPPFLAGS="$GL_save_CPPFLAGS"

  AC_LANG_RESTORE
])

dnl External macros

builtin([include],acx_pthread.m4)

dnl Simplistic implementation of autoconf 2.50 macros for earlier versions

ifndef([AC_HELP_STRING],
  AC_DEFUN([AC_HELP_STRING],
    [  ifelse(builtin([eval],len([$1])<24),1,[builtin([format], [%-23s], [$1])],[$1
                         ]) $2]))


# FP_CHECK_PROG(VARIABLE, PROG-TO-CHECK-FOR,
#               [VALUE-IF-NOT-FOUND], [PATH], [REJECT])
# -----------------------------------------------------
# HACK: A small wrapper around AC_CHECK_PROG, setting VARIABLE to the full path
# of PROG-TO-CHECK-FOR when found.
AC_DEFUN([FP_CHECK_PROG],
[AC_CHECK_PROG([$1], [$2], [$as_dir/$ac_word$ac_exec_ext], [$3], [$4], [$5])][]dnl
)# FP_CHECK_PROC


# FP_PROG_FIND
# ------------
# Find a non-WinDoze version of the "find" utility.
AC_DEFUN([FP_PROG_FIND],
[AC_PATH_PROG([fp_prog_find], [find])
echo foo > conftest.txt
$fp_prog_find conftest.txt -print > conftest.out 2>&1
if grep '^conftest.txt$' conftest.out > /dev/null 2>&1 ; then
  # OK, looks like a real "find".
  FindCmd="$fp_prog_find"
else
  # Found a poor WinDoze version of "find", ignore it.
  AC_MSG_WARN([$fp_prog_find looks like a non-*nix find, ignoring it])
  FP_CHECK_PROG([FindCmd], [find], [], [], [$fp_prog_find])
fi
rm -f conftest.txt conftest.out
AC_SUBST([FindCmd])[]dnl
])# FP_PROG_FIND


# FP_PROG_SORT
# ------------
# Find a non-WinDoze version of the "sort" utility.
AC_DEFUN([FP_PROG_SORT],
[AC_PATH_PROG([fp_prog_sort], [sort])
echo foo > conftest.txt
$fp_prog_sort -u conftest.txt > conftest.out 2>&1
if grep '^foo$' conftest.out > /dev/null 2>&1 ; then
  # OK, looks like a real "sort".
  SortCmd="$fp_prog_sort"
else
  # Found a poor WinDoze version of "sort", ignore it.
  AC_MSG_WARN([$fp_prog_sort looks like a non-*nix sort, ignoring it])
  FP_CHECK_PROG([SortCmd], [sort], [], [], [$fp_prog_sort])
fi
rm -f conftest.txt conftest.out
AC_SUBST([SortCmd])[]dnl
])# FP_PROG_SORT
