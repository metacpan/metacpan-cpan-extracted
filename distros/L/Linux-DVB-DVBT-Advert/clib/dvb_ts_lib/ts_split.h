/*
 * ts_split.h
 *
 *  Created on: 25 Jan 2011
 *      Author: sdprice1
 */

#ifndef TS_SPLIT_H_
#define TS_SPLIT_H_

#include "ts_skip.h"

//---------------------------------------------------------------------------------------------------------
int ts_split(char *filename, char *ofilename, struct list_head *cuts_array, unsigned debug);


#endif /* TS_SPLIT_H_ */
