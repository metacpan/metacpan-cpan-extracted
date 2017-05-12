/*
 * parse_desc_linkage.h
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
 *      Author: sdprice1
 */

#ifndef PARSE_DESC_LINKAGE_H_
#define PARSE_DESC_LINKAGE_H_

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

// linkage_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  transport_stream_id  16 uimsbf
//  original_network_id  16 uimsbf
//  service_id  16 uimsbf
//  linkage_type  8 uimsbf
//   if (linkage_type !=0x08){
//   for (i=0;i<N;i++){
//    private_data_byte  8 bslbf
//     }
//  }
//   if (linkage_type ==0x08){
//   hand_over_type  4 bslbf
//   reserved_future_use  3 bslbf
//   origin_type  1 bslbf
//   if (hand_over_type ==0x01
//    network_id  16 uimsbf
//     }
//   if (origin_type ==0x00){
//    initial_service_id  16 uimsbf
//     }
//   for (i=0;i<N;i++){
//    private_data_byte  8 bslbf
//     }
//  }
// }

struct Descriptor_linkage {

	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits
	unsigned descriptor_length ;                      	   // 8 bits
	unsigned transport_stream_id ;                    	   // 16 bits
	unsigned original_network_id ;                    	   // 16 bits
	unsigned service_id ;                             	   // 16 bits
	unsigned linkage_type ;                           	   // 8 bits
	// IF
#define MAX_PRIVATE_DATA_LEN 256
	char private_data[MAX_PRIVATE_DATA_LEN + 1] ;
	// ENDIF
	// IF
	unsigned hand_over_type ;                         	   // 4 bits
	unsigned origin_type ;                            	   // 1 bits
	// IF
	unsigned network_id ;                             	   // 16 bits
	// ENDIF
	// IF
	unsigned initial_service_id ;                     	   // 16 bits
	// ENDIF
#define MAX_PRIVATE_DATA1_LEN 256
	char private_data1[MAX_PRIVATE_DATA1_LEN + 1] ;
	// ENDIF
};

	
/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void print_linkage(struct Descriptor_linkage *ld, int level) ;
struct Descriptor *parse_linkage(struct TS_bits *bits, unsigned tag, unsigned len) ;
void free_linkage(struct Descriptor_linkage *ld) ;

#endif /* PARSE_DESC_LINKAGE_H_ */

