/*
 * parse_si_cit.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_SI_CIT_H_
#define PARSE_SI_CIT_H_

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

// content_identifier_section() {
//     table_id 8 uimsbf
//     section_syntax_indicator 1 bslbf
//     private_indicator 1 bslbf
//     reserved 2 bslbf
//     section_length 12 uimsbf
//     service_id 16 uimsbf
//     reserved 2 bslbf
//     version_number 5 uimsbf
//     current_next_indicator 1 bslbf
//     section_number 8 uimsbf
//     last_section_number 8 uimsbf
//     transport_stream_id 16 uimsbf
//     original_network_id 16 uimsbf
//     prepend_strings_length 8 uimsbf
//     for (i=0; i< prepend_strings_length ; i++) {
//         prepend_strings_byte 8 uimsbf
//     }
//     for (j=0; j<N; j++) {
//         crid_ref 16 uimsbf
//         prepend_string_index 8 uimsbf
//         unique_string_length 8 uimsbf
//         for (k=0; k<unique_string_length; k++) {
//             unique_string_byte 8 uimsbf
//         }
//     }
//     CRC32 32 rpchof
// }

struct CIT_entry {
	// linked list
	struct list_head next ;

	// entry contents
	unsigned crid_ref ;                               	   // 16 bits
	unsigned prepend_string_index ;                   	   // 8 bits
	unsigned unique_string_length ;                   	   // 8 bits
#define MAX_UNIQUE_STRING_LEN 256
	char unique_string[MAX_UNIQUE_STRING_LEN + 1] ;
} ;

struct Section_content_identifier {
	unsigned table_id ;                               	   // 8 bits
	unsigned section_syntax_indicator ;               	   // 1 bits
	unsigned private_indicator ;                      	   // 1 bits
	unsigned section_length ;                         	   // 12 bits
	unsigned service_id ;                             	   // 16 bits
	unsigned version_number ;                         	   // 5 bits
	unsigned current_next_indicator ;                 	   // 1 bits
	unsigned section_number ;                         	   // 8 bits
	unsigned last_section_number ;                    	   // 8 bits
	unsigned transport_stream_id ;                    	   // 16 bits
	unsigned original_network_id ;                    	   // 16 bits
	unsigned prepend_strings_length ;                 	   // 8 bits
#define MAX_PREPEND_STRINGS_LEN 256
	char prepend_strings[MAX_PREPEND_STRINGS_LEN + 1] ;
	
	// linked list of CIT_entry
	struct list_head cit_array ;
	
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_cit(struct Section_content_identifier *cit) ;
void parse_cit(struct TS_reader *tsreader, struct TS_state *tsstate, struct TS_bits *bits,
		Section_handler handler, struct Section_decode_flags *flags) ;


#endif /* PARSE_SI_CIT_H_ */
	
