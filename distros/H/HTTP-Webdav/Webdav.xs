/*
############################################################################
#
# HTTP::Webdav - Perl interface to Neon HTTP and WebDAV client library
#
# Copyright (c) 2001 Gerald Richter / ecos gmbh (www.ecos.de)
# 
# You may distribute under the terms of either the GNU General Public 
# License or the Artistic License, as specified in the Perl README file.
# 
# THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED 
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF 
# MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
# $Id: Webdav.xs,v 1.25 2001/10/19 04:36:30 richter Exp $
#
############################################################################
*/







#ifdef __cplusplus
extern "C" {
#endif
#include "ne_request.h"
#include "ne_locks.h"
#include "ne_dates.h"
#include "ne_md5.h"
#include "ne_alloc.h"
#include "ne_auth.h"
#include "ne_uri.h"
#include "ne_xml.h"
#include "ne_compress.h"
#include "ne_socket.h"
#include "ne_string.h"
#include "ne_redirect.h"
#include "ne_i18n.h"
#include "ne_props.h"
#include "ne_session.h"
#include "ne_defs.h"
#include "ne_acl.h"
#include "ne_utils.h"
#include "ne_207.h"
#include "ne_cookies.h"
#include "ne_basic.h"
#ifdef __cplusplus
}
#endif


#undef _

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#ifdef apply
#undef apply
#endif


SV * __fetchmember (HV * pHV, char * pKey)
    {
    SV ** ppSV = hv_fetch (pHV, pKey, strlen (pKey), 1) ;
    if (!ppSV || !*ppSV)
        croak ("bad hash") ;

    return *ppSV ;
    }

HV * pC2Perl ;
HV * pPerl2C ;

#undef scope


    struct perl_callback_data 
        {
        SV * pUser ;
        CV * pCallback ;
        } ;


    
    /* *** ne_207_end_propstat set by ne_207_set_propstat_handlers *** */

void neon_cb___cb__18 (
    void *userdata, void *propstat, const char *status_line, 
    const ne_status *status, const char *description)
    {

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__18", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
	sv_setiv(pSV, (IV)propstat);	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, status_line);
	XPUSHs(pSV);
	pSV = sv_newmortal ();
	
        {
        HV * _pHV_ ;
        if (!SvOK(pSV))
            {
            pSV = newRV_noinc((SV *)(_pHV_ = newHV())) ;
            sv_2mortal (pSV) ;
            }
        else if (!SvROK (pSV))
            {
            croak ("status must be a reference") ;
            }
        else if (SvTYPE(_pHV_ = (HV *)SvRV(pSV)) != SVt_PVHV)
	    SvUPGRADE ((SV *)_pHV_, SVt_PVHV) ;
        if (status)
            {
	sv_setiv(__fetchmember(_pHV_,"major_version"), (IV)((const ne_status *)status)->major_version);
	;
	sv_setiv(__fetchmember(_pHV_,"minor_version"), (IV)((const ne_status *)status)->minor_version);
	;
	sv_setiv(__fetchmember(_pHV_,"code"), (IV)((const ne_status *)status)->code);
	;
	sv_setiv(__fetchmember(_pHV_,"klass"), (IV)((const ne_status *)status)->klass);
	;
	sv_setpv((SV*)__fetchmember(_pHV_,"reason_phrase"), ((const ne_status *)status)->reason_phrase);
	;

            }
        }
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, description);
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_VOID) ;
		}

    FREETMPS ;
    LEAVE ;

    }

    
    /* *** ne_207_end_response set by ne_207_set_response_handlers *** */

void neon_cb___cb__19 (
    void *userdata, void *response, const char *status_line,
    const ne_status *status, const char *description)
    {

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__19", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
	sv_setiv(pSV, (IV)response);	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, status_line);
	XPUSHs(pSV);
	pSV = sv_newmortal ();
	
        {
        HV * _pHV_ ;
        if (!SvOK(pSV))
            {
            pSV = newRV_noinc((SV *)(_pHV_ = newHV())) ;
            sv_2mortal (pSV) ;
            }
        else if (!SvROK (pSV))
            {
            croak ("status must be a reference") ;
            }
        else if (SvTYPE(_pHV_ = (HV *)SvRV(pSV)) != SVt_PVHV)
	    SvUPGRADE ((SV *)_pHV_, SVt_PVHV) ;
        if (status)
            {
	sv_setiv(__fetchmember(_pHV_,"major_version"), (IV)((const ne_status *)status)->major_version);
	;
	sv_setiv(__fetchmember(_pHV_,"minor_version"), (IV)((const ne_status *)status)->minor_version);
	;
	sv_setiv(__fetchmember(_pHV_,"code"), (IV)((const ne_status *)status)->code);
	;
	sv_setiv(__fetchmember(_pHV_,"klass"), (IV)((const ne_status *)status)->klass);
	;
	sv_setpv((SV*)__fetchmember(_pHV_,"reason_phrase"), ((const ne_status *)status)->reason_phrase);
	;

            }
        }
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, description);
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_VOID) ;
		}

    FREETMPS ;
    LEAVE ;

    }

    
    /* *** ne_accept_response set by ne_add_response_body_reader *** */

int neon_cb___cb__23 (
    void *userdata, ne_request *req, ne_status *st)
    {
	int retval ;

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__23", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
	
        {
        SV ** ppArg ;
        ppArg = hv_fetch (pC2Perl, (char *)(&req), sizeof(req), 1) ;
        if (!SvOK(*ppArg))
            {
            SV * pObj ;
            *ppArg = newRV_noinc ((SV *)newHV()) ;
            sv_2mortal(*ppArg) ;
	    sv_bless (*ppArg, gv_stashpv ("HTTP::Webdav::Request", 0)) ;
            hv_store (pPerl2C, (char *)(SvRV (*ppArg)), sizeof (void *), newSViv ((IV)req), 0) ;
            }
        pSV = *ppArg ;
        }
	XPUSHs(pSV);
	pSV = sv_newmortal ();
	
        {
        HV * _pHV_ ;
        if (!SvOK(pSV))
            {
            pSV = newRV_noinc((SV *)(_pHV_ = newHV())) ;
            sv_2mortal (pSV) ;
            }
        else if (!SvROK (pSV))
            {
            croak ("st must be a reference") ;
            }
        else if (SvTYPE(_pHV_ = (HV *)SvRV(pSV)) != SVt_PVHV)
	    SvUPGRADE ((SV *)_pHV_, SVt_PVHV) ;
        if (st)
            {
	sv_setiv(__fetchmember(_pHV_,"major_version"), (IV)((ne_status *)st)->major_version);
	;
	sv_setiv(__fetchmember(_pHV_,"minor_version"), (IV)((ne_status *)st)->minor_version);
	;
	sv_setiv(__fetchmember(_pHV_,"code"), (IV)((ne_status *)st)->code);
	;
	sv_setiv(__fetchmember(_pHV_,"klass"), (IV)((ne_status *)st)->klass);
	;
	sv_setpv((SV*)__fetchmember(_pHV_,"reason_phrase"), ((ne_status *)st)->reason_phrase);
	;

            }
        }
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_SCALAR) ;
		}

    SPAGAIN ;
    if (cnt != 1)
        {
        retval = 0 ;
        }
    else
        {
        pSV = POPs ;
	retval = (int)SvIV(pSV);
	}
	PUTBACK ;

    FREETMPS ;
    LEAVE ;
	return retval ;

    }

    
    /* *** ne_accept_response set by ne_decompress_reader *** */

int neon_cb___cb__27 (
    void *userdata, ne_request *req, ne_status *st)
    {
	int retval ;

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__27", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
	
        {
        SV ** ppArg ;
        ppArg = hv_fetch (pC2Perl, (char *)(&req), sizeof(req), 1) ;
        if (!SvOK(*ppArg))
            {
            SV * pObj ;
            *ppArg = newRV_noinc ((SV *)newHV()) ;
            sv_2mortal(*ppArg) ;
	    sv_bless (*ppArg, gv_stashpv ("HTTP::Webdav::Request", 0)) ;
            hv_store (pPerl2C, (char *)(SvRV (*ppArg)), sizeof (void *), newSViv ((IV)req), 0) ;
            }
        pSV = *ppArg ;
        }
	XPUSHs(pSV);
	pSV = sv_newmortal ();
	
        {
        HV * _pHV_ ;
        if (!SvOK(pSV))
            {
            pSV = newRV_noinc((SV *)(_pHV_ = newHV())) ;
            sv_2mortal (pSV) ;
            }
        else if (!SvROK (pSV))
            {
            croak ("st must be a reference") ;
            }
        else if (SvTYPE(_pHV_ = (HV *)SvRV(pSV)) != SVt_PVHV)
	    SvUPGRADE ((SV *)_pHV_, SVt_PVHV) ;
        if (st)
            {
	sv_setiv(__fetchmember(_pHV_,"major_version"), (IV)((ne_status *)st)->major_version);
	;
	sv_setiv(__fetchmember(_pHV_,"minor_version"), (IV)((ne_status *)st)->minor_version);
	;
	sv_setiv(__fetchmember(_pHV_,"code"), (IV)((ne_status *)st)->code);
	;
	sv_setiv(__fetchmember(_pHV_,"klass"), (IV)((ne_status *)st)->klass);
	;
	sv_setpv((SV*)__fetchmember(_pHV_,"reason_phrase"), ((ne_status *)st)->reason_phrase);
	;

            }
        }
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_SCALAR) ;
		}

    SPAGAIN ;
    if (cnt != 1)
        {
        retval = 0 ;
        }
    else
        {
        pSV = POPs ;
	retval = (int)SvIV(pSV);
	}
	PUTBACK ;

    FREETMPS ;
    LEAVE ;
	return retval ;

    }

    
    /* *** ne_block_reader set by ne_read_file *** */

void neon_cb___cb__9 (
    void *userdata, const char *buf, size_t len)
    {

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__9", 7, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, buf);
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setiv(pSV, (IV)len);
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_VOID) ;
		}

    FREETMPS ;
    LEAVE ;

    }

    
    /* *** ne_block_reader set by ne_add_response_body_reader *** */

void neon_cb___cb__24 (
    void *userdata, const char *buf, size_t len)
    {

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__24", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, buf);
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setiv(pSV, (IV)len);
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_VOID) ;
		}

    FREETMPS ;
    LEAVE ;

    }

    
    /* *** ne_block_reader set by ne_decompress_reader *** */

