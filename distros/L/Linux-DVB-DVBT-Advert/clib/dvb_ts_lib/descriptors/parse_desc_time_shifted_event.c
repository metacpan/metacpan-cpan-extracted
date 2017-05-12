/*
 * parse_desc_time_shifted_event.c
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

#include "parse_desc_time_shifted_event.h"
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
// time_shifted_event_descriptor(){
//  descriptor_tag  8 uimsbf
//  descriptor_length  8 uimsbf
//  reference_service_id  16 uimsbf
//  reference_event_id  16 uimsbf
// }

	
/* ----------------------------------------------------------------------- */
void print_time_shifted_event(struct Descriptor_time_shifted_event *tsed, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  time_shifted_event [0x%02x]\n", tsed->descriptor_tag) ;
	printf("    Length: %d\n", tsed->descriptor_length) ;

	printf("    reference_service_id = %d\n", tsed->reference_service_id) ;
	printf("    reference_event_id = %d\n", tsed->reference_event_id) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_time_shifted_event(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_time_shifted_event *tsed ;
unsigned byte ;
int end_buff_len ;

	tsed = (struct Descriptor_time_shifted_event *)malloc( sizeof(*tsed) ) ;
	memset(tsed,0,sizeof(*tsed));

	//== Parse data ==
	INIT_LIST_HEAD(&tsed->next);
	tsed->descriptor_tag = tag ; // already extracted by parse_desc()
	tsed->descriptor_length = len ; // already extracted by parse_desc()
	tsed->reference_service_id = bits_get(bits, 16) ;
	tsed->reference_event_id = bits_get(bits, 16) ;
	
	return (struct Descriptor *)tsed ;
}
	
/* ----------------------------------------------------------------------- */
void free_time_shifted_event(struct Descriptor_time_shifted_event *tsed)
{
struct list_head  *item, *safe;
	
	free(tsed) ;
}
