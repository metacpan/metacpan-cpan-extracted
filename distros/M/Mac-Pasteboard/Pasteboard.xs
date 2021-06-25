#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifdef USE_PBL_BACKEND

#include "pbl.h"
#include "constant-h.inc"

#else /* ifdef USE_PBL_BACKEND */

#define ASCII_ENCODING kCFStringEncodingASCII

/* this could also credibly be "public.plain-text", but in point
 * of fact the text programs I could bring easily to bear (pbpaste,
 * AppleWorks, vim, and PasteboardPeeker) could not see this.
 */

#ifdef UTF_8_PLAIN_TEXT
#define DEFAULT_FLAVOR "public.utf8-plain-text"
#define DEFAULT_ENCODE 1
#else /* ifdef UTF_8_PLAIN_TEXT */
#define DEFAULT_FLAVOR "com.apple.traditional-mac-plain-text"
#define DEFAULT_ENCODE 0
#endif /* ifdef UTF_8_PLAIN_TEXT */

#define PB_FLAVOR_FLAGS OptionBits

#endif /* ifdef USE_PBL_BACKEND */

#define UTF8_ENCODING kCFStringEncodingUTF8

#include <ApplicationServices/ApplicationServices.h>

#ifdef PERL_CAN_USE_UNICODE
#define PERL_ENCODING UTF8_ENCODING
#define my_sv_utf8_decode(sv) sv_utf8_decode(sv)
#define my_SvPVbyte(x,l) SvPVbyte(x,l)
#define my_SvPVutf8(x,l) SvPVutf8(x,l)
#define my_SvPVbyte_nolen(x) SvPVbyte_nolen(x)
#define my_SvPVutf8_nolen(x) SvPVutf8_nolen(x)
#else
#define PERL_ENCODING ASCII_ENCODING
#define my_sv_utf8_decode(sv) (1)
#define my_SvPVbyte(x,l) SvPV(x,l)
#define my_SvPVutf8(x,l) SvPV(x,l)
#define my_SvPVbyte_nolen(x) SvPV_nolen(x)
#define my_SvPVutf8_nolen(x) SvPV_nolen(x)
#endif

#define CF_TO_SV(sv,cf) { \
	if ( cf == NULL ) { \
	    sv = &PL_sv_undef; \
	} else { \
	    char *by; \
	    CFRange rng; \
	    rng.location = 0; \
	    rng.length = CFStringGetLength( ( CFStringRef ) cf ); \
	    CFIndex cf_len = 0; \
	    CFStringGetBytes( cf, rng, PERL_ENCODING, 0, \
		0, NULL, 0, &cf_len ); \
	    cf_len++; \
	    by = ( char * ) malloc( cf_len ); \
	    if ( by == NULL ) { \
		sv = NULL; \
	    } else { \
		CFStringGetBytes( cf, rng, PERL_ENCODING, 0, \
		    0, ( UInt8 * ) by, cf_len, \
		    &cf_len ); \
		sv = newSVpvn( by, cf_len ); \
		my_sv_utf8_decode( sv ); \
		free( by ); \
	    } \
	} \
    }

#define CF_TO_SV_CHECKED(sv,cf) \
    CF_TO_SV( sv, cf ); \
    CHECK_SV( sv );

#define CFD_TO_SV(sv,cf) { \
	if ( cf == NULL ) { \
	    sv = &PL_sv_undef; \
	} else { \
	    char *by; \
	    CFRange rng; \
	    rng.location = 0; \
	    rng.length = CFDataGetLength( ( CFDataRef ) cf ); \
	    by = ( char * ) malloc( rng.length ); \
	    if ( by == NULL ) { \
		sv = NULL; \
	    } else { \
		CFDataGetBytes( cf, rng, ( UInt8 * ) by ); \
		sv = newSVpvn( by, rng.length ); \
		free( by ); \
	    } \
	} \
    }

#define CFD_TO_SV_CHECKED(sv,cf) \
    CFD_TO_SV( sv, cf ); \
    CHECK_SV( sv );