void neon_cb___cb__28 (
    void *userdata, const char *buf, size_t len)
    {

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__28", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, buf);
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setiv(pSV, (IV)len);
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_VOID) ;
		}

    FREETMPS ;
    LEAVE ;

    }

    
    /* *** ne_create_request_fn set by ne_hook_create_request *** */

void neon_cb___cb__2 (void *userdata, ne_request *req,
				     const char *method, const char *uri)
    {

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__2", 7, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
	
        {
        SV ** ppArg ;
        ppArg = hv_fetch (pC2Perl, (char *)(&req), sizeof(req), 1) ;
        if (!SvOK(*ppArg))
            {
            SV * pObj ;
            *ppArg = newRV_noinc ((SV *)newHV()) ;
            sv_2mortal(*ppArg) ;
	    sv_bless (*ppArg, gv_stashpv ("HTTP::Webdav::Request", 0)) ;
            hv_store (pPerl2C, (char *)(SvRV (*ppArg)), sizeof (void *), newSViv ((IV)req), 0) ;
            }
        pSV = *ppArg ;
        }
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, method);
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, uri);
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_VOID) ;
		}

    FREETMPS ;
    LEAVE ;

    }

    
    /* *** ne_destory_fn set by ne_hook_destroy_request *** */

void neon_cb___cb__3 (void *userdata)
    {

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__3", 7, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_VOID) ;
		}

    FREETMPS ;
    LEAVE ;

    }

    
    /* *** ne_destory_fn set by ne_hook_destroy_session *** */

void neon_cb___cb__4 (void *userdata)
    {

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__4", 7, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_VOID) ;
		}

    FREETMPS ;
    LEAVE ;

    }

    
    /* *** ne_header_handler set by ne_add_response_header_catcher *** */

void neon_cb___cb__25 (void *userdata, const char *value)
    {

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__25", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, value);
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_VOID) ;
		}

    FREETMPS ;
    LEAVE ;

    }

    
    /* *** ne_header_handler set by ne_add_response_header_handler *** */

void neon_cb___cb__26 (void *userdata, const char *value)
    {

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__26", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, value);
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_VOID) ;
		}

    FREETMPS ;
    LEAVE ;

    }

    
    /* *** ne_lock_result set by ne_lock_discover *** */

void neon_cb___cb__7 (void *userdata, const struct ne_lock *lock, 
			       const char *uri, const ne_status *status)
    {

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__7", 7, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
	
        {
        HV * _pHV_ ;
        if (!SvOK(pSV))
            {
            pSV = newRV_noinc((SV *)(_pHV_ = newHV())) ;
            sv_2mortal (pSV) ;
            }
        else if (!SvROK (pSV))
            {
            croak ("lock must be a reference") ;
            }
        else if (SvTYPE(_pHV_ = (HV *)SvRV(pSV)) != SVt_PVHV)
	    SvUPGRADE ((SV *)_pHV_, SVt_PVHV) ;
        if (lock)
            {
	sv_setpv((SV*)__fetchmember(_pHV_,"uri"), ((const struct ne_lock *)lock)->uri);
	;
	sv_setiv(__fetchmember(_pHV_,"depth"), (IV)((const struct ne_lock *)lock)->depth);
	;
	sv_setiv(__fetchmember(_pHV_,"type"), (IV)((const struct ne_lock *)lock)->type);
	;
	sv_setiv(__fetchmember(_pHV_,"scope"), (IV)((const struct ne_lock *)lock)->scope);
	;
	sv_setpv((SV*)__fetchmember(_pHV_,"token"), ((const struct ne_lock *)lock)->token);
	;
	sv_setpv((SV*)__fetchmember(_pHV_,"owner"), ((const struct ne_lock *)lock)->owner);
	;
	sv_setiv(__fetchmember(_pHV_,"timeout"), (IV)((const struct ne_lock *)lock)->timeout);
	;
	sv_setiv(__fetchmember(_pHV_,"prev"), (IV)((const struct ne_lock *)lock)->prev);
	;
	sv_setiv(__fetchmember(_pHV_,"next"), (IV)((const struct ne_lock *)lock)->next);
	;

            }
        }
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, uri);
	XPUSHs(pSV);
	pSV = sv_newmortal ();
	
        {
        HV * _pHV_ ;
        if (!SvOK(pSV))
            {
            pSV = newRV_noinc((SV *)(_pHV_ = newHV())) ;
            sv_2mortal (pSV) ;
            }
        else if (!SvROK (pSV))
            {
            croak ("status must be a reference") ;
            }
        else if (SvTYPE(_pHV_ = (HV *)SvRV(pSV)) != SVt_PVHV)
	    SvUPGRADE ((SV *)_pHV_, SVt_PVHV) ;
        if (status)
            {
	sv_setiv(__fetchmember(_pHV_,"major_version"), (IV)((const ne_status *)status)->major_version);
	;
	sv_setiv(__fetchmember(_pHV_,"minor_version"), (IV)((const ne_status *)status)->minor_version);
	;
	sv_setiv(__fetchmember(_pHV_,"code"), (IV)((const ne_status *)status)->code);
	;
	sv_setiv(__fetchmember(_pHV_,"klass"), (IV)((const ne_status *)status)->klass);
	;
	sv_setpv((SV*)__fetchmember(_pHV_,"reason_phrase"), ((const ne_status *)status)->reason_phrase);
	;

            }
        }
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_VOID) ;
		}

    FREETMPS ;
    LEAVE ;

    }

    
    /* *** ne_lock_walkfunc set by ne_lock_iterate *** */

void neon_cb___cb__17 (struct ne_lock *lock, void *userdata)
    {

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__17", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = sv_newmortal ();
	
        {
        HV * _pHV_ ;
        if (!SvOK(pSV))
            {
            pSV = newRV_noinc((SV *)(_pHV_ = newHV())) ;
            sv_2mortal (pSV) ;
            }
        else if (!SvROK (pSV))
            {
            croak ("lock must be a reference") ;
            }
        else if (SvTYPE(_pHV_ = (HV *)SvRV(pSV)) != SVt_PVHV)
	    SvUPGRADE ((SV *)_pHV_, SVt_PVHV) ;
        if (lock)
            {
	sv_setpv((SV*)__fetchmember(_pHV_,"uri"), ((struct ne_lock *)lock)->uri);
	;
	sv_setiv(__fetchmember(_pHV_,"depth"), (IV)((struct ne_lock *)lock)->depth);
	;
	sv_setiv(__fetchmember(_pHV_,"type"), (IV)((struct ne_lock *)lock)->type);
	;
	sv_setiv(__fetchmember(_pHV_,"scope"), (IV)((struct ne_lock *)lock)->scope);
	;
	sv_setpv((SV*)__fetchmember(_pHV_,"token"), ((struct ne_lock *)lock)->token);
	;
	sv_setpv((SV*)__fetchmember(_pHV_,"owner"), ((struct ne_lock *)lock)->owner);
	;
	sv_setiv(__fetchmember(_pHV_,"timeout"), (IV)((struct ne_lock *)lock)->timeout);
	;
	sv_setiv(__fetchmember(_pHV_,"prev"), (IV)((struct ne_lock *)lock)->prev);
	;
	sv_setiv(__fetchmember(_pHV_,"next"), (IV)((struct ne_lock *)lock)->next);
	;

            }
        }
	XPUSHs(pSV);
	pSV = (SV *)userdata;
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_VOID) ;
		}

    FREETMPS ;
    LEAVE ;

    }

    
    /* *** ne_notify_status set by ne_set_status *** */

void neon_cb___cb__15 (void *userdata, 
				 ne_conn_status status,
				 const char *info)
    {

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__15", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, info);
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_VOID) ;
		}

    FREETMPS ;
    LEAVE ;

    }

    
    /* *** ne_post_send_fn set by ne_hook_post_send *** */

int neon_cb___cb__5 (void *userdata, const ne_status *status)
    {
	int retval ;

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__5", 7, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
	
        {
        HV * _pHV_ ;
        if (!SvOK(pSV))
            {
            pSV = newRV_noinc((SV *)(_pHV_ = newHV())) ;
            sv_2mortal (pSV) ;
            }
        else if (!SvROK (pSV))
            {
            croak ("status must be a reference") ;
            }
        else if (SvTYPE(_pHV_ = (HV *)SvRV(pSV)) != SVt_PVHV)
	    SvUPGRADE ((SV *)_pHV_, SVt_PVHV) ;
        if (status)
            {
	sv_setiv(__fetchmember(_pHV_,"major_version"), (IV)((const ne_status *)status)->major_version);
	;
	sv_setiv(__fetchmember(_pHV_,"minor_version"), (IV)((const ne_status *)status)->minor_version);
	;
	sv_setiv(__fetchmember(_pHV_,"code"), (IV)((const ne_status *)status)->code);
	;
	sv_setiv(__fetchmember(_pHV_,"klass"), (IV)((const ne_status *)status)->klass);
	;
	sv_setpv((SV*)__fetchmember(_pHV_,"reason_phrase"), ((const ne_status *)status)->reason_phrase);
	;

            }
        }
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_SCALAR) ;
		}

    SPAGAIN ;
    if (cnt != 1)
        {
        retval = 0 ;
        }
    else
        {
        pSV = POPs ;
	retval = (int)SvIV(pSV);
	}
	PUTBACK ;

    FREETMPS ;
    LEAVE ;
	return retval ;

    }

    
    /* *** ne_pre_send_fn set by ne_hook_pre_send *** */

void neon_cb___cb__6 (void *userdata, ne_buffer *header)
    {

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__6", 7, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
	
        {
        SV ** ppArg ;
        ppArg = hv_fetch (pC2Perl, (char *)(&header), sizeof(header), 1) ;
        if (!SvOK(*ppArg))
            {
            SV * pObj ;
            *ppArg = newRV_noinc ((SV *)newHV()) ;
            sv_2mortal(*ppArg) ;
	    sv_bless (*ppArg, gv_stashpv ("HTTP::Webdav::Buffer", 0)) ;
            hv_store (pPerl2C, (char *)(SvRV (*ppArg)), sizeof (void *), newSViv ((IV)header), 0) ;
            }
        pSV = *ppArg ;
        }
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_VOID) ;
		}

    FREETMPS ;
    LEAVE ;

    }

    
    /* *** ne_props_result set by ne_propnames *** */

