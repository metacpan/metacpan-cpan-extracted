/*
 * parse_desc_terrestrial_delivery_system.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_TERRESTRIAL_DELIVERY_SYSTEM_H_
#define PARSE_DESC_TERRESTRIAL_DELIVERY_SYSTEM_H_

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

// terrestrial_delivery_system_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  centre_frequency  32 bslbf
//  bandwidth  3 bslbf
//  priority  1 bslbf
//  Time_Slicing_indicator  1 bslbf
//  MPE_FEC_indicator  1 bslbf
//  reserved_future_use  2 bslbf
//  constellation  2 bslbf
//  hierarchy_information  3 bslbf
//  code_rate_HP_stream  3 bslbf
//  code_rate_LP_stream  3 bslbf
//  guard_interval  2 bslbf
//  transmission_mode  2 bslbf
//  other_frequency_flag  1 bslbf
//  reserved_future_use  32 bslbf
// }

struct Descriptor_terrestrial_delivery_system {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned centre_frequency ;                       	   // 32 bits
	unsigned bandwidth ;                              	   // 3 bits
	unsigned priority ;                               	   // 1 bits
	unsigned Time_Slicing_indicator ;                 	   // 1 bits
	unsigned MPE_FEC_indicator ;                      	   // 1 bits
	unsigned constellation ;                          	   // 2 bits
	unsigned hierarchy_information ;                  	   // 3 bits
	unsigned code_rate_HP_stream ;                    	   // 3 bits
	unsigned code_rate_LP_stream ;                    	   // 3 bits
	unsigned guard_interval ;                         	   // 2 bits
	unsigned transmission_mode ;                      	   // 2 bits
	unsigned other_frequency_flag ;                   	   // 1 bits
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_terrestrial_delivery_system(struct Descriptor_terrestrial_delivery_system *tdsd, int level) ;
struct Descriptor *parse_terrestrial_delivery_system(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_terrestrial_delivery_system(struct Descriptor_terrestrial_delivery_system *tdsd) ;

#endif /* PARSE_DESC_TERRESTRIAL_DELIVERY_SYSTEM_H_ */

