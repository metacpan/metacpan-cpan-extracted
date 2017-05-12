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
#   $Id: epdat2.h 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################*/


#ifndef __EPDAT2_H
#define __EPDAT2_H

#ifdef PERL_IMPLICIT_CONTEXT
#ifdef USE_THREADS
#define tPerlInterpreter struct perl_thread 
#else
#define tPerlInterpreter PerlInterpreter 
#endif
#else
#define tPerlInterpreter void
#endif

#ifdef PerlIO
#define FILEIO PerlIO 
#else
#define FILEIO FILE
#endif

struct tReq; /* forward */

/*-----------------------------------------------------------------*/
/*								   */
/*  Parser data structures 	            			   */
/*								   */
/*-----------------------------------------------------------------*/

typedef   unsigned char tCharMap [256/(sizeof(unsigned char)*8)]   ;

struct tToken ;

struct tTokenTable
    {
    void *	    pCompilerInfo ; /* stores tables of the compiler , !!!must be first item!!! */
    SV *            _perlsv ;         /**< The perl reference to this structure */
    const char *    sName ;	    /* name of syntax */
    const char *    sRootNode ;	    /* name of root node */
    tCharMap	    cStartChars ;   /* for every vaild start char there is one bit set */
    tCharMap	    cAllChars   ;   /* for every vaild char there is one bit set */
    struct tToken * pTokens ;	    /* table with all tokens */
    int             numTokens ;	    /* number of tokens in above table */
    int		    bLSearch ;	    /* when set perform a linear, instead of a binary search */
    int		    nDefNodeType ;  /* either ntypCDATA or ntypText */
    struct tToken * pContainsToken ;/* pointer to the token that has a pContains defined (could be only one per table) */
    } ;

typedef struct tTokenTable tTokenTable ;
    



typedef struct tComponentConfig

    {
    SV *        _perlsv ;         /**< The perl reference to this structure */
    tMemPool *  pPool ;  /**< pool for memorymanagement */
    bool        bUseEnv ;           /**< Take configuration values out of the environment */
    bool        bUseRedirectEnv ;   /**< Take configuration values out of the environment. Remove REDIRECT_ prefix. */
    char *      sPackage ;
    char *      sTopInclude ;           /**< Include this text at the top of the page */
    unsigned    bDebug ;
    unsigned    bOptions ;
    int         nCleanup ;
    int         nEscMode ;
    int         nInputEscMode ;
    char *      sInputCharset ;
    int         bEP1Compat;
    char *      sCacheKey ;
    unsigned    bCacheKeyOptions;
    CV *        pExpiredFunc ;
    CV *        pCacheKeyFunc ;
    int         nExpiresIn ;
    char *      sExpiresFilename ;
    char *      sSyntax ;
    SV   *      pRecipe ;
    char *      sXsltstylesheet ;
    char *      sXsltproc ;
    char *      sCompartment ;
    SV *        pOpcodeMask ;   /* Opcode mask (if any) */
    } tComponentConfig ;


typedef struct tReqConfig
    {
    SV *        _perlsv ;           /**< The perl reference to this structure */
    tMemPool *  pPool ;             /**< pool for memorymanagement */
    bool        bUseEnv ;           /**< Take configuration values out of the environment */
    bool        bUseRedirectEnv ;   /**< Take configuration values out of the environment. Remove REDIRECT_ prefix. */
    CV *        pAllow ;
    CV *        pUriMatch ;
    char        cMultFieldSep ;
    AV *        pPathAV ;
    int         nOutputMode ;       /**< 0 = html 1 = xml */
    int         nOutputEscCharset ; /**< 0 = utf-8 (min) 1 = latin1 2 = latin2 */
    unsigned    bDebug ;
    unsigned    bOptions ;
    int         nSessionMode ;      /**< sets how to pass the session id, see smodeXXX constants */
    } tReqConfig ;

typedef struct tReqParam
    {
    SV *        _perlsv ;         /**< The perl reference to this structure */
    tMemPool *  pPool ;  /**< pool for memorymanagement */
    char *  sFilename ;
    char *  sUnparsedUri ;
    char *  sUri ;
    char *  sServerAddr ;	/**< protocol://server:port */
    char *  sPathInfo ;
    char *  sQueryInfo ;
    char *  sLanguage ;         /**< Language for the current request */
    HV *    pCookies ;          /**< Received Cookies */
    SV *    pCGISV ;            /**< CGI Object which hold upload data */
    } tReqParam ;

