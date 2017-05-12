/*
 * parse_desc_content.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_CONTENT_H_
#define PARSE_DESC_CONTENT_H_

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

// content_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//   for (i=0;i<N;i++) {
//    content_nibble_level_1  4 uimsbf
//    content_nibble_level_2  4 uimsbf
//    user_nibble  4 uimsbf
//    user_nibble  4 uimsbf
//  }
// }

struct CD_entry {
	// linked list
	struct list_head next ;

	unsigned content_nibble_level_1 ;                 	   // 4 bits
	unsigned content_nibble_level_2 ;                 	   // 4 bits
	unsigned user_nibble ;                            	   // 4 bits
	unsigned user_nibble1 ;                           	   // 4 bits
} ;

struct Descriptor_content {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	
	// linked list of CD_entry
	struct list_head cd_array ;
	
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_content(struct Descriptor_content *cd, int level) ;
struct Descriptor *parse_content(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_content(struct Descriptor_content *cd) ;

#endif /* PARSE_DESC_CONTENT_H_ */