void neon_cb___cb__8 (void *userdata, const char *href,
				 const ne_prop_result_set *results)
    {

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__8", 7, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, href);
	XPUSHs(pSV);
	pSV = sv_newmortal ();
	
        {
        SV ** ppArg ;
        ppArg = hv_fetch (pC2Perl, (char *)(&results), sizeof(results), 1) ;
        if (!SvOK(*ppArg))
            {
            SV * pObj ;
            *ppArg = newRV_noinc ((SV *)newHV()) ;
            sv_2mortal(*ppArg) ;
	    sv_bless (*ppArg, gv_stashpv ("HTTP::Webdav::Propset", 0)) ;
            hv_store (pPerl2C, (char *)(SvRV (*ppArg)), sizeof (void *), newSViv ((IV)results), 0) ;
            }
        pSV = *ppArg ;
        }
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_VOID) ;
		}

    FREETMPS ;
    LEAVE ;

    }

    
    /* *** ne_props_result set by ne_simple_propfind *** */

void neon_cb___cb__16 (void *userdata, const char *href,
				 const ne_prop_result_set *results)
    {

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__16", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, href);
	XPUSHs(pSV);
	pSV = sv_newmortal ();
	
        {
        SV ** ppArg ;
        ppArg = hv_fetch (pC2Perl, (char *)(&results), sizeof(results), 1) ;
        if (!SvOK(*ppArg))
            {
            SV * pObj ;
            *ppArg = newRV_noinc ((SV *)newHV()) ;
            sv_2mortal(*ppArg) ;
	    sv_bless (*ppArg, gv_stashpv ("HTTP::Webdav::Propset", 0)) ;
            hv_store (pPerl2C, (char *)(SvRV (*ppArg)), sizeof (void *), newSViv ((IV)results), 0) ;
            }
        pSV = *ppArg ;
        }
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_VOID) ;
		}

    FREETMPS ;
    LEAVE ;

    }

    
    /* *** ne_props_result set by ne_propfind_allprop *** */

void neon_cb___cb__20 (void *userdata, const char *href,
				 const ne_prop_result_set *results)
    {

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__20", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, href);
	XPUSHs(pSV);
	pSV = sv_newmortal ();
	
        {
        SV ** ppArg ;
        ppArg = hv_fetch (pC2Perl, (char *)(&results), sizeof(results), 1) ;
        if (!SvOK(*ppArg))
            {
            SV * pObj ;
            *ppArg = newRV_noinc ((SV *)newHV()) ;
            sv_2mortal(*ppArg) ;
	    sv_bless (*ppArg, gv_stashpv ("HTTP::Webdav::Propset", 0)) ;
            hv_store (pPerl2C, (char *)(SvRV (*ppArg)), sizeof (void *), newSViv ((IV)results), 0) ;
            }
        pSV = *ppArg ;
        }
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_VOID) ;
		}

    FREETMPS ;
    LEAVE ;

    }

    
    /* *** ne_props_result set by ne_propfind_named *** */

void neon_cb___cb__21 (void *userdata, const char *href,
				 const ne_prop_result_set *results)
    {

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__21", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, href);
	XPUSHs(pSV);
	pSV = sv_newmortal ();
	
        {
        SV ** ppArg ;
        ppArg = hv_fetch (pC2Perl, (char *)(&results), sizeof(results), 1) ;
        if (!SvOK(*ppArg))
            {
            SV * pObj ;
            *ppArg = newRV_noinc ((SV *)newHV()) ;
            sv_2mortal(*ppArg) ;
	    sv_bless (*ppArg, gv_stashpv ("HTTP::Webdav::Propset", 0)) ;
            hv_store (pPerl2C, (char *)(SvRV (*ppArg)), sizeof (void *), newSViv ((IV)results), 0) ;
            }
        pSV = *ppArg ;
        }
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_VOID) ;
		}

    FREETMPS ;
    LEAVE ;

    }

    
    /* *** ne_propset_iterator set by ne_propset_iterate *** */

int neon_cb___cb__22 (void *userdata,
				    const ne_propname *pname,
				    const char *value,
				    const ne_status *status)
    {
	int retval ;

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__22", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
	
        {
        HV * _pHV_ ;

        /* croak ("pname unsupported") ; */
        if (!SvOK(pSV))
            {
            pSV = newRV_noinc((SV *)(_pHV_ = newHV())) ;
            sv_2mortal (pSV) ;
            }
        else if (!SvROK (pSV))
            {
            croak ("pname must be a reference") ;
            }
        else if (SvTYPE(_pHV_ = (HV *)SvRV(pSV)) != SVt_PVHV)
	    SvUPGRADE ((SV *)_pHV_, SVt_PVHV) ;
        if (pname)
            {
	sv_setpv((SV*)__fetchmember(_pHV_,"nspace"), ((const ne_propname *)pname)->nspace);
	;
	sv_setpv((SV*)__fetchmember(_pHV_,"name"), ((const ne_propname *)pname)->name);
	;

            }
        }
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, value);
	XPUSHs(pSV);
	pSV = sv_newmortal ();
	
        {
        HV * _pHV_ ;
        if (!SvOK(pSV))
            {
            pSV = newRV_noinc((SV *)(_pHV_ = newHV())) ;
            sv_2mortal (pSV) ;
            }
        else if (!SvROK (pSV))
            {
            croak ("status must be a reference") ;
            }
        else if (SvTYPE(_pHV_ = (HV *)SvRV(pSV)) != SVt_PVHV)
	    SvUPGRADE ((SV *)_pHV_, SVt_PVHV) ;
        if (status)
            {
	sv_setiv(__fetchmember(_pHV_,"major_version"), (IV)((const ne_status *)status)->major_version);
	;
	sv_setiv(__fetchmember(_pHV_,"minor_version"), (IV)((const ne_status *)status)->minor_version);
	;
	sv_setiv(__fetchmember(_pHV_,"code"), (IV)((const ne_status *)status)->code);
	;
	sv_setiv(__fetchmember(_pHV_,"klass"), (IV)((const ne_status *)status)->klass);
	;
	sv_setpv((SV*)__fetchmember(_pHV_,"reason_phrase"), ((const ne_status *)status)->reason_phrase);
	;

            }
        }
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_SCALAR) ;
		}

    SPAGAIN ;
    if (cnt != 1)
        {
        retval = 0 ;
        }
    else
        {
        pSV = POPs ;
	retval = (int)SvIV(pSV);
	}
	PUTBACK ;

    FREETMPS ;
    LEAVE ;
	return retval ;

    }

    
    /* *** ne_provide_body set by ne_set_request_body_provider *** */

ssize_t neon_cb___cb__29 (void *userdata, 
				   char *buffer, size_t buflen)
    {
	ssize_t retval ;

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__29", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, buffer);
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setiv(pSV, (IV)buflen);
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_SCALAR) ;
		}

    SPAGAIN ;
    if (cnt != 1)
        {
        retval = 0 ;
        }
    else
        {
        pSV = POPs ;
	retval = (ssize_t)SvIV(pSV);
	}
	PUTBACK ;

    FREETMPS ;
    LEAVE ;
	return retval ;

    }

    
    /* *** ne_redirect_confirm set by ne_redirect_register *** */

int neon_cb___cb__10 (void *userdata,
				   const char *src, const char *dest)
    {
	int retval ;

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__10", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, src);
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, dest);
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_SCALAR) ;
		}

    SPAGAIN ;
    if (cnt != 1)
        {
        retval = 0 ;
        }
    else
        {
        pSV = POPs ;
	retval = (int)SvIV(pSV);
	}
	PUTBACK ;

    FREETMPS ;
    LEAVE ;
	return retval ;

    }

    
    /* *** ne_redirect_notify set by ne_redirect_register *** */

void neon_cb___cb__11 (void *userdata,
				   const char *src, const char *dest)
    {

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__11", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, src);
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, dest);
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_VOID) ;
		}

    FREETMPS ;
    LEAVE ;

    }

    
    /* *** ne_request_auth set by ne_set_proxy_auth *** */

int neon_cb___cb__13 (
    void *userdata, const char *realm,
    char **username, char **password)
    {
	int retval ;

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__13", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, realm);
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		XPUSHs(pSV);
	pSV = sv_newmortal ();
		XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_ARRAY) ;
		}
	SPAGAIN ; 
	
    if (cnt < 2)
        retval = -1 ;
    else
        {
        SV * pPassword = POPs ;
        SV * pUsername = POPs ;
        char * s ;
        STRLEN l ;
        s = SvPV (pUsername, l) ;
        *username = malloc (l + 1) ;
        strcpy (*username, s) ;
        s = SvPV (pPassword, l) ;
        *password = malloc (l + 1) ;
        strcpy (*password, s) ;
        retval = 0 ;
        }
 ;
	PUTBACK ;

    FREETMPS ;
    LEAVE ;
	return retval ;

    }

    
    /* *** ne_request_auth set by ne_set_server_auth *** */

int neon_cb___cb__14 (
    void *userdata, const char *realm,
    char **username, char **password)
    {
	int retval ;

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__14", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, realm);
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		XPUSHs(pSV);
	pSV = sv_newmortal ();
		XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_ARRAY) ;
		}
	SPAGAIN ; 
	
    if (cnt < 2)
        retval = -1 ;
    else
        {
        SV * pPassword = POPs ;
        SV * pUsername = POPs ;
        char * s ;
        STRLEN l ;
        s = SvPV (pUsername, l) ;
        *username = malloc (l + 1) ;
        strcpy (*username, s) ;
        s = SvPV (pPassword, l) ;
        *password = malloc (l + 1) ;
        strcpy (*password, s) ;
        retval = 0 ;
        }
 ;
	PUTBACK ;

    FREETMPS ;
    LEAVE ;
	return retval ;

    }

    
    /* *** ne_use_proxy set by ne_session_decide_proxy *** */

int neon_cb___cb__1 (void *userdata,
			    const char *scheme, const char *hostname)
    {
	int retval ;

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__1", 7, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, scheme);
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, hostname);
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_SCALAR) ;
		}

    SPAGAIN ;
    if (cnt != 1)
        {
        retval = 0 ;
        }
    else
        {
        pSV = POPs ;
	retval = (int)SvIV(pSV);
	}
	PUTBACK ;

    FREETMPS ;
    LEAVE ;
	return retval ;

    }

    
    /* *** ne_xml_cdata_cb set by ne_xml_push_mixed_handler *** */

