/*###################################################################################
#
#   Embperl - Copyright (c) 1997-2001 Gerald Richter / ECOS
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#   For use with Apache httpd and mod_perl, see also Apache copyright.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: epdat.h,v 1.37 2001/11/02 10:03:48 richter Exp $
#
###################################################################################*/



#ifdef EP2
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
/*  Processor							   */
/*								   */
/*-----------------------------------------------------------------*/


typedef struct tProcessor
    {
    int nProcessorNo ;
    const char *    sName ;
    int (* pPreCompiler)            (/*in*/  tReq *	  r,
				     /*in*/  struct tProcessor * pProcessor,
				     /*in*/  tDomTree **  ppDomTree,
				     /*in*/  SV **        ppPreCompResult,
				     /*out*/ SV **        ppCompResult) ;
    int (* pCompiler)               (/*in*/  tReq *	  r,
				     /*in*/  struct tProcessor * pProcessor,
				     /*in*/  tDomTree **  ppDomTree,
				     /*in*/  SV **        ppPreCompResult,
				     /*out*/ SV **        ppCompResult) ;
    int (* pPreExecuter)            (/*in*/  tReq *	  r,
				     /*in*/  struct tProcessor * pProcessor,
				     /*in*/  tDomTree **  pDomTree,
				     /*in*/  SV **        ppPreCompResult,
				     /*in*/  SV **        ppCompResult) ;
    int (* pExecuter)               (/*in*/  tReq *	  r,
				     /*in*/  struct tProcessor * pProcessor,
				     /*in*/  tDomTree **  pDomTree,
				     /*in*/  SV **        ppPreCompResult,
				     /*in*/  SV **        ppCompResult,
				     /*out*/ SV **        ppExecResult) ;

    const char *    sCacheKey ;	    /* literal to add to key for cache */
    CV *	    pCacheKeyCV ;   /* CV to call and add result to key for cache */
    tCacheOptions   bCacheKeyOptions ;
    double          nOutputExpiresIn ;
    CV *            pOutputExpiresCV ;

    struct tProcessor * pNext ;
    } tProcessor ;

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

typedef   unsigned char tCharMap [256/(sizeof(unsigned char)*8)]   ;

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
    struct tTokenTable *    pFollowedBy;/* table of tokens that can follow this one */
    struct tTokenTable *    pInside ;	/* table of tokens that can apear inside this one */
    struct tToken      *    pStartTag ;	/* token that contains definition for the start of the current token */
    struct tToken      *    pEndTag ;	/* token that contains definition for the end of the current token */
    const char *	    sParseTimePerlCode ; /* perl code that is executed when this token is parsed, %% is replaced by the value of the current attribute */
    } ;        

struct tTokenTable
    {
    void *	    pCompilerInfo ; /* stores tables of the compiler , must be first item */
    const char *    sName ;	    /* name of syntax */
    tCharMap	    cStartChars ;   /* for every vaild start char there is one bit set */
    tCharMap	    cAllChars   ;   /* for every vaild char there is one bit set */
    struct tToken * pTokens ;	    /* table with all tokens */
    int             numTokens ;	    /* number of tokens in above table */
    int		    bLSearch ;	    /* when set perform a linear, instead of a binary search */
    int		    nDefNodeType ;  /* either ntypCDATA or ntypText */
    struct tToken * pContainsToken ;/* pointer to the token that has a pContains defined (could be only one per table) */
    } ;

typedef struct tTokenTable tTokenTable ;
    
#else

typedef void * tTokenTable ;


#endif



/*-----------------------------------------------------------------*/
/*								   */
/*  Per (directory) configuration data				   */
/*								   */
/*-----------------------------------------------------------------*/


