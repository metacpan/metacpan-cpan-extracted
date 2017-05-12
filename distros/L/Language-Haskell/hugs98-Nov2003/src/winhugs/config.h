/* ../config.h.  Generated automatically by configure.  */
/* ../config.h.in.  Generated automatically from configure.in by autoheader.  */

/* Define if using alloca.c.  */
#define C_ALLOCA 1

/* Define to empty if the keyword does not work.  */
/* #undef const */

/* Define to one of _getb67, GETB67, getb67 for Cray-2 and Cray-YMP systems.
   This function is required for alloca.c support on those systems.  */
/* #undef CRAY_STACKSEG_END */

/* Define if you have alloca, as a function or macro.  */
/* #undef HAVE_ALLOCA */

/* Define if you have <alloca.h> and it should be used (not on Ultrix).  */
/* #undef HAVE_ALLOCA_H */

/* Define if you have <sys/wait.h> that is POSIX.1 compatible.  */
/* #undef HAVE_SYS_WAIT_H */

/* Define if your struct tm has tm_zone.  */
/* #undef HAVE_TM_ZONE */

/* Define if you don't have tm_zone but do have the external array
   tzname.  */
#define HAVE_TZNAME 1

/* Define as the return type of signal handlers (int or void).  */
#define RETSIGTYPE void

/* If using the C implementation of alloca, define if you know the
   direction of stack growth for your system; otherwise it will be
   automatically deduced at run-time.
 STACK_DIRECTION > 0 => grows toward higher addresses
 STACK_DIRECTION < 0 => grows toward lower addresses
 STACK_DIRECTION = 0 => direction of growth unknown
 */
#define STACK_DIRECTION -1

/* Define if you have the ANSI C header files.  */
#define STDC_HEADERS 1

/* Define if you can safely include both <sys/time.h> and <time.h>.  */
/* #undef TIME_WITH_SYS_TIME */

/* Define if your <sys/time.h> declares struct tm.  */
/* #undef TM_IN_SYS_TIME */

/* Define if the X Window System is missing or not being used.  */
#define X_DISPLAY_MISSING 1

/* The following symbols are defined in options.h:
 * 
 *   BYTECODE_PRIMS
 *   CHECK_TAGS
 *   DEBUG_CODE
 *   DEBUG_PRINTER
 *   DONT_PANIC
 *   GIMME_STACK_DUMPS
 *   HUGSDIR
 *   HUGSPATH
 *   HUGSSUFFIXES
 *   HUGS_FOR_WINDOWS
 *   HUGS_VERSION
 *   INTERNAL_PRIMS
 *   LARGE_HUGS
 *   PATH_CANONICALIZATION
 *   PROFILING
 *   REGULAR_HUGS
 *   SMALL_BANNER
 *   SMALL_HUGS
 *   USE_PREPROCESSOR
 *   USE_READLINE
 *   WANT_TIMER
 *   HASKELL_98_ONLY
 */

/* Define to alignment constraint on chars */
#define ALIGNMENT_CHAR 1

/* Define to alignment constraint on doubles */
#define ALIGNMENT_DOUBLE 8

/* Define to alignment constraint on floats */
#define ALIGNMENT_FLOAT 4

/* Define to alignment constraint on ints */
#define ALIGNMENT_INT 4

/* Define to alignment constraint on longs */
#define ALIGNMENT_LONG 4

/* Define to alignment constraint on long longs */
#define ALIGNMENT_LONG_LONG 8

/* Define to alignment constraint on shorts */
#define ALIGNMENT_SHORT 2

/* Define to alignment constraint on unsigned chars */
#define ALIGNMENT_UNSIGNED_CHAR 1

/* Define to alignment constraint on unsigned ints */
#define ALIGNMENT_UNSIGNED_INT 4

/* Define to alignment constraint on unsigned longs */
#define ALIGNMENT_UNSIGNED_LONG 4

/* Define to alignment constraint on unsigned long longs */
#define ALIGNMENT_UNSIGNED_LONG_LONG 8

/* Define to alignment constraint on unsigned shorts */
#define ALIGNMENT_UNSIGNED_SHORT 2

/* Define to alignment constraint on void pointers */
#define ALIGNMENT_VOID_P 4

/* C compiler invocation use to build a dynamically loadable library.
 * Typical value: "gcc -shared"
 * Must evaluate to a literal C string.
 */
