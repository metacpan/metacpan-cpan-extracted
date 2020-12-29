AC_INIT
AC_CONFIG_SRCDIR([libeio/eio.h])
AC_CONFIG_HEADERS([config.h])

AC_PREREQ(2.60)
AC_USE_SYSTEM_EXTENSIONS

AC_PROG_CC

m4_include([libeio/libeio.m4])

# for these to work, you need to run autoheader in IO::AIO, not libeio :(

AC_CACHE_CHECK(for set/getrlimit, ac_cv_rlimits, [AC_LINK_IFELSE([AC_LANG_SOURCE([[
#include <sys/time.h>
#include <sys/resource.h>
int main (void)
{
   struct rlimit srl;
   int res;
   srl.rlim_cur = srl.rlim_max = RLIM_INFINITY;
   res = getrlimit (RLIMIT_NOFILE, &srl);
   res = setrlimit (RLIMIT_NOFILE, &srl);
   return 0;
}
]])],ac_cv_rlimits=yes,ac_cv_rlimits=no)])
test $ac_cv_rlimits = yes && AC_DEFINE(HAVE_RLIMITS, 1, setrlimit/getrlimit is available)

dnl at least uclibc defines _POSIX_ADVISORY_INFO without *any* of the required
dnl functionality actually being present. ugh.
AC_CACHE_CHECK(for posix_madvise, ac_cv_posix_madvise, [AC_LINK_IFELSE([AC_LANG_SOURCE([
#include <sys/mman.h>
int main (void)
{
   int res = posix_madvise ((void *)0, (size_t)0, POSIX_MADV_NORMAL);
   int a = POSIX_MADV_SEQUENTIAL;
   int b = POSIX_MADV_RANDOM;
   int c = POSIX_MADV_WILLNEED;
   int d = POSIX_MADV_DONTNEED;
   return 0;
}
])],ac_cv_posix_madvise=yes,ac_cv_posix_madvise=no)])
test $ac_cv_posix_madvise = yes && AC_DEFINE(HAVE_POSIX_MADVISE, 1, posix_madvise(2) is available)

AC_CACHE_CHECK(for posix_fadvise, ac_cv_posix_fadvise, [AC_LINK_IFELSE([AC_LANG_SOURCE([
#define _XOPEN_SOURCE 600
#include <fcntl.h>
int main (void)
{
   int res = posix_fadvise ((int)0, (off_t)0, (off_t)0, POSIX_FADV_NORMAL);
   int a = POSIX_FADV_SEQUENTIAL;
   int b = POSIX_FADV_NOREUSE;
   int c = POSIX_FADV_RANDOM;
   int d = POSIX_FADV_WILLNEED;
   int e = POSIX_FADV_DONTNEED;
   return 0;
}
])],ac_cv_posix_fadvise=yes,ac_cv_posix_fadvise=no)])
test $ac_cv_posix_fadvise = yes && AC_DEFINE(HAVE_POSIX_FADVISE, 1, posix_fadvise(2) is available)

dnl lots of linux specifics
AC_CHECK_HEADERS([linux/fs.h linux/fiemap.h])

dnl glibc major/minor macros
AC_CHECK_HEADERS([sys/sysmacros.h])

dnl solaris major/minor
AC_CHECK_HEADERS([sys/mkdev.h])

dnl readv / preadv, vmsplice
AC_CHECK_HEADERS([sys/uio.h])

AC_CACHE_CHECK([for unix-style syscall interface], ac_cv_syscall, [AC_LINK_IFELSE([AC_LANG_SOURCE([
#include <unistd.h>
#include <sys/syscall.h>
int main (void)
{
   long res = syscall (SYS_exit, 0);
   return 0;
}
])],ac_cv_syscall=yes,ac_cv_syscall=no)])
test $ac_cv_syscall = yes && AC_DEFINE(HAVE_SYSCALL, 1, unix syscall interface)

