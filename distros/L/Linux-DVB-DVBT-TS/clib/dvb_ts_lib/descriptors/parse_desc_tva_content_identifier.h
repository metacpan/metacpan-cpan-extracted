/*
 * parse_desc_tva_content_identifier.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_TVA_CONTENT_IDENTIFIER_H_
#define PARSE_DESC_TVA_CONTENT_IDENTIFIER_H_

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

// TVA_content_identifier_descriptor() {
// descriptor_tag 8 uimsbf
// descriptor_length 8 uimsbf
// for (i=0;i<N;i++) {
// crid_type 6 uimsbf
// crid_location 2 uimsbf
// if (crid_location == '00' ) {
// crid_length 8 uimsbf
// for (j=0;j<crid_length;j++) {
// crid_byte 8 uimsbf
// }
// }
// if (crid_location == '01' ) {
// crid_ref 16 uimsbf
// }
// }
// }

struct TCID_entry {
	// linked list
	struct list_head next ;

	unsigned crid_type ;                              	   // 6 bits
	unsigned crid_location ;                          	   // 2 bits
	// IF
	unsigned crid_length ;                            	   // 8 bits
#define MAX_CRID_LEN 256
	char crid[MAX_CRID_LEN + 1] ;
	// ENDIF
	// IF
	unsigned crid_ref ;                               	   // 16 bits
	// ENDIF
} ;

struct Descriptor_tva_content_identifier {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	
	// linked list of TCID_entry
	struct list_head tcid_array ;
	
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_tva_content_identifier(struct Descriptor_tva_content_identifier *tcid, int level) ;
struct Descriptor *parse_tva_content_identifier(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_tva_content_identifier(struct Descriptor_tva_content_identifier *tcid) ;

#endif /* PARSE_DESC_TVA_CONTENT_IDENTIFIER_H_ */