#define MKDLL_CMD "cl /LD /ML /nologo"

/* Define if you have malloc.h and it defines _alloca - eg for Visual C++. */
#define HAVE__ALLOCA 1

/* Define if you have /bin/sh */
#define HAVE_BIN_SH 1

/* Define if you have the GetModuleFileName function.  */
#define HAVE_GETMODULEFILENAME 1

/* Define if heap profiler can (and should) automatically invoke hp2ps
 * to convert heap profile (in "profile.hp") to postscript.
 */
#define HAVE_HP2PS 0

/* Define if compiler supports gcc's "labels as values" (aka computed goto)
 * feature (which is used to speed up instruction dispatch in the interpreter).
 * Here's what typical code looks like:
 *
 * void *label[] = { &&l1, &&l2 };
 * ...
 * goto *label[i];
 * l1: ...
 * l2: ...
 * ...
 */
#define HAVE_LABELS_AS_VALUES 0

/* Define if C compiler supports long long types */
#define HAVE_LONG_LONG 1

/* Define if compiler supports prototypes. */
#define HAVE_PROTOTYPES 1

/* Define if you have the WinExec function.  */
#define HAVE_WINEXEC 1

/* Define if jmpbufs can be treated like arrays.
 * That is, if the following code compiles ok:
 *
 * #include <setjmp.h>
 * 
 * int test1() {
 *     jmp_buf jb[1];
 *     jmp_buf *jbp = jb;
 *     return (setjmp(jb[0]) == 0);
 * }
 */
#define JMPBUF_ARRAY   1

/* Define if your C compiler inserts underscores before symbol names */
/* #undef LEADING_UNDERSCORE */

/* Define if signal handlers have type void (*)(int)
 * (Otherwise, they're assumed to have type int (*)(void).)
 */
#define VOID_INT_SIGNALS 1

/* Define if time.h or sys/time.h define the altzone variable.  */
/* #undef HAVE_ALTZONE */

/* Define if we want to use Apple's OpenGL for the Quartz Display System on Mac OS X (instead of X11) */   
/* #undef USE_QUARTZ_OPENGL */

/* Define if time.h or sys/time.h define the timezone variable.  */
#define HAVE_TIMEZONE 1

/* The number of bytes in a char.  */
#define SIZEOF_CHAR 1

/* The number of bytes in a double.  */
#define SIZEOF_DOUBLE 8

/* The number of bytes in a float.  */
#define SIZEOF_FLOAT 4

/* The number of bytes in a int.  */
#define SIZEOF_INT 4

/* The number of bytes in a int*.  */
#define SIZEOF_INTP 4

/* The number of bytes in a long.  */
#define SIZEOF_LONG 4

/* The number of bytes in a long long.  */
#define SIZEOF_LONG_LONG 8

/* The number of bytes in a short.  */
#define SIZEOF_SHORT 2

/* The number of bytes in a unsigned char.  */
#define SIZEOF_UNSIGNED_CHAR 1

/* The number of bytes in a unsigned int.  */
#define SIZEOF_UNSIGNED_INT 4

/* The number of bytes in a unsigned long.  */
#define SIZEOF_UNSIGNED_LONG 4

/* The number of bytes in a unsigned long long.  */
#define SIZEOF_UNSIGNED_LONG_LONG 8

/* The number of bytes in a unsigned short.  */
#define SIZEOF_UNSIGNED_SHORT 2

/* The number of bytes in a void *.  */
#define SIZEOF_VOID_P 4

/* Define if you have the _fullpath function.  */
#define HAVE__FULLPATH 1

/* Define if you have the _pclose function.  */
#define HAVE__PCLOSE 1

/* Define if you have the _popen function.  */
#define HAVE__POPEN 1

/* Define if you have the _snprintf function.  */
#define HAVE__SNPRINTF 1

/* Define if you have the _stricmp function.  */
#define HAVE__STRICMP 1

/* Define if you have the _vsnprintf function.  */
#define HAVE__VSNPRINTF 1

/* Define if you have the canonicalize_file_name function.  */
/* #undef HAVE_CANONICALIZE_FILE_NAME */

/* Define if you have the farcalloc function.  */
/* #undef HAVE_FARCALLOC */

/* Define if you have the fgetpos function.  */
#define HAVE_FGETPOS 1

/* Define if you have the fseek function.  */
#define HAVE_FSEEK 1

