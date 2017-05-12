/*
 * parse_desc_stream_identifier.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_STREAM_IDENTIFIER_H_
#define PARSE_DESC_STREAM_IDENTIFIER_H_

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

// stream_identifier_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  component_tag  8 uimsbf
// }

struct Descriptor_stream_identifier {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned component_tag ;                          	   // 8 bits
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_stream_identifier(struct Descriptor_stream_identifier *sid, int level) ;
struct Descriptor *parse_stream_identifier(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_stream_identifier(struct Descriptor_stream_identifier *sid) ;

#endif /* PARSE_DESC_STREAM_IDENTIFIER_H_ */

