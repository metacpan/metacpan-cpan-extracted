/*
 * parse_si_rst.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_SI_RST_H_
#define PARSE_SI_RST_H_

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

// running_status_section(){
//  table_id  8 uimsbf
//  section_syntax_indicator  1 bslbf
//  reserved_future_use  1 bslbf
//  reserved  2 bslbf
//  section_length  12 uimsbf
//  for (i=0;i<N;i++){
//   transport_stream_id   16 uimsbf
//   original_network_id   16 uimsbf
//   service_id  16 uimsbf
//   event_id  16 uimsbf
//   reserved_future_use  5 bslbf
//   running_status   3 uimsbf
//  }
// }

struct RST_entry {
	// linked list
	struct list_head next ;

	// entry contents
	unsigned transport_stream_id ;                    	   // 16 bits
	unsigned original_network_id ;                    	   // 16 bits
	unsigned service_id ;                             	   // 16 bits
	unsigned event_id ;                               	   // 16 bits
	unsigned running_status ;                         	   // 3 bits
} ;

struct Section_running_status {
	unsigned table_id ;                               	   // 8 bits
	unsigned section_syntax_indicator ;               	   // 1 bits
	unsigned section_length ;                         	   // 12 bits
	
	// linked list of RST_entry
	struct list_head rst_array ;
	
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_rst(struct Section_running_status *rst) ;
void parse_rst(struct TS_reader *tsreader, struct TS_state *tsstate, struct TS_bits *bits,
		Section_handler handler, struct Section_decode_flags *flags) ;


#endif /* PARSE_SI_RST_H_ */
	
