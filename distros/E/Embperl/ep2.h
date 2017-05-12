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
#   $Id: ep2.h 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################*/


/* ---- from epcmd2.c ----- */


void embperlCmd_InputCheck (/*i/o*/ register req *     r,
			    /*in*/ tDomTree *	    pDomTree,
			    /*in*/ tNode	    xNode,
			    /*in*/ tRepeatLevel     nRepeatLevel,
			    /*in*/ const char *     pName,
			    /*in*/ int              nNameLen,
			    /*in*/ const char *     pVal,
			    /*in*/ int              nValLen,
                            /*in*/ int              bSetInSource) ;


void embperlCmd_Option (/*i/o*/ register req *     r,
			/*in*/ tDomTree *	    pDomTree,
			/*in*/ tNode	    xNode,
		        /*in*/ tRepeatLevel     nRepeatLevel,
			/*in*/ const char *     pName,
			/*in*/ int              nNameLen,
			/*in*/ const char *     pVal,
			/*in*/ int              nValLen,
                        /*in*/ int              bSetInSource) ;

int embperlCmd_Hidden	(/*i/o*/ register req *     r,
			 /*in*/ tDomTree *	    pDomTree,
			 /*in*/ tNode		    xNode,
			 /*in*/ tRepeatLevel     nRepeatLevel,
			 /*in*/ const char *	    sArg) ;
			

SV * Node_replaceChildWithUrlDATA (/*in*/ tReq *        r,
                                   /*in*/ tIndex  xDomTree, 
					  tIndex  xOldChild, 
				  /*in*/ tRepeatLevel     nRepeatLevel,
					  SV *    sText) ;
int embperlCmd_AddSessionIdToHidden(/*i/o*/ register req *     r,
			            /*in*/ tDomTree *	    pDomTree,
			            /*in*/ tNode		    xNode,
		                    /*in*/ tRepeatLevel	    nRepeatLevel) ;
int embperlCmd_AddSessionIdToLink  (/*i/o*/ register req *     r,
			            /*in*/ tDomTree *	    pDomTree,
			            /*in*/ tNode		    xNode,
		                    /*in*/ tRepeatLevel	    nRepeatLevel,
                                    /*in*/ char *            sAttrName) ;

    
			 
/* ---- from epparse.c ----- */

extern struct tTokenTable DefaultTokenTable ;

int BuildTokenTable (/*i/o*/ register req *	  r,
 		     /*in*/ int            nLevel,
                     /*in*/  const char *         sName,
                     /*in*/  HV *		  pTokenHash,
		     /*in*/  const char *         pDefEnd,
		     /*i/o*/ void * *		  ppCompilerInfo,
                     /*out*/ struct tTokenTable * pTokenTable) ;

int ParseFile (/*i/o*/ register req * r) ;

int embperl_Parse (/*i/o*/ register req * r,
                   /*in*/  char *   pSource,
                   /*in*/  size_t         nLen,
                   /*out*/ tIndex *       pxDomTree) ;

/* ---- from epcomp.c ----- */

struct tCacheItem ;

int embperl_CompileInitItem      (/*i/o*/ register req * r,
				  /*in*/  HV *           pHash,
				  /*in*/  int            nNodeName,
				  /*in*/  int            nNodeType,
				  /*in*/  int		 nTagSet,
				  /*in*/  void * *	 ppInfo) ;


int embperl_Compile                 (/*in*/  tReq *	  r,
				     /*in*/  tIndex       xDomTree,
				     /*out*/ tIndex *     pxResultDomTree,
                                     /*out*/ SV * *       pProg) ;

int embperl_Execute	            (/*in*/  tReq *	  r,
				     /*in*/  tIndex       xSrcDomTree,
                                     /*in*/  CV *         pCV,
				     /*in*/  tIndex  *    pResultDomTree) ;


int embperl_ExecuteSubStart         (/*in*/  tReq *	  r,
				     /*in*/  SV *         pDomTreeSV,
				     /*in*/  tIndex       xDomTree,
				     /*in*/  AV *         pSaveAV) ;

