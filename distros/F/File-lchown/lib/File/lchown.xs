/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2007,2008 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/time.h>
#include <unistd.h>

MODULE = File::lchown    PACKAGE = File::lchown

int
lchown(uid, gid, ...)
    int uid
    int gid

  PREINIT:
    int i;

  CODE:
    RETVAL = 0;

    for(i = 2; i < items; i++) {
      char *path = SvPV_nolen(ST(i));
      if(lchown(path, uid, gid) == 0)
        RETVAL++;
    }

  OUTPUT:
    RETVAL

int
lutimes(atime, mtime, ...)
    SV *atime
    SV *mtime

  PREINIT:
    struct timeval tv[2];
    struct timeval *tvp;
    int i;

  CODE:
#ifdef HAVE_LUTIMES
    if(!SvOK(atime) && !SvOK(mtime))
      tvp = NULL;
    else {
      tv[0].tv_sec  = SvUV(atime);
      tv[0].tv_usec = 0;

      tv[1].tv_sec  = SvUV(mtime);
      tv[1].tv_usec = 0;

      tvp = tv;
    }

    RETVAL = 0;

    for(i = 2; i < items; i++) {
      char *path = SvPV_nolen(ST(i));
      if(lutimes(path, tvp) == 0)
        RETVAL++;
    }
#else
    croak("lutimes() not implemented");
#endif

  OUTPUT:
    RETVAL
