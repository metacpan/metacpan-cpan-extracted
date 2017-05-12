/*
 * parse_desc_adaptation_field_data.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_ADAPTATION_FIELD_DATA_H_
#define PARSE_DESC_ADAPTATION_FIELD_DATA_H_

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

// adaptation_field_data_descriptor(){
//    descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//  adaptation_field_data_identifier  8 bslbf
// }

struct Descriptor_adaptation_field_data {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned adaptation_field_data_identifier ;       	   // 8 bits
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_adaptation_field_data(struct Descriptor_adaptation_field_data *afdd, int level) ;
struct Descriptor *parse_adaptation_field_data(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_adaptation_field_data(struct Descriptor_adaptation_field_data *afdd) ;

#endif /* PARSE_DESC_ADAPTATION_FIELD_DATA_H_ */

