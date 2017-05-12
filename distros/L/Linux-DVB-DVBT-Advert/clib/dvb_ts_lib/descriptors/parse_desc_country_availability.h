/*
 * parse_desc_country_availability.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_COUNTRY_AVAILABILITY_H_
#define PARSE_DESC_COUNTRY_AVAILABILITY_H_

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

// country_availability_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  country_availability_flag  1 bslbf
//  reserved_future_use  7 bslbf
//  for (i=0;i<N;i++){
//   country_code  24 bslbf
//  }
// }

struct Descriptor_country_availability {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned country_availability_flag ;              	   // 1 bits
#define MAX_COUNTRY_CODE_LEN 256
	unsigned country_code[MAX_COUNTRY_CODE_LEN + 1] ;
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_country_availability(struct Descriptor_country_availability *cad, int level) ;
struct Descriptor *parse_country_availability(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_country_availability(struct Descriptor_country_availability *cad) ;

#endif /* PARSE_DESC_COUNTRY_AVAILABILITY_H_ */

