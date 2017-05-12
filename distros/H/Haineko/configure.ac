dnl #                                               -*- Autoconf -*-
dnl # Process this file with autoconf to produce a configure script.
dnl # -Id: configure.ac,v 1.35 2009/08/27 05:09:04 ak Exp -
dnl # Copyright (C) 2013 azumakuniyuki
AC_PREREQ(2.61)
AC_INIT([haineko], [0.2.16], [haineko@azumakuniyuki.org])
AM_INIT_AUTOMAKE([foreign])
AC_PREFIX_DEFAULT(/usr/local/haineko)
AC_CANONICAL_HOST

AC_SUBST(TARGET_OSTYPE)
AC_SUBST(TARGET_HOSTNAME)
AC_SUBST(TARGET_DOMAINNAME)

BUILDROOT=`pwd`
AC_SUBST(BUILDROOT)

dnl # Checks for programs.
AC_PROG_INSTALL
AC_PROG_MAKE_SET
AC_PATH_PROG(SHELL, sh, no, /bin:/usr/bin:/usr/local/bin)
if test "x$SHELL" = xno; then
    AC_MSG_ERROR([*** Cannot find sh program])
fi

AC_PROG_LN_S
AC_PATH_PROG(CAT, cat, no, /bin:/usr/bin:/usr/local/bin)
if test "x$CAT" = xno; then
    AC_MSG_ERROR([*** Cannot find cat program])
fi

AC_PATH_PROG(TOUCH, touch, no, /bin:/usr/bin:/usr/local/bin)
if test "x$TOUCH" = xno; then
    AC_MSG_ERROR([*** Cannot find touch program])
fi

AC_PATH_PROG(FIND, find, no, /bin:/usr/bin:/usr/local/bin)
if test "x$FIND" = xno; then
    AC_MSG_ERROR([*** Cannot find find program])
fi

AC_PATH_PROG(CPANM, cpanm, no, .:~/bin:/bin:/usr/bin:/usr/local/bin)
if test "x$CPANM" = xno; then
    AC_MSG_ERROR([*** Cannot find cpanm program. Try ``curl -LO http://xrl.us/cpanm''])
fi

AC_ARG_WITH([perl],
    AC_HELP_STRING(
        [--with-perl=PATH],
        [Path to perl binary, ex) /usr/local/bin/perl]),
    [WITH_PERLPATH=$withval],[WITH_PERLPATH=none])
if test "x$WITH_PERLPATH" = "xnone"; then
    AC_PATH_PROG(PERL, perl, no, /usr/local/bin:/usr/bin:/bin)
    if test "x$PERL" = xno; then
        AC_MSG_ERROR([*** Cannot find perl program])
    fi
    AC_PATH_PROG(PROVE, prove, no, /usr/local/bin:/usr/bin:/bin)
    if test "x$PROVE" = xno; then
        PROVE="$PERL -I./blib/lib -I./lib -I./dist/lib/perl5"
    else
        PROVE="$PROVE -r --timer -I./blib/lib -I./lib -I./dist/lib/perl5"
    fi
else
    PERL=$WITH_PERLPATH
    PROVE=`dirname $WITH_PERLPATH`/prove
    if test "x$PROVE" = xno; then
        PROVE="$PERL -I./blib/lib -I./lib -I./dist/lib/perl5"
    else
        PROVE="$PROVE -r --timer -I./blib/lib -I./lib -I./dist/lib/perl5"
    fi
fi

dnl # Checks for library functions.
AC_CONFIG_FILES([
        Makefile
        bin/Makefile
        etc/Makefile
        lib/Makefile
        lib/Haineko/Makefile
        lib/Haineko/CLI/Makefile
        lib/Haineko/CLI/Setup/Makefile
        lib/Haineko/HTTPD/Makefile
        lib/Haineko/SMTPD/Makefile
        lib/Haineko/SMTPD/Milter/Makefile
        lib/Haineko/SMTPD/Relay/Makefile
        libexec/Makefile])
AC_OUTPUT
