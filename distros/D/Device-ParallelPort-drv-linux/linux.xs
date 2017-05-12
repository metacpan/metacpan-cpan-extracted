#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/stat.h>
#include <sys/sysmacros.h>
#include <asm/io.h>

#include "linux.h"

#define LPSIZE 3

MODULE = Device::ParallelPort::drv::linux             PACKAGE = Device::ParallelPort::drv::linux            

int
linux_opendev(devname)
	INPUT:
		char *		devname
	CODE:
		int base, fd;
		struct stat s;
		base = 0x378;
		if (ioperm(base, LPSIZE, 1) < 0) {
			fprintf(stderr, "%s: ioperm:%s ", devname, strerror(errno));
			RETVAL = -1;
		} else {
			RETVAL = base;
		}
	OUTPUT:
		RETVAL

char
linux_read(base, offset)
	INPUT:
		int		base
		int		offset
	CODE:
		RETVAL = inb(base+offset);
	OUTPUT:
		RETVAL

void
linux_write(base, offset, val)
	INPUT:
		int		base
		int		offset
		char		val
	CODE:
		outb(val, base+offset);