#define CHECK_SV(sv) { \
	if ( sv == NULL ) { \
	    status = cNoMemErr; \
	    goto cleanup; \
	} \
    }

MODULE = Mac::Pasteboard		PACKAGE = Mac::Pasteboard

INCLUDE: constant-xs.inc

PROTOTYPES: DISABLE

#define SV_TO_C(c,sv,dflt) \
if ( SvOK( sv ) ) { \
    c = my_SvPVbyte_nolen( sv ); \
} else { \
    c = dflt; \
}

#define SV_TO_CF(cf,sv,dflt) \
    if ( SvOK( sv ) ) { \
	char *utf8_sv; \
	STRLEN utf8_sv_len; \
	utf8_sv = my_SvPVutf8( sv, utf8_sv_len ); \
	cf = CFStringCreateWithBytes( \
	    NULL, ( const unsigned char * ) utf8_sv, utf8_sv_len, \
	    PERL_ENCODING, 0 ); \
    } else { \
	cf = dflt; \
    }

char *
xs_pbl_variant()
    CODE:
#ifdef USE_PBL_BACKEND
	RETVAL = "PBL backend";
#else	/* def USE_PBL_BACKEND */
	RETVAL = "Pure XS";
#endif	/* def USE_PBL_BACKEND */
    OUTPUT:
	RETVAL

void
xs_pbl_create (SV * input_name)
    PPCODE:
#ifdef USE_PBL_BACKEND
	char *cname;
	char *created_name;
	void *pbref;
	long status;
	if (SvOK (input_name)) {
	    cname = my_SvPVbyte_nolen (input_name);
	} else {
	    cname = NULL;
	}
	status = (long) pbl_create (cname, &pbref, &created_name);
	EXTEND (SP, 3);
	PUSHs (sv_2mortal (newSViv (status)));
	PUSHs (sv_2mortal (newSVuv (PTR2UV (pbref))));
	if (created_name == NULL) {
	    PUSHs (sv_2mortal (newSV(0)));
	} else {
	    PUSHs (sv_2mortal (newSVpv (created_name, 0)));
	    FREE ("xs_pbl_create created_name", created_name);
	}
#else	/* def USE_PBL_BACKEND */
	void *pbref;
	long status;
	CFStringRef cf_name = NULL;
	CFStringRef cf_created = NULL;
	CFRange cf_range;
	SV *sv_stat;
	SV_TO_CF( cf_name, input_name, kPasteboardUniqueName );
	status = PasteboardCreate( cf_name, ( PasteboardRef * ) &pbref );
	sv_stat = sv_2mortal( newSViv( status ) );
	if ( status ) {	/* true indicates error */
	    EXTEND( SP, 1 );
	    PUSHs( sv_stat );
	} else {
#ifdef TIGER
	    SV *sv_created;
	    EXTEND( SP, 3 );
#else
	    EXTEND( SP, 2 );
#endif
	    PUSHs( sv_stat );
	    PUSHs( sv_2mortal( newSVuv( PTR2UV( pbref ) ) ) );
#ifdef TIGER
	    PasteboardCopyName( ( PasteboardRef ) pbref, &cf_created );
	    CF_TO_SV_CHECKED( sv_created, cf_created );
	    PUSHs( sv_2mortal( sv_created ) );
#endif
	}

	cleanup:

	if ( cf_name != NULL )
	    CFRelease( cf_name );
	if ( cf_created != NULL )
	    CFRelease( cf_created );
#endif	/* def USE_PBL_BACKEND */

long
xs_pbl_clear (void * pbref)
    CODE:
#ifdef USE_PBL_BACKEND
	RETVAL = (long) pbl_clear (pbref);
#else	/* def USE_PBL_BACKEND */
	RETVAL = ( long ) PasteboardClear( pbref );
#endif	/* def USE_PBL_BACKEND */
    OUTPUT:
	RETVAL

long
xs_pbl_copy (void * pbref, SV * data, unsigned long id, SV *sv_flavor, unsigned int flags)
    CODE:
