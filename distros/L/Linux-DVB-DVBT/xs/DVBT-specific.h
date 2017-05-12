/*---------------------------------------------------------------------------------------------------*/
#include <linux/dvb/frontend.h>
#include <linux/dvb/dmx.h>

#include "dvb_lib.h"
#include "ts_structs.h"

#define DEFAULT_TIMEOUT		900

// If large file support is not included, then make the value do nothing
#ifndef O_LARGEFILE
#define O_LARGEFILE	0
#endif

/*---------------------------------------------------------------------------------------------------*/

static int DVBT_DEBUG = 0 ;


static int bw[16] = {
	[ 0 ... 15 ] = 0,
	[ BANDWIDTH_AUTO  ] = 0,
	[ BANDWIDTH_8_MHZ ] = 8,
	[ BANDWIDTH_7_MHZ ] = 7,
	[ BANDWIDTH_6_MHZ ] = 6,
    };
static int co_t[16] = {
	[ 0 ... 15 ] = 0,
	[ QAM_AUTO ] = 0,
	[ QPSK     ] = 0,
	[ QAM_16   ] = 16,
	[ QAM_32   ] = 32,
	[ QAM_64   ] = 64,
	[ QAM_128  ] = 128,
	[ QAM_256  ] = 256,
    };
static int hi[16] = {
	[ 0 ... 15 ] = 0,
	[ HIERARCHY_AUTO ] = 0,
	[ HIERARCHY_NONE ] = 0,
	[ HIERARCHY_1 ]    = 1,
	[ HIERARCHY_2 ]    = 2,
	[ HIERARCHY_4 ]    = 3,
    };
static int ra_t[16] = {
	[ 0 ... 15 ] = 0,
	[ FEC_AUTO ] = 0,
	[ FEC_NONE ] = 0,
	[ FEC_1_2  ] = 12,
	[ FEC_2_3  ] = 23,
	[ FEC_3_4  ] = 34,
	[ FEC_4_5  ] = 45,
	[ FEC_5_6  ] = 56,
	[ FEC_6_7  ] = 67,
	[ FEC_7_8  ] = 78,
	[ FEC_8_9  ] = 89,
    };
static int gu[16] = {
	[ 0 ... 15 ] = 0,
	[ GUARD_INTERVAL_AUTO ] = 0,
	[ GUARD_INTERVAL_1_4  ] = 4,
	[ GUARD_INTERVAL_1_8  ] = 8,
	[ GUARD_INTERVAL_1_16 ] = 16,
	[ GUARD_INTERVAL_1_32 ] = 32,
    };
static int tr[16] = {
	[ 0 ... 15 ] = 0,
	[ TRANSMISSION_MODE_AUTO ] = 0,
	[ TRANSMISSION_MODE_2K   ] = 2,
	[ TRANSMISSION_MODE_8K   ] = 8,
    };


