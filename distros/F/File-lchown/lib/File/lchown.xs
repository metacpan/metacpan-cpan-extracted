/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2007,2008,2025 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/time.h>
#include <unistd.h>

static void S_extract_timeval(pTHX_ struct timeval *tvp, SV *sv)
{
  if(SvNOK(sv)) {
    NV nv = SvNV(sv);
    tvp->tv_sec  = (long)nv;
    tvp->tv_usec = 1000000 * (nv - tvp->tv_sec);
  }
  else if(SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) {
    AV *av = (AV *)SvRV(sv);
    if(AvFILL(av) < 1)
      croak("Expected an ARRAY reference of at least 2 elements");
    tvp->tv_sec  = SvUV(*av_fetch(av, 0, 0));
    tvp->tv_usec = SvUV(*av_fetch(av, 1, 0));
  }
  else {
    tvp->tv_sec  = SvUV(sv);
    tvp->tv_usec = 0;
  }
}

MODULE = File::lchown    PACKAGE = File::lchown

int
lchown(int uid, int gid, ...)
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
lutimes(SV *atime, SV *mtime, ...)
  PREINIT:
    struct timeval tv[2];
    struct timeval *tvp;
    int i;

  CODE:
#ifdef HAVE_LUTIMES
    if(!SvOK(atime) && !SvOK(mtime))
      tvp = NULL;
    else {
      S_extract_timeval(aTHX_ &tv[0], atime);
      S_extract_timeval(aTHX_ &tv[1], mtime);
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
