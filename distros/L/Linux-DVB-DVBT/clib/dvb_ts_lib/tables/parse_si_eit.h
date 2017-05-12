/*
 * parse_si_eit.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_SI_EIT_H_
#define PARSE_SI_EIT_H_

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

// event_information_section(){
//  table_id  8 uimsbf
//  section_syntax_indicator  1 bslbf
//  reserved_future_use  1 bslbf
//  reserved  2 bslbf
//  section_length  12 uimsbf
//  service_id  16 uimsbf
//  reserved  2 bslbf
//  version_number  5 uimsbf
//  current_next_indicator  1 bslbf
//  section_number  8 uimsbf
//  last_section_number  8 uimsbf
//  transport_stream_id  16 uimsbf
//  original_network_id  16 uimsbf
//  segment_last_section_number  8 uimsbf
//  last_table_id  8 uimsbf
//  for(i=0;i<N;i++){
//   event_id  16 uimsbf
//   start_time  40 bslbf
//   duration  24 uimsbf
//   running_status  3 uimsbf
//   free_CA_mode  1 bslbf
//   descriptors_loop_length  12 uimsbf
//   for(i=0;i<N;i++){
//    descriptor()
//     }
//  }
//  CRC_32  32 rpchof
// }

struct EIT_entry {
	// linked list
	struct list_head next ;

	// entry contents
	unsigned event_id ;                               	   // 16 bits
	struct tm start_time ;                            	   // 40 bits
	unsigned duration ;                               	   // 24 bits
	unsigned running_status ;                         	   // 3 bits
	unsigned free_CA_mode ;                           	   // 1 bits
	unsigned descriptors_loop_length ;                	   // 12 bits
	
	// linked list of descriptors (may be empty)
	struct list_head descriptors_array ;
	
} ;

struct Section_event_information {
	unsigned table_id ;                               	   // 8 bits
	unsigned section_syntax_indicator ;               	   // 1 bits
	unsigned section_length ;                         	   // 12 bits
	unsigned service_id ;                             	   // 16 bits
	unsigned version_number ;                         	   // 5 bits
	unsigned current_next_indicator ;                 	   // 1 bits
	unsigned section_number ;                         	   // 8 bits
	unsigned last_section_number ;                    	   // 8 bits
	unsigned transport_stream_id ;                    	   // 16 bits
	unsigned original_network_id ;                    	   // 16 bits
	unsigned segment_last_section_number ;            	   // 8 bits
	unsigned last_table_id ;                          	   // 8 bits
	
	// linked list of EIT_entry
	struct list_head eit_array ;
	
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_eit(struct Section_event_information *eit) ;
void parse_eit(struct TS_reader *tsreader, struct TS_state *tsstate, struct TS_bits *bits,
		Section_handler handler, struct Section_decode_flags *flags) ;


#endif /* PARSE_SI_EIT_H_ */
	