typedef struct tConf
    {
    HV *    pReqParameter ; /* parameters passed to this request */
    int     bDebug ;	    /* Debugging options */
    int     bOptions ;	    /* Options */
    char *  sPackage ;	    /* Packagename */
    char *  sLogFilename ;  /* name of logfile */
    char *  sVirtLogURI ;      /* uri for access virtual log file */
    SV *    pOpcodeMask ;   /* Opcode mask (if any) */
    int     nEscMode ;      /* default escape mode */
    char *  sCookieName ;   /* Name to use for cookie */
    char *  sCookieExpires ; /* cookie expiration time */
    char *  sCookieDomain ; /* domain patter for which the cookie should be returned */
    char *  sCookiePath ;   /* path to which cookie should be returned */
    char    cMultFieldSep ;
    char *  pOpenBracket  ;
    char *  pCloseBracket ;
#ifdef EP2
    bool    bEP1Compat ;    /* run in Embperl 1.x compatible mode */
    tProcessor ** pProcessor ;   /* [array] processors used to process the file */
    char *  sCacheKey ;    /* Key used to store expires setting */
    CV *	    pCacheKeyCV ;   /* CV to call and add result to key for cache */
    tCacheOptions   bCacheKeyOptions ;
    double  nExpiresIn ;   /* Data expiers at */
    CV *    pExpiresCV ;   /* sub that is called to determinate expiration */
    char *  sRecipe ;      /* name of recipe used to process the current file */
#endif    
    char *  sPath ;	    /* file search path */
    char *  sReqFilename ;  /* filename of original request */
    } tConf ;

/*-----------------------------------------------------------------*/
/*								   */
/*  Per sourcefile data 					   */
/*								   */
/*-----------------------------------------------------------------*/


typedef struct tFile
    {
    char *  sSourcefile ;   /* Name of sourcefile */
    double  mtime ;	    /* last modification time of file */
    size_t  nFilesize ;	    /* size of File */
    SV *    pBufSV ;        /* SV that contains the file content */
    bool    bKeep ;	    /* set true if you want to keep file in memory */
    
    HV *    pCacheHash ;    /* Hash containing CVs to precompiled subs */

    char *  sCurrPackage ;  /* Package of file  */
    STRLEN  nCurrPackage ;  /* Package of file (length) */
    HV *    pExportHash ;   /* exportable Macros */

    int	    nFirstLine ;    /* First line number of sourcefile */

    struct tFile * pNext2Free ;  /* Next file that has to be freed after the request */
    } tFile ;

/*-----------------------------------------------------------------*/
/*								   */
/*  Per sourcebuffer data 					   */
/*								   */
/*-----------------------------------------------------------------*/


typedef struct tSrcBuf
    {
    tFile * pFile ;             /* pointer source file/package specific data */
    char *  pBuf ;	        /* Buffer which holds the html source file */
    char *  pCurrPos ;	        /* Current position in html file */
    char *  pCurrStart ;        /* Current start position of html tag / eval expression */
    char *  pEndPos ;	        /* end of html file */
    int     nBlockNo ;          /* Block number where we are currently */
    char *  pCurrTag ;	        /* Current start position of html tag */
    int     nSourceline ;       /* Currentline in sourcefile */
    char *  pSourcelinePos ;    /* Positon of nSourceline in sourcefile */
    char *  pLineNoCurrPos ;    /* save pCurrPos for line no calculation */
    char *  sEvalPackage ;      /* Package for eval (normaly same sCurrPackage,
			           differs when running in a safe namespace */
    STRLEN  nEvalPackage ;      /* Package for eval (length) */
    } tSrcBuf ;
    

/*-----------------------------------------------------------------*/
/*								   */
/*  Commandtypes         					   */
/*								   */
/*-----------------------------------------------------------------*/
   
enum tCmdType
    {
    cmdNorm     = 1,
    cmdIf       = 2,
    cmdEndif    = 4,
    cmdWhile    = 8,
    cmdTable    = 16,
    cmdTablerow = 32,
    cmdTextarea = 64,
    cmdDo       = 128,
    cmdForeach  = 256,
    cmdSub      = 512,

    cmdAll      = 1023
    } ;