void neon_cb___cb__38 (void *userdata, const struct ne_xml_elm *s, 
     const char *cdata, int len)
    {

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__38", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
	sv_setiv(pSV, (IV)s);	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, cdata);
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setiv(pSV, (IV)len);
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_VOID) ;
		}

    FREETMPS ;
    LEAVE ;

    }

    
    /* *** ne_xml_endelm_cb set by ne_xml_push_handler *** */

int neon_cb___cb__35 (void *userdata, const struct ne_xml_elm *s, const char *cdata)
    {
	int retval ;

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__35", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
	sv_setiv(pSV, (IV)s);	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, cdata);
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_SCALAR) ;
		}

    SPAGAIN ;
    if (cnt != 1)
        {
        retval = 0 ;
        }
    else
        {
        pSV = POPs ;
	retval = (int)SvIV(pSV);
	}
	PUTBACK ;

    FREETMPS ;
    LEAVE ;
	return retval ;

    }

    
    /* *** ne_xml_endelm_cb set by ne_xml_push_mixed_handler *** */

int neon_cb___cb__39 (void *userdata, const struct ne_xml_elm *s, const char *cdata)
    {
	int retval ;

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__39", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
	sv_setiv(pSV, (IV)s);	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, cdata);
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_SCALAR) ;
		}

    SPAGAIN ;
    if (cnt != 1)
        {
        retval = 0 ;
        }
    else
        {
        pSV = POPs ;
	retval = (int)SvIV(pSV);
	}
	PUTBACK ;

    FREETMPS ;
    LEAVE ;
	return retval ;

    }

    
    /* *** ne_xml_startelm_cb set by ne_xml_push_handler *** */

int neon_cb___cb__34 (void *userdata, const struct ne_xml_elm *elm, const char **atts)
    {
	int retval ;

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__34", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
	sv_setiv(pSV, (IV)elm);	XPUSHs(pSV);
	pSV = sv_newmortal ();
		XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_SCALAR) ;
		}

    SPAGAIN ;
    if (cnt != 1)
        {
        retval = 0 ;
        }
    else
        {
        pSV = POPs ;
	retval = (int)SvIV(pSV);
	}
	PUTBACK ;

    FREETMPS ;
    LEAVE ;
	return retval ;

    }

    
    /* *** ne_xml_startelm_cb set by ne_xml_push_mixed_handler *** */

int neon_cb___cb__37 (void *userdata, const struct ne_xml_elm *elm, const char **atts)
    {
	int retval ;

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__37", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
	sv_setiv(pSV, (IV)elm);	XPUSHs(pSV);
	pSV = sv_newmortal ();
		XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_SCALAR) ;
		}

    SPAGAIN ;
    if (cnt != 1)
        {
        retval = 0 ;
        }
    else
        {
        pSV = POPs ;
	retval = (int)SvIV(pSV);
	}
	PUTBACK ;

    FREETMPS ;
    LEAVE ;
	return retval ;

    }

    
    /* *** ne_xml_validate_cb set by ne_xml_push_handler *** */

int neon_cb___cb__33 (void *userdata, ne_xml_elmid parent, ne_xml_elmid child)
    {
	int retval ;

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__33", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		XPUSHs(pSV);
	pSV = sv_newmortal ();
		XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_SCALAR) ;
		}

    SPAGAIN ;
    if (cnt != 1)
        {
        retval = 0 ;
        }
    else
        {
        pSV = POPs ;
	retval = (int)SvIV(pSV);
	}
	PUTBACK ;

    FREETMPS ;
    LEAVE ;
	return retval ;

    }

    
    /* *** ne_xml_validate_cb set by ne_xml_push_mixed_handler *** */

int neon_cb___cb__36 (void *userdata, ne_xml_elmid parent, ne_xml_elmid child)
    {
	int retval ;

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__36", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		XPUSHs(pSV);
	pSV = sv_newmortal ();
		XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_SCALAR) ;
		}

    SPAGAIN ;
    if (cnt != 1)
        {
        retval = 0 ;
        }
    else
        {
        pSV = POPs ;
	retval = (int)SvIV(pSV);
	}
	PUTBACK ;

    FREETMPS ;
    LEAVE ;
	return retval ;

    }

    
    /* *** nssl_key_prompt set by sock_set_key_prompt *** */

int neon_cb___cb__30 (void *userdata, const char *filename,
			       char *buf, int buflen)
    {
	int retval ;

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__30", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, filename);
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, buf);
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setiv(pSV, (IV)buflen);
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_SCALAR) ;
		}

    SPAGAIN ;
    if (cnt != 1)
        {
        retval = 0 ;
        }
    else
        {
        pSV = POPs ;
	retval = (int)SvIV(pSV);
	}
	PUTBACK ;

    FREETMPS ;
    LEAVE ;
	return retval ;

    }

    
    /* *** sock_block_reader set by sock_readfile_blocked *** */

void neon_cb___cb__31 (
    void *userdata, const char *buf, size_t len)
    {

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__31", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setpv((SV*)pSV, buf);
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setiv(pSV, (IV)len);
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_VOID) ;
		}

    FREETMPS ;
    LEAVE ;

    }

    
    /* *** sock_progress set by ne_set_progress *** */

void neon_cb___cb__12 (void *userdata, off_t progress, off_t total)
    {

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__12", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setiv(pSV, (IV)progress);
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setiv(pSV, (IV)total);
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_VOID) ;
		}

    FREETMPS ;
    LEAVE ;

    }

    
    /* *** sock_progress set by sock_register_progress *** */

void neon_cb___cb__32 (void *userdata, off_t progress, off_t total)
    {

    int cnt ;
    SV * pSV ;
    SV ** ppCV ;

    dSP ;
    ENTER ;
    SAVETMPS ;
    PUSHMARK(SP) ;

    ppCV = hv_fetch ((HV *)SvRV((SV *)userdata), "__cb__32", 8, 0) ;
    if (ppCV && *ppCV)
        {
	pSV = (SV *)userdata;
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setiv(pSV, (IV)progress);
	XPUSHs(pSV);
	pSV = sv_newmortal ();
		sv_setiv(pSV, (IV)total);
	XPUSHs(pSV);

    PUTBACK ;
		cnt = perl_call_sv (*ppCV, G_VOID) ;
		}

    FREETMPS ;
    LEAVE ;

    }



MODULE = HTTP::Webdav         PACKAGE = HTTP::Webdav


int
DESTROY(sess)
	ne_session * sess
CODE:
	RETVAL = 	ne_session_destroy(sess);

        hv_delete (pPerl2C, (char *)(SvRV(ST(0))), sizeof (void *), G_DISCARD) ;
            {
            SV ** ppArg = hv_fetch (pC2Perl, (char *)(&sess), sizeof(sess), 0) ;
	    if (ppArg && *ppArg)
                {
                *ppArg = NULL ;
                hv_delete (pC2Perl, (char *)(&sess), sizeof(sess), G_DISCARD) ;
                }
            }
OUTPUT:
RETVAL


int
acl_set(sess,uri,entries,numentries)
	ne_session * sess
	char * uri
	ne_acl_entry * entries
	int numentries
CODE:
	RETVAL = 	ne_acl_set(sess,uri,entries,numentries);
OUTPUT:
RETVAL


int
close_connection(sess)
	ne_session * sess
CODE:
	RETVAL = 	ne_close_connection(sess);
OUTPUT:
RETVAL


void
cookie_register(sess,cache)
	ne_session * sess
	ne_cookie_cache * cache
CODE:
	ne_cookie_register(sess,cache);


int
copy(sess,overwrite,depth,src,dest)
	ne_session * sess
	int overwrite
	int depth
	char * src
	char * dest
CODE:
	RETVAL = 	ne_copy(sess,overwrite,depth,src,dest);
OUTPUT:
RETVAL


void
decide_proxy(sess,use_proxy)
	ne_session * sess
	CV * use_proxy

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (use_proxy)
                {
                SvREFCNT_inc ((SV *)use_proxy) ;
                hv_store (pObjHV, "__cb__1", 7, (SV *)use_proxy, 0) ; 
                }
	ne_session_decide_proxy(sess,use_proxy?&neon_cb___cb__1:NULL,pObject);


int
delete(sess,uri)
	ne_session * sess
	char * uri
CODE:
	RETVAL = 	ne_delete(sess,uri);
OUTPUT:
RETVAL


void
forget_auth(sess)
	ne_session * sess
CODE:
	ne_forget_auth(sess);


int
get(sess,uri,fd)
	ne_session * sess
	char * uri
	int fd
CODE:
	RETVAL = 	ne_get(sess,uri,fd);
OUTPUT:
RETVAL


const char *
get_error(sess)
	ne_session * sess
CODE:
	RETVAL = 	ne_get_error(sess);
OUTPUT:
RETVAL


int
get_range(sess,uri,range,fd)
	ne_session * sess
	char * uri
	ne_content_range * range
	int fd
CODE:
	RETVAL = 	ne_get_range(sess,uri,range,fd);
OUTPUT:
RETVAL


const char *
get_scheme(sess)
	ne_session * sess
CODE:
	RETVAL = 	ne_get_scheme(sess);
OUTPUT:
RETVAL


const char *
get_server_hostport(sess)
	ne_session * sess
CODE:
	RETVAL = 	ne_get_server_hostport(sess);
OUTPUT:
RETVAL


int
getmodtime(sess,uri,modtime)
	ne_session * sess
	char * uri
	time_t * modtime
CODE:
	RETVAL = 	ne_getmodtime(sess,uri,modtime);
OUTPUT:
RETVAL


void
hook_create_request(sess,fn)
	ne_session * sess
	CV * fn

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (fn)
                {
                SvREFCNT_inc ((SV *)fn) ;
                hv_store (pObjHV, "__cb__2", 7, (SV *)fn, 0) ; 
                }
	ne_hook_create_request(sess,fn?&neon_cb___cb__2:NULL,pObject);


void
hook_destroy_request(sess,fn)
	ne_session * sess
	CV * fn

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (fn)
                {
                SvREFCNT_inc ((SV *)fn) ;
                hv_store (pObjHV, "__cb__3", 7, (SV *)fn, 0) ; 
                }
	ne_hook_destroy_request(sess,fn?&neon_cb___cb__3:NULL,pObject);


void
hook_destroy_session(sess,fn)
	ne_session * sess
	CV * fn

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (fn)
                {
                SvREFCNT_inc ((SV *)fn) ;
                hv_store (pObjHV, "__cb__4", 7, (SV *)fn, 0) ; 
                }
	ne_hook_destroy_session(sess,fn?&neon_cb___cb__4:NULL,pObject);


