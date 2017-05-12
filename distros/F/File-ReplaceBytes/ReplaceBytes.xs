#include <sys/types.h>

#include <stdlib.h>
#include <unistd.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

MODULE = File::ReplaceBytes             PACKAGE = File::ReplaceBytes            

ssize_t
pread(PerlIO *fh, SV *buf, ...)
  PROTOTYPE: $$$;$
  PREINIT:
    off_t offset = 0;
    STRLEN len   = 0;

  CODE:
    if( items > 2 ) {
        if (!SvIOK(ST(2)) || SvIV(ST(2)) < 0) {
            errno = EINVAL;
            XSRETURN_IV(-1);
        }
        len = SvIV(ST(2));
    }
/* emulate pread not complaining if nothing to read */
    if (len == 0)
        XSRETURN_IV(0);
    if( items > 3 ) {
        if (!SvIOK(ST(3)) || SvIV(ST(3)) < 0) {
            errno = EINVAL;
            XSRETURN_IV(-1);
        }
        offset = SvIV(ST(3));
    }

    if(!SvOK(buf)) 
        sv_setpvs(buf, "");

    RETVAL = pread(PerlIO_fileno(fh), SvGROW(buf, len), len, offset);
    if (RETVAL > 0) {
        SvCUR_set(buf, RETVAL);
        SvTAINTED_on(buf);
    } else {
        SvCUR_set(buf, 0);
    }

  OUTPUT:
    buf
    RETVAL

ssize_t
pwrite(PerlIO *fh, SV *buf, ...)
  PROTOTYPE: $$;$$
  PREINIT:
    char *bp;
    off_t offset = 0;
    STRLEN len = 0;
    STRLEN userlen = 0;

  CODE:
/* pwrite(2) does not complain if nothing to write, so emulate that */
    if(!SvOK(buf) || SvCUR(buf) == 0)
        XSRETURN_IV(0);
/* length, offset are optional, but offset demands that length also be
 * set by the caller */
    if( items > 2 ) {
        if (!SvIOK(ST(2)) || SvIV(ST(2)) < 0) {
            errno = EINVAL;
            XSRETURN_IV(-1);
        }
        userlen = SvIV(ST(2));
    }
    if( items > 3 ) {
        if (!SvIOK(ST(3)) || SvIV(ST(3)) < 0) {
            errno = EINVAL;
            XSRETURN_IV(-1);
        }
        offset = SvIV(ST(3));
    }

    bp = SvPV(buf, len);
    if (userlen == 0 || userlen > len)
        userlen = len;
    RETVAL = pwrite(PerlIO_fileno(fh), bp, userlen, offset);

  OUTPUT:
    RETVAL

ssize_t
replacebytes(SV *filename, SV *buf, ...)
  PROTOTYPE: $$;$
  PREINIT:
    char *bp;
    int fd, i;
    off_t offset = 0;
    STRLEN len;

  CODE:
    if(!SvOK(buf) || SvCUR(buf) == 0)
        XSRETURN_IV(0);
    if( items > 2 ) {
        if (!SvIOK(ST(2)) || SvIV(ST(2)) < 0) {
            errno = EINVAL;
            XSRETURN_IV(-1);
        }
        offset = SvIV(ST(2));
    }

    /* as otherwise a filename of "bar\0foo" results in a "bar" file which
     * is not the same as what was input */
    bp = SvPV(filename, len);
    for (i = 0; i < len; i++) {
        if (bp[i] == '\0') {
            errno = EINVAL;
            XSRETURN_IV(-1);
        }
    }

    if((fd = open(SvPV_nolen(filename), O_CREAT|O_WRONLY, 0666)) == -1)
        XSRETURN_IV(-1);

    bp = SvPV(buf, len);
    RETVAL = pwrite(fd, bp, len, offset);

    close(fd);

  OUTPUT:
    RETVAL
