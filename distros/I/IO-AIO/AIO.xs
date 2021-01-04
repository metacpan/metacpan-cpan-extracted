#include "libeio/xthread.h"

#include <errno.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "perliol.h"

#if !defined mg_findext
# define mg_findext(sv,type,vtbl) mg_find (sv, type)
#endif

#include <stddef.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <limits.h>
#include <fcntl.h>
#include <sched.h>

/* the incompetent fool that created musl keeps __linux__, refuses
 * to implement any linux standard apis, and also has no way to test
 * for his broken iplementation. don't complain to me if this fails
 * for you.
 */
#if __linux__ && (defined __GLIBC__ || defined __UCLIBC__)
# include <linux/fs.h>
# ifdef FS_IOC_FIEMAP
#  include <linux/types.h>
#  include <linux/fiemap.h>
#  define HAVE_FIEMAP 1
# endif
#endif

/* perl namespace pollution */
#undef VERSION

/* perl stupidly overrides readdir and maybe others */
/* with thread-unsafe versions, imagine that :( */
#undef readdir
#undef opendir
#undef closedir

#ifdef _WIN32

  // perl overrides all those nice libc functions

  #undef malloc
  #undef free
  #undef open
  #undef read
  #undef write
  #undef send
  #undef recv
  #undef stat
  #undef lstat
  #undef fstat
  #undef truncate
  #undef ftruncate
  #undef open
  #undef link
  #undef close
  #undef unlink
  #undef mkdir
  #undef rmdir
  #undef rename
  #undef lseek
  #undef opendir
  #undef readdir
  #undef closedir
  #undef chmod
  #undef fchmod
  #undef dup
  #undef dup2
  #undef abort
  #undef pipe
  #undef utime

  #define EIO_STRUCT_STAT struct _stati64
  #define EIO_STRUCT_STATI64

#else

  #include <sys/time.h>
  #include <sys/select.h>
  #include <sys/wait.h>
  #include <unistd.h>
  #include <utime.h>
  #include <signal.h>

  #define EIO_STRUCT_STAT Stat_t

#endif

/*****************************************************************************/

#if __GNUC__ >= 3
# define expect(expr,value) __builtin_expect ((expr),(value))
#else
# define expect(expr,value) (expr)
#endif

#define expect_false(expr) expect ((expr) != 0, 0)
#define expect_true(expr)  expect ((expr) != 0, 1)

/*****************************************************************************/

#include "config.h"

#if HAVE_SYS_MKDEV_H
# include <sys/mkdev.h>
#elif HAVE_SYS_SYSMACROS_H
# include <sys/sysmacros.h>
#endif

#if _POSIX_MEMLOCK || _POSIX_MEMLOCK_RANGE || _POSIX_MAPPED_FILES
# include <sys/mman.h>
#endif

#if HAVE_SYS_UIO_H
# include <sys/uio.h>
#endif

#if HAVE_ST_XTIMENSEC
# define ATIMENSEC PL_statcache.st_atimensec
# define MTIMENSEC PL_statcache.st_mtimensec
# define CTIMENSEC PL_statcache.st_ctimensec
#elif HAVE_ST_XTIMESPEC
# define ATIMENSEC PL_statcache.st_atim.tv_nsec
# define MTIMENSEC PL_statcache.st_mtim.tv_nsec
# define CTIMENSEC PL_statcache.st_ctim.tv_nsec
#else
# define ATIMENSEC 0
# define MTIMENSEC 0
# define CTIMENSEC 0
#endif

#if HAVE_ST_BIRTHTIMENSEC
# define BTIMESEC  PL_statcache.st_birthtime
# define BTIMENSEC PL_statcache.st_birthtimensec
#elif HAVE_ST_BIRTHTIMESPEC
# define BTIMESEC  PL_statcache.st_birthtim.tv_sec
# define BTIMENSEC PL_statcache.st_birthtim.tv_nsec
#else
# define BTIMESEC  0
# define BTIMENSEC 0
#endif

#if HAVE_ST_GEN
# define ST_GEN    PL_statcache.st_gen
#else
# define ST_GEN    0
#endif

#include "schmorp.h"

#if HAVE_EVENTFD
# include <sys/eventfd.h>
#endif

#if HAVE_TIMERFD
# include <sys/timerfd.h>
#endif

#if HAVE_RLIMITS
  #include <sys/time.h>
  #include <sys/resource.h>
#endif

typedef SV SV8; /* byte-sv, used for argument-checking */
typedef int aio_rfd; /* read file desriptor */
typedef int aio_wfd; /* write file descriptor */

static HV *aio_stash, *aio_req_stash, *aio_grp_stash, *aio_wd_stash;

#define EIO_REQ_MEMBERS	\
  SV *callback;		\
  SV *sv1, *sv2;	\
  SV *sv3, *sv4;	\
  STRLEN stroffset;	\
  SV *self;

#define EIO_NO_WRAPPERS 1

#include "libeio/eio.h"

static int req_invoke    (eio_req *req);
#define EIO_FINISH(req)  req_invoke (req)
static void req_destroy  (eio_req *grp);
#define EIO_DESTROY(req) req_destroy (req)

#include "libeio/eio.c"

#if !HAVE_POSIX_FADVISE
# define posix_fadvise(a,b,c,d) errno = ENOSYS /* also return ENOSYS */
#endif

#if !HAVE_POSIX_MADVISE
# define posix_madvise(a,b,c) errno = ENOSYS /* also return ENOSYS */
#endif

#ifndef MAP_ANONYMOUS
# ifdef MAP_ANON
#  define MAP_ANONYMOUS MAP_ANON
# else
#  define MAP_ANONYMOUS MAP_FIXED /* and hope this fails */
# endif
#endif

#ifndef makedev
# define makedev(maj,min) (((maj) << 8) | (min))
#endif
#ifndef major
# define major(dev) ((dev) >> 8)
#endif
#ifndef minor
# define minor(dev) ((dev) & 0xff)
#endif

/* solaris has a non-posix/unix compliant PAGESIZE that breaks compilation */
#ifdef __sun
# undef PAGESIZE
#endif

#if PAGESIZE <= 0
# define PAGESIZE sysconf (_SC_PAGESIZE)
#endif

#if HAVE_SYSCALL
#include <sys/syscall.h>
#else
# define syscall(nr,...) (errno = ENOSYS, -1)
#endif

/*****************************************************************************/

#if !_POSIX_MAPPED_FILES
# define mmap(addr,length,prot,flags,fd,offs) (errno = ENOSYS, (void *)-1)
# define munmap(addr,length)                  EIO_ENOSYS ()
#endif

#if !_POSIX_MEMORY_PROTECTION
# define mprotect(addr,len,prot)              EIO_ENOSYS ()
#endif

#if !MREMAP_MAYMOVE
# define mremap(old_address,old_size,new_size,flags,new_address) (errno = ENOSYS, (void *)-1)
#endif

#define FOREIGN_MAGIC PERL_MAGIC_ext

static int ecb_cold
mmap_free (pTHX_ SV *sv, MAGIC *mg)
{
  int old_errno = errno;
  munmap (mg->mg_ptr, (size_t)mg->mg_obj);
  errno = old_errno;

  mg->mg_obj = 0; /* just in case */

  SvREADONLY_off (sv);

  if (SvPVX (sv) != mg->mg_ptr)
    croak ("ERROR: IO::AIO::mmap-mapped scalar changed location, detected");

  SvCUR_set (sv, 0);
  SvPVX (sv) = 0;
  SvOK_off (sv);

  return 0;
}

static MGVTBL mmap_vtbl = {
  0, 0, 0, 0, mmap_free
};

static int ecb_cold
sysfree_free (pTHX_ SV *sv, MAGIC *mg)
{
  free (mg->mg_ptr);
  mg->mg_obj = 0; /* just in case */

  SvREADONLY_off (sv);

  if (SvPVX (sv) != mg->mg_ptr)
    croak ("ERROR: IO::AIO mapped scalar changed location, detected");

  SvCUR_set (sv, 0);
  SvPVX (sv) = 0;
  SvOK_off (sv);

  return 0;
}

static MGVTBL sysfree_vtbl = {
  0, 0, 0, 0, sysfree_free
};

/*****************************************************************************/

/* helper: set scalar to foreign ptr with custom free */
ecb_noinline
static void
sv_set_foreign (SV *sv, const MGVTBL *const vtbl, void *addr, IV length)
{
  sv_force_normal (sv);

  /* we store the length in mg_obj, as namlen is I32 :/ */
  sv_magicext (sv, 0, FOREIGN_MAGIC, vtbl, (char *)addr, 0)
    ->mg_obj = (SV *)length;

  SvUPGRADE (sv, SVt_PV); /* nop... */

  if (SvLEN (sv))
    Safefree (SvPVX (sv));

  SvPVX (sv) = (char *)addr;
  SvCUR_set (sv, length);
  SvLEN_set (sv, 0);
  SvPOK_only (sv);
}

static void
sv_clear_foreign (SV *sv)
{
  /* todo: iterate over magic and only free ours, but of course */
  /* the perl5porters will call that (correct) behaviour buggy */
  sv_unmagic (sv, FOREIGN_MAGIC);
}

/*****************************************************************************/

/* defines all sorts of constants to 0 unless they are already defined */
/* also provides const_iv_ and const_niv_ macros for them */
#include "def0.h"

/*****************************************************************************/

static void
fiemap (eio_req *req)
{
  req->result = -1;

#if HAVE_FIEMAP
  /* assume some c99 */
  struct fiemap *fiemap = 0;
  size_t end_offset;
  int count = req->int3;

  req->flags |= EIO_FLAG_PTR1_FREE;

  /* heuristic: start with 512 bytes (8 extents), and if that isn't enough, */
  /* increase in fixed steps */
  if (count < 0)
    count = 8;

  fiemap = malloc (sizeof (*fiemap) + sizeof (struct fiemap_extent) * count);
  errno = ENOMEM;
  if (!fiemap)
    return;

  req->ptr1 = fiemap;

  fiemap->fm_start        = req->offs;
  fiemap->fm_length       = req->size;
  fiemap->fm_flags        = req->int2;
  fiemap->fm_extent_count = count;

  if (ioctl (req->int1, FS_IOC_FIEMAP, fiemap) < 0)
    return;

  if (req->int3 >= 0 /* not autosizing */
      || !fiemap->fm_mapped_extents /* no more extents */
      || fiemap->fm_extents [fiemap->fm_mapped_extents - 1].fe_flags & FIEMAP_EXTENT_LAST /* hit eof */)
    goto done;

  /* else we have to loop -
   * it would be tempting (actually I tried that first) to just query the
   * number of extents needed, but linux often feels like not returning all
   * extents, without telling us it left any out. this complicates
   * this quite a bit.
   */

  end_offset = fiemap->fm_length + (fiemap->fm_length == FIEMAP_MAX_OFFSET ? 0 : fiemap->fm_start);

  for (;;)
    {
      /* we go in 54 extent steps - 3kb, in the hope that this fits nicely on the eio stack (normally 16+ kb) */
      char scratch[3072];
      struct fiemap *incmap = (struct fiemap *)scratch;

      incmap->fm_start        = fiemap->fm_extents [fiemap->fm_mapped_extents - 1].fe_logical
                                + fiemap->fm_extents [fiemap->fm_mapped_extents - 1].fe_length;
      incmap->fm_length       = fiemap->fm_length - (incmap->fm_start - fiemap->fm_start);
      incmap->fm_flags        = fiemap->fm_flags;
      incmap->fm_extent_count = (sizeof (scratch) - sizeof (struct fiemap)) / sizeof (struct fiemap_extent);

      if (ioctl (req->int1, FS_IOC_FIEMAP, incmap) < 0)
        return;

      if (!incmap->fm_mapped_extents)
        goto done;

      count = fiemap->fm_mapped_extents + incmap->fm_mapped_extents;
      fiemap = realloc (fiemap, sizeof (*fiemap) + sizeof (struct fiemap_extent) * count);
      errno = ENOMEM;
      if (!fiemap)
        return;

      req->ptr1 = fiemap;

      for (count = 0; count < incmap->fm_mapped_extents; ++count)
        {
          struct fiemap_extent *e = incmap->fm_extents + count;

          fiemap->fm_extents [fiemap->fm_mapped_extents++] = *e;

          if (e->fe_logical >= end_offset)
            goto done;

          if (e->fe_flags & FIEMAP_EXTENT_LAST)
            goto done;

        }
    }

done:
  req->result = 0;

#else
  errno = ENOSYS;
#endif
}

