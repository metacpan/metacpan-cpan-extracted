#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <fcntl.h>
#include <signal.h>
#include <sched.h>
#include <endian.h>

typedef void *InputStream;  /* hack, but 5.6.1 is simply toooo old ;) */
typedef void *OutputStream; /* hack, but 5.6.1 is simply toooo old ;) */
typedef void *InOutStream;  /* hack, but 5.6.1 is simply toooo old ;) */

#if __i386 || __amd64
# define STACKSIZE ( 256 * sizeof (long))
#elif __ia64
# define STACKSIZE (8192 * sizeof (long))
#else
# define STACKSIZE ( 512 * sizeof (long))
#endif

enum {
  REQ_QUIT,
  REQ_OPEN, REQ_CLOSE,
  REQ_READ, REQ_WRITE, REQ_READAHEAD,
  REQ_STAT, REQ_LSTAT, REQ_FSTAT, REQ_UNLINK,
  REQ_FSYNC, REQ_FDATASYNC,
};

typedef struct {
  char stack[STACKSIZE];
} aio_thread;

typedef struct aio_cb {
  struct aio_cb *next;

  int type;
  aio_thread *thread;

  int fd;
  off_t offset;
  size_t length;
  ssize_t result;
  mode_t mode; /* open */
  int errorno;
  SV *data, *callback;
  void *dataptr;
  STRLEN dataoffset;

  Stat_t *statdata;
} aio_cb;

typedef aio_cb *aio_req;

static int started;
static int nreqs;
static int reqpipe[2], respipe[2];

static aio_req qs, qe; /* queue start, queue end */

static int aio_proc(void *arg);

static void
start_thread (void)
{
  aio_thread *thr;

  New (0, thr, 1, aio_thread);

  if (clone (aio_proc,
             &(thr->stack[STACKSIZE - 16]),
             CLONE_VM|CLONE_FS|CLONE_FILES,
             thr) >= 0)
    started++;
  else
    Safefree (thr);
}

static void
send_reqs (void)
{
  /* this write is atomic */
  while (qs && write (reqpipe[1], &qs, sizeof qs) == sizeof qs)
   {
     qs = qs->next;
     if (!qs) qe = 0;
   }
}

static void
send_req (aio_req req)
{
  nreqs++;
  req->next = 0;

  if (qe)
    {
      qe->next = req;
      qe = req;
    }
  else
    qe = qs = req;

  send_reqs ();
}

static void
end_thread (void)
{
  aio_req req;
  New (0, req, 1, aio_cb);
  req->type = REQ_QUIT;

  send_req (req);
}

static void
read_write (pTHX_
            int dowrite, int fd, off_t offset, size_t length,
            SV *data, STRLEN dataoffset, SV *callback)
{
  aio_req req;
  STRLEN svlen;
  char *svptr = SvPV (data, svlen);

  SvUPGRADE (data, SVt_PV);
  SvPOK_on (data);

  if (dataoffset < 0)
    dataoffset += svlen;

  if (dataoffset < 0 || dataoffset > svlen)
    croak ("data offset outside of string");

  if (dowrite)
    {
      /* write: check length and adjust. */
      if (length < 0 || length + dataoffset > svlen)
        length = svlen - dataoffset;
    }
  else
    {
      /* read: grow scalar as necessary */
      svptr = SvGROW (data, length + dataoffset);
    }

  if (length < 0)
    croak ("length must not be negative");

  Newz (0, req, 1, aio_cb);

  if (!req)
    croak ("out of memory during aio_req allocation");

  req->type = dowrite ? REQ_WRITE : REQ_READ;
  req->fd = fd;
  req->offset = offset;
  req->length = length;
  req->data = SvREFCNT_inc (data);
  req->dataptr = (char *)svptr + dataoffset;
  req->callback = SvREFCNT_inc (callback);

  send_req (req);
}

static void
poll_wait ()
{
  if (!nreqs)
    return;

  fd_set rfd;
  FD_ZERO(&rfd);
  FD_SET(respipe[0], &rfd);

  select (respipe[0] + 1, &rfd, 0, 0, 0);
}

