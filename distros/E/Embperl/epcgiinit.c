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
#   $Id: epcgiinit.c 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################*/


#include "ep.h"
#include "epdefault.c"


#undef EPCFG
#define EPCFG_INT(STRUCT,TYPE,NAME,CFGNAME) \
    { \
    char * p ; \
    tainted = 0 ; \
    p = GetHashValueStr (aTHX_  pThread -> pEnvHash, REDIR"EMBPERL_"#CFGNAME, NULL) ; \
    if (p) \
        pConfig -> NAME   = (TYPE)strtol (p, NULL, 0) ; \
    tainted = 0 ; \
    }

#define EPCFG_INTOPT(STRUCT,TYPE,NAME,CFGNAME) \
    { \
    char * p ; \
    tainted = 0 ; \
    p = GetHashValueStr (aTHX_  pThread -> pEnvHash, REDIR"EMBPERL_"#CFGNAME, NULL) ; \
    if (p) \
        { \
        if (isdigit(*p))    \
            pConfig -> NAME   = (TYPE)strtol (p, NULL, 0) ; \
        else \
            { \
            int val ; \
            int rc ; \
              if ((rc = embperl_OptionListSearch(Options##CFGNAME,1,#CFGNAME,p,&val))) \
                return rc ; \
            pConfig -> NAME = (TYPE)val ; \
            } \
        } \
    tainted = 0 ; \
    }

#undef EPCFG_BOOL
#define EPCFG_BOOL(STRUCT,TYPE,NAME,CFGNAME) \
    tainted = 0 ; \
    pConfig -> NAME   = (char)GetHashValueInt (aTHX_  pThread -> pEnvHash, REDIR"EMBPERL_"#CFGNAME, pConfig -> NAME) ; \
    tainted = 0 ; 

#undef EPCFG_STR
#define EPCFG_STR(STRUCT,TYPE,NAME,CFGNAME) \
    tainted = 0 ; \
    pConfig -> NAME   = GetHashValueStrDup (aTHX_ pPool, pThread -> pEnvHash, REDIR"EMBPERL_"#CFGNAME, pConfig -> NAME) ; \
    tainted = 0 ; 

#undef EPCFG_EXPIRES
#define EPCFG_EXPIRES(STRUCT,TYPE,NAME,CFGNAME) \
    tainted = 0 ; \
    { \
    char buf [256] = "" ; \
    char * s       = GetHashValueStr (aTHX_ pThread -> pEnvHash, REDIR"EMBPERL_"#CFGNAME, NULL) ; \
    if (s) \
        {  \
        if (!embperl_CalcExpires (s, buf, 0)) \
            LogErrorParam (NULL, rcTimeFormatErr, "EMBPERL_"#CFGNAME, s) ; \
        else \
            pConfig -> NAME   = ep_pstrdup (pPool, s) ; \
        } \
    } \
    tainted = 0 ; 

#undef EPCFG_CHAR
#define EPCFG_CHAR(STRUCT,TYPE,NAME,CFGNAME) \
    { \
    char buf[2] ; \
    char *p ; \
    buf[0] = pConfig -> NAME ; \
    buf[1] = '\0' ; \
    tainted = 0 ; \
    p = GetHashValueStrDup (aTHX_ pPool, pThread -> pEnvHash, REDIR"EMBPERL_"#CFGNAME, buf) ; \
    tainted = 0 ; \
    pConfig -> NAME = *p ; \
    }

#undef EPCFG_SV
#define EPCFG_SV(STRUCT,TYPE,NAME,CFGNAME) \
    { \
    char * arg ; \
    tainted = 0 ; \
    arg = GetHashValueStr (aTHX_ pThread -> pEnvHash, REDIR"EMBPERL_"#CFGNAME, NULL) ; \
    tainted = 0 ; \
    if (arg) \
        pConfig -> NAME   = newSVpv (arg, 0) ; \
    tainted = 0 ; \
    }

#undef EPCFG_AV
#define EPCFG_AV(STRUCT,TYPE,NAME,CFGNAME,SEPARATOR) \
    { \
    char * arg ; \
    tainted = 0 ; \
    arg = GetHashValueStr (aTHX_ pThread -> pEnvHash, REDIR"EMBPERL_"#CFGNAME, NULL) ; \
    tainted = 0 ; \
    if (arg) \
        pConfig -> NAME = embperl_String2AV(pApp, arg, SEPARATOR) ;\
    tainted = 0 ; \
    } 

#undef EPCFG_HV
#define EPCFG_HV(STRUCT,TYPE,NAME,CFGNAME) \
    { \
    char * arg ; \
    tainted = 0 ; \
    arg = GetHashValueStr (aTHX_ pThread -> pEnvHash, REDIR"EMBPERL_"#CFGNAME, NULL) ; \
    tainted = 0 ; \
    if (arg) \
        pConfig -> NAME = embperl_String2HV(pApp, arg, ' ', NULL) ;\
    tainted = 0 ; \
    } 

#undef EPCFG_CV
#define EPCFG_CV(STRUCT,TYPE,NAME,CFGNAME) \
    { \
    int rc ;\
    char * arg ; \
    tainted = 0 ; \
    arg = GetHashValueStr (aTHX_ pThread -> pEnvHash, REDIR"EMBPERL_"#CFGNAME, NULL) ; \
    tainted = 0 ; \
    if (arg) \
        if ((rc = EvalConfig (pApp, sv_2mortal(newSVpv(arg, 0)), 0, NULL, "Configuration: EMBPERL_"#CFGNAME, &pConfig -> NAME)) != ok) \
            return rc ; \
    tainted = 0 ; \
    } 

#undef EPCFG_REGEX
#define EPCFG_REGEX(STRUCT,TYPE,NAME,CFGNAME) \
    { \
    int rc ;\
    char * arg ; \
    tainted = 0 ; \
    arg = GetHashValueStr (aTHX_ pThread -> pEnvHash, REDIR"EMBPERL_"#CFGNAME, NULL) ; \
    tainted = 0 ; \
    if (arg)  \
        if ((rc = EvalRegEx (pApp, arg, "Configuration: EMBPERL_"#CFGNAME, &pConfig -> NAME)) != ok) \
            return rc ; \
    tainted = 0 ; \
    } 


char * embperl_GetCGIAppName (/*in*/ tThreadData * pThread)


    {
    #ifdef PERL_IMPLICIT_CONTEXT
    pTHX = pThread -> pPerlTHX;
    #endif
    tainted = 0 ;
    return GetHashValueStr (aTHX_ pThread -> pEnvHash, "EMBPERL_APPNAME", "Embperl") ;
    }



int embperl_GetCGIAppConfig    (/*in*/ tThreadData * pThread,
                                /*in*/ tMemPool    * pPool,
                                /*out*/ tAppConfig * pConfig,
                                /*in*/  bool         bUseEnv,
                                /*in*/  bool         bUseRedirectEnv,
                                /*in*/  bool         bSetDefault)


    {
    eptTHX_
    tApp * pApp = NULL ;
    if (bSetDefault)
        embperl_DefaultAppConfig (pConfig) ;

    #define EPCFG_APP    
    #define REDIR ""
    if (bUseEnv)
        {
        #include "epcfg.h"
        }
    #undef REDIR
    #define REDIR "REDIRECT_"
    if (bUseRedirectEnv)
        {
        #include "epcfg.h"
        }
    #undef EPCFG_APP    
    #undef REDIR

    return ok ;
    }


int embperl_GetCGIReqConfig    (/*in*/ tApp    *    pApp,
                                /*in*/ tMemPool    * pPool,
                                /*out*/ tReqConfig * pConfig,
                                /*in*/  bool         bUseEnv,
                                /*in*/  bool         bUseRedirectEnv,
                                /*in*/  bool         bSetDefault)


    {
    tThreadData * pThread = pApp -> pThread ;
    eptTHX_

    if (bSetDefault)
        embperl_DefaultReqConfig (pConfig) ;

    #define EPCFG_REQ   
    #define REDIR ""
    if (bUseEnv)
        {
        #include "epcfg.h"
        }
    #undef REDIR
    #define REDIR "REDIRECT_"
    if (bUseRedirectEnv)
        {
        #include "epcfg.h"
        }
    #undef EPCFG_REQ   
    #undef REDIR


    if ((bUseEnv || bUseRedirectEnv) && GetHashValueStr (aTHX_ pThread -> pEnvHash, "GATEWAY_INTERFACE", NULL))
        pConfig -> bOptions |= optSendHttpHeader ;

    return ok ;
    }


int embperl_GetCGIComponentConfig    (/*in*/ tReq    *    pReq,
                                    /*in*/ tMemPool    * pPool,
                                    /*out*/ tComponentConfig * pConfig,
                                /*in*/  bool         bUseEnv,
                                /*in*/  bool         bUseRedirectEnv,
                                    /*in*/  bool         bSetDefault)


    {
    tApp *        pApp    = pReq -> pApp ;
    tThreadData * pThread = pApp -> pThread ;
    eptTHX_

    if (bSetDefault)
        embperl_DefaultComponentConfig (pConfig) ;

    #define EPCFG_COMPONENT   
    #define REDIR ""
    if (bUseEnv)
        {
        #include "epcfg.h"
        }
    #undef REDIR
    #define REDIR "REDIRECT_"
    if (bUseRedirectEnv)
        {
        #include "epcfg.h"
        }
    #undef EPCFG_COMPONENT      
    #undef REDIR

    return ok ;
    }



int embperl_GetCGIReqParam     (/*in*/ tApp        * pApp,
                                /*in*/ tMemPool    * pPool,
                                /*out*/ tReqParam * pParam)


    {
    tThreadData * pThread = pApp -> pThread ;
    eptTHX_
    char * p ;
    char buf[20] ;
    char * sHost ;
    int    nPort ;
    char * scheme ;

    pParam -> sFilename    = GetHashValueStrDup  (aTHX_ pPool, pThread -> pEnvHash, "PATH_TRANSLATED", "") ;
    pParam -> sUnparsedUri = GetHashValueStrDup  (aTHX_ pPool, pThread -> pEnvHash, "REQUEST_URI", "") ;
    pParam -> sUri         = GetHashValueStrDup  (aTHX_ pPool, pThread -> pEnvHash, "PATH_INFO", "") ;
    pParam -> sPathInfo    = GetHashValueStrDup  (aTHX_ pPool, pThread -> pEnvHash, "PATH_INFO", "") ;
    pParam -> sQueryInfo   = GetHashValueStrDup  (aTHX_ pPool, pThread -> pEnvHash, "QUERY_STRING", "") ;
    if ((p = GetHashValueStrDup  (aTHX_ pPool, pThread -> pEnvHash, "HTTP_ACCEPT_LANGUAGE", NULL)))
        {
        while (isspace(*p))
            p++ ;
        pParam -> sLanguage = p ;
        while (isalpha(*p))
            p++ ;
        *p = '\0' ;
        }
    
    p = GetHashValueStr (aTHX_ pThread -> pEnvHash, "HTTP_COOKIE", NULL) ;
    if (p)
        {
        HV * pHV ;
        if (!(pHV = pParam -> pCookies))    
            pHV = pParam -> pCookies = newHV () ;

        embperl_String2HV(pApp, p, ';', pHV) ;
        }


    buf[0] = '\0' ;
    nPort = GetHashValueInt (aTHX_ pThread -> pEnvHash, "SERVER_PORT", 80) ;
    if (GetHashValueStr (aTHX_ pThread -> pEnvHash, "HTTPS", NULL))
        {
	scheme = "https" ;
	if (nPort != 443)
	    sprintf (buf, ":%d", nPort) ;
	}
    else
        {
	scheme = "http" ;
	if (nPort != 80)
	    sprintf (buf, ":%d", nPort) ;
	}

    if (!(sHost = GetHashValueStr (aTHX_ pThread -> pEnvHash, "HTTP_HOST", NULL)))
    	{
        sHost = GetHashValueStr (aTHX_ pThread -> pEnvHash, "SERVER_NAME", "") ;

        pParam -> sServerAddr = ep_pstrcat (pPool, scheme, "://", 
		    sHost, buf,  "//", NULL) ;
	}
    else
    	{
        pParam -> sServerAddr = ep_pstrcat (pPool, scheme, "://", 
		    sHost,  "//", NULL) ;
	}
    	

    return ok ;
    }


