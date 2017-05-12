#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef PL_sv_undef
#ifdef sv_undef
# define PL_sv_undef sv_undef
#endif
#endif

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <glib.h>
#include <gmime/gmime.h>
#include "gmime-version.h"

#define XSINTERFACE_FUNC_MIMEFAST_MESSAGE_SET(cv,f)      \
	CvXSUBANY(cv).any_dptr = (void (*) (pTHX_ void*))(CAT2( g_mime_message_,f ))
#define XSINTERFACE_FUNC_MIMEFAST_PART_SET(cv,f)      \
	CvXSUBANY(cv).any_dptr = (void (*) (pTHX_ void*))(CAT2( g_mime_part_,f ))
#define XSINTERFACE_FUNC_MIMEFAST_MULTIPART_SET(cv,f)      \
	CvXSUBANY(cv).any_dptr = (void (*) (pTHX_ void*))(CAT2( g_mime_multipart_,f ))
#define XSINTERFACE_FUNC_MIMEFAST_IA_SET(cv,f)      \
	CvXSUBANY(cv).any_dptr = (void (*) (pTHX_ void*))(CAT2( internet_address_,f ))
	
/* debug output from MIME::Fast module */
static gboolean gmime_debug = 0;

struct raw_header {
    struct raw_header *next;
    char *name;
    char *value;
};			

typedef struct _GMimeHeader {
        GHashTable *hash;
	GHashTable *writers;
        struct raw_header *headers;
} local_GMimeHeader;	

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

#define GMIME_LENGTH_ENCODED 1
#define GMIME_LENGTH_CUMULATIVE 2

#include "gmime-stream-perlio.h"

#include "gmime-newfunc.c"
#include "gmime-newfuncheader.c"
#include "perl-constants.c"

void
warn_type(SV *svmixed, char *text)
{
  SV		*svval;
  svtype	svvaltype;
  char		*svtext;
  STRLEN	vallen;

  svval = svmixed;
  if (SvROK(svmixed)) {
    svval = SvRV(svmixed);
  }
  svvaltype = SvTYPE(svval);

  svtext =
    (svvaltype == SVt_NULL) ?
        "SVt_NULL" :      /* 0 */
    (svvaltype == SVt_IV) ?
        "SVt_IV" :        /* 1 */
    (svvaltype == SVt_NV) ?
        "SVt_NV" :        /* 2 */
    (svvaltype == SVt_RV) ?
        "SVt_RV" :        /* 3 */
    (svvaltype == SVt_PV) ?
        "SVt_PV" :        /* 4 */
    (svvaltype == SVt_PVIV) ?
        "SVt_PVIV" :      /* 5 */
    (svvaltype == SVt_PVNV) ?
        "SVt_PVNV" :      /* 6 */
    (svvaltype == SVt_PVMG) ?
        "SVt_PVMG" :      /* 7 */
    (svvaltype == SVt_PVBM) ?
        "SVt_PVBM" :      /* 8 */
    (svvaltype == SVt_PVLV) ?
        "SVt_PVLV" :      /* 9 */
    (svvaltype == SVt_PVAV) ?
        "SVt_PVAV" :      /* 10 */
    (svvaltype == SVt_PVHV) ?
        "SVt_PVHV" :      /* 11 */
    (svvaltype == SVt_PVCV) ?
        "SVt_PVCV" :      /* 12 */
    (svvaltype == SVt_PVGV) ?
        "SVt_PVGV" :      /* 13 */
    (svvaltype == SVt_PVFM) ?
        "SVt_PVFM" :      /* 14 */
    (svvaltype == SVt_PVIO) ?
        "SVt_PVIO" :      /* 15 */
        "Unknown";

  warn("warn_type '%s': %s%d / %s, value='%s'", text,
    (SvROK(svmixed)) ? "ref " : "",
    (int)svvaltype,
    svtext,
    SvOK(svval) ? SvPV(svval, vallen) : "undef");
  
}

