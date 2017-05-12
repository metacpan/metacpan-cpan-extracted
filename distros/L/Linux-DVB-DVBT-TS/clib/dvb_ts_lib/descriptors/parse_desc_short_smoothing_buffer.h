/*
 * parse_desc_short_smoothing_buffer.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_SHORT_SMOOTHING_BUFFER_H_
#define PARSE_DESC_SHORT_SMOOTHING_BUFFER_H_

/*=============================================================================================*/
// USES
/*=============================================================================================*/
#include "desc_structs.h"
#include "ts_structs.h"

/*=============================================================================================*/
// CONSTANTS
/*=============================================================================================*/

/*=============================================================================================*/
// MACROS
/*=============================================================================================*/

/*=============================================================================================*/
// STRUCTS
/*=============================================================================================*/

// short_smoothing_buffer_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  sb_size  2 uimsbf
//  sb_leak_rate  6 uimsbf
//  for (i=0;i<N;i++){
//   DVB_reserved  8 bslbf
//  }
// }

struct Descriptor_short_smoothing_buffer {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned sb_size ;                                	   // 2 bits
	unsigned sb_leak_rate ;                           	   // 6 bits
#define MAX_DVB_RESERVED_LEN 256
	unsigned DVB_reserved[MAX_DVB_RESERVED_LEN + 1] ;
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_short_smoothing_buffer(struct Descriptor_short_smoothing_buffer *ssbd, int level) ;
struct Descriptor *parse_short_smoothing_buffer(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_short_smoothing_buffer(struct Descriptor_short_smoothing_buffer *ssbd) ;

#endif /* PARSE_DESC_SHORT_SMOOTHING_BUFFER_H_ */

