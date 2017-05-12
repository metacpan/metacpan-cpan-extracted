/*
 * dvb_error.c
 *
 *  Created on: 28 Apr 2010
 *      Author: sdprice1
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>
//#include <fcntl.h>
//#include <inttypes.h>
//#include <sys/time.h>
//#include <sys/types.h>
//#include <sys/ioctl.h>

#include "dvb_error.h"

// ERRORS
enum DVB_error dvb_error_code = ERR_NONE ;
int dvb_errno = 0 ;

static char *DVB_ERRORS[256] = {
	[0 ... 255]	= "UNKNOWN",
	[-ERR_BUFFER_ZERO]		= "unexpected empty buffer",
	[-ERR_INVALID_ERR]		= "error code is outside valid range",
	[-ERR_MALLOC]			= "malloc error",
	[-ERR_IOCTL]			= "ioctl error",
	[-ERR_GENERIC]			= "general error",

	[-ERR_NOSYNC]			= "no sync byte found in transport stream",
	[-ERR_BADSYNC]			= "invalid sync byte found in transport stream",
	[-ERR_TSERR]			= "TS error flag set in transport stream",
	[-ERR_SECTIONLEN]		= "invalid PSI section length in transport stream",
	[-ERR_PESHEAD]			= "corrupted PES header in transport stream",
	[-ERR_TSCORRUPT]		= "corrupted transport stream",

	[-ERR_READ]				= "read error",
	[-ERR_SELECT]			= "error waiting for data",
	[-ERR_TIMEOUT]			= "timed out waiting for data",
	[-ERR_EOF]				= "unexpected EOF",
	[-ERR_OVERFLOW]			= "dvb buffer overflow",

	[-ERR_FILE]				= "file error",
	[-ERR_FILE_SEEK]		= "file seek error",
	[-ERR_FILE_NO_PKTS]		= "file no ts packets",
	[-ERR_FILE_ZERO]		= "file zero length",

	[-ERR_TUNING_TIMEOUT]	= "frontend tuning timed out",
	[-ERR_TUNING_TIMEOUT0]	= "frontend is not tuned (no timeout specified)",

	[-ERR_DVB_DEV]			= "DVB device error",
	[-ERR_DEMUX_OPEN]		= "DVB demux device busy",
	[-ERR_DVR_OPEN]			= "DVB recording device busy",
	[-ERR_FE_OPEN]			= "DVB frontend device busy",
	[-ERR_SET_PES_FILTER]	= "DVB unable to set PES filter",
	[-ERR_REQ_SECTION]		= "DVB unable to set section filter",

	[-ERR_DURATION]			= "invalid recording duration parameter",
	[-ERR_INVALID_TSREADER]	= "invalid tsreader structure",


	[-ERR_NONE]				= "no error",
} ;


/*=============================================================================================*/


/*=============================================================================================*/
// PUBLIC
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
// convert error code into a message string
char *dvb_error_str(enum DVB_error error)
{
static char error_str[256] ;

	// check range
	if ((error > 0) || (error < ERR_MAX))
	{
		sprintf(error_str, "%s %d .. %d (code = %d)", DVB_ERRORS[-ERR_INVALID_ERR], ERR_NONE, ERR_MAX, error) ;
		return error_str ;
	}

	// make code +ve
	error = -error ;

	// lookup
	if ( (dvb_error_code != ERR_NONE) && dvb_errno )
	{
		sprintf(error_str, "%s : %s", DVB_ERRORS[error], strerror(dvb_errno)) ;
	}
	else
	{
		sprintf(error_str, "%s", DVB_ERRORS[error]) ;
	}

	return error_str ;
}

/* ----------------------------------------------------------------------- */
// Clear errors
void dvb_error_clear()
{
	errno = 0 ;
	dvb_errno = 0 ;
	dvb_error_code = ERR_NONE ;
}