/* enums */
typedef GMimePartEncodingType	MIME__Fast__PartEncodingType;
typedef InternetAddressType	MIME__Fast__InternetAddressType;
typedef GMimeBestEncoding	MIME__Fast__BestEncoding;
typedef GMimeFilterFromMode	MIME__Fast__FilterFromMode;
typedef GMimeFilterYencDirection	Mime__Fast__FilterYencDirection;
typedef GMimeSeekWhence		MIME__Fast__SeekWhence;

/* C types */
typedef GMimeObject *		MIME__Fast__Object;
typedef GMimeParam *		MIME__Fast__Param;
typedef GMimePart *		MIME__Fast__Part;
typedef GMimeParser *		MIME__Fast__Parser;
typedef GMimeMultipart *	MIME__Fast__MultiPart;
typedef GMimeMessage *		MIME__Fast__Message;
typedef GMimeMessagePart *	MIME__Fast__MessagePart;
typedef GMimeMessagePartial *	MIME__Fast__MessagePartial;
#if GMIME_CHECK_VERSION_UNSUPPORTED
typedef GMimeMessageDelivery *	MIME__Fast__MessageDelivery;
typedef GMimeMessageMDN *	MIME__Fast__MessageMDN;
typedef GMimeMessageMDNDisposition *	MIME__Fast__MessageMDNDisposition;
typedef GMimeFilterFunc *	MIME__Fast__Filter__Func;
#endif
typedef GMimeFilterEnriched *	MIME__Fast__Filter__Enriched;
#if GMIME_CHECK_VERSION_2_1_0
typedef GMimeFilterWindows *	MIME__Fast__Filter__Windows;
#endif
typedef InternetAddress *	MIME__Fast__InternetAddress;
typedef GMimeDisposition *	MIME__Fast__Disposition;
typedef GMimeContentType *	MIME__Fast__ContentType;
typedef GMimeStream *		MIME__Fast__Stream;
typedef GMimeStreamFilter *	MIME__Fast__StreamFilter;
typedef GMimeDataWrapper *	MIME__Fast__DataWrapper;
typedef GMimeFilter *		MIME__Fast__Filter;
typedef GMimeFilterBasic *	MIME__Fast__Filter__Basic;
typedef GMimeFilterBest *	MIME__Fast__Filter__Best;
typedef GMimeFilterCharset *	MIME__Fast__Filter__Charset;
typedef GMimeFilterCRLF *	MIME__Fast__Filter__CRLF;
typedef GMimeFilterFrom *	MIME__Fast__Filter__From;
typedef GMimeFilterHTML *	MIME__Fast__Filter__HTML;
typedef GMimeFilterMd5 *	MIME__Fast__Filter__Md5;
typedef GMimeFilterStrip *	MIME__Fast__Filter__Strip;
typedef GMimeFilterYenc *	MIME__Fast__Filter__Yenc;
typedef GMimeCharset *		MIME__Fast__Charset;

/*
 * Declarations for message header hash array
 */

static gboolean
recipients_destroy (gpointer key, gpointer value, gpointer user_data)
{
        InternetAddressList *recipients = value;
        
        internet_address_list_destroy (recipients);

        return TRUE;
}

typedef struct {
        int			keyindex;	/* key index for firstkey */
        char			*fetchvalue;	/* value for each() method fetched with FETCH */
        MIME__Fast__Message	objptr;		/* any object pointer */
} hash_header;

typedef hash_header *	MIME__Fast__Hash__Header;

/*
 * Double linked list of perl allocated pointers (for DESTROY xsubs)
 */
static GList *plist = NULL;

/*
 * Calling callback function for each mime part
 */
struct _user_data_sv {
    SV *  svfunc;
    SV *  svuser_data;
    SV *  svfunc_complete;
    SV *  svfunc_sizeout;
};

