/*
 * ad_file.h
 *
 *  Created on: 18 Feb 2011
 *      Author: sdprice1
 */

#ifndef AD_FILE_H_
#define AD_FILE_H_

#include "config.h"
#include "ts_advert.h"

//---------------------------------------------------------------------------------------------------------------------------
// Read detect file
enum DVB_error detect_from_file(struct Ad_user_data *user_data, char *filename) ;

#endif /* AD_FILE_H_ */
