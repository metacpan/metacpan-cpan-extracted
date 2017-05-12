
#ifdef  __MINGW32__
#ifndef __USE_MINGW_ANSI_STDIO
#define __USE_MINGW_ANSI_STDIO 1
#endif
#endif

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


SV * win32_fmode(pTHX_  FILE *stream ) {

#ifdef _WIN32
/*
 * Win32 code supplied by BrowserUK
 * to work aroumd the MS C runtime library's
 * lack of a function to retrieve the file mode
 * used when a file is opened
*/
  return newSViv(stream->_flag);
#else
  croak("win32_fmode function works only with Win32");
#endif
}

#ifdef PERL580_OR_LATER

/*
 * XS code to deal with filehandles
 * attached to memory objects supplied
 * by attn.steven.kuo. (Applies only
 * to perl 5.8 and later.)
*/

#include <perliol.h>
#endif

SV * perliol_readable(pTHX_ SV * handle) {
#ifdef PERL580_OR_LATER
     IV flags;
     IO *io;
     PerlIO *f;
     io = sv_2io(handle);
     f  = IoIFP(io);
     if(PerlIOValid(f)){
       flags = PerlIOBase(f)->flags;
       if(flags & PERLIO_F_CANREAD) return newSVuv(1);
       return newSVuv(0);
     }
     croak("Couldn't validate the filehandle passed to perliol_readable");
#else
     croak("perliol_readable function works only with perl 5.8 or later");
#endif
}

SV * perliol_writable(pTHX_ SV * handle) {
#ifdef PERL580_OR_LATER
     IV flags;
     IO *io;
     PerlIO *f;
     io = sv_2io(handle);
     f  = IoIFP(io);
     if(PerlIOValid(f)){
       flags = PerlIOBase(f)->flags;
       if(flags & PERLIO_F_CANWRITE) return newSVuv(1);
       return newSVuv(0);
     }
     croak("Couldn't validate the filehandle passed to perliol_writable");
#else
     croak("perliol_writable function works only with perl 5.8 or later");
#endif
}

SV * is_appendable(pTHX_ SV * handle) {
#ifdef PERL561_OR_LATER
     IO *io;
     io = sv_2io(handle);
     if (IoTYPE(io) == IoTYPE_APPEND) return newSVuv(1);
     return newSVuv(0);
#else
     croak("is_appendable function implemented only with perl 5.6.1 or later");
#endif
}

MODULE = FileHandle::Fmode  PACKAGE = FileHandle::Fmode

PROTOTYPES: DISABLE


SV *
win32_fmode (stream)
	FILE *	stream
CODE:
  RETVAL = win32_fmode (aTHX_ stream);
OUTPUT:  RETVAL

SV *
perliol_readable (handle)
	SV *	handle
CODE:
  RETVAL = perliol_readable (aTHX_ handle);
OUTPUT:  RETVAL

SV *
perliol_writable (handle)
	SV *	handle
CODE:
  RETVAL = perliol_writable (aTHX_ handle);
OUTPUT:  RETVAL

SV *
is_appendable (handle)
	SV *	handle
CODE:
  RETVAL = is_appendable (aTHX_ handle);
OUTPUT:  RETVAL