static int
poll_cb (pTHX)
{
  dSP;
  int count = 0;
  aio_req req;

  while (read (respipe[0], (void *)&req, sizeof (req)) == sizeof (req))
    {
      nreqs--;

      if (req->type == REQ_QUIT)
        {
          Safefree (req->thread);
          started--;
        }
      else
        {
          int errorno = errno;
          errno = req->errorno;

          if (req->type == REQ_READ)
            SvCUR_set (req->data, req->dataoffset
                                  + (req->result > 0 ? req->result : 0));

          if (req->data)
            SvREFCNT_dec (req->data);

          if (req->type == REQ_STAT || req->type == REQ_LSTAT || req->type == REQ_FSTAT)
            {
              PL_laststype   = req->type == REQ_LSTAT ? OP_LSTAT : OP_STAT;
              PL_laststatval = req->result;
              PL_statcache   = *(req->statdata);

              Safefree (req->statdata);
            }

          PUSHMARK (SP);
          XPUSHs (sv_2mortal (newSViv (req->result)));
          PUTBACK;
          call_sv (req->callback, G_VOID);
          SPAGAIN;
          
          if (req->callback)
            SvREFCNT_dec (req->callback);

          errno = errorno;
          count++;
        }

      Safefree (req);
    }

  if (qs)
    send_reqs ();

  return count;
}

static sigset_t fullsigset;

#undef errno
#include <linux/unistd.h>
#include <linux/types.h>
#include <sys/prctl.h>

#if __alpha || __ia64 || __hppa || __v850__
# define stat kernelstat
# define stat64 kernelstat64
# include <asm/stat.h>
# undef stat
# undef stat64
#else
# define kernelstat stat
# define kernelstat64 stat64
#endif

#define COPY_STATDATA	\
  req->statdata->st_dev     = statdata.st_dev;		\
  req->statdata->st_ino     = statdata.st_ino;		\
  req->statdata->st_mode    = statdata.st_mode;		\
  req->statdata->st_nlink   = statdata.st_nlink;	\
  req->statdata->st_uid     = statdata.st_uid;		\
  req->statdata->st_gid     = statdata.st_gid;		\
  req->statdata->st_rdev    = statdata.st_rdev;		\
  req->statdata->st_size    = statdata.st_size;		\
  req->statdata->st_atime   = statdata.st_atime;	\
  req->statdata->st_mtime   = statdata.st_mtime;	\
  req->statdata->st_ctime   = statdata.st_ctime;	\
  req->statdata->st_blksize = statdata.st_blksize;	\
  req->statdata->st_blocks  = statdata.st_blocks;	\