AC_CACHE_CHECK([for splice, vmsplice and tee], ac_cv_linux_splice, [AC_LINK_IFELSE([AC_LANG_SOURCE([
#include <sys/types.h>
#include <fcntl.h>
#include <sys/uio.h>
int main (void)
{
   ssize_t res;
   res = splice ((int)0, (loff_t)0, (int)0, (loff_t *)0, (size_t)0, SPLICE_F_MOVE | SPLICE_F_NONBLOCK | SPLICE_F_MORE);
   res = tee ((int)0, (int)0, (size_t)0, SPLICE_F_NONBLOCK);
   res = vmsplice ((int)0, (struct iovec *)0, 0, SPLICE_F_NONBLOCK | SPLICE_F_GIFT);
   return 0;
}
])],ac_cv_linux_splice=yes,ac_cv_linux_splice=no)])
test $ac_cv_linux_splice = yes && AC_DEFINE(HAVE_LINUX_SPLICE, 1, splice/vmsplice/tee(2) are available)

AC_CACHE_CHECK(for pipe2, ac_cv_pipe2, [AC_LINK_IFELSE([AC_LANG_SOURCE([[
#include <fcntl.h>
#include <unistd.h>
int main (void)
{
   int res;
   res = pipe2 (0, 0);
   return 0;
}
]])],ac_cv_pipe2=yes,ac_cv_pipe2=no)])
test $ac_cv_pipe2 = yes && AC_DEFINE(HAVE_PIPE2, 1, pipe2(2) is available)

AC_CACHE_CHECK(for eventfd, ac_cv_eventfd, [AC_LINK_IFELSE([AC_LANG_SOURCE([[
#include <sys/eventfd.h>
int main (void)
{
   int res;
   res = eventfd (1, EFD_CLOEXEC | EFD_NONBLOCK);
   return 0;
}
]])],ac_cv_eventfd=yes,ac_cv_eventfd=no)])
test $ac_cv_eventfd = yes && AC_DEFINE(HAVE_EVENTFD, 1, eventfd(2) is available)

AC_CACHE_CHECK(for timerfd_*, ac_cv_timerfd, [AC_LINK_IFELSE([AC_LANG_SOURCE([[
#include <sys/timerfd.h>
int main (void)
{
   struct itimerspec its;
   int res;
   res = timerfd_create (CLOCK_REALTIME, TFD_CLOEXEC | TFD_NONBLOCK);
   res = timerfd_settime (res, TFD_TIMER_ABSTIME /*| TFD_TIMER_CANCEL_ON_SET*/, &its, 0);
   res = timerfd_gettime (res, &its);
   return 0;
}
]])],ac_cv_timerfd=yes,ac_cv_timerfd=no)])
test $ac_cv_timerfd = yes && AC_DEFINE(HAVE_TIMERFD, 1, timerfd_*(2) are available)

AC_CACHE_CHECK(for memfd_create, ac_cv_memfd_create, [AC_LINK_IFELSE([AC_LANG_SOURCE([[
#include <sys/mman.h>
int main (void)
{
   int res = memfd_create ("name", MFD_CLOEXEC | MFD_ALLOW_SEALING);
   return 0;
}
]])],ac_cv_memfd_create=yes,ac_cv_memfd_create=no)])
test $ac_cv_memfd_create = yes && AC_DEFINE(HAVE_MEMFD_CREATE, 1, memfd_create(2) is available)

AC_CACHE_CHECK(for copy_file_range, ac_cv_copy_file_range, [AC_LINK_IFELSE([AC_LANG_SOURCE([[
#include <unistd.h>
#include <sys/syscall.h>
/*#include <linux/copy.h>*/
int main (void)
{
   int res;
   /*res = syscall (SYS_copy_file_range, 0, 0, 0, 0, 0, COPY_FR_REFLINK | COPY_FR_DEDUP | COPY_FR_COPY);*/
   res = syscall (SYS_copy_file_range, 0, 0, 0, 0, 0, 0);
   return 0;
}
]])],ac_cv_copy_file_range=yes,ac_cv_copy_file_range=no)])
test $ac_cv_copy_file_range = yes && AC_DEFINE(HAVE_COPY_FILE_RANGE, 1, copy_file_range(2) is available)

AC_CACHE_CHECK(for st_xtimensec, ac_cv_xtimensec, [AC_COMPILE_IFELSE([AC_LANG_SOURCE([[
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int main (void)
{
   return PL_statcache.st_atimensec
        + PL_statcache.st_mtimensec
        + PL_statcache.st_ctimensec;
}
]])],ac_cv_xtimensec=yes,ac_cv_xtimensec=no)])
test $ac_cv_xtimensec = yes && AC_DEFINE(HAVE_ST_XTIMENSEC, 1, stat nanosecond access by st_xtimensec)

