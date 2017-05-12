/*
 * desc_structs.h
 *
 *  Created on: 2 Apr 2011
 *      Author: sdprice1
 */

#ifndef DESC_STRUCTS_H_
#define DESC_STRUCTS_H_

/*=============================================================================================*/
// USES
/*=============================================================================================*/
#include "list.h"
#include "ts_bits.h"

/*=============================================================================================*/
// CONSTANTS
/*=============================================================================================*/

// List of descriptors
//
// From ETSI 300-468
enum TS_descriptor_ids {
	DESC_NETWORK_NAME                        	= 0x40, //
	DESC_SERVICE_LIST                        	= 0x41, //
	DESC_STUFFING                            	= 0x42,
	DESC_SATELLITE_DELIVERY_SYSTEM           	= 0x43,
	DESC_CABLE_DELIVERY_SYSTEM               	= 0x44,
	DESC_VBI_DATA                            	= 0x45,
	DESC_VBI_TELETEXT                        	= 0x46,
	DESC_BOUQUET_NAME                        	= 0x47,
	DESC_SERVICE                             	= 0x48, //
	DESC_COUNTRY_AVAILABILITY                	= 0x49,
	DESC_LINKAGE                             	= 0x4A, //
	DESC_NVOD_REFERENCE                      	= 0x4B,
	DESC_TIME_SHIFTED_SERVICE                	= 0x4C,
	DESC_SHORT_EVENT                         	= 0x4D, //
	DESC_EXTENDED_EVENT                      	= 0x4E,
	DESC_TIME_SHIFTED_EVENT                  	= 0x4F,
	DESC_COMPONENT                           	= 0x50, //
	DESC_MOSAIC                              	= 0x51,
	DESC_STREAM_IDENTIFIER                   	= 0x52, //
	DESC_CA_IDENTIFIER                       	= 0x53, //
	DESC_CONTENT                             	= 0x54, //
	DESC_PARENTAL_RATING                     	= 0x55,
	DESC_TELETEXT                            	= 0x56,
	DESC_TELEPHONE                           	= 0x57,
	DESC_LOCAL_TIME_OFFSET                   	= 0x58, //
	DESC_SUBTITLING                          	= 0x59, //
	DESC_TERRESTRIAL_DELIVERY_SYSTEM         	= 0x5A, //
	DESC_MULTILINGUAL_NETWORK_NAME           	= 0x5B,
	DESC_MULTILINGUAL_BOUQUET_NAME           	= 0x5C,
	DESC_MULTILINGUAL_SERVICE_NAME           	= 0x5D,
	DESC_MULTILINGUAL_COMPONENT              	= 0x5E,
	DESC_PRIVATE_DATA_SPECIFIER              	= 0x5F, //
	DESC_SERVICE_MOVE                        	= 0x60,
	DESC_SHORT_SMOOTHING_BUFFER              	= 0x61,
	DESC_FREQUENCY_LIST                      	= 0x62,
	DESC_PARTIAL_TRANSPORT_STREAM            	= 0x63,
	DESC_DATA_BROADCAST                      	= 0x64,
	DESC_SCRAMBLING                          	= 0x65,
	DESC_DATA_BROADCAST_ID                   	= 0x66, //
	DESC_TRANSPORT_STREAM                    	= 0x67,
	DESC_DSNG                                	= 0x68,
	DESC_PDC                                 	= 0x69,
	DESC_AC3                                 	= 0x6A,
	DESC_ANCILLARY_DATA                      	= 0x6B,
	DESC_CELL_LIST                           	= 0x6C,
	DESC_CELL_FREQUENCY_LINK                 	= 0x6D,
	DESC_ANNOUNCEMENT_SUPPORT                	= 0x6E,
	DESC_APPLICATION_SIGNALLING              	= 0x6F,
	DESC_ADAPTATION_FIELD_DATA               	= 0x70,
	DESC_SERVICE_IDENTIFIER                  	= 0x71,
	DESC_SERVICE_AVAILABILITY                	= 0x72,
	DESC_DEFAULT_AUTHORITY                   	= 0x73,
	DESC_RELATED_CONTENT                     	= 0x74,
	DESC_TVA_ID                              	= 0x75,
	DESC_TVA_CONTENT_IDENTIFIER                	= 0x76, //
	DESC_TIME_SLICE_FEC_IDENTIFIER           	= 0x77,
	DESC_ECM_REPETITION_RATE                 	= 0x78,
	DESC_S2_SATELLITE_DELIVERY_SYSTEM        	= 0x79,
	DESC_ENHANCED_AC3                        	= 0x7A,
	DESC_DTS                                 	= 0x7B,
	DESC_AAC                                 	= 0x7C,
	DESC_EXTENSION                             	= 0x7F, //

	DESC_MAX									= 0xFF
};

/*=============================================================================================*/
// MACROS
/*=============================================================================================*/

/*=============================================================================================*/
// STRUCTS
/*=============================================================================================*/

// A generic descriptor - all descriptors start like this (with the addition of linked list)
struct Descriptor {
	// linked list
	struct list_head next ;

	// contents
	unsigned descriptor_tag ;                         	   // 8 bits = enum TS_descriptor_ids
	unsigned descriptor_length ;                      	   // 8 bits

	void *descriptor_data ;
};


#endif /* DESC_STRUCTS_H_ */
