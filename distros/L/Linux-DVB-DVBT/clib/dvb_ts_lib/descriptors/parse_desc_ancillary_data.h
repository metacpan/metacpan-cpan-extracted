/*
 * parse_desc_ancillary_data.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_ANCILLARY_DATA_H_
#define PARSE_DESC_ANCILLARY_DATA_H_

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

// ancillary_data_descriptor(){
//  descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//  ancillary_data_identifier  8 bslbf
// }

struct Descriptor_ancillary_data {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned ancillary_data_identifier ;              	   // 8 bits
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_ancillary_data(struct Descriptor_ancillary_data *add, int level) ;
struct Descriptor *parse_ancillary_data(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_ancillary_data(struct Descriptor_ancillary_data *add) ;

#endif /* PARSE_DESC_ANCILLARY_DATA_H_ */

