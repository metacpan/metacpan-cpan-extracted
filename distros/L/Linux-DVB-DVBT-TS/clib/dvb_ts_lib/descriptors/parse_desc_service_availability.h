/*
 * parse_desc_service_availability.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_SERVICE_AVAILABILITY_H_
#define PARSE_DESC_SERVICE_AVAILABILITY_H_

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

// service_availability_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  availability_flag  1 bslbf
//  reserved  7 bslbf
//   for (i=0;i<N;i++) {
//   cell_id  16 uimsbf
//  }
// }

struct Descriptor_service_availability {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned availability_flag ;                      	   // 1 bits
#define MAX_CELL_ID_LEN 256
	unsigned cell_id[MAX_CELL_ID_LEN + 1] ;
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_service_availability(struct Descriptor_service_availability *sad, int level) ;
struct Descriptor *parse_service_availability(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_service_availability(struct Descriptor_service_availability *sad) ;

#endif /* PARSE_DESC_SERVICE_AVAILABILITY_H_ */

