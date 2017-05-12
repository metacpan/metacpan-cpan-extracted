/*
 * parse_desc_service_list.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_SERVICE_LIST_H_
#define PARSE_DESC_SERVICE_LIST_H_

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

// service_list_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  for (i=0;i<N;I++){
//   service_id  16 uimsbf
//   service_type  8 uimsbf
//  }
// }

struct SLD_entry {
	// linked list
	struct list_head next ;

	unsigned service_id ;                             	   // 16 bits
	unsigned service_type ;                           	   // 8 bits
} ;

struct Descriptor_service_list {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	
	// linked list of SLD_entry
	struct list_head sld_array ;
	
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_service_list(struct Descriptor_service_list *sld, int level) ;
struct Descriptor *parse_service_list(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_service_list(struct Descriptor_service_list *sld) ;

#endif /* PARSE_DESC_SERVICE_LIST_H_ */

