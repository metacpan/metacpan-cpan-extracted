/*
 * parse_desc_short_event.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_SHORT_EVENT_H_
#define PARSE_DESC_SHORT_EVENT_H_

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

// short_event_descriptor(){
//  descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//  ISO_639_language_code  24 bslbf
//  event_name_length  8 uimsbf
//  for (i=0;i<event_name_length;i++){
//   event_name_char  8 uimsbf
//  }
//  text_length  8 uimsbf
//  for (i=0;i<text_length;i++){
//   text_char  8 uimsbf
//  }
// }

struct Descriptor_short_event {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned ISO_639_language_code ;                  	   // 24 bits
	unsigned event_name_length ;                      	   // 8 bits
#define MAX_EVENT_NAME_LEN 256
	char event_name[MAX_EVENT_NAME_LEN + 1] ;
	unsigned text_length ;                            	   // 8 bits
#define MAX_TEXT_LEN 256
	char text[MAX_TEXT_LEN + 1] ;
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_short_event(struct Descriptor_short_event *sed, int level) ;
struct Descriptor *parse_short_event(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_short_event(struct Descriptor_short_event *sed) ;

#endif /* PARSE_DESC_SHORT_EVENT_H_ */

