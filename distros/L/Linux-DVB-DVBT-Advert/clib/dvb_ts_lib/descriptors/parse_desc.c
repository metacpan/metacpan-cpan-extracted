/*
 * parse_desc.c
 *
 *  Created on: 2 Apr 2011
 *      Author: sdprice1
 */


// VERSION = 1.00

/*=============================================================================================*/
// USES
/*=============================================================================================*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>
#include <fcntl.h>
#include <inttypes.h>

#include "parse_desc.h"
#include "ts_bits.h"

// Descriptors:
#include "parse_desc_network_name.h"  /* 0x40 */
#include "parse_desc_service_list.h"  /* 0x41 */
#include "parse_desc_stuffing.h"  /* 0x42 */
#include "parse_desc_satellite_delivery_system.h"  /* 0x43 */
#include "parse_desc_cable_delivery_system.h"  /* 0x44 */
#include "parse_desc_vbi_data.h"  /* 0x45 */
#include "parse_desc_vbi_teletext.h"  /* 0x46 */
#include "parse_desc_bouquet_name.h"  /* 0x47 */
#include "parse_desc_service.h"  /* 0x48 */
#include "parse_desc_country_availability.h"  /* 0x49 */
#include "parse_desc_linkage.h"  /* 0x4a */
#include "parse_desc_nvod_reference.h"  /* 0x4b */
#include "parse_desc_time_shifted_service.h"  /* 0x4c */
#include "parse_desc_short_event.h"  /* 0x4d */
#include "parse_desc_extended_event.h"  /* 0x4e */
#include "parse_desc_time_shifted_event.h"  /* 0x4f */
#include "parse_desc_component.h"  /* 0x50 */
#include "parse_desc_mosaic.h"  /* 0x51 */
#include "parse_desc_stream_identifier.h"  /* 0x52 */
#include "parse_desc_ca_identifier.h"  /* 0x53 */
#include "parse_desc_content.h"  /* 0x54 */
#include "parse_desc_parental_rating.h"  /* 0x55 */
#include "parse_desc_teletext.h"  /* 0x56 */
#include "parse_desc_telephone.h"  /* 0x57 */
#include "parse_desc_local_time_offset.h"  /* 0x58 */
#include "parse_desc_subtitling.h"  /* 0x59 */
#include "parse_desc_terrestrial_delivery_system.h"  /* 0x5a */
#include "parse_desc_multilingual_network_name.h"  /* 0x5b */
#include "parse_desc_multilingual_bouquet_name.h"  /* 0x5c */
#include "parse_desc_multilingual_service_name.h"  /* 0x5d */
#include "parse_desc_multilingual_component.h"  /* 0x5e */
#include "parse_desc_private_data_specifier.h"  /* 0x5f */
#include "parse_desc_service_move.h"  /* 0x60 */
#include "parse_desc_short_smoothing_buffer.h"  /* 0x61 */
#include "parse_desc_frequency_list.h"  /* 0x62 */
#include "parse_desc_partial_transport_stream.h"  /* 0x63 */
#include "parse_desc_data_broadcast.h"  /* 0x64 */
#include "parse_desc_scrambling.h"  /* 0x65 */
#include "parse_desc_data_broadcast_id.h"  /* 0x66 */
#include "parse_desc_transport_stream.h"  /* 0x67 */
#include "parse_desc_dsng.h"  /* 0x68 */
#include "parse_desc_pdc.h"  /* 0x69 */
#include "parse_desc_ancillary_data.h"  /* 0x6b */
#include "parse_desc_cell_frequency_link.h"  /* 0x6d */
#include "parse_desc_announcement_support.h"  /* 0x6e */
#include "parse_desc_adaptation_field_data.h"  /* 0x70 */
#include "parse_desc_service_availability.h"  /* 0x72 */
#include "parse_desc_tva_content_identifier.h"  /* 0x76 */
#include "parse_desc_s2_satellite_delivery_system.h"  /* 0x79 */
#include "parse_desc_extension.h"  /* 0x7f */

/*=============================================================================================*/
// CONSTANTS
/*=============================================================================================*/

/*=============================================================================================*/
// MACROS
/*=============================================================================================*/

/*=============================================================================================*/
// FUNCTIONS
/*=============================================================================================*/

