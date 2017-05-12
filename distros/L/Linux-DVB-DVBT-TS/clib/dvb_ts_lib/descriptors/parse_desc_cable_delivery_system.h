/*
 * parse_desc_cable_delivery_system.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_CABLE_DELIVERY_SYSTEM_H_
#define PARSE_DESC_CABLE_DELIVERY_SYSTEM_H_

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

// cable_delivery_system_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  frequency  32 bslbf
//  reserved_future_use  12 bslbf
//  FEC_outer  4 bslbf
//  modulation  8 bslbf
//  symbol_rate  28 bslbf
//  FEC_inner  4 bslbf
// }

struct Descriptor_cable_delivery_system {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned frequency ;                              	   // 32 bits
	unsigned FEC_outer ;                              	   // 4 bits
	unsigned modulation ;                             	   // 8 bits
	unsigned symbol_rate ;                            	   // 28 bits
	unsigned FEC_inner ;                              	   // 4 bits
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_cable_delivery_system(struct Descriptor_cable_delivery_system *cdsd, int level) ;
struct Descriptor *parse_cable_delivery_system(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_cable_delivery_system(struct Descriptor_cable_delivery_system *cdsd) ;

#endif /* PARSE_DESC_CABLE_DELIVERY_SYSTEM_H_ */

