/*
 * parse_desc_transport_stream.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_TRANSPORT_STREAM_H_
#define PARSE_DESC_TRANSPORT_STREAM_H_

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

// transport_stream_descriptor(){
//  descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//  for (i=0;i<N;i++){
//   byte  8 uimsbf
//  }
// }

struct Descriptor_transport_stream {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
#define MAX_BYTE_LEN 256
	char byte[MAX_BYTE_LEN + 1] ;
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_transport_stream(struct Descriptor_transport_stream *tsd, int level) ;
struct Descriptor *parse_transport_stream(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_transport_stream(struct Descriptor_transport_stream *tsd) ;

#endif /* PARSE_DESC_TRANSPORT_STREAM_H_ */