void
hook_post_send(sess,fn)
	ne_session * sess
	CV * fn

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (fn)
                {
                SvREFCNT_inc ((SV *)fn) ;
                hv_store (pObjHV, "__cb__5", 7, (SV *)fn, 0) ; 
                }
	ne_hook_post_send(sess,fn?&neon_cb___cb__5:NULL,pObject);


void
hook_pre_send(sess,fn)
	ne_session * sess
	CV * fn

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (fn)
                {
                SvREFCNT_inc ((SV *)fn) ;
                hv_store (pObjHV, "__cb__6", 7, (SV *)fn, 0) ; 
                }
	ne_hook_pre_send(sess,fn?&neon_cb___cb__6:NULL,pObject);


void *
hook_private(sess,id)
	ne_session * sess
	char * id
CODE:
	RETVAL = 	ne_session_hook_private(sess,id);
OUTPUT:
RETVAL


void
hook_session_accessor(sess,id,arg2,userdata)
	ne_session * sess
	char * id
	ne_accessor_fn arg2
	void * userdata
CODE:
	ne_hook_session_accessor(sess,id,arg2,userdata);


int
lock(sess,lock)
	ne_session * sess
	struct ne_lock * lock
CODE:
	RETVAL = 	ne_lock(sess,lock);
OUTPUT:
RETVAL
lock


int
lock_discover(sess,uri,result)
	ne_session * sess
	char * uri
	CV * result

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (result)
                {
                SvREFCNT_inc ((SV *)result) ;
                hv_store (pObjHV, "__cb__7", 7, (SV *)result, 0) ; 
                }
	RETVAL = 	ne_lock_discover(sess,uri,result?&neon_cb___cb__7:NULL,pObject);
OUTPUT:
RETVAL


int
lock_refresh(sess,lock)
	ne_session * sess
	struct ne_lock * lock
CODE:
	RETVAL = 	ne_lock_refresh(sess,lock);
OUTPUT:
RETVAL


ne_lock_session *
lock_register(sess)
	ne_session * sess
CODE:
	RETVAL = 	ne_lock_register(sess);
OUTPUT:
RETVAL


int
mkcol(sess,uri)
	ne_session * sess
	char * uri
CODE:
	RETVAL = 	ne_mkcol(sess,uri);
OUTPUT:
RETVAL


int
move(sess,overwrite,src,dest)
	ne_session * sess
	int overwrite
	char * src
	char * dest
CODE:
	RETVAL = 	ne_move(sess,overwrite,src,dest);
OUTPUT:
RETVAL


int
options(sess,uri,caps)
	ne_session * sess
	char * uri
	ne_server_capabilities * caps
CODE:
	RETVAL = 	ne_options(sess,uri,caps);
OUTPUT:
RETVAL
caps


int
post(sess,uri,fd,buffer)
	ne_session * sess
	char * uri
	int fd
	char * buffer
CODE:
	RETVAL = 	ne_post(sess,uri,fd,buffer);
OUTPUT:
RETVAL


ne_propfind_handler *
propfind_create(sess,uri,depth)
	ne_session * sess
	char * uri
	int depth
CODE:
	RETVAL = 	ne_propfind_create(sess,uri,depth);
OUTPUT:
RETVAL


int
propnames(sess,href,depth,results)
	ne_session * sess
	char * href
	int depth
	CV * results

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (results)
                {
                SvREFCNT_inc ((SV *)results) ;
                hv_store (pObjHV, "__cb__8", 7, (SV *)results, 0) ; 
                }
	RETVAL = 	ne_propnames(sess,href,depth,results?&neon_cb___cb__8:NULL,pObject);
OUTPUT:
RETVAL


int
proppatch(sess,uri,items)
	ne_session * sess
	char * uri
	ne_proppatch_operation * items
CODE:
	RETVAL = 	ne_proppatch(sess,uri,items);
OUTPUT:
RETVAL


int
proxy(sess,hostname,port)
	ne_session * sess
	char * hostname
	int port
CODE:
	RETVAL = 	ne_session_proxy(sess,hostname,port);
OUTPUT:
RETVAL


int
put(sess,uri,fd)
	ne_session * sess
	char * uri
	int fd
CODE:
	RETVAL = 	ne_put(sess,uri,fd);
OUTPUT:
RETVAL


int
put_if_unmodified(sess,uri,fd,modtime)
	ne_session * sess
	char * uri
	int fd
	time_t modtime
CODE:
	RETVAL = 	ne_put_if_unmodified(sess,uri,fd,modtime);
OUTPUT:
RETVAL


int
read_file(sess,uri,reader)
	ne_session * sess
	char * uri
	CV * reader

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (reader)
                {
                SvREFCNT_inc ((SV *)reader) ;
                hv_store (pObjHV, "__cb__9", 7, (SV *)reader, 0) ; 
                }
	RETVAL = 	ne_read_file(sess,uri,reader?&neon_cb___cb__9:NULL,pObject);
OUTPUT:
RETVAL


const char *
redirect_location(sess)
	ne_session * sess
CODE:
	RETVAL = 	ne_redirect_location(sess);
OUTPUT:
RETVAL


void
redirect_register(sess,confirm,notify)
	ne_session * sess
	CV * confirm
	CV * notify

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (confirm)
                {
                SvREFCNT_inc ((SV *)confirm) ;
                hv_store (pObjHV, "__cb__10", 8, (SV *)confirm, 0) ; 
                }

            if (notify)
                {
                SvREFCNT_inc ((SV *)notify) ;
                hv_store (pObjHV, "__cb__11", 8, (SV *)notify, 0) ; 
                }
	ne_redirect_register(sess,confirm?&neon_cb___cb__10:NULL,notify?&neon_cb___cb__11:NULL,pObject);


ne_request *
request_create(sess,method,uri)
	ne_session * sess
	char * method
	char * uri
CODE:
	RETVAL = 	ne_request_create(sess,method,uri);
OUTPUT:
RETVAL


int
server(sess,hostname,port)
	ne_session * sess
	char * hostname
	int port
CODE:
	RETVAL = 	ne_session_server(sess,hostname,port);
OUTPUT:
RETVAL


int
set_accept_secure_upgrade(sess,acc_upgrade)
	ne_session * sess
	int acc_upgrade
CODE:
	RETVAL = 	ne_set_accept_secure_upgrade(sess,acc_upgrade);
OUTPUT:
RETVAL


void
set_error(sess,errstring)
	ne_session * sess
	char * errstring
CODE:
	ne_set_error(sess,errstring);


void
set_expect100(sess,use_expect100)
	ne_session * sess
	int use_expect100
CODE:
	ne_set_expect100(sess,use_expect100);


void
set_persist(sess,persist)
	ne_session * sess
	int persist
CODE:
	ne_set_persist(sess,persist);


void
set_progress(sess,progress)
	ne_session * sess
	CV * progress

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (progress)
                {
                SvREFCNT_inc ((SV *)progress) ;
                hv_store (pObjHV, "__cb__12", 8, (SV *)progress, 0) ; 
                }
	ne_set_progress(sess,progress?&neon_cb___cb__12:NULL,pObject);


void
set_proxy_auth(sess,callback)
	ne_session * sess
	CV * callback

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (callback)
                {
                SvREFCNT_inc ((SV *)callback) ;
                hv_store (pObjHV, "__cb__13", 8, (SV *)callback, 0) ; 
                }
	ne_set_proxy_auth(sess,callback?&neon_cb___cb__13:NULL,pObject);


int
set_request_secure_upgrade(sess,req_upgrade)
	ne_session * sess
	int req_upgrade
CODE:
	RETVAL = 	ne_set_request_secure_upgrade(sess,req_upgrade);
OUTPUT:
RETVAL


int
set_secure(sess,secure)
	ne_session * sess
	int secure
CODE:
	RETVAL = 	ne_set_secure(sess,secure);
OUTPUT:
RETVAL


void
set_secure_context(sess,ctx)
	ne_session * sess
	nssl_context * ctx
CODE:
	ne_set_secure_context(sess,ctx);


void
set_server_auth(sess,callback)
	ne_session * sess
	CV * callback

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (callback)
                {
                SvREFCNT_inc ((SV *)callback) ;
                hv_store (pObjHV, "__cb__14", 8, (SV *)callback, 0) ; 
                }
	ne_set_server_auth(sess,callback?&neon_cb___cb__14:NULL,pObject);


void
set_status(sess,status)
	ne_session * sess
	CV * status

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (status)
                {
                SvREFCNT_inc ((SV *)status) ;
                hv_store (pObjHV, "__cb__15", 8, (SV *)status, 0) ; 
                }
	ne_set_status(sess,status?&neon_cb___cb__15:NULL,pObject);


void
set_useragent(sess,product)
	ne_session * sess
	char * product
CODE:
	ne_set_useragent(sess,product);


int
simple_propfind(sess,uri,depth,props,results)
	ne_session * sess
	char * uri
	int depth
	ne_propname * props
	CV * results

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (results)
                {
                SvREFCNT_inc ((SV *)results) ;
                hv_store (pObjHV, "__cb__16", 8, (SV *)results, 0) ; 
                }
	RETVAL = 	ne_simple_propfind(sess,uri,depth,props,results?&neon_cb___cb__16:NULL,pObject);
OUTPUT:
RETVAL


int
simple_request(sess,req)
	ne_session * sess
	ne_request * req
CODE:
	RETVAL = 	ne_simple_request(sess,req);
OUTPUT:
RETVAL


int
unlock(sess,lock)
	ne_session * sess
	struct ne_lock * lock
CODE:
	RETVAL = 	ne_unlock(sess,lock);
OUTPUT:
RETVAL


int
version_pre_http11(sess)
	ne_session * sess
CODE:
	RETVAL = 	ne_version_pre_http11(sess);
OUTPUT:
RETVAL

MODULE = HTTP::Webdav         PACKAGE = HTTP::Webdav::Buffer


void
DESTROY(buf)
	ne_buffer * buf
CODE:
	ne_buffer_destroy(buf);

        hv_delete (pPerl2C, (char *)(SvRV(ST(0))), sizeof (void *), G_DISCARD) ;
            {
            SV ** ppArg = hv_fetch (pC2Perl, (char *)(&buf), sizeof(buf), 0) ;
	    if (ppArg && *ppArg)
                {
                *ppArg = NULL ;
                hv_delete (pC2Perl, (char *)(&buf), sizeof(buf), G_DISCARD) ;
                }
            }


