/*
 * parse_desc_partial_transport_stream.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_PARTIAL_TRANSPORT_STREAM_H_
#define PARSE_DESC_PARTIAL_TRANSPORT_STREAM_H_

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

// partial_transport_stream_descriptor() {
//  descriptor_tag  8 bslbf
//  descriptor_length  8 uimsbf
//  DVB_reserved_future_use  2 bslbf
//  peak_rate  22 uimsbf
//  DVB_reserved_future_use  2 bslbf
//  minimum_overall_smoothing_rate  22 uimsbf
//  DVB_reserved_future_use  2 bslbf
//  maximum_overall_smoothing_buffer  14 uimsbf
// }

struct Descriptor_partial_transport_stream {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned peak_rate ;                              	   // 22 bits
	unsigned minimum_overall_smoothing_rate ;         	   // 22 bits
	unsigned maximum_overall_smoothing_buffer ;       	   // 14 bits
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_partial_transport_stream(struct Descriptor_partial_transport_stream *ptsd, int level) ;
struct Descriptor *parse_partial_transport_stream(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_partial_transport_stream(struct Descriptor_partial_transport_stream *ptsd) ;

#endif /* PARSE_DESC_PARTIAL_TRANSPORT_STREAM_H_ */