/* Define if you have the fsetpos function.  */
#define HAVE_FSETPOS 1

/* Define if you have the fstat function.  */
#define HAVE_FSTAT 1

/* Define if you have the ftell function.  */
#define HAVE_FTELL 1

/* Define if you have the ftime function.  */
/* #undef HAVE_FTIME */

/* Define if you have the getclock function.  */
/* #undef HAVE_GETCLOCK */

/* Define if you have the getrusage function.  */
/* #undef HAVE_GETRUSAGE */

/* Define if you have the gettimeofday function.  */
/* #undef HAVE_GETTIMEOFDAY */

/* Define if you have the gmtime function.  */
#define HAVE_GMTIME 1

/* Define if you have the isatty function.  */
#define HAVE_ISATTY 1

/* Define if you have the localtime function.  */
#define HAVE_LOCALTIME 1

/* Define if you have the lstat function.  */
/* #undef HAVE_LSTAT */

/* Define if you have the macsystem function.  */
/* #undef HAVE_MACSYSTEM */

/* Define if you have the mktime function.  */
#define HAVE_MKTIME 1

/* Define if you have the PBHSetVolSync function.  */
/* #undef HAVE_PBHSETVOLSYNC */

/* Define if you have the pclose function.  */
/* #undef HAVE_PCLOSE */

/* Define if you have the poly function.  */
/* #undef HAVE_POLY */

/* Define if you have the popen function.  */
/* #undef HAVE_POPEN */

/* Define if you have the readdir_r function.  */
/* #undef HAVE_READDIR_R */

/* Define if you have the realpath function.  */
/* #undef HAVE_REALPATH */

/* Define if you have the rindex function.  */
/* #undef HAVE_RINDEX */

/* Define if you have the select function.  */
/* #undef HAVE_SELECT */

/* Define if you have the setenv function.  */
/* #undef HAVE_SETENV */

/* Define if you have the sigprocmask function.  */
/* #undef HAVE_SIGPROCMASK */

/* Define if you have the snprintf function.  */
/* #undef HAVE_SNPRINTF */

/* Define if you have the stime function.  */
/* #undef HAVE_STIME */

/* Define if you have the strcasecmp function.  */
/* #undef HAVE_STRCASECMP */

/* Define if you have the strcmp function.  */
#define HAVE_STRCMP 1

/* Define if you have the strcmpi function.  */
#define HAVE_STRCMPI 1

/* Define if you have the stricmp function.  */
#define HAVE_STRICMP 1

/* Define if you have the strrchr function.  */
#define HAVE_STRRCHR 1

/* Define if you have the time function.  */
#define HAVE_TIME 1

/* Define if you have the times function.  */
/* #undef HAVE_TIMES */

/* Define if you have the unsetenv function.  */
/* #undef HAVE_UNSETENV */

/* Define if you have the valloc function.  */
/* #undef HAVE_VALLOC */

/* Define if you have the vsnprintf function.  */
/* #undef HAVE_VSNPRINTF */

/* Define if you have the <arpa/inet.h> header file.  */
/* #undef HAVE_ARPA_INET_H */

/* Define if you have the <assert.h> header file.  */
#define HAVE_ASSERT_H 1

/* Define if you have the <conio.h> header file.  */
#define HAVE_CONIO_H 1

/* Define if you have the <console.h> header file.  */
/* #undef HAVE_CONSOLE_H */

/* Define if you have the <ctype.h> header file.  */
#define HAVE_CTYPE_H 1

/* Define if you have the <direct.h> header file.  */
#define HAVE_DIRECT_H 1

/* Define if you have the <dirent.h> header file.  */
/* #undef HAVE_DIRENT_H */

/* Define if you have the <dl.h> header file.  */
/* #undef HAVE_DL_H */

/* Define if you have the <dlfcn.h> header file.  */
/* #undef HAVE_DLFCN_H */

/* Define if you have the <dos.h> header file.  */
#define HAVE_DOS_H 1

/* Define if you have the <errno.h> header file.  */
#define HAVE_ERRNO_H 1

/* Define if you have the <fcntl.h> header file.  */
#define HAVE_FCNTL_H 1

/* Define if you have the <Files.h> header file.  */
/* #undef HAVE_FILES_H */

/* Define if you have the <float.h> header file.  */
#define HAVE_FLOAT_H 1

/* Define if you have the <ftw.h> header file.  */
/* #undef HAVE_FTW_H */

