/*
 * parse_desc_service.c
 *
 *  Created by: si_desc.pl
 *  Created on: 20-May-2011
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

#include "parse_desc_service.h"
#include "descriptors/parse_desc.h"

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
//
// service_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  service_type  8 uimsbf
//  service_provider_name_length  8 uimsbf
//  for (i=0;i<N;I++){
//   char  8 uimsbf
//  }
//  service_name_length  8 uimsbf
//  for (i=0;i<N;I++){
//   Char  8 uimsbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_service(struct Descriptor_service *sd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  service [0x%02x]\n", sd->descriptor_tag) ;
	printf("    Length: %d\n", sd->descriptor_length) ;

	printf("    service_type = %d\n", sd->service_type) ;
	printf("    service_provider_name_length = %d\n", sd->service_provider_name_length) ;
	printf("    service_provider_name = \"%s\"\n", sd->service_provider_name) ;
	printf("    service_name_length = %d\n", sd->service_name_length) ;
	printf("    service_name = \"%s\"\n", sd->service_name) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_service(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_service *sd ;
unsigned byte ;
int end_buff_len ;

	sd = (struct Descriptor_service *)malloc( sizeof(*sd) ) ;
	memset(sd,0,sizeof(*sd));

	//== Parse data ==
	INIT_LIST_HEAD(&sd->next);
	sd->descriptor_tag = tag ; // already extracted by parse_desc()
	sd->descriptor_length = len ; // already extracted by parse_desc()
	sd->service_type = bits_get(bits, 8) ;
	sd->service_provider_name_length = bits_get(bits, 8) ;

	end_buff_len = bits_len_calc(bits, -sd->service_provider_name_length) ;
	sd->service_provider_name[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_SERVICE_PROVIDER_NAME_LEN); ++byte)
	{
		sd->service_provider_name[byte] = bits_get(bits, 8) ;
		sd->service_provider_name[byte+1] = 0 ;
	}

	sd->service_name_length = bits_get(bits, 8) ;

	end_buff_len = bits_len_calc(bits, -sd->service_name_length) ;
	sd->service_name[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_SERVICE_NAME_LEN); ++byte)
	{
		sd->service_name[byte] = bits_get(bits, 8) ;
		sd->service_name[byte+1] = 0 ;
	}

	
	return (struct Descriptor *)sd ;
}
	
/* ----------------------------------------------------------------------- */
void free_service(struct Descriptor_service *sd)
{
struct list_head  *item, *safe;
	
	free(sd) ;
}