static int
aio_proc (void *thr_arg)
{
  aio_thread *thr = thr_arg;
  aio_req req;
  int errno;

  /* this is very much kernel-specific :(:(:( */
  /* we rely on gcc's ability to create closures. */
  _syscall3(__kernel_size_t, read , unsigned int, fd, char *, buf, __kernel_size_t, count)
  _syscall3(__kernel_size_t, write, unsigned int, fd, char *, buf, __kernel_size_t, count)

  _syscall3(long, open, char *, pathname, int, flags, int, mode)
  _syscall1(long, close, unsigned int, fd)
  _syscall1(long, unlink, char *, filename);
  _syscall1(long, fsync, unsigned int, fd);

#ifndef __NR_fdatasync
# define __NR_fdatasync __NR_fsync
#endif
  _syscall1(long, fdatasync, unsigned int, fd);

#if BYTE_ORDER == LITTLE_ENDIAN
# define LOFF_ARG(off) (off & 0xffffffff), (off >> 32)
#elif BYTE_ORDER == BIG_ENDIAN
# define LOFF_ARG(off) (off >> 32), (off & 0xffffffff)
#endif

#ifndef __NR_pread64
# define __NR_pread64 __NR_pread
# define __NR_pwrite64 __NR_write
#endif
  _syscall5(__kernel_ssize_t, pread64 , unsigned int, fd, char *, buf,
            __kernel_size_t, count, unsigned int, offset_lh, unsigned int, offset_hl)
  _syscall5(__kernel_ssize_t, pwrite64, unsigned int, fd, char *, buf,
            __kernel_size_t, count, unsigned int, offset_lh, unsigned int, offset_hl)
  _syscall4(long, readahead, unsigned int, fd, unsigned int, offset_lh, unsigned int, offset_hl, __kernel_size_t, count);

#if __NR_stat64
  _syscall2(long, stat64 , const char *, filename, struct kernelstat64 *, buf)
  _syscall2(long, lstat64, const char *, filename, struct kernelstat64 *, buf)
  _syscall2(long, fstat64, int         , fd      , struct kernelstat64 *, buf)
#elif __NR_stat
  _syscall2(long, stat , const char *, filename, struct kernelstat *, buf)
  _syscall2(long, lstat, const char *, filename, struct kernelstat *, buf)
  _syscall2(long, fstat, int         , fd      , struct kernelstat *, buf)
#else
# error "neither stat64 nor stat defined"
#endif

  /* the following two calls might clobber errno */
  sigprocmask (SIG_SETMASK, &fullsigset, 0);
  prctl (PR_SET_PDEATHSIG, SIGKILL);

  /* then loop */
  while (read (reqpipe[0], (void *)&req, sizeof (req)) == sizeof (req))
    {
      req->thread = thr;
      errno = 0; /* strictly unnecessary */

      switch (req->type)
        {
          case REQ_READ:      req->result = pread64   (req->fd, req->dataptr, req->length, LOFF_ARG (req->offset)); break;
          case REQ_WRITE:     req->result = pwrite64  (req->fd, req->dataptr, req->length, LOFF_ARG (req->offset)); break;
          case REQ_READAHEAD: req->result = readahead (req->fd, LOFF_ARG (req->offset), req->length); break;

#if __NR_stat64
          struct kernelstat64 statdata;
          case REQ_STAT:      req->result = stat64    (req->dataptr, &statdata); COPY_STATDATA; break;
          case REQ_LSTAT:     req->result = lstat64   (req->dataptr, &statdata); COPY_STATDATA; break;
          case REQ_FSTAT:     req->result = fstat64   (req->fd     , &statdata); COPY_STATDATA; break;
#else
          struct kernelstat statdata;
          case REQ_STAT:      req->result = stat      (req->dataptr, &statdata); COPY_STATDATA; break;
          case REQ_LSTAT:     req->result = lstat     (req->dataptr, &statdata); COPY_STATDATA; break;
          case REQ_FSTAT:     req->result = fstat     (req->fd     , &statdata); COPY_STATDATA; break;
#endif

          case REQ_OPEN:      req->result = open      (req->dataptr, req->fd, req->mode); break;
          case REQ_CLOSE:     req->result = close     (req->fd); break;
          case REQ_UNLINK:    req->result = unlink    (req->dataptr); break;

          case REQ_FSYNC:     req->result = fsync     (req->fd); break;
          case REQ_FDATASYNC: req->result = fdatasync (req->fd); break;

          case REQ_QUIT:
            write (respipe[1], (void *)&req, sizeof (req));
            return 0;

          default:
            req->result = ENOSYS;
            break;
        }

      req->errorno = errno;
      write (respipe[1], (void *)&req, sizeof (req));
    }

  return 0;
}

MODULE = Linux::AIO                PACKAGE = Linux::AIO

BOOT:
{
        sigfillset (&fullsigset);
        sigdelset (&fullsigset, SIGTERM);
        sigdelset (&fullsigset, SIGQUIT);
        sigdelset (&fullsigset, SIGABRT);
        sigdelset (&fullsigset, SIGINT);

        if (pipe (reqpipe) || pipe (respipe))
          croak ("unable to initialize request or result pipe");

        if (fcntl (reqpipe[1], F_SETFL, O_NONBLOCK))
          croak ("cannot set result pipe to nonblocking mode");

        if (fcntl (respipe[0], F_SETFL, O_NONBLOCK))
          croak ("cannot set result pipe to nonblocking mode");
}

void
min_parallel(nthreads)
	int	nthreads
	PROTOTYPE: $
        CODE:
        while (nthreads > started)
          start_thread ();

void
max_parallel(nthreads)
	int	nthreads
	PROTOTYPE: $
        CODE:
{
        int cur = started;
        while (cur > nthreads)
          {          
            end_thread ();
            cur--;
          }

        while (started > nthreads)
          {
            poll_wait ();
            poll_cb (aTHX);
          }
}

