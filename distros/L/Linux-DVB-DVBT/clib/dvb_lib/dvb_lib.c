#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>
#include <fcntl.h>
#include <inttypes.h>
#include <signal.h>
#include <sys/time.h>
#include <sys/ioctl.h>
#include <sys/poll.h>
#include <sys/types.h>

// for statvfs
#include <sys/statvfs.h>

#include "dvb_lib.h"

#define DVB_LIB_VER		"2.00"

static void adapter_name(int adap, char *adapter_name, int len) ;
static void frontend_name(int frontend, char *frontend_name, int len, char *adapter_name) ;
static void dvr_name(int dvr, char *dvr_name, int len, char *adapter_name) ;
static void demux_name(int demux, char *demux_name, int len, char *adapter_name) ;


/* ----------------------------------------------------------------------- */
static void adapter_name(int adap, char *adapter_name, int len)
{
	snprintf(adapter_name,len,"/dev/dvb/adapter%d", adap);
}

/* ----------------------------------------------------------------------- */
static void frontend_name(int frontend, char *frontend_name, int len, char *adapter_name)
{
	snprintf(frontend_name,len,"%s/frontend%d", adapter_name, frontend);
}

/* ----------------------------------------------------------------------- */
static void dvr_name(int dvr, char *dvr_name, int len, char *adapter_name)
{
	snprintf(dvr_name,len,"%s/dvr%d", adapter_name, dvr);
}

/* ----------------------------------------------------------------------- */
static void demux_name(int demux, char *demux_name, int len, char *adapter_name)
{
	snprintf(demux_name,len,"%s/demux%d", adapter_name, demux);
}

/* ----------------------------------------------------------------------- */
// Creates an info struct if this is a valid frontend, otherwise returns NULL
struct devinfo * dvb_probe_frontend(unsigned adap, unsigned fe, int debug)
{
struct dvb_frontend_info feinfo;
char adapter[512];
char device[512];
struct devinfo *info = NULL ;
int fd;

if (debug)
{
	fprintf(stderr, "dvb_probe_frontend(%u, %u)\n", adap, fe) ;
}

	adapter_name(adap, adapter, sizeof(adapter));
	frontend_name(fe, device, sizeof(device), adapter) ;
	fd = open(device, O_RDONLY | O_NONBLOCK);
if (debug)
{
	fprintf(stderr, " + adapter %s, device %s : fd %d (errno %d)\n", adapter, device, fd, errno) ;
	if (fd < 0)
	{
		perror("Failed to open device") ;
	}
}

	if (-1 == fd)
		return info ;

	if (-1 == ioctl(fd, FE_GET_INFO, &feinfo)) {
		if (debug)
			perror("ioctl FE_GET_INFO");
		close(fd);
		return info ;
	}

	if (debug)
	{
		fprintf(stderr, " + got FE_GET_INFO\n", adap, fe) ;
	}

	info = (struct devinfo *)malloc(sizeof(struct devinfo));
	memset(info,0,sizeof(struct devinfo));
	strncpy(info->device, adapter, sizeof(info->device));
	strncpy(info->name, feinfo.name, sizeof(info->name));
	info->adapter_num = adap ;
	info->frontend_num = fe ;
	info->flags = (int)feinfo.caps ;

	// extra
	info->type = feinfo.type ;
	info->frequency_min = feinfo.frequency_min ;
	info->frequency_max = feinfo.frequency_max ;
	info->frequency_stepsize = feinfo.frequency_stepsize ;
	info->frequency_tolerance = feinfo.frequency_tolerance ;
	info->symbol_rate_min = feinfo.symbol_rate_min ;
	info->symbol_rate_max = feinfo.symbol_rate_max ;
	info->symbol_rate_tolerance = feinfo.symbol_rate_tolerance ;

	close(fd);

if (debug)
{
	fprintf(stderr, " + end of probe\n") ;
}

    return info;
}



/*----------------------------------------------------------------------
 Portable function to set a socket into nonblocking mode.
 Calling this on a socket causes all future read() and write() calls on
 that socket to do only as much as they can immediately, and return
 without waiting.
 If no data can be read or written, they return -1 and set errno
 to EAGAIN (or EWOULDBLOCK).
 Thanks to Bjorn Reese for this code.
----------------------------------------------------------------------*/
int setNonblocking(int fd)
{
    int flags;

    /* If they have O_NONBLOCK, use the Posix way to do it */
#if defined(O_NONBLOCK)
    /* Fixme: O_NONBLOCK is defined but broken on SunOS 4.1.x and AIX 3.2.5. */
    if (-1 == (flags = fcntl(fd, F_GETFL, 0)))
        flags = 0;
    return fcntl(fd, F_SETFL, flags | O_NONBLOCK);
#else
    /* Otherwise, use the old way of doing it */
    flags = 1;
    return ioctl(fd, FIOBIO, &flags);
#endif
}


//---------------------------------------------------------------------
// Use statvfs to return the free space for the disk that contains the
// specified path.
//
// NOTE: To work, the path (file or directory) *MUST* exist!
//
unsigned long long get_free_space(const char *path)
{
	unsigned long long result = 0;
	struct statvfs sfs;
	if ( statvfs (path, &sfs) != -1 )
	{
		result = (unsigned long long)sfs.f_bsize * sfs.f_bfree;
	}
	return result;
}
