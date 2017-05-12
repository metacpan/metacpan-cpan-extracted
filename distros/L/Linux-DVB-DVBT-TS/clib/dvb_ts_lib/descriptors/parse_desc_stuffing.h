/*
 * parse_desc_stuffing.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_STUFFING_H_
#define PARSE_DESC_STUFFING_H_

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

// stuffing_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//   for (i= 0;i<N;i++){
//   stuffing_byte  8 bslbf
//  }
// }
// stuffing_section(){
//  table_id  8 uimsbf
//  section_syntax_indicator  1 bslbf
//  reserved_future_use  1 bslbf
//  reserved  2 bslbf
//  section_length  12 uimsbf
//  for (i=0;i<N;i++){
//   data_byte   8 uimsbf
//  }
// }

struct Descriptor_stuffing {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
#define MAX_STUFFING_LEN 256
	char stuffing[MAX_STUFFING_LEN + 1] ;
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_stuffing(struct Descriptor_stuffing *sd, int level) ;
struct Descriptor *parse_stuffing(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_stuffing(struct Descriptor_stuffing *sd) ;

#endif /* PARSE_DESC_STUFFING_H_ */

