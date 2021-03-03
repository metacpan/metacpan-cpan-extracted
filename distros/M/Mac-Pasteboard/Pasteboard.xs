#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "pbl.h"

#include "constant-h.inc"

MODULE = Mac::Pasteboard		PACKAGE = Mac::Pasteboard		

INCLUDE: constant-xs.inc

PROTOTYPES: DISABLE

void
xs_pbl_create (SV * input_name)
    PPCODE:
	{
	    char *cname;
	    char *created_name;
	    void *pbref;
	    long status;
	    if (SvOK (input_name)) {
		cname = SvPV_nolen (input_name);
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
	}

long
xs_pbl_clear (void * pbref)
    CODE:
	RETVAL = (long) pbl_clear (pbref);
    OUTPUT:
	RETVAL

long
xs_pbl_copy (void * pbref, SV * data, unsigned long id, char * cflavor, unsigned int flags)
    CODE:
	{
	    unsigned char * bytes;
	    STRLEN size;
	    bytes = (unsigned char *) SvPV (data, size);
	    RETVAL = (long) pbl_copy (pbref, bytes, (size_t) size,
		id, cflavor, flags);
	}
    OUTPUT:
	RETVAL

long
xs_pbl_paste (void * pbref, SV * id, char * cflavor)
    PPCODE:
	{
	    unsigned char *data;
	    size_t size;
	    long status;
	    unsigned long cid;
	    int any;
	    PB_FLAVOR_FLAGS flags;
	    if (SvOK (id)) {
		any = 0;
		cid = SvUV (id);
	    } else {
		any = 1;
		cid = 0;
	    }
	    status = (long) pbl_paste (
		pbref, any, cid, cflavor, &data, &size, &flags);
	    EXTEND (SP, 3);
	    PUSHs (sv_2mortal (newSViv (status)));
	    if (data == NULL) {
		PUSHs (sv_2mortal (newSV(0)));
	    } else {
		PUSHs (sv_2mortal (newSVpvn ((char *) data, (STRLEN) size)));
		FREE ("xs_pbl_paste data", data);
	    }
	    PUSHs (sv_2mortal (newSVuv (flags)));
	}

unsigned long
xs_pbl_synch (void * pbref)
    CODE:
	RETVAL = pbl_synch (pbref);
    OUTPUT:
	RETVAL

void
xs_pbl_uti_tags (char * c_uti)
    PPCODE:
	{
	    pbl_uti_tags_t tags_s;
	    HV *tags_h;
	    pbl_uti_tags (c_uti, &tags_s);
	    EXTEND (SP, 1);
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
	    PUSHs (newRV ((SV *) tags_h));
	}

long
xs_pbl_all (void * pbref, SV * id, int want_data, SV * conforms_to)
    PPCODE:
	{
	    pbl_rqst_t rqst;
	    pbl_resp_t *resp;
	    size_t num_resp;
	    long status;
	    size_t inx;
	    if (SvOK (id)) {
		rqst.all = 0;
		rqst.id = SvUV (id);
	    } else {
		rqst.all = 1;
		rqst.id = 0;
	    }
	    rqst.want_data = want_data;
	    if (SvOK (conforms_to)) {
		rqst.conforms_to = SvPV_nolen (conforms_to);
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
		if (resp[inx].data != NULL)
		    (void)(hv_store (flvr, "data", 4,
		        newSVpvn ((char *) resp[inx].data, resp[inx].size), 0));
		PUSHs (newRV ((SV *) flvr));
	    }
	    pbl_free_all (resp, num_resp);
	}



long
xs_pbl_release (void * pbref)
    CODE:
	RETVAL = (long) pbl_release (pbref);
    OUTPUT:
	RETVAL

long
xs_pbl_retain (void * pbref)
    CODE:
	RETVAL = (long) pbl_retain (pbref);
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