#ifdef USE_PBL_BACKEND
	unsigned char * bytes;
	STRLEN size;
	char *cflavor;

	SV_TO_C( cflavor, sv_flavor, DEFAULT_FLAVOR );

	bytes = (unsigned char *) my_SvPVbyte (data, size);
	RETVAL = (long) pbl_copy (pbref, bytes, (size_t) size,
	    id, cflavor, flags);
#else	/* def USE_PBL_BACKEND */
	CFDataRef pbdata = NULL;
	CFStringRef cf_flavor = NULL;
	PasteboardSyncFlags sync;
	unsigned char * bytes;
	STRLEN size;
	OSStatus status;
	bytes = ( unsigned char * ) my_SvPVbyte( data, size );
	sync = PasteboardSynchronize( pbref );
	/* TODO clear if don't own pasteboard */
	if ( bytes == NULL ) {
	    pbdata = CFDataCreate( NULL, ( const unsigned char * ) "", 0 );
	} else {
	    pbdata = CFDataCreate( NULL, bytes, size );
	}

	SV_TO_CF( cf_flavor, sv_flavor, CFSTR( DEFAULT_FLAVOR ) );

	status = PasteboardPutItemFlavor( pbref, ( PasteboardItemID ) id,
		cf_flavor, pbdata, ( PasteboardFlavorFlags ) flags );
	if ( cf_flavor != NULL ) CFRelease( cf_flavor );
	if ( pbdata != NULL ) CFRelease( pbdata );
	RETVAL = ( long ) status;
#endif	/* def USE_PBL_BACKEND */
    OUTPUT:
	RETVAL

long
xs_pbl_paste( void *pbref, SV *id, SV *sv_flavor )
    PPCODE:
#ifdef USE_PBL_BACKEND
	unsigned char *data;
	size_t size;
	long status;
	unsigned long cid;
	int any;
	char *cflavor;
	PB_FLAVOR_FLAGS flags;
	if (SvOK (id)) {
	    any = 0;
	    cid = SvUV (id);
	} else {
	    any = 1;
	    cid = 0;
	}

	SV_TO_C( cflavor, sv_flavor, NULL );

	status = (long) pbl_paste (
	    pbref, any, cid, cflavor, &data, &size, &flags);
	EXTEND (SP, 3);
	PUSHs (sv_2mortal (newSViv (status)));
	if (data == NULL) {
	    PUSHs (sv_2mortal (newSV(0)));
	} else {
	    PUSHs (sv_2mortal (newSVpvn ((char *) data, (STRLEN) size)));
	    SvTAINTED_on( ST( 1 ) );
	    FREE ("xs_pbl_paste data", data);
	}
	PUSHs (sv_2mortal (newSVuv (flags)));
#else	/* def USE_PBL_BACKEND */
	int any;
	unsigned long cid;
	unsigned char *data;
	SV *sv_data = NULL;
	PB_FLAVOR_FLAGS flags;
	CFDataRef flavor_data = NULL;
	ItemCount item_inx;
	ItemCount pb_items;
	size_t size;	/* TODO STRLEN */
	OSStatus status;
	PasteboardSyncFlags sync;
	CFStringRef want_flavor = NULL;

	if (SvOK (id)) {
	    any = 0;
	    cid = SvUV (id);
	} else {
	    any = 1;
	    cid = 0;
	}

	SV_TO_CF( want_flavor, sv_flavor, kPasteboardClipboard );

	sync = PasteboardSynchronize( pbref );
	status = PasteboardGetItemCount( pbref, &pb_items );

	for (item_inx = pb_items; item_inx > 0; --item_inx) {
	    PasteboardItemID item_id;

	    status = PasteboardGetItemIdentifier( pbref, item_inx, &item_id );
	    if ( status ) goto cleanup;

	    if ( ! any && item_id != ( PasteboardItemID ) id )
		continue;

	    status = PasteboardCopyItemFlavorData(
		    pbref, item_id, want_flavor, &flavor_data );
	    if ( any && status == badPasteboardFlavorErr )
		continue;
	    if ( status ) goto cleanup;

	    status = PasteboardGetItemFlavorFlags(
		    pbref, item_id, want_flavor,
		    ( PasteboardFlavorFlags * ) &flags );
	    if ( status ) goto cleanup;

	    CFD_TO_SV_CHECKED( sv_data, flavor_data );

	    goto cleanup;

	}

	status = badPasteboardFlavorErr;

	cleanup:

	if ( flavor_data != NULL ) CFRelease( flavor_data );
	if ( want_flavor != NULL ) CFRelease( want_flavor );

	if ( status ) {	/* true is error */
	    EXTEND( SP, 1 );
	    PUSHs( sv_2mortal( newSViv( status ) ) );
	} else {
	    EXTEND( SP, 3 );
	    PUSHs( sv_2mortal( newSViv( status ) ) );
	    if ( data == NULL ) {
		PUSHs( sv_2mortal( newSV(0) ) );
	    } else {
	        PUSHs( sv_2mortal( sv_data ) );
		SvTAINTED_on( ST( 1 ) );
		free( data );
	    }
	    PUSHs( sv_2mortal( newSVuv( flags ) ) );
	}
