/*
 * parse_desc_cell_list.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_CELL_LIST_H_
#define PARSE_DESC_CELL_LIST_H_

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

// cell_list_descriptor(){
//  descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//  for (i=0;i<N;i++){
//   cell_id  16 uimsbf
//   cell_latitude  16 uimsbf
//   cell_longitude  16 uimsbf
//   cell_extent_of_latitude  12 uimsbf
//   cell_extent_of_longitude  12 uimsbf
//   subcell_info_loop_length  8 uimsbf
//   for (j=0;j<N;j++){
//    cell_id_extension  8 uimsbf
//    subcell_latitude  16 uimsbf
//    subcell_longitude  16 uimsbf
//    subcell_extent_of_latitude  12 uimsbf
//    subcell_extent_of_longitude  12 uimsbf
//     }
//  }
// }

struct CLD1_entry {
	// linked list
	struct list_head next ;

	unsigned cell_id_extension ;                      	   // 8 bits
	unsigned subcell_latitude ;                       	   // 16 bits
	unsigned subcell_longitude ;                      	   // 16 bits
	unsigned subcell_extent_of_latitude ;             	   // 12 bits
	unsigned subcell_extent_of_longitude ;            	   // 12 bits
} ;

struct CLD_entry {
	// linked list
	struct list_head next ;

	unsigned cell_id ;                                	   // 16 bits
	unsigned cell_latitude ;                          	   // 16 bits
	unsigned cell_longitude ;                         	   // 16 bits
	unsigned cell_extent_of_latitude ;                	   // 12 bits
	unsigned cell_extent_of_longitude ;               	   // 12 bits
	unsigned subcell_info_loop_length ;               	   // 8 bits
	
	// linked list of CLD1_entry
	struct list_head cld1_array ;
	
} ;

struct Descriptor_cell_list {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	
	// linked list of CLD_entry
	struct list_head cld_array ;
	
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_cell_list(struct Descriptor_cell_list *cld, int level) ;
struct Descriptor *parse_cell_list(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_cell_list(struct Descriptor_cell_list *cld) ;

#endif /* PARSE_DESC_CELL_LIST_H_ */

