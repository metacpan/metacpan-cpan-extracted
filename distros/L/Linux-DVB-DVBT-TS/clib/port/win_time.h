/*
 * win_time.h
 *
 *  Created on: 27 Oct 2010
 *      Author: sdprice1
 */

#ifndef WIN_TIME_H_
#define WIN_TIME_H_

typedef long time_t ;

struct timespec {
   time_t   tv_sec;        /* seconds */
   long     tv_nsec;       /* nanoseconds */
};
#define CLOCK_REALTIME	0

int clock_gettime(int type, struct timespec *tp);


#endif /* WIN_TIME_H_ */
