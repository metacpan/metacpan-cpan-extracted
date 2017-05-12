/*
 * parse_desc_extended_event.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_EXTENDED_EVENT_H_
#define PARSE_DESC_EXTENDED_EVENT_H_

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

// extended_event_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  descriptor_number  4 uimsbf
//  last_descriptor_number  4 uimsbf
//  ISO_639_language_code  24 bslbf
//  length_of_items  8 uimsbf
//   for ( i=0;i<N;i++){
//   item_description_length  8 uimsbf
//   for (j=0;j<N;j++){
//    item_description_char  8 uimsbf
//     }
//   item_length  8 uimsbf
//   for (j=0;j<N;j++){
//    item_char  8 uimsbf
//     }
//  }
//  text_length   8 uimsbf
//  for (i=0;i<N;i++){
//   text_char  8 uimsbf
//  }
// }

struct EED_entry {
	// linked list
	struct list_head next ;

	unsigned item_description_length ;                	   // 8 bits
#define MAX_ITEM_DESCRIPTION_LEN 256
	char item_description[MAX_ITEM_DESCRIPTION_LEN + 1] ;
	unsigned item_length ;                            	   // 8 bits
#define MAX_ITEM_LEN 256
	char item[MAX_ITEM_LEN + 1] ;
} ;

struct Descriptor_extended_event {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned descriptor_number ;                      	   // 4 bits
	unsigned last_descriptor_number ;                 	   // 4 bits
	unsigned ISO_639_language_code ;                  	   // 24 bits
	unsigned length_of_items ;                        	   // 8 bits
	
	// linked list of EED_entry
	struct list_head eed_array ;
	
	unsigned text_length ;                            	   // 8 bits
#define MAX_TEXT_LEN 256
	char text[MAX_TEXT_LEN + 1] ;
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_extended_event(struct Descriptor_extended_event *eed, int level) ;
struct Descriptor *parse_extended_event(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_extended_event(struct Descriptor_extended_event *eed) ;

#endif /* PARSE_DESC_EXTENDED_EVENT_H_ */

