#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

// readv/writev
#include <sys/uio.h>

// errno/EINTR
#include <errno.h>

// IOV_MAX
#include <limits.h>

#ifndef IOV_MAX
#  ifdef UIO_MAXIOV
#    define IOV_MAX UIO_MAXIOV
#  endif
#endif

#ifndef IOV_MAX
#  error "Unable to determine IOV_MAX from system headers"
#endif



MODULE = IO::Vectored		PACKAGE = IO::Vectored

PROTOTYPES: ENABLE


unsigned long
_backend(fileno, is_write, ...)
        int fileno
        int is_write
    CODE:
        ssize_t rv;
        int iovcnt;

        if (items < 3) croak("need more arguments to %s", is_write ? "syswritev" : "sysreadv");

        iovcnt = items - 2;
        if (iovcnt > IOV_MAX) croak("too many arguments to %s", is_write ? "syswritev" : "sysreadv");

        {
          struct iovec v[iovcnt]; // Needs C99 compiler
          SV *item;
          int i;
          size_t len;

          for(i=0; i<iovcnt; i++) {
            item = ST(2 + i);

            if (!is_write && SvREADONLY(item)) croak("Can't modify constant item in sysreadv"); 

            SvUPGRADE(item, SVt_PV);
            if (!SvPOK(item) && !SvIOK(item) && !SvNOK(item))
              croak("non-string object passed to %s", is_write ? "syswritev" : "sysreadv");
            SvPV_nolen(item);

            v[i].iov_len = len = SvCUR(item);
            if (is_write) {
              v[i].iov_base = SvPV(item, len);
            } else {
              v[i].iov_base = SvPV_force(item, len);
            }
          }

          again:

          if (is_write) {
            rv = writev(fileno, &v[0], iovcnt);
          } else {
            rv = readv(fileno, &v[0], iovcnt);
          }

          if (rv < 0 && errno == EINTR) goto again;
        }

        if (rv < 0) XSRETURN_UNDEF;

        RETVAL = (unsigned long) rv;
    OUTPUT:
        RETVAL


int
_get_iov_max()
    CODE:
        RETVAL = IOV_MAX;
    OUTPUT:
        RETVAL
