/*
 * ts_cut.h
 *
 *  Created on: 25 Jan 2011
 *      Author: sdprice1
 */

#ifndef TS_CUT_H_
#define TS_CUT_H_

#include "ts_skip.h"


//---------------------------------------------------------------------------------------------------------
int ts_cut(char *filename, char *ofilename, struct list_head *cuts_array, unsigned debug);


#endif /* TS_CUT_H_ */
