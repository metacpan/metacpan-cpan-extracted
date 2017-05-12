/* ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42)
 * <tobez@catpipe.net> wrote this file.  As long as you retain this notice you
 * can do whatever you want with this stuff. If we meet some day, and you think
 * this stuff is worth it, you can buy me a beer in return.   Anton Berezin
 * ----------------------------------------------------------------------------
 *
 * $Id: Dirfd.xs,v 1.1.1.1 2001/11/21 17:30:15 tobez Exp $
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* dirfd definitions */
#include <sys/types.h>
#include <dirent.h>

MODULE = IO::Dir::Dirfd		PACKAGE = IO::Dir::Dirfd	PREFIX = xs_

int
xs_dirfd(dirh)
	SV *dirh;
PROTOTYPE: *
PREINIT:
#if defined(Direntry_t)
	IO *io;
#endif
CODE:
{
#if !defined(Direntry_t)
	XSRETURN_UNDEF;
#else
	/* io = GvIOn(dirglob); */
	io = sv_2io(dirh);
	if (!io || !IoDIRP(io) || (RETVAL = dirfd(IoDIRP(io))) == -1) {
		if (!errno)
			SETERRNO(EBADF,RMS$_DIR);
		XSRETURN_UNDEF;
	}
#endif
}
OUTPUT:
	RETVAL