/*****************************************************************************/

static int close_fd; /* dummy fd to close fds via dup2 */

#if HAVE_STATX
static struct statx stx;
#define statx_offsetof(member) offsetof (struct statx, member)
#define eio__statx statx
#else
#define statx_offsetof(member) 0
#define eio__statx(dir,path,flags,mask,stx) EIO_ENOSYS()
#endif

enum {
  FLAG_SV2_RO_OFF = 0x40, /* data was set readonly */
};

typedef eio_req *aio_req;
typedef eio_req *aio_req_ornot;
typedef eio_wd   aio_wd;

static SV *on_next_submit;
static int next_pri = EIO_PRI_DEFAULT;
static int max_outstanding;

static s_epipe respipe;

static void req_destroy (aio_req req);
static void req_cancel (aio_req req);

static void
want_poll (void)
{
  /* write a dummy byte to the pipe so fh becomes ready */
  s_epipe_signal (&respipe);
}

static void
done_poll (void)
{
  /* read any signals sent by the worker threads */
  s_epipe_drain (&respipe);
}

/* must be called at most once */
ecb_noinline
static SV *
req_sv (aio_req req, HV *stash)
{
  if (!req->self)
    {
      req->self = (SV *)newHV ();
      sv_magic (req->self, 0, PERL_MAGIC_ext, (char *)req, 0);
    }

  return sv_2mortal (sv_bless (newRV_inc (req->self), stash));
}

static SV *
newSVaio_wd (aio_wd wd)
{
  return sv_bless (newRV_noinc (newSViv ((intptr_t)wd)), aio_wd_stash);
}

ecb_noinline
static aio_req
SvAIO_REQ (SV *sv)
{
  MAGIC *mg;

  if (!SvROK (sv)
      /* for speed reasons, we do not verify that SvROK actually has a stash ptr */
      || (SvSTASH (SvRV (sv)) != aio_grp_stash
          && SvSTASH (SvRV (sv)) != aio_req_stash
          && !sv_derived_from (sv, "IO::AIO::REQ")))
    croak ("object of class IO::AIO::REQ expected");

  mg = mg_find (SvRV (sv), PERL_MAGIC_ext);

  return mg ? (aio_req)mg->mg_ptr : 0;
}

static aio_wd
SvAIO_WD (SV *sv)
{
  if (!SvROK (sv)
      || SvTYPE (SvRV (sv)) != SVt_PVMG
      || SvSTASH (SvRV (sv)) != aio_wd_stash)
    croak ("IO::AIO: expected a working directory object as returned by aio_wd");

  return (aio_wd)(long)SvIVX (SvRV (sv));
}

static SV *
newmortalFH (int fd, int flags)
{
  if (fd < 0)
    return &PL_sv_undef;

  GV *gv = (GV *)sv_newmortal ();
  char sym[64];
  int symlen;
  
  symlen = snprintf (sym, sizeof (sym), "fd#%d", fd);
  gv_init (gv, aio_stash, sym, symlen, 0);

  symlen = snprintf (
     sym,
     sizeof (sym),
     "%s&=%d",
     flags == O_RDONLY ? "<" : flags == O_WRONLY ? ">" : "+<",
     fd
  );

  return do_open (gv, sym, symlen, 0, 0, 0, 0)
         ? (SV *)gv : &PL_sv_undef;
}

static void
aio_grp_feed (aio_req grp)
{
  if (grp->sv2 && SvOK (grp->sv2))
    {
      dSP;

      ENTER;
      SAVETMPS;
      PUSHMARK (SP);
      XPUSHs (req_sv (grp, aio_grp_stash));
      PUTBACK;
      call_sv (grp->sv2, G_VOID | G_EVAL | G_KEEPERR);
      SPAGAIN;
      FREETMPS;
      LEAVE;
    }
}

ecb_noinline
static void
req_submit (eio_req *req)
{
  eio_submit (req);

  if (expect_false (on_next_submit))
    {
      dSP;
      SV *cb = sv_2mortal (on_next_submit);

      on_next_submit = 0;

      PUSHMARK (SP);
      PUTBACK;
      call_sv (cb, G_DISCARD | G_EVAL);
    }
}

static int
req_invoke (eio_req *req)
{
  if (req->flags & FLAG_SV2_RO_OFF)
    SvREADONLY_off (req->sv2);

  if (!EIO_CANCELLED (req) && req->callback)
    {
      dSP;
      static SV *sv_result_cache; /* caches the result integer SV */
      SV *sv_result;

      ENTER;
      SAVETMPS;
      PUSHMARK (SP);
      EXTEND (SP, 1);

      /* do not recreate the result IV from scratch each time */
      if (expect_true (sv_result_cache))
        {
          sv_result = sv_result_cache; sv_result_cache = 0;
          SvIV_set (sv_result, req->result);
          SvIOK_only (sv_result);
        }
      else
        {
          sv_result = newSViv (req->result);
          SvREADONLY_on (sv_result);
        }

      switch (req->type)
        {
          case EIO_WD_OPEN:
            PUSHs (req->result ? &PL_sv_undef : sv_2mortal (newSVaio_wd (req->wd)));
            break;

          case EIO_READDIR:
            {
              SV *rv = &PL_sv_undef;

              if (req->result >= 0)
                {
                  int i;
                  char *names = (char *)req->ptr2;
                  eio_dirent *ent = (eio_dirent *)req->ptr1; /* might be 0 */
                  AV *av = newAV ();

                  av_extend (av, req->result - 1);

                  for (i = 0; i < req->result; ++i)
                    {
                      if (req->int1 & EIO_READDIR_DENTS)
                        {
                          SV *namesv = newSVpvn (names + ent->nameofs, ent->namelen);

                          if (req->int1 & EIO_READDIR_CUSTOM2)
                            {
                              static SV *sv_type [EIO_DT_MAX + 1]; /* type sv cache */
                              AV *avent = newAV ();

                              av_extend (avent, 2);

                              if (!sv_type [ent->type])
                                {
                                  sv_type [ent->type] = newSViv (ent->type);
                                  SvREADONLY_on (sv_type [ent->type]);
                                }

                              av_store (avent, 0, namesv);
                              av_store (avent, 1, SvREFCNT_inc (sv_type [ent->type]));
                              av_store (avent, 2, IVSIZE >= 8 ? newSVuv (ent->inode) : newSVnv (ent->inode));

                              av_store (av, i, newRV_noinc ((SV *)avent));
                            }
                          else
                            av_store (av, i, namesv);

                          ++ent;
                        }
                      else
                        {
                          SV *name = newSVpv (names, 0);
                          av_store (av, i, name);
                          names += SvCUR (name) + 1;
                        }
                    }

                  rv = sv_2mortal (newRV_noinc ((SV *)av));
                }

              PUSHs (rv);

              if (req->int1 & EIO_READDIR_CUSTOM1)
                XPUSHs (sv_2mortal (newSViv (req->int1 & ~(EIO_READDIR_CUSTOM1 | EIO_READDIR_CUSTOM2))));
            }
            break;

          case EIO_OPEN:
            PUSHs (newmortalFH (req->result, req->int1 & (O_RDONLY | O_WRONLY | O_RDWR)));
            break;

          case EIO_STATVFS:
          case EIO_FSTATVFS:
            {
              SV *rv = &PL_sv_undef;
             
#ifndef _WIN32
              if (req->result >= 0)
                {
                  EIO_STRUCT_STATVFS *f = EIO_STATVFS_BUF (req);
                  HV *hv = newHV ();
                  /* POSIX requires fsid to be unsigned long, but AIX in its infinite wisdom
                   * chooses to make it a struct.
                   */
                  unsigned long fsid = 0;
                  memcpy (&fsid, &f->f_fsid, sizeof (unsigned long) < sizeof (f->f_fsid) ? sizeof (unsigned long) : sizeof (f->f_fsid));

                  rv = sv_2mortal (newRV_noinc ((SV *)hv));

                  hv_store (hv, "bsize"  , sizeof ("bsize"  ) - 1, newSVval64 (f->f_bsize  ), 0);
                  hv_store (hv, "frsize" , sizeof ("frsize" ) - 1, newSVval64 (f->f_frsize ), 0);
                  hv_store (hv, "blocks" , sizeof ("blocks" ) - 1, newSVval64 (f->f_blocks ), 0);
                  hv_store (hv, "bfree"  , sizeof ("bfree"  ) - 1, newSVval64 (f->f_bfree  ), 0);
                  hv_store (hv, "bavail" , sizeof ("bavail" ) - 1, newSVval64 (f->f_bavail ), 0);
                  hv_store (hv, "files"  , sizeof ("files"  ) - 1, newSVval64 (f->f_files  ), 0);
                  hv_store (hv, "ffree"  , sizeof ("ffree"  ) - 1, newSVval64 (f->f_ffree  ), 0);
                  hv_store (hv, "favail" , sizeof ("favail" ) - 1, newSVval64 (f->f_favail ), 0);
                  hv_store (hv, "fsid"   , sizeof ("fsid"   ) - 1, newSVval64 (fsid        ), 0);
                  hv_store (hv, "flag"   , sizeof ("flag"   ) - 1, newSVval64 (f->f_flag   ), 0);
                  hv_store (hv, "namemax", sizeof ("namemax") - 1, newSVval64 (f->f_namemax), 0);
                }
#endif

              PUSHs (rv);
            }

            break;

          case EIO_GROUP:
            req->int1 = 2; /* mark group as finished */

            if (req->sv1)
              {
                int i;
                AV *av = (AV *)req->sv1;

                EXTEND (SP, AvFILL (av) + 1);
                for (i = 0; i <= AvFILL (av); ++i)
                  PUSHs (*av_fetch (av, i, 0));
              }
            break;

          case EIO_NOP:
          case EIO_BUSY:
            break;

          case EIO_READLINK:
          case EIO_REALPATH:
            if (req->result > 0)
              PUSHs (sv_2mortal (newSVpvn (req->ptr2, req->result)));
            break;

          case EIO_STAT:
          case EIO_LSTAT:
          case EIO_FSTAT:
            PL_laststype = req->type == EIO_LSTAT ? OP_LSTAT : OP_STAT;

            if (!(PL_laststatval = req->result))
              /* if compilation fails here then perl's Stat_t is not struct _stati64 */
              PL_statcache = *(EIO_STRUCT_STAT *)(req->ptr2);

            PUSHs (sv_result);
            break;

          case EIO_SEEK:
            PUSHs (req->result ? sv_result : sv_2mortal (newSVval64 (req->offs)));
            break;

          case EIO_READ:
            {
              SvCUR_set (req->sv2, req->stroffset + (req->result > 0 ? req->result : 0));
              *SvEND (req->sv2) = 0;
              SvPOK_only (req->sv2);
              SvSETMAGIC (req->sv2);
              PUSHs (sv_result);
            }
            break;

          case EIO_SLURP:
            {
              if (req->result >= 0)
                {
                  /* if length was originally not known, we steal the malloc'ed memory */
                  if (req->flags & EIO_FLAG_PTR2_FREE)
                    {
                      req->flags &= ~EIO_FLAG_PTR2_FREE;
                      sv_set_foreign (req->sv2, &sysfree_vtbl, req->ptr2, req->result);
                    }
                  else
                    {
                      SvCUR_set (req->sv2, req->result);
                      *SvEND (req->sv2) = 0;
                      SvPOK_only (req->sv2);
                    }

                  SvSETMAGIC (req->sv2);
                }

              PUSHs (sv_result);
            }
            break;

          case EIO_CUSTOM:
            if (req->feed == fiemap)
              {
#if HAVE_FIEMAP
                if (!req->result)
                  {
                    struct fiemap *fiemap = (struct fiemap *)req->ptr1;

                    if (fiemap->fm_extent_count)
                      {
                        AV *av = newAV ();
                        int i;

                        while (fiemap->fm_mapped_extents)
                          {
                            struct fiemap_extent *extent = &fiemap->fm_extents [--fiemap->fm_mapped_extents];
                            AV *ext_av = newAV ();

                            av_store (ext_av, 3, newSVuv    (extent->fe_flags));
                            av_store (ext_av, 2, newSVval64 (extent->fe_length));
                            av_store (ext_av, 1, newSVval64 (extent->fe_physical));
                            av_store (ext_av, 0, newSVval64 (extent->fe_logical));

                            av_store (av, fiemap->fm_mapped_extents, newRV_noinc ((SV *)ext_av));
                          }

                        PUSHs (sv_2mortal (newRV_noinc ((SV *)av)));
                      }
                    else
                      {
                        SvIV_set (sv_result, fiemap->fm_mapped_extents);
                        PUSHs (sv_result);
                      }
                  }
#endif
              }
            else
              PUSHs (sv_result);
            break;

#if 0
          case EIO_CLOSE:
            PerlIOUnix_refcnt_dec (req->int1);
            break;
#endif

          case EIO_DUP2: /* EIO_DUP2 actually means aio_close(), so fudge result value */
            if (req->result > 0)
              SvIV_set (sv_result, 0);
            /* FALLTHROUGH */

          default:
            PUSHs (sv_result);
            break;
        }

      errno = req->errorno;

      PUTBACK;
      call_sv (req->callback, G_VOID | G_EVAL | G_DISCARD);
      SPAGAIN;

      if (expect_false (SvREFCNT (sv_result) != 1 || sv_result_cache))
        SvREFCNT_dec (sv_result);
      else
        sv_result_cache = sv_result;

      FREETMPS;
      LEAVE;

      PUTBACK;
    }

  return !!SvTRUE (ERRSV);
}

