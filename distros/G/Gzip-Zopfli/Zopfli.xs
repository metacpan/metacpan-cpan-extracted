#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#ifdef WIN32
#undef free
#undef malloc
#undef realloc
#endif /* def WIN32 */

#include "zopfli-one.c"
#include "gzip-zopfli-perl.c"

typedef gzip_zopfli_t * Gzip__Zopfli;

MODULE=Gzip::Zopfli PACKAGE=Gzip::Zopfli

PROTOTYPES: DISABLE

SV *
zopfli_compress(in, ...)
	SV * in;
PREINIT:
	gzip_zopfli_t gz = {0};
CODE:
	gzip_zopfli_init (& gz);
	if (items > 1) {
		if ((items - 1) % 2 != 0) {
			warn ("odd number of arguments ignored");
		}
		else {
			int i;
			for (i = 1; i < items; i += 2) {
				gzip_zopfli_set (& gz, ST (i), ST (i + 1));
			}
		}
	}
	RETVAL = gzip_zopfli (& gz, in);
OUTPUT:
	RETVAL
