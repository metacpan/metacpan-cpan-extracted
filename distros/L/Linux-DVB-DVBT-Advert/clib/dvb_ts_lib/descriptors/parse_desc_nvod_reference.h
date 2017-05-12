/*
 * parse_desc_nvod_reference.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_NVOD_REFERENCE_H_
#define PARSE_DESC_NVOD_REFERENCE_H_

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

// NVOD_reference_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//   for (i=0;i<N;i++) {
//   transport_stream_id  16 uimsbf
//   original_network_id  16 uimsbf
//   service_id  16 uimsbf
//  }
// }

struct NRD_entry {
	// linked list
	struct list_head next ;

	unsigned transport_stream_id ;                    	   // 16 bits
	unsigned original_network_id ;                    	   // 16 bits
	unsigned service_id ;                             	   // 16 bits
} ;

struct Descriptor_nvod_reference {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	
	// linked list of NRD_entry
	struct list_head nrd_array ;
	
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_nvod_reference(struct Descriptor_nvod_reference *nrd, int level) ;
struct Descriptor *parse_nvod_reference(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_nvod_reference(struct Descriptor_nvod_reference *nrd) ;

#endif /* PARSE_DESC_NVOD_REFERENCE_H_ */