static void
req_destroy (aio_req req)
{
  if (req->self)
    {
      sv_unmagic (req->self, PERL_MAGIC_ext);
      SvREFCNT_dec (req->self);
    }

  SvREFCNT_dec (req->sv1);
  SvREFCNT_dec (req->sv2);
  SvREFCNT_dec (req->sv3);
  SvREFCNT_dec (req->sv4);
  SvREFCNT_dec (req->callback);

  free (req);
}

static void
req_cancel_subs (aio_req grp)
{
  if (grp->type != EIO_GROUP)
    return;

  SvREFCNT_dec (grp->sv2);
  grp->sv2 = 0;

  eio_grp_cancel (grp);
}

ecb_cold
static void
create_respipe (void)
{
  if (s_epipe_renew (&respipe))
    croak ("IO::AIO: unable to initialize result pipe");
}

static void
poll_wait (void)
{
  while (eio_nreqs ())
    {
      int size;

      X_LOCK   (EIO_POOL->reslock);
      size = EIO_POOL->res_queue.size;
      X_UNLOCK (EIO_POOL->reslock);

      if (size)
        return;

      etp_maybe_start_thread (EIO_POOL);

      s_epipe_wait (&respipe);
    }
}

static int
poll_cb (void)
{
  for (;;)
    {
      int res = eio_poll ();

      if (res > 0)
        croak (0);

      if (!max_outstanding || max_outstanding > eio_nreqs ())
        return res;

      poll_wait ();
    }
}

ecb_cold
static void
reinit (void)
{
  create_respipe ();

  if (eio_init (want_poll, done_poll) < 0)
    croak ("IO::AIO: unable to initialise eio library");
}

/*****************************************************************************/

static SV *
get_cb (SV *cb_sv)
{
  SvGETMAGIC (cb_sv);
  return SvOK (cb_sv) ? s_get_cv_croak (cb_sv) : 0;
}

ecb_noinline
static aio_req ecb_noinline
dreq (SV *callback)
{
  SV *cb_cv;
  aio_req req;
  int req_pri = next_pri;
  next_pri = EIO_PRI_DEFAULT;

  cb_cv = get_cb (callback);

  req = calloc (sizeof (*req), 1);
  if (!req)
    croak ("out of memory during eio_req allocation");

  req->callback = SvREFCNT_inc (cb_cv);
  req->pri = req_pri;

  return req;
}

#define dREQ							\
  aio_req req = dreq (callback);				\

#define REQ_SEND						\
  PUTBACK;							\
  req_submit (req);						\
  SPAGAIN;							\
								\
  if (GIMME_V != G_VOID)					\
    XPUSHs (req_sv (req, aio_req_stash));

/* *wdsv, *pathsv, *wd and *ptr must be 0-initialized */
ecb_inline
void
req_set_path (SV *path, SV **wdsv, SV **pathsv, eio_wd *wd, void **ptr)
{
  if (expect_false (SvROK (path)))
    {
      SV *rv = SvRV (path);
      SV *wdob;

      if (SvTYPE (rv) == SVt_PVAV && AvFILLp (rv) == 1)
        {
          path = AvARRAY (rv)[1];
          wdob = AvARRAY (rv)[0];

          if (SvOK (wdob))
            {
              *wd = SvAIO_WD (wdob);
              *wdsv = SvREFCNT_inc_NN (SvRV (wdob));
            }
          else
            *wd = EIO_INVALID_WD;
        }
      else if (SvTYPE (rv) == SVt_PVMG && SvSTASH (rv) == aio_wd_stash)
        {
          *wd = (aio_wd)(long)SvIVX (rv);
          *wdsv = SvREFCNT_inc_NN (rv);
          *ptr = ".";
          return; /* path set to "." */
        }
      else
        croak ("IO::AIO: pathname arguments must be specified as a string, an IO::AIO::WD object or a [IO::AIO::WD, path] pair");
    }

  *pathsv = newSVsv (path);
  *ptr = SvPVbyte_nolen (*pathsv);
}

ecb_noinline
static void
req_set_path1 (aio_req req, SV *path)
{
  req_set_path (path, &req->sv1, &req->sv3, &req->wd, &req->ptr1);
}

ecb_noinline
static void
req_set_fh_or_path (aio_req req, int type_path, int type_fh, SV *fh_or_path)
{
  SV *rv = SvROK (fh_or_path) ? SvRV (fh_or_path) : fh_or_path;

  switch (SvTYPE (rv))
    {
      case SVt_PVIO:
      case SVt_PVLV:
      case SVt_PVGV:
        req->type = type_fh;
        req->sv1  = newSVsv (fh_or_path);
        req->int1 = PerlIO_fileno (IoIFP (sv_2io (fh_or_path)));
        break;

      default:
        req->type = type_path;
        req_set_path1 (req, fh_or_path);
        break;
    }
}

/*****************************************************************************/

static void
ts_set (struct timespec *ts, NV value)
{
  ts->tv_sec  = value;
  ts->tv_nsec = (value - ts->tv_sec) * 1e9;
}

static NV
ts_get (const struct timespec *ts)
{
  return ts->tv_sec + ts->tv_nsec * 1e-9;
}

/*****************************************************************************/

XS(boot_IO__AIO) ecb_cold;

MODULE = IO::AIO                PACKAGE = IO::AIO

PROTOTYPES: ENABLE