enum tCmdNo
    {
    cnNop,       
    cnTable,
    cnTr,
    cnDir,
    cnMenu,
    cnOl,
    cnUl,
    cnDl,
    cnSelect,
    cnDo,
    cnForeach
    } ;

/*-----------------------------------------------------------------*/
/*								   */
/*  Commands             					   */
/*								   */
/*-----------------------------------------------------------------*/
   

typedef struct tCmd
    {
    const char *    sCmdName ;     /* Commandname */
    int            ( *pProc)(/*i/o*/ register req * r, /*in*/ const char *   sArg) ;   /* pointer to the procedure */
    bool            bPush ;         /* Push current state? */
    bool            bPop ;          /* Pop last state? */
    enum tCmdType   nCmdType ;      /* Type of the command  */
    bool            bScanArg ;      /* is it nessesary to scan the command arg */
    bool            bSaveArg ;      /* is it nessesary to save the command arg for later use */
    enum tCmdNo     nCmdNo ;        /* number of command to catch mismatch in start/end */
    int             bDisableOption ; /* option bit which disables this cmd */
    bool            bHtml ;          /* this is an html tag */
    } tCmd ;


/*-----------------------------------------------------------------*/
/*								   */
/*  Command/HTML-Stack         					   */
/*								   */
/*-----------------------------------------------------------------*/
   

typedef struct tStackEntry
    {
    enum tCmdType   nCmdType ;      /* Type of the command which the pushed the entry on the stack */
    char *          pStart ;        /* Startposition for loops */
    int             nBlockNo ;      /* Block number where the startposition is */
    long            bProcessCmds ;  /* Process corresponding cmds */
    int             nResult ;       /* Result of Command which starts the block */
    char *          sArg ;          /* Argument of Command which starts the block */
    SV *            pSV ;           /* Additional Data */
    SV *            pSV2 ;          /* Additional Data */
    struct tBuf *   pBuf;          /* Output buf for table rollback          */
    struct tCmd *   pCmd ;          /* pointer to command infos */
    struct tStackEntry * pNext ;      /* pointer to next one on stack/free list */
    } tStackEntry ;


/*-----------------------------------------------------------------*/
/*								   */
/*  Table-Stack         					   */
/*								   */
/*-----------------------------------------------------------------*/
   

typedef struct tTableStackEntry
    {
    int             nResult ;       /* Result of Command which starts the block */
    int             nCount ;        /* Count for tables, lists etc */
    int             nCountUsed ;    /* Count for tables, lists is used in Table  */
    int             nRow ;          /* Row Count for tables, lists etc */
    int             nRowUsed ;      /* Row Count for tables, lists is used in Table  */
    int             nCol ;          /* Column Count for tables, lists etc */
    int             nColUsed ;      /* Column Count for tables, lists is used in Table  */
    int             nMaxRow ;       /* maximum rows */
    int             nMaxCol ;       /* maximum columns */
    int             nTabMode;      /* table mode */
    int             bHead ;         /* this row contains a heading */
    int             bRowHead ;      /* the entire row is made of th tags */
    struct tTableStackEntry * pNext ;      /* pointer to next one on stack/free list */
    } tTableStackEntry ;

/*-----------------------------------------------------------------*/
/*								   */
/*  Stack-Pointer         					   */
/*								   */
/*-----------------------------------------------------------------*/


typedef struct tStackPointer

    {
    struct tStackEntry * pStack  ;      /* pointer to stacked entrys */
    struct tStackEntry * pStackFree  ;  /* pointer to currently unused entrys */

    struct tStackEntry State ;	        /* top of stack */
    } tStackPointer ;


typedef struct tTableStackPointer

    {
    struct tTableStackEntry * pStack  ;      /* pointer to stacked entrys */
    struct tTableStackEntry * pStackFree  ;  /* pointer to currently unused entrys */

    struct tTableStackEntry State ;	        /* top of stack */
    } tTableStackPointer ;

   
