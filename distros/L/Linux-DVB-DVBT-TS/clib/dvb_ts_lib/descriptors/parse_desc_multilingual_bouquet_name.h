/*
 * parse_desc_multilingual_bouquet_name.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_MULTILINGUAL_BOUQUET_NAME_H_
#define PARSE_DESC_MULTILINGUAL_BOUQUET_NAME_H_

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

// multilingual_bouquet_name_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//   for (i=0;i<N;i++) {
//   ISO_639_language_code  24 bslbf
//   bouquet_name_length  8 uimsbf
//   for (j=0;j<N;j++){
//    char  8 uimsbf
//     }
//  }
// }

struct MBND_entry {
	// linked list
	struct list_head next ;

	unsigned ISO_639_language_code ;                  	   // 24 bits
	unsigned bouquet_name_length ;                    	   // 8 bits
#define MAX_BOUQUET_NAME_LEN 256
	char bouquet_name[MAX_BOUQUET_NAME_LEN + 1] ;
} ;

struct Descriptor_multilingual_bouquet_name {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	
	// linked list of MBND_entry
	struct list_head mbnd_array ;
	
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_multilingual_bouquet_name(struct Descriptor_multilingual_bouquet_name *mbnd, int level) ;
struct Descriptor *parse_multilingual_bouquet_name(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_multilingual_bouquet_name(struct Descriptor_multilingual_bouquet_name *mbnd) ;

#endif /* PARSE_DESC_MULTILINGUAL_BOUQUET_NAME_H_ */

