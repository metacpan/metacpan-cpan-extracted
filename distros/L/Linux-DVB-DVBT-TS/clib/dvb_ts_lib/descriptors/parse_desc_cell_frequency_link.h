/*
 * parse_desc_cell_frequency_link.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_CELL_FREQUENCY_LINK_H_
#define PARSE_DESC_CELL_FREQUENCY_LINK_H_

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

// cell_frequency_link_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  for (i=0;i<N;i++){
//   cell_id  16 uimsbf
//   frequency  32 uimsbf
//   subcell_info_loop_length  8 uimsbf
//   for (j=0;j<N;j++){
//    cell_id_extension  8 uimsbf
//    transposer_frequency  32 uimsbf
//    }
//  }
// }

struct CFLD1_entry {
	// linked list
	struct list_head next ;

	unsigned cell_id_extension ;                      	   // 8 bits
	unsigned transposer_frequency ;                   	   // 32 bits
} ;

struct CFLD_entry {
	// linked list
	struct list_head next ;

	unsigned cell_id ;                                	   // 16 bits
	unsigned frequency ;                              	   // 32 bits
	unsigned subcell_info_loop_length ;               	   // 8 bits
	
	// linked list of CFLD1_entry
	struct list_head cfld1_array ;
	
} ;

struct Descriptor_cell_frequency_link {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	
	// linked list of CFLD_entry
	struct list_head cfld_array ;
	
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_cell_frequency_link(struct Descriptor_cell_frequency_link *cfld, int level) ;
struct Descriptor *parse_cell_frequency_link(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_cell_frequency_link(struct Descriptor_cell_frequency_link *cfld) ;

#endif /* PARSE_DESC_CELL_FREQUENCY_LINK_H_ */

