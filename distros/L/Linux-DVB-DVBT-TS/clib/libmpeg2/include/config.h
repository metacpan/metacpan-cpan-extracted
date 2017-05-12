/* i486-linux-gnu-thread-multi */
#ifndef CONFIG_H
#define CONFIG_H
	
/* autodetect accelerations */
#define ACCEL_DETECT 

/* Define if building universal (internal helper macro) */
#undef AC_APPLE_UNIVERSAL_BUILD

/* alpha architecture */
#undef ARCH_ALPHA

/* ARM architecture */
#undef ARCH_ARM 

/* ppc architecture */
#undef ARCH_PPC

/* sparc architecture */
#undef ARCH_SPARC

/* x86 architecture */
#undef ARCH_X86

#define ARCH_X86

/* Operating system */
#define OS_LINUX


/* maximum supported data alignment */
#define ATTRIBUTE_ALIGNED_MAX 32

/* debug mode configuration */
#undef DEBUG

/* Define to 1 if you have the <altivec.h> header. */
/* #undef HAVE_ALTIVEC_H */

/* Define if you have the `__builtin_expect' function. */
#define HAVE_BUILTIN_EXPECT 1

/* Define to 1 if you have the `ftime' function. */
#define HAVE_FTIME 1

/* Define to 1 if you have the `gettimeofday' function. */
#define HAVE_GETTIMEOFDAY 1

/* Define to 1 if you have the <inttypes.h> header file. */
#define HAVE_INTTYPES_H 1

/* Define to 1 if you have the <io.h> header file. */
#undef HAVE_IO_H 

/* Define to 1 if you have the <memory.h> header file. */
#define HAVE_MEMORY_H 1

/* Define to 1 if you have the <stdint.h> header file. */
#define HAVE_STDINT_H 1

/* Define to 1 if you have the <stdlib.h> header file. */
#define HAVE_STDLIB_H 1

/* Define to 1 if you have the <strings.h> header file. */
#define HAVE_STRINGS_H 1

/* Define to 1 if you have the <string.h> header file. */
#define HAVE_STRING_H 1

/* Define to 1 if the system has the type `struct timeval'. */
#define HAVE_STRUCT_TIMEVAL 1

/* Define to 1 if you have the <sys/stat.h> header file. */
#define HAVE_SYS_STAT_H 1

/* Define to 1 if you have the <sys/timeb.h> header file. */
#define HAVE_SYS_TIMEB_H 1

/* Define to 1 if you have the <sys/time.h> header file. */
#define HAVE_SYS_TIME_H 1

/* Define to 1 if you have the <sys/types.h> header file. */
#define HAVE_SYS_TYPES_H 1

/* Define to 1 if you have the <time.h> header file. */
#define HAVE_TIME_H 1

/* Define to 1 if you have the <unistd.h> header file. */
#define HAVE_UNISTD_H 1


/* mpeg2dec profiling */
#undef MPEG2DEC_GPROF

/* Name of package */
#define PACKAGE "libmpeg2"

/* Define to the address where bug reports for this package should be sent. */
#define PACKAGE_BUGREPORT ""

/* Define to the full name of this package. */
#define PACKAGE_NAME "libmpeg2"

/* Define to the full name and version of this package. */
#define PACKAGE_STRING "libmpeg2 0.5.1"

/* Define to the one symbol short name of this package. */
#define PACKAGE_TARNAME "libmpeg2"

/* Define to the version of this package. */
#define PACKAGE_VERSION "0.5.1"



/* Define as the return type of signal handlers - this is now ALWAYS 'void' */
#define RETSIGTYPE void


/* Define WORDS_BIGENDIAN to 1 if your processor stores words with the most
   significant byte first (like Motorola and SPARC, unlike Intel). */

#undef WORDS_BIGENDIAN
#undef SHORT_BIGENDIAN
#undef WORDS_LITTLEENDIAN
#define SHORT_LITTLEENDIAN	1


/* Number of bits in a file offset, on hosts where this is settable. */
#define _FILE_OFFSET_BITS 64

/* Define for large files, on AIX-style hosts. */
#define _LARGE_FILES 1

/* Define to empty if `const' does not conform to ANSI C. */
/* #define const  */

/* Define to `__inline__' or `__inline' if that's what the C compiler
   calls it, or to nothing if 'inline' is not supported under any name.  */
#ifndef __cplusplus

#endif

/* Define as `__restrict' if that's what the C compiler calls it, or to
   nothing if it is not supported. */
#define restrict __restrict__

/* Work around a bug in Sun C++: it does not support _Restrict, even
   though the corresponding Sun C compiler does, which causes
   "#define restrict _Restrict" in the previous line.  Perhaps some future
   version of Sun C++ will work with _Restrict; if so, it'll probably
   define __RESTRICT, just as Sun C does.  */
#if defined __SUNPRO_CC && !defined __RESTRICT
# define _Restrict
#endif

/* Define to `unsigned int' if <sys/types.h> does not define. */


/* Define to empty if the keyword `volatile' does not work. Warning: valid
   code using `volatile' can become incorrect without. Disable with care. */
/* #define volatile  */

#endif

