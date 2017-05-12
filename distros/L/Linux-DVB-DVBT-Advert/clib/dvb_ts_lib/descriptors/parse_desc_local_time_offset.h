/*
 * parse_desc_local_time_offset.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_LOCAL_TIME_OFFSET_H_
#define PARSE_DESC_LOCAL_TIME_OFFSET_H_

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

// local_time_offset_descriptor(){
//  descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//  for(i=0;i<N;i++){
//   country_code   24 bslbf
//   country_region_id  6 bslbf
//   reserved  1 bslbf
//   local_time_offset_polarity  1 bslbf
//   local_time_offset  16 bslbf
//   time_of_change  40 bslbf
//   next_time_offset  16 bslbf
//  }
// }

struct LTOD_entry {
	// linked list
	struct list_head next ;

	unsigned country_code ;                           	   // 24 bits
	unsigned country_region_id ;                      	   // 6 bits
	unsigned local_time_offset_polarity ;             	   // 1 bits
	unsigned local_time_offset ;                      	   // 16 bits
	struct tm time_of_change ;                        	   // 40 bits
	unsigned next_time_offset ;                       	   // 16 bits
} ;

struct Descriptor_local_time_offset {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	
	// linked list of LTOD_entry
	struct list_head ltod_array ;
	
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_local_time_offset(struct Descriptor_local_time_offset *ltod, int level) ;
struct Descriptor *parse_local_time_offset(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_local_time_offset(struct Descriptor_local_time_offset *ltod) ;

#endif /* PARSE_DESC_LOCAL_TIME_OFFSET_H_ */

