/*
 * parse_desc_service.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_SERVICE_H_
#define PARSE_DESC_SERVICE_H_

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

// service_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  service_type  8 uimsbf
//  service_provider_name_length  8 uimsbf
//  for (i=0;i<N;I++){
//   char  8 uimsbf
//  }
//  service_name_length  8 uimsbf
//  for (i=0;i<N;I++){
//   Char  8 uimsbf
//  }
// }

struct Descriptor_service {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned service_type ;                           	   // 8 bits
	unsigned service_provider_name_length ;           	   // 8 bits
#define MAX_SERVICE_PROVIDER_NAME_LEN 256
	char service_provider_name[MAX_SERVICE_PROVIDER_NAME_LEN + 1] ;
	unsigned service_name_length ;                    	   // 8 bits
#define MAX_SERVICE_NAME_LEN 256
	char service_name[MAX_SERVICE_NAME_LEN + 1] ;
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_service(struct Descriptor_service *sd, int level) ;
struct Descriptor *parse_service(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_service(struct Descriptor_service *sd) ;

#endif /* PARSE_DESC_SERVICE_H_ */

