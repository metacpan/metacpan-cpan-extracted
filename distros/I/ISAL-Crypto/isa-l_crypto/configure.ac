#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ(2.69)
AC_INIT([libisal_crypto],
        [2.22.0],
        [sg.support.isal@intel.com],
        [isa-l_crypto],
        [http://01.org/storage-acceleration-library])
AC_CONFIG_SRCDIR([])
AC_CONFIG_AUX_DIR([build-aux])
AM_INIT_AUTOMAKE([
	foreign
	1.11
	-Wall
	-Wno-portability
	silent-rules
	tar-pax
	no-dist-gzip
	dist-xz
	subdir-objects
])
AM_PROG_AS

AC_CANONICAL_HOST
CPU=""
AS_CASE([$host_cpu],
  [x86_64], [CPU="x86_64"],
  [amd64], [CPU="x86_64"],
  [i?86], [CPU="x86_32"],
  [aarch64], [CPU="aarch64"],
  [arm64], [CPU="aarch64"],
)
AM_CONDITIONAL([CPU_X86_64], [test "$CPU" = "x86_64"])
AM_CONDITIONAL([CPU_X86_32], [test "$CPU" = "x86_32"])
AM_CONDITIONAL([CPU_AARCH64], [test "$CPU" = "aarch64"])
AM_CONDITIONAL([CPU_UNDEFINED], [test "x$CPU" = "x"])

if test "$CPU" = "x86_64"; then
   is_x86=yes
else
   if test "$CPU" = "x86_32"; then
      is_x86=yes
   else
      is_x86=no
   fi
fi

# Check for programs
AC_PROG_CC_STDC
AC_USE_SYSTEM_EXTENSIONS
AM_SILENT_RULES([yes])
LT_INIT
AC_PREFIX_DEFAULT([/usr])
AC_PROG_SED
AC_PROG_MKDIR_P

# Options
AC_ARG_ENABLE([debug],
        AS_HELP_STRING([--enable-debug], [enable debug messages @<:@default=disabled@:>@]),
        [], [enable_debug=no])
AS_IF([test "x$enable_debug" = "xyes"], [
        AC_DEFINE(ENABLE_DEBUG, [1], [Debug messages.])
])
# If this build is for x86, look for yasm and nasm
if test x"$is_x86" = x"yes"; then
  # Check for yasm and yasm features
  AC_CHECK_PROG(HAVE_YASM, yasm, yes, no)
  if test "$HAVE_YASM" = "no"; then
    AC_MSG_RESULT([no yasm])
  else
    AC_MSG_CHECKING([for modern yasm])
    AC_LANG_CONFTEST([AC_LANG_SOURCE([[vmovdqa %xmm0, %xmm1;]])])
    if yasm -f elf64 -p gas conftest.c ; then
    with_modern_yasm=yes
    AC_MSG_RESULT([yes])
    AC_MSG_CHECKING([for optional yasm AVX512 support])
    AC_LANG_CONFTEST([AC_LANG_SOURCE([[vpshufb %zmm0, %zmm1, %zmm2;]])])
    if yasm -f elf64 -p gas conftest.c 2> /dev/null; then
      yasm_knows_avx512=yes
      AC_MSG_RESULT([yes])
    else
      AC_MSG_RESULT([no])
    fi
    AC_MSG_CHECKING([for optional yasm SHA-NI support])
    AC_LANG_CONFTEST([AC_LANG_SOURCE([[sha256rnds2 %xmm0,%xmm1,%xmm2;]])])
    if yasm -f elf64 -p gas conftest.c 2> /dev/null; then
      yasm_knows_shani=yes
      AC_MSG_RESULT([yes])
    else
      AC_MSG_RESULT([no])
    fi
    else
    AC_MSG_FAILURE([no])
    fi
  fi

  # Check for nasm and nasm features
  AC_CHECK_PROG(HAVE_NASM, nasm, yes, no)
  if test "$HAVE_NASM" = "no"; then
    AC_MSG_RESULT([no nasm])
  else
    AC_MSG_CHECKING([for modern nasm])
    AC_LANG_CONFTEST([AC_LANG_SOURCE([[pblendvb xmm2, xmm1;]])])
    sed -i -e '/pblendvb/!d' conftest.c
    if nasm -f elf64 conftest.c 2> /dev/null; then
    with_modern_nasm=yes
    AC_MSG_RESULT([yes])
    AC_MSG_CHECKING([for optional nasm AVX512 support])
    AC_LANG_CONFTEST([AC_LANG_SOURCE([[vpshufb zmm0, zmm1, zmm2;]])])
    sed -i -e '/vpshufb/!d' conftest.c
    if nasm -f elf64  conftest.c 2> /dev/null; then
      nasm_knows_avx512=yes
      AC_MSG_RESULT([yes])
    else
      AC_MSG_RESULT([no])
    fi
    AC_MSG_CHECKING([for optional nasm SHA-NI support])
    AC_LANG_CONFTEST([AC_LANG_SOURCE([[sha256rnds2 xmm2,xmm1,xmm0;]])])
    sed -i -e '/sha256rnds2/!d' conftest.c
    if nasm -f elf64  conftest.c 2> /dev/null; then
      nasm_knows_shani=yes
      AC_MSG_RESULT([yes])
    else
      AC_MSG_RESULT([no])
    fi
    else
    AC_MSG_RESULT([no])
    fi
  fi

  # Pick an assembler yasm or nasm
  if test x"$AS" = x""; then
    if test x"$yasm_knows_avx512" = x"yes"; then
    AS=yasm
    elif test x"$nasm_knows_avx512" = x"yes"; then
    AS=nasm
    elif test x"$yasm_knows_shani" = x"yes"; then
    AS=yasm
    elif test x"$nasm_knows_shani" = x"yes"; then
    AS=nasm
    elif test x"$with_modern_yasm" = x"yes"; then
    AS=yasm
    elif test x"$with_modern_nasm" = x"yes"; then
    AS=nasm
    else
    AC_MSG_ERROR([No modern yasm or nasm found as required. Yasm should be 1.2.0 or later, and nasm should be v2.11.01 or later.])
    fi
  fi
  echo "Using assembler $AS"

  if test \( x"$AS" = x"yasm" -a x"$yasm_knows_avx512" = x"yes" \) -o \( x"$AS" = x"nasm" -a x"$nasm_knows_avx512" = x"yes" \); then
    AC_DEFINE(HAVE_AS_KNOWS_AVX512, [1], [Assembler can do AVX512.])
    have_as_knows_avx512=yes
  else
    AC_MSG_RESULT([Assembler does not understand AVX512 opcodes.  Consider upgrading for best performance.])
  fi
  if test \( x"$AS" = x"yasm" -a x"$yasm_knows_shani" = x"yes" \) -o \( x"$AS" = x"nasm" -a x"$nasm_knows_shani" = x"yes" \); then
    AC_DEFINE(HAVE_AS_KNOWS_SHANI, [1], [Assembler can do SHANI.])
    have_as_knows_shani=yes
  else
    AC_MSG_RESULT([Assembler does not understand SHANI opcodes.  Consider upgrading for best performance.])
  fi

  AM_CONDITIONAL(USE_YASM, test x"$AS" = x"yasm")
  AM_CONDITIONAL(USE_NASM, test x"$AS" = x"nasm")
  AM_CONDITIONAL(WITH_AVX512, test x"$have_as_knows_avx512" = x"yes")
  AM_CONDITIONAL(WITH_SHANI, test x"$have_as_knows_shani" = x"yes")


  case $host_os in
     *linux*) arch=linux   yasm_args="-f elf64";;
     *darwin*)  arch=darwin  yasm_args="-f macho64 --prefix=_ ";;
     *netbsd*)  arch=netbsd  yasm_args="-f elf64";;
     *)   arch=unknown yasm_args="-f elf64";;
  esac
  AC_SUBST([yasm_args])
  AM_CONDITIONAL(DARWIN, test x"$arch" = x"darwin")
  AC_MSG_RESULT([Using yasm args target "$arch" "$yasm_args"])
