#ifdef __cplusplus
extern "C" {
#endif

#define PERL_NO_GET_CONTEXT /* we want efficiency */
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef __cplusplus
} /* extern "C" */
#endif

#define NEED_newSVpvn_flags
#include "ppport.h"

#include <sys/types.h>
#define _GNU_SOURCE             /* See feature_test_macros(7) */
#include <sys/socket.h>

MODULE = Linux::Socket::Accept4    PACKAGE = Linux::Socket::Accept4

BOOT:
    HV* stash = gv_stashpvs("Linux::Socket::Accept4", GV_ADD);
    newCONSTSUB(stash, "SOCK_CLOEXEC", newSViv(SOCK_CLOEXEC));
    newCONSTSUB(stash, "SOCK_NONBLOCK", newSViv(SOCK_NONBLOCK));

PROTOTYPES: ENABLE

void
accept4(...)
PROTOTYPE: **$
PREINIT:
    GV *ngv;
    IO *gstio;
    IO *nstio;
    char namebuf[MAXPATHLEN];
    Sock_size_t len = sizeof namebuf;
    int fd;
PPCODE:
{
        if (items !=3) {
            croak("Usage: accept4(ngv, ggv, flags)");
        }
        switch (SvTYPE(ST(0))) {
            case SVt_PVIO:
            case SVt_PVGV:
            case SVt_PVLV:
                nstio = sv_2io(ST(0));
                break;
            case SVt_IV:
#if PERL_VERSION < 11
            case SVt_RV:
#endif
                if (SvROK(ST(0))) {
                    nstio = sv_2io(ST(0));
                    break;
                }
                /* fallbthrough */
            default: {
                GV *ngv = newGVgen("Linux::Socket::Accept4");
                GvIOp(ngv) = newIO();
                nstio = GvIO(ngv);
                sv_setsv(ST(0), sv_2mortal(newRV_inc((SV*)ngv)));
                /* stolen from IO::File's new_tmpfile() */
                (void)hv_delete(GvSTASH(ngv), GvNAME(ngv), GvNAMELEN(ngv), G_DISCARD);
                break;
            }
        }
        gstio = sv_2io(ST(1));
        int flags = SvIV(ST(2));

        if (!gstio || !IoIFP(gstio)) {
            goto nuts;
        }

        fd = accept4(PerlIO_fileno(IoIFP(gstio)), (struct sockaddr *) namebuf, &len, flags);

        if (fd < 0) {
            goto badexit;
        }
        if (IoIFP(ST(0))) {
            PerlIO_close(IoIFP(nstio));
        }
        IoIFP(nstio) = PerlIO_fdopen(fd, "r"SOCKET_OPEN_MODE);
        IoOFP(nstio) = PerlIO_fdopen(fd, "w"SOCKET_OPEN_MODE);
        IoTYPE(nstio) = IoTYPE_SOCKET;
        if (!IoIFP(nstio) || !IoOFP(nstio)) {
            if (IoIFP(nstio)) PerlIO_close(IoIFP(nstio));
            if (IoOFP(nstio)) PerlIO_close(IoOFP(nstio));
            if (!IoIFP(nstio) && !IoOFP(nstio)) PerlLIO_close(fd);
            goto badexit;
        }

        ST(0) = sv_2mortal(newSVpvn(namebuf, len));
        XSRETURN(1);

    nuts:
        /* report_evil_fh(ggv); */
        SETERRNO(EBADF,SS_IVCHAN);

    badexit:
        XSRETURN_UNDEF;
}


