#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/mman.h>
#include <sys/syscall.h>

#define die_sys(format) Perl_croak(aTHX_ format, strerror(errno))

static SV* S_io_fdopen(pTHX_ int fd, const char* classname, char type) {
	PerlIO* pio = PerlIO_fdopen(fd, "r");
	GV* gv = newGVgen(classname ? classname : "Linux::FD::Mem");
	SV* ret = newRV_noinc((SV*)gv);
	IO* io = GvIOn(gv);
	IoTYPE(io) = type;
	IoIFP(io) = pio;
	IoOFP(io) = pio;
	if (classname) {
		HV* stash = gv_stashpv(classname, FALSE);
		sv_bless(ret, stash);
	}
	return ret;
}
#define io_fdopen(fd, classname, type) S_io_fdopen(aTHX_ fd, classname, type)

MODULE = Linux::FD::Mem				PACKAGE = Linux::FD::Mem

SV*
new(classname, name)
	const char* classname;
	const char* name;
	PREINIT:
	int memfd;
	CODE:
	memfd = syscall(__NR_memfd_create, name, MFD_CLOEXEC);
	if (memfd < 0)
		die_sys("Couldn't open memfd: %s");
	RETVAL = io_fdopen(memfd, classname, '+');
	OUTPUT:
		RETVAL