typedef struct tAppConfig
    {
    SV *        _perlsv ;         /**< The perl reference to this structure */
    tMemPool *  pPool ;  /**< pool for memorymanagement */
    char *  sAppName ;
    bool        bUseEnv ;           /**< Take configuration values out of the environment */
    bool        bUseRedirectEnv ;   /**< Take configuration values out of the environment. Remove REDIRECT_ prefix. */
    char *  sAppHandlerClass ;
    char *  sSessionHandlerClass ;
    HV *    pSessionArgs ;
    AV *    pSessionClasses ;
    char *  sSessionConfig ;
    char *  sCookieName ;
    char *  sCookieDomain ;
    char *  sCookiePath ;
    char *  sCookieExpires ;   /**< Argument given in config for cookie expires **/
    bool    bCookieSecure ;
    char *  sLog ;
    unsigned    bDebug ;
    char *  sMailhost ;
    char *  sMailhelo ;
    char *  sMailfrom ;
    bool    bMaildebug ;
    char *  sMailErrorsTo ;
    int     nMailErrorsLimit ;
    int     nMailErrorsResetTime ;
    int     nMailErrorsResendTime ;
    char *  sObjectBase ;
    char *  sObjectApp ;
    AV *    pObjectAddpathAV ;  /**< add to search path */
    AV *    pObjectReqpathAV ;  /**< search this directries for requested documents */
    char *  sObjectStopdir ;
    char *  sObjectFallback ;
    char *  sObjectHandlerClass ;
    } tAppConfig ;



typedef struct tComponentParam
    {
    SV *        _perlsv ;   /**< The perl reference to this structure */
    tMemPool *  pPool ;     /**< pool for memorymanagement */
    char *  sInputfile ;    /**< name of sourcefile */
    char *  sOutputfile ;   /**< name of outputfile */
    char *  sSubreq ;       /**< sub request uri */
    SV *    pInput ;
    SV *    pOutput ;
    char *  sSub ;          /* subroutine to call */
    int     nImport ;
    char *  sObject ;       /**< create an object */
    char *  sISA ;          /**< make this a base class */
    AV *    pErrArray ;     /**< return error messages in this hash */
    int     nFirstLine ;
    int     nMtime ;        /**< last modification time of pInput */
    AV *    pParam ;        /**< parameters passed via Execute */
    HV *    pFormHash;      /**< fdat for this component */
    AV *    pFormArray ;    /**< ffld for this component */
    HV *    pXsltParam ;    /**< parameter for xslt proc */    
    } tComponentParam ;


typedef struct tThreadData
    {
    SV *    _perlsv ;               /**< The perl reference to this structure */
    tPerlInterpreter * pPerlTHX ;   /* pointer to Perl interpreter */
    tMemPool *         pPool ;      /**< pool for memorymanagement */
    tMemPool *         pMainPool ;  /**< global pool. Only use during initialisation! */
    HV *    pApplications ;         /**< Hash with available applications */
    struct tReq *  pCurrReq ;       /**< Current running request if any */
    pid_t   nPid ;                  /**< process/thread id */

    /* --- Embperl special hashs/arrays --- */

    HV *    pEnvHash ;	 /* environment from CGI Script */
    HV *    pFormHash ;  /* Formular data */
    GV *    pFormHashGV ;  
    HV *    pFormSplitHash ;  /* Formular data split up at \t */
    HV *    pInputHash ; /* Data of input fields */
    AV *    pFormArray ; /* Fieldnames */
    GV *    pFormArrayGV ; 
    HV *    pHeaderHash ;/* http headers */
    SV *    pReqRV ;       /* the request object global */
    SV *    pAppRV ;       /* the application object global */
    AV *    pParamArray ;
    GV *    pParamArrayGV ;

    } tThreadData ;


