/*
 * parse_desc_satellite_delivery_system.c
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

#include "parse_desc_satellite_delivery_system.h"
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
// satellite_delivery_system_descriptor(){
//  descriptor_tag   8 uimsbf
//  descriptor_length  8 uimsbf
//  frequency  32 bslbf
//  orbital_position  16 bslbf
//  west_east_flag  1 bslbf
//  polarization  2 bslbf
//     If  (modulation_system == "1") {
//         roll_off  2 bslbf
//     } else {
//         "00"  2 bslbf
//     }
//     modulation_system  1 bslbf
//     modulation_type  2 bslbf
//  symbol_rate  28 bslbf
//  FEC_inner  4 bslbf
//     }

	
/* ----------------------------------------------------------------------- */
void print_satellite_delivery_system(struct Descriptor_satellite_delivery_system *sdsd, int level)
{
struct list_head  *item, *safe;

	printf("    Descriptor:  satellite_delivery_system [0x%02x]\n", sdsd->descriptor_tag) ;
	printf("    Length: %d\n", sdsd->descriptor_length) ;

	printf("    frequency = %d\n", sdsd->frequency) ;
	printf("    orbital_position = %d\n", sdsd->orbital_position) ;
	printf("    west_east_flag = %d\n", sdsd->west_east_flag) ;
	printf("    polarization = %d\n", sdsd->polarization) ;
	if (sdsd->modulation_system == 0x1  )
	{
	printf("    roll_off = %d\n", sdsd->roll_off) ;
	}
	else
	{
	}
	
	printf("    modulation_system = %d\n", sdsd->modulation_system) ;
	printf("    modulation_type = %d\n", sdsd->modulation_type) ;
	printf("    symbol_rate = %d\n", sdsd->symbol_rate) ;
	printf("    FEC_inner = %d\n", sdsd->FEC_inner) ;
}
	
/* ----------------------------------------------------------------------- */
struct Descriptor *parse_satellite_delivery_system(struct TS_bits *bits, unsigned tag, unsigned len)
{
struct Descriptor_satellite_delivery_system *sdsd ;
unsigned byte ;
int end_buff_len ;

	sdsd = (struct Descriptor_satellite_delivery_system *)malloc( sizeof(*sdsd) ) ;
	memset(sdsd,0,sizeof(*sdsd));

	//== Parse data ==
	INIT_LIST_HEAD(&sdsd->next);
	sdsd->descriptor_tag = tag ; // already extracted by parse_desc()
	sdsd->descriptor_length = len ; // already extracted by parse_desc()
	sdsd->frequency = bits_get(bits, 32) ;
	sdsd->orbital_position = bits_get(bits, 16) ;
	sdsd->west_east_flag = bits_get(bits, 1) ;
	sdsd->polarization = bits_get(bits, 2) ;
	if (sdsd->modulation_system == 0x1  )
	{
	sdsd->roll_off = bits_get(bits, 2) ;
	}
	else
	{
	bits_skip(bits, 2) ;
	}
	
	sdsd->modulation_system = bits_get(bits, 1) ;
	sdsd->modulation_type = bits_get(bits, 2) ;
	sdsd->symbol_rate = bits_get(bits, 28) ;
	sdsd->FEC_inner = bits_get(bits, 4) ;
	
	return (struct Descriptor *)sdsd ;
}
	
/* ----------------------------------------------------------------------- */
void free_satellite_delivery_system(struct Descriptor_satellite_delivery_system *sdsd)
{
struct list_head  *item, *safe;
	
	free(sdsd) ;
}
