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
#   $Id: mod_embperl.c 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################*/


#include "ep.h"


#ifdef APACHE

#include <http_core.h>
#include "epdefault.c"

#if !defined(MOD_EMBPERL) && !defined(EMBPERL_SO)
#define MOD_EMBPERL
#define EMBPERL_SO
#endif


/* use getenv from runtime library and not from Perl */
#undef getenv
#undef getpid

/* define get thread id if not already done by Apache */
#ifndef gettid
#ifdef WIN32
#define gettid GetCurrentThreadId
#else
static int gettid()
    {
    return 0 ;
    }
#endif
#endif

#ifndef APACHE2
/* from mod_perl 1.x */
apr_pool_t * perl_get_startup_pool (void)
{
    SV *sv ;
    dTHX ;
    sv = perl_get_sv("Apache::__POOL", FALSE);
    if(sv) {
        IV tmp = SvIV((SV*)SvRV(sv));
        return (pool *)tmp;
    }
    return NULL;
}
#endif


/* debugging by default off, enable with httpd -D EMBPERL_APDEBUG */
static int bApDebug = 0 ;
static int bApInit  = 0 ;

/* subpool to get notified on unload */
static apr_pool_t * unload_subpool ;



/* --- declare config datastructure --- */

#define EPCFG_STR EPCFG
#define EPCFG_INT EPCFG
#define EPCFG_INTOPT EPCFG
#define EPCFG_BOOL EPCFG
#define EPCFG_CHAR EPCFG
#define EPCFG_EXPIRES EPCFG_STR

#define EPCFG_CV EPCFG_SAVE
#define EPCFG_SV EPCFG_SAVE
#define EPCFG_HV EPCFG_SAVE
#define EPCFG_REGEX EPCFG_SAVE
#define EPCFG_AV(STRUCT,TYPE,NAME,CFGNAME,SEPARATOR) EPCFG_SAVE(STRUCT,TYPE,NAME,CFGNAME)

#define EPCFG_APP    
#define EPCFG_REQ   
#define EPCFG_COMPONENT   


#define EPCFG(STRUCT,TYPE,NAME,CFGNAME)   int  set_##STRUCT##NAME:1 ;
#define EPCFG_SAVE(STRUCT,TYPE,NAME,CFGNAME)  \
     int  set_##STRUCT##NAME:1 ; \
     char *  save_##STRUCT##NAME ; 

struct tApacheDirConfig
    {
    tPerlInterpreter * pPerlTHX ;                  /* pointer to Perl interpreter */
    tAppConfig       AppConfig ;
    tReqConfig       ReqConfig ;
    tComponentConfig ComponentConfig ;
    int              bUseEnv ;
    /* flags if config directive is given in context */
#include "epcfg.h"
    }  ;



#ifdef MOD_EMBPERL


/* --- declare other function prototypes --- */

#ifdef APACHE2
static int embperl_ApacheInit (apr_pool_t *p, apr_pool_t *plog, apr_pool_t *ptemp, server_rec *s) ;
static int embperl_ApachePostConfig (apr_pool_t *p, apr_pool_t *plog, apr_pool_t *ptemp, server_rec *s) ;
static apr_status_t embperl_ApacheInitCleanup (void * p) ;
#else
static void embperl_ApacheInitCleanup (void * p) ;
static void embperl_ApacheInit (server_rec *s, apr_pool_t *p) ;
#endif


static const char * embperl_Apache_Config_useenv (cmd_parms *cmd, /*tApacheDirConfig*/ void * pDirCfg, int arg) ;
static void *embperl_create_dir_config(apr_pool_t *p, char *d) ;
static void *embperl_create_server_config(apr_pool_t *p, server_rec *s) ;
static void *embperl_merge_dir_config (apr_pool_t *p, void *basev, void *addv) ;



/* --- declare config function prototypes --- */

#undef EPCFG_SAVE
#define EPCFG_SAVE EPCFG
#undef EPCFG 
#define EPCFG(STRUCT,TYPE,NAME,CFGNAME) \
    const char * embperl_Apache_Config_##STRUCT##NAME (cmd_parms *cmd, /*tApacheDirConfig*/ void * pDirCfg, const char *  arg) ;

#include "epcfg.h"

#ifndef AP_INIT_TAKE1
#define AP_INIT_TAKE1(name,func,foo,valid,comment) { name,func,foo,valid, TAKE1, comment }
#endif
#ifndef AP_INIT_FLAG
#define AP_INIT_FLAG(name,func,foo,valid,comment) { name,func,foo,valid, FLAG, comment }
#endif

