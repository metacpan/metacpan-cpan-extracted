#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "google/coredumper.h"

typedef int fd_t;

STATIC SV *
handle_from_fd (fd_t fd)
{
	SV *ret;
	int count;
	dSP;

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);
	EXTEND (SP, 3);
	PUSHs (newSVpvs ("IO::Handle"));
	mPUSHi (fd);
	PUSHs (newSVpvs ("r"));
	PUTBACK;

	count = call_method ("new_from_fd", G_SCALAR);

	SPAGAIN;

	if (count != 1) {
		croak ("IO::Handle->new_from_fd didn't return a single scalar");
	}

	ret = POPs;
	SvREFCNT_inc (ret);

	PUTBACK;
	FREETMPS;
	LEAVE;

	return ret;
}

MODULE = Devel::CoreDump  PACKAGE = Devel::CoreDump

PROTOTYPES: DISABLE

fd_t
get (class)
	CODE:
		RETVAL = GetCoreDump ();
	POSTCALL:
		if (RETVAL < 0) {
			croak ("failed to get coredump: %s", strerror (errno));
		}
	OUTPUT:
		RETVAL

void
write (class, filename)
		const char *filename
	PREINIT:
		int ret;
	CODE:
		ret = WriteCoreDump (filename);
	POSTCALL:
		if (ret < 0) {
			croak ("failed to write coredump: %s", strerror (errno));
		}
