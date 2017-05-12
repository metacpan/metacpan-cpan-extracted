/*
 * parse_si_sdt.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_SI_SDT_H_
#define PARSE_SI_SDT_H_

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

// service_description_section(){
//  table_id  8 uimsbf
//  section_syntax_indicator  1 bslbf
//  reserved_future_use  1 bslbf
//  reserved  2 bslbf
//  section_length  12 uimsbf
//  transport_stream_id  16 uimsbf
//  reserved  2 bslbf
//  version_number  5 uimsbf
//  current_next_indicator  1 bslbf
//  section_number  8 uimsbf
//  last_section_number  8 uimsbf
//  original_network_id  16 uimsbf
//  reserved_future_use  8 bslbf
//  for (i=0;i<N;i++){
//   service_id  16 uimsbf
//   reserved_future_use  6 bslbf
//   EIT_schedule_flag  1 bslbf
//   EIT_present_following_flag  1 bslbf
//   running_status  3 uimsbf
//   free_CA_mode  1 bslbf
//   descriptors_loop_length  12 uimsbf
//   for (j=0;j<N;j++){
//    descriptor()
//     }
//  }
//  CRC_32  32 rpchof
// }

struct SDT_entry {
	// linked list
	struct list_head next ;

	// entry contents
	unsigned service_id ;                             	   // 16 bits
	unsigned EIT_schedule_flag ;                      	   // 1 bits
	unsigned EIT_present_following_flag ;             	   // 1 bits
	unsigned running_status ;                         	   // 3 bits
	unsigned free_CA_mode ;                           	   // 1 bits
	unsigned descriptors_loop_length ;                	   // 12 bits
	
	// linked list of descriptors (may be empty)
	struct list_head descriptors_array ;
	
} ;

struct Section_service_description {
	unsigned table_id ;                               	   // 8 bits
	unsigned section_syntax_indicator ;               	   // 1 bits
	unsigned section_length ;                         	   // 12 bits
	unsigned transport_stream_id ;                    	   // 16 bits
	unsigned version_number ;                         	   // 5 bits
	unsigned current_next_indicator ;                 	   // 1 bits
	unsigned section_number ;                         	   // 8 bits
	unsigned last_section_number ;                    	   // 8 bits
	unsigned original_network_id ;                    	   // 16 bits
	
	// linked list of SDT_entry
	struct list_head sdt_array ;
	
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_sdt(struct Section_service_description *sdt) ;
void parse_sdt(struct TS_reader *tsreader, struct TS_state *tsstate, struct TS_bits *bits,
		Section_handler handler, struct Section_decode_flags *flags) ;


#endif /* PARSE_SI_SDT_H_ */
	
