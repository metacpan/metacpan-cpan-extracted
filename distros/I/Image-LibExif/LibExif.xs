#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <libexif/exif-loader.h>
#include <libexif/exif-data.h>
#include <libexif/exif-log.h>
#include <libexif/exif-mem.h>
#include <libexif/exif-utils.h>

/*
	EXIF_FORMAT_BYTE       =  1,
	EXIF_FORMAT_ASCII      =  2,
	EXIF_FORMAT_SHORT      =  3,
	EXIF_FORMAT_LONG       =  4,
	EXIF_FORMAT_RATIONAL   =  5,
	EXIF_FORMAT_SBYTE      =  6,
	EXIF_FORMAT_UNDEFINED  =  7,
	EXIF_FORMAT_SSHORT     =  8,
	EXIF_FORMAT_SLONG      =  9,
	EXIF_FORMAT_SRATIONAL  = 10,
	EXIF_FORMAT_FLOAT      = 11,
	EXIF_FORMAT_DOUBLE     = 12
*/

static int my_exif_get_short  ( const unsigned char *b, ExifByteOrder o ) { (int) exif_get_short(b,o); }
static int my_exif_get_sshort ( const unsigned char *b, ExifByteOrder o ) { (int) exif_get_sshort(b,o); }
static int my_exif_get_long   ( const unsigned char *b, ExifByteOrder o ) { (int) exif_get_long(b,o); }
static int my_exif_get_slong  ( const unsigned char *b, ExifByteOrder o ) { (int) exif_get_slong(b,o); }
// TODO: Double/Rational
// TODO: unsigned long

static int ( *exif_get_by_format[] )( const unsigned char *, ExifByteOrder )  = {
	0, // skip 0
	my_exif_get_short,
	0,
	my_exif_get_short,
	my_exif_get_long,
	0, // Rational
	my_exif_get_short,
	0, // Undefined
	my_exif_get_sshort,
	my_exif_get_slong,
	0, // SRational
	0, // Float
	0  // Double
};

SV *
my_exif_get_value(ExifEntry *e, ExifByteOrder o) {
	int ( *extractor )( const unsigned char *, ExifByteOrder );
	char value[1024];
	int intval, have_intval = 0;
	SV *rv;
	if (extractor = exif_get_by_format[e->format]) {
		intval = extractor(e->data,o);
		have_intval = 1;
	}
	exif_entry_get_value(e, value, sizeof(value));
	rv = newSVpvn(value,strlen(value));
	if (have_intval) {
		(void) SvUPGRADE(rv,SVt_PVNV);
		SvIV_set(rv, intval);
		SvIOK_on(rv);
	}
	return rv;
}

MODULE = Image::LibExif		PACKAGE = Image::LibExif		

SV *
image_exif(src)
	char *src;
	PROTOTYPE:$
	CODE:
		int k,l,m,n;
		ExifLoader  * loader;
		ExifData    * data;
		ExifContent * content;
		ExifEntry   * entry;
		
		loader = exif_loader_new();
		exif_loader_write_file(loader, src);
		data = exif_loader_get_data(loader);
		exif_loader_unref(loader);
		if (!data) XSRETURN_UNDEF;
		
		exif_data_fix(data);
		
		HV * rv = newHV();
		ExifByteOrder o = exif_data_get_byte_order(data);
		for (k = 0; k < EXIF_IFD_COUNT; k++) {
			content = data->ifd[k];
			if (!content) continue;
			//warn("Reading IFD %d\n",k);
			for (l = 0; l < content->count; l++) {
				entry = content->entries[l];
				const char *tagname = exif_tag_get_name_in_ifd(entry->tag,k);
				const SV * tagval = my_exif_get_value(entry,o);
				//if (memcmp(tagname,"GPS",3) == 0) {
				//	warn("\tStore tag %04x (%s) with value %s\n",entry->tag,tagname,SvPV_nolen(tagval));
				//}
				(void) hv_store(rv, tagname, strlen(tagname), tagval, 0 );
			}
		}
		if (data->size && data->data) {
			(void) hv_store(rv, "ThumbnailImage", strlen("ThumbnailImage"), newRV_noinc(newSVpvn(data->data,data->size)), 0 );
		}
		exif_data_unref(data);
		
		ST(0) = sv_2mortal(newRV_noinc((SV *)rv));
		XSRETURN(1);