BOOT:
{
  static const struct {
    const char *name;
    IV iv;
  } *civ, const_iv[] = {
#   define const_niv(name, value) { # name, (IV) value },
#   define const_iv(name) { # name, (IV) name },
#   define const_eio(name) { # name, (IV) EIO_ ## name },

    /* you have to re-run ./gendef0 after adding/removing any constants here */
    /* the first block can be undef if missing */
    const_iv (ENOSYS)
    const_iv (EXDEV)
    const_iv (EBADR)

    /* for lseek */
    const_iv (SEEK_DATA)
    const_iv (SEEK_HOLE)

    const_niv (FADV_NORMAL    , POSIX_FADV_NORMAL)
    const_niv (FADV_SEQUENTIAL, POSIX_FADV_SEQUENTIAL)
    const_niv (FADV_RANDOM    , POSIX_FADV_RANDOM)
    const_niv (FADV_NOREUSE   , POSIX_FADV_NOREUSE)
    const_niv (FADV_WILLNEED  , POSIX_FADV_WILLNEED)
    const_niv (FADV_DONTNEED  , POSIX_FADV_DONTNEED)

    const_niv (MADV_NORMAL    , POSIX_MADV_NORMAL)
    const_niv (MADV_SEQUENTIAL, POSIX_MADV_SEQUENTIAL)
    const_niv (MADV_RANDOM    , POSIX_MADV_RANDOM)
    const_niv (MADV_WILLNEED  , POSIX_MADV_WILLNEED)
    const_niv (MADV_DONTNEED  , POSIX_MADV_DONTNEED)

    /* the second block will be 0 when missing */
    const_iv (O_ACCMODE)

    const_iv (O_RDONLY)
    const_iv (O_WRONLY)
    const_iv (O_RDWR)
    const_iv (O_CREAT)
    const_iv (O_TRUNC)
    const_iv (O_EXCL)
    const_iv (O_APPEND)

    const_iv (O_ASYNC)
    const_iv (O_DIRECT)
    const_iv (O_NOATIME)

    const_iv (O_CLOEXEC)
    const_iv (O_NOCTTY)
    const_iv (O_NOFOLLOW)
    const_iv (O_NONBLOCK)
    const_iv (O_EXEC)
    const_iv (O_SEARCH)
    const_iv (O_DIRECTORY)
    const_iv (O_DSYNC)
    const_iv (O_RSYNC)
    const_iv (O_SYNC)
    const_iv (O_PATH)
    const_iv (O_TMPFILE)
    const_iv (O_TTY_INIT)

    const_iv (S_IFIFO)
    const_iv (S_IFCHR)
    const_iv (S_IFBLK)
    const_iv (S_IFLNK)
    const_iv (S_IFREG)
    const_iv (S_IFDIR)
    const_iv (S_IFWHT)
    const_iv (S_IFSOCK)
    const_iv (S_IFMT)

    const_iv (ST_RDONLY)
    const_iv (ST_NOSUID)
    const_iv (ST_NODEV)
    const_iv (ST_NOEXEC)
    const_iv (ST_SYNCHRONOUS)
    const_iv (ST_MANDLOCK)
    const_iv (ST_WRITE)
    const_iv (ST_APPEND)
    const_iv (ST_IMMUTABLE)
    const_iv (ST_NOATIME)
    const_iv (ST_NODIRATIME)
    const_iv (ST_RELATIME)

    const_iv (PROT_NONE)
    const_iv (PROT_EXEC)
    const_iv (PROT_READ)
    const_iv (PROT_WRITE)

    const_iv (MAP_PRIVATE)
    const_iv (MAP_SHARED)
    const_iv (MAP_FIXED)
    const_iv (MAP_ANONYMOUS)

    /* linuxish */
    const_iv (MAP_LOCKED)
    const_iv (MAP_NORESERVE)
    const_iv (MAP_POPULATE)
    const_iv (MAP_NONBLOCK)
    const_iv (MAP_GROWSDOWN)
    const_iv (MAP_32BIT)
    const_iv (MAP_HUGETLB)
    const_iv (MAP_STACK)

    const_iv (MREMAP_MAYMOVE)
    const_iv (MREMAP_FIXED)

    const_iv (MSG_CMSG_CLOEXEC)
    const_iv (SOCK_CLOEXEC)

    const_iv (F_DUPFD_CLOEXEC)

    const_iv (F_ADD_SEALS)
    const_iv (F_GET_SEALS)
    const_iv (F_SEAL_SEAL)
    const_iv (F_SEAL_SHRINK)
    const_iv (F_SEAL_GROW)
    const_iv (F_SEAL_WRITE)

    const_iv (F_OFD_GETLK)
    const_iv (F_OFD_SETLK)
    const_iv (F_OFD_GETLKW)

    const_iv (FIFREEZE)
    const_iv (FITHAW)
    const_iv (FITRIM)
    const_iv (FICLONE)
    const_iv (FICLONERANGE)
    const_iv (FIDEDUPERANGE)

    const_iv (FS_IOC_GETFLAGS)
    const_iv (FS_IOC_SETFLAGS)
    const_iv (FS_IOC_GETVERSION)
    const_iv (FS_IOC_SETVERSION)
    const_iv (FS_IOC_FIEMAP)
    const_iv (FS_IOC_FSGETXATTR)
    const_iv (FS_IOC_FSSETXATTR)
    const_iv (FS_IOC_SET_ENCRYPTION_POLICY)
    const_iv (FS_IOC_GET_ENCRYPTION_PWSALT)
    const_iv (FS_IOC_GET_ENCRYPTION_POLICY)

    const_iv (FS_KEY_DESCRIPTOR_SIZE)

    const_iv (FS_SECRM_FL)
    const_iv (FS_UNRM_FL)
    const_iv (FS_COMPR_FL)
    const_iv (FS_SYNC_FL)
    const_iv (FS_IMMUTABLE_FL)
    const_iv (FS_APPEND_FL)
    const_iv (FS_NODUMP_FL)
    const_iv (FS_NOATIME_FL)
    const_iv (FS_DIRTY_FL)
    const_iv (FS_COMPRBLK_FL)
    const_iv (FS_NOCOMP_FL)
    const_iv (FS_ENCRYPT_FL)
    const_iv (FS_BTREE_FL)
    const_iv (FS_INDEX_FL)
    const_iv (FS_JOURNAL_DATA_FL)
    const_iv (FS_NOTAIL_FL)
    const_iv (FS_DIRSYNC_FL)
    const_iv (FS_TOPDIR_FL)
    const_iv (FS_FL_USER_MODIFIABLE)

    const_iv (FS_XFLAG_REALTIME)
    const_iv (FS_XFLAG_PREALLOC)
    const_iv (FS_XFLAG_IMMUTABLE)
    const_iv (FS_XFLAG_APPEND)
    const_iv (FS_XFLAG_SYNC)
    const_iv (FS_XFLAG_NOATIME)
    const_iv (FS_XFLAG_NODUMP)
    const_iv (FS_XFLAG_RTINHERIT)
    const_iv (FS_XFLAG_PROJINHERIT)
    const_iv (FS_XFLAG_NOSYMLINKS)
    const_iv (FS_XFLAG_EXTSIZE)
    const_iv (FS_XFLAG_EXTSZINHERIT)
    const_iv (FS_XFLAG_NODEFRAG)
    const_iv (FS_XFLAG_FILESTREAM)
    const_iv (FS_XFLAG_DAX)
    const_iv (FS_XFLAG_HASATTR)

    const_iv (FIEMAP_FLAG_SYNC)
    const_iv (FIEMAP_FLAG_XATTR)
    const_iv (FIEMAP_FLAGS_COMPAT)
    const_iv (FIEMAP_EXTENT_LAST)
    const_iv (FIEMAP_EXTENT_UNKNOWN)
    const_iv (FIEMAP_EXTENT_DELALLOC)
    const_iv (FIEMAP_EXTENT_ENCODED)
    const_iv (FIEMAP_EXTENT_DATA_ENCRYPTED)
    const_iv (FIEMAP_EXTENT_NOT_ALIGNED)
    const_iv (FIEMAP_EXTENT_DATA_INLINE)
    const_iv (FIEMAP_EXTENT_DATA_TAIL)
    const_iv (FIEMAP_EXTENT_UNWRITTEN)
    const_iv (FIEMAP_EXTENT_MERGED)
    const_iv (FIEMAP_EXTENT_SHARED)

    const_iv (SPLICE_F_MOVE)
    const_iv (SPLICE_F_NONBLOCK)
    const_iv (SPLICE_F_MORE)
    const_iv (SPLICE_F_GIFT)

    const_iv (EFD_CLOEXEC)
    const_iv (EFD_NONBLOCK)
    const_iv (EFD_SEMAPHORE)

    const_iv (MFD_CLOEXEC)
    const_iv (MFD_ALLOW_SEALING)
    const_iv (MFD_HUGETLB)

    const_iv (CLOCK_REALTIME)
    const_iv (CLOCK_MONOTONIC)
    const_iv (CLOCK_BOOTTIME)
    const_iv (CLOCK_REALTIME_ALARM)
    const_iv (CLOCK_BOOTTIME_ALARM)

    const_iv (TFD_NONBLOCK)
    const_iv (TFD_CLOEXEC)

    const_iv (TFD_TIMER_ABSTIME)
    const_iv (TFD_TIMER_CANCEL_ON_SET)

    const_iv (STATX_TYPE)
    const_iv (STATX_MODE)
    const_iv (STATX_NLINK)
    const_iv (STATX_UID)
    const_iv (STATX_GID)
    const_iv (STATX_ATIME)
    const_iv (STATX_MTIME)
    const_iv (STATX_CTIME)
    const_iv (STATX_INO)
    const_iv (STATX_SIZE)
    const_iv (STATX_BLOCKS)
    const_iv (STATX_BASIC_STATS)
    const_iv (STATX_ALL)
    const_iv (STATX_BTIME)
    const_iv (STATX_ATTR_COMPRESSED)
    const_iv (STATX_ATTR_IMMUTABLE)
    const_iv (STATX_ATTR_APPEND)
    const_iv (STATX_ATTR_NODUMP)
    const_iv (STATX_ATTR_ENCRYPTED)
    const_iv (STATX_ATTR_AUTOMOUNT)

    const_iv (AT_FDCWD)
    const_iv (AT_SYMLINK_NOFOLLOW)
    const_iv (AT_EACCESS)
    const_iv (AT_REMOVEDIR)
    const_iv (AT_SYMLINK_FOLLOW)
    const_iv (AT_NO_AUTOMOUNT)
    const_iv (AT_EMPTY_PATH)
    const_iv (AT_STATX_SYNC_TYPE)
    const_iv (AT_STATX_AS_STAT)
    const_iv (AT_STATX_FORCE_SYNC)
    const_iv (AT_STATX_DONT_SYNC)
    const_iv (AT_RECURSIVE)

    const_iv (OPEN_TREE_CLONE)

    const_iv (FSOPEN_CLOEXEC)

    const_iv (FSPICK_CLOEXEC)
    const_iv (FSPICK_SYMLINK_NOFOLLOW)
    const_iv (FSPICK_NO_AUTOMOUNT)
    const_iv (FSPICK_EMPTY_PATH)

    const_iv (MOVE_MOUNT_F_SYMLINKS)
    const_iv (MOVE_MOUNT_F_AUTOMOUNTS)
    const_iv (MOVE_MOUNT_F_EMPTY_PATH)
    const_iv (MOVE_MOUNT_T_SYMLINKS)
    const_iv (MOVE_MOUNT_T_AUTOMOUNTS)
    const_iv (MOVE_MOUNT_T_EMPTY_PATH)

    /* waitid */
    const_iv (P_PID)
    const_iv (P_PIDFD)
    const_iv (P_PGID)
    const_iv (P_ALL)

    const_iv (FSCONFIG_SET_FLAG)
    const_iv (FSCONFIG_SET_STRING)
    const_iv (FSCONFIG_SET_BINARY)
    const_iv (FSCONFIG_SET_PATH)
    const_iv (FSCONFIG_SET_PATH_EMPTY)
    const_iv (FSCONFIG_SET_FD)
    const_iv (FSCONFIG_CMD_CREATE)
    const_iv (FSCONFIG_CMD_RECONFIGURE)

    const_iv (MOUNT_ATTR_RDONLY)
    const_iv (MOUNT_ATTR_NOSUID)
    const_iv (MOUNT_ATTR_NODEV)
    const_iv (MOUNT_ATTR_NOEXEC)
    const_iv (MOUNT_ATTR__ATIME)
    const_iv (MOUNT_ATTR_RELATIME)
    const_iv (MOUNT_ATTR_NOATIME)
    const_iv (MOUNT_ATTR_STRICTATIME)
    const_iv (MOUNT_ATTR_NODIRATIME)

    /* these are libeio constants, and are independent of gendef0 */
    const_eio (SEEK_SET)
    const_eio (SEEK_CUR)
    const_eio (SEEK_END)

    const_eio (MCL_FUTURE)
    const_eio (MCL_CURRENT)
    const_eio (MCL_ONFAULT)

    const_eio (MS_ASYNC)
    const_eio (MS_INVALIDATE)
    const_eio (MS_SYNC)

    const_eio (MT_MODIFY)

    const_eio (SYNC_FILE_RANGE_WAIT_BEFORE)
    const_eio (SYNC_FILE_RANGE_WRITE)
    const_eio (SYNC_FILE_RANGE_WAIT_AFTER)

    const_eio (FALLOC_FL_KEEP_SIZE)
    const_eio (FALLOC_FL_PUNCH_HOLE)
    const_eio (FALLOC_FL_COLLAPSE_RANGE)
    const_eio (FALLOC_FL_ZERO_RANGE)
    const_eio (FALLOC_FL_INSERT_RANGE)
    const_eio (FALLOC_FL_UNSHARE_RANGE)

    const_eio (RENAME_NOREPLACE)
    const_eio (RENAME_EXCHANGE)
    const_eio (RENAME_WHITEOUT)

    const_eio (READDIR_DENTS)
    const_eio (READDIR_DIRS_FIRST)
    const_eio (READDIR_STAT_ORDER)
    const_eio (READDIR_FOUND_UNKNOWN)

    const_eio (DT_UNKNOWN)
    const_eio (DT_FIFO)
    const_eio (DT_CHR)
    const_eio (DT_DIR)
    const_eio (DT_BLK)
    const_eio (DT_REG)
    const_eio (DT_LNK)
    const_eio (DT_SOCK)
    const_eio (DT_WHT)
  };

  aio_stash     = gv_stashpv ("IO::AIO"     , 1);
  aio_req_stash = gv_stashpv ("IO::AIO::REQ", 1);
  aio_grp_stash = gv_stashpv ("IO::AIO::GRP", 1);
  aio_wd_stash  = gv_stashpv ("IO::AIO::WD" , 1);

  for (civ = const_iv + sizeof (const_iv) / sizeof (const_iv [0]); civ > const_iv; civ--)
    newCONSTSUB (aio_stash, (char *)civ[-1].name, newSViv (civ[-1].iv));

  newCONSTSUB (aio_stash, "PAGESIZE", newSViv (PAGESIZE));

  /* allocate dummy pipe fd for aio_close */
  {
    int pipefd [2];

    if (
#ifdef _WIN32
      _pipe (pipefd, 1, _O_BINARY) < 0
#else
      pipe (pipefd) < 0
      || fcntl (pipefd [0], F_SETFD, FD_CLOEXEC) < 0
#endif
      || close (pipefd [1]) < 0
    )
      croak ("IO::AIO: unable to create dummy pipe for aio_close");

    close_fd = pipefd [0];
  }

  reinit ();
}