AC_CACHE_CHECK(for st_xtimespec, ac_cv_xtimespec, [AC_COMPILE_IFELSE([AC_LANG_SOURCE([[
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int main (void)
{
   return PL_statcache.st_atim.tv_nsec
        + PL_statcache.st_mtim.tv_nsec
        + PL_statcache.st_ctim.tv_nsec;
}
]])],ac_cv_xtimespec=yes,ac_cv_xtimespec=no)])
test $ac_cv_xtimespec = yes && AC_DEFINE(HAVE_ST_XTIMESPEC, 1, stat nanosecond access by st_xtimespec)

# apparently, True64 uses st_u[amc]time, aix uses at_[amc]time_n and apple uses st_[amc,birth]timespec?

AC_CACHE_CHECK(for st_birthtimensec, ac_cv_birthtimensec, [AC_COMPILE_IFELSE([AC_LANG_SOURCE([[
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int main (void)
{
   return PL_statcache.st_birthtime + PL_statcache.st_birthtimensec;
}
]])],ac_cv_birthtimensec=yes,ac_cv_birthtimensec=no)])
test $ac_cv_birthtimensec = yes && AC_DEFINE(HAVE_ST_BIRTHTIMENSEC, 1, birthtime nanosecond access by st_birthtimensec)

AC_CACHE_CHECK(for st_birthtimespec, ac_cv_birthtimespec, [AC_COMPILE_IFELSE([AC_LANG_SOURCE([[
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int main (void)
{
   return PL_statcache.st_birthtim.tv_sec + PL_statcache.st_birthtim.tv_nsec;
}
]])],ac_cv_birthtimespec=yes,ac_cv_birthtimespec=no)])
test $ac_cv_birthtimespec = yes && AC_DEFINE(HAVE_ST_BIRTHTIMESPEC, 1, birthtime nanosecond access by st_birthtimespec)

AC_CACHE_CHECK(for st_gen, ac_cv_st_gen, [AC_COMPILE_IFELSE([AC_LANG_SOURCE([[
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int main (void)
{
   return PL_statcache.st_gen;
}
]])],ac_cv_st_gen=yes,ac_cv_st_gen=no)])
test $ac_cv_st_gen = yes && AC_DEFINE(HAVE_ST_GEN, 1, stat st_gen member)

AC_CACHE_CHECK(for statx, ac_cv_statx, [AC_LINK_IFELSE([AC_LANG_SOURCE([[
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
int res;
int main (void)
{
   struct statx sx;
   int res;
   res = statx (AT_FDCWD, ".",
         AT_EMPTY_PATH | AT_NO_AUTOMOUNT | AT_SYMLINK_NOFOLLOW | AT_STATX_SYNC_AS_STAT | AT_STATX_FORCE_SYNC | AT_STATX_DONT_SYNC,
         STATX_ALL, &sx);
   STATX_TYPE; STATX_MODE; STATX_NLINK; STATX_UID; STATX_GID; STATX_ATIME; STATX_MTIME; STATX_CTIME;
   STATX_INO; STATX_SIZE; STATX_BLOCKS; STATX_BASIC_STATS; STATX_BTIME; STATX_ALL;
   STATX_ATTR_COMPRESSED; STATX_ATTR_IMMUTABLE; STATX_ATTR_APPEND; STATX_ATTR_NODUMP; STATX_ATTR_ENCRYPTED;
   return 0;
}
]])],ac_cv_statx=yes,ac_cv_statx=no)])
test $ac_cv_statx = yes && AC_DEFINE(HAVE_STATX, 1, statx(2) is available)

AC_CACHE_CHECK(for accept4, ac_cv_accept4, [AC_LINK_IFELSE([AC_LANG_SOURCE([[
#include <sys/types.h>
#include <sys/socket.h>
int main (void)
{
   int res;
   res = accept4 (1, (struct sockaddr *)0, (socklen_t)0, SOCK_NONBLOCK | SOCK_CLOEXEC);
   return 0;
}
]])],ac_cv_accept4=yes,ac_cv_accept4=no)])
test $ac_cv_accept4 = yes && AC_DEFINE(HAVE_ACCEPT4, 1, accept4(2) is available)

AC_OUTPUT