/* Define if you have the <GL/gl.h> header file.  */
/* #undef HAVE_GL_GL_H */

/* Define if you have the <grp.h> header file.  */
/* #undef HAVE_GRP_H */

/* Define if you have the <io.h> header file.  */
#define HAVE_IO_H 1

/* Define if you have the <limits.h> header file.  */
#define HAVE_LIMITS_H 1

/* Define if you have the <mach-o/dyld.h> header file.  */
/* #undef HAVE_MACH_O_DYLD_H */

/* Define if you have the <netdb.h> header file.  */
/* #undef HAVE_NETDB_H */

/* Define if you have the <netinet/in.h> header file.  */
/* #undef HAVE_NETINET_IN_H */

/* Define if you have the <netinet/tcp.h> header file.  */
/* #undef HAVE_NETINET_TCP_H */

/* Define if you have the <nlist.h> header file.  */
/* #undef HAVE_NLIST_H */

/* Define if you have the <OpenGL/gl.h> header file.  */
/* #undef HAVE_OPENGL_GL_H */

/* Define if you have the <pascal.h> header file.  */
/* #undef HAVE_PASCAL_H */

/* Define if you have the <pwd.h> header file.  */
/* #undef HAVE_PWD_H */

/* Define if you have the <sgtty.h> header file.  */
/* #undef HAVE_SGTTY_H */

/* Define if you have the <signal.h> header file.  */
#define HAVE_SIGNAL_H 1

/* Define if you have the <stat.h> header file.  */
/* #undef HAVE_STAT_H */

/* Define if you have the <std.h> header file.  */
/* #undef HAVE_STD_H */

/* Define if you have the <stdarg.h> header file.  */
#define HAVE_STDARG_H 1

/* Define if you have the <stdlib.h> header file.  */
#define HAVE_STDLIB_H 1

/* Define if you have the <string.h> header file.  */
#define HAVE_STRING_H 1

/* Define if you have the <sys/ioctl.h> header file.  */
/* #undef HAVE_SYS_IOCTL_H */

/* Define if you have the <sys/param.h> header file.  */
/* #undef HAVE_SYS_PARAM_H */

/* Define if you have the <sys/resource.h> header file.  */
/* #undef HAVE_SYS_RESOURCE_H */

/* Define if you have the <sys/socket.h> header file.  */
/* #undef HAVE_SYS_SOCKET_H */

/* Define if you have the <sys/stat.h> header file.  */
#define HAVE_SYS_STAT_H 1

/* Define if you have the <sys/time.h> header file.  */
/* #undef HAVE_SYS_TIME_H */

/* Define if you have the <sys/timeb.h> header file.  */
/* #undef HAVE_SYS_TIMEB_H */

/* Define if you have the <sys/timers.h> header file.  */
/* #undef HAVE_SYS_TIMERS_H */

/* Define if you have the <sys/times.h> header file.  */
/* #undef HAVE_SYS_TIMES_H */

/* Define if you have the <sys/types.h> header file.  */
#define HAVE_SYS_TYPES_H 1

/* Define if you have the <sys/uio.h> header file.  */
/* #undef HAVE_SYS_UIO_H */

/* Define if you have the <sys/un.h> header file.  */
/* #undef HAVE_SYS_UN_H */

/* Define if you have the <sys/utsname.h> header file.  */
/* #undef HAVE_SYS_UTSNAME_H */

/* Define if you have the <termio.h> header file.  */
/* #undef HAVE_TERMIO_H */

/* Define if you have the <termios.h> header file.  */
/* #undef HAVE_TERMIOS_H */

/* Define if you have the <time.h> header file.  */
#define HAVE_TIME_H 1

/* Define if you have the <unistd.h> header file.  */
/* #undef HAVE_UNISTD_H */

/* Define if you have the <utime.h> header file.  */
/* #undef HAVE_UTIME_H */

/* Define if you have the <values.h> header file.  */
/* #undef HAVE_VALUES_H */

/* Define if you have the <vfork.h> header file.  */
/* #undef HAVE_VFORK_H */

/* Define if you have the <windows.h> header file.  */
#define HAVE_WINDOWS_H 1

/* Define if you have the <winsock.h> header file.  */
#define HAVE_WINSOCK_H 1

/* Define to the necessary symbol if this constant
                           uses a non-standard name on your system. */