void
altered(buf)
	ne_buffer * buf
CODE:
	ne_buffer_altered(buf);


int
append(buf,data,len)
	ne_buffer * buf
	char * data
	size_t len
CODE:
	RETVAL = 	ne_buffer_append(buf,data,len);
OUTPUT:
RETVAL


void
clear(buf)
	ne_buffer * buf
CODE:
	ne_buffer_clear(buf);


char *
finish(buf)
	ne_buffer * buf
CODE:
	RETVAL = 	ne_buffer_finish(buf);
OUTPUT:
RETVAL


int
grow(buf,size)
	ne_buffer * buf
	size_t size
CODE:
	RETVAL = 	ne_buffer_grow(buf,size);
OUTPUT:
RETVAL


int
zappend(buf,str)
	ne_buffer * buf
	char * str
CODE:
	RETVAL = 	ne_buffer_zappend(buf,str);
OUTPUT:
RETVAL

MODULE = HTTP::Webdav         PACKAGE = HTTP::Webdav::LockSession



void
DESTROY(obj)
	ne_lock_session * obj
CODE:
        hv_delete (pPerl2C, (char *)(SvRV(ST(0))), sizeof (void *), G_DISCARD) ;
            {
            SV ** ppArg = hv_fetch (pC2Perl, (char *)(&obj), sizeof(obj), 0) ;
	    if (ppArg && *ppArg)
                {
                *ppArg = NULL ;
                hv_delete (pC2Perl, (char *)(&obj), sizeof(obj), G_DISCARD) ;
                }
            }


void
add(sess,lock)
	ne_lock_session * sess
	struct ne_lock * lock
CODE:
	ne_lock_add(sess,lock);


struct ne_lock *
find(sess,uri)
	ne_lock_session * sess
	char * uri
CODE:
	RETVAL = 	ne_lock_find(sess,uri);
OUTPUT:
RETVAL


int
iterate(sess,func)
	ne_lock_session * sess
	CV * func

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (func)
                {
                SvREFCNT_inc ((SV *)func) ;
                hv_store (pObjHV, "__cb__17", 8, (SV *)func, 0) ; 
                }
	RETVAL = 	ne_lock_iterate(sess,func?&neon_cb___cb__17:NULL,pObject);
OUTPUT:
RETVAL


void
remove(sess,lock)
	ne_lock_session * sess
	struct ne_lock * lock
CODE:
	ne_lock_remove(sess,lock);

MODULE = HTTP::Webdav         PACKAGE = HTTP::Webdav::MD5



void
DESTROY(obj)
	struct ne_md5_ctx * obj
CODE:
        hv_delete (pPerl2C, (char *)(SvRV(ST(0))), sizeof (void *), G_DISCARD) ;
            {
            SV ** ppArg = hv_fetch (pC2Perl, (char *)(&obj), sizeof(obj), 0) ;
	    if (ppArg && *ppArg)
                {
                *ppArg = NULL ;
                hv_delete (pC2Perl, (char *)(&obj), sizeof(obj), G_DISCARD) ;
                }
            }


void *
finish_ctx(ctx,resbuf)
	struct ne_md5_ctx * ctx
	void * resbuf
CODE:
	RETVAL = 	ne_md5_finish_ctx(ctx,resbuf);
OUTPUT:
RETVAL


void
init_ctx(ctx)
	struct ne_md5_ctx * ctx
CODE:
	ne_md5_init_ctx(ctx);


void *
read_ctx(ctx,resbuf)
	struct ne_md5_ctx * ctx
	void * resbuf
CODE:
	RETVAL = 	ne_md5_read_ctx(ctx,resbuf);
OUTPUT:
RETVAL

MODULE = HTTP::Webdav         PACKAGE = HTTP::Webdav::MultiStatus


void
DESTROY(p)
	ne_207_parser * p
CODE:
	ne_207_destroy(p);

        hv_delete (pPerl2C, (char *)(SvRV(ST(0))), sizeof (void *), G_DISCARD) ;
            {
            SV ** ppArg = hv_fetch (pC2Perl, (char *)(&p), sizeof(p), 0) ;
	    if (ppArg && *ppArg)
                {
                *ppArg = NULL ;
                hv_delete (pC2Perl, (char *)(&p), sizeof(p), G_DISCARD) ;
                }
            }


void *
get_current_propstat(p)
	ne_207_parser * p
CODE:
	RETVAL = 	ne_207_get_current_propstat(p);
OUTPUT:
RETVAL


void *
get_current_response(p)
	ne_207_parser * p
CODE:
	RETVAL = 	ne_207_get_current_response(p);
OUTPUT:
RETVAL


void
ignore_unknown(p)
	ne_207_parser * p
CODE:
	ne_207_ignore_unknown(p);


void
set_propstat_handlers(p,start,end)
	ne_207_parser * p
	ne_207_start_propstat start
	CV * end

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (end)
                {
                SvREFCNT_inc ((SV *)end) ;
                hv_store (pObjHV, "__cb__18", 8, (SV *)end, 0) ; 
                }
	ne_207_set_propstat_handlers(p,start,end?&neon_cb___cb__18:NULL);


void
set_response_handlers(p,start,end)
	ne_207_parser * p
	ne_207_start_response start
	CV * end

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (end)
                {
                SvREFCNT_inc ((SV *)end) ;
                hv_store (pObjHV, "__cb__19", 8, (SV *)end, 0) ; 
                }
	ne_207_set_response_handlers(p,start,end?&neon_cb___cb__19:NULL);

MODULE = HTTP::Webdav         PACKAGE = HTTP::Webdav::Propfind


void
DESTROY(handler)
	ne_propfind_handler * handler
CODE:
	ne_propfind_destroy(handler);

        hv_delete (pPerl2C, (char *)(SvRV(ST(0))), sizeof (void *), G_DISCARD) ;
            {
            SV ** ppArg = hv_fetch (pC2Perl, (char *)(&handler), sizeof(handler), 0) ;
	    if (ppArg && *ppArg)
                {
                *ppArg = NULL ;
                hv_delete (pC2Perl, (char *)(&handler), sizeof(handler), G_DISCARD) ;
                }
            }


int
allprop(handler,result)
	ne_propfind_handler * handler
	CV * result

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (result)
                {
                SvREFCNT_inc ((SV *)result) ;
                hv_store (pObjHV, "__cb__20", 8, (SV *)result, 0) ; 
                }
	RETVAL = 	ne_propfind_allprop(handler,result?&neon_cb___cb__20:NULL,pObject);
OUTPUT:
RETVAL


void *
current_private(handler)
	ne_propfind_handler * handler
CODE:
	RETVAL = 	ne_propfind_current_private(handler);
OUTPUT:
RETVAL


ne_xml_parser *
get_parser(handler)
	ne_propfind_handler * handler
CODE:
	RETVAL = 	ne_propfind_get_parser(handler);
OUTPUT:
RETVAL


ne_request *
get_request(handler)
	ne_propfind_handler * handler
CODE:
	RETVAL = 	ne_propfind_get_request(handler);
OUTPUT:
RETVAL


int
named(handler,prop,result)
	ne_propfind_handler * handler
	ne_propname * prop
	CV * result

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (result)
                {
                SvREFCNT_inc ((SV *)result) ;
                hv_store (pObjHV, "__cb__21", 8, (SV *)result, 0) ; 
                }
	RETVAL = 	ne_propfind_named(handler,prop,result?&neon_cb___cb__21:NULL,pObject);
OUTPUT:
RETVAL


void
set_private(handler,creator,userdata)
	ne_propfind_handler * handler
	ne_props_create_complex creator
	void * userdata
CODE:
	ne_propfind_set_private(handler,creator,userdata);

MODULE = HTTP::Webdav         PACKAGE = HTTP::Webdav::Propset



void
DESTROY(obj)
	const ne_prop_result_set * obj
CODE:
        hv_delete (pPerl2C, (char *)(SvRV(ST(0))), sizeof (void *), G_DISCARD) ;
            {
            SV ** ppArg = hv_fetch (pC2Perl, (char *)(&obj), sizeof(obj), 0) ;
	    if (ppArg && *ppArg)
                {
                *ppArg = NULL ;
                hv_delete (pC2Perl, (char *)(&obj), sizeof(obj), G_DISCARD) ;
                }
            }


int
iterate(set,iterator)
	ne_prop_result_set * set
	CV * iterator

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (iterator)
                {
                SvREFCNT_inc ((SV *)iterator) ;
                hv_store (pObjHV, "__cb__22", 8, (SV *)iterator, 0) ; 
                }
	RETVAL = 	ne_propset_iterate(set,iterator?&neon_cb___cb__22:NULL,pObject);
OUTPUT:
RETVAL


const char *
lang(set,pname)
	ne_prop_result_set * set
	ne_propname * pname
CODE:
	RETVAL = 	ne_propset_lang(set,pname);
OUTPUT:
RETVAL


void *
private(set)
	ne_prop_result_set * set
CODE:
	RETVAL = 	ne_propset_private(set);
OUTPUT:
RETVAL


const ne_status *
status(set,propname)
	ne_prop_result_set * set
	ne_propname * propname
CODE:
	RETVAL = 	ne_propset_status(set,propname);
OUTPUT:
RETVAL


const char *
value(set,propname)
	ne_prop_result_set * set
	ne_propname * propname
CODE:
	RETVAL = 	ne_propset_value(set,propname);
OUTPUT:
RETVAL

MODULE = HTTP::Webdav         PACKAGE = HTTP::Webdav::Request


void
DESTROY(req)
	ne_request * req
CODE:
	ne_request_destroy(req);

        hv_delete (pPerl2C, (char *)(SvRV(ST(0))), sizeof (void *), G_DISCARD) ;
            {
            SV ** ppArg = hv_fetch (pC2Perl, (char *)(&req), sizeof(req), 0) ;
	    if (ppArg && *ppArg)
                {
                *ppArg = NULL ;
                hv_delete (pC2Perl, (char *)(&req), sizeof(req), G_DISCARD) ;
                }
            }


void
add_depth_header(req,depth)
	ne_request * req
	int depth
CODE:
	ne_add_depth_header(req,depth);


void
add_request_header(req,name,value)
	ne_request * req
	char * name
	char * value
CODE:
	ne_add_request_header(req,name,value);


