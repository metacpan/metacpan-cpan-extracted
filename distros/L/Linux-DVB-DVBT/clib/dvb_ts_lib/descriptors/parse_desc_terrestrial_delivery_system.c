/*
 * parse_desc_terrestrial_delivery_system.c
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

#include "parse_desc_terrestrial_delivery_system.h"
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
// terrestrial_delivery_system_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  centre_frequency  32 bslbf
//  bandwidth  3 bslbf
//  priority  1 bslbf
//  Time_Slicing_indicator  1 bslbf
//  MPE_FEC_indicator  1 bslbf
//  reserved_future_use  2 bslbf
//  constellation  2 bslbf
//  hierarchy_information  3 bslbf
//  code_rate_HP_stream  3 bslbf
//  code_rate_LP_stream  3 bslbf
//  guard_interval  2 bslbf
//  transmission_mode  2 bslbf
//  other_frequency_flag  1 bslbf
//  reserved_future_use  32 bslbf
// }

	
/* ----------------------------------------------------------------------- */
void print_terrestrial_delivery_system(struct Descriptor_terrestrial_delivery_system *tdsd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  terrestrial_delivery_system [0x%02x]\n", tdsd->descriptor_tag) ;
	printf("    Length: %d\n", tdsd->descriptor_length) ;

	printf("    centre_frequency = %d\n", tdsd->centre_frequency) ;
	printf("    bandwidth = %d\n", tdsd->bandwidth) ;
	printf("    priority = %d\n", tdsd->priority) ;
	printf("    Time_Slicing_indicator = %d\n", tdsd->Time_Slicing_indicator) ;
	printf("    MPE_FEC_indicator = %d\n", tdsd->MPE_FEC_indicator) ;
	printf("    constellation = %d\n", tdsd->constellation) ;
	printf("    hierarchy_information = %d\n", tdsd->hierarchy_information) ;
	printf("    code_rate_HP_stream = %d\n", tdsd->code_rate_HP_stream) ;
	printf("    code_rate_LP_stream = %d\n", tdsd->code_rate_LP_stream) ;
	printf("    guard_interval = %d\n", tdsd->guard_interval) ;
	printf("    transmission_mode = %d\n", tdsd->transmission_mode) ;
	printf("    other_frequency_flag = %d\n", tdsd->other_frequency_flag) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_terrestrial_delivery_system(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_terrestrial_delivery_system *tdsd ;
unsigned byte ;
int end_buff_len ;

	tdsd = (struct Descriptor_terrestrial_delivery_system *)malloc( sizeof(*tdsd) ) ;
	memset(tdsd,0,sizeof(*tdsd));

	//== Parse data ==
	INIT_LIST_HEAD(&tdsd->next);
	tdsd->descriptor_tag = tag ; // already extracted by parse_desc()
	tdsd->descriptor_length = len ; // already extracted by parse_desc()
	tdsd->centre_frequency = bits_get(bits, 32) ;
	tdsd->bandwidth = bits_get(bits, 3) ;
	tdsd->priority = bits_get(bits, 1) ;
	tdsd->Time_Slicing_indicator = bits_get(bits, 1) ;
	tdsd->MPE_FEC_indicator = bits_get(bits, 1) ;
	bits_skip(bits, 2) ;
	tdsd->constellation = bits_get(bits, 2) ;
	tdsd->hierarchy_information = bits_get(bits, 3) ;
	tdsd->code_rate_HP_stream = bits_get(bits, 3) ;
	tdsd->code_rate_LP_stream = bits_get(bits, 3) ;
	tdsd->guard_interval = bits_get(bits, 2) ;
	tdsd->transmission_mode = bits_get(bits, 2) ;
	tdsd->other_frequency_flag = bits_get(bits, 1) ;
	bits_skip(bits, 32) ;
	
	return (struct Descriptor *)tdsd ;
}
	
/* ----------------------------------------------------------------------- */
void free_terrestrial_delivery_system(struct Descriptor_terrestrial_delivery_system *tdsd)
{
struct list_head  *item, *safe;
	
	free(tdsd) ;
}
