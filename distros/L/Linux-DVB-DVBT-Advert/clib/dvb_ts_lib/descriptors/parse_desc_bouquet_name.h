/*
 * parse_desc_bouquet_name.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_BOUQUET_NAME_H_
#define PARSE_DESC_BOUQUET_NAME_H_

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

// bouquet_name_descriptor(){
//  descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//  for(i=0;i<N;i++){
//   char  8 uimsbf
//  }
// }

struct Descriptor_bouquet_name {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
#define MAX_DESCRIPTOR_LEN 256
	char descriptor[MAX_DESCRIPTOR_LEN + 1] ;
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_bouquet_name(struct Descriptor_bouquet_name *bnd, int level) ;
struct Descriptor *parse_bouquet_name(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_bouquet_name(struct Descriptor_bouquet_name *bnd) ;

#endif /* PARSE_DESC_BOUQUET_NAME_H_ */