/* #undef PTHREAD_CREATE_JOINABLE */

/* Define if you have POSIX threads libraries and header files. */
/* #undef HAVE_PTHREAD */


/* Define if netinet/in.h defines the in_addr type.  */
/* #undef HAVE_IN_ADDR_T */

/* Define if you have the dl library (-ldl).  */
/* #undef HAVE_LIBDL */

/* Define if you have the dld library (-ldld).  */
/* #undef HAVE_LIBDLD */

/* Define if you have the m library (-lm).  */
#define HAVE_LIBM 1

/* Define if you have the editline library (-leditline).  */
/* #undef HAVE_LIBREADLINE */

/* Define if struct msghdr contains msg_accrights field */
/* #undef HAVE_STRUCT_MSGHDR_MSG_ACCRIGHTS */
 
/* Define if struct msghdr contains msg_control field */
/* #undef HAVE_STRUCT_MSGHDR_MSG_CONTROL */

/* Host cpu architecture */
#define HOST_ARCH "i686"

/* Host operating system */
#define HOST_OS "msvc"

/* Define to Haskell type for cc_t */
#define HTYPE_CC_T NotReallyAType

/* Define to Haskell type for char */
#define HTYPE_CHAR Int8

/* Define to Haskell type for clock_t */
#define HTYPE_CLOCK_T Int32

/* Define to Haskell type for dev_t */
#define HTYPE_DEV_T Word32

/* Define to Haskell type for signed double */
#define HTYPE_DOUBLE Double

/* Define to Haskell type for float */
#define HTYPE_FLOAT Float

/* Define to Haskell type for gid_t */
#define HTYPE_GID_T NotReallyAType

/* Define to Haskell type for GLbitfield */
#define HTYPE_GLBITFIELD Word32

/* Define to Haskell type for GLboolean */
#define HTYPE_GLBOOLEAN Word8

/* Define to Haskell type for GLbyte */
#define HTYPE_GLBYTE Int8

/* Define to Haskell type for GLclampd */
#define HTYPE_GLCLAMPD Double

/* Define to Haskell type for GLclampf */
#define HTYPE_GLCLAMPF Float

/* Define to Haskell type for GLdouble */
#define HTYPE_GLDOUBLE Double

/* Define to Haskell type for GLenum */
#define HTYPE_GLENUM Word32

/* Define to Haskell type for GLfloat */
#define HTYPE_GLFLOAT Float

/* Define to Haskell type for GLint */
#define HTYPE_GLINT Int32

/* Define to Haskell type for GLshort */
#define HTYPE_GLSHORT Int16

/* Define to Haskell type for GLsizei */
#define HTYPE_GLSIZEI Int32

/* Define to Haskell type for GLubyte */
#define HTYPE_GLUBYTE Word8

/* Define to Haskell type for GLuint */
#define HTYPE_GLUINT Word32

/* Define to Haskell type for GLushort */
#define HTYPE_GLUSHORT Word16

/* Define to Haskell type for int */
#define HTYPE_INT Int32

/* Define to Haskell type for ino_t */
#define HTYPE_INO_T Int16

/* Define to Haskell type for long */
#define HTYPE_LONG Int32

/* Define to Haskell type for long long */
#define HTYPE_LONG_LONG Int64

/* Define to Haskell type for mode_t */
#define HTYPE_MODE_T Word16

/* Define to Haskell type for nlink_t */
#define HTYPE_NLINK_T NotReallyAType

/* Define to Haskell type for off_t */
#define HTYPE_OFF_T Int32

/* Define to Haskell type for pid_t */
#define HTYPE_PID_T Int32

/* Define to Haskell type for ptrdiff_t */
#define HTYPE_PTRDIFF_T Int32

/* Define to Haskell type for rlim_t */
#define HTYPE_RLIM_T NotReallyAType

/* Define to Haskell type for short */
#define HTYPE_SHORT Int16

/* Define to Haskell type for sig_atomic_t */
#define HTYPE_SIG_ATOMIC_T Int32

/* Define to Haskell type for signed char */
#define HTYPE_SIGNED_CHAR Int8

/* Define to Haskell type for size_t */
#define HTYPE_SIZE_T Word32

/* Define to Haskell type for speed_t */
#define HTYPE_SPEED_T NotReallyAType

/* Define to Haskell type for ssize_t */
#define HTYPE_SSIZE_T NotReallyAType

