/*
 * tspics.h
 *
 *  Created on: 27 Oct 2010
 *      Author: sdprice1
 */

#ifndef TSPICS_H_
#define TSPICS_H_

#include <stdint.h>

unsigned grab_pics(char *filename, unsigned start_pkt, unsigned start_framenum, unsigned num_frames, unsigned scale) ;
int grab_size(unsigned framenum) ;
int grab_width(unsigned framenum) ;
int grab_height(unsigned framenum) ;
unsigned char *grab_image(unsigned framenum) ;
void grab_free() ;
void grab_debug(unsigned set_debug, unsigned set_ts_debug) ;

#endif /* TSPICS_H_ */
