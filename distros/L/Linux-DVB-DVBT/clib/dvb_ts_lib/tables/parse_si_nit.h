/*
 * parse_si_nit.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_SI_NIT_H_
#define PARSE_SI_NIT_H_

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

// network_information_section(){
//  table_id   8 uimsbf
//  section_syntax_indicator   1 bslbf
//  reserved_future_use  1 bslbf
//  reserved  2 bslbf
//  section_length  12 uimsbf
//  network_id  16 uimsbf
//  reserved  2 bslbf
//  version_number  5 uimsbf
//  current_next_indicator  1 bslbf
//  section_number  8 uimsbf
//  last_section_number  8 uimsbf
//  reserved_future_use  4 bslbf
//  network_descriptors_length  12 uimsbf
//  for(i=0;i<N;i++){
//   descriptor()
//  }
//  reserved_future_use  4 bslbf
//  transport_stream_loop_length  12 uimsbf
//  for(i=0;i<N;i++){
//   transport_stream_id  16 uimsbf
//   original_network_id  16 uimsbf
//   reserved_future_use  4 bslbf
//   transport_descriptors_length  12 uimsbf
//   for(j=0;j<N;j++){
//    descriptor()
//     }
//  }
//  CRC_32  32 rpchof
// }

struct NIT_entry {
	// linked list
	struct list_head next ;

	// entry contents
	unsigned transport_stream_id ;                    	   // 16 bits
	unsigned original_network_id ;                    	   // 16 bits
	unsigned transport_descriptors_length ;           	   // 12 bits
	
	// linked list of descriptors (may be empty)
	struct list_head transport_array ;
	
} ;

struct Section_network_information {
	unsigned table_id ;                               	   // 8 bits
	unsigned section_syntax_indicator ;               	   // 1 bits
	unsigned section_length ;                         	   // 12 bits
	unsigned network_id ;                             	   // 16 bits
	unsigned version_number ;                         	   // 5 bits
	unsigned current_next_indicator ;                 	   // 1 bits
	unsigned section_number ;                         	   // 8 bits
	unsigned last_section_number ;                    	   // 8 bits
	unsigned network_descriptors_length ;             	   // 12 bits
	
	// linked list of descriptors (may be empty)
	struct list_head network_array ;
	
	unsigned transport_stream_loop_length ;           	   // 12 bits
	
	// linked list of NIT_entry
	struct list_head nit_array ;
	
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_nit(struct Section_network_information *nit) ;
void parse_nit(struct TS_reader *tsreader, struct TS_state *tsstate, struct TS_bits *bits,
		Section_handler handler, struct Section_decode_flags *flags) ;


#endif /* PARSE_SI_NIT_H_ */
	
