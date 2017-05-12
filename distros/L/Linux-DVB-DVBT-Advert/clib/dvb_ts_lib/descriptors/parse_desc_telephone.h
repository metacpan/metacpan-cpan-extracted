/*
 * parse_desc_telephone.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_TELEPHONE_H_
#define PARSE_DESC_TELEPHONE_H_

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

// telephone_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  reserved_future_use  2 bslbf
//  foreign_availability  1 bslbf
//  connection_type  5 uimsbf
//  reserved_future_use  1 bslbf
//  country_prefix_length  2 uimsbf
//  international_area_code_length  3 uimsbf
//  operator_code_length  2 uimsbf
//  reserved_future_use  1 bslbf
//  national_area_code_length  3 uimsbf
//  core_number_length  4 uimsbf
//  for (i=0;i<N;i++){
//   country_prefix_char  8 uimsbf
//  }
//  for (i=0;i<N;i++){
//   international_area_code_char  8 uimsbf
//  }
//  for (i=0;i<N;i++){
//   operator_code_char  8 uimsbf
//  }
//  for (i=0;i<N;i++){
//   national_area_code_char  8 uimsbf
//  }
//  for (i=0;i<N;i++){
//   core_number_char  8 uimsbf
//  }
// }

struct Descriptor_telephone {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned foreign_availability ;                   	   // 1 bits
	unsigned connection_type ;                        	   // 5 bits
	unsigned country_prefix_length ;                  	   // 2 bits
	unsigned international_area_code_length ;         	   // 3 bits
	unsigned operator_code_length ;                   	   // 2 bits
	unsigned national_area_code_length ;              	   // 3 bits
	unsigned core_number_length ;                     	   // 4 bits
#define MAX_COUNTRY_PREFIX_LEN 4
	char country_prefix[MAX_COUNTRY_PREFIX_LEN + 1] ;
#define MAX_INTERNATIONAL_AREA_CODE_LEN 8
	char international_area_code[MAX_INTERNATIONAL_AREA_CODE_LEN + 1] ;
#define MAX_OPERATOR_CODE_LEN 4
	char operator_code[MAX_OPERATOR_CODE_LEN + 1] ;
#define MAX_NATIONAL_AREA_CODE_LEN 8
	char national_area_code[MAX_NATIONAL_AREA_CODE_LEN + 1] ;
#define MAX_CORE_NUMBER_LEN 16
	char core_number[MAX_CORE_NUMBER_LEN + 1] ;
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_telephone(struct Descriptor_telephone *td, int level) ;
struct Descriptor *parse_telephone(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_telephone(struct Descriptor_telephone *td) ;

#endif /* PARSE_DESC_TELEPHONE_H_ */