#endif	/* def USE_PBL_BACKEND */

unsigned long
xs_pbl_synch (void * pbref)
    CODE:
#ifdef USE_PBL_BACKEND
	RETVAL = pbl_synch (pbref);
#else	/* def USE_PBL_BACKEND */
	RETVAL = ( unsigned long ) PasteboardSynchronize( pbref );
#endif	/* def USE_PBL_BACKEND */
    OUTPUT:
	RETVAL

HV *
xs_pbl_uti_tags( SV *sv_uti )
    CODE:
#ifdef USE_PBL_BACKEND
	char *c_uti;
	pbl_uti_tags_t tags_s;
	HV *tags_h;
	SV_TO_C( c_uti, sv_uti, NULL );
	pbl_uti_tags (c_uti, &tags_s);
	tags_h = (HV *) sv_2mortal ((SV *)newHV());
	/* cast to void to avoid 'expression result unsed' warning */
	if (tags_s.extension != NULL) {
	    (void)(hv_store (tags_h, "extension", 9, newSVpv
		(tags_s.extension, 0), 0));
	    FREE ("xs_pbl_uti_tags tags_s.extension",
		tags_s.extension);
	}
	if (tags_s.mime != NULL) {
	    (void)(hv_store (tags_h, "mime", 4, newSVpv (tags_s.mime, 0),
		0));
	    FREE ("xs_pbl_uti_tags tags_s.mime", tags_s.mime);
	}
	if (tags_s.pboard != NULL) {
	    (void)(hv_store (tags_h, "pboard", 6, newSVpv (tags_s.pboard,
		0), 0));
	    FREE ("xs_pbl_uti_tags tags_s.pboard", tags_s.pboard);
	}
	if (tags_s.os != NULL) {
	    (void)(hv_store (tags_h, "os", 2, newSVpv (tags_s.os, 0), 0));
	    FREE ("xs_pbl_uti_tags tags_s.os", tags_s.os);
	}
	RETVAL = tags_h;
