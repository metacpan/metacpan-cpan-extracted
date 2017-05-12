#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#undef NO_PERLIO
#ifndef PerlIO
#  define NO_PERLIO
#  ifdef USE_SFIO
#    define PerlIO             Sfio_t
#    define PerlIO_ungetc(f,c) sfungetc(f,c)
#  else
#    define PerlIO             FILE
#    define PerlIO_ungetc(f,c) ungetc(c,f)
#  endif
#endif

MODULE = IO::Unread  PACKAGE = IO::Unread

PROTOTYPES: ENABLE

BOOT:
#if PERLIO_LAYERS
    newCONSTSUB(NULL, "IO::Unread::HAVE_PERLIO_LAYERS", &PL_sv_yes);
#else
    newCONSTSUB(NULL, "IO::Unread::HAVE_PERLIO_LAYERS", &PL_sv_no);
#endif

SV *
_check_fh (SV *rv)
CODE:
    {
        GV *gv = (GV*)SvRV(rv);
        IO *io = GvIO(gv);
        
        if(!io)
            RETVAL = &PL_sv_undef;
        else if (IoTYPE(io) == IoTYPE_WRONLY) {
            const char *const name = 
                gv && isGV_with_GP(gv) ? GvENAME(gv) : NULL;
            Perl_warner(aTHX_ packWARN(WARN_IO), 
                "Filehandle %s opened only for output", name);
            RETVAL = &PL_sv_no;
        }
        else
            RETVAL = &PL_sv_yes;
    }
OUTPUT:
    RETVAL

IV
_PerlIO_unread (PerlIO *io, SV *str)
PROTOTYPE: *$
CODE:
#ifdef NO_PERLIO
    PERL_UNUSED_VAR(str);
    Perl_croak(aTHX_ "IO::Unread::_PerlIO_unread called in non-PerlIO perl");
#else
    {
        char *pv;
        STRLEN len;

        pv = SvPV(str, len);
        RETVAL = PerlIO_unread(io, pv, len);
        if (RETVAL == -1)
            XSRETURN_UNDEF;
    }
#endif
OUTPUT:
    RETVAL

char
_PerlIO_ungetc (PerlIO *io, char chr)
PROTOTYPE: *$
CODE:
    RETVAL = PerlIO_ungetc(io, chr);
    if (RETVAL == -1)
        XSRETURN_UNDEF;
OUTPUT:
    RETVAL
