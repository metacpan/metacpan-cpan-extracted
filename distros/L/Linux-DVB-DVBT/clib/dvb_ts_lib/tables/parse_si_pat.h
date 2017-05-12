/*
 * parse_si_pat.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_SI_PAT_H_
#define PARSE_SI_PAT_H_

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

// program_association_section() {
//     table_id 8 uimsbf
//     section_syntax_indicator 1 bslbf
//     '0' 1 bslbf
//     reserved 2 bslbf
//     section_length 12 uimsbf
//     transport_stream_id 16 uimsbf
//     reserved 2 bslbf
//     version_number 5 uimsbf
//     current_next_indicator 1 bslbf
//     section_number 8 uimsbf
//     last_section_number 8 uimsbf
//     for (i = 0; i < N; i++) {
//         program_number 16 uimsbf
//         reserved 3 bslbf
//         if (program_number = = '0') {
//             network_PID 13 uimsbf
//         } else {
//             program_map_PID 13 uimsbf
//         }
//     }
//     CRC_32 32 rpchof
// }

struct PAT_entry {
	// linked list
	struct list_head next ;

	// entry contents
	unsigned program_number ;                         	   // 16 bits
	// IF
	unsigned network_PID ;                            	   // 13 bits
	// ELSE
	unsigned program_map_PID ;                        	   // 13 bits
	// ENDIF
} ;

struct Section_program_association {
	unsigned table_id ;                               	   // 8 bits
	unsigned section_syntax_indicator ;               	   // 1 bits
	unsigned section_length ;                         	   // 12 bits
	unsigned transport_stream_id ;                    	   // 16 bits
	unsigned version_number ;                         	   // 5 bits
	unsigned current_next_indicator ;                 	   // 1 bits
	unsigned section_number ;                         	   // 8 bits
	unsigned last_section_number ;                    	   // 8 bits
	
	// linked list of PAT_entry
	struct list_head pat_array ;
	
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_pat(struct Section_program_association *pat) ;
void parse_pat(struct TS_reader *tsreader, struct TS_state *tsstate, struct TS_bits *bits,
		Section_handler handler, struct Section_decode_flags *flags) ;


#endif /* PARSE_SI_PAT_H_ */
	
