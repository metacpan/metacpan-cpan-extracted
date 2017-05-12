/*
 * win_time.c
 *
 *  Created on: 27 Oct 2010
 *      Author: sdprice1
 */
#include "win_time.h"

int clock_gettime(int type, struct timespec *tp)
{
	tp->tv_sec = 0 ;
	tp->tv_nsec = 0 ;
	return 0 ;
}
