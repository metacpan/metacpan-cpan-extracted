/*
 * parse_si_pmt.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_SI_PMT_H_
#define PARSE_SI_PMT_H_

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

// program_map_section() {
//     table_id 8 uimsbf
//     section_syntax_indicator 1 bslbf
//     '0' 1 bslbf
//     reserved 2 bslbf
//     section_length 12 uimsbf
//     program_number 16 uimsbf
//     reserved 2 bslbf
//     version_number 5 uimsbf
//     current_next_indicator 1 bslbf
//     section_number 8 uimsbf
//     last_section_number 8 uimsbf
//     reserved 3 bslbf
//     PCR_PID 13 uimsbf
//     reserved 4 bslbf
//     program_info_length 12 uimsbf
//     for (i = 0; i < N; i++) {
//         descriptor()
//     }
//     for (i = 0; i < N1; i++) {
//         stream_type 8 uimsbf
//         reserved 3 bslbf
//         elementary_PID 13 uimsbf
//         reserved 4 bslbf
//         ES_info_length 12 uimsbf
//         for (i = 0; i < N2; i++) {
//             descriptor()
//         }
//     }
//     CRC_32 32 rpchof
// }

struct PMT_entry {
	// linked list
	struct list_head next ;

	// entry contents
	unsigned stream_type ;                            	   // 8 bits
	unsigned elementary_PID ;                         	   // 13 bits
	unsigned ES_info_length ;                         	   // 12 bits
	
	// linked list of descriptors (may be empty)
	struct list_head descriptors_array ;
	
} ;

struct Section_program_map {
	unsigned table_id ;                               	   // 8 bits
	unsigned section_syntax_indicator ;               	   // 1 bits
	unsigned section_length ;                         	   // 12 bits
	unsigned program_number ;                         	   // 16 bits
	unsigned version_number ;                         	   // 5 bits
	unsigned current_next_indicator ;                 	   // 1 bits
	unsigned section_number ;                         	   // 8 bits
	unsigned last_section_number ;                    	   // 8 bits
	unsigned PCR_PID ;                                	   // 13 bits
	unsigned program_info_length ;                    	   // 12 bits
	
	// linked list of descriptors (may be empty)
	struct list_head descriptors_array ;
	
	
	// linked list of PMT_entry
	struct list_head pmt_array ;
	
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_pmt(struct Section_program_map *pmt) ;
void parse_pmt(struct TS_reader *tsreader, struct TS_state *tsstate, struct TS_bits *bits,
		Section_handler handler, struct Section_decode_flags *flags) ;


#endif /* PARSE_SI_PMT_H_ */
	
