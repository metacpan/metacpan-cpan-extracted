#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <sys/types.h>
#include <sys/socket.h>

typedef PerlIO* InOutStream;
typedef int SysRet;

#ifndef PerlIO
#define PerlIO_fileno(f) fileno(f)
#endif

static Size_t aligned_cmsghdr_sz = 0;

struct Socket__MsgHdr {
    struct msghdr m;
    struct iovec io;
};

static void
hv_2msghdr(struct Socket__MsgHdr *mh, SV *thing)
{
    HV*     hash;
    SV **   svp;
    STRLEN  dlen;

    if (!thing || !sv_isa(thing, "IO::EventMux::Socket::MsgHdr"))
        croak("parameter not of type IO::EventMux::Socket::MsgHdr");
    
    hash = (HV*) SvRV(thing);

    Zero(mh, 1, struct Socket__MsgHdr);

    mh->m.msg_iov    = &mh->io;
    mh->m.msg_iovlen = 1;

    if (svp = hv_fetch(hash, "name", 4, FALSE)) {
        // If undefined, define it
        if(!SvOK(*svp)) {
            *svp = newSVpv("", 0);
        }
        mh->m.msg_name    = SvPV_force(*svp, dlen);
        mh->m.msg_namelen = dlen;
    }

    if (svp = hv_fetch(hash, "buf", 3, FALSE)) {
        // If undefined, define it
        if(!SvOK(*svp)) {
            *svp = newSVpv("", 0);
        }
        mh->io.iov_base = SvPV_force(*svp, dlen);
        mh->io.iov_len  = dlen;
    }

    if (svp = hv_fetch(hash, "control", 7, FALSE)) {
        // If undefined, define it
        if(!SvOK(*svp)) {
            *svp = newSVpv("", 0);
        }
        mh->m.msg_control    = SvPV_force(*svp, dlen);
        mh->m.msg_controllen = dlen;
    }

    if (svp = hv_fetch(hash, "flags", 5, FALSE)) {
        if(!SvOK(*svp)) {
            *svp = newSViv(0);
        }
        mh->m.msg_flags    = SvIV(*svp);
    }
}

MODULE = IO::EventMux::Socket::MsgHdr    PACKAGE = IO::EventMux::Socket::MsgHdr   PREFIX = smh_

SV *
smh_pack_cmsghdr(...)
    PROTOTYPE: $$$;@
    PREINIT:
        STRLEN len;
        STRLEN space;
        I32 i;
        struct cmsghdr *cm;
    CODE:
        space = 0;
        for (i=0; i<items; i+=3) {
            len = sv_len(ST(i+2));
            space += CMSG_SPACE(len);
        }
        RETVAL = newSV( space );
        SvPOK_on(RETVAL);
        SvCUR_set(RETVAL, space);

        cm = (struct cmsghdr *)SvPVX(RETVAL);
        
        for (i=0; i<items; i+=3) {
            len = sv_len(ST(i+2));
            cm->cmsg_len = CMSG_LEN(len);
            cm->cmsg_level = SvIV( ST(i) );
            cm->cmsg_type = SvIV( ST(i+1) );
            Copy(SvPVX(ST(i+2)), CMSG_DATA(cm), len, U8);
            cm = (struct cmsghdr *)((U8 *)cm + CMSG_SPACE( len ));
        }
    OUTPUT:
    RETVAL

void
smh_unpack_cmsghdr(cmsv)
    SV*     cmsv;
    INIT:
    struct msghdr dummy;
    struct cmsghdr *cm;
    STRLEN  len;
    PPCODE:
    dummy.msg_control    = (struct cmsghdr *) SvPV(cmsv, len);
    dummy.msg_controllen = len;

    if (!len)
        XSRETURN_EMPTY;

    cm = CMSG_FIRSTHDR(&dummy);
    for (; cm; cm = CMSG_NXTHDR(&dummy, cm)) {
       XPUSHs(sv_2mortal(newSViv(cm->cmsg_level)));
       XPUSHs(sv_2mortal(newSViv(cm->cmsg_type)));
       XPUSHs(sv_2mortal(newSVpvn(CMSG_DATA(cm),
                                 (cm->cmsg_len - aligned_cmsghdr_sz))));
    }

SysRet
smh_sendmsg(s, msg_hdr, flags = 0)
    InOutStream s;
    SV * msg_hdr;
    int flags;

    PROTOTYPE: $$;$
    PREINIT:
    struct Socket__MsgHdr mh;
    CODE:
    hv_2msghdr(&mh, msg_hdr);
    RETVAL = sendmsg(PerlIO_fileno(s), &mh.m, flags);
    OUTPUT:
    RETVAL

SysRet
smh_recvmsg(s, msg_hdr, flags = 0)
    InOutStream s;
    SV * msg_hdr;
    int flags;

    PROTOTYPE: $$;$
    PREINIT:
    struct Socket__MsgHdr mh;
    struct cmsghdr *cm;
        
    CODE:
    hv_2msghdr(&mh, msg_hdr);
    if ((RETVAL = recvmsg(PerlIO_fileno(s), &mh.m, flags)) >= 0) {
        SV**    svp;
        HV*     hsh;

        hsh = (HV*) SvRV(msg_hdr);

        if (svp = hv_fetch(hsh, "name", 7, FALSE))
            SvCUR_set(*svp, mh.m.msg_namelen);
        if (svp = hv_fetch(hsh, "buf", 3, FALSE))
            SvCUR_set(*svp, RETVAL);
        if (svp = hv_fetch(hsh, "control", 7, FALSE))
            SvCUR_set(*svp, mh.m.msg_controllen);
    }
    OUTPUT:
    RETVAL

BOOT:
    aligned_cmsghdr_sz = CMSG_LEN(0);
