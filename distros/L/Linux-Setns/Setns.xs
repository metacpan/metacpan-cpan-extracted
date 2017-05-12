#ifndef __linux
#error "No linux. Compile aborted."
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include <sys/syscall.h>

#define CLONE_ALL 0

#ifndef setns
int setns(int fd, int nstype) {
	return syscall(SYS_setns, fd, nstype);
}
#endif

MODULE = Linux::Setns		PACKAGE = Linux::Setns

SV * setns_wrapper(path,nstype)
	SV *	path;
	int		nstype;
CODE:
	int fd = -1;
	int err = 2;
	fd = open(SvPV_nolen(path), O_RDONLY);
	if (fd == -1) {
		err = 2;
	} else {
		err = setns(fd, nstype);
	}
	RETVAL = newSVnv(err);
OUTPUT:
	RETVAL