#undef EPCFG
#undef EPCFG_SAVE
#define EPCFG_SAVE EPCFG
#define EPCFG(STRUCT,TYPE,NAME,CFGNAME) \
    AP_INIT_TAKE1( "EMBPERL_"#CFGNAME,   embperl_Apache_Config_##STRUCT##NAME,   NULL, RSRC_CONF | OR_OPTIONS,  "" ),


static const command_rec embperl_cmds[] =
{
#include "epcfg.h"
    
    AP_INIT_FLAG("EMBPERL_USEENV", embperl_Apache_Config_useenv, NULL, RSRC_CONF, "If set to 'on' Embperl will also scan the environment variable for configuration information"),
    {NULL}
};



/* --- apache callback datastructures --- */

#ifdef APACHE2

static void embperl_register_hooks (apr_pool_t * p)
    {
    ap_hook_open_logs(embperl_ApacheInit, NULL, NULL, APR_HOOK_LAST) ; /* make sure we run after modperl init */
    ap_hook_post_config(embperl_ApachePostConfig, NULL, NULL, APR_HOOK_FIRST) ; 
    }


module AP_MODULE_DECLARE_DATA embperl_module =
    {
    STANDARD20_MODULE_STUFF,
    embperl_create_dir_config,  /* dir config creater */
    embperl_merge_dir_config,   /* dir merger --- default is to override */
    embperl_create_server_config, /* server config */
    embperl_merge_dir_config,   /* merge server configs */
    embperl_cmds,               /* command table */
    embperl_register_hooks      /* register hooks */
    };



#else

/* static module MODULE_VAR_EXPORT embperl_module = { */
static module embperl_module = {
    STANDARD_MODULE_STUFF,
    embperl_ApacheInit,         /* initializer */
    embperl_create_dir_config,  /* dir config creater */
    embperl_merge_dir_config,   /* dir merger --- default is to override */
    embperl_create_server_config, /* server config */
    embperl_merge_dir_config,   /* merge server configs */
    embperl_cmds,               /* command table */
    NULL,                       /* handlers */
    NULL,                       /* filename translation */
    NULL,                       /* check_user_id */
    NULL,                       /* check auth */
    NULL,                       /* check access */
    NULL,                       /* type_checker */
    NULL,			/* fixups */
    NULL,                       /* logger */
    NULL,                       /* header parser */
    NULL,                       /* child_init */
    NULL,                       /* child_exit */
    NULL                        /* post read-request */
};


#endif

/*---------------------------------------------------------------------------
* embperl_ApInitDone
*/

int embperl_ApInitDone (void)
    {
    return 0 ; /* bInitDone ; */
    }

/*---------------------------------------------------------------------------
* embperl_ApacheInitUnload
*/
/*!
*
* \_en									   
* Apache 1: Register subpool to get notified on unload
* Apache 2: nothing
* \endif                                                                       
*
* \_de									   
* Apache 1: Subppol registrieren um einen Unload mitzubekommen
* Apache 2: nichts
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



static int embperl_ApacheInitUnload (apr_pool_t *p)

    {
#ifdef APACHE2
     if (!unload_subpool && p)
         {    
         apr_pool_create_ex(&unload_subpool, p, NULL, NULL); 
         apr_pool_cleanup_register(unload_subpool, NULL, embperl_ApacheInitCleanup, embperl_ApacheInitCleanup); 
         if (bApDebug)
             ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: ApacheInitUnload [%d/%d]\n", getpid(), gettid()) ;
         }
#else
    if (!unload_subpool && p)
        {            
        unload_subpool = ap_make_sub_pool(p);
        ap_register_cleanup(unload_subpool, NULL, embperl_ApacheInitCleanup, embperl_ApacheInitCleanup);
        if (bApDebug)
            ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: ApacheInitUnload [%d/%d]\n", getpid(), gettid()) ;
        }
#endif

    return ok ;
    }



/*---------------------------------------------------------------------------
* embperl_ApacheAddModule
*/
/*!
*
* \_en									   
* Apache 1: Add module to dynamily loaded modules
* Apache 2: Just print a debug message. (mod_embperl.so must have been already loaded)
* \endif                                                                       
*
* \_de									   
* Apache 1: Module zu dynamisch geladenen Modulen hinzufügen
* Apache 2: Nur eine Debugmessage ausgeben. (mod_embperl.so muß bereits geladen sein)
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

void embperl_ApacheAddModule (void)

    {
    bApDebug |= ap_exists_config_define("EMBPERL_APDEBUG") ;
   
#ifdef APACHE2
    if (bApDebug)
        ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: Perl part initialization start [%d/%d]\n", getpid(), gettid()) ;
    return ;
#else 


    if (!ap_find_linked_module("mod_embperl.c"))
        {
        apr_pool_t * pool ;

        if (bApDebug)
            ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: About to add mod_embperl.c as dynamic module [%d/%d]\n", getpid(), gettid()) ;
        
        ap_add_module (&embperl_module) ;

        pool = perl_get_startup_pool () ;
        embperl_ApacheInitUnload (pool) ;
        }
    else
        if (bApDebug)
            ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: mod_embperl.c already added as dynamic module [%d/%d]\n", getpid(), gettid()) ;
#endif
    }



/*---------------------------------------------------------------------------
* embperl_ApacheInit
*/
/*!
*
* \_en									   
* Apache 1: Call initialization of Embperl, after configuration is read in
* Apache 2: Just add version component. (Initilalization is call from Perl)
* \endif                                                                       
*
* \_de									   
* Apache 1: Initzialisierung von Embperl ausführen, nachdem Konfiguration eingelesen ist
* Apache 2: Nur Versionsnummer dem Apache hinzufügen. (Initialisierung von von Perl aus aufgerufen)
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



#ifdef APACHE2
static int embperl_ApacheInit (apr_pool_t *p, apr_pool_t *plog, apr_pool_t *ptemp, server_rec *s)
#else
static void embperl_ApacheInit (server_rec *s, apr_pool_t *p)
#endif

    {
#ifndef APACHE2
    int     rc;
#endif
    dTHX ;

#ifndef APACHE2
    embperl_ApacheInitUnload (p) ;
#endif

    bApDebug |= ap_exists_config_define("EMBPERL_APDEBUG") ;
    
    if (bApDebug)
        ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: ApacheInit [%d/%d]\n", getpid(), gettid()) ;

#ifdef APACHE2
    bApInit = 1 ;
    return APR_SUCCESS ;
#else
    ap_add_version_component ("Embperl/"VERSION) ;

    if ((rc = embperl_Init (aTHX_ NULL, NULL, s)) != ok)
        {
        ap_log_error (APLOG_MARK, APLOG_ERR | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "Initialization of Embperl failed (#%d)\n", rc) ;
        }
    bApInit = 1 ;

#endif
    }




#ifdef APACHE2
static int embperl_ApachePostConfig (apr_pool_t *p, apr_pool_t *plog, apr_pool_t *ptemp, server_rec *s)

    {
    ap_add_version_component (p, "Embperl/"VERSION) ;
    return APR_SUCCESS ;
    }
#endif

/*---------------------------------------------------------------------------
* embperl_ApacheInitCleanup
*/
/*!
*
* \_en									   
* Apache 1: Make sure Embperl is unloaded before mod_perl is unloaded
* Apache 2: not used
* \endif                                                                       
*
* \_de									   
* Apache 1: Sicherstellen, das Embperl vor mod_perl aus dem Speicher entladen wird
* Apache 2: Nich benutzt
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



#ifdef APACHE2
static apr_status_t embperl_ApacheInitCleanup (void * p)
#else
static void embperl_ApacheInitCleanup (void * p)
#endif

    {
#ifdef APACHE2
    if (bApDebug)
        ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: embperl_ApacheInitCleanup [%d/%d]\n", getpid(), gettid()) ;
    return OK ;
#else
    module * m ;
    /* make sure embperl module is removed before mod_perl in case mod_perl is loaded dynamicly*/
    if ((m = ap_find_linked_module("mod_perl.c")))
        {
        if (m -> dynamic_load_handle)
            {
            if (bApDebug)
                ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: ApacheInitCleanup: mod_perl.c dynamicly loaded -> remove mod_embperl.c [%d/%d]\n", getpid(), gettid()) ;
            /*embperl_EndPass1 () ;*/
            ap_remove_module (&embperl_module) ; 
            }
        else
            {
            if (bApDebug)
                ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: ApacheInitCleanup: mod_perl.c not dynamic loaded [%d/%d]\n", getpid(), gettid()) ;
            embperl_EndPass1 () ;
            }
        }
    else
        {
        if (bApDebug)
            ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: ApacheInitCleanup: mod_perl.c not found [%d/%d]\n", getpid(), gettid()) ;
        embperl_EndPass1 () ;
        }

#endif
    }


