/*
 * parse_desc_scrambling.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_SCRAMBLING_H_
#define PARSE_DESC_SCRAMBLING_H_

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

// scrambling_descriptor(){
//  descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//  scrambling_mode  8 uimsbf
// }

struct Descriptor_scrambling {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned scrambling_mode ;                        	   // 8 bits
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_scrambling(struct Descriptor_scrambling *sd, int level) ;
struct Descriptor *parse_scrambling(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_scrambling(struct Descriptor_scrambling *sd) ;

#endif /* PARSE_DESC_SCRAMBLING_H_ */

