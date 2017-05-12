#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <perliol.h>

#include "ppport.h"

#define CanRead(f) (PerlIOBase(f)->flags & PERLIO_F_CANREAD)

#define undef (&PL_sv_undef)

MODULE = IO::Handle::unread	PACKAGE = IO::Handle

PROTOTYPES: DISABLE

IV
unread(filehandle, string, length = undef)
	SV* filehandle
	SV* string
	SV* length
PREINIT:
	PerlIO* f;
	IO* io = sv_2io(filehandle); /* doesn't return NULL */
INIT:
	RETVAL = -1;
CODE:
	if((f = IoIFP(io)) && PerlIOValid(f) && CanRead(f)){
		STRLEN len;
		const char* pv = SvPV_const(string, len);

		if(SvOK(length)){
			UV uv;
			if(looks_like_number(length) && SvIV(length) < 0)
				Perl_croak(aTHX_ "Negative length");

			uv = SvUV(length);
			if(uv < len){
				len = uv;
			}
		}

		RETVAL = PerlIO_unread(f, pv, len);
	}
	else {
		if(ckWARN(WARN_IO)){
			const char* msg =
				  (PerlIOValid(f) && !CanRead(f)) ? "FileHandle opened only for output"
				: IoTYPE(io) == IoTYPE_CLOSED     ? "unread() on closed filehandle"
				: "unread() on unopened filehandle";
					
			Perl_warner(aTHX_ packWARN(WARN_IO), msg);
		}
		SETERRNO(EBADF,RMS_IFI);
		XSRETURN_EMPTY;
	}
OUTPUT:
	RETVAL
