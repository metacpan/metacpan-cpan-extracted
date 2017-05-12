/*
 * si_structs.h
 *
 *  Created on: 2 Apr 2011
 *      Author: sdprice1
 */

#ifndef SI_STRUCTS_H_
#define SI_STRUCTS_H_

/*=============================================================================================*/
// USES
/*=============================================================================================*/
#include "list.h"
#include "ts_bits.h"

/*=============================================================================================*/
// CONSTANTS
/*=============================================================================================*/

#define SI_CRC_LEN				4
#define SI_HEADER_LEN			4
#define SECTION_HEADER_LEN		3

// Running Status
//
//Value Meaning 
//0 undefined 
//1 not running 
//2  starts in a few seconds (e.g. for video recording) 
//3 pausing 
//4 running 
//5 service off­air 
//6 to 7  reserved for future use 
enum SI_Running_Status {
	RUNNING_STATUS_UNDEF 		= 0,
	RUNNING_STATUS_NOT_RUNNING 	= 1,
	RUNNING_STATUS_PENDING 		= 1,	// alias
	RUNNING_STATUS_STARTING 	= 2,
	RUNNING_STATUS_PAUSING 		= 3,
	RUNNING_STATUS_RUNNING 		= 4,
	RUNNING_STATUS_OFF_AIR		= 5,

	// Internal - set when seen service running
	RUNNING_STATUS_COMPLETE		= 0x10,
};


// List of tables
//
//y	0x00 program_association_section 
//	0x01 conditional_access_section 
//y	0x02 program_map_section 
//	0x03 transport_stream_description_section 
//	0x04 to 0x3F  reserved 
//y	0x40  network_information_section ­ actual_network 
//	0x41  network_information_section ­ other_network 
//y	0x42 service_description_section  ­ actual_transport_stream  
//	0x43 to 0x45  reserved for future use 
//y	0x46 service_description_section ­ other_transport_stream 
//	0x47 to 0x49  reserved for future use 
//	0x4A bouquet_association_section 
//	0x4B to 0x4D  reserved for future use 
//y	0x4E  event_information_section ­ actual_transport_stream, present/following 
//y	0x4F  event_information_section ­ other_transport_stream, present/following 
//y	0x50 to 0x5F  event_information_section ­ actual_transport_stream, schedule 
//y	0x60 to 0x6F  event_information_section ­ other_transport_stream, schedule 
//	0x70 time_date_section 
//	0x71 running_status_section 
//	0x72 stuffing_section 
//y	0x73 time_offset_section 
//	0x74  application information section (TS 102 812 [17]) 
//	0x75  container section (TS 102 323 [15]) 
//	0x76  related content section (TS 102 323 [15]) 
//	0x77 content identifier  section (TS 102 323 [15]) 
//	0x78  MPE­FEC section (EN 301 192 [4]) 
//	0x79  resolution notification section (TS 102 323 [15]) 
//	0x79 to 0x7D  reserved for future use 
//	0x7E discontinuity_information_section 
//	0x7F selection_information_section 
//	0x80 to 0xFE  user defined 
//	0xFF reserved 
//
enum TS_section_ids {
	SECTION_PAT					= 0x00,
	SECTION_CAT					= 0x01,
	SECTION_PMT					= 0x02,
	SECTION_TSDT				= 0x03,

	SECTION_NIT_ACTUAL			= 0x40,
	SECTION_NIT_OTHER			= 0x41,
	SECTION_SDT_ACTUAL			= 0x42,
	SECTION_SDT_OTHER			= 0x46,

	SECTION_BAT					= 0x4A,

	SECTION_EIT_START			= 0x4E,
	SECTION_EIT_NOW_ACTUAL		= 0x4E,
	SECTION_EIT_NOW_OTHER		= 0x4F,

	SECTION_EIT_ACTUAL			= 0x50,
	SECTION_EIT_ACTUAL_START	= 0x50,
	SECTION_EIT_ACTUAL_END		= 0x5F,
	SECTION_EIT_OTHER			= 0x60,
	SECTION_EIT_OTHER_START		= 0x60,
	SECTION_EIT_OTHER_END		= 0x6F,
	SECTION_EIT_END				= 0x6F,

	SECTION_TDT					= 0x70,
	SECTION_RST					= 0x71,
	SECTION_ST					= 0x72,
	SECTION_TOT					= 0x73,

	SECTION_CIT					= 0x77,

	SECTION_DIT					= 0x7E,
	SECTION_SIT					= 0x7F,

	SECTION_MAX					= 0xFF,
};


/*=============================================================================================*/
// MACROS
/*=============================================================================================*/

/*=============================================================================================*/
// STRUCTS
/*=============================================================================================*/

//----------------------------------------------------------------------------------------------

// All sections/tables start with this
struct Section {
	unsigned table_id ;                               	   // 8 bits
	unsigned section_syntax_indicator ;               	   // 1 bits
	// unsigned reserved_future_use ;                 	   // 1 bits
	// unsigned reserved ;                            	   // 2 bits
	unsigned section_length ;                         	   // 12 bits

	void	*section_data ;
} ;

// A section handler
struct TS_reader ;
struct TS_state ;
typedef void (*Section_handler)(struct TS_reader *tsreader, struct TS_state *tsstate, struct Section *section, void *user_data) ;


//----------------------------------------------------------------------------------------------
// Table to register decoding of sections

struct Section_decode_flags {
	unsigned	decode_descriptor : 1 ;
}  ;

// There is an array of these entries, one per table id
struct Section_registry {
	Section_handler						handler ;
	struct Section_decode_flags			flags ;
};


#endif /* SI_STRUCTS_H_ */
