/*
 * parse_desc_multilingual_service_name.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_MULTILINGUAL_SERVICE_NAME_H_
#define PARSE_DESC_MULTILINGUAL_SERVICE_NAME_H_

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

// multilingual_service_name_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//   for (i=0;i<N;i++) {
//   ISO_639_language_code  24 bslbf
//   service_provider_name_length  8 uimsbf
//   for (j=0;j<N;j++){
//    char  8 uimsbf
//     }
//   service_name_length  8 uimsbf
//   for (j=0;j<N;j++){
//    char  8 uimsbf
//     }
//  }
// }

struct MSND_entry {
	// linked list
	struct list_head next ;

	unsigned ISO_639_language_code ;                  	   // 24 bits
	unsigned service_provider_name_length ;           	   // 8 bits
#define MAX_SERVICE_PROVIDER_NAME_LEN 256
	char service_provider_name[MAX_SERVICE_PROVIDER_NAME_LEN + 1] ;
	unsigned service_name_length ;                    	   // 8 bits
#define MAX_SERVICE_NAME_LEN 256
	char service_name[MAX_SERVICE_NAME_LEN + 1] ;
} ;

struct Descriptor_multilingual_service_name {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	
	// linked list of MSND_entry
	struct list_head msnd_array ;
	
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_multilingual_service_name(struct Descriptor_multilingual_service_name *msnd, int level) ;
struct Descriptor *parse_multilingual_service_name(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_multilingual_service_name(struct Descriptor_multilingual_service_name *msnd) ;

#endif /* PARSE_DESC_MULTILINGUAL_SERVICE_NAME_H_ */

