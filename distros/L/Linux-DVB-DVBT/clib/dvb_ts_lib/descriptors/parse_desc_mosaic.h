/*
 * parse_desc_mosaic.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_MOSAIC_H_
#define PARSE_DESC_MOSAIC_H_

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

// mosaic_descriptor(){
//  descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//  mosaic_entry_point  1 bslbf
//  number_of_horizontal_elementary_cells   3 uimsbf
//  reserved_future_use  1 bslbf
//  number_of_vertical_elementary_cells   3 uimsbf
//   for (i=0;i<N; i++) {
//   logical_cell_id  6 uimsbf
//   reserved_future_use  7 bslbf
//   logical_cell_presentation_info  3 uimsbf
//   elementary_cell_field_length  8 uimsbf
//   for (i=0;j<elementary_cell_field_length;j++) {
//    reserved_future_use  2 bslbf
//    elementary_cell_id  6 uimsbf
//     }
//   cell_linkage_info   8 uimsbf
//   If (cell_linkage_info ==0x01){
//    bouquet_id  16 uimsbf
//     }
//   If (cell_linkage_info ==0x02){
//    original_network_id  16 uimsbf
//    transport_stream_id  16 uimsbf
//    service_id  16 uimsbf
//     }
//   If (cell_linkage_info ==0x03){
//    original_network_id  16 uimsbf
//    transport_stream_id  16 uimsbf
//    service_id  16 uimsbf
//     }
//   If (cell_linkage_info ==0x04){
//    original_network_id  16 uimsbf
//    transport_stream_id  16 uimsbf
//    service_id  16 uimsbf
//    event_id  16 uimsbf
//     }
//  }
// }

struct MD1_entry {
	// linked list
	struct list_head next ;

	unsigned elementary_cell_id ;                     	   // 6 bits
} ;

struct MD_entry {
	// linked list
	struct list_head next ;

	unsigned logical_cell_id ;                        	   // 6 bits
	unsigned logical_cell_presentation_info ;         	   // 3 bits
	unsigned elementary_cell_field_length ;           	   // 8 bits
	
	// linked list of MD1_entry
	struct list_head md1_array ;
	
	unsigned cell_linkage_info ;                      	   // 8 bits
	// IF
	unsigned bouquet_id ;                             	   // 16 bits
	// ENDIF
	// IF
	unsigned original_network_id ;                    	   // 16 bits
	unsigned transport_stream_id ;                    	   // 16 bits
	unsigned service_id ;                             	   // 16 bits
	// ENDIF
	// IF
	unsigned original_network_id1 ;                   	   // 16 bits
	unsigned transport_stream_id1 ;                   	   // 16 bits
	unsigned service_id1 ;                            	   // 16 bits
	// ENDIF
	// IF
	unsigned original_network_id2 ;                   	   // 16 bits
	unsigned transport_stream_id2 ;                   	   // 16 bits
	unsigned service_id2 ;                            	   // 16 bits
	unsigned event_id ;                               	   // 16 bits
	// ENDIF
} ;

struct Descriptor_mosaic {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned mosaic_entry_point ;                     	   // 1 bits
	unsigned number_of_horizontal_elementary_cells ;  	   // 3 bits
	unsigned number_of_vertical_elementary_cells ;    	   // 3 bits
	
	// linked list of MD_entry
	struct list_head md_array ;
	
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_mosaic(struct Descriptor_mosaic *md, int level) ;
struct Descriptor *parse_mosaic(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_mosaic(struct Descriptor_mosaic *md) ;

#endif /* PARSE_DESC_MOSAIC_H_ */