void
add_response_body_reader(req,accpt,rdr)
	ne_request * req
	CV * accpt
	CV * rdr

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (accpt)
                {
                SvREFCNT_inc ((SV *)accpt) ;
                hv_store (pObjHV, "__cb__23", 8, (SV *)accpt, 0) ; 
                }

            if (rdr)
                {
                SvREFCNT_inc ((SV *)rdr) ;
                hv_store (pObjHV, "__cb__24", 8, (SV *)rdr, 0) ; 
                }
	ne_add_response_body_reader(req,accpt?&neon_cb___cb__23:NULL,rdr?&neon_cb___cb__24:NULL,pObject);


void
add_response_header_catcher(req,hdl)
	ne_request * req
	CV * hdl

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (hdl)
                {
                SvREFCNT_inc ((SV *)hdl) ;
                hv_store (pObjHV, "__cb__25", 8, (SV *)hdl, 0) ; 
                }
	ne_add_response_header_catcher(req,hdl?&neon_cb___cb__25:NULL,pObject);


void
add_response_header_handler(req,name,hdl)
	ne_request * req
	char * name
	CV * hdl

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (hdl)
                {
                SvREFCNT_inc ((SV *)hdl) ;
                hv_store (pObjHV, "__cb__26", 8, (SV *)hdl, 0) ; 
                }
	ne_add_response_header_handler(req,name,hdl?&neon_cb___cb__26:NULL,pObject);


int
begin_request(req)
	ne_request * req
CODE:
	RETVAL = 	ne_begin_request(req);
OUTPUT:
RETVAL


ne_decompress *
decompress_reader(req,accpt,rdr)
	ne_request * req
	CV * accpt
	CV * rdr

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (accpt)
                {
                SvREFCNT_inc ((SV *)accpt) ;
                hv_store (pObjHV, "__cb__27", 8, (SV *)accpt, 0) ; 
                }

            if (rdr)
                {
                SvREFCNT_inc ((SV *)rdr) ;
                hv_store (pObjHV, "__cb__28", 8, (SV *)rdr, 0) ; 
                }
	RETVAL = 	ne_decompress_reader(req,accpt?&neon_cb___cb__27:NULL,rdr?&neon_cb___cb__28:NULL,pObject);
OUTPUT:
RETVAL


int
dispatch(req)
	ne_request * req
CODE:
	RETVAL = 	ne_request_dispatch(req);
OUTPUT:
RETVAL


int
end_request(req)
	ne_request * req
CODE:
	RETVAL = 	ne_end_request(req);
OUTPUT:
RETVAL


ne_session *
get_session(req)
	ne_request * req
CODE:
	RETVAL = 	ne_get_session(req);
OUTPUT:
RETVAL


const ne_status *
get_status(req)
	ne_request * req
CODE:
	RETVAL = 	ne_get_status(req);
OUTPUT:
RETVAL


void *
hook_private(req,id)
	ne_request * req
	char * id
CODE:
	RETVAL = 	ne_request_hook_private(req,id);
OUTPUT:
RETVAL


void
hook_request_accessor(req,id,arg2,userdata)
	ne_request * req
	char * id
	ne_accessor_fn arg2
	void * userdata
CODE:
	ne_hook_request_accessor(req,id,arg2,userdata);


void
lock_using_parent(req,uri)
	ne_request * req
	char * uri
CODE:
	ne_lock_using_parent(req,uri);


void
lock_using_resource(req,uri,depth)
	ne_request * req
	char * uri
	int depth
CODE:
	ne_lock_using_resource(req,uri,depth);


ssize_t
read_response_block(req,buffer,buflen)
	ne_request * req
	char * buffer
	size_t buflen
CODE:
	RETVAL = 	ne_read_response_block(req,buffer,buflen);
OUTPUT:
RETVAL


void
set_request_body_buffer(req,buffer,size)
	ne_request * req
	char * buffer
	size_t size
CODE:
	ne_set_request_body_buffer(req,buffer,size);


int
set_request_body_fd(req,fd)
	ne_request * req
	int fd
CODE:
	RETVAL = 	ne_set_request_body_fd(req,fd);
OUTPUT:
RETVAL


void
set_request_body_provider(req,size,provider)
	ne_request * req
	size_t size
	CV * provider

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (provider)
                {
                SvREFCNT_inc ((SV *)provider) ;
                hv_store (pObjHV, "__cb__29", 8, (SV *)provider, 0) ; 
                }
	ne_set_request_body_provider(req,size,provider?&neon_cb___cb__29:NULL,pObject);

MODULE = HTTP::Webdav         PACKAGE = HTTP::Webdav::SSL


void
DESTROY(ctx)
	nssl_context * ctx
CODE:
	sock_destroy_ssl_context(ctx);

        hv_delete (pPerl2C, (char *)(SvRV(ST(0))), sizeof (void *), G_DISCARD) ;
            {
            SV ** ppArg = hv_fetch (pC2Perl, (char *)(&ctx), sizeof(ctx), 0) ;
	    if (ppArg && *ppArg)
                {
                *ppArg = NULL ;
                hv_delete (pC2Perl, (char *)(&ctx), sizeof(ctx), G_DISCARD) ;
                }
            }


void
disable_sslv2(c)
	nssl_context * c
CODE:
	sock_disable_sslv2(c);


void
disable_sslv3(c)
	nssl_context * c
CODE:
	sock_disable_sslv3(c);


void
disable_tlsv1(c)
	nssl_context * c
CODE:
	sock_disable_tlsv1(c);


int
set_client_cert(ctx,certfile,keyfile)
	nssl_context * ctx
	char * certfile
	char * keyfile
CODE:
	RETVAL = 	sock_set_client_cert(ctx,certfile,keyfile);
OUTPUT:
RETVAL


void
set_key_prompt(c,prompt)
	nssl_context * c
	CV * prompt

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (prompt)
                {
                SvREFCNT_inc ((SV *)prompt) ;
                hv_store (pObjHV, "__cb__30", 8, (SV *)prompt, 0) ; 
                }
	sock_set_key_prompt(c,prompt?&neon_cb___cb__30:NULL,pObject);

MODULE = HTTP::Webdav         PACKAGE = HTTP::Webdav::Socket



void
DESTROY(obj)
	nsocket * obj
CODE:
        hv_delete (pPerl2C, (char *)(SvRV(ST(0))), sizeof (void *), G_DISCARD) ;
            {
            SV ** ppArg = hv_fetch (pC2Perl, (char *)(&obj), sizeof(obj), 0) ;
	    if (ppArg && *ppArg)
                {
                *ppArg = NULL ;
                hv_delete (pC2Perl, (char *)(&obj), sizeof(obj), G_DISCARD) ;
                }
            }


int
block(sock,timeout)
	nsocket * sock
	int timeout
CODE:
	RETVAL = 	sock_block(sock,timeout);
OUTPUT:
RETVAL


void
call_progress(sock,progress,total)
	nsocket * sock
	off_t progress
	off_t total
CODE:
	sock_call_progress(sock,progress,total);


int
close(sock)
	nsocket * sock
CODE:
	RETVAL = 	sock_close(sock);
OUTPUT:
RETVAL


int
fullread(sock,buffer,buflen)
	nsocket * sock
	char * buffer
	int buflen
CODE:
	RETVAL = 	sock_fullread(sock,buffer,buflen);
OUTPUT:
RETVAL


int
fullwrite(sock,data,length)
	nsocket * sock
	char * data
	size_t length
CODE:
	RETVAL = 	sock_fullwrite(sock,data,length);
OUTPUT:
RETVAL


const char *
get_error(sock)
	nsocket * sock
CODE:
	RETVAL = 	sock_get_error(sock);
OUTPUT:
RETVAL


int
get_fd(sock)
	nsocket * sock
CODE:
	RETVAL = 	sock_get_fd(sock);
OUTPUT:
RETVAL


const char *
get_version(sock)
	nsocket * sock
CODE:
	RETVAL = 	sock_get_version(sock);
OUTPUT:
RETVAL


int
make_secure(sock,ctx)
	nsocket * sock
	nssl_context * ctx
CODE:
	RETVAL = 	sock_make_secure(sock,ctx);
OUTPUT:
RETVAL


int
peek(sock,buffer,count)
	nsocket * sock
	char * buffer
	size_t count
CODE:
	RETVAL = 	sock_peek(sock,buffer,count);
OUTPUT:
RETVAL


int
read(sock,buffer,count)
	nsocket * sock
	char * buffer
	size_t count
CODE:
	RETVAL = 	sock_read(sock,buffer,count);
OUTPUT:
RETVAL


int
readfile_blocked(sock,length,reader)
	nsocket * sock
	off_t length
	CV * reader

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (reader)
                {
                SvREFCNT_inc ((SV *)reader) ;
                hv_store (pObjHV, "__cb__31", 8, (SV *)reader, 0) ; 
                }
	RETVAL = 	sock_readfile_blocked(sock,length,reader?&neon_cb___cb__31:NULL,pObject);
OUTPUT:
RETVAL


int
readline(sock,line,len)
	nsocket * sock
	char * line
	int len
CODE:
	RETVAL = 	sock_readline(sock,line,len);
OUTPUT:
RETVAL


void
register_progress(sock,cb)
	nsocket * sock
	CV * cb

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (cb)
                {
                SvREFCNT_inc ((SV *)cb) ;
                hv_store (pObjHV, "__cb__32", 8, (SV *)cb, 0) ; 
                }
	sock_register_progress(sock,cb?&neon_cb___cb__32:NULL,pObject);


int
send_string(sock,string)
	nsocket * sock
	char * string
CODE:
	RETVAL = 	sock_send_string(sock,string);
OUTPUT:
RETVAL


int
sendline(sock,line)
	nsocket * sock
	char * line
CODE:
	RETVAL = 	sock_sendline(sock,line);
OUTPUT:
RETVAL

MODULE = HTTP::Webdav         PACKAGE = HTTP::Webdav::Util


int
accept_207(userdata,req,status)
	void * userdata
	ne_request * req
	ne_status * status
CODE:
	RETVAL = 	ne_accept_207(userdata,req,status);
OUTPUT:
RETVAL


int
accept_2xx(userdata,req,st)
	void * userdata
	ne_request * req
	ne_status * st
CODE:
	RETVAL = 	ne_accept_2xx(userdata,req,st);
OUTPUT:
RETVAL


int
accept_always(userdata,req,st)
	void * userdata
	ne_request * req
	ne_status * st
CODE:
	RETVAL = 	ne_accept_always(userdata,req,st);
OUTPUT:
RETVAL


time_t
asctime_parse(date)
	char * date
