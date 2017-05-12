#include "epeg/src/lib/epeg_main.c"
#include <stdlib.h>

/* Perl5 overwrites original free(3) function. save it. */
int orig_free(void *x) {
    free(x);
}

#ifdef __cplusplus
extern "C"
{
	#endif
	#include "EXTERN.h"
	#include "perl.h"
	#include "XSUB.h"
	#include "ppport.h"
	#ifdef __cplusplus
}
#endif

/*
 *	Epeg Headers
 */

#include "epeg/src/lib/Epeg.h"

/*
 *	Wrapper
 */

MODULE = Image::Epeg		PACKAGE = Image::Epeg		

PROTOTYPES: disable

Epeg_Image *
_epeg_file_open( filename )
	const char * filename;
	PREINIT:
		int h, w;
	CODE:
		RETVAL = (Epeg_Image *)epeg_file_open( filename );
	OUTPUT:
		RETVAL


Epeg_Image *
_epeg_memory_open( data, dataLen );
	unsigned char * data;
	int dataLen;
	CODE:
		RETVAL = (Epeg_Image *)epeg_memory_open( data, dataLen );
	OUTPUT:
		RETVAL


void
_epeg_size_get( img )
	Epeg_Image * img;
	PREINIT:
		int h, w;
	PPCODE:
		epeg_size_get( img, &w, &h );
		XPUSHs( sv_2mortal( newSViv( w ) ) );
		XPUSHs( sv_2mortal( newSViv( h ) ) );


void
_epeg_output_size_get( img )
	Epeg_Image * img;
	PREINIT:
		int h, w;
	PPCODE:
		epeg_output_size_get( img, &w, &h );
		XPUSHs( sv_2mortal( newSViv( w ) ) );
		XPUSHs( sv_2mortal( newSViv( h ) ) );


void
_epeg_decode_size_set( img, w, h )
	Epeg_Image * img;
	int w;
	int h;
	CODE:
		epeg_decode_size_set( img, w, h );


void
_epeg_decode_colorspace_set( img, colorspace )
	Epeg_Image * img;
	int colorspace;
	CODE:
		epeg_decode_colorspace_set( img, colorspace );
	

const char *
_epeg_comment_get( img )
	Epeg_Image * img;
	CODE:
		RETVAL = epeg_comment_get( img );
	OUTPUT:
		RETVAL


void
_epeg_comment_set( img, comment )
	Epeg_Image * img;
	const char *comment
	CODE:
		epeg_comment_set( img, comment );


void
_epeg_quality_set( img, quality )
	Epeg_Image * img;
	int quality;
	CODE:
		epeg_quality_set( img, quality );


void
_epeg_get_data( img )
	Epeg_Image * img;
	PREINIT:
		unsigned char * pOut = NULL;
		int outSize = 0;
		int rc;
	PPCODE:
		epeg_memory_output_set( img, &pOut, &outSize );
		rc = epeg_encode( img );
		if( !rc )
		{
			PUSHs(sv_2mortal(newSVpv( (char*)pOut, outSize )));
			orig_free(pOut);
		}
		else
		{
			PUSHs(sv_2mortal(&PL_sv_undef));
		}


void
_epeg_write_file( img, filename )
	Epeg_Image * img;
	const char * filename;
	PREINIT:
		int rc;
	PPCODE:
		epeg_file_output_set( img, filename );
		rc = epeg_encode( img );
		PUSHs(sv_2mortal( (rc ? &PL_sv_undef : newSViv(1)) ));


void
_epeg_close( img )
	Epeg_Image * img;
	CODE:
		epeg_close( img );

int
_epeg_libjpeg_version()
    CODE:
        RETVAL=JPEG_LIB_VERSION;
    OUTPUT:
        RETVAL

