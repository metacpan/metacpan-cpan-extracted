#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

// $VERSION = sprintf( "%s", q{$Id: Elf.xs,v 1.4 2002/05/15 23:08:19 steve Exp $} =~ /(\d+\.\d+)/ );

MODULE = Digest::Elf		PACKAGE = Digest::Elf		

unsigned long
elf ( sval )
	char * sval;

	CODE:
		unsigned long h = 0, g;

		while ( *sval )
		{
			h = ( h << 4 ) + *sval++;
			if ( g = h & 0xF0000000 )
				h ^= g >> 24;

			h &= ~g;
		}
		RETVAL = h;

	OUTPUT:
		RETVAL

