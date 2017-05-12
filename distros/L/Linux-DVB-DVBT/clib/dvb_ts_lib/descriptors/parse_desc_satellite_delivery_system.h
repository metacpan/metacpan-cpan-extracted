/*
 * parse_desc_satellite_delivery_system.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_SATELLITE_DELIVERY_SYSTEM_H_
#define PARSE_DESC_SATELLITE_DELIVERY_SYSTEM_H_

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

// satellite_delivery_system_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  frequency  32 bslbf
//  orbital_position  16 bslbf
//  west_east_flag  1 bslbf
//  polarization  2 bslbf
//     If  (modulation_system == "1") {
//         roll_off  2 bslbf
//     } else {
//         "00"  2 bslbf
//     }
//     modulation_system  1 bslbf
//     modulation_type  2 bslbf
//  symbol_rate  28 bslbf
//  FEC_inner  4 bslbf
//     }

struct Descriptor_satellite_delivery_system {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned frequency ;                              	   // 32 bits
	unsigned orbital_position ;                       	   // 16 bits
	unsigned west_east_flag ;                         	   // 1 bits
	unsigned polarization ;                           	   // 2 bits
	// IF
	unsigned roll_off ;                               	   // 2 bits
	// ELSE
	// ENDIF
	unsigned modulation_system ;                      	   // 1 bits
	unsigned modulation_type ;                        	   // 2 bits
	unsigned symbol_rate ;                            	   // 28 bits
	unsigned FEC_inner ;                              	   // 4 bits
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_satellite_delivery_system(struct Descriptor_satellite_delivery_system *sdsd, int level) ;
struct Descriptor *parse_satellite_delivery_system(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_satellite_delivery_system(struct Descriptor_satellite_delivery_system *sdsd) ;

#endif /* PARSE_DESC_SATELLITE_DELIVERY_SYSTEM_H_ */

