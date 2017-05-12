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
#   $Id: eppriv.h 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################*/


#define EMBPERL_PACKAGE         Embperl
#define EMBPERL_PACKAGE_STR     "Embperl"


#ifdef PERL_IMPLICIT_CONTEXT
#define epTHX pTHX = r -> pPerlTHX
#define epaTHX pTHX = a -> pPerlTHX
#define eptTHX pTHX = pThread -> pPerlTHX
#define epTHX_ epTHX ;
#define epaTHX_ epaTHX ;
#define eptTHX_ eptTHX ;
#else
#define epTHX 
#define epaTHX
#define eptTHX
#define epTHX_ 
#define epaTHX_
#define eptTHX_
#endif


void boot_Embperl__Thread (pTHX_ CV * cv) ;
void boot_Embperl__App (pTHX_ CV * cv) ;
void boot_Embperl__App__Config (pTHX_ CV * cv) ;
void boot_Embperl__Req (pTHX_ CV * cv) ;
void boot_Embperl__Req__Config (pTHX_ CV * cv) ;
void boot_Embperl__Req__Param (pTHX_ CV * cv) ;
void boot_Embperl__Component (pTHX_ CV * cv) ;
void boot_Embperl__Component__Config (pTHX_ CV * cv) ;
void boot_Embperl__Component__Param (pTHX_ CV * cv) ;
void boot_Embperl__Component__Output (pTHX_ CV * cv) ;
void boot_Embperl__Syntax (pTHX_ CV * cv) ;


struct tCacheItem ;

extern SV ep_sv_undef ; 


/*-----------------------------------------------------------------*/
/*								   */
/*  cache Options						   */
/*								   */
/*-----------------------------------------------------------------*/

typedef enum tCacheOptions
    {
    ckoptCarryOver = 1,   /* use result from CacheKeyCV of preivious step if any */
    ckoptPathInfo  = 2,   /* include the PathInfo into CacheKey */
    ckoptQueryInfo = 4,	  /* include the QueryInfo into CacheKey */
    ckoptDontCachePost = 8,	  /* don't cache POST requests */
    ckoptDefault    = 15	  /* default is all options set */
    } tCacheOptions ;


/*-----------------------------------------------------------------*/
/*								   */
/*  RequestPhases						   */
/*								   */
/*-----------------------------------------------------------------*/

typedef enum 
    {
    phInit,
    phParse,
    phCompile,
    phRunAfterCompile,
    phPerlCompile,
    phRun,
    phTerm
    } tPhase ;
    
/*-----------------------------------------------------------------*/
/*								   */
/*  Parser data structures 	            			   */
/*								   */
/*-----------------------------------------------------------------*/


struct tToken
    {
    const char *	    sText ;	/* string of token (MUST be first item!) */
    const char *	    sName ;	/* name of token (only for description) */
    int			    nTextLen ;	/* len of string */
    const char *	    sEndText ;	/* string which ends the block */
    const char *	    sNodeName;	/* name of the node to create */
    int			    nNodeName ;	/* index in string table of node name */
    tNodeType		    nNodeType ;	/* type of the node that should be created */
    tNodeType		    nCDataType ;/* type for sub nodes that contains text */
    tNodeType		    nForceType ;/* force this type for sub nodes */
    int			    bUnescape ;	/* translate input?  */
    int			    bAddFlags ;	/* add flags to node  */
    int			    bRemoveSpaces ;	/* 1 remove spaces before tag, 2 remove after */
    unsigned char *	    pContains ;	/* chars that could be contained in the string */
    int			    bInsideMustExist ;	/* if inside definition doesn't exists, ignore whole tag */
    int			    bMatchAll ;	/* match any start text */
    int			    bDontEat ;	/* don't eat the characters when parsing this token (look ahead) */
    int			    bExitInside ;/* when this tag is found exit the inside table */
    int			    bAddFirstChild;/* already add an empty CDATA node child */
    struct tTokenTable *    pFollowedBy;/* table of tokens that can follow this one */
    struct tTokenTable *    pInside ;	/* table of tokens that can apear inside this one */
    struct tToken      *    pStartTag ;	/* token that contains definition for the start of the current token */
    struct tToken      *    pEndTag ;	/* token that contains definition for the end of the current token */
    const char *	    sParseTimePerlCode ; /* perl code that is executed when this token is parsed, %% is replaced by the value of the current attribute */
    } ;        



/* --- threads & mutex --- */

#if !defined (USE_THREADS) && !defined(USE_ITHREADS) && !defined(perl_mutex)
/* dummy definition */
#define perl_mutex int
#define ep_acquire_mutex(mutex) 
#define ep_release_mutex(mutex) 
#define ep_create_mutex(mutex) 
#define ep_destroy_mutex(mutex)

#else

#define ep_acquire_mutex(mutex) MUTEX_LOCK(&mutex)
#define ep_release_mutex(mutex) MUTEX_UNLOCK(&mutex)
#define ep_create_mutex(mutex) MUTEX_INIT(&mutex)
#define ep_destroy_mutex(mutex) MUTEX_DESTROY(&mutex)
#endif

/* --- memory management --- */



tMemPool * ep_init_alloc(void);	
void ep_cleanup_alloc(void);

tMemPool * ep_make_sub_pool(tMemPool *);
void   ep_destroy_pool(tMemPool *);
void * ep_palloc(struct tMemPool *, int nbytes);
void * ep_pcalloc(struct tMemPool *, int nbytes);
char * ep_pstrdup(struct tMemPool *, const char *s);
char * ep_pstrndup(struct tMemPool *, const char *s, int n);
char * ep_pstrcat(struct tMemPool *,...) ;
char * ep_psprintf(struct tMemPool *, const char *fmt, ...) ;
char * ep_pvsprintf(struct tMemPool *, const char *fmt, va_list);


