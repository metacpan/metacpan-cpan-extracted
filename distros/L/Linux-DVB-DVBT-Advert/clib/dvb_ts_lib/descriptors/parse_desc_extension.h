/*
 * parse_desc_extension.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_EXTENSION_H_
#define PARSE_DESC_EXTENSION_H_

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

// extension_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  descriptor_tag_extension  8 uimsbf
//  for (i=0;i<N;i++){
//   selector_byte  8 bslbf
//  }
// }

struct Descriptor_extension {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned descriptor_tag_extension ;               	   // 8 bits
#define MAX_SELECTOR_LEN 256
	char selector[MAX_SELECTOR_LEN + 1] ;
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_extension(struct Descriptor_extension *ed, int level) ;
struct Descriptor *parse_extension(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_extension(struct Descriptor_extension *ed) ;

#endif /* PARSE_DESC_EXTENSION_H_ */

