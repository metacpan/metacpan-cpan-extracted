/*
 * parse_desc_announcement_support.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_ANNOUNCEMENT_SUPPORT_H_
#define PARSE_DESC_ANNOUNCEMENT_SUPPORT_H_

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

// announcement_support_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  announcement_support_indicator  16 bslbf
//   for (i=0; i<N; i++){
//   announcement_type  4 uimsbf
//   reserved_future_use  1 bslbf
//   reference_type  3 uimsbf
//     if (reference_type == 0x01
//    original_network_id  16 uimsbf
//    transport_stream_id  16 uimsbf
//    service_id  16 uimsbf
//    component_tag__  8 uimsbf
//     }
//     }
//  }

struct ASD_entry {
	// linked list
	struct list_head next ;

	unsigned announcement_type ;                      	   // 4 bits
	unsigned reference_type ;                         	   // 3 bits
	// IF
	unsigned original_network_id ;                    	   // 16 bits
	unsigned transport_stream_id ;                    	   // 16 bits
	unsigned service_id ;                             	   // 16 bits
	unsigned component_tag ;                          	   // 8 bits
	// ENDIF
} ;

struct Descriptor_announcement_support {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned announcement_support_indicator ;         	   // 16 bits
	
	// linked list of ASD_entry
	struct list_head asd_array ;
	
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_announcement_support(struct Descriptor_announcement_support *asd, int level) ;
struct Descriptor *parse_announcement_support(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_announcement_support(struct Descriptor_announcement_support *asd) ;

#endif /* PARSE_DESC_ANNOUNCEMENT_SUPPORT_H_ */