/* ----------------------------------------------------------------------- */
void free_descriptors_list(struct list_head *desc_array)
{
    struct list_head  *item, *safe;
    struct Descriptor  *desc;

    list_for_each_safe(item,safe,desc_array) {
    	desc = list_entry(item, struct Descriptor, next);
		free_desc(desc) ;
    };

}

/* ----------------------------------------------------------------------- */
// Dump out all descriptors in the list
void print_desc_list(struct list_head *descriptors_array, int level)
{
    struct list_head  *item, *safe;
    struct Descriptor  *desc;

    list_for_each_safe(item,safe,descriptors_array) {
    	desc = list_entry(item, struct Descriptor, next);
		print_desc(desc, level) ;
    };

}

/* ----------------------------------------------------------------------- */
// Free this descriptor
void free_desc(struct Descriptor *descriptor)
{
	switch (descriptor->descriptor_tag)
	{
	case DESC_NETWORK_NAME:
		free_network_name((struct Descriptor_network_name *)descriptor) ;
		break ;

	case DESC_SERVICE_LIST:
		free_service_list((struct Descriptor_service_list *)descriptor) ;
		break ;

	case DESC_STUFFING:
		free_stuffing((struct Descriptor_stuffing *)descriptor) ;
		break ;

	case DESC_SATELLITE_DELIVERY_SYSTEM:
		free_satellite_delivery_system((struct Descriptor_satellite_delivery_system *)descriptor) ;
		break ;

	case DESC_CABLE_DELIVERY_SYSTEM:
		free_cable_delivery_system((struct Descriptor_cable_delivery_system *)descriptor) ;
		break ;

	case DESC_VBI_DATA:
		free_vbi_data((struct Descriptor_vbi_data *)descriptor) ;
		break ;

	case DESC_VBI_TELETEXT:
		free_vbi_teletext((struct Descriptor_vbi_teletext *)descriptor) ;
		break ;

	case DESC_BOUQUET_NAME:
		free_bouquet_name((struct Descriptor_bouquet_name *)descriptor) ;
		break ;

	case DESC_SERVICE:
		free_service((struct Descriptor_service *)descriptor) ;
		break ;

	case DESC_COUNTRY_AVAILABILITY:
		free_country_availability((struct Descriptor_country_availability *)descriptor) ;
		break ;

	case DESC_LINKAGE:
		free_linkage((struct Descriptor_linkage *)descriptor) ;
		break ;

	case DESC_NVOD_REFERENCE:
		free_nvod_reference((struct Descriptor_nvod_reference *)descriptor) ;
		break ;

	case DESC_TIME_SHIFTED_SERVICE:
		free_time_shifted_service((struct Descriptor_time_shifted_service *)descriptor) ;
		break ;

	case DESC_SHORT_EVENT:
		free_short_event((struct Descriptor_short_event *)descriptor) ;
		break ;

	case DESC_EXTENDED_EVENT:
		free_extended_event((struct Descriptor_extended_event *)descriptor) ;
		break ;

	case DESC_TIME_SHIFTED_EVENT:
		free_time_shifted_event((struct Descriptor_time_shifted_event *)descriptor) ;
		break ;

	case DESC_COMPONENT:
		free_component((struct Descriptor_component *)descriptor) ;
		break ;

	case DESC_MOSAIC:
		free_mosaic((struct Descriptor_mosaic *)descriptor) ;
		break ;

	case DESC_STREAM_IDENTIFIER:
		free_stream_identifier((struct Descriptor_stream_identifier *)descriptor) ;
		break ;

	case DESC_CA_IDENTIFIER:
		free_ca_identifier((struct Descriptor_ca_identifier *)descriptor) ;
		break ;

	case DESC_CONTENT:
		free_content((struct Descriptor_content *)descriptor) ;
		break ;

	case DESC_PARENTAL_RATING:
		free_parental_rating((struct Descriptor_parental_rating *)descriptor) ;
		break ;

	case DESC_TELETEXT:
		free_teletext((struct Descriptor_teletext *)descriptor) ;
		break ;

	case DESC_TELEPHONE:
		free_telephone((struct Descriptor_telephone *)descriptor) ;
		break ;

	case DESC_LOCAL_TIME_OFFSET:
		free_local_time_offset((struct Descriptor_local_time_offset *)descriptor) ;
		break ;

	case DESC_SUBTITLING:
		free_subtitling((struct Descriptor_subtitling *)descriptor) ;
		break ;

	case DESC_TERRESTRIAL_DELIVERY_SYSTEM:
		free_terrestrial_delivery_system((struct Descriptor_terrestrial_delivery_system *)descriptor) ;
		break ;

	case DESC_MULTILINGUAL_NETWORK_NAME:
		free_multilingual_network_name((struct Descriptor_multilingual_network_name *)descriptor) ;
		break ;

	case DESC_MULTILINGUAL_BOUQUET_NAME:
		free_multilingual_bouquet_name((struct Descriptor_multilingual_bouquet_name *)descriptor) ;
		break ;

	case DESC_MULTILINGUAL_SERVICE_NAME:
		free_multilingual_service_name((struct Descriptor_multilingual_service_name *)descriptor) ;
		break ;

	case DESC_MULTILINGUAL_COMPONENT:
		free_multilingual_component((struct Descriptor_multilingual_component *)descriptor) ;
		break ;

	case DESC_PRIVATE_DATA_SPECIFIER:
		free_private_data_specifier((struct Descriptor_private_data_specifier *)descriptor) ;
		break ;

	case DESC_SERVICE_MOVE:
		free_service_move((struct Descriptor_service_move *)descriptor) ;
		break ;

	case DESC_SHORT_SMOOTHING_BUFFER:
		free_short_smoothing_buffer((struct Descriptor_short_smoothing_buffer *)descriptor) ;
		break ;

	case DESC_FREQUENCY_LIST:
		free_frequency_list((struct Descriptor_frequency_list *)descriptor) ;
		break ;

	case DESC_PARTIAL_TRANSPORT_STREAM:
		free_partial_transport_stream((struct Descriptor_partial_transport_stream *)descriptor) ;
		break ;

	case DESC_DATA_BROADCAST:
		free_data_broadcast((struct Descriptor_data_broadcast *)descriptor) ;
		break ;

	case DESC_SCRAMBLING:
		free_scrambling((struct Descriptor_scrambling *)descriptor) ;
		break ;

	case DESC_DATA_BROADCAST_ID:
		free_data_broadcast_id((struct Descriptor_data_broadcast_id *)descriptor) ;
		break ;

	case DESC_TRANSPORT_STREAM:
		free_transport_stream((struct Descriptor_transport_stream *)descriptor) ;
		break ;

	case DESC_DSNG:
		free_dsng((struct Descriptor_dsng *)descriptor) ;
		break ;

	case DESC_PDC:
		free_pdc((struct Descriptor_pdc *)descriptor) ;
		break ;

	case DESC_ANCILLARY_DATA:
		free_ancillary_data((struct Descriptor_ancillary_data *)descriptor) ;
		break ;

	case DESC_CELL_FREQUENCY_LINK:
		free_cell_frequency_link((struct Descriptor_cell_frequency_link *)descriptor) ;
		break ;

	case DESC_ANNOUNCEMENT_SUPPORT:
		free_announcement_support((struct Descriptor_announcement_support *)descriptor) ;
		break ;

	case DESC_ADAPTATION_FIELD_DATA:
		free_adaptation_field_data((struct Descriptor_adaptation_field_data *)descriptor) ;
		break ;

	case DESC_SERVICE_AVAILABILITY:
		free_service_availability((struct Descriptor_service_availability *)descriptor) ;
		break ;

	case DESC_TVA_CONTENT_IDENTIFIER:
		free_tva_content_identifier((struct Descriptor_tva_content_identifier *)descriptor) ;
		break ;

	case DESC_S2_SATELLITE_DELIVERY_SYSTEM:
		free_s2_satellite_delivery_system((struct Descriptor_s2_satellite_delivery_system *)descriptor) ;
		break ;

	case DESC_EXTENSION:
		free_extension((struct Descriptor_extension *)descriptor) ;
		break ;

	default:
		break ;
	}
}


