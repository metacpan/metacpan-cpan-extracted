/*
 * parse_desc_s2_satellite_delivery_system.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_S2_SATELLITE_DELIVERY_SYSTEM_H_
#define PARSE_DESC_S2_SATELLITE_DELIVERY_SYSTEM_H_

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

// S2_satellite_delivery_system_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  scrambling_sequence_selector  1 bslbf
//  multiple_input_stream_flag  1 bslbf
//  backwards_compatibility_indicator  1 bslbf
//  reserved_future_use  5 bslbf
//   if (scrambling_sequence_selector == 1){
//   Reserved  6 bslbf
//   scrambling_sequence_index  18 uimsbf
//  }
//   if (multiple_input_stream_flag == 1){
//   input_stream_identifier  8 uimsbf
//  }
// }

struct Descriptor_s2_satellite_delivery_system {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned scrambling_sequence_selector ;           	   // 1 bits
	unsigned multiple_input_stream_flag ;             	   // 1 bits
	unsigned backwards_compatibility_indicator ;      	   // 1 bits
	// IF
	unsigned scrambling_sequence_index ;              	   // 18 bits
	// ENDIF
	// IF
	unsigned input_stream_identifier ;                	   // 8 bits
	// ENDIF
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_s2_satellite_delivery_system(struct Descriptor_s2_satellite_delivery_system *ssdsd, int level) ;
struct Descriptor *parse_s2_satellite_delivery_system(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_s2_satellite_delivery_system(struct Descriptor_s2_satellite_delivery_system *ssdsd) ;

#endif /* PARSE_DESC_S2_SATELLITE_DELIVERY_SYSTEM_H_ */