#else	/* def USE_PBL_BACKEND */
	HV *tags_h;
	CFStringRef cf_tag = NULL;
	CFStringRef cf_uti;
	OSStatus status;	/* Unused, but referred to by CF_TO_SV_CHECKED() */
	SV *sv_tag;
	SV_TO_CF( cf_uti, sv_uti, NULL );
	tags_h = ( HV * ) sv_2mortal( ( SV * ) newHV() );

	cf_tag = UTTypeCopyPreferredTagWithClass( cf_uti,
		kUTTagClassFilenameExtension );
	if ( cf_tag != NULL ) {
	    CF_TO_SV_CHECKED( sv_tag, cf_tag );
	    ( void ) hv_stores( tags_h, "extension", sv_tag );
	    CFRelease( cf_tag );
	    cf_tag = NULL;
	}

	cf_tag = UTTypeCopyPreferredTagWithClass( cf_uti,
		kUTTagClassMIMEType );
	if ( cf_tag != NULL ) {
	    CF_TO_SV_CHECKED( sv_tag, cf_tag );
	    ( void ) hv_stores( tags_h, "mime", sv_tag );
	    CFRelease( cf_tag );
	    cf_tag = NULL;
	}

	cf_tag = UTTypeCopyPreferredTagWithClass( cf_uti,
		kUTTagClassNSPboardType );
	if (cf_tag != NULL) {
	    CF_TO_SV_CHECKED( sv_tag, cf_tag );
	    ( void ) hv_stores( tags_h, "pboard", sv_tag );
	    CFRelease( cf_tag );
	    cf_tag = NULL;
	}

	cf_tag = UTTypeCopyPreferredTagWithClass( cf_uti,
		kUTTagClassOSType );
	if (cf_tag != NULL) {
	    CF_TO_SV_CHECKED( sv_tag, cf_tag );
	    ( void ) hv_stores( tags_h, "os", sv_tag );
	    CFRelease( cf_tag );
	    cf_tag = NULL;
	}

	cleanup:

	if ( cf_tag != NULL )
	    CFRelease( cf_tag );

	RETVAL = tags_h;
#endif	/* def USE_PBL_BACKEND */
    OUTPUT:
	RETVAL

void
xs_pbl_all( void *pbref, SV *sv_id, int want_data, SV *sv_conforms_to )
    PPCODE:
#ifdef USE_PBL_BACKEND
	pbl_rqst_t rqst;
	pbl_resp_t *resp;
	size_t num_resp;
	long status;
	size_t inx;
	if (SvOK (sv_id)) {
	    rqst.all = 0;
	    rqst.id = SvUV (sv_id);
	} else {
	    rqst.all = 1;
	    rqst.id = 0;
	}
	rqst.want_data = want_data;
	if (SvOK (sv_conforms_to)) {
	    rqst.conforms_to = my_SvPVbyte_nolen (sv_conforms_to);
	} else {
	    rqst.conforms_to = NULL;
	}
	status = pbl_all (pbref, &rqst, &resp, &num_resp);
	if (resp == NULL)
	    num_resp = 0;
	EXTEND (SP, 1 + num_resp);
	PUSHs (sv_2mortal (newSViv (status)));
	for (inx = 0; inx < num_resp; inx++) {
	    HV *flvr;
	    flvr = (HV *) sv_2mortal ((SV *)newHV());
	    /* Cast to void to supress 'expression result unused' */
	    (void)(
		hv_store (flvr, "flags", 5, newSVuv (resp[inx].flags), 0));
	    (void)(hv_store (flvr, "id", 2, newSVuv (resp[inx].id), 0));
	    if (resp[inx].flavor != NULL)
		(void)(hv_store (flvr, "flavor", 6,
		    newSVpv (resp[inx].flavor, 0), 0));
	    if ( resp[inx].data != NULL ) {
		SV * data = newSVpvn( ( char * ) resp[inx].data,
		    resp[inx].size );
		SvTAINTED_on( data );
		( void ) ( hv_store( flvr, "data", 4, data , 0) );
	    }
	    PUSHs (newRV ((SV *) flvr));
	}
	pbl_free_all (resp, num_resp);
