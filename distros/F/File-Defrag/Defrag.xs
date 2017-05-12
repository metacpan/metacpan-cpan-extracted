#define _GNU_SOURCE // gets us largefile64, among others

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>

#include <linux/fs.h>

#ifndef O_NOATIME
# if __i386__ || __ia64__ || __x86_64__ || __ppc__
#  define O_NOATIME 01000000
# else
#  define O_NOATIME 0
# endif
#endif

MODULE = File::Defrag		PACKAGE = File::Defrag

PROTOTYPES: enable

SV *
direct_open (const char *pathname, int flags, int mode = 0666)
  CODE:
{
  int fd = open (pathname, flags | O_DIRECT | O_LARGEFILE | O_NOATIME | O_NOFOLLOW, mode);

  if (fd < 0 && errno == EINVAL)
     fd = open (pathname, flags | O_LARGEFILE | O_NOATIME | O_NOFOLLOW, mode);

  if (fd < 0)
    XSRETURN_UNDEF;

  fcntl (fd, F_SETFD, 1);

  GV *gv = newGVgen ("File::Defrag");
  IO *io = GvIOn (gv);

  IoIFP (io) = PerlIO_fdopen (fd, "r+");
  RETVAL = newRV_noinc ((SV *)gv);
}
  OUTPUT:
  RETVAL

U32
direct_copy (PerlIO *f1, PerlIO *f2, U32 chunksize, U32 chunkindex)
  CODE:
{
  int fd1 = PerlIO_fileno (f1);
  int fd2 = PerlIO_fileno (f2);

  void *buff = mmap (0, chunksize,
                     PROT_READ | PROT_WRITE,
                     MAP_PRIVATE | MAP_LOCKED | MAP_ANONYMOUS | MAP_POPULATE,
                     0, 0);

  if (buff == MAP_FAILED)
    croak ("unable to allocate %ld bytes of memory for copy buffer", (long)chunksize);

  off64_t offs = (off_t)chunksize * (off_t)chunkindex;

  ssize_t count = pread64 (fd1, buff, chunksize, offs);

  if (count == -1)
    {
      munmap (buff, chunksize);
      croak ("unable to read %ld bytes from source file", (long)chunksize);
    }

  ssize_t rounded = (count + 511) & ~511;

  ssize_t written = pwrite64 (fd2, buff, rounded, offs);

  munmap (buff, chunksize);

  if (written != rounded)
    croak ("unable to write %ld bytes to destination file", (long)rounded);

  RETVAL = count;
}
  OUTPUT:
  RETVAL

long
file_extents (PerlIO *f, long max_gap = 0)
  CODE:
{
  int fd = PerlIO_fileno (f);

  struct stat64 statdata;

  if (fstat64 (fd, &statdata))
    croak ("unable to stat() file");

  long blksize;

  if (ioctl (fd, FIGETBSZ, &blksize))
    croak ("unable to detect file blocksize");

  long fragments = 1;
  long next_blk = 0;

  if (ioctl (fd, FIBMAP, &next_blk))
    XSRETURN_EMPTY;

  long count = (statdata.st_size + blksize - 1) / blksize;

  long i;
  for (i = 0; i < count; i++)
    {
      long blk = i;
      if (ioctl (fd, FIBMAP, &blk))
        XSRETURN_EMPTY;

      if (blk < next_blk || next_blk + max_gap < blk)
        fragments++;
      
      next_blk = blk + 1;
   }

  RETVAL = fragments;
}
  OUTPUT:
  RETVAL
