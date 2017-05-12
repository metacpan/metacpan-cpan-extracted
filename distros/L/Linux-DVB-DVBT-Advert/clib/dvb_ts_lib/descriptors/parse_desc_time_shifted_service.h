/*
 * parse_desc_time_shifted_service.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_TIME_SHIFTED_SERVICE_H_
#define PARSE_DESC_TIME_SHIFTED_SERVICE_H_

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

// time_shifted_service_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  reference_service_id  16 uimsbf
// }

struct Descriptor_time_shifted_service {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned reference_service_id ;                   	   // 16 bits
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_time_shifted_service(struct Descriptor_time_shifted_service *tssd, int level) ;
struct Descriptor *parse_time_shifted_service(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_time_shifted_service(struct Descriptor_time_shifted_service *tssd) ;

#endif /* PARSE_DESC_TIME_SHIFTED_SERVICE_H_ */

