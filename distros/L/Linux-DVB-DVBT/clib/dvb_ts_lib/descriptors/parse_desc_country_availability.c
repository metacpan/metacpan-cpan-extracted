/*
 * parse_desc_country_availability.c
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

#include "parse_desc_country_availability.h"
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
// country_availability_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  country_availability_flag  1 bslbf
//  reserved_future_use  7 bslbf
//  for (i=0;i<N;i++){
//   country_code  24 bslbf
//  }
// }

	
/* ----------------------------------------------------------------------- */
void print_country_availability(struct Descriptor_country_availability *cad, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  country_availability [0x%02x]\n", cad->descriptor_tag) ;
	printf("    Length: %d\n", cad->descriptor_length) ;

	printf("    country_availability_flag = %d\n", cad->country_availability_flag) ;
	bits_dump("country_code", cad->country_code, cad->descriptor_length, 2) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_country_availability(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_country_availability *cad ;
unsigned byte ;
int end_buff_len ;

	cad = (struct Descriptor_country_availability *)malloc( sizeof(*cad) ) ;
	memset(cad,0,sizeof(*cad));

	//== Parse data ==
	INIT_LIST_HEAD(&cad->next);
	cad->descriptor_tag = tag ; // already extracted by parse_desc()
	cad->descriptor_length = len ; // already extracted by parse_desc()
	cad->country_availability_flag = bits_get(bits, 1) ;
	bits_skip(bits, 7) ;

	end_buff_len = bits_len_calc(bits, -(cad->descriptor_length - 1)) ;
	cad->country_code[0] = 0 ;
	for (byte=0; (bits->buff_len > end_buff_len) && (byte < MAX_COUNTRY_CODE_LEN); ++byte)
	{
		cad->country_code[byte] = bits_get(bits, 8) ;
		cad->country_code[byte+1] = 0 ;
	}

	
	return (struct Descriptor *)cad ;
}
	
/* ----------------------------------------------------------------------- */
void free_country_availability(struct Descriptor_country_availability *cad)
{
struct list_head  *item, *safe;
	
	free(cad) ;
}
