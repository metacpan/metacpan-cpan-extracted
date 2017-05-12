/*
 * parse_desc_data_broadcast_id.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_DATA_BROADCAST_ID_H_
#define PARSE_DESC_DATA_BROADCAST_ID_H_

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

// data_broadcast_id_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  data_broadcast_id  16 uimsbf
//   for(i=0; i < N;i++){
//   id_selector_byte  8 uimsbf
//  }
// }

struct Descriptor_data_broadcast_id {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned data_broadcast_id ;                      	   // 16 bits
#define MAX_ID_SELECTOR_LEN 256
	char id_selector[MAX_ID_SELECTOR_LEN + 1] ;
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_data_broadcast_id(struct Descriptor_data_broadcast_id *dbid, int level) ;
struct Descriptor *parse_data_broadcast_id(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_data_broadcast_id(struct Descriptor_data_broadcast_id *dbid) ;

#endif /* PARSE_DESC_DATA_BROADCAST_ID_H_ */

