/*
 * parse_desc_dsng.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_DSNG_H_
#define PARSE_DESC_DSNG_H_

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

// DSNG_descriptor (){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//   for (i=0;i<N;i++) {
//   byte  8 uimsbf
//  }
// }

struct Descriptor_dsng {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
#define MAX_BYTE_LEN 256
	char byte[MAX_BYTE_LEN + 1] ;
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_dsng(struct Descriptor_dsng *dd, int level) ;
struct Descriptor *parse_dsng(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_dsng(struct Descriptor_dsng *dd) ;

#endif /* PARSE_DESC_DSNG_H_ */

