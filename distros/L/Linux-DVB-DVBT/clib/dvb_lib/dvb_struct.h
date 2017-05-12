/*
 * dvb_struct.h
 *
 *  Created on: 14 Apr 2011
 *      Author: sdprice1
 */

#ifndef DVB_STRUCT_H_
#define DVB_STRUCT_H_

/*=============================================================================================*/
// USES
/*=============================================================================================*/
#include <linux/dvb/frontend.h>
#include <linux/dvb/dmx.h>

#include "list.h"

/*=============================================================================================*/
// CONSTANTS
/*=============================================================================================*/

/*=============================================================================================*/
// MACROS
/*=============================================================================================*/

/*=============================================================================================*/
// STRUCTS
/*=============================================================================================*/

typedef struct demux_filter {
    int                              fd;
    struct dmx_pes_filter_params     filter;
} Demux_filter ;

typedef struct dvb_state {
    /* device file names */
    char                             frontend[32];
    char                             demux[32];
    char                             dvr[32];

    /* frontend */
    int                              fdro;
    int                              fdwr;
    int								 dvro;

    struct dvb_frontend_info         info;
    struct dvb_frontend_parameters   p;
    struct dvb_frontend_parameters   plast;

    /* demux */
    struct demux_filter              audio;
    struct demux_filter              video;
} DVB ;


struct devinfo {
    struct list_head    next;
    char  device[512];
    int adapter_num ;
    int frontend_num ;
    char  name[512];
    char  bus[512];
    int   flags;

	fe_type_t  type;
	__u32      frequency_min;
	__u32      frequency_max;
	__u32      frequency_stepsize;
	__u32      frequency_tolerance;
	__u32      symbol_rate_min;
	__u32      symbol_rate_max;
	__u32      symbol_rate_tolerance;	/* ppm */
};

#endif /* DVB_STRUCT_H_ */