static void
call_sub_foreach(GMimeObject *mime_object, gpointer data)
{
    SV * svpart;
    SV * rvpart;

    dSP ;
    struct _user_data_sv *svdata;

    svdata = (struct _user_data_sv *) data;
    svpart = sv_newmortal();

    if (GMIME_IS_MESSAGE_PARTIAL(mime_object))
        rvpart = sv_setref_pv(svpart, "MIME::Fast::MessagePartial", (MIME__Fast__MessagePartial)mime_object);
#if GMIME_CHECK_VERSION_UNSUPPORTED
    else if (GMIME_IS_MESSAGE_MDN(mime_object))
        rvpart = sv_setref_pv(svpart, "MIME::Fast::MessageMDN", (MIME__Fast__MessageMDN)mime_object);
    else if (GMIME_IS_MESSAGE_DELIVERY(mime_object))
        rvpart = sv_setref_pv(svpart, "MIME::Fast::MessageDelivery", (MIME__Fast__MessageDelivery)mime_object);
#endif
    else if (GMIME_IS_MESSAGE_PART(mime_object))
        rvpart = sv_setref_pv(svpart, "MIME::Fast::MessagePart", (MIME__Fast__MessagePart)mime_object);
    else if (GMIME_IS_MULTIPART(mime_object))
        rvpart = sv_setref_pv(svpart, "MIME::Fast::MultiPart", (MIME__Fast__MultiPart)mime_object);
    else if (GMIME_IS_PART(mime_object))
        rvpart = sv_setref_pv(svpart, "MIME::Fast::Part", (MIME__Fast__Part)mime_object);
    else
        rvpart = sv_setref_pv(svpart, "MIME::Fast::Object", mime_object);
        
    if (gmime_debug)
      warn("function call_sub_foreach: setref (not in plist) MIME::Fast object 0x%x", mime_object);
    PUSHMARK(sp);
    XPUSHs(rvpart);
    XPUSHs(sv_mortalcopy(svdata->svuser_data));
    PUTBACK ;
    if (svdata->svfunc)
      perl_call_sv(svdata->svfunc, G_DISCARD);
}

/* filter sizeout func */
size_t
call_filter_sizeout_func (size_t len, gpointer data)
{
    dSP ;
    	int	count = 0;
	size_t	outlen = 0;
        struct _user_data_sv *svdata;

    ENTER ;
    SAVETMPS;

        svdata = (struct _user_data_sv *) data;

    PUSHMARK(sp);
	XPUSHs(sv_2mortal(newSViv(len)));
	if (svdata->svuser_data)
	XPUSHs(svdata->svuser_data);
    PUTBACK ;
    
        if (svdata->svfunc_sizeout)
          count = perl_call_sv(svdata->svfunc_sizeout, G_SCALAR);

    SPAGAIN ;

	switch (count) {
	    case 1:
		outlen = POPi;
		break;
	}
    PUTBACK ;
    FREETMPS ;
    LEAVE ;
	return outlen;
}


/* filter complete func */
size_t
call_filter_complete_func (unsigned char *in, size_t len, unsigned char *out, int *state, guint32 *save, gpointer data)
{
    dSP ;
    	int	count = 0;
	size_t	outlen = 0;
        struct _user_data_sv *svdata;
	char *outptr;
	SV *	svin;

    ENTER ;
    SAVETMPS;

        svdata = (struct _user_data_sv *) data;

	svin = sv_newmortal();
	SvUPGRADE (svin, SVt_PV);
	SvREADONLY_on (svin);
	SvPVX (svin) = (char *)in;
	SvCUR_set (svin, len);
	SvLEN_set (svin, 0);
	SvPOK_only (svin);
	
    PUSHMARK(sp);
	XPUSHs(svin);
	XPUSHs(sv_2mortal(newSViv(*state)));
	XPUSHs(sv_2mortal(newSViv(*save)));
	if (svdata->svuser_data)
	XPUSHs(svdata->svuser_data);
    PUTBACK ;
    
        if (svdata->svfunc_complete)
          count = perl_call_sv(svdata->svfunc_complete, G_ARRAY);

    SPAGAIN ;

	switch (count) {
	    case 3:
		*save  = POPi;
	    case 2:
		*state = POPi;
	    case 1:
		{
		    STRLEN n_a;
		    outptr = POPpx;
		    outlen = n_a;
		    if (out && outptr && outlen > 0) {
			memcpy (out, outptr, outlen);
		    }
		}
		break;
	}
    PUTBACK ;
    FREETMPS ;
    LEAVE ;
	g_free (svdata);

	return outlen;
}