else
  # Disable below conditionals if not x86
  AM_CONDITIONAL(USE_YASM, test "x" = "y")
  AM_CONDITIONAL(USE_NASM, test "x" = "y")
  AM_CONDITIONAL(WITH_AVX512, test "x" = "y")
  AM_CONDITIONAL(WITH_SHANI, test "x" = "y")
  AM_CONDITIONAL(DARWIN, test "x" = "y")
fi
# Check for header files
AC_CHECK_HEADERS([limits.h stdint.h stdlib.h string.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_C_INLINE
AC_TYPE_SIZE_T
AC_TYPE_UINT16_T
AC_TYPE_UINT32_T
AC_TYPE_UINT64_T
AC_TYPE_UINT8_T

# Checks for library functions.
AC_FUNC_MALLOC  # Used only in tests
AC_CHECK_FUNCS([memmove memset])

my_CFLAGS="\
-Wall \
-Wchar-subscripts \
-Wformat-security \
-Wnested-externs \
-Wpointer-arith \
-Wshadow \
-Wstrict-prototypes \
-Wtype-limits \
"
AC_SUBST([my_CFLAGS])

AC_CONFIG_FILES([\
  Makefile\
  libisal_crypto.pc
])

AC_OUTPUT
AC_MSG_RESULT([
        $PACKAGE $VERSION
        =====

        prefix:                 ${prefix}
        sysconfdir:             ${sysconfdir}
        libdir:                 ${libdir}
        includedir:             ${includedir}

        compiler:               ${CC}
        cflags:                 ${CFLAGS}
        ldflags:                ${LDFLAGS}

        debug:                  ${enable_debug}
])
