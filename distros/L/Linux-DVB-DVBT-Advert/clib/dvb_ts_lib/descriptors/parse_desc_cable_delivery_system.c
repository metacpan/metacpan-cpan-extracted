/*
 * parse_desc_cable_delivery_system.c
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

#include "parse_desc_cable_delivery_system.h"
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
// cable_delivery_system_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  frequency  32 bslbf
//  reserved_future_use  12 bslbf
//  FEC_outer  4 bslbf
//  modulation  8 bslbf
//  symbol_rate  28 bslbf
//  FEC_inner  4 bslbf
// }

	
/* ----------------------------------------------------------------------- */
void print_cable_delivery_system(struct Descriptor_cable_delivery_system *cdsd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  cable_delivery_system [0x%02x]\n", cdsd->descriptor_tag) ;
	printf("    Length: %d\n", cdsd->descriptor_length) ;

	printf("    frequency = %d\n", cdsd->frequency) ;
	printf("    FEC_outer = %d\n", cdsd->FEC_outer) ;
	printf("    modulation = %d\n", cdsd->modulation) ;
	printf("    symbol_rate = %d\n", cdsd->symbol_rate) ;
	printf("    FEC_inner = %d\n", cdsd->FEC_inner) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_cable_delivery_system(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_cable_delivery_system *cdsd ;
unsigned byte ;
int end_buff_len ;

	cdsd = (struct Descriptor_cable_delivery_system *)malloc( sizeof(*cdsd) ) ;
	memset(cdsd,0,sizeof(*cdsd));

	//== Parse data ==
	INIT_LIST_HEAD(&cdsd->next);
	cdsd->descriptor_tag = tag ; // already extracted by parse_desc()
	cdsd->descriptor_length = len ; // already extracted by parse_desc()
	cdsd->frequency = bits_get(bits, 32) ;
	bits_skip(bits, 12) ;
	cdsd->FEC_outer = bits_get(bits, 4) ;
	cdsd->modulation = bits_get(bits, 8) ;
	cdsd->symbol_rate = bits_get(bits, 28) ;
	cdsd->FEC_inner = bits_get(bits, 4) ;
	
	return (struct Descriptor *)cdsd ;
}
	
/* ----------------------------------------------------------------------- */
void free_cable_delivery_system(struct Descriptor_cable_delivery_system *cdsd)
{
struct list_head  *item, *safe;
	
	free(cdsd) ;
}