/* Define to Haskell type for time_t */
#define HTYPE_TIME_T Int32

/* Define to Haskell type for tcflag_t */
#define HTYPE_TCFLAG_T NotReallyAType

/* Define to Haskell type for uid_t */
#define HTYPE_UID_T NotReallyAType

/* Define to Haskell type for unsigned char */
#define HTYPE_UNSIGNED_CHAR Word8

/* Define to Haskell type for unsigned int */
#define HTYPE_UNSIGNED_INT Word32

/* Define to Haskell type for unsigned long */
#define HTYPE_UNSIGNED_LONG Word32

/* Define to Haskell type for unsigned long long */
#define HTYPE_UNSIGNED_LONG_LONG Word64

/* Define to Haskell type for unsigned short */
#define HTYPE_UNSIGNED_SHORT Word16

/* Define to Haskell type for wchar_t */
#define HTYPE_WCHAR_T Word16

/* The value of E2BIG.  */
#define CONST_E2BIG 7

/* The value of EACCES.  */
#define CONST_EACCES 13

/* The value of EADDRINUSE.  */
#define CONST_EADDRINUSE -1

/* The value of EADDRNOTAVAIL.  */
#define CONST_EADDRNOTAVAIL -1

/* The value of EADV.  */
#define CONST_EADV -1

/* The value of EAFNOSUPPORT.  */
#define CONST_EAFNOSUPPORT -1

/* The value of EAGAIN.  */
#define CONST_EAGAIN 11

/* The value of EALREADY.  */
#define CONST_EALREADY -1

/* The value of EBADF.  */
#define CONST_EBADF 9

/* The value of EBADMSG.  */
#define CONST_EBADMSG -1

/* The value of EBADRPC.  */
#define CONST_EBADRPC -1

/* The value of EBUSY.  */
#define CONST_EBUSY 16

/* The value of ECHILD.  */
#define CONST_ECHILD 10

/* The value of ECOMM.  */
#define CONST_ECOMM -1

/* The value of ECONNABORTED.  */
#define CONST_ECONNABORTED -1

/* The value of ECONNREFUSED.  */
#define CONST_ECONNREFUSED -1

/* The value of ECONNRESET.  */
#define CONST_ECONNRESET -1

/* The value of EDEADLK.  */
#define CONST_EDEADLK 36

/* The value of EDESTADDRREQ.  */
#define CONST_EDESTADDRREQ -1

/* The value of EDIRTY.  */
#define CONST_EDIRTY -1

/* The value of EDOM.  */
#define CONST_EDOM 33

/* The value of EDQUOT.  */
#define CONST_EDQUOT -1

/* The value of EEXIST.  */
#define CONST_EEXIST 17

/* The value of EFAULT.  */
#define CONST_EFAULT 14

/* The value of EFBIG.  */
#define CONST_EFBIG 27

/* The value of EFTYPE.  */
#define CONST_EFTYPE -1

/* The value of EHOSTDOWN.  */
#define CONST_EHOSTDOWN -1

/* The value of EHOSTUNREACH.  */
#define CONST_EHOSTUNREACH -1

/* The value of EIDRM.  */
#define CONST_EIDRM -1

/* The value of EILSEQ.  */
#define CONST_EILSEQ 42

/* The value of EINPROGRESS.  */
#define CONST_EINPROGRESS -1

/* The value of EINTR.  */
#define CONST_EINTR 4

/* The value of EINVAL.  */
#define CONST_EINVAL 22

/* The value of EIO.  */
#define CONST_EIO 5

/* The value of EISCONN.  */
#define CONST_EISCONN -1

/* The value of EISDIR.  */
#define CONST_EISDIR 21

/* The value of ELOOP.  */
#define CONST_ELOOP -1

/* The value of EMFILE.  */
#define CONST_EMFILE 24

/* The value of EMLINK.  */
#define CONST_EMLINK 31

/* The value of EMSGSIZE.  */
#define CONST_EMSGSIZE -1

/* The value of EMULTIHOP.  */
#define CONST_EMULTIHOP -1

/* The value of ENAMETOOLONG.  */
#define CONST_ENAMETOOLONG 38

/* The value of ENETDOWN.  */
#define CONST_ENETDOWN -1

/* The value of ENETRESET.  */
#define CONST_ENETRESET -1

/* The value of ENETUNREACH.  */
#define CONST_ENETUNREACH -1