void
reinit ()
	PROTOTYPE:

void
max_poll_reqs (unsigned int nreqs)
	PROTOTYPE: $
        CODE:
        eio_set_max_poll_reqs (nreqs);

void
max_poll_time (double nseconds)
	PROTOTYPE: $
        CODE:
        eio_set_max_poll_time (nseconds);

void
min_parallel (unsigned int nthreads)
	PROTOTYPE: $
        CODE:
        eio_set_min_parallel (nthreads);

void
max_parallel (unsigned int nthreads)
	PROTOTYPE: $
        CODE:
        eio_set_max_parallel (nthreads);

void
max_idle (unsigned int nthreads)
	PROTOTYPE: $
        CODE:
        eio_set_max_idle (nthreads);

void
idle_timeout (unsigned int seconds)
	PROTOTYPE: $
        CODE:
        eio_set_idle_timeout (seconds);

void
max_outstanding (unsigned int maxreqs)
	PROTOTYPE: $
        CODE:
        max_outstanding = maxreqs;

void
aio_wd (SV8 *pathname, SV *callback = &PL_sv_undef)
	PPCODE:
{
        dREQ;

        req->type = EIO_WD_OPEN;
        req_set_path1 (req, pathname);

        REQ_SEND;
}

void
aio_open (SV8 *pathname, int flags, int mode, SV *callback = &PL_sv_undef)
	PPCODE:
{
        dREQ;

        req->type = EIO_OPEN;
        req_set_path1 (req, pathname);
        req->int1 = flags;
        req->int2 = mode;

        REQ_SEND;
}

void
aio_fsync (SV *fh, SV *callback = &PL_sv_undef)
        ALIAS:
           aio_fsync     = EIO_FSYNC
           aio_fdatasync = EIO_FDATASYNC
           aio_syncfs    = EIO_SYNCFS
	PPCODE:
{
	int fd = s_fileno_croak (fh, 0);
        dREQ;

        req->type = ix;
        req->sv1  = newSVsv (fh);
        req->int1 = fd;

        REQ_SEND;
}

void
aio_sync_file_range (SV *fh, off_t offset, size_t nbytes, UV flags, SV *callback = &PL_sv_undef)
	PPCODE:
{
	int fd = s_fileno_croak (fh, 0);
        dREQ;

        req->type = EIO_SYNC_FILE_RANGE;
        req->sv1  = newSVsv (fh);
        req->int1 = fd;
        req->offs = offset;
        req->size = nbytes;
        req->int2 = flags;

        REQ_SEND;
}

void
aio_allocate (SV *fh, int mode, off_t offset, size_t len, SV *callback = &PL_sv_undef)
	PPCODE:
{
	int fd = s_fileno_croak (fh, 0);
        dREQ;

        req->type = EIO_FALLOCATE;
        req->sv1  = newSVsv (fh);
        req->int1 = fd;
        req->int2 = mode;
        req->offs = offset;
        req->size = len;

        REQ_SEND;
}

void
aio_close (SV *fh, SV *callback = &PL_sv_undef)
	PPCODE:
{
	int fd = s_fileno_croak (fh, 0);
        dREQ;
#if 0
        /* partially duplicate logic in s_fileno */
	SvGETMAGIC (fh);

	if (SvROK (fh))
	  {
	    fh = SvRV (fh);
	    SvGETMAGIC (fh);
	  }

        if (SvTYPE (fh) == SVt_PVGV)
          {
            /* perl filehandle */
            PerlIOUnix_refcnt_inc (fd);
            do_close ((GV *)fh, 1);

            req->type = EIO_CLOSE;
            req->int1 = fd;
            /*req->sv2  = newSVsv (fh);*/ /* since we stole the fd, no need to keep the fh */
          }
        else
#endif
          {
            /* fd number */
            req->type = EIO_DUP2;
            req->int1 = close_fd;
            req->sv2  = newSVsv (fh);
            req->int2 = fd;
          }

        REQ_SEND;
}

void
aio_seek (SV *fh, SV *offset, int whence, SV *callback = &PL_sv_undef)
        PPCODE:
{
        int fd = s_fileno_croak (fh, 0);
        dREQ;

        req->type = EIO_SEEK;
        req->sv1  = newSVsv (fh);
        req->int1 = fd;
        req->offs = SvVAL64 (offset);
        req->int2 = whence;

        REQ_SEND;
}

void
aio_read (SV *fh, SV *offset, SV *length, SV8 *data, IV dataoffset, SV *callback = &PL_sv_undef)
        ALIAS:
           aio_read  = EIO_READ
           aio_write = EIO_WRITE
        PPCODE:
{
        STRLEN svlen;
        int fd = s_fileno_croak (fh, ix == EIO_WRITE);
        char *svptr = SvPVbyte (data, svlen);
        UV len = SvUV (length);

        if (dataoffset < 0)
          dataoffset += svlen;

        if (dataoffset < 0 || dataoffset > svlen)
          croak ("dataoffset outside of data scalar");

        if (ix == EIO_WRITE)
          {
            /* write: check length and adjust. */
            if (!SvOK (length) || len + dataoffset > svlen)
              len = svlen - dataoffset;
          }
        else
          {
            /* read: check type and grow scalar as necessary */
            if (!SvPOK (data) || SvLEN (data) >= SvCUR (data))
              svptr = sv_grow (data, len + dataoffset + 1);
            else if (SvCUR (data) < len + dataoffset)
              croak ("length + dataoffset outside of scalar, and cannot grow");
          }

        {
          dREQ;

          req->type = ix;
          req->sv1  = newSVsv (fh);
          req->int1 = fd;
          req->offs = SvOK (offset) ? SvVAL64 (offset) : -1;
          req->size = len;
          req->sv2  = SvREFCNT_inc (data);
          req->ptr2 = (char *)svptr + dataoffset;
          req->stroffset = dataoffset;

          if (!SvREADONLY (data))
            {
              SvREADONLY_on (data);
              req->flags |= FLAG_SV2_RO_OFF;
            }

          REQ_SEND;
        }
}

void
aio_ioctl (SV *fh, unsigned long request, SV8 *arg, SV *callback = &PL_sv_undef)
        ALIAS:
           aio_ioctl = EIO_IOCTL
           aio_fcntl = EIO_FCNTL
        PPCODE:
{
        int fd = s_fileno_croak (fh, 0);
        char *svptr;

        if (SvPOK (arg) || !SvNIOK (arg))
          {
            STRLEN svlen;
            /* perl uses IOCPARM_LEN for fcntl, so we do, too */
#ifdef IOCPARM_LEN
            STRLEN need = IOCPARM_LEN (request);
#else
            STRLEN need = 256;
#endif

            if (svlen < need)
              svptr = SvGROW (arg, need);
          }
        else
          svptr = (char *)SvIV (arg);

        {
          dREQ;

          req->type = ix;
          req->sv1  = newSVsv (fh);
          req->int1 = fd;
          req->int2 = (long)request;
          req->sv2  = SvREFCNT_inc (arg);
          req->ptr2 = svptr;

          REQ_SEND;
        }
}

void
aio_readlink (SV8 *pathname, SV *callback = &PL_sv_undef)
        ALIAS:
           aio_readlink = EIO_READLINK
           aio_realpath = EIO_REALPATH
        PPCODE:
{
        dREQ;

        req->type = ix;
        req_set_path1 (req, pathname);

        REQ_SEND;
}

void
aio_sendfile (SV *out_fh, SV *in_fh, off_t in_offset, size_t length, SV *callback = &PL_sv_undef)
        PPCODE:
{
	int ifd = s_fileno_croak (in_fh , 0);
	int ofd = s_fileno_croak (out_fh, 1);
	dREQ;

        req->type = EIO_SENDFILE;
        req->sv1  = newSVsv (out_fh);
        req->int1 = ofd;
        req->sv2  = newSVsv (in_fh);
        req->int2 = ifd;
        req->offs = in_offset;
        req->size = length;

        REQ_SEND;
}

void
aio_readahead (SV *fh, off_t offset, size_t length, SV *callback = &PL_sv_undef)
        PPCODE:
{
	int fd = s_fileno_croak (fh, 0);
	dREQ;

        req->type = EIO_READAHEAD;
        req->sv1  = newSVsv (fh);
        req->int1 = fd;
        req->offs = offset;
        req->size = length;

        REQ_SEND;
}

void
aio_stat (SV8 *fh_or_path, SV *callback = &PL_sv_undef)
        ALIAS:
           aio_stat    = EIO_STAT
           aio_lstat   = EIO_LSTAT
           aio_statvfs = EIO_STATVFS
	PPCODE:
{
	dREQ;

        req_set_fh_or_path (req, ix, ix == EIO_STATVFS ? EIO_FSTATVFS : EIO_FSTAT, fh_or_path);

        REQ_SEND;
}

void
st_xtime ()
	ALIAS:
           st_atime = 0x01
           st_mtime = 0x02
           st_ctime = 0x04
           st_btime = 0x08
           st_xtime = 0x0f
	PPCODE:
        EXTEND (SP, 4);
        if (ix & 0x01) PUSHs (newSVnv (PL_statcache.st_atime + 1e-9 * ATIMENSEC));
        if (ix & 0x02) PUSHs (newSVnv (PL_statcache.st_mtime + 1e-9 * MTIMENSEC));
        if (ix & 0x04) PUSHs (newSVnv (PL_statcache.st_ctime + 1e-9 * CTIMENSEC));
        if (ix & 0x08) PUSHs (newSVnv (BTIMESEC              + 1e-9 * BTIMENSEC));