/*---------------------------------------------------------------------------
* embperl_ApacheConfigCleanup
*/
/*!
*
* \_en									   
* Apache Cleanup DirConfig structure
* \endif                                                                       
*
* \_de									   
* Apache Cleanup DirConfig structure
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

/* --- functions for merging configurations --- */

#define EPCFG_APP    
#define EPCFG_REQ   
#define EPCFG_COMPONENT   

#undef EPCFG_STR
#undef EPCFG_INT
#undef EPCFG_INTOPT
#undef EPCFG_BOOL
#undef EPCFG_CHAR
#undef EPCFG_CV
#undef EPCFG_SV
#undef EPCFG_HV
#undef EPCFG_AV
#undef EPCFG_REGEX

#define EPCFG_INT EPCFG
#define EPCFG_INTOPT EPCFG
#define EPCFG_BOOL EPCFG
#define EPCFG_CHAR EPCFG
#define EPCFG_STR EPCFG

#define EPCFG_CV EPCFG_DEC
#define EPCFG_SV EPCFG_DEC
#define EPCFG_HV EPCFG_DEC
#define EPCFG_REGEX EPCFG_DEC
#define EPCFG_AV(STRUCT,TYPE,NAME,CFGNAME,X) EPCFG_DEC(STRUCT,TYPE,NAME,CFGNAME)

#undef EPCFG
#define EPCFG(STRUCT,TYPE,NAME,CFGNAME)