/* ----------------------------------------------------------------------- */
// Dump out this descriptor
void print_desc(struct Descriptor *descriptor, int level)
{
	switch (descriptor->descriptor_tag)
	{
	case DESC_NETWORK_NAME:
		print_network_name((struct Descriptor_network_name *)descriptor, level) ;
		break ;

	case DESC_SERVICE_LIST:
		print_service_list((struct Descriptor_service_list *)descriptor, level) ;
		break ;

	case DESC_STUFFING:
		print_stuffing((struct Descriptor_stuffing *)descriptor, level) ;
		break ;

	case DESC_SATELLITE_DELIVERY_SYSTEM:
		print_satellite_delivery_system((struct Descriptor_satellite_delivery_system *)descriptor, level) ;
		break ;

	case DESC_CABLE_DELIVERY_SYSTEM:
		print_cable_delivery_system((struct Descriptor_cable_delivery_system *)descriptor, level) ;
		break ;

	case DESC_VBI_DATA:
		print_vbi_data((struct Descriptor_vbi_data *)descriptor, level) ;
		break ;

	case DESC_VBI_TELETEXT:
		print_vbi_teletext((struct Descriptor_vbi_teletext *)descriptor, level) ;
		break ;

	case DESC_BOUQUET_NAME:
		print_bouquet_name((struct Descriptor_bouquet_name *)descriptor, level) ;
		break ;

	case DESC_SERVICE:
		print_service((struct Descriptor_service *)descriptor, level) ;
		break ;

	case DESC_COUNTRY_AVAILABILITY:
		print_country_availability((struct Descriptor_country_availability *)descriptor, level) ;
		break ;

	case DESC_LINKAGE:
		print_linkage((struct Descriptor_linkage *)descriptor, level) ;
		break ;

	case DESC_NVOD_REFERENCE:
		print_nvod_reference((struct Descriptor_nvod_reference *)descriptor, level) ;
		break ;

	case DESC_TIME_SHIFTED_SERVICE:
		print_time_shifted_service((struct Descriptor_time_shifted_service *)descriptor, level) ;
		break ;

	case DESC_SHORT_EVENT:
		print_short_event((struct Descriptor_short_event *)descriptor, level) ;
		break ;

	case DESC_EXTENDED_EVENT:
		print_extended_event((struct Descriptor_extended_event *)descriptor, level) ;
		break ;

	case DESC_TIME_SHIFTED_EVENT:
		print_time_shifted_event((struct Descriptor_time_shifted_event *)descriptor, level) ;
		break ;

	case DESC_COMPONENT:
		print_component((struct Descriptor_component *)descriptor, level) ;
		break ;

	case DESC_MOSAIC:
		print_mosaic((struct Descriptor_mosaic *)descriptor, level) ;
		break ;

	case DESC_STREAM_IDENTIFIER:
		print_stream_identifier((struct Descriptor_stream_identifier *)descriptor, level) ;
		break ;

	case DESC_CA_IDENTIFIER:
		print_ca_identifier((struct Descriptor_ca_identifier *)descriptor, level) ;
		break ;

	case DESC_CONTENT:
		print_content((struct Descriptor_content *)descriptor, level) ;
		break ;

	case DESC_PARENTAL_RATING:
		print_parental_rating((struct Descriptor_parental_rating *)descriptor, level) ;
		break ;

	case DESC_TELETEXT:
		print_teletext((struct Descriptor_teletext *)descriptor, level) ;
		break ;

	case DESC_TELEPHONE:
		print_telephone((struct Descriptor_telephone *)descriptor, level) ;
		break ;

	case DESC_LOCAL_TIME_OFFSET:
		print_local_time_offset((struct Descriptor_local_time_offset *)descriptor, level) ;
		break ;

	case DESC_SUBTITLING:
		print_subtitling((struct Descriptor_subtitling *)descriptor, level) ;
		break ;

	case DESC_TERRESTRIAL_DELIVERY_SYSTEM:
		print_terrestrial_delivery_system((struct Descriptor_terrestrial_delivery_system *)descriptor, level) ;
		break ;

	case DESC_MULTILINGUAL_NETWORK_NAME:
		print_multilingual_network_name((struct Descriptor_multilingual_network_name *)descriptor, level) ;
		break ;

	case DESC_MULTILINGUAL_BOUQUET_NAME:
		print_multilingual_bouquet_name((struct Descriptor_multilingual_bouquet_name *)descriptor, level) ;
		break ;

	case DESC_MULTILINGUAL_SERVICE_NAME:
		print_multilingual_service_name((struct Descriptor_multilingual_service_name *)descriptor, level) ;
		break ;

	case DESC_MULTILINGUAL_COMPONENT:
		print_multilingual_component((struct Descriptor_multilingual_component *)descriptor, level) ;
		break ;

	case DESC_PRIVATE_DATA_SPECIFIER:
		print_private_data_specifier((struct Descriptor_private_data_specifier *)descriptor, level) ;
		break ;

	case DESC_SERVICE_MOVE:
		print_service_move((struct Descriptor_service_move *)descriptor, level) ;
		break ;

	case DESC_SHORT_SMOOTHING_BUFFER:
		print_short_smoothing_buffer((struct Descriptor_short_smoothing_buffer *)descriptor, level) ;
		break ;

	case DESC_FREQUENCY_LIST:
		print_frequency_list((struct Descriptor_frequency_list *)descriptor, level) ;
		break ;

	case DESC_PARTIAL_TRANSPORT_STREAM:
		print_partial_transport_stream((struct Descriptor_partial_transport_stream *)descriptor, level) ;
		break ;

	case DESC_DATA_BROADCAST:
		print_data_broadcast((struct Descriptor_data_broadcast *)descriptor, level) ;
		break ;

	case DESC_SCRAMBLING:
		print_scrambling((struct Descriptor_scrambling *)descriptor, level) ;
		break ;

	case DESC_DATA_BROADCAST_ID:
		print_data_broadcast_id((struct Descriptor_data_broadcast_id *)descriptor, level) ;
		break ;

	case DESC_TRANSPORT_STREAM:
		print_transport_stream((struct Descriptor_transport_stream *)descriptor, level) ;
		break ;

	case DESC_DSNG:
		print_dsng((struct Descriptor_dsng *)descriptor, level) ;
		break ;

	case DESC_PDC:
		print_pdc((struct Descriptor_pdc *)descriptor, level) ;
		break ;

	case DESC_ANCILLARY_DATA:
		print_ancillary_data((struct Descriptor_ancillary_data *)descriptor, level) ;
		break ;

	case DESC_CELL_FREQUENCY_LINK:
		print_cell_frequency_link((struct Descriptor_cell_frequency_link *)descriptor, level) ;
		break ;

	case DESC_ANNOUNCEMENT_SUPPORT:
		print_announcement_support((struct Descriptor_announcement_support *)descriptor, level) ;
		break ;

	case DESC_ADAPTATION_FIELD_DATA:
		print_adaptation_field_data((struct Descriptor_adaptation_field_data *)descriptor, level) ;
		break ;

	case DESC_SERVICE_AVAILABILITY:
		print_service_availability((struct Descriptor_service_availability *)descriptor, level) ;
		break ;

	case DESC_TVA_CONTENT_IDENTIFIER:
		print_tva_content_identifier((struct Descriptor_tva_content_identifier *)descriptor, level) ;
		break ;

	case DESC_S2_SATELLITE_DELIVERY_SYSTEM:
		print_s2_satellite_delivery_system((struct Descriptor_s2_satellite_delivery_system *)descriptor, level) ;
		break ;

	case DESC_EXTENSION:
		print_extension((struct Descriptor_extension *)descriptor, level) ;
		break ;

	default:
		break ;
	}
}