#else	/* def USE_PBL_BACKEND */
	int all;
	CFStringRef cf_conforms_to;
	CFArrayRef flavor_array = NULL;
	CFDataRef	flavor_data = NULL;
	unsigned long id;
	ItemCount item_inx;
	ItemCount pb_items;
	OSStatus status;
	PasteboardSyncFlags sync;

	if ( SvOK( sv_id ) ) {
	    all = 0;
	    id = SvUV( sv_id );
	} else {
	    all = 1;
	    id = 0;
	}
	SV_TO_CF( cf_conforms_to, sv_conforms_to, NULL );

	sync = PasteboardSynchronize( pbref );
	status = PasteboardGetItemCount( pbref, &pb_items );
	if ( status ) goto cleanup;

	EXTEND( SP, 1 + pb_items );
	PUSHs( sv_2mortal( newSViv( status ) ) );	/* Replaced at end */

	for ( item_inx = 1; item_inx <= pb_items; item_inx++ ) {
	    PasteboardItemID item_id;
	    CFIndex	flavor_count;
	    CFIndex	flavor_inx;

	    status = PasteboardGetItemIdentifier( pbref, item_inx, &item_id );
	    if ( status ) goto cleanup;

	    if ( ! all && item_id != ( PasteboardItemID ) id )
		continue;

	    status = PasteboardCopyItemFlavors( pbref, item_id, &flavor_array );
	    if ( status ) goto cleanup;

	    flavor_count = CFArrayGetCount( flavor_array );

	    for ( flavor_inx = 0; flavor_inx < flavor_count; flavor_inx++ ) {
		CFStringRef flavor_type;
		PB_FLAVOR_FLAGS flags;
		SV *sv_data;

		flavor_type = ( CFStringRef ) CFArrayGetValueAtIndex(
		    flavor_array, flavor_inx );
		if ( cf_conforms_to != NULL &&
		    UTTypeConformsTo( flavor_type, cf_conforms_to ) )
		    continue;

		status = PasteboardGetItemFlavorFlags(
			pbref, item_id, flavor_type, &flags );
		if ( status ) goto cleanup;

		HV *flvr;
		flvr = ( HV * ) sv_2mortal( ( SV * ) newHV() );
		PUSHs( newRV( ( SV * ) flvr ) );

		( void ) hv_stores( flvr, "flags", newSVuv( flags ) );

		( void ) hv_stores( flvr, "id", newSVuv( id ) );

		CF_TO_SV_CHECKED( sv_data, flavor_type );
		( void ) hv_stores( flvr, "flavor", sv_data );

		if ( ! want_data )
		    continue;

		status = PasteboardCopyItemFlavorData(
			pbref, item_id, flavor_type, &flavor_data );
		if ( status ) goto cleanup;

		CFD_TO_SV_CHECKED( sv_data, flavor_data );
		SvTAINTED_on( sv_data );
		( void ) hv_stores( flvr, "data", sv_data );
	    }

	    if ( flavor_array != NULL ) {
		CFRelease( flavor_array );
		flavor_array = NULL;
	    }

	    if ( flavor_data != NULL ) {
		CFRelease( flavor_data );
		flavor_data = NULL;
	    }
	}

	cleanup:

	if ( flavor_array != NULL ) {
	    CFRelease( flavor_array );
	    flavor_array = NULL;
	}


	if ( flavor_data != NULL ) {
	    CFRelease( flavor_data );
	    flavor_data = NULL;
	}

	ST( 0 ) = sv_2mortal( newSViv( status ) );
#endif	/* def USE_PBL_BACKEND */

long
xs_pbl_release (void * pbref)
    CODE:
#ifdef USE_PBL_BACKEND
	RETVAL = ( long ) pbl_release( pbref );
#else	/* def USE_PBL_BACKEND */
	if ( pbref != NULL )
	    CFRelease( pbref );
	RETVAL = 0;
#endif	/* def USE_PBL_BACKEND */
    OUTPUT:
	RETVAL

long
xs_pbl_retain (void * pbref)
    CODE:
#ifdef USE_PBL_BACKEND
	RETVAL = ( long ) pbl_retain( pbref );
#else	/* def USE_PBL_BACKEND */
	if ( pbref != NULL )
	    CFRetain( pbref );
	RETVAL = 0;
#endif	/* def USE_PBL_BACKEND */
    OUTPUT:
	RETVAL

char *
defaultFlavor ();
    CODE:
	RETVAL = DEFAULT_FLAVOR;
    OUTPUT:
	RETVAL

long
defaultEncode ()
    CODE:
	RETVAL = DEFAULT_ENCODE;
    OUTPUT:
	RETVAL