void
st_xtimensec ()
	ALIAS:
           st_atimensec = 0x01
           st_mtimensec = 0x02
           st_ctimensec = 0x04
           st_btimensec = 0x08
           st_xtimensec = 0x0f
           st_btimesec  = 0x10
           st_gen       = 0x20
	PPCODE:
        EXTEND (SP, 4);
        if (ix & 0x01) PUSHs (newSViv (ATIMENSEC));
        if (ix & 0x02) PUSHs (newSViv (MTIMENSEC));
        if (ix & 0x04) PUSHs (newSViv (CTIMENSEC));
        if (ix & 0x08) PUSHs (newSViv (BTIMENSEC));
        if (ix & 0x10) PUSHs (newSVuv (BTIMESEC));
        if (ix & 0x20) PUSHs (newSVuv (ST_GEN));

UV
major (UV dev)
	ALIAS:
        minor = 1
	CODE:
        RETVAL = ix ? minor (dev) : major (dev);
	OUTPUT:
        RETVAL

UV
makedev (UV maj, UV min)
	CODE:
        RETVAL = makedev (maj, min);
	OUTPUT:
        RETVAL

void
aio_utime (SV8 *fh_or_path, SV *atime, SV *mtime, SV *callback = &PL_sv_undef)
	PPCODE:
{
	dREQ;

        req->nv1 = SvOK (atime) ? SvNV (atime) : -1.;
        req->nv2 = SvOK (mtime) ? SvNV (mtime) : -1.;
        req_set_fh_or_path (req, EIO_UTIME, EIO_FUTIME, fh_or_path);

        REQ_SEND;
}

void
aio_truncate (SV8 *fh_or_path, SV *offset, SV *callback = &PL_sv_undef)
	PPCODE:
{
	dREQ;

        req->offs = SvOK (offset) ? SvVAL64 (offset) : -1;
        req_set_fh_or_path (req, EIO_TRUNCATE, EIO_FTRUNCATE, fh_or_path);

        REQ_SEND;
}

void
aio_chmod (SV8 *fh_or_path, int mode, SV *callback = &PL_sv_undef)
	PPCODE:
{
	dREQ;

        req->int2 = mode;
        req_set_fh_or_path (req, EIO_CHMOD, EIO_FCHMOD, fh_or_path);

        REQ_SEND;
}

void
aio_chown (SV8 *fh_or_path, SV *uid, SV *gid, SV *callback = &PL_sv_undef)
	PPCODE:
{
	dREQ;

        req->int2 = SvOK (uid) ? SvIV (uid) : -1;
        req->int3 = SvOK (gid) ? SvIV (gid) : -1;
        req_set_fh_or_path (req, EIO_CHOWN, EIO_FCHOWN, fh_or_path);

        REQ_SEND;
}

void
aio_readdirx (SV8 *pathname, IV flags, SV *callback = &PL_sv_undef)
	PPCODE:
{
	dREQ;
	
        req->type = EIO_READDIR;
        req->int1 = flags | EIO_READDIR_DENTS | EIO_READDIR_CUSTOM1;

        if (flags & EIO_READDIR_DENTS)
          req->int1 |= EIO_READDIR_CUSTOM2;

        req_set_path1 (req, pathname);

	REQ_SEND;
}

void
aio_mkdir (SV8 *pathname, int mode, SV *callback = &PL_sv_undef)
	PPCODE:
{
	dREQ;

        req->type = EIO_MKDIR;
        req->int2 = mode;
        req_set_path1 (req, pathname);

        REQ_SEND;
}

void
aio_unlink (SV8 *pathname, SV *callback = &PL_sv_undef)
        ALIAS:
           aio_unlink  = EIO_UNLINK
           aio_rmdir   = EIO_RMDIR
           aio_readdir = EIO_READDIR
	PPCODE:
{
	dREQ;
	
        req->type = ix;
        req_set_path1 (req, pathname);

	REQ_SEND;
}

void
aio_link (SV8 *oldpath, SV8 *newpath, SV *callback = &PL_sv_undef)
        ALIAS:
           aio_link    = EIO_LINK
           aio_symlink = EIO_SYMLINK
           aio_rename  = EIO_RENAME
	PPCODE:
{
        eio_wd wd2 = 0;
	dREQ;
	
        req->type = ix;
        req_set_path1 (req, oldpath);
        req_set_path (newpath, &req->sv2, &req->sv4, &wd2, &req->ptr2);
        req->int3 = (long)wd2;
	
	REQ_SEND;
}

void
aio_rename2 (SV8 *oldpath, SV8 *newpath, int flags = 0, SV *callback = &PL_sv_undef)
	PPCODE:
{
        eio_wd wd2 = 0;
	dREQ;
	
        req->type = EIO_RENAME;
        req_set_path1 (req, oldpath);
        req_set_path (newpath, &req->sv2, &req->sv4, &wd2, &req->ptr2);
        req->int2 = flags;
        req->int3 = (long)wd2;
	
	REQ_SEND;
}

void
aio_mknod (SV8 *pathname, int mode, UV dev, SV *callback = &PL_sv_undef)
	PPCODE:
{
	dREQ;
	
        req->type = EIO_MKNOD;
        req->int2 = (mode_t)mode;
        req->offs = dev;
        req_set_path1 (req, pathname);
	
	REQ_SEND;
}

void
aio_mtouch (SV8 *data, IV offset = 0, SV *length = &PL_sv_undef, int flags = -1, SV *callback = &PL_sv_undef)
        ALIAS:
           aio_mtouch = EIO_MTOUCH
           aio_msync  = EIO_MSYNC
        PPCODE:
{
        STRLEN svlen;
        char *svptr = SvPVbyte (data, svlen);
        UV len = SvUV (length);

        if (flags < 0)
          flags = ix == EIO_MSYNC ? EIO_MS_SYNC : 0;

        if (offset < 0)
          offset += svlen;

        if (offset < 0 || offset > svlen)
          croak ("offset outside of scalar");

        if (!SvOK (length) || len + offset > svlen)
          len = svlen - offset;

        {
          dREQ;

          req->type = ix;
          req->sv2  = SvREFCNT_inc (data);
          req->ptr2 = (char *)svptr + offset;
          req->size = len;
          req->int1 = flags;

          REQ_SEND;
        }
}

void
aio_mlock (SV8 *data, IV offset = 0, SV *length = &PL_sv_undef, SV *callback = &PL_sv_undef)
        PPCODE:
{
        STRLEN svlen;
        char *svptr = SvPVbyte (data, svlen);
        UV len = SvUV (length);

        if (offset < 0)
          offset += svlen;

        if (offset < 0 || offset > svlen)
          croak ("offset outside of scalar");

        if (!SvOK (length) || len + offset > svlen)
          len = svlen - offset;

        {
          dREQ;

          req->type = EIO_MLOCK;
          req->sv2  = SvREFCNT_inc (data);
          req->ptr2 = (char *)svptr + offset;
          req->size = len;

          REQ_SEND;
        }
}

void
aio_mlockall (IV flags, SV *callback = &PL_sv_undef)
        PPCODE:
{
        dREQ;

        req->type = EIO_MLOCKALL;
        req->int1 = flags;

        REQ_SEND;
}

void
aio_fiemap (SV *fh, off_t start, SV *length, U32 flags, SV *count, SV *callback = &PL_sv_undef)
        PPCODE:
{
	int fd = s_fileno_croak (fh, 0);
	dREQ;

        req->type = EIO_CUSTOM;
        req->sv1  = newSVsv (fh);
        req->int1 = fd;

        req->feed = fiemap;
#if HAVE_FIEMAP
        /* keep our fingers crossed that the next two types are 64 bit */
        req->offs = start;
        req->size = SvOK (length) ? SvVAL64 (length) : ~0ULL;
        req->int2 = flags;
        req->int3 = SvOK (count) ? SvIV (count) : -1;
#endif

	REQ_SEND;
}

void
aio_slurp (SV *pathname, off_t offset, UV length, SV8 *data, SV *callback = &PL_sv_undef)
        PPCODE:
{
        char *svptr = 0;

        sv_clear_foreign (data);

        if (length) /* known length, directly read into scalar */
          {
            if (!SvPOK (data) || SvLEN (data) >= SvCUR (data))
              svptr = sv_grow (data, length + 1);
            else if (SvCUR (data) < length)
              croak ("length outside of scalar, and cannot grow");
            else
              svptr = SvPVbyte_nolen (data);
          }

        {
          dREQ;

          req->type = EIO_SLURP;
          req_set_path1 (req, pathname);
          req->offs = offset;
          req->size = length;
          req->sv2  = SvREFCNT_inc (data);
          req->ptr2 = svptr;

          if (!SvREADONLY (data))
            {
              SvREADONLY_on (data);
              req->flags |= FLAG_SV2_RO_OFF;
            }

          REQ_SEND;
        }
}

void
aio_busy (double delay, SV *callback = &PL_sv_undef)
	PPCODE:
{
	dREQ;

        req->type = EIO_BUSY;
        req->nv1  = delay < 0. ? 0. : delay;

	REQ_SEND;
}

void
aio_group (SV *callback = &PL_sv_undef)
        PPCODE:
{
	dREQ;

        req->type = EIO_GROUP;

        PUTBACK;
        req_submit (req);
        SPAGAIN;

        XPUSHs (req_sv (req, aio_grp_stash));
}

void
aio_nop (SV *callback = &PL_sv_undef)
	ALIAS:
           aio_nop  = EIO_NOP
           aio_sync = EIO_SYNC
	PPCODE:
{
	dREQ;

        req->type = ix;

	REQ_SEND;
}

int
aioreq_pri (int pri = NO_INIT)
	CODE:
	RETVAL = next_pri;
	if (items > 0)
	  {
	    if (pri < EIO_PRI_MIN) pri = EIO_PRI_MIN;
	    if (pri > EIO_PRI_MAX) pri = EIO_PRI_MAX;
	    next_pri = pri;
	  }
	OUTPUT:
	RETVAL

void
aioreq_nice (int nice = 0)
	CODE:
	nice = next_pri - nice;
	if (nice < EIO_PRI_MIN) nice = EIO_PRI_MIN;
	if (nice > EIO_PRI_MAX) nice = EIO_PRI_MAX;
	next_pri = nice;

void
flush ()
	CODE:
        while (eio_nreqs ())
          {
            poll_wait ();
            poll_cb ();
          }

int
poll ()
	CODE:
        poll_wait ();
        RETVAL = poll_cb ();
	OUTPUT:
	RETVAL

int
poll_fileno ()
	CODE:
        RETVAL = s_epipe_fd (&respipe);
	OUTPUT:
	RETVAL

int
poll_cb (...)
	PROTOTYPE:
	CODE:
        RETVAL = poll_cb ();
	OUTPUT:
	RETVAL

void
poll_wait ()
	CODE:
        poll_wait ();

int
nreqs ()
	CODE:
        RETVAL = eio_nreqs ();
	OUTPUT:
	RETVAL

int
nready ()
	CODE:
        RETVAL = eio_nready ();
	OUTPUT:
	RETVAL

