/*
 * parse_desc_vbi_data.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_VBI_DATA_H_
#define PARSE_DESC_VBI_DATA_H_

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

// VBI_data_descriptor() {
//  descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//   for (i=0; i<N; i++) {
//   data_service_id  8 uimsbf
//   data_service_descriptor_length  8 uimsbf
//   if (data_service_id==0x01 ||
//       for (i=0; i<N; i++) {
//     reserved  2 bslbf
//     field_parity  1 bslbf
//     line_offset  5 uimsbf
//       }
//   } else {
//       for (i=0; i<N; i++) {
//     reserved  8 bslbf
//       }
//     }
//  }
// }

struct VDD1_entry {
	// linked list
	struct list_head next ;

	unsigned field_parity ;                           	   // 1 bits
	unsigned line_offset ;                            	   // 5 bits
} ;

struct VDD_entry {
	// linked list
	struct list_head next ;

	unsigned data_service_id ;                        	   // 8 bits
	unsigned data_service_descriptor_length ;         	   // 8 bits
	// IF
	
	// linked list of VDD1_entry
	struct list_head vdd1_array ;
	
	// ELSE
#define MAX_DATA_SERVICE_DESCRIPTOR_LEN 256
	unsigned data_service_descriptor[MAX_DATA_SERVICE_DESCRIPTOR_LEN + 1] ;
	// ENDIF
} ;

struct Descriptor_vbi_data {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	
	// linked list of VDD_entry
	struct list_head vdd_array ;
	
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_vbi_data(struct Descriptor_vbi_data *vdd, int level) ;
struct Descriptor *parse_vbi_data(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_vbi_data(struct Descriptor_vbi_data *vdd) ;

#endif /* PARSE_DESC_VBI_DATA_H_ */

