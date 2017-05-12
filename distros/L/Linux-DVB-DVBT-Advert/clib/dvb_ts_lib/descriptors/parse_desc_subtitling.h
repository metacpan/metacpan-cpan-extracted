/*
 * parse_desc_subtitling.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_SUBTITLING_H_
#define PARSE_DESC_SUBTITLING_H_

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

// subtitling_descriptor(){
//  descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//   for (i= 0;i<N;I++){
//   ISO_639_language_code  24 bslbf
//   subtitling_type  8 bslbf
//   composition_page_id  16 bslbf
//   ancillary_page_id  16 bslbf
//  }
// }

struct SD_entry {
	// linked list
	struct list_head next ;

	unsigned ISO_639_language_code ;                  	   // 24 bits
	unsigned subtitling_type ;                        	   // 8 bits
	unsigned composition_page_id ;                    	   // 16 bits
	unsigned ancillary_page_id ;                      	   // 16 bits
} ;

struct Descriptor_subtitling {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	
	// linked list of SD_entry
	struct list_head sd_array ;
	
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_subtitling(struct Descriptor_subtitling *sd, int level) ;
struct Descriptor *parse_subtitling(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_subtitling(struct Descriptor_subtitling *sd) ;

#endif /* PARSE_DESC_SUBTITLING_H_ */

