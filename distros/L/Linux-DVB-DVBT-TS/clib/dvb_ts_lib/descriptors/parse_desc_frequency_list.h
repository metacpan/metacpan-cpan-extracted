/*
 * parse_desc_frequency_list.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_FREQUENCY_LIST_H_
#define PARSE_DESC_FREQUENCY_LIST_H_

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

// frequency_list_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  reserved_future_use  6 bslbf
//  coding_type  2 bslbf
//  for (i=0;I<N;i++){
//   centre_frequency  32 uimsbf
//  }
// }

struct Descriptor_frequency_list {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned coding_type ;                            	   // 2 bits
#define MAX_CENTRE_FREQUENCY_LEN 256
	unsigned centre_frequency[MAX_CENTRE_FREQUENCY_LEN + 1] ;
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_frequency_list(struct Descriptor_frequency_list *fld, int level) ;
struct Descriptor *parse_frequency_list(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_frequency_list(struct Descriptor_frequency_list *fld) ;

#endif /* PARSE_DESC_FREQUENCY_LIST_H_ */