#undef EPCFG_DEC
#define EPCFG_DEC(STRUCT,TYPE,NAME,CFGNAME)  \
    if (cfg -> STRUCT.NAME) \
        { \
        if (bApDebug) \
            ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: ApacheConfigCleanup:SvREFCNT_dec "#CFGNAME" (name="#NAME" type="#TYPE" refcnt=%d) \n", (int)SvREFCNT ((SV *)(cfg -> STRUCT.NAME))) ; \
        SvREFCNT_dec ((SV *)(cfg -> STRUCT.NAME)) ; \
        cfg -> STRUCT.NAME = NULL ; \
        }


#ifdef APACHE2
static apr_status_t embperl_ApacheConfigCleanup (void * p)
#else
static void embperl_ApacheConfigCleanup (void * p)
#endif

    {
    tApacheDirConfig * cfg = (tApacheDirConfig *) p ;
    dTHX ;

    if (bApDebug)
        ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: ApacheConfigCleanup [%d/%d]\n", getpid(), gettid()) ;

#include "epcfg.h"

#ifdef APACHE2
    return OK ;
#endif

    }





/*---------------------------------------------------------------------------
* embperl_GetApacheConfig
*/

int embperl_GetApacheConfig (/*in*/ tThreadData * pThread,
                            /*in*/  request_rec * r,
                            /*in*/  server_rec * s,
                            /*out*/ tApacheDirConfig * * ppConfig)

    {
    *ppConfig = NULL ;

    if (embperl_module.module_index >= 0)
        {
        if(r && r->per_dir_config)
            {
            *ppConfig = (tApacheDirConfig *) ap_get_module_config(r->per_dir_config, &embperl_module);
            if (bApDebug)
                ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: GetApacheConfig for dir\n") ;
            }
        else if(s && s->lookup_defaults) /*s->module_config)*/
            {
            *ppConfig = (tApacheDirConfig *) ap_get_module_config(s->lookup_defaults /*s->module_config*/, &embperl_module);
            if (bApDebug)
                ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: GetApacheConfig for server\n") ;
            }
        else if (bApDebug)
            ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: GetApacheConfig -> no config available for %s\n",r && r->per_dir_config?"dir":"server" ) ;
        }
    else
        if (bApDebug)
            ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: GetApacheConfig -> no config available for %s; mod_embperl not loaded?\n",r && r->per_dir_config?"dir":"server" ) ;

    return ok ;
    }

/*---------------------------------------------------------------------------
* embperl_create_dir_config
*/

static void *embperl_create_dir_config(apr_pool_t * p, char *d)
    {
    /*char buf [20] ;*/
    tApacheDirConfig *cfg ;
    apr_pool_t * subpool ;

    embperl_ApacheInitUnload (p) ;

#ifdef APACHE2
    apr_pool_create_ex(&subpool, p, NULL, NULL);
#else
    subpool = ap_make_sub_pool(p);
#endif
    cfg = (tApacheDirConfig *) apr_pcalloc(subpool, sizeof(tApacheDirConfig));

#if 0
#ifdef APACHE2
    apr_pool_cleanup_register(subpool, cfg, embperl_ApacheConfigCleanup, embperl_ApacheConfigCleanup); 
#else
    ap_register_cleanup(subpool, cfg, embperl_ApacheConfigCleanup, embperl_ApacheConfigCleanup);
#endif
#endif
    
    embperl_DefaultReqConfig (&cfg -> ReqConfig) ;
    embperl_DefaultAppConfig (&cfg -> AppConfig) ;
    embperl_DefaultComponentConfig (&cfg -> ComponentConfig) ;
    cfg -> bUseEnv = -1 ; 

    if (bApDebug)
        ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: create_dir_config %s (0x%p) [%d/%d]\n", cfg -> AppConfig.sAppName?cfg -> AppConfig.sAppName:"", cfg, getpid(), gettid()) ;

    return cfg;
    }


/*---------------------------------------------------------------------------
* embperl_create_server_config
*/

static void *embperl_create_server_config(apr_pool_t * p, server_rec *s)
    {
    tApacheDirConfig *cfg = (tApacheDirConfig *) apr_pcalloc(p, sizeof(tApacheDirConfig));

    bApDebug |= ap_exists_config_define("EMBPERL_APDEBUG") ;

    embperl_ApacheInitUnload (p) ;

    embperl_DefaultReqConfig (&cfg -> ReqConfig) ;
    embperl_DefaultAppConfig (&cfg -> AppConfig) ;
    embperl_DefaultComponentConfig (&cfg -> ComponentConfig) ;
    cfg -> bUseEnv = -1 ; 

    if (bApDebug)
        ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: create_server_config (0x%p) [%d/%d]\n", cfg, getpid(), gettid()) ;


    return cfg;
    }


/* --- functions for merging configurations --- */

#define EPCFG_APP    
#define EPCFG_REQ   
#define EPCFG_COMPONENT   

#undef EPCFG_STR
#undef EPCFG_INT
#undef EPCFG_INTOPT
#undef EPCFG_BOOL
#undef EPCFG_CHAR
#undef EPCFG_CV
#undef EPCFG_SV
#undef EPCFG_HV
#undef EPCFG_AV
#undef EPCFG_REGEX

#define EPCFG_INT EPCFG
#define EPCFG_INTOPT EPCFG
#define EPCFG_BOOL EPCFG
#define EPCFG_CHAR EPCFG

#define EPCFG_CV EPCFG_SAVE
#define EPCFG_SV EPCFG_SAVE
#define EPCFG_HV EPCFG_SAVE
#define EPCFG_REGEX EPCFG_SAVE
#define EPCFG_AV(STRUCT,TYPE,NAME,CFGNAME,SEPARATOR) EPCFG_SAVE(STRUCT,TYPE,NAME,CFGNAME)

#undef EPCFG
#define EPCFG(STRUCT,TYPE,NAME,CFGNAME)  \
    if (add -> set_##STRUCT##NAME) \
        { \
        mrg -> set_##STRUCT##NAME = 1 ; \
        mrg -> STRUCT.NAME = add -> STRUCT.NAME ; \
        if (bApDebug) \
            ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: Merge "#CFGNAME" (type="#TYPE") => %d\n", mrg -> STRUCT.NAME) ; \
        } \
    else \
        {  \
        if (bApDebug && mrg -> set_##STRUCT##NAME) \
            ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: Merge "#CFGNAME" (type="#TYPE") stays %d\n", mrg -> STRUCT.NAME) ; \
        } 

#define EPCFG_STR(STRUCT,TYPE,NAME,CFGNAME)  \
    if (add -> set_##STRUCT##NAME) \
        { \
        mrg -> set_##STRUCT##NAME = 1 ; \
        mrg -> STRUCT.NAME = add -> STRUCT.NAME ; \
        if (bApDebug) \
            ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: Merge "#CFGNAME" (type="#TYPE") => %s\n", mrg -> STRUCT.NAME?mrg -> STRUCT.NAME:"<null>") ; \
        } \
    else \
        {  \
        if (bApDebug && mrg -> set_##STRUCT##NAME) \
            ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: Merge "#CFGNAME" (type="#TYPE") stays %s\n", mrg -> STRUCT.NAME?mrg -> STRUCT.NAME:"<null>") ; \
        } 

#undef EPCFG_SAVE

#ifdef PERL_IMPLICIT_CONTEXT
#define dTHXCond if (!aTHX) aTHX = PERL_GET_THX ;
#else
#define dTHXCond 
#endif

#define EPCFG_SAVE(STRUCT,TYPE,NAME,CFGNAME)  \
    if (add -> set_##STRUCT##NAME) \
        { \
        mrg -> set_##STRUCT##NAME = 1 ; \
        mrg -> STRUCT.NAME = add -> STRUCT.NAME ; \
        mrg -> save_##STRUCT##NAME = add -> save_##STRUCT##NAME ; \
        if (bApDebug) \
            ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: Merge "#CFGNAME" (type="#TYPE") => %s\n", mrg -> save_##STRUCT##NAME?mrg -> save_##STRUCT##NAME:"<null>") ; \
        } \
    else \
        {  \
        if (bApDebug && mrg -> set_##STRUCT##NAME) \
            ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: Merge "#CFGNAME" (type="#TYPE") stays %s\n", mrg -> save_##STRUCT##NAME?mrg -> save_##STRUCT##NAME:"<null>") ; \
        } \
    if (mrg -> STRUCT.NAME) \
        { \
        dTHXCond  \
        SvREFCNT_inc((SV *)mrg -> STRUCT.NAME) ; \
        } 

/*---------------------------------------------------------------------------
* embperl_merge_dir_config
*/

static void *embperl_merge_dir_config (apr_pool_t *p, void *basev, void *addv)
    {
    if (!basev)
        return addv ;
    
        {
        tApacheDirConfig *mrg ; /*= (tApacheDirConfig *)ap_palloc (p, sizeof(tApacheDirConfig)); */
        tApacheDirConfig *base = (tApacheDirConfig *)basev;
        tApacheDirConfig *add = (tApacheDirConfig *)addv;
        apr_pool_t * subpool ;
#ifdef PERL_IMPLICIT_CONTEXT
        pTHX ;
        aTHX = NULL ;
#endif

#ifdef APACHE2
        apr_pool_create_ex(&subpool, p, NULL, NULL);
#else
        subpool = ap_make_sub_pool(p);
#endif
        mrg = (tApacheDirConfig *)apr_palloc (subpool, sizeof(tApacheDirConfig));

        if (bApDebug)
            ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: merge_dir/server_config base=0x%p add=0x%p mrg=0x%p\n", basev, addv, mrg) ;

#ifdef APACHE2
        apr_pool_cleanup_register(subpool, mrg, embperl_ApacheConfigCleanup, embperl_ApacheConfigCleanup); 
#else
        ap_register_cleanup(subpool, mrg, embperl_ApacheConfigCleanup, embperl_ApacheConfigCleanup);
#endif

        memcpy (mrg, base, sizeof (*mrg)) ;

        if (bApDebug)
            ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: merge_dir/server_config %s + %s\n", mrg -> AppConfig.sAppName, add -> AppConfig.sAppName) ;

        if (add -> AppConfig.sAppName)
            mrg -> AppConfig.sAppName = add -> AppConfig.sAppName ;

#include "epcfg.h" 

        if (add -> bUseEnv >= 0)
            mrg -> bUseEnv = add -> bUseEnv ;

        return mrg ;
        }
    }

/*---------------------------------------------------------------------------
* embperl_Apache_Config_useenv
*/


static const char * embperl_Apache_Config_useenv (cmd_parms *cmd, /*tApacheDirConfig*/ void * pDirCfg, int arg)
    { 
    ((tApacheDirConfig *)pDirCfg) -> bUseEnv = arg ; 
    if (bApDebug)
        ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: Set UseEnv = %d\n", arg) ;

    return NULL; 
    } 




/* --- functions for apache config cmds --- */


#undef EPCFG
#undef EPCFG_INT
#define EPCFG_INT(STRUCT,TYPE,NAME,CFGNAME) \
const char * embperl_Apache_Config_##STRUCT##NAME (cmd_parms *cmd, /* tApacheDirConfig */ void * pDirCfg, const char * arg) \
    { \
    ((tApacheDirConfig *)pDirCfg) -> STRUCT.NAME = (TYPE)strtol(arg, NULL, 0) ; \
    ((tApacheDirConfig *)pDirCfg) -> set_##STRUCT##NAME = 1 ; \
    if (bApDebug) \
        ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: Set "#CFGNAME" (type="#TYPE";INT) = %s\n", arg) ; \
    return NULL; \
    } 

#undef EPCFG_INTOPT
#define EPCFG_INTOPT(STRUCT,TYPE,NAME,CFGNAME) \
const char * embperl_Apache_Config_##STRUCT##NAME (cmd_parms *cmd, /* tApacheDirConfig */ void * pDirCfg, const char * arg) \
    { \
    if (isdigit(*arg))    \
        ((tApacheDirConfig *)pDirCfg) -> STRUCT.NAME = (TYPE)strtol(arg, NULL, 0) ; \
    else \
        { \
        int val ; \
        if (embperl_OptionListSearch(Options##CFGNAME,1,#CFGNAME,arg,&val)) \
            return "Unknown Option" ; \
        ((tApacheDirConfig *)pDirCfg) -> STRUCT.NAME = (TYPE)val ; \
        } \
    ((tApacheDirConfig *)pDirCfg) -> set_##STRUCT##NAME = 1 ; \
    if (bApDebug) \
        ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: Set "#CFGNAME" (type="#TYPE";INT) = %s\n", arg) ; \
    return NULL; \
    } 

#undef EPCFG_BOOL
#define EPCFG_BOOL(STRUCT,TYPE,NAME,CFGNAME) \
const char * embperl_Apache_Config_##STRUCT##NAME (cmd_parms *cmd, /* tApacheDirConfig */ void * pDirCfg, const char * arg) \
    { \
    ((tApacheDirConfig *)pDirCfg) -> STRUCT.NAME = (TYPE)(arg?1:0) ; \
    ((tApacheDirConfig *)pDirCfg) -> set_##STRUCT##NAME = 1 ; \
    if (bApDebug) \
        ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: Set "#CFGNAME" (type="#TYPE";BOOL) = %s\n", arg) ; \
    return NULL; \
    } 


#undef EPCFG_STR
#define EPCFG_STR(STRUCT,TYPE,NAME,CFGNAME) \
const char * embperl_Apache_Config_##STRUCT##NAME (cmd_parms *cmd, /* tApacheDirConfig */ void * pDirCfg, const char* arg) \
    { \
    apr_pool_t * p = cmd -> pool ;    \
    ((tApacheDirConfig *)pDirCfg) -> STRUCT.NAME = apr_pstrdup(p, arg) ; \
    ((tApacheDirConfig *)pDirCfg) -> set_##STRUCT##NAME = 1 ; \
    if (bApDebug) \
        ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: Set "#CFGNAME" (type="#TYPE";STR) = %s\n", arg) ; \
    return NULL; \
    } 

#undef EPCFG_EXPIRES
#define EPCFG_EXPIRES(STRUCT,TYPE,NAME,CFGNAME) \
const char * embperl_Apache_Config_##STRUCT##NAME (cmd_parms *cmd, /* tApacheDirConfig */ void * pDirCfg, const char* arg) \
    { \
    apr_pool_t * p = cmd -> pool ;    \
    char buf[256] ; \
    if (!embperl_CalcExpires(arg, buf, 0)) \
        LogErrorParam (NULL, rcTimeFormatErr, "EMBPERL_"#CFGNAME, arg) ; \
    else \
        ((tApacheDirConfig *)pDirCfg) -> STRUCT.NAME = apr_pstrdup(p, arg) ; \
    ((tApacheDirConfig *)pDirCfg) -> set_##STRUCT##NAME = 1 ; \
    if (bApDebug) \
        ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: Set "#CFGNAME" (type="#TYPE";STR) = %s\n", arg) ; \
    return NULL; \
    } 

#undef EPCFG_CHAR
#define EPCFG_CHAR(STRUCT,TYPE,NAME,CFGNAME) \
const char * embperl_Apache_Config_##STRUCT##NAME (cmd_parms *cmd, /* tApacheDirConfig */ void * pDirCfg, const char * arg) \
    { \
    ((tApacheDirConfig *)pDirCfg) -> STRUCT.NAME = (TYPE)arg[0] ; \
    ((tApacheDirConfig *)pDirCfg) -> set_##STRUCT##NAME = 1 ; \
    if (bApDebug) \
        ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: Set "#CFGNAME" (type="#TYPE";CHAR) = %s\n", arg) ; \
    return NULL; \
    } 

#undef EPCFG_CV
#undef EPCFG_SV
#undef EPCFG_HV
#undef EPCFG_AV
#undef EPCFG_REGEX
#define EPCFG_CV EPCFG_SAVE
#define EPCFG_SV EPCFG_SAVE
#define EPCFG_HV EPCFG_SAVE
#define EPCFG_REGEX EPCFG_SAVE
#define EPCFG_AV(STRUCT,TYPE,NAME,CFGNAME,SEPARATOR) EPCFG_SAVE(STRUCT,TYPE,NAME,CFGNAME)

#undef EPCFG_SAVE
#define EPCFG_SAVE(STRUCT,TYPE,NAME,CFGNAME) \
const char * embperl_Apache_Config_##STRUCT##NAME (cmd_parms *cmd, /* tApacheDirConfig */ void * pDirCfg, const char* arg) \
    { \
    ((tApacheDirConfig *)pDirCfg) -> save_##STRUCT##NAME = apr_pstrdup(cmd -> pool, arg) ; \
    ((tApacheDirConfig *)pDirCfg) -> set_##STRUCT##NAME = 1 ; \
    if (bApDebug) \
        ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: Set "#CFGNAME" (type="#TYPE") = %s (save for later conversion to Perl data)\n", arg) ; \
    return NULL ; \
    } 

#define EPCFG_APP    
#define EPCFG_REQ   
#define EPCFG_COMPONENT   


#include "epcfg.h"

#endif /* MOD_EMBPERL */
/*--------------------------------------------------------------------------- */
#ifdef EMBPERL_SO

/*---------------------------------------------------------------------------
* embperl_GetApacheAppName
*/

char * embperl_GetApacheAppName (/*in*/ tApacheDirConfig * pDirCfg)


    {
    char *n = pDirCfg?pDirCfg -> AppConfig.sAppName:"Embperl" ;
    if (bApDebug)
        ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: get_appname %s[%d/%d]\n", n?n:"", getpid(), gettid()) ;
    return n ;
    }


/* --- functions for converting string to Perl structures --- */

#undef EPCFG_STR
#undef EPCFG_INT
#undef EPCFG_EXPIRES
#undef EPCFG_INTOPT
#undef EPCFG_BOOL
#undef EPCFG_CHAR
#define EPCFG_INT EPCFG
#define EPCFG_EXPIRES EPCFG_STR
#define EPCFG_INTOPT EPCFG
#define EPCFG_BOOL EPCFG
#define EPCFG_CHAR EPCFG
#undef EPCFG

#define EPCFG(STRUCT,TYPE,NAME,CFGNAME)  \
        if (bApDebug && pDirCfg -> set_##STRUCT##NAME) \
            ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: Get "#CFGNAME" (type="#TYPE") %d (0x%x)\n", pDirCfg -> STRUCT.NAME, pDirCfg -> STRUCT.NAME) ; 

#define EPCFG_STR(STRUCT,TYPE,NAME,CFGNAME)  \
        if (bApDebug && pDirCfg -> set_##STRUCT##NAME) \
            ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: Get "#CFGNAME" (type="#TYPE") %s\n", pDirCfg -> STRUCT.NAME?pDirCfg -> STRUCT.NAME:"<null>") ; 



#undef EPCFG_SV
#define EPCFG_SV(STRUCT,TYPE,NAME,CFGNAME) \
    if (pDirCfg -> save_##STRUCT##NAME && !pDirCfg -> STRUCT.NAME) \
        { \
        if (bApDebug) \
            ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: Get: about to convert "#CFGNAME" (type="#TYPE";SV) to perl data: %s\n", pDirCfg -> save_##STRUCT##NAME) ; \
\
        pDirCfg -> STRUCT.NAME = newSVpv((char *)pDirCfg -> save_##STRUCT##NAME, 0) ; \
        } \
    SvREFCNT_inc((SV *)(pDirCfg -> STRUCT.NAME)) ;

#undef EPCFG_CV
#define EPCFG_CV(STRUCT,TYPE,NAME,CFGNAME) \
    if (pDirCfg -> save_##STRUCT##NAME && !pDirCfg -> STRUCT.NAME) \
        { \
        int rc ;\
        if (bApDebug) \
            ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: Get: about to convert "#CFGNAME" (type="#TYPE";CV) to perl data: %s\n", pDirCfg -> save_##STRUCT##NAME) ; \
\
        if ((rc = EvalConfig (pApp, sv_2mortal(newSVpv(pDirCfg -> save_##STRUCT##NAME, 0)), 0, NULL, "Configuration: EMBPERL_"#CFGNAME, &pDirCfg -> STRUCT.NAME)) != ok) \
            pDirCfg -> STRUCT.NAME = NULL ; \
        tainted = 0 ; \
        } \
    if (pDirCfg -> STRUCT.NAME) \
        SvREFCNT_inc((SV *)(pDirCfg -> STRUCT.NAME)) ;


#undef EPCFG_AV
#define EPCFG_AV(STRUCT,TYPE,NAME,CFGNAME,SEPARATOR) \
    if (pDirCfg -> save_##STRUCT##NAME && !pDirCfg -> STRUCT.NAME) \
        { \
        if (bApDebug) \
            ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: Get: about to convert "#CFGNAME" (type="#TYPE";AV) to perl data: %s\n", pDirCfg -> save_##STRUCT##NAME) ; \
\
        pDirCfg -> STRUCT.NAME = embperl_String2AV(pApp, pDirCfg -> save_##STRUCT##NAME, SEPARATOR) ;\
        tainted = 0 ; \
        } \
    SvREFCNT_inc((SV *)(pDirCfg -> STRUCT.NAME)) ;

  
#undef EPCFG_HV
#define EPCFG_HV(STRUCT,TYPE,NAME,CFGNAME) \
    if (pDirCfg -> save_##STRUCT##NAME && !pDirCfg -> STRUCT.NAME) \
        { \
        if (bApDebug) \
            ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: Get: about to convert "#CFGNAME" (type="#TYPE";HV) to perl data: %s\n", pDirCfg -> save_##STRUCT##NAME) ; \
\
        pDirCfg -> STRUCT.NAME = embperl_String2HV(pApp, pDirCfg -> save_##STRUCT##NAME, ' ', NULL) ;\
        tainted = 0 ; \
        } \
    SvREFCNT_inc((SV *)(pDirCfg -> STRUCT.NAME)) ;
    

#undef EPCFG_REGEX
#define EPCFG_REGEX(STRUCT,TYPE,NAME,CFGNAME) \
    if (pDirCfg -> save_##STRUCT##NAME && !pDirCfg -> STRUCT.NAME) \
        { \
        int rc ; \
        if (bApDebug) \
            ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "EmbperlDebug: Get: about to convert "#CFGNAME" (type="#TYPE";REGEX) to perl data: %s\n", pDirCfg -> save_##STRUCT##NAME) ; \
\
        if ((rc = EvalRegEx (pApp, pDirCfg -> save_##STRUCT##NAME, "Configuration: EMBPERL_"#CFGNAME, &pDirCfg -> STRUCT.NAME)) != ok) \
            pDirCfg -> STRUCT.NAME = NULL ; \
        tainted = 0 ; \
        } \
    if (pDirCfg -> STRUCT.NAME) \
        SvREFCNT_inc((SV *)(pDirCfg -> STRUCT.NAME)) ;


/*---------------------------------------------------------------------------
* embperl_GetApacheAppConfig
*/

int embperl_GetApacheAppConfig (/*in*/ tThreadData * pThread,
                                /*in*/ tMemPool    * pPool,
                                /*in*/ tApacheDirConfig * pDirCfg,
                                /*out*/ tAppConfig * pConfig)


    {
    eptTHX_
    tApp * pApp = NULL ;
    if(pDirCfg)
        {
#define EPCFG_APP    
#undef EPCFG_REQ   
#undef EPCFG_COMPONENT   

#include "epcfg.h"         
        
        memcpy (&pConfig -> pPool + 1, &pDirCfg -> AppConfig.pPool + 1, sizeof (*pConfig) - ((tUInt8 *)(&pConfig -> pPool) - (tUInt8 *)pConfig) - sizeof (pConfig -> pPool)) ;
        pConfig -> bDebug = pDirCfg -> ComponentConfig.bDebug ;
        
        if (pDirCfg -> bUseEnv)
             embperl_GetCGIAppConfig (pThread, pPool, pConfig, 1, 0, 0) ;
        }
    else
        embperl_DefaultAppConfig (pConfig) ;

    return ok ;
    }


/*---------------------------------------------------------------------------
* embperl_GetApacheReqConfig
*/

int embperl_GetApacheReqConfig (/*in*/ tApp *        pApp,
                                /*in*/ tMemPool    * pPool,
                                /*in*/ tApacheDirConfig * pDirCfg,
                                /*out*/ tReqConfig * pConfig)


    {
#define a pApp
    epaTHX_
#undef a

    if(pDirCfg)
        {
#undef EPCFG_APP    
#define EPCFG_REQ   
#undef EPCFG_COMPONENT   

#include "epcfg.h"         

        memcpy (&pConfig -> pPool + 1, &pDirCfg -> ReqConfig.pPool + 1, sizeof (*pConfig) - ((tUInt8 *)(&pConfig -> pPool) - (tUInt8 *)pConfig) - sizeof (pConfig -> pPool)) ;
        pConfig -> bDebug = pDirCfg -> ComponentConfig.bDebug ;
        pConfig -> bOptions = pDirCfg -> ComponentConfig.bOptions ;

        if (pDirCfg -> bUseEnv)
             embperl_GetCGIReqConfig (pApp, pPool, pConfig, 1, 0, 0) ;
        }
    else
        embperl_DefaultReqConfig (pConfig) ;
    pConfig -> bOptions |= optSendHttpHeader ;

    return ok ;
    }

/*---------------------------------------------------------------------------
* embperl_GetApacheComponentConfig
*/

int embperl_GetApacheComponentConfig (/*in*/ tReq * pReq,
                                /*in*/ tMemPool    * pPool,
                                /*in*/ tApacheDirConfig * pDirCfg,
                                /*out*/ tComponentConfig * pConfig)


    {

    if(pDirCfg)
        {
    #define r pReq
        epTHX_
    #undef r
        tApp * pApp = pReq -> pApp ;

#undef EPCFG_APP    
#undef EPCFG_REQ   
#define EPCFG_COMPONENT   

#include "epcfg.h"         

        memcpy (&pConfig -> pPool + 1, &pDirCfg -> ComponentConfig.pPool + 1, sizeof (*pConfig) - ((tUInt8 *)(&pConfig -> pPool) - (tUInt8 *)pConfig) - sizeof (pConfig -> pPool)) ;
        
        if (pDirCfg -> bUseEnv)
             embperl_GetCGIComponentConfig (pReq, pPool, pConfig, 1, 0, 0) ;
        }
    else
        embperl_DefaultComponentConfig (pConfig) ;

    return ok ;
    }


/*---------------------------------------------------------------------------
* embperl_AddCookie
*/

struct addcookie
    {
    tApp * pApp ;
    tReqParam * pParam ;
    } ;

static int embperl_AddCookie (/*in*/ void * s, const char * pKey, const char * pValue)

    {
    tApp * a = ((struct addcookie *)s) -> pApp ;
    epaTHX_ 
    HV *   pHV ;
        
    if (!(pHV = ((struct addcookie *)s) -> pParam -> pCookies))    
        pHV = ((struct addcookie *)s) -> pParam -> pCookies = newHV () ;

    embperl_String2HV(a, pValue, ';', pHV) ;

    return 1 ;
    }


/*---------------------------------------------------------------------------
* embperl_GetApacheReqParam
*/

int embperl_GetApacheReqParam  (/*in*/  tApp        * pApp,
                                /*in*/ tMemPool    * pPool,
                                /*in*/  request_rec * r,
                                /*out*/ tReqParam * pParam)


    {
    tApp * a = pApp ;
    epaTHX_
    char * p ;
    struct addcookie s ;
    char buf[20] ;
    char * scheme ;
    short  port ;

    s.pApp = a ;
    s.pParam = pParam ;


    pParam -> sFilename    = r -> filename ;
    pParam -> sUnparsedUri = r -> unparsed_uri ;
    pParam -> sUri         = r -> uri ;
    pParam -> sPathInfo    = r -> path_info ;
    pParam -> sQueryInfo   = r -> args ;  
    if ((p = ep_pstrdup (pPool, apr_table_get (r -> headers_in, "Accept-Language"))))
        {
        while (isspace(*p))
            p++ ;
        pParam -> sLanguage = p ;
        while (isalpha(*p))
            p++ ;
        *p = '\0' ;
        }

    apr_table_do (embperl_AddCookie, &s, r -> headers_in, "Cookie", NULL) ;

    buf[0] = '\0' ;
#ifdef APACHE2
    port   = r -> connection -> local_addr -> port ;
#else
    port   = ntohs(r -> connection -> local_addr.sin_port) ;
#endif
#ifdef EAPI
    if (ap_ctx_get (r -> connection -> client -> ctx, "ssl"))
        {
	scheme = "https" ;
	if (port != 443)
	    sprintf (buf, ":%d", port) ;
	}
    else
#endif
        {
	scheme = "http" ;
	if (port != 80)
	    sprintf (buf, ":%d", port) ;
	}


    pParam -> sServerAddr = ep_pstrcat (pPool, scheme, "://", 
		    r -> hostname?r -> hostname:r -> server -> server_hostname, buf, NULL) ;


    return ok ;
    }

#endif /* EMBPERL_SO */

#endif /* APACHE */