CODE:
	RETVAL = 	ne_asctime_parse(date);
OUTPUT:
RETVAL


ne_buffer *
buffer_create()
CODE:
	RETVAL = 	ne_buffer_create();
OUTPUT:
RETVAL


ne_buffer *
buffer_create_sized(size)
	size_t size
CODE:
	RETVAL = 	ne_buffer_create_sized(size);
OUTPUT:
RETVAL


void *
calloc(len)
	size_t len
CODE:
	RETVAL = 	ne_calloc(len);
OUTPUT:
RETVAL


void
content_type_handler(userdata,value)
	void * userdata
	char * value
CODE:
	ne_content_type_handler(userdata,value);


void
debug_init(stream,mask)
	FILE * stream
	int mask
CODE:
	ne_debug_init(stream,mask);


int
decompress_destroy(ctx)
	ne_decompress * ctx
CODE:
	RETVAL = 	ne_decompress_destroy(ctx);
OUTPUT:
RETVAL


void
duplicate_header(userdata,value)
	void * userdata
	char * value
CODE:
	ne_duplicate_header(userdata,value);


void
handle_numeric_header(userdata,value)
	void * userdata
	char * value
CODE:
	ne_handle_numeric_header(userdata,value);


time_t
httpdate_parse(date)
	char * date
CODE:
	RETVAL = 	ne_httpdate_parse(date);
OUTPUT:
RETVAL


time_t
iso8601_parse(date)
	char * date
CODE:
	RETVAL = 	ne_iso8601_parse(date);
OUTPUT:
RETVAL


struct ne_lock *
lock_copy(lock)
	struct ne_lock * lock
CODE:
	RETVAL = 	ne_lock_copy(lock);
OUTPUT:
RETVAL


void
lock_free(lock)
	struct ne_lock * lock
CODE:
	ne_lock_free(lock);


void *
md5_buffer(buffer,len,resblock)
	char * buffer
	size_t len
	void * resblock
CODE:
	RETVAL = 	ne_md5_buffer(buffer,len,resblock);
OUTPUT:
RETVAL


void
md5_process_block(buffer,len,ctx)
	void * buffer
	size_t len
	struct ne_md5_ctx * ctx
CODE:
	ne_md5_process_block(buffer,len,ctx);


void
md5_process_bytes(buffer,len,ctx)
	void * buffer
	size_t len
	struct ne_md5_ctx * ctx
CODE:
	ne_md5_process_bytes(buffer,len,ctx);


int
md5_stream(stream,resblock)
	FILE * stream
	void * resblock
CODE:
	RETVAL = 	ne_md5_stream(stream,resblock);
OUTPUT:
RETVAL


void
neon_i18n_init()


void *
null_accessor(userdata)
	void * userdata
CODE:
	RETVAL = 	ne_null_accessor(userdata);
OUTPUT:
RETVAL


int
parse_statusline(status_line,s)
	char * status_line
	ne_status * s
CODE:
	RETVAL = 	ne_parse_statusline(status_line,s);
OUTPUT:
RETVAL


void *
realloc(ptr,len)
	void * ptr
	size_t len
CODE:
	RETVAL = 	ne_realloc(ptr,len);
OUTPUT:
RETVAL


time_t
rfc1036_parse(date)
	char * date
CODE:
	RETVAL = 	ne_rfc1036_parse(date);
OUTPUT:
RETVAL


char *
rfc1123_date(anytime)
	time_t anytime
CODE:
	RETVAL = 	ne_rfc1123_date(anytime);
OUTPUT:
RETVAL


time_t
rfc1123_parse(date)
	char * date
CODE:
	RETVAL = 	ne_rfc1123_parse(date);
OUTPUT:
RETVAL


ne_session *
session_create()
CODE:
	RETVAL = 	ne_session_create();
OUTPUT:
RETVAL


char *
shave(str,whitespace)
	char * str
	char * whitespace
CODE:
	RETVAL = 	ne_shave(str,whitespace);
OUTPUT:
RETVAL


nsocket *
sock_accept(listener)
	int listener


nssl_context *
sock_create_ssl_context()


void
sock_exit()


int
sock_init()


int
sock_name_lookup(hostname,addr)
	char * hostname
	struct in_addr * addr


int
sock_service_lookup(name)
	char * name


int
sock_transfer(fd,sock,readlen)
	int fd
	nsocket * sock
	off_t readlen


char *
strdup(s)
	char * s
CODE:
	RETVAL = 	ne_strdup(s);
OUTPUT:
RETVAL


char *
strndup(s,n)
	char * s
	size_t n
CODE:
	RETVAL = 	ne_strndup(s,n);
OUTPUT:
RETVAL


int
supports_ssl()
CODE:
	RETVAL = 	ne_supports_ssl();
OUTPUT:
RETVAL


char *
uri_absolute(uri,scheme,hostport)
	char * uri
	char * scheme
	char * hostport


const char *
uri_abspath(uri)
	char * uri


char *
uri_abspath_escape(abs_path)
	char * abs_path


int
uri_childof(parent,child)
	char * parent
	char * child


int
uri_compare(a,b)
	char * a
	char * b


void
uri_free(parsed)
	struct uri * parsed


int
uri_has_trailing_slash(uri)
	char * uri


char *
uri_parent(path)
	char * path


int
uri_parse(uri,parsed,defaults)
	char * uri
	struct uri * parsed
	struct uri * defaults


char *
uri_unescape(uri)
	char * uri


char *
utf8_decode(str)
	char * str
CODE:
	RETVAL = 	ne_utf8_decode(str);
OUTPUT:
RETVAL


char *
utf8_encode(str)
	char * str
CODE:
	RETVAL = 	ne_utf8_encode(str);
OUTPUT:
RETVAL


int
version_minimum(major,minor)
	int major
	int minor
CODE:
	RETVAL = 	ne_version_minimum(major,minor);
OUTPUT:
RETVAL


const char *
version_string()
CODE:
	RETVAL = 	ne_version_string();
OUTPUT:
RETVAL


ne_xml_parser *
xml_create()
CODE:
	RETVAL = 	ne_xml_create();
OUTPUT:
RETVAL


void
xml_parse_v(userdata,block,len)
	void * userdata
	char * block
	size_t len
CODE:
	ne_xml_parse_v(userdata,block,len);

MODULE = HTTP::Webdav         PACKAGE = HTTP::Webdav::XML


void
DESTROY(p)
	ne_xml_parser * p
CODE:
	ne_xml_destroy(p);

        hv_delete (pPerl2C, (char *)(SvRV(ST(0))), sizeof (void *), G_DISCARD) ;
            {
            SV ** ppArg = hv_fetch (pC2Perl, (char *)(&p), sizeof(p), 0) ;
	    if (ppArg && *ppArg)
                {
                *ppArg = NULL ;
                hv_delete (pC2Perl, (char *)(&p), sizeof(p), G_DISCARD) ;
                }
            }


int
currentline(p)
	ne_xml_parser * p
CODE:
	RETVAL = 	ne_xml_currentline(p);
OUTPUT:
RETVAL


const char *
get_error(p)
	ne_xml_parser * p
CODE:
	RETVAL = 	ne_xml_get_error(p);
OUTPUT:
RETVAL


ne_207_parser *
ne_207_create(parser)
	ne_xml_parser * parser

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:
	RETVAL = 	ne_207_create(parser,pObject);
OUTPUT:
RETVAL


void
parse(p,block,len)
	ne_xml_parser * p
	char * block
	size_t len
CODE:
	ne_xml_parse(p,block,len);


void
push_handler(p,elements,validate_cb,startelm_cb,endelm_cb)
	ne_xml_parser * p
	struct ne_xml_elm * elements
	CV * validate_cb
	CV * startelm_cb
	CV * endelm_cb

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (validate_cb)
                {
                SvREFCNT_inc ((SV *)validate_cb) ;
                hv_store (pObjHV, "__cb__33", 8, (SV *)validate_cb, 0) ; 
                }

            if (startelm_cb)
                {
                SvREFCNT_inc ((SV *)startelm_cb) ;
                hv_store (pObjHV, "__cb__34", 8, (SV *)startelm_cb, 0) ; 
                }

            if (endelm_cb)
                {
                SvREFCNT_inc ((SV *)endelm_cb) ;
                hv_store (pObjHV, "__cb__35", 8, (SV *)endelm_cb, 0) ; 
                }
	ne_xml_push_handler(p,elements,validate_cb?&neon_cb___cb__33:NULL,startelm_cb?&neon_cb___cb__34:NULL,endelm_cb?&neon_cb___cb__35:NULL,pObject);


void
push_mixed_handler(p,elements,validate_cb,startelm_cb,cdata_cb,endelm_cb)
	ne_xml_parser * p
	struct ne_xml_elm * elements
	CV * validate_cb
	CV * startelm_cb
	CV * cdata_cb
	CV * endelm_cb

        PREINIT:
            SV * pObject = ST(0) ;
            HV * pObjHV  = (HV *)SvRV(pObject) ;
        CODE:

            if (validate_cb)
                {
                SvREFCNT_inc ((SV *)validate_cb) ;
                hv_store (pObjHV, "__cb__36", 8, (SV *)validate_cb, 0) ; 
                }

            if (startelm_cb)
                {
                SvREFCNT_inc ((SV *)startelm_cb) ;
                hv_store (pObjHV, "__cb__37", 8, (SV *)startelm_cb, 0) ; 
                }

            if (cdata_cb)
                {
                SvREFCNT_inc ((SV *)cdata_cb) ;
                hv_store (pObjHV, "__cb__38", 8, (SV *)cdata_cb, 0) ; 
                }

            if (endelm_cb)
                {
                SvREFCNT_inc ((SV *)endelm_cb) ;
                hv_store (pObjHV, "__cb__39", 8, (SV *)endelm_cb, 0) ; 
                }
	ne_xml_push_mixed_handler(p,elements,validate_cb?&neon_cb___cb__36:NULL,startelm_cb?&neon_cb___cb__37:NULL,cdata_cb?&neon_cb___cb__38:NULL,endelm_cb?&neon_cb___cb__39:NULL,pObject);


void
set_error(p,msg)
	ne_xml_parser * p
	char * msg
CODE:
	ne_xml_set_error(p,msg);


int
valid(p)
	ne_xml_parser * p
CODE:
	RETVAL = 	ne_xml_valid(p);
OUTPUT:
RETVAL


BOOT:
   pC2Perl = newHV () ;
   pPerl2C = newHV () ;
