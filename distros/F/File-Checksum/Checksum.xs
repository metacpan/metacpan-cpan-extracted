#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


MODULE = File::Checksum		PACKAGE = File::Checksum		
PROTOTYPES: ENABLE

unsigned short
Checksum(fname, count)
	char *fname
	int count
 CODE:
 	unsigned short us_buffer;
 	unsigned long ul_sum = 0;
 	int i;
 	FILE *file = fopen(fname, "rb");
 # Our algorithm is simple, using a 32 bit accumulator (ul_sum),
 # we add sequential 16 bit words to it, and at the end, fold
 # back all the carry bits from the top 16 bits into the lower 16 bits.
 	if(file)
 		{
  		for(i = 0; i < count; i += 2)
 			if(fread(&us_buffer, sizeof(unsigned short), 1, file))
 				ul_sum += us_buffer;
 			else
 				break;
 		fclose(file);
 # Add back carry outs from top 16 bits to low 16 bits.
 # Add hi 16 to low 16.
		ul_sum = (ul_sum >> 16) + (ul_sum & 0xffff);
 # Add carry.
 		ul_sum += (ul_sum >> 16);
 # Truncate to 16 bits.	
 		RETVAL = (unsigned short)~ul_sum;	
 		}
 	else
 		RETVAL = 0;
 OUTPUT:
 	RETVAL


