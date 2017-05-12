/*
 * parse_desc_service_move.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_SERVICE_MOVE_H_
#define PARSE_DESC_SERVICE_MOVE_H_

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

// service_move_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  new_original_network_id  16 uimsbf
//  new_transport_stream_id  16 uimsbf
//  new_service_id  16 uimsbf
// }

struct Descriptor_service_move {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned new_original_network_id ;                	   // 16 bits
	unsigned new_transport_stream_id ;                	   // 16 bits
	unsigned new_service_id ;                         	   // 16 bits
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_service_move(struct Descriptor_service_move *smd, int level) ;
struct Descriptor *parse_service_move(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_service_move(struct Descriptor_service_move *smd) ;

#endif /* PARSE_DESC_SERVICE_MOVE_H_ */

