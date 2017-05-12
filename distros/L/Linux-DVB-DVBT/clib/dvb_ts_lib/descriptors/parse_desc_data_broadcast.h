/*
 * parse_desc_data_broadcast.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_DATA_BROADCAST_H_
#define PARSE_DESC_DATA_BROADCAST_H_

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

// data_broadcast_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  data_broadcast_id  16 uimsbf
//  component_tag  8 uimsbf
//  selector_length  8 uimsbf
//   for (i=0; i<selector_length; i++){
//   selector_byte  8 uimsbf
//  }
//  ISO_639_language_code  24 bslbf
//  text_length  8 uimsbf
//   for (i=0; i<text_length; i++){
//   text_char  8 uimsbf
//  }
// }

struct Descriptor_data_broadcast {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned data_broadcast_id ;                      	   // 16 bits
	unsigned component_tag ;                          	   // 8 bits
	unsigned selector_length ;                        	   // 8 bits
#define MAX_SELECTOR_LEN 256
	char selector[MAX_SELECTOR_LEN + 1] ;
	unsigned ISO_639_language_code ;                  	   // 24 bits
	unsigned text_length ;                            	   // 8 bits
#define MAX_TEXT_LEN 256
	char text[MAX_TEXT_LEN + 1] ;
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_data_broadcast(struct Descriptor_data_broadcast *dbd, int level) ;
struct Descriptor *parse_data_broadcast(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_data_broadcast(struct Descriptor_data_broadcast *dbd) ;

#endif /* PARSE_DESC_DATA_BROADCAST_H_ */

