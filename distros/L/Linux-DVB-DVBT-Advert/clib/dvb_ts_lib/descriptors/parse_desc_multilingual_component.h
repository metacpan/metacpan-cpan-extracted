/*
 * parse_desc_multilingual_component.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_MULTILINGUAL_COMPONENT_H_
#define PARSE_DESC_MULTILINGUAL_COMPONENT_H_

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

// multilingual_component_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  component_tag  8 uimsbf
//   for (i=0;i<N;i++) {
//   ISO_639_language_code  24 bslbf
//   text_description_length  8 uimsbf
//   for (j=0;j<N;j++){
//    text_char  8 uimsbf
//     }
//  }
// }

struct MCD_entry {
	// linked list
	struct list_head next ;

	unsigned ISO_639_language_code ;                  	   // 24 bits
	unsigned text_description_length ;                	   // 8 bits
#define MAX_TEXT_DESCRIPTION_LEN 256
	char text_description[MAX_TEXT_DESCRIPTION_LEN + 1] ;
} ;

struct Descriptor_multilingual_component {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned component_tag ;                          	   // 8 bits
	
	// linked list of MCD_entry
	struct list_head mcd_array ;
	
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_multilingual_component(struct Descriptor_multilingual_component *mcd, int level) ;
struct Descriptor *parse_multilingual_component(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_multilingual_component(struct Descriptor_multilingual_component *mcd) ;

#endif /* PARSE_DESC_MULTILINGUAL_COMPONENT_H_ */