/*-----------------------------------------------------------------*/
/*								   */
/*  Per request data						   */
/*								   */
/*-----------------------------------------------------------------*/

#define ERRDATLEN 1024

#ifdef WIN32
#define pid_t int
#endif


struct tReq
    {
    SV *          pReqSV ;      /* The perl reference to this request structure */

    #ifdef APACHE
    request_rec * pApacheReq ;	/* apache request record */
    SV *          pApacheReqSV ;
    #endif

    pid_t nPid ;                /* process/thread id */
    
    tConf * pConf ;             /* pointer to configuration data */

    bool    bReqRunning  ;	/* we are inside of a request */
    int     bDebug ;		/* Debugging options */
    int     bOptions ;		/* Options */
    int     nIOType ;
    bool    bSubReq ;           /* This is a sub request (called inside an Embperl page) */
    char *  sSubName ;          /* subroutine to call */
    int	    nSessionMgnt ;	/* how to retrieve the session id */
    int	    nInsideSub ;	/* Are we inside of a sub? */
    int	    bExit ;		/* We should exit the page */
    int	    nPathNdx ;		/* gives the index in the path where the current file is found */

    char *  sSessionID ;        /* stores session name and id for status session data */
#ifdef EP2
    bool    bEP1Compat ;	/* run in Embperl 1.x compatible mode */    
    tPhase  nPhase ;		/* which phase of the request we are in */

    char *  sPathInfo ;
    char *  sQueryInfo ;
    
    /* --- DomTree ---*/

    tNode	xDocument ;	/* Document node */
    tNode	xCurrNode ;	/* node that was last executed */
    tRepeatLevel nCurrRepeatLevel ; /* repeat level for node that was last executed */
    tIndex      nCurrCheckpoint ; /* next checkpoint that should be passed if execution order is unchanged (i.e. no loop/if) */
    tIndex	xCurrDomTree ;	/* DomTree we are currently working on */
    tIndex	xSourceDomTree ;/* DomTree which contains the source */
#endif
    struct tTokenTable *  pTokenTable ; /* holds the current syntax */

    /* --- Source in memory --- */

    tSrcBuf   Buf ;            /* Buffer */
    tSrcBuf * pBufStack  ;     /* pointer to buffer stack */
    tSrcBuf * pBufStackFree  ; /* pointer to buffer stack free list*/

    tFile * pFiles2Free ;	/* files that has to be freed after the request (only valid in main request) */

    /* --- command handling --- */

    tCmd *              pCurrCmd ;	/* Current cmd which is excuted */

    /* --- Stacks --- */

    tStackPointer       CmdStack  ;      /* Stack for if, while, etc. */
    tStackPointer       HtmlStack ;      /* Stack for table etc. */
    tTableStackPointer  TableStack ;     /* Stack for table */

    /* --- Tablehandling --- */

    int nTabMode    ;	 /* mode for next table (only takes affect after next <TABLE> */
    int nTabMaxRow  ;	 /* maximum rows for next table (only takes affect after next <TABLE> */
    int nTabMaxCol  ;	 /* maximum columns for next table (only takes affect after next <TABLE> */

    /* --- Escaping --- */

    struct tCharTrans * pCurrEscape ;   /* pointer to current escape table */
    struct tCharTrans * pNextEscape ;   /* pointer to next escape table (after end of block) */
    int                 nEscMode ;      /* escape mode set by the user */
    int                 nCurrEscMode ;  /* current active escape mode */
    int                 bEscModeSet ;   /* escape mode already set in this block */
    int                 bEscInUrl ;     /* we are inside an url */
    
    /* --- memory management --- */

    size_t nAllocSize ;             /*  Alloced memory for debugging */

    /* --- buffering output */

    struct tBuf *   pFirstBuf  ;    /* First buffer */
    struct tBuf *   pLastBuf   ;    /* Last written buffer */
    struct tBuf *   pFreeBuf   ;    /* List of unused buffers */
    struct tBuf *   pLastFreeBuf ;  /* End of list of unused buffers */

    char *          pMemBuf ;	    /* temporary output */
    char *          pMemBufPtr ;    /* temporary output */
    size_t          nMemBufSize ;   /* size of pMemBuf */
    size_t          nMemBufSizeFree;/* remaining space in pMemBuf */

    int     nMarker ;               /*  Makers for rollback output */

    /* --- i/o filehandles --- */

    #ifdef PerlIO
    PerlIO *  ifd  ;    /* input file */
    PerlIO *  ofd  ;    /* output file */
    PerlIO *  lfd  ;    /* log file */
    #else
    FILE *  ifd  ;      /* input file */
    FILE *  ofd  ;      /* output file */
    FILE *  lfd  ;      /* log file */
    #endif

    SV *    ofdobj ;	/* perl object that is tied to stdout, if any */
    SV *    ifdobj ;	/* perl object that is tied to stdin, if any */

    long    nLogFileStartPos ; /* file position of logfile, when logfile started */
    char *  sOutputfile ;      /* name of output file */
    bool    bAppendToMainReq ; /* append output to main request */
    bool    bDisableOutput ;   /* no output is generated */

    SV *    pOutData ;
    SV *    pInData ;
    
    /* ------------------------ */

    tReq *  pNext ;  /* Next free one */
    tReq *  pLastReq ;  /* Request from which this one is called */

    /* ------------------------ */
    
    /* --- keep track of errors --- */

    bool    bError  ;		/* Error has occured somewhere */
    I32     nLastErrFill  ;	/* last size of error array */
    int     bLastErrState ;	/* last state of error flag */
    AV *    pErrArray ; 	/* Errors to show on Error response */
    AV *    pErrFill ;		/* AvFILL of pErrArray, index is nMarker */
    AV *    pErrState ; 	/* bError, index is nMarker  */

    /* Everything after here will not automaticly set to zero */
    int     zeroend ;

    char    errdat1 [ERRDATLEN] ; /* Additional error information */
    char    errdat2 [ERRDATLEN] ;
    char    lastwarn [ERRDATLEN] ; /* last warning */

    /* --- Embperl special hashs/arrays --- */

    HV *    pEnvHash ;	 /* environement from CGI Script */
    HV *    pFormHash ;  /* Formular data */
    HV *    pFormSplitHash ;  /* Formular data split up at \t */
    HV *    pInputHash ; /* Data of input fields */
    AV *    pFormArray ; /* Fieldnames */
    HV *    pUserHash ;  /* Session User data */
    HV *    pStateHash ; /* Session State data */
    HV *    pModHash ;   /* Module data */
    HV *    pHeaderHash ;/* http headers */
#ifdef EP2
    AV *    pDomTreeAV ; /* holds all DomTrees alocated during the request */
    AV *    pCleanupAV ; /* set all sv's that are conatined in that array to undef after the whole request */
#endif

    /* --- for statistics --- */

    clock_t startclock ;
    I32     stsv_count ;
    I32     stsv_objcount ;
    I32     lstsv_count ;
    I32     lstsv_objcount  ;
    int     numEvals ;
    int     numCacheHits ;

    /* --- more infos for eval --- */

    int  bStrict ; /* aply use strict in each eval */

    char op_mask_buf[MAXO + 100]; /* save buffer for opcode mask - maxo shouldn't differ from MAXO but leave room anyway (see BOOT:)	*/

    HV *  pImportStash ;	/* stash for package, where new macros should be imported */

#ifdef EP2
    
    char * * pProg ;            /* pointer into currently compiled code */
    char * pProgRun ;           /* pointer into currently compiled run code */
    char * pProgDef ;           /* pointer into currently compiled define code */

    SV *   pCodeSV ;		/* contains currently compiled line */
#endif

    } ;




#define EPMAINSUB   "_ep_main"
