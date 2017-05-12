/*
 * dvb_error.h
 *
 *  Created on: 17 May 2010
 *      Author: sdprice1
 */

#ifndef DVB_ERROR_H_
#define DVB_ERROR_H_


// Set the global error code
#define SET_DVB_ERROR(err)	\
{ \
	dvb_error_code = (enum DVB_error)err ; \
	dvb_errno = errno ; \
}

// set global error code then return value
#define RETURN_DVB_ERROR(err)	\
SET_DVB_ERROR(err); \
return (dvb_error_code) ;

// Set a value AND set the error code alongside it
#define SET_ERROR(val, err)	\
{ \
	(val) = (int)err ; \
	SET_DVB_ERROR(err) ; \
}



// Error groups (top bits)
#define ERR_GRP_SIZE	0x10
enum DVB_error_group {

	ERR_GRP_NONE			= 0x00,

	ERR_GRP_PARAM			= (ERR_GRP_SIZE*1),		// calling parameter errors
	ERR_GRP_PARAM_START		= (ERR_GRP_SIZE*1)+ERR_GRP_SIZE-1,

	// 2

	ERR_GRP_DEVICE			= (ERR_GRP_SIZE*3),		// dvb device-specific errors
	ERR_GRP_DEVICE_START	= (ERR_GRP_SIZE*3)+ERR_GRP_SIZE-1,

	ERR_GRP_TUNING			= (ERR_GRP_SIZE*4),		// dvb tuning-specific errors
	ERR_GRP_TUNING_START	= (ERR_GRP_SIZE*4)+ERR_GRP_SIZE-1,

	ERR_GRP_EPG				= (ERR_GRP_SIZE*5),		// dvb epg-specific errors
	ERR_GRP_EPG_START		= (ERR_GRP_SIZE*5)+ERR_GRP_SIZE-1,

	ERR_GRP_SCAN			= (ERR_GRP_SIZE*6),		// dvb scan-specific errors
	ERR_GRP_SCAN_START		= (ERR_GRP_SIZE*6)+ERR_GRP_SIZE-1,

	// 7,8,9

	ERR_GRP_FILE			= (ERR_GRP_SIZE*10),		// file-specific errors
	ERR_GRP_FILE_START		= (ERR_GRP_SIZE*10)+ERR_GRP_SIZE-1,

	ERR_GRP_ACCESS			= (ERR_GRP_SIZE*11),		// file/device access
	ERR_GRP_ACCESS_START	= (ERR_GRP_SIZE*11)+ERR_GRP_SIZE-1,

	ERR_GRP_DATA			= (ERR_GRP_SIZE*12),		// Error with the decoded data
	ERR_GRP_DATA_START		= (ERR_GRP_SIZE*13)+ERR_GRP_SIZE-1,

	// 13,14

	ERR_GRP_INT				= (ERR_GRP_SIZE*15),		// Internal errors
	ERR_GRP_INT_START		= (ERR_GRP_SIZE*15)+ERR_GRP_SIZE-1,
} ;


// ERRORS (stored as -ve to distinguish then from valid return values/file handles etc)
enum DVB_error {
	ERR_MAX				= -255,

	ERR_BUFFER_ZERO		= -ERR_GRP_INT_START,
	ERR_INVALID_ERR,
	ERR_MALLOC,
	ERR_IOCTL,
	ERR_GENERIC,

	ERR_NOSYNC			= -ERR_GRP_DATA_START,
	ERR_BADSYNC,
	ERR_TSERR,
	ERR_SECTIONLEN,
	ERR_PESHEAD,
	ERR_TSCORRUPT,

	ERR_READ			= -ERR_GRP_ACCESS_START,
	ERR_SELECT,
	ERR_TIMEOUT,
	ERR_EOF,
	ERR_OVERFLOW,

	ERR_FILE			= -ERR_GRP_FILE_START,
	ERR_FILE_SEEK,
	ERR_FILE_NO_PKTS,
	ERR_FILE_ZERO,

	ERR_EPG_POLL		= -ERR_GRP_EPG_START,

	ERR_TUNING_TIMEOUT	= -ERR_GRP_TUNING_START,
	ERR_TUNING_TIMEOUT0,

	ERR_DVB_DEV			= -ERR_GRP_DEVICE_START,
	ERR_DVR_OPEN,
	ERR_FE_OPEN,
	ERR_DEMUX_OPEN,
	ERR_SET_PES_FILTER,
	ERR_REQ_SECTION,

	ERR_DURATION		= -ERR_GRP_PARAM_START,
	ERR_INVALID_TSREADER,

	ERR_NONE			= ERR_GRP_NONE,
} ;

// DVB-generated error code
extern enum DVB_error dvb_error_code ;

// copy of errno
extern int dvb_errno ;

char *dvb_error_str(enum DVB_error) ;
void dvb_error_clear() ;

#endif /* DVB_ERROR_H_ */
