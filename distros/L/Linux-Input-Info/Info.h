#ifndef _INPUT_H
#define _INPUT_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <linux/input.h>
#include <inttypes.h>
#include <sys/ioctl.h>




#ifdef __KERNEL__
#include <linux/time.h>
#include <linux/list.h>
#else
#include <sys/time.h>
#include <sys/ioctl.h>
#include <asm/types.h>
#endif


/*
 * Protocol version.
 */

#define EV_VERSION		0x010000

#define EV_MAX			0x1f

/*
 * IOCTLs (0x00 - 0x7f)
 */

struct input_id {
        __u16 bustype;
        __u16 vendor;
        __u16 product;
        __u16 version;
};

#define EVIOCGID		_IOR('E', 0x02, struct input_id)	/* get device ID */
#define EVIOCGVERSION           _IOR('E', 0x01, int)                    /* get driver version */
#define EVIOCGREP               _IOR('E', 0x03, int[2])                 /* get repeat settings */
#define EVIOCSREP               _IOW('E', 0x03, int[2])                 /* get repeat settings */
#define EVIOCGKEYCODE           _IOR('E', 0x04, int[2])                 /* get keycode */
#define EVIOCSKEYCODE           _IOW('E', 0x04, int[2])                 /* set keycode */

#define EVIOCGNAME(len)         _IOC(_IOC_READ, 'E', 0x06, len)         /* get device name */
#define EVIOCGPHYS(len)         _IOC(_IOC_READ, 'E', 0x07, len)         /* get physical location */
#define EVIOCGUNIQ(len)         _IOC(_IOC_READ, 'E', 0x08, len)         /* get unique identifier */

#define EVIOCGBIT(ev,len)	_IOC(_IOC_READ, 'E', 0x20 + ev, len)	/* get event bits */

#define BITFIELD uint32_t

#define BUS_PCI			0x01
#define BUS_ISAPNP		0x02
#define BUS_USB			0x03
#define BUS_HIL			0x04

#define BUS_ISA			0x10
#define BUS_I8042		0x11
#define BUS_XTKBD		0x12
#define BUS_RS232		0x13
#define BUS_GAMEPORT		0x14
#define BUS_PARPORT		0x15
#define BUS_AMIGA		0x16
#define BUS_ADB			0x17
#define BUS_I2C			0x18
#define BUS_HOST		0x19


char *BUS_NAME[] = {
	[ BUS_PCI          ] = "BUS_PCI",
	[ BUS_ISAPNP       ] = "BUS_ISAPNP",
	[ BUS_USB          ] = "BUS_USB",
	[ BUS_HIL          ] = "BUS_HIL",
	[ BUS_ISA          ] = "BUS_ISA",
	[ BUS_I8042        ] = "BUS_I8042",
	[ BUS_XTKBD        ] = "BUS_XTKBD",
	[ BUS_RS232        ] = "BUS_RS232",
	[ BUS_GAMEPORT     ] = "BUS_GAMEPORT",
	[ BUS_PARPORT      ] = "BUS_PARPORT",
	[ BUS_AMIGA        ] = "BUS_AMIGA",
	[ BUS_ADB          ] = "BUS_ADB",
	[ BUS_I2C          ] = "BUS_I2C",
	[ BUS_HOST         ] = "BUS_HOST",
};

static __inline__ int test_bit(int nr, BITFIELD * addr)
{
	BITFIELD mask;

	addr += nr >> 5;
	mask = 1 << (nr & 0x1f);
	return ((mask & *addr) != 0);
}


#endif /* _INPUT_H */