typedef struct tApp
    {
    SV *            _perlsv ;         /**< The perl reference to this structure */
    tPerlInterpreter * pPerlTHX ;                  /* pointer to Perl interpreter */
    tMemPool *         pPool ;  /**< pool for memorymanagement */
    tThreadData *   pThread ;
    struct tReq *          pCurrReq ;      /**< Current running request if any */
    tAppConfig      Config ;        /**< application configuration data */
    FILEIO *        lfd  ;          /**< log file handle */

    HV *            pUserHash ;     /**< Session User data */
    SV *            pUserObj ;      /**< Session User object */
    HV *            pStateHash ;    /**< Session State data */
    SV *            pStateObj ;     /**< Session State object */
    HV *            pAppHash ;      /**< Session Application data */
    SV *            pAppObj ;       /**< Session Application object */

    int             nErrorsCount ;      /**< Number of errors */
    int             nErrorsLastTime ;   /**< Time last error has occured */
    int             nErrorsLastSendTime ;/**< Time last error was send via mail */
    
    } tApp ;


typedef struct tComponentOutput
    {
    SV *    _perlsv ;         /**< The perl reference to this structure */
    tMemPool *         pPool ;  /**< pool for memorymanagement */

    bool    bDisableOutput ;   /* no output is generated */

    struct tBuf *   pFirstBuf  ;    /* First buffer */
    struct tBuf *   pLastBuf   ;    /* Last written buffer */
    struct tBuf *   pFreeBuf   ;    /* List of unused buffers */
    struct tBuf *   pLastFreeBuf ;  /* End of list of unused buffers */

    char *          pMemBuf ;	    /* temporary output */
    char *          pMemBufPtr ;    /* temporary output */
    size_t          nMemBufSize ;   /* size of pMemBuf */
    size_t          nMemBufSizeFree;/* remaining space in pMemBuf */

    int     nMarker ;               /*  Makers for rollback output */

    FILEIO *  ofd  ;                /* output file descriptor */
    int	      no_ofd_close ;	    /* do not close output file handle, because it's ownd by perl */

    SV *    ofdobj ;	            /* perl object that is tied to stdout, if any */
    } tComponentOutput ;



struct tComponent
    {
    SV *    _perlsv ;         /**< The perl reference to this structure */
    tMemPool *         pPool ;  /**< pool for memorymanagement */

    tComponentConfig    Config ;    /**< request configuration data */
    tComponentParam     Param ;     /**< parameter passed to current request */
    tComponentOutput *  pOutput ;   /**< output channel for this component */
    tReq *              pReq ;

    bool    bReqRunning  ;	/* we are inside of a request */
    bool    bSubReq ;           /* This is a sub request (called inside an Embperl page) */
    int	    nInsideSub ;	/* Are we inside of a sub? */
    int	    bSubNotEmpty ;	/* Sub has some output */
    int	    bExit ;		/* We should exit the page */
    int	    nPathNdx ;		/* gives the index in the path where the current file is found */
    char *  sCWD ;              /**< Current working directory */
    char    sResetDir[PATH_MAX] ; /**< Reset directory to */
#ifdef WIN32
    char    nResetDrive ;       /**< Reset drive to */
#endif

    bool    bEP1Compat ;	/* run in Embperl 1.x compatible mode */    
    int     nPhase ;		/* which phase of the request we are in */

    /* --- source --- */
    char *  sSourcefile ;	/**< Contains the current sourefilename */
    char *  pBuf ;              /**< Contains a pointer to the start of the current source in memory */
    char *  pEndPos ;           /**< First byte after sourcebuffer */
    char *  pCurrPos ;	        /**< Current position in sourcebuffer */
    int     nSourceline ;       /**< Currentline in sourcefile */
    char *  pSourcelinePos ;    /**< Positon of nSourceline in sourcebuffer */
    char *  pLineNoCurrPos ;    /**< save pCurrPos for line no calculation */


    /* --- DomTree ---*/

    tNode	xDocument ;	/* Document node */
    tNode	xCurrNode ;	/* node that was last executed */
    tRepeatLevel nCurrRepeatLevel ; /* repeat level for node that was last executed */
    tIndex      nCurrCheckpoint ; /* next checkpoint that should be passed if execution order is unchanged (i.e. no loop/if) */
    tIndex	xCurrDomTree ;	/* DomTree we are currently working on */
    tIndex	xSourceDomTree ;/* DomTree which contains the source */

    struct tCacheItem * pOutputCache ;  /**< Cache which hold the final output */
    SV *                pOutputSV ;	/**< set if output is text and not a tree */
    struct tTokenTable *  pTokenTable ; /**< holds the current syntax */

    /* --- Escaping --- */

    struct tCharTrans * pCurrEscape ;   /* pointer to current escape table */
    struct tCharTrans * pNextEscape ;   /* pointer to next escape table (after end of block) */
    int                 nCurrEscMode ;  /* current active escape mode */
    int                 bEscModeSet ;   /* escape mode already set in this block */
    int                 bEscInUrl ;     /* we are inside an url */
    

    /* --- i/o filehandles --- */

    FILEIO *  ifd  ;      /* input file */
    SV *    ifdobj ;	/* perl object that is tied to stdin, if any */

    bool    bAppendToMainReq ; /* append output to main request */

    /* ------------------------ */

    struct tComponent *  pPrev ;  /* Component from which this one is called */

    /* ------------------------ */
    
    /* --- more infos for eval --- */

    int  bStrict ; /* aply use strict in each eval */

    char op_mask_buf[MAXO + 100]; /* save buffer for opcode mask - maxo shouldn't differ from MAXO but leave room anyway (see BOOT:)	*/

    char * sImportPackage ;     /**< name of caller macro that should be used to import new subs */
    HV *  pImportStash ;	/* stash for package, where new subs should be imported */
    HV *  pExportHash ;


    /* --- compiler --- */    

    char *  sCurrPackage ;      /**< Package name for current sourcefile */
    char *  sEvalPackage ;      /**< Package for eval (normally same sCurrPackage,
			             differs when running in a safe namespace */
    STRLEN  nEvalPackage ;      /**< Length of package name for eval */
    char *  sMainSub ;          /**< Name of sub to call when executing the current source */

    char * * pProg ;            /* pointer into currently compiled code */
    char * pProgRun ;           /* pointer into currently compiled run code */
    char * pProgDef ;           /* pointer into currently compiled define code */

    SV *   pCodeSV ;		/* contains currently compiled line */

    }  ;



    
    
