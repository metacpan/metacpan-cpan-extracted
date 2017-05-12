/*
 * parse_desc_pdc.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_PDC_H_
#define PARSE_DESC_PDC_H_

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

// PDC_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length   8 uimsbf
//  reserved_future_use   4 bslbf
//  programme_identification_label  20 bslbf
// }

struct Descriptor_pdc {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned programme_identification_label ;         	   // 20 bits
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_pdc(struct Descriptor_pdc *pd, int level) ;
struct Descriptor *parse_pdc(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_pdc(struct Descriptor_pdc *pd) ;

#endif /* PARSE_DESC_PDC_H_ */

