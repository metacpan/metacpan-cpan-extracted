#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.69])
AC_INIT([shapereader], [0.0.1])
AC_CONFIG_AUX_DIR([build-aux])
AM_INIT_AUTOMAKE([foreign])
AC_CONFIG_SRCDIR([shapereader.h])
AC_CONFIG_HEADERS([config.h])
PKG_INSTALLDIR

# Checks for programs.
AC_PROG_CC
AC_PROG_RANLIB
AM_PROG_AR

# Checks for libraries.

# Checks for header files.

# Checks for typedefs, structures, and compiler characteristics.
AC_C_BIGENDIAN

# Checks for library functions.
AC_MSG_CHECKING([for chdir])
have_chdir=no
AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
#include <unistd.h>
]],[[
chdir(".");
]])],
[AC_DEFINE([HAVE_CHDIR], [1], [Define to 1 if chdir() exists.])]
have_chdir=yes
)
AC_MSG_RESULT([$have_chdir])

AC_MSG_CHECKING([for stat])
have_stat=no
AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
#include <sys/stat.h>
]],[[
struct stat statbuf;
stat(".", &statbuf);
]])],
[AC_DEFINE([HAVE_STAT], [1], [Define to 1 if stat() exists.])]
have_stat=yes
)
AC_MSG_RESULT([$have_stat])

AC_MSG_CHECKING([for strtold])
have_strtold=no
AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
#include <stdlib.h>
]],[[
strtold("0.0", NULL);
]])],
[AC_DEFINE([HAVE_STRTOLD], [1], [Define to 1 if strtold() exists.])]
have_strtold=yes
)
AC_MSG_RESULT([$have_strtold])

AC_MSG_CHECKING([for strtoll])
have_strtoll=no
AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
#include <stdlib.h>
]],[[
strtoll("0", NULL, 10);
]])],
[AC_DEFINE([HAVE_STRTOLL], [1], [Define to 1 if strtoll() exists.])]
have_strtoll=yes
)
AC_MSG_RESULT([$have_strtoll])

AC_MSG_CHECKING([for strtoull])
have_strtoull=no
AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
#include <stdlib.h>
]],[[
strtoull("0", NULL, 10);
]])],
[AC_DEFINE([HAVE_STRTOULL], [1], [Define to 1 if strtoull() exists.])]
have_strtoull=yes
)
AC_MSG_RESULT([$have_strtoull])

AC_MSG_CHECKING([for vsnprintf])
have_vsnprintf=no
AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
char buf[256];
void p(char *format, ...) {
  va_list ap;
  va_start(ap, format);
  vsnprintf(buf, sizeof(buf), format, ap);
  va_end(ap);
}
]],[[
int32_t i = 23;
p("%ld", (long) i);
]])],
[AC_DEFINE([HAVE_VSNPRINTF], [1], [Define to 1 if vsnprintf() exists.])]
have_vsnprintf=yes
)
AC_MSG_RESULT([$have_vsnprintf])

if test "x$have_strtold" != xyes; then
  AC_MSG_ERROR([strtold() is not available])
fi

if test "x$have_strtoll" != xyes; then
  AC_MSG_ERROR([strtoll() is not available])
fi

if test "x$have_strtoull" != xyes; then
  AC_MSG_ERROR([strtoull() is not available])
fi

if test "x$have_vsnprintf" != xyes; then
  AC_MSG_ERROR([vsnprintf() is not available])
fi

AC_CONFIG_FILES([Makefile tests/Makefile tests/data/Makefile shapereader.pc])
AC_REQUIRE_AUX_FILE([tap-driver.sh])
AC_OUTPUT