int
npending ()
	CODE:
        RETVAL = eio_npending ();
	OUTPUT:
	RETVAL

int
nthreads ()
	CODE:
        RETVAL = eio_nthreads ();
	OUTPUT:
	RETVAL

int
fadvise (aio_rfd fh, off_t offset, off_t length, IV advice)
        CODE:
        RETVAL = posix_fadvise (fh, offset, length, advice);
	OUTPUT:
        RETVAL

IV
sendfile (aio_wfd ofh, aio_rfd ifh, off_t offset, size_t count)
        CODE:
        RETVAL = eio_sendfile_sync (ofh, ifh, offset, count);
	OUTPUT:
        RETVAL

void
mmap (SV *scalar, STRLEN length, int prot, int flags, SV *fh = &PL_sv_undef, off_t offset = 0)
	PPCODE:
        sv_clear_foreign (scalar);
{
        int fd = SvOK (fh) ? s_fileno_croak (fh, flags & PROT_WRITE) : -1;
        void *addr = (void *)mmap (0, length, prot, flags, fd, offset);
	if (addr == (void *)-1)
	  XSRETURN_NO;

        sv_set_foreign (scalar, &mmap_vtbl, addr, length);

	if (!(prot & PROT_WRITE))
	  SvREADONLY_on (scalar);

        XSRETURN_YES;
}

void
munmap (SV *scalar)
	CODE:
        sv_clear_foreign (scalar);

SV *
mremap (SV *scalar, STRLEN new_length, int flags = MREMAP_MAYMOVE, IV new_address = 0)
	CODE:
{
        MAGIC *mg = mg_findext (scalar, FOREIGN_MAGIC, &mmap_vtbl);
        void *new;

        if (!mg || SvPVX (scalar) != mg->mg_ptr)
          croak ("IO::AIO::mremap: scalar not mapped by IO::AIO::mmap or improperly modified");

        new = mremap (mg->mg_ptr, (size_t)mg->mg_obj, new_length, flags, (void *)new_address);

        RETVAL = &PL_sv_no;

        if (new != (void *)-1)
          {
            RETVAL = new == (void *)mg->mg_ptr
              ? newSVpvn ("0 but true", 10)
              : &PL_sv_yes;

            mg->mg_ptr = (char *)new;
            mg->mg_obj = (SV *)new_length;

            SvPVX (scalar) = mg->mg_ptr;
            SvCUR_set (scalar, new_length);
          }
}
	OUTPUT:
        RETVAL

int
madvise (SV *scalar, IV offset = 0, SV *length = &PL_sv_undef, IV advice_or_prot)
	ALIAS:
        mprotect = 1
        CODE:
{
	STRLEN svlen;
	void *addr = SvPVbyte (scalar, svlen);
        STRLEN len = SvUV (length);

        if (offset < 0)
          offset += svlen;

        if (offset < 0 || offset > svlen)
          croak ("offset outside of scalar");

        if (!SvOK (length) || len + offset > svlen)
          len = svlen - offset;

        addr = (void *)(((intptr_t)addr) + offset);
        eio_page_align (&addr, &len);

        switch (ix)
          {
            case 0: RETVAL = posix_madvise (addr, len, advice_or_prot); break;
            case 1: RETVAL = mprotect      (addr, len, advice_or_prot); break;
          }
}
	OUTPUT:
        RETVAL

int
munlock (SV *scalar, IV offset = 0, SV *length = &PL_sv_undef)
        CODE:
{
	STRLEN svlen;
	void *addr = SvPVbyte (scalar, svlen);
        size_t len = SvUV (length);

        if (offset < 0)
          offset += svlen;

        if (offset < 0 || offset > svlen)
          croak ("offset outside of scalar");

        if (!SvOK (length) || len + offset > svlen)
          len = svlen - offset;

        addr = (void *)(((intptr_t)addr) + offset);
        eio_page_align (&addr, &len);
#if _POSIX_MEMLOCK_RANGE
        RETVAL = munlock (addr, len);
#else
        RETVAL = EIO_ENOSYS ();
#endif
}
        OUTPUT:
        RETVAL

int
mlockall (int flags)
	PROTOTYPE: $;
        CODE:
        RETVAL = eio_mlockall_sync (flags);
	OUTPUT:
        RETVAL

int
munlockall ()
        CODE:
#if _POSIX_MEMLOCK
        munlockall ();
#else
        RETVAL = EIO_ENOSYS ();
#endif
        OUTPUT:
        RETVAL

int
statx (SV8 *pathname, int flags, UV mask)
        CODE:
{
	/* undocumented, and might go away, and anyway, should use eio_statx */
	SV *wdsv = 0;
        SV *pathsv = 0;
        eio_wd wd = EIO_CWD;
        void *ptr;
        int res;

	req_set_path (pathname, &wdsv, &pathsv, &wd, &ptr);
        RETVAL = eio__statx (!wd || wd->fd == EIO_CWD ? AT_FDCWD : wd->fd, ptr, flags, mask & STATX_ALL, &stx);

        SvREFCNT_dec (pathsv);
        SvREFCNT_dec (wdsv);
}
	OUTPUT:
        RETVAL

U32
stx_mode ()
	PROTOTYPE:
	CODE:
#if HAVE_STATX
        RETVAL = stx.stx_mode;
#else
	XSRETURN_UNDEF;
#endif
	OUTPUT:
        RETVAL

#define STATX_OFFSET_mask            statx_offsetof (stx_mask)
#define STATX_OFFSET_blksize         statx_offsetof (stx_blksize)
#define STATX_OFFSET_nlink           statx_offsetof (stx_nlink)
#define STATX_OFFSET_uid             statx_offsetof (stx_uid)
#define STATX_OFFSET_gid             statx_offsetof (stx_gid)
#define STATX_OFFSET_rdev_major      statx_offsetof (stx_rdev_major)
#define STATX_OFFSET_rdev_minor      statx_offsetof (stx_rdev_minor)
#define STATX_OFFSET_dev_major       statx_offsetof (stx_dev_major)
#define STATX_OFFSET_dev_minor       statx_offsetof (stx_dev_minor)
#define STATX_OFFSET_attributes      statx_offsetof (stx_attributes)
#define STATX_OFFSET_ino             statx_offsetof (stx_ino)
#define STATX_OFFSET_size            statx_offsetof (stx_size)
#define STATX_OFFSET_blocks          statx_offsetof (stx_blocks)
#define STATX_OFFSET_attributes_mask statx_offsetof (stx_attributes_mask)
#define STATX_OFFSET_atime           statx_offsetof (stx_atime)
#define STATX_OFFSET_btime           statx_offsetof (stx_btime)
#define STATX_OFFSET_ctime           statx_offsetof (stx_ctime)
#define STATX_OFFSET_mtime           statx_offsetof (stx_mtime)

U32
stx_mask ()
	PROTOTYPE:
        ALIAS:
        stx_mask       = STATX_OFFSET_mask
        stx_blksize    = STATX_OFFSET_blksize
        stx_nlink      = STATX_OFFSET_nlink
        stx_uid        = STATX_OFFSET_uid
        stx_gid        = STATX_OFFSET_gid
        stx_rdev_major = STATX_OFFSET_rdev_major
        stx_rdev_minor = STATX_OFFSET_rdev_minor
        stx_dev_major  = STATX_OFFSET_dev_major
        stx_dev_minor  = STATX_OFFSET_dev_minor
	CODE:
#if HAVE_STATX
        RETVAL = *(__u32 *)((char *)&stx + ix);
#else
	XSRETURN_UNDEF;
#endif
	OUTPUT:
        RETVAL

VAL64
stx_attributes ()
	PROTOTYPE:
        ALIAS:
        stx_attributes      = STATX_OFFSET_attributes
        stx_ino             = STATX_OFFSET_ino
        stx_size            = STATX_OFFSET_size
        stx_blocks          = STATX_OFFSET_blocks
        stx_attributes_mask = STATX_OFFSET_attributes_mask
	CODE:
#if HAVE_STATX
        RETVAL = *(__u64 *)((char *)&stx + ix);
#else
	XSRETURN_UNDEF;
#endif
	OUTPUT:
        RETVAL

NV
stx_atime ()
	PROTOTYPE:
        ALIAS:
        stx_atime      = STATX_OFFSET_atime
        stx_btime      = STATX_OFFSET_btime
        stx_ctime      = STATX_OFFSET_ctime
        stx_mtime      = STATX_OFFSET_mtime
	CODE:
#if HAVE_STATX
        struct statx_timestamp *ts = (struct statx_timestamp *)((char *)&stx + ix);
        RETVAL = ts->tv_sec + ts->tv_nsec * 1e-9;
#else
	XSRETURN_UNDEF;
#endif
	OUTPUT:
        RETVAL

VAL64
stx_atimesec ()
	PROTOTYPE:
        ALIAS:
        stx_atimesec   = STATX_OFFSET_atime
        stx_btimesec   = STATX_OFFSET_btime
        stx_ctimesec   = STATX_OFFSET_ctime
        stx_mtimesec   = STATX_OFFSET_mtime
	CODE:
#if HAVE_STATX
        struct statx_timestamp *ts = (struct statx_timestamp *)((char *)&stx + ix);
        RETVAL = ts->tv_sec;
#else
	XSRETURN_UNDEF;
#endif
	OUTPUT:
        RETVAL

U32
stx_atimensec ()
	PROTOTYPE:
        ALIAS:
        stx_atimensec  = STATX_OFFSET_atime
        stx_btimensec  = STATX_OFFSET_btime
        stx_ctimensec  = STATX_OFFSET_ctime
        stx_mtimensec  = STATX_OFFSET_mtime
	CODE:
#if HAVE_STATX
        struct statx_timestamp *ts = (struct statx_timestamp *)((char *)&stx + ix);
        RETVAL = ts->tv_nsec;
#else
        RETVAL = 0;
#endif
	OUTPUT:
        RETVAL

void
accept4 (aio_rfd rfh, SV *sockaddr, int salen, int flags)
	PPCODE:
{
        SV *retval;
#if HAVE_ACCEPT4
        socklen_t salen_ = salen ? salen + 1 : 0;

        if (salen)
          {
            sv_upgrade (sockaddr, SVt_PV);
            sv_grow (sockaddr, salen_);
          }
        
        int res = accept4 (rfh, salen ? (struct sockaddr *)SvPVX (sockaddr) : 0, salen ? &salen_ : 0, flags);
        
        retval = newmortalFH (res, O_RDWR);

        if (res >= 0 && salen > 0)
          {
            if (salen_ > salen + 1)
              salen_ = salen + 1;

            SvPOK_only (sockaddr);
            SvCUR_set (sockaddr, salen_);
          }
#else
        errno = ENOSYS;
        retval = &PL_sv_undef;
#endif
        XPUSHs (retval);
}

ssize_t
splice (aio_rfd rfh, SV *off_in, aio_wfd wfh, SV *off_out, size_t length, unsigned int flags)
        CODE:
{
#if HAVE_LINUX_SPLICE
	loff_t off_in_, off_out_;
        RETVAL = splice (
          rfh, SvOK (off_in ) ? (off_in_  = SvVAL64 (off_in )), &off_in_  : 0,
          wfh, SvOK (off_out) ? (off_out_ = SvVAL64 (off_out)), &off_out_ : 0,
          length, flags
        );
#else
        RETVAL = EIO_ENOSYS ();
#endif
}
	OUTPUT:
        RETVAL