/* --- configuration --- */


void embperl_ApacheAddModule (void) ;
int embperl_GetApacheConfig (/*in*/ tThreadData * pThread,
                            /*in*/  request_rec * r,
                            /*in*/  server_rec * s,
                            /*out*/ tApacheDirConfig * * ppConfig) ;
char * embperl_GetApacheAppName (/*in*/ tApacheDirConfig * pDirCfg) ;
int embperl_GetApacheAppConfig (/*in*/ tThreadData * pThread,
                                /*in*/ tMemPool    * pPool,
                                /*in*/ tApacheDirConfig * pDirCfg,
                                /*out*/ tAppConfig * pConfig);
int embperl_GetApacheReqConfig (/*in*/ tApp *        pApp,
                                /*in*/ tMemPool    * pPool,
                                /*in*/ tApacheDirConfig * pDirCfg,
                                /*out*/ tReqConfig * pReqConfig) ;
int embperl_GetApacheComponentConfig (/*in*/ tReq * pReq,
                                /*in*/ tMemPool    * pPool,
                                /*in*/ tApacheDirConfig * pDirCfg,
                                /*out*/ tComponentConfig * pConfig) ;
int embperl_GetApacheReqParam  (/*in*/  tApp        * pApp,
                                /*in*/ tMemPool    * pPool,
                                /*in*/  request_rec * r,
                                /*out*/ tReqParam * pParam) ;




char * embperl_GetCGIAppName (/*in*/ tThreadData * pThread) ;
int embperl_GetCGIAppConfig    (/*in*/ tThreadData * pThread,
                                /*in*/ tMemPool    * pPool,
                                /*out*/ tAppConfig * pConfig,
                                /*in*/  bool         bUseEnv,
                                /*in*/  bool         bUseRedirectEnv,
                                /*in*/  bool         bSetDefault) ;
int embperl_GetCGIReqConfig    (/*in*/ tApp    *    pApp,
                                /*in*/ tMemPool    * pPool,
                                /*out*/ tReqConfig * pConfig,
                                /*in*/  bool         bUseEnv,
                                /*in*/  bool         bUseRedirectEnv,
                                /*in*/  bool         bSetDefault) ;
int embperl_GetCGIComponentConfig    (/*in*/ tReq    *    pReq,
                                    /*in*/ tMemPool    * pPool,
                                    /*out*/ tComponentConfig * pConfig,
                                /*in*/  bool         bUseEnv,
                                /*in*/  bool         bUseRedirectEnv,
                                /*in*/  bool         bSetDefault) ;
int embperl_GetCGIReqParam     (/*in*/ tApp        * pApp,
                                /*in*/ tMemPool    * pPool,
                                /*out*/ tReqParam  * pParam) ;


typedef struct tOptionEntry
    {
    const char *    sOption ;
    int             nValue ;
    } tOptionEntry ;

extern tOptionEntry OptionsDEBUG[] ;
extern tOptionEntry OptionsOPTIONS[] ;
extern tOptionEntry OptionsESCMODE[] ;
extern tOptionEntry OptionsINPUT_ESCMODE[] ;
extern tOptionEntry OptionsOUTPUT_MODE[] ;
extern tOptionEntry OptionsOUTPUT_ESC_CHARSET[] ;
extern tOptionEntry OptionsSESSION_MODE[] ;



int embperl_OptionListSearch (/*in*/ tOptionEntry * pList,
                              /*in*/ bool          bMult,
                              /*in*/ const char *  sCmd,
                              /*in*/ const char *  sOptions,
                              /*in*/ int *         pnValue) ;

const char * embperl_CalcExpires(const char *sTime, char * sResult, int bHTTP) ;



/* --- init --- */

#if 0
void embperl_DefaultAppConfig (/*in*/ tAppConfig  *pCfg) ;
void embperl_DefaultReqConfig (/*in*/ tReqConfig  *pCfg) ;
void embperl_DefaultComponentConfig (/*in*/ tComponentConfig  *pCfg) ;
#endif

void Embperl__App_new_init(pTHX_ tApp * pApp, SV * pPerlParam, int overwrite) ;
void Embperl__App__Config_new_init(pTHX_ tAppConfig * pAppConfig, SV * pPerlParam, int overwrite) ;
void Embperl__Req_new_init (pTHX_ tReq * r, SV * pPerlParam, int overwrite) ;
void Embperl__Req__Config_new_init (pTHX_ tReqConfig * r, SV * pPerlParam, int overwrite) ;
void Embperl__Req__Param_new_init (pTHX_ tReqParam * r, SV * pPerlParam, int overwrite) ;
void Embperl__Component_new_init (pTHX_ tComponent * c, SV * pPerlParam, int overwrite) ;
void Embperl__Component__Config_new_init (pTHX_ tComponentConfig * c, SV * pPerlParam, int overwrite) ;
void Embperl__Component__Param_new_init (pTHX_ tComponentParam * c, SV * pPerlParam, int overwrite) ;

void Embperl__Req__Config_destroy(pTHX_ tReqConfig * p) ;
void Embperl__Req__Param_destroy(pTHX_ tReqParam * p) ;
void Embperl__Req_destroy(pTHX_ tReq * p) ;
void Embperl__Component__Config_destroy(pTHX_ tComponentConfig * p) ;
void Embperl__Component__Param_destroy(pTHX_ tComponentParam * p) ;
void Embperl__Component_destroy(pTHX_ tComponent *p) ;

int    embperl_EndPass1  (void) ;