int embperl_ExecuteSubEnd           (/*in*/  tReq *	  r,
				     /*in*/  SV *         pDomTreeSV,
				     /*in*/  AV *         pSaveAV) ;



/* ---- from epcache.c ----- */

#define cache_malloc(r,s) malloc(s)
#define cache_free(r,m) free(m)


struct tProvider ;
struct tProviderClass ;
struct tCacheItem ;

typedef struct tCacheItem
    {
    const char *    sKey ;                  /**< key under which this cache item is accessable */
    
    bool            bExpired ;              /**< this item is expired */
    bool            bCache ;                /**< if true cache result of provider */
    int             nLastChecked ;          /**< request when this item was last checked */
    int             nLastUpdated ;          /**< request when this item was last updated */
    time_t          nLastModified ;         /**< time when item was last modified */
    time_t          nExpiresInTime ;        /**< time in sec when item expires, 0 = does not expire */ 
    const char *    sExpiresFilename ;      /**< Item expires when mtime of filename is different to nLastModified */
    time_t          nFileModified ;         /**< time when file was last modified */
    struct stat     FileStat ;              /**< Item expires when mtime of filename is different to nLastModified */
    CV *            pExpiresCV ;            /**< Perl code to call. If returns true item expires */
    int             (*fExpires) (struct tCacheItem * pItem) ; /**< C code to call. If returns true item expires */

    void *          pData ;                 /**< Item C data */
    SV *            pSVData ;               /**< Item Perl data */
    tIndex          xData ;                 /**< Item Index data */

    struct tCacheItem * *  pDependsOn ;            /**< CacheItem on which this one depends */
    struct tCacheItem * *  pNeededFor ;            /**< CacheItems that need this item */

    struct tProvider *  pProvider ;         /**< Provider for this cacheItem */
    
    } tCacheItem ;


typedef struct tProviderClass
    {
    const char *    sOutputType ;                                                   /**< MIME type of output format (maybe override by object) */
    int (*fNew)(req * r, tCacheItem * pOutputCache, struct tProviderClass * pProviderClass, HV * pProviderParam, SV * pParam, IV nParamIndex)  ;  /**< called to initialize the provider */
    int (*fAppendKey)(req * r, struct tProviderClass * pProviderClass, HV * pProviderParam, SV * pParam, IV nParamIndex, SV * pKey)  ;  /**< append the key for the cache of the provider and it's dependencies */
    int (*fUpdateParam)(req * r, struct tProvider * pProvider, HV * pProviderParam)  ;        /**< update the parameter of the provider */
    int (*fGetContentSV)(req * r, struct tProvider * pProvider, SV ** pData, bool bUseCache) ;      /**< Get the content from that provider */
    int (*fGetContentPtr)(req * r, struct tProvider * pProvider, void ** pData, bool bUseCache) ;   /**< Get the content from that provider */
    int (*fGetContentIndex)(req * r, struct tProvider * pProvider, tIndex * pData, bool bUseCache) ;/**< Get the content from that provider */
    int (*fFreeContent) (req * r, struct tCacheItem * pItem) ;      /**< Called to free memory of associated data */
    int (*fExpires) (req * r, struct tProvider * pProvider) ;       /**< Called to check if provider content is expired */
    } tProviderClass ;


/*! General provider for input */

typedef struct tProvider
    {
    const char *    sOutputType ;       /**< MIME type of output format */
    tCacheItem *    pCache ;            /**< CacheItem for this provider instance */
    tProviderClass *    pProviderClass ;    /**< Provider class */
    } tProvider ;


int Cache_Init (/*in*/ tApp * a) ;

int Cache_AddProviderClass (/*in*/ const char *     sName,
                            /*in*/ tProviderClass * pClass) ;

int Cache_CleanupRequest (req * r) ;

int Cache_New (/*in*/ req *             r,
               /*in*/ SV *              pParam,
               /*in*/ IV                nParamNdx,
               /*in*/ bool              bTopLevel,
               /*in*/ tCacheItem * *    pItem) ;

