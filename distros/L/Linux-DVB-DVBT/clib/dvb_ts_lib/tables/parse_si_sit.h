/*
 * parse_si_sit.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_SI_SIT_H_
#define PARSE_SI_SIT_H_

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

// selection_information_section(){
//  table_id   8 uimsbf
//  section_syntax_indicator   1 bslbf
//  DVB_reserved_future_use  1 bslbf
//  ISO_reserved  2 bslbf
//  section_length  12 uimsbf
//  DVB_reserved_future_use  16 uimsbf
//  ISO_reserved  2 bslbf
//  version_number  5 uimsbf
//  current_next_indicator  1 bslbf
//  section_number  8 uimsbf
//  last_section_number  8 uimsbf
//  DVB_reserved_for_future_use  4 uimsbf
//  transmission_info_loop_length  12 bslbf
//   for(i =0;i<N;i++) {
//   descriptor()
//  }
//  for(i=0;i<N;i++){
//   service_id  16 uimsbf
//   DVB_reserved_future_use  1 uimsbf
//   running_status  3 bslbf
//   service_loop_length  12 bslbf
//   for(j=0;j<N;j++){
//    descriptor()
//     }
//  }
//  CRC_32  32 rpchof
// }

struct SIT_entry {
	// linked list
	struct list_head next ;

	// entry contents
	unsigned service_id ;                             	   // 16 bits
	unsigned running_status ;                         	   // 3 bits
	unsigned service_loop_length ;                    	   // 12 bits
	
	// linked list of descriptors (may be empty)
	struct list_head service_array ;
	
} ;

struct Section_selection_information {
	unsigned table_id ;                               	   // 8 bits
	unsigned section_syntax_indicator ;               	   // 1 bits
	unsigned section_length ;                         	   // 12 bits
	unsigned version_number ;                         	   // 5 bits
	unsigned current_next_indicator ;                 	   // 1 bits
	unsigned section_number ;                         	   // 8 bits
	unsigned last_section_number ;                    	   // 8 bits
	unsigned transmission_info_loop_length ;          	   // 12 bits
	
	// linked list of descriptors (may be empty)
	struct list_head transmission_info_array ;
	
	
	// linked list of SIT_entry
	struct list_head sit_array ;
	
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_sit(struct Section_selection_information *sit) ;
void parse_sit(struct TS_reader *tsreader, struct TS_state *tsstate, struct TS_bits *bits,
		Section_handler handler, struct Section_decode_flags *flags) ;


#endif /* PARSE_SI_SIT_H_ */
	
