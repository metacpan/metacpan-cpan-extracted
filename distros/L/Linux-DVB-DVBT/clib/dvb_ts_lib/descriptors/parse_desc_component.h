/*
 * parse_desc_component.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_COMPONENT_H_
#define PARSE_DESC_COMPONENT_H_

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

// component_descriptor(){
//  descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//  reserved_future_use  4 bslbf
//  stream_content  4 uimsbf
//  component_type  8 uimsbf
//  component_tag  8 uimsbf
//  ISO_639_language_code   24 bslbf
//  for (i=0;i<N;i++){
//   text_char  8 uimsbf
//  }
// }

struct Descriptor_component {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned stream_content ;                         	   // 4 bits
	unsigned component_type ;                         	   // 8 bits
	unsigned component_tag ;                          	   // 8 bits
	unsigned ISO_639_language_code ;                  	   // 24 bits
#define MAX_TEXT_LEN 256
	char text[MAX_TEXT_LEN + 1] ;
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_component(struct Descriptor_component *cd, int level) ;
struct Descriptor *parse_component(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_component(struct Descriptor_component *cd) ;

#endif /* PARSE_DESC_COMPONENT_H_ */