int Cache_AppendKey               (/*in*/ req *              r,
                                   /*in*/ HV *               pProviderParam,
                                   /*in*/ const char *       sSubProvider, 
                                   /*in*/ SV *               pParam,
                                   /*in*/ IV                 nParamIndex,
                                   /*i/o*/ SV *              pKey) ;

tCacheItem * Cache_GetByKey    (/*in*/ req *       r,
                                /*in*/ const char * sKey) ;

int Cache_AddDependency (/*in*/ req *       r,
                         /*in*/ tCacheItem *    pItem,
                         /*in*/ tCacheItem *    pDependsOn) ;

tCacheItem * Cache_GetDependency (/*in*/ req *           r,
                                  /*in*/ tCacheItem *    pItem,
                                  /*in*/ int             n) ;

int Cache_IsExpired     (/*in*/ req *           r,
                         /*in*/ tCacheItem *    pItem,
                         /*in*/ int             nLastUpdated) ;

int Cache_SetNotExpired (/*in*/ req *       r,
                         /*in*/ tCacheItem *    pItem) ;

int Cache_GetContentSV      (/*in*/ req *             r,
                             /*in*/ tCacheItem        *pItem,
                             /*in*/ SV * *            pData, 
                             /*in*/ bool              bUseCache) ;

int Cache_GetContentPtr     (/*in*/ req *             r,
                             /*in*/ tCacheItem        *pItem,
                             /*in*/ void * *          pData,
                             /*in*/ bool              bUseCache) ;

int Cache_GetContentIndex   (/*in*/ req *             r,
                             /*in*/ tCacheItem        *pItem,
                             /*in*/ tIndex *          pData,
                             /*in*/ bool              bUseCache) ;

int Cache_GetContentSvIndex   (/*in*/ req *             r,
                             /*in*/ tCacheItem        *pItem,
                             /*in*/ SV * *            pSVData,
                             /*in*/ tIndex *          pData,
                             /*in*/ bool              bUseCache) ;

int Cache_ReleaseContent        (/*in*/ req *             r,
                                 /*in*/ tCacheItem        *pItem) ;

int Cache_FreeContent           (/*in*/ req *             r,
                                 /*in*/ tCacheItem        *pItem) ;


/* ---- from epprovider.c ----- */


int Provider_Init (/*in*/ tApp * a) ;

int Provider_New            (/*in*/ req *              r,
                             /*in*/ size_t             nSize,
                             /*in*/ tCacheItem *       pItem,
                             /*in*/ tProviderClass *   pProviderClass,
                             /*in*/ HV *               pParam) ;

int Provider_NewDependOne   (/*in*/ req *              r,
                             /*in*/ size_t             nSize,
                             /*in*/ const char *       sSourceName,
                             /*in*/ tCacheItem *       pItem,
                             /*in*/ tProviderClass *   pProviderClass,
                             /*in*/ HV *               pProviderParam,
                             /*in*/ SV *               pParam,
                             /*in*/ IV                 nParamIndex) ;

int Provider_AddDependOne   (/*in*/ req *              r,
                             /*in*/ tProvider *        pProvider,
                             /*in*/ const char *       sSourceName,
                             /*in*/ tCacheItem *       pItem,
                             /*in*/ tProviderClass *   pProviderClass,
                             /*in*/ HV *               pProviderParam,
                             /*in*/ SV *               pParam,
                             /*in*/ IV                 nParamIndex) ;

#ifdef APACHE2
int ApFilter_Init (/*in*/ tApp * a) ;
#endif

/* --- from epinit.c --- */


int    embperl_SetupThread  (/*in*/ pTHX_
                             /*out*/tThreadData * *  ppThread) ;

tThreadData * embperl_GetThread  (/*in*/ pTHX) ;

#define CurrReq       (embperl_GetThread (aTHX) -> pCurrReq)
#define CurrComponent (&(embperl_GetThread (aTHX) -> pCurrReq -> Component))
#define CurrApp (embperl_GetThread (aTHX) -> pCurrReq -> pApp)



#ifdef XALAN
    int embperl_Xalan_Init (void) ;
#endif
#ifdef LIBXSLT
    int embperl_LibXSLT_Init (void) ;
#endif


 