/* filter step func */
size_t
call_filter_step_func (unsigned char *in, size_t len, unsigned char *out, int *state, guint32 *save, gpointer data)
{
    dSP ;
    	int	count = 0;
	size_t	outlen = 0;
        struct _user_data_sv *svdata;
	char *outptr;
	SV *	svin;

    ENTER ;
    SAVETMPS;

        svdata = (struct _user_data_sv *) data;

	svin = sv_newmortal();
	SvUPGRADE (svin, SVt_PV);
	SvREADONLY_on (svin);
	SvPVX (svin) = (char *)in;
	SvCUR_set (svin, len);
	SvLEN_set (svin, 0);
	SvPOK_only (svin);
	
    PUSHMARK(sp);
	XPUSHs(svin);
	XPUSHs(sv_2mortal(newSViv(*state)));
	XPUSHs(sv_2mortal(newSViv(*save)));
	if (svdata->svuser_data)
	XPUSHs(svdata->svuser_data);
    PUTBACK ;
    
        if (svdata->svfunc)
          count = perl_call_sv(svdata->svfunc, G_ARRAY);

    SPAGAIN ;

	switch (count) {
	    case 3:
		*save  = POPi;
	    case 2:
		*state = POPi;
	    case 1:
		{
		    STRLEN n_a;
		    outptr = POPpx;
		    outlen = n_a;
		    if (out && outptr && outlen > 0) {
			memcpy (out, outptr, outlen);
		    }
		}
		break;
	}
    PUTBACK ;
    FREETMPS ;
    LEAVE ;

	return outlen;
}

void
call_sub_header_regex (GMimeParser *parser, const char *header,
		       const char *value, off_t offset,
		       gpointer user_data)
{
    SV *svfunc = NULL;
    SV *svuser_data = NULL;
    SV **sv;
    HV *hvarray;

    dSP ;

    if (!user_data)
	return;

    if (!user_data || !SvROK((SV *)user_data))
	    return;

    hvarray = (HV *)(SvRV((SV *)user_data));

    sv = hv_fetch(hvarray, "func", 4, FALSE);
    if (sv == (SV**)NULL)
      croak("call_sub_header_regex: Internal error getting func ...\n") ;
    svfunc = *sv;

    sv = hv_fetch(hvarray, "user_data", 9, FALSE);
    if (sv == (SV**)NULL)
      croak("call_sub_header_regex: Internal error getting user data...\n") ;
    svuser_data = *sv;

    PUSHMARK(sp);
    XPUSHs(sv_2mortal(newSVpv(header, 0)));
    XPUSHs(sv_2mortal(newSVpv(value,  0)));
    XPUSHs(sv_2mortal(newSViv(offset)));
    XPUSHs(sv_mortalcopy(svuser_data));
    PUTBACK ;
    if (svfunc)
	perl_call_sv(svfunc, G_DISCARD);
}

MODULE = MIME::Fast		PACKAGE = MIME::Fast		