/* ----------------------------------------------------------------------- */
//
//descriptor(){
//descriptor_tag 8 uimsbf
//descriptor_length 8 uimsbf
//...
//}
//
enum TS_descriptor_ids parse_desc(struct list_head *descriptors_array, struct TS_bits *bits, unsigned decode_descriptor)
{
	// common
	unsigned tag = bits_get(bits, 8) ;
	unsigned len = bits_get(bits, 8) ;

	//== Only decode descriptor if required to ==
	if (decode_descriptor)
	{
int expected_buff_len = bits->buff_len+2-(len+2) ;
printf(" + parse_desc() Tag 0x%02x Len %d (Total=%d) [Buff=%d -> will be %d]\n", tag, len, len+2, bits->buff_len+2, expected_buff_len) ;

		// parse it
		struct Descriptor *descriptor = 0 ;

		switch (tag)
		{
		case DESC_NETWORK_NAME:
			descriptor = (struct Descriptor *)parse_network_name(bits, tag, len) ;
			break ;

		case DESC_SERVICE_LIST:
			descriptor = (struct Descriptor *)parse_service_list(bits, tag, len) ;
			break ;

		case DESC_STUFFING:
			descriptor = (struct Descriptor *)parse_stuffing(bits, tag, len) ;
			break ;

		case DESC_SATELLITE_DELIVERY_SYSTEM:
			descriptor = (struct Descriptor *)parse_satellite_delivery_system(bits, tag, len) ;
			break ;

		case DESC_CABLE_DELIVERY_SYSTEM:
			descriptor = (struct Descriptor *)parse_cable_delivery_system(bits, tag, len) ;
			break ;

		case DESC_VBI_DATA:
			descriptor = (struct Descriptor *)parse_vbi_data(bits, tag, len) ;
			break ;

		case DESC_VBI_TELETEXT:
			descriptor = (struct Descriptor *)parse_vbi_teletext(bits, tag, len) ;
			break ;

		case DESC_BOUQUET_NAME:
			descriptor = (struct Descriptor *)parse_bouquet_name(bits, tag, len) ;
			break ;

		case DESC_SERVICE:
			descriptor = (struct Descriptor *)parse_service(bits, tag, len) ;
			break ;

		case DESC_COUNTRY_AVAILABILITY:
			descriptor = (struct Descriptor *)parse_country_availability(bits, tag, len) ;
			break ;

		case DESC_LINKAGE:
			descriptor = (struct Descriptor *)parse_linkage(bits, tag, len) ;
			break ;

		case DESC_NVOD_REFERENCE:
			descriptor = (struct Descriptor *)parse_nvod_reference(bits, tag, len) ;
			break ;

		case DESC_TIME_SHIFTED_SERVICE:
			descriptor = (struct Descriptor *)parse_time_shifted_service(bits, tag, len) ;
			break ;

		case DESC_SHORT_EVENT:
			descriptor = (struct Descriptor *)parse_short_event(bits, tag, len) ;
			break ;

		case DESC_EXTENDED_EVENT:
			descriptor = (struct Descriptor *)parse_extended_event(bits, tag, len) ;
			break ;

		case DESC_TIME_SHIFTED_EVENT:
			descriptor = (struct Descriptor *)parse_time_shifted_event(bits, tag, len) ;
			break ;

		case DESC_COMPONENT:
			descriptor = (struct Descriptor *)parse_component(bits, tag, len) ;
			break ;

		case DESC_MOSAIC:
			descriptor = (struct Descriptor *)parse_mosaic(bits, tag, len) ;
			break ;

		case DESC_STREAM_IDENTIFIER:
			descriptor = (struct Descriptor *)parse_stream_identifier(bits, tag, len) ;
			break ;

		case DESC_CA_IDENTIFIER:
			descriptor = (struct Descriptor *)parse_ca_identifier(bits, tag, len) ;
			break ;

		case DESC_CONTENT:
			descriptor = (struct Descriptor *)parse_content(bits, tag, len) ;
			break ;

		case DESC_PARENTAL_RATING:
			descriptor = (struct Descriptor *)parse_parental_rating(bits, tag, len) ;
			break ;

		case DESC_TELETEXT:
			descriptor = (struct Descriptor *)parse_teletext(bits, tag, len) ;
			break ;

		case DESC_TELEPHONE:
			descriptor = (struct Descriptor *)parse_telephone(bits, tag, len) ;
			break ;

		case DESC_LOCAL_TIME_OFFSET:
			descriptor = (struct Descriptor *)parse_local_time_offset(bits, tag, len) ;
			break ;

		case DESC_SUBTITLING:
			descriptor = (struct Descriptor *)parse_subtitling(bits, tag, len) ;
			break ;

		case DESC_TERRESTRIAL_DELIVERY_SYSTEM:
			descriptor = (struct Descriptor *)parse_terrestrial_delivery_system(bits, tag, len) ;
			break ;

		case DESC_MULTILINGUAL_NETWORK_NAME:
			descriptor = (struct Descriptor *)parse_multilingual_network_name(bits, tag, len) ;
			break ;

		case DESC_MULTILINGUAL_BOUQUET_NAME:
			descriptor = (struct Descriptor *)parse_multilingual_bouquet_name(bits, tag, len) ;
			break ;

		case DESC_MULTILINGUAL_SERVICE_NAME:
			descriptor = (struct Descriptor *)parse_multilingual_service_name(bits, tag, len) ;
			break ;

		case DESC_MULTILINGUAL_COMPONENT:
			descriptor = (struct Descriptor *)parse_multilingual_component(bits, tag, len) ;
			break ;

		case DESC_PRIVATE_DATA_SPECIFIER:
			descriptor = (struct Descriptor *)parse_private_data_specifier(bits, tag, len) ;
			break ;

		case DESC_SERVICE_MOVE:
			descriptor = (struct Descriptor *)parse_service_move(bits, tag, len) ;
			break ;

		case DESC_SHORT_SMOOTHING_BUFFER:
			descriptor = (struct Descriptor *)parse_short_smoothing_buffer(bits, tag, len) ;
			break ;

		case DESC_FREQUENCY_LIST:
			descriptor = (struct Descriptor *)parse_frequency_list(bits, tag, len) ;
			break ;

		case DESC_PARTIAL_TRANSPORT_STREAM:
			descriptor = (struct Descriptor *)parse_partial_transport_stream(bits, tag, len) ;
			break ;

		case DESC_DATA_BROADCAST:
			descriptor = (struct Descriptor *)parse_data_broadcast(bits, tag, len) ;
			break ;

		case DESC_SCRAMBLING:
			descriptor = (struct Descriptor *)parse_scrambling(bits, tag, len) ;
			break ;

		case DESC_DATA_BROADCAST_ID:
			descriptor = (struct Descriptor *)parse_data_broadcast_id(bits, tag, len) ;
			break ;

		case DESC_TRANSPORT_STREAM:
			descriptor = (struct Descriptor *)parse_transport_stream(bits, tag, len) ;
			break ;

		case DESC_DSNG:
			descriptor = (struct Descriptor *)parse_dsng(bits, tag, len) ;
			break ;

		case DESC_PDC:
			descriptor = (struct Descriptor *)parse_pdc(bits, tag, len) ;
			break ;

		case DESC_ANCILLARY_DATA:
			descriptor = (struct Descriptor *)parse_ancillary_data(bits, tag, len) ;
			break ;

		case DESC_CELL_FREQUENCY_LINK:
			descriptor = (struct Descriptor *)parse_cell_frequency_link(bits, tag, len) ;
			break ;

		case DESC_ANNOUNCEMENT_SUPPORT:
			descriptor = (struct Descriptor *)parse_announcement_support(bits, tag, len) ;
			break ;

		case DESC_ADAPTATION_FIELD_DATA:
			descriptor = (struct Descriptor *)parse_adaptation_field_data(bits, tag, len) ;
			break ;

		case DESC_SERVICE_AVAILABILITY:
			descriptor = (struct Descriptor *)parse_service_availability(bits, tag, len) ;
			break ;

		case DESC_TVA_CONTENT_IDENTIFIER:
			descriptor = (struct Descriptor *)parse_tva_content_identifier(bits, tag, len) ;
			break ;

		case DESC_S2_SATELLITE_DELIVERY_SYSTEM:
			descriptor = (struct Descriptor *)parse_s2_satellite_delivery_system(bits, tag, len) ;
			break ;

		case DESC_EXTENSION:
			descriptor = (struct Descriptor *)parse_extension(bits, tag, len) ;
			break ;

		default:
			// skip descriptor
			bits_skip(bits, len*8) ;
			break ;
		}

if (bits->buff_len != expected_buff_len)
{
	printf("**** parse_desc() : buffer length not as expected (was %d expected %d) ****\n", bits->buff_len, expected_buff_len);
}

		// add to list
		if (descriptor)
		{
			list_add_tail(&descriptor->next, descriptors_array);
		}
	}
	else
	{
		// skip descriptor
		bits_skip(bits, len*8) ;
	}

	return (enum TS_descriptor_ids)tag ;
}

