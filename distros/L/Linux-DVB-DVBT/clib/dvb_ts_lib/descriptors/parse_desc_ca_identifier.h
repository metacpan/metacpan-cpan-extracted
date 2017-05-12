/*
 * parse_desc_ca_identifier.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_CA_IDENTIFIER_H_
#define PARSE_DESC_CA_IDENTIFIER_H_

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

// CA_identifier_descriptor(){
//  descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//  for (i=0;i<N;i++){
//   CA_system_id  16 uimsbf
//  }
// }

struct Descriptor_ca_identifier {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
#define MAX_CA_SYSTEM_ID_LEN 256
	unsigned CA_system_id[MAX_CA_SYSTEM_ID_LEN + 1] ;
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_ca_identifier(struct Descriptor_ca_identifier *cid, int level) ;
struct Descriptor *parse_ca_identifier(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_ca_identifier(struct Descriptor_ca_identifier *cid) ;

#endif /* PARSE_DESC_CA_IDENTIFIER_H_ */

