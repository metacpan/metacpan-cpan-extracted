/*
 * parse_desc_private_data_specifier.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_PRIVATE_DATA_SPECIFIER_H_
#define PARSE_DESC_PRIVATE_DATA_SPECIFIER_H_

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

// private_data_specifier_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  private_data_specifier  32 uimsbf
// }

struct Descriptor_private_data_specifier {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned private_data_specifier ;                 	   // 32 bits
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_private_data_specifier(struct Descriptor_private_data_specifier *pdsd, int level) ;
struct Descriptor *parse_private_data_specifier(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_private_data_specifier(struct Descriptor_private_data_specifier *pdsd) ;

#endif /* PARSE_DESC_PRIVATE_DATA_SPECIFIER_H_ */

