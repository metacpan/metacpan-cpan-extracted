/*
 * ts_bits.c
 *
 *  Created on: 2 Apr 2011
 *      Author: sdprice1
 */

// VERSION = 1.00

/*=============================================================================================*/
// USES
/*=============================================================================================*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>
#include <fcntl.h>
#include <inttypes.h>

#include "ts_bits.h"

/*=============================================================================================*/
// CONSTANTS
/*=============================================================================================*/

/*=============================================================================================*/
// MACROS
/*=============================================================================================*/

/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void bits_free(struct TS_bits **bits)
{
struct TS_bits *bp = *bits ;

	if (bp)
	{
		free(bp) ;
	}
	*bits = NULL ;
}

/* ----------------------------------------------------------------------- */
struct TS_bits *bits_new(uint8_t *src, unsigned src_len)
{
struct TS_bits *bp ;

	// create struct
	bp = (struct TS_bits *)malloc(sizeof(struct TS_bits)) ;
	memset(bp, 0, sizeof(*bp));

	// init
	bp->buff_ptr = src ;
	bp->buff_len = src_len ;
	bp->start_bit = 0 ;

	return bp ;
}




/* ----------------------------------------------------------------------- */
unsigned bits_get(struct TS_bits *bits, unsigned len)
{
unsigned int result = 0;
unsigned start_len = len + bits->start_bit ;
unsigned mask ;
int left_shift ;
unsigned byte = 0 ;

	if (len==0)
		return 0 ;

if (len > 32)
{
	fprintf(stderr, "BUGGER! Request for > 32 bits!\n") ;
	exit(1) ;
}

if (bits->buff_len <= 0)
{
	fprintf(stderr, "BUGGER! Gone past the end of the buffer!\n") ;
	exit(1) ;
}

	if (len == 32)
	{
		mask = 0xffffffff ;
	}
	else
	{
		mask = (1 << len) -1 ;
	}

	// We want to shift the "start" bit to the MS bit of the final length
	//
	// 0   s  7    - NOTE: start bit is numbered from MS = 0 to LS = 7
	// [  0   ]
	//
	//
	left_shift = (len-1) - (7-bits->start_bit) ;

	if (left_shift >= 0)
	{

		while (left_shift >= 0)
		{
			result |= bits->buff_ptr[byte++] << left_shift ;
			left_shift -= 8 ;
		}
	}
	if ((left_shift < 0) && (left_shift > -8))
	{
		result |= bits->buff_ptr[byte] >> -left_shift ;
	}

	result &= mask ;

	// update buffer
	bits->start_bit = start_len % 8 ;
	bits->buff_len -= start_len / 8 ;
	bits->buff_ptr += start_len / 8 ;

    return result;
}

/* ----------------------------------------------------------------------- */
void bits_skip(struct TS_bits *bits, unsigned len)
{
unsigned int result ;

	while (len > 32)
	{
		// chop into 32 bit chunkc
		result= bits_get(bits, 32) ;
		len -= 32 ;
	}
	result = bits_get(bits, len) ;
}

/* ----------------------------------------------------------------------- */
// Calculate the result of adding the offset to the current buffer length and return
// that result (clamping value to 0 min)
int bits_len_calc(struct TS_bits *bits, int offset)
{
	int len = bits->buff_len + offset ;
	if (len < 0) len = 0 ;
	return len ;
}


/* ----------------------------------------------------------------------- */
// Read the 16 bit MJD & 24 bit START then convert to time_t format
struct tm bits_get_mjd_time(struct TS_bits *bits)
{
struct tm tm;
int y2,m2,k;
int mjd, start ;

	mjd = bits_get(bits, 16) ;
	start = bits_get(bits, 24) ;

    memset(&tm,0,sizeof(tm));

    /* taken as-is from EN-300-486 */
    y2 = (int)((mjd - 15078.2) / 365.25);
    m2 = (int)((mjd - 14956.1 - (int)(y2 * 365.25)) / 30.6001);
    k  = (m2 == 14 || m2 == 15) ? 1 : 0;
    tm.tm_mday = mjd - 14956 - (int)(y2 * 365.25) - (int)(m2 * 30.6001);
    tm.tm_year = y2 + k + 1900;
    tm.tm_mon  = m2 - 1 - k * 12;

    /* time is bcd ... */
    tm.tm_hour  = ((start >> 20) & 0xf) * 10;
    tm.tm_hour += ((start >> 16) & 0xf);
    tm.tm_min   = ((start >> 12) & 0xf) * 10;
    tm.tm_min  += ((start >>  8) & 0xf);
    tm.tm_sec   = ((start >>  4) & 0xf) * 10;
    tm.tm_sec  += ((start)       & 0xf);

    return tm ;
}


#if 0
    fprintf(stderr,"mjd %d, time 0x%06x  =>  %04d-%02d-%02d %02d:%02d:%02d",
	    mjd, start,
	    tm.tm_year, tm.tm_mon, tm.tm_mday,
	    tm.tm_hour, tm.tm_min, tm.tm_sec);

    {
	char buf[16];

	strftime(buf,sizeof(buf),"%H:%M:%S",&tm);
	fprintf(stderr,"  =>  %s",buf);

	gmtime_r(&t,&tm);
	strftime(buf,sizeof(buf),"%H:%M:%S GMT",&tm);
	fprintf(stderr,"  =>  %s",buf);

	localtime_r(&t,&tm);
	strftime(buf,sizeof(buf),"%H:%M:%S %z",&tm);
	fprintf(stderr,"  =>  %s\n",buf);
    }
#endif

/* ----------------------------------------------------------------------- */
void bits_dump_indent(unsigned level)
{
unsigned i ;

	for (i=0; i < level; i++)
	{
		printf("  ") ;
	}
}

/* ----------------------------------------------------------------------- */
void bits_dump(char *name, unsigned *buff, unsigned length, unsigned level)
{
unsigned byte ;

	bits_dump_indent(level) ; printf("%s :\n", name) ;
	bits_dump_indent(level+1) ;
	for (byte=0; byte < length; ++byte)
	{
		if (byte % 32 == 0)
		{
			printf("%04x: ", byte) ;
		}
		printf("%02x ", buff[byte]) ;
		if (byte % 8 == 7)
		{
			printf(" - ") ;
		}
		if (byte % 32 == 31)
		{
			printf("\n") ;
			bits_dump_indent(level+1) ;
		}
	}
	printf("\n") ;
}

