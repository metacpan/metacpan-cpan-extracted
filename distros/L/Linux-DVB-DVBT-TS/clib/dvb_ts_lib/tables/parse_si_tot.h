/*
 * parse_si_tot.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_SI_TOT_H_
#define PARSE_SI_TOT_H_

/*=============================================================================================*/
// USES
/*=============================================================================================*/
#include "si_structs.h"
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

// time_offset_section(){
//  table_id  8 uimsbf
//  section_syntax_indicator  1 bslbf
//  reserved_future_use  1 bslbf
//  reserved  2 bslbf
//  section_length  12 uimsbf
//  UTC_time  40 bslbf
//  reserved  4 bslbf
//  descriptors_loop_length  12 uimsbf
//  for(i=0;i<N;i++){
//   descriptor()
//  }
//  CRC_32  32 rpchof
// }

struct Section_time_offset {
	unsigned table_id ;                               	   // 8 bits
	unsigned section_syntax_indicator ;               	   // 1 bits
	unsigned section_length ;                         	   // 12 bits
	struct tm UTC_time ;                              	   // 40 bits
	unsigned descriptors_loop_length ;                	   // 12 bits
	
	// linked list of descriptors (may be empty)
	struct list_head descriptors_array ;
	
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_tot(struct Section_time_offset *tot) ;
void parse_tot(struct TS_reader *tsreader, struct TS_state *tsstate, struct TS_bits *bits,
		Section_handler handler, struct Section_decode_flags *flags) ;


#endif /* PARSE_SI_TOT_H_ */
	