void
aio_open(pathname,flags,mode,callback)
	SV *	pathname
        int	flags
        int	mode
        SV *	callback
	PROTOTYPE: $$$$
	CODE:
{
        aio_req req;

        Newz (0, req, 1, aio_cb);

        if (!req)
          croak ("out of memory during aio_req allocation");

        req->type = REQ_OPEN;
        req->data = newSVsv (pathname);
        req->dataptr = SvPV_nolen (req->data);
        req->fd = flags;
        req->mode = mode;
        req->callback = SvREFCNT_inc (callback);

        send_req (req);
}

void
aio_close(fh,callback)
        InputStream	fh
        SV *		callback
	PROTOTYPE: $$
        ALIAS:
           aio_close     = REQ_CLOSE
           aio_fsync     = REQ_FSYNC
           aio_fdatasync = REQ_FDATASYNC
	CODE:
{
        aio_req req;

        Newz (0, req, 1, aio_cb);

        if (!req)
          croak ("out of memory during aio_req allocation");

        req->type = ix;
        req->fd = PerlIO_fileno (fh);
        req->callback = SvREFCNT_inc (callback);

        send_req (req);
}

void
aio_read(fh,offset,length,data,dataoffset,callback)
        InputStream	fh
        UV		offset
        IV		length
        SV *		data
        IV		dataoffset
        SV *		callback
	PROTOTYPE: $$$$$$
        CODE:
        read_write (aTHX_ 0, PerlIO_fileno (fh), offset, length, data, dataoffset, callback);

void
aio_write(fh,offset,length,data,dataoffset,callback)
        OutputStream	fh
        UV		offset
        IV		length
        SV *		data
        IV		dataoffset
        SV *		callback
	PROTOTYPE: $$$$$$
        CODE:
        read_write (aTHX_ 1, PerlIO_fileno (fh), offset, length, data, dataoffset, callback);

void
aio_readahead(fh,offset,length,callback)
        InputStream	fh
        UV		offset
        IV		length
        SV *		callback
	PROTOTYPE: $$$$
        CODE:
{
        aio_req req;

        if (length < 0)
          croak ("length must not be negative");

        Newz (0, req, 1, aio_cb);

        if (!req)
          croak ("out of memory during aio_req allocation");

        req->type = REQ_READAHEAD;
        req->fd = PerlIO_fileno (fh);
        req->offset = offset;
        req->length = length;
        req->callback = SvREFCNT_inc (callback);

        send_req (req);
}

void
aio_stat(fh_or_path,callback)
        SV *		fh_or_path
        SV *		callback
	PROTOTYPE: $$
        ALIAS:
           aio_lstat = 1
	CODE:
{
        aio_req req;

        Newz (0, req, 1, aio_cb);

        if (!req)
          croak ("out of memory during aio_req allocation");

        New (0, req->statdata, 1, Stat_t);

        if (!req->statdata)
          croak ("out of memory during aio_req->statdata allocation");

        if (SvPOK (fh_or_path))
          {
            req->type = ix ? REQ_LSTAT : REQ_STAT;
            req->data = newSVsv (fh_or_path);
            req->dataptr = SvPV_nolen (req->data);
          }
        else
          {
            req->type = REQ_FSTAT;
            req->fd = PerlIO_fileno (IoIFP (sv_2io (fh_or_path)));
          }

        req->callback = SvREFCNT_inc (callback);

        send_req (req);
}

void
aio_unlink(pathname,callback)
	SV * pathname
	SV * callback
	PROTOTYPE: $$
	CODE:
{
	aio_req req;
	
	Newz (0, req, 1, aio_cb);
	
	if (!req)
	  croak ("out of memory during aio_req allocation");
	
	req->type = REQ_UNLINK;
	req->data = newSVsv (pathname);
	req->dataptr = SvPV_nolen (req->data);
	req->callback = SvREFCNT_inc (callback);
	
	send_req (req);
}

int
poll_fileno()
	PROTOTYPE:
	CODE:
        RETVAL = respipe[0];
	OUTPUT:
	RETVAL

int
poll_cb(...)
	PROTOTYPE:
	CODE:
        RETVAL = poll_cb (aTHX);
	OUTPUT:
	RETVAL

void
poll_wait()
	PROTOTYPE:
	CODE:
        poll_wait ();

int
nreqs()
	PROTOTYPE:
	CODE:
        RETVAL = nreqs;
	OUTPUT:
	RETVAL