struct tReq
    {
    SV *    _perlsv ;         /**< The perl reference to this structure */

    tPerlInterpreter * pPerlTHX ;                  /* pointer to Perl interpreter */
    tMemPool *         pPool ;  /**< pool for memorymanagement */

    request_rec * pApacheReq ;	/* apache request record */
    SV *          pApacheReqSV ;
    tApacheDirConfig * pApacheConfig ;

    tReq *        pPrevReq ;     /**< Stack in case a new request is startet, when a request is active */
  
    tReqConfig    Config ;    /**< request configuration data */
    tReqParam     Param ;     /**< request parameter data */
    tComponent    Component ;
    tApp *        pApp ;
    tThreadData * pThread ;

    int     nRequestCount ;     /**< increments by one on each request */
    time_t  nRequestTime ;      /**< time when request starts */

    int     nIOType ;
    
    int	    nSessionMgnt ;	/* how to retrieve the session id */
    char *  sSessionID ;        /**< stores session name and id for status session data */
    char *  sSessionUserID ;    /**< received id of user session data */
    char *  sSessionStateID ;   /**< received id of state session data */
    char *  sCookieExpires ;	/**< Time when cookie expires **/	

    int	    bExit ;	        /**< We should exit the request */
    long    nLogFileStartPos ;  /**< file position of logfile, when logfile started */

    int     bError  ;		/* Error has occured somewhere */
    AV *    pErrArray ; 	/* Errors to show on Error response */

    char    errdat1 [ERRDATLEN] ; /* Additional error information */
    char    errdat2 [ERRDATLEN] ;
    char    lastwarn [ERRDATLEN] ; /* last warning */
    SV *    pErrSV ;               /* in case error is an object it is copied to here */

    AV *    pDomTreeAV ; /* holds all DomTrees alocated during the request */
    AV *    pCleanupAV ; /* set all sv's that are conatined in that array to undef after the whole request */
    HV *    pCleanupPackagesHV ; /* packages that should be cleaned up at end of request */

    char *  sInitialCWD ;         /**< Reset directory to */
    
    AV *    pMessages ;
    AV *    pDefaultMessages ;
    
    /* --- for statistics --- */

    clock_t startclock ;
    I32     stsv_count ;

#if defined (_MDEBUG) && defined (WIN32)
    _CrtMemState MemCheckpoint ;             /* memory leak debugging */    
#endif    

#ifdef DMALLOC
    unsigned long MemCheckpoint ;             /* memory leak debugging */    
#endif    
    } ;


#endif
