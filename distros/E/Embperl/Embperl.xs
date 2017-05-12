/*###################################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2014 Gerald Richter
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#   For use with Apache httpd and mod_perl, see also Apache copyright.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
###################################################################################*/

#include "ep.h"
#include "xs/ep_xs_typedefs.h"
#include "xs/ep_xs_sv_convert.h"


/* for embperl_exit */
static I32 errgv_empty_set(pTHX_ IV ix, SV * sv)
{ 
    sv_setsv(sv, &sv_undef);
    return TRUE;
}




MODULE = Embperl    PACKAGE = Embperl   PREFIX = embperl_

int
embperl_Init(pApacheSrvSV=NULL, pPerlParam=NULL)
    SV * pApacheSrvSV
    SV * pPerlParam
CODE:
    RETVAL = embperl_Init (aTHX_ pApacheSrvSV, pPerlParam, NULL) ;
OUTPUT:
    RETVAL


#ifdef APACHEXXX

void 
embperl_ApacheAddModule ()

#endif

#ifdef DMALLOC

unsigned long
embperl_dmalloc_mark()
CODE:
    RETVAL = dmalloc_mark () ; 
OUTPUT:
    RETVAL


void
embperl_dmalloc_check(nMemCheckpoint,txt)
    unsigned long nMemCheckpoint
    char * txt
CODE:
    if (nMemCheckpoint)
        {
        if (txt && *txt)
            dmalloc_message (txt) ;
        dmalloc_log_changed (nMemCheckpoint, 1, 0, 1) ;
        }

#endif    

int
embperl_InitAppForRequest(pApacheReqSV, pPerlParam)
    SV * pApacheReqSV
    SV * pPerlParam
PREINIT:
    Embperl__App pApp;
    Embperl__Thread pThread;
    tApacheDirConfig * pApacheCfg = NULL ;
PPCODE:
    RETVAL = embperl_InitAppForRequest(aTHX_ pApacheReqSV, pPerlParam, &pThread, &pApp, &pApacheCfg);
    XSprePUSH ;
    EXTEND(SP, 2) ;
    PUSHs(epxs_IV_2obj(RETVAL)) ;
    PUSHs(epxs_Embperl__Thread_2obj(pThread)) ;
    PUSHs(epxs_Embperl__App_2obj(pApp)) ;



char *
embperl_get_date_time()
PREINIT:
    char buf[256] ;
CODE:
    RETVAL = embperl_GetDateTime(buf) ;
OUTPUT:
    RETVAL

    

MODULE = Embperl::Req    PACKAGE = Embperl::Req   PREFIX = embperl_

int
embperl_InitRequest(pApacheReqSV, pPerlParam)
    SV * pApacheReqSV
    SV * pPerlParam
PREINIT:
    Embperl__Req ppReq;
PPCODE:
    RETVAL = embperl_InitRequest(aTHX_ pApacheReqSV, pPerlParam, &ppReq);
    XSprePUSH ;
    EXTEND(SP, 2) ;
    PUSHs(epxs_IV_2obj(RETVAL)) ;
    PUSHs(epxs_Embperl__Req_2obj(ppReq)) ;

int
embperl_InitRequestComponent(pApacheReqSV, pPerlParam)
    SV * pApacheReqSV
    SV * pPerlParam
PREINIT:
    Embperl__Req ppReq;
PPCODE:
    RETVAL = embperl_InitRequestComponent(aTHX_ pApacheReqSV, pPerlParam, &ppReq);
    XSprePUSH ;
    EXTEND(SP, 2) ;
    PUSHs(epxs_IV_2obj(RETVAL)) ;
    PUSHs(epxs_Embperl__Req_2obj(ppReq)) ;


int
embperl_ExecuteRequest(pApacheReqSV=NULL, pPerlParam=NULL)
    SV * pApacheReqSV
    SV * pPerlParam
CODE:
    RETVAL = embperl_ExecuteRequest (aTHX_ pApacheReqSV, pPerlParam) ;
    tainted = 0 ;
OUTPUT:
    RETVAL


int
embperl_send_http_header(pReq)
    tReq * pReq;
CODE:
    RETVAL = embperl_SendHttpHeader (pReq) ;
OUTPUT:
    RETVAL




INCLUDE: Old.xs


MODULE = Embperl    PACKAGE = Embperl   PREFIX = embperl_

void
embperl_Boot(version)
    SV * version
CODE:
    PUSHMARK(sp);  
    XPUSHs(sv_2mortal(newSVpv("Embperl::Thread", 0))) ;   
    XPUSHs(version) ;   
    PUTBACK;
    boot_Embperl__Thread (aTHX_ cv) ;

    PUSHMARK(sp);  
    XPUSHs(sv_2mortal(newSVpv("Embperl::App", 0))) ;   
    XPUSHs(version) ;   
    PUTBACK;
    boot_Embperl__App (aTHX_ cv) ;

    PUSHMARK(sp);  
    XPUSHs(sv_2mortal(newSVpv("Embperl::App::Config", 0))) ;   
    XPUSHs(version) ;   
    PUTBACK;
    boot_Embperl__App__Config (aTHX_ cv) ;

    PUSHMARK(sp);  
    XPUSHs(sv_2mortal(newSVpv("Embperl::Req", 0))) ;   
    XPUSHs(version) ;   
    PUTBACK;
    boot_Embperl__Req (aTHX_ cv) ;

    PUSHMARK(sp);  
    XPUSHs(sv_2mortal(newSVpv("Embperl::Req::Config", 0))) ;   
    XPUSHs(version) ;   
    PUTBACK;
    boot_Embperl__Req__Config (aTHX_ cv) ;

    PUSHMARK(sp);  
    XPUSHs(sv_2mortal(newSVpv("Embperl::Req::Param", 0))) ;   
    XPUSHs(version) ;   
    PUTBACK;
    boot_Embperl__Req__Param (aTHX_ cv) ;

    PUSHMARK(sp);  
    XPUSHs(sv_2mortal(newSVpv("Embperl::Component", 0))) ;   
    XPUSHs(version) ;   
    PUTBACK;
    boot_Embperl__Component (aTHX_ cv) ;

    PUSHMARK(sp);  
    XPUSHs(sv_2mortal(newSVpv("Embperl::Component::Config", 0))) ;   
    XPUSHs(version) ;   
    PUTBACK;
    boot_Embperl__Component__Config (aTHX_ cv) ;

    PUSHMARK(sp);  
    XPUSHs(sv_2mortal(newSVpv("Embperl::Component::Param", 0))) ;   
    XPUSHs(version) ;   
    PUTBACK;
    boot_Embperl__Component__Param (aTHX_ cv) ;

    PUSHMARK(sp);  
    XPUSHs(sv_2mortal(newSVpv("Embperl::Component::Output", 0))) ;   
    XPUSHs(version) ;   
    PUTBACK;
    boot_Embperl__Component__Output (aTHX_ cv) ;

    PUSHMARK(sp);  
    XPUSHs(sv_2mortal(newSVpv("Embperl::Syntax", 0))) ;   
    XPUSHs(version) ;   
    PUTBACK;
    boot_Embperl__Syntax (aTHX_ cv) ;



