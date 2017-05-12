/*
 * parse_desc_parental_rating.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_PARENTAL_RATING_H_
#define PARSE_DESC_PARENTAL_RATING_H_

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

// parental_rating_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  for (i=0;i<N;i++){
//   country_code  24 bslbf
//   rating  8 uimsbf
//  }
// }

struct PRD_entry {
	// linked list
	struct list_head next ;

	unsigned country_code ;                           	   // 24 bits
	unsigned rating ;                                 	   // 8 bits
} ;

struct Descriptor_parental_rating {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	
	// linked list of PRD_entry
	struct list_head prd_array ;
	
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_parental_rating(struct Descriptor_parental_rating *prd, int level) ;
struct Descriptor *parse_parental_rating(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_parental_rating(struct Descriptor_parental_rating *prd) ;

#endif /* PARSE_DESC_PARENTAL_RATING_H_ */