/* The value of ENFILE.  */
#define CONST_ENFILE 23

/* The value of ENOBUFS.  */
#define CONST_ENOBUFS -1

/* The value of ENODATA.  */
#define CONST_ENODATA -1

/* The value of ENODEV.  */
#define CONST_ENODEV 19

/* The value of ENOENT.  */
#define CONST_ENOENT 2

/* The value of ENOEXEC.  */
#define CONST_ENOEXEC 8

/* The value of ENOLCK.  */
#define CONST_ENOLCK 39

/* The value of ENOLINK.  */
#define CONST_ENOLINK -1

/* The value of ENOMEM.  */
#define CONST_ENOMEM 12

/* The value of ENOMSG.  */
#define CONST_ENOMSG -1

/* The value of ENONET.  */
#define CONST_ENONET -1

/* The value of ENOPROTOOPT.  */
#define CONST_ENOPROTOOPT -1

/* The value of ENOSPC.  */
#define CONST_ENOSPC 28

/* The value of ENOSR.  */
#define CONST_ENOSR -1

/* The value of ENOSTR.  */
#define CONST_ENOSTR -1

/* The value of ENOSYS.  */
#define CONST_ENOSYS 40

/* The value of ENOTBLK.  */
#define CONST_ENOTBLK -1

/* The value of ENOTCONN.  */
#define CONST_ENOTCONN -1

/* The value of ENOTDIR.  */
#define CONST_ENOTDIR 20

/* The value of ENOTEMPTY.  */
#define CONST_ENOTEMPTY 41

/* The value of ENOTSOCK.  */
#define CONST_ENOTSOCK -1

/* The value of ENOTTY.  */
#define CONST_ENOTTY 25

/* The value of ENXIO.  */
#define CONST_ENXIO 6

/* The value of EOPNOTSUPP.  */
#define CONST_EOPNOTSUPP -1

/* The value of EPERM.  */
#define CONST_EPERM 1

/* The value of EPFNOSUPPORT.  */
#define CONST_EPFNOSUPPORT -1

/* The value of EPIPE.  */
#define CONST_EPIPE 32

/* The value of EPROCLIM.  */
#define CONST_EPROCLIM -1

/* The value of EPROCUNAVAIL.  */
#define CONST_EPROCUNAVAIL -1

/* The value of EPROGMISMATCH.  */
#define CONST_EPROGMISMATCH -1

/* The value of EPROGUNAVAIL.  */
#define CONST_EPROGUNAVAIL -1

/* The value of EPROTO.  */
#define CONST_EPROTO -1

/* The value of EPROTONOSUPPORT.  */
#define CONST_EPROTONOSUPPORT -1

/* The value of EPROTOTYPE.  */
#define CONST_EPROTOTYPE -1

/* The value of ERANGE.  */
#define CONST_ERANGE 34

/* The value of EREMCHG.  */
#define CONST_EREMCHG -1

/* The value of EREMOTE.  */
#define CONST_EREMOTE -1

/* The value of EROFS.  */
#define CONST_EROFS 30

/* The value of ERPCMISMATCH.  */
#define CONST_ERPCMISMATCH -1

/* The value of ERREMOTE.  */
#define CONST_ERREMOTE -1

/* The value of ESHUTDOWN.  */
#define CONST_ESHUTDOWN -1

/* The value of ESOCKTNOSUPPORT.  */
#define CONST_ESOCKTNOSUPPORT -1

/* The value of ESPIPE.  */
#define CONST_ESPIPE 29

/* The value of ESRCH.  */
#define CONST_ESRCH 3

/* The value of ESRMNT.  */
#define CONST_ESRMNT -1

/* The value of ESTALE.  */
#define CONST_ESTALE -1

/* The value of ETIME.  */
#define CONST_ETIME -1

/* The value of ETIMEDOUT.  */
#define CONST_ETIMEDOUT -1

/* The value of ETOOMANYREFS.  */
#define CONST_ETOOMANYREFS -1

/* The value of ETXTBSY.  */
#define CONST_ETXTBSY -1

/* The value of EUSERS.  */
#define CONST_EUSERS -1

/* The value of EWOULDBLOCK.  */
#define CONST_EWOULDBLOCK -1

/* The value of EXDEV.  */
#define CONST_EXDEV 18

/* The value of O_BINARY.  */
#define CONST_O_BINARY 32768