SV *
get_object_type(svmixed)
        SV *		        svmixed
    PREINIT:
        void *	data = NULL;
        SV*     svval;
        svtype	svvaltype;
    CODE:
    	svval = svmixed;
        svvaltype = SvTYPE(svval);
	if (!sv_isobject(svmixed))
	  XSRETURN_UNDEF;
        if (SvROK(svmixed)) {
          IV tmp;
          svval = SvRV(svmixed);
          tmp = SvIV(svval);
	  data = (void *)tmp;
	} else {
	  XSRETURN_UNDEF;
	}
        if (data == NULL) {
	    XSRETURN_UNDEF;
#if GMIME_CHECK_VERSION_UNSUPPORTED
	} else if (GMIME_IS_MESSAGE_MDN((GMimeMessageMDN *)data)) {
	    RETVAL = newSVpvn("MIME::Fast::MessageMDN", 22);
	} else if (GMIME_IS_MESSAGE_DELIVERY((GMimeMessageDelivery *)data)) {
	    RETVAL = newSVpvn("MIME::Fast::MessageDelivery", 27);
#endif
	} else if (GMIME_IS_MESSAGE_PARTIAL((GMimeMessagePartial *)data)) {
	    RETVAL = newSVpvn("MIME::Fast::MessagePartial", 26);
	} else if (GMIME_IS_PART((GMimePart *)data)) {
	    RETVAL = newSVpvn("MIME::Fast::Part", 16);
	} else if (GMIME_IS_MULTIPART((GMimeMultipart *)data)) {
	    RETVAL = newSVpvn("MIME::Fast::MultiPart", 21);
	} else if (GMIME_IS_MESSAGE((GMimeMessage *)data)) {
	    RETVAL = newSVpvn("MIME::Fast::Message", 19);
	} else if (GMIME_IS_MESSAGE_PART((GMimeMessagePart *)data)) {
	    RETVAL = newSVpvn("MIME::Fast::MessagePart", 23);
	} else if (GMIME_IS_OBJECT((GMimeObject *)data)) {
	    RETVAL = newSVpvn("MIME::Fast::Object", 18);
	} else if (sv_isobject(svmixed)) {
            RETVAL = newSVpv( HvNAME( SvSTASH(SvRV(svmixed)) ), 0);
	} else {
            XSRETURN_UNDEF;
	}
    OUTPUT:
    	RETVAL
	

BOOT:
g_mime_init(0);

double
constant(sv,arg)
    PREINIT:
        STRLEN		len;
    INPUT:
        SV *		sv
        char *		s = SvPV(sv, len);
        int		arg
    CODE:
        RETVAL = constant(s,len,arg);
    OUTPUT:
        RETVAL

const char *
constant_string(sv,arg)
    PREINIT:
        STRLEN		len;
    INPUT:
        SV *		sv
        char *		s = SvPV(sv, len);
        int		arg
    CODE:
        RETVAL = constant_string(s,len,arg);
    OUTPUT:
        RETVAL


INCLUDE: Fast/Object.xs
INCLUDE: Fast/Param.xs
INCLUDE: Fast/ContentType.xs
INCLUDE: Fast/MultiPart.xs
INCLUDE: Fast/Part.xs
INCLUDE: Fast/Message.xs
INCLUDE: Fast/MessagePart.xs
INCLUDE: Fast/MessagePartial.xs

#if GMIME_CHECK_VERSION_UNSUPPORTED

INCLUDE: Fast/MessageDelivery.xs
INCLUDE: Fast/MessageMDN.xs
INCLUDE: Fast/MessageMDNDisposition.xs

#endif

INCLUDE: Fast/InternetAddress.xs
INCLUDE: Fast/Charset.xs
INCLUDE: Fast/DataWrapper.xs
INCLUDE: Fast/Stream.xs
INCLUDE: Fast/StreamFilter.xs
INCLUDE: Fast/Filter.xs
INCLUDE: Fast/Filter/Basic.xs
INCLUDE: Fast/Filter/Best.xs
INCLUDE: Fast/Filter/Charset.xs
INCLUDE: Fast/Filter/CRLF.xs
INCLUDE: Fast/Filter/Enriched.xs
INCLUDE: Fast/Filter/From.xs

#if GMIME_CHECK_VERSION_UNSUPPORTED

INCLUDE: Fast/Filter/Func.xs

#endif

INCLUDE: Fast/Filter/HTML.xs
INCLUDE: Fast/Filter/Md5.xs
INCLUDE: Fast/Filter/Strip.xs

#if GMIME_CHECK_VERSION_2_1_0

INCLUDE: Fast/Filter/Windows.xs

#endif

INCLUDE: Fast/Filter/Yenc.xs
INCLUDE: Fast/Parser.xs
INCLUDE: Fast/Disposition.xs
INCLUDE: Fast/Utils.xs
INCLUDE: Fast/Hash.xs