ssize_t
tee (aio_rfd rfh, aio_wfd wfh, size_t length, unsigned int flags)
        CODE:
#if HAVE_LINUX_SPLICE
        RETVAL = tee (rfh, wfh, length, flags);
#else
        RETVAL = EIO_ENOSYS ();
#endif
	OUTPUT:
        RETVAL

int
pipesize (aio_rfd rfh, int new_size = -1)
	PROTOTYPE: $;$
        CODE:
#if defined(F_SETPIPE_SZ) && defined(F_GETPIPE_SZ)
        if (new_size >= 0)
          RETVAL = fcntl (rfh, F_SETPIPE_SZ, new_size);
        else
          RETVAL = fcntl (rfh, F_GETPIPE_SZ);
#else
        errno = ENOSYS;
        RETVAL = -1;
#endif
        OUTPUT:
        RETVAL

void
pipe2 (int flags = 0)
	PROTOTYPE: ;$
        PPCODE:
{
	int fd[2];
        int res;

        if (flags)
#if HAVE_PIPE2
          res = pipe2 (fd, flags);
#else
          res = (errno = ENOSYS, -1);
#endif
        else
          res = pipe (fd);

        if (!res)
          {
            EXTEND (SP, 2);
            PUSHs (newmortalFH (fd[0], O_RDONLY));
            PUSHs (newmortalFH (fd[1], O_WRONLY));
          }
}

void
pidfd_open (int pid, unsigned int flags = 0)
	PPCODE:
{
        /*GENDEF0_SYSCALL(pidfd_open,434)*/
        int fd = syscall (SYS_pidfd_open, pid, flags);
        XPUSHs (newmortalFH (fd, O_RDWR));
}

int
pidfd_send_signal (SV *pidfh, int sig, SV *siginfo = &PL_sv_undef, unsigned int flags = 0)
	PPCODE:
{
	int res;
	siginfo_t si = { 0 };

        if (SvOK (siginfo))
          {
            HV *hv;
            SV **svp;

            if (!SvROK (siginfo) || SvTYPE (SvRV (siginfo)) != SVt_PVHV)
              croak ("siginfo argument must be a hashref code, pid, uid and value_int or value_ptr members, caught");

            hv = (HV *)SvRV (siginfo);

            if ((svp = hv_fetchs (hv, "code"     , 0))) si.si_code            =         SvIV (*svp);
            if ((svp = hv_fetchs (hv, "pid"      , 0))) si.si_pid             =         SvIV (*svp);
            if ((svp = hv_fetchs (hv, "uid"      , 0))) si.si_uid             =         SvIV (*svp);
            if ((svp = hv_fetchs (hv, "value_int", 0))) si.si_value.sival_int =         SvIV (*svp);
            if ((svp = hv_fetchs (hv, "value_ptr", 0))) si.si_value.sival_ptr = (void *)SvIV (*svp);
          }

        /*GENDEF0_SYSCALL(pidfd_send_signal,424)*/
        res = syscall (SYS_pidfd_send_signal, s_fileno_croak (pidfh, 0), sig, SvOK (siginfo) ? &si : 0, flags);

        XPUSHs (sv_2mortal (newSViv (res)));
}

void
pidfd_getfd (SV *pidfh, int targetfd, unsigned int flags = 0)
	PPCODE:
{
        /*GENDEF0_SYSCALL(pidfd_getfd,438)*/
        int fd = syscall (SYS_pidfd_getfd, s_fileno_croak (pidfh, 0), targetfd, flags);
        XPUSHs (newmortalFH (fd, O_RDWR));
}

void
eventfd (unsigned int initval = 0, int flags = 0)
	PPCODE:
{
	int fd;
#if HAVE_EVENTFD
        fd = eventfd (initval, flags);
#else
        fd = (errno = ENOSYS, -1);
#endif
	
        XPUSHs (newmortalFH (fd, O_RDWR));
}

void
timerfd_create (int clockid, int flags = 0)
	PPCODE:
{
	int fd;
#if HAVE_TIMERFD
        fd = timerfd_create (clockid, flags);
#else
        fd = (errno = ENOSYS, -1);
#endif
	
        XPUSHs (newmortalFH (fd, O_RDWR));
}

void
timerfd_settime (SV *fh, int flags, NV interval, NV value)
	PPCODE:
{
        int fd = s_fileno_croak (fh, 0);
#if HAVE_TIMERFD
	int res;
        struct itimerspec its, ots;

        ts_set (&its.it_interval, interval);
        ts_set (&its.it_value   , value);
        res = timerfd_settime (fd, flags, &its, &ots);

        if (!res)
          {
            EXTEND (SP, 2);
            PUSHs (newSVnv (ts_get (&ots.it_interval)));
            PUSHs (newSVnv (ts_get (&ots.it_value)));
          }
#else
        errno = ENOSYS;
#endif
}

void
timerfd_gettime (SV *fh)
	PPCODE:
{
        int fd = s_fileno_croak (fh, 0);
#if HAVE_TIMERFD
	int res;
        struct itimerspec ots;
        res = timerfd_gettime (fd, &ots);

        if (!res)
          {
            EXTEND (SP, 2);
            PUSHs (newSVnv (ts_get (&ots.it_interval)));
            PUSHs (newSVnv (ts_get (&ots.it_value)));
          }
#else
        errno = ENOSYS;
#endif
}

void
memfd_create (SV8 *pathname, int flags = 0)
	PPCODE:
{
	int fd;
#if HAVE_MEMFD_CREATE
        fd = memfd_create (SvPVbyte_nolen (pathname), flags);
#else
        fd = (errno = ENOSYS, -1);
#endif
	
        XPUSHs (newmortalFH (fd, O_RDWR));
}

UV
get_fdlimit ()
	CODE:
#if HAVE_RLIMITS
        struct rlimit rl;
        if (0 == getrlimit (RLIMIT_NOFILE, &rl))
	  XSRETURN_UV (rl.rlim_cur == RLIM_INFINITY ? (UV)-1 : rl.rlim_cur);
#endif
        XSRETURN_UNDEF;
	OUTPUT:
        RETVAL

void
min_fdlimit (UV limit = 0x7fffffffU)
	CODE:
{
#if HAVE_RLIMITS
        struct rlimit rl;
        rlim_t orig_rlim_max;
        UV bit;

        if (0 != getrlimit (RLIMIT_NOFILE, &rl))
          goto fail;

        if (rl.rlim_cur == RLIM_INFINITY)
          XSRETURN_YES;

        orig_rlim_max = rl.rlim_max == RLIM_INFINITY ? ((rlim_t)0)-1 : rl.rlim_max;

        if (rl.rlim_cur < limit)
          {
            rl.rlim_cur = limit;

            if (rl.rlim_max < rl.rlim_cur && rl.rlim_max != RLIM_INFINITY)
              rl.rlim_max = rl.rlim_cur;
          }

        if (0 == setrlimit (RLIMIT_NOFILE, &rl))
          XSRETURN_YES;

        if (errno == EPERM)
          {
            /* setrlimit failed with EPERM - maybe we can't raise the hardlimit, or maybe */
            /* our limit overflows a system-wide limit */
            /* try an adaptive algorithm, but do not lower the hardlimit */
            rl.rlim_max = 0;
            for (bit = 0x40000000U; bit; bit >>= 1)
              {
                rl.rlim_max |= bit;
                rl.rlim_cur = rl.rlim_max;

                /* never decrease the hard limit */
                if (rl.rlim_max < orig_rlim_max)
                  break;

                if (0 != setrlimit (RLIMIT_NOFILE, &rl))
                  rl.rlim_max &= ~bit; /* too high, remove bit again */
              }

            /* now, raise the soft limit to the max permitted */
            if (0 == getrlimit (RLIMIT_NOFILE, &rl))
              {
                rl.rlim_cur = rl.rlim_max;
                if (0 == setrlimit (RLIMIT_NOFILE, &rl))
                  errno = EPERM;
              }
	  }
#endif
        fail:
        XSRETURN_UNDEF;
}

void _on_next_submit (SV *cb)
	CODE:
        SvREFCNT_dec (on_next_submit);
        on_next_submit = SvOK (cb) ? newSVsv (cb) : 0;

PROTOTYPES: DISABLE

MODULE = IO::AIO                PACKAGE = IO::AIO::WD

BOOT:
{
  newCONSTSUB (aio_stash, "CWD"       , newSVaio_wd (EIO_CWD       ));
  newCONSTSUB (aio_stash, "INVALID_WD", newSVaio_wd (EIO_INVALID_WD));
}

void
DESTROY (SV *self)
	CODE:
{
	aio_wd wd = SvAIO_WD (self);
#if HAVE_AT
        {
          SV *callback = &PL_sv_undef;
          dREQ; /* clobbers next_pri :/ */
          next_pri = req->pri; /* restore next_pri */
          req->pri = EIO_PRI_MAX; /* better use max. priority to conserve fds */
          req->type = EIO_WD_CLOSE;
          req->wd = wd;
          REQ_SEND;
        }
#else
        eio_wd_close_sync (wd);
#endif
}

MODULE = IO::AIO                PACKAGE = IO::AIO::REQ

void
cancel (aio_req_ornot req)
	CODE:
        eio_cancel (req);

void
cb (aio_req_ornot req, SV *callback = NO_INIT)
	PPCODE:
{
        if (GIMME_V != G_VOID)
          XPUSHs (req->callback ? sv_2mortal (newRV_inc (req->callback)) : &PL_sv_undef);

        if (items > 1)
          {
            SV *cb_cv = get_cb (callback);

            SvREFCNT_dec (req->callback);
            req->callback = SvREFCNT_inc (cb_cv);
          }
}

MODULE = IO::AIO                PACKAGE = IO::AIO::GRP

void
add (aio_req grp, ...)
        PPCODE:
{
	int i;

        if (grp->int1 == 2)
          croak ("cannot add requests to IO::AIO::GRP after the group finished");

	for (i = 1; i < items; ++i )
          {
            aio_req req;

            if (GIMME_V != G_VOID)
              XPUSHs (sv_2mortal (newSVsv (ST (i))));

            req = SvAIO_REQ (ST (i));

            if (req)
              eio_grp_add (grp, req);
          }
}

void
cancel_subs (aio_req_ornot req)
	CODE:
        req_cancel_subs (req);

void
result (aio_req grp, ...)
        CODE:
{
        int i;
        AV *av;

        grp->errorno = errno;

        av = newAV ();
        av_extend (av, items - 1);

        for (i = 1; i < items; ++i )
          av_push (av, newSVsv (ST (i)));

        SvREFCNT_dec (grp->sv1);
        grp->sv1 = (SV *)av;
}

void
errno (aio_req grp, int errorno = errno)
        CODE:
        grp->errorno = errorno;

void
limit (aio_req grp, int limit)
	CODE:
        eio_grp_limit (grp, limit);

void
feed (aio_req grp, SV *callback = &PL_sv_undef)
	CODE:
{
        SvREFCNT_dec (grp->sv2);
        grp->sv2  = newSVsv (callback);
        grp->feed = aio_grp_feed;

        if (grp->int2 <= 0)
          grp->int2 = 2;

        eio_grp_limit (grp, grp->int2);
}

