/*###################################################################################
#
#   Embperl - Copyright (c) 1997-1999 Gerald Richter / ECOS
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


#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <memory.h>
#include <string.h>
#include <ctype.h>
#include <time.h>

#ifndef PERL_VERSION
#include <patchlevel.h>
#ifndef PERL_VERSION
#define PERL_VERSION PATCHLEVEL
#define PERL_SUBVERSION SUBVERSION
#endif
#endif


#if !defined(PERLIO_IS_STDIO) && PERL_VERSION < 8
#define PERLIO_IS_STDIO
#endif

#ifdef EP2
#define PERL_NO_GET_CONTEXT
#endif

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#undef AP_DEBUG

#ifdef APACHE
/* form mod_perl.h ->
 * perl hides it's symbols in libperl when these macros are 
 * expanded to Perl_foo
 * but some cause conflict when expanded in other headers files
 */
#undef S_ISREG
#undef DIR
#undef VOIDUSED
#undef pregexec
#undef pregfree
#undef pregcomp
#undef setregid
#undef setreuid
#undef sync
#undef my_memcmp
#undef RETURN
#undef die
#undef __attribute__
#undef isnan

#if defined(EPAPACHE_SSL) || defined(APACHE_SSL) 
#undef TRUE
#undef FALSE
#endif

#ifdef WIN32

#ifdef uid_t
#define apache_uid_t uid_t
#undef uid_t
#endif
#define uid_t apache_uid_t

#ifdef gid_t
#define apache_gid_t gid_t
#undef gid_t
#endif
#define gid_t apache_gid_t

#ifdef mode_t
#define apache_mode_t mode_t
#undef mode_t
#endif
#define mode_t apache_mode_t

#ifdef stat
#define apache_stat stat
#undef stat
#endif

#ifdef lstat
#define apache_lstat lstat
#undef lstat
#endif

#ifdef sleep
#define apache_sleep sleep
#undef sleep
#endif


#if PERL_VERSION >= 6

#ifdef opendir
#define apache_opendir opendir
#undef opendir
#endif

#ifdef readdir
#define apache_readdir readdir
#undef readdir
#endif

#ifdef closedir
#define apache_closedir closedir
#undef closedir
#endif

#ifdef crypt
#define apache_crypt crypt
#undef crypt
#endif

#ifndef WIN32
#ifdef errno
#define apache_errno errno
#undef errno
#endif
#endif

#endif /* endif PERL_VERSION >= 6 */ 

#endif /* endif WIN32 */

#include <httpd.h>
#include <http_config.h>
#include <http_protocol.h>
#include <http_log.h>
#if MODULE_MAGIC_NUMBER >= 19980713
#include "ap_compat.h"
#elif MODULE_MAGIC_NUMBER >= 19980413
#include "compat.h"
#endif

#ifdef APACHE2
#include <apr_strings.h>
#endif

#endif

#ifdef WIN32
#define PATH_MAX _MAX_DIR
#endif

#ifndef PATH_MAX
#define PATH_MAX 512
#endif


#include "eptypes.h"
#include "epnames.h"


#if defined (_MDEBUG) && defined (WIN32)
#define _CRTDBG_MAP_ALLOC
#undef malloc
#undef calloc
#undef realloc
#undef free
#include <crtdbg.h>
#endif

#ifdef DMALLOC
#define DMALLOC_FUNC_CHECK 
#include "dmalloc.h"
#endif

#ifdef EP2
#include "epdom.h"
#include "eppublic.h"
#include "epdat2.h"
#include "eppriv.h"
#else
#include "epdat.h"
#endif
#include "embperl.h"



/* ---- from epmain.c ----- */

                     
#define nInitialScanOutputSize 2048

int Init          (int          nIOType,
                   const char * sLogFile,
                   int          nDebugDefault) ;

int ResetHandler (/*in*/ SV * pApacheReqSV) ;

int Term (void) ;

int ExecuteReq (/*i/o*/ register req * r,
                /*in*/  SV *           pReqSV) ;


int embperl_SendHttpHeader (/*i/o*/ register req * r) ;

char * LogError        (/*i/o*/ register req * r,
			/*in*/  int   rc) ;
char * LogErrorParam   (/*i/o*/ struct tApp * a,
			/*in*/ int   rc,
                        /*in*/ const char * errdata1,
                        /*in*/ const char * errdata2) ;

void CommitError (/*i/o*/ register req * r) ;
void RollbackError (/*i/o*/ register req * r) ;

int ProcessBlock	(/*i/o*/ register req * r,
			 /*in*/  int	 nBlockStart,
			 /*in*/  int	 nBlockSize,
                         /*in*/  int     nBlockNo) ;
void NewEscMode (/*i/o*/ register req * r,
			           SV * pSV) ;


int AddMagicAV (/*i/o*/ register req * r,
		/*in*/ char *     sVarName,
                /*in*/ MGVTBL *   pVirtTab) ;


/* ---- from epio.c ----- */


/*
    Datastructure for buffering output
*/

struct tBuf
    {
    struct tBuf *   pNext ;     /* Next buffer  */
    int             nSize ;     /* Size in bytes */
    int             nMarker ;   /* nesting level */
    int             nCount ;    /* output count including this buffer */
    } ;



/* i/o functions */


int OpenInput (/*i/o*/ register req * r,
			/*in*/ const char *  sFilename) ;
int CloseInput (/*i/o*/ register req * r) ;
int iread (/*i/o*/ register req * r,
			/*in*/ void * ptr,
                        /*in*/ size_t size) ;
char * igets (/*i/o*/ register req * r,
			/*in*/ char * s,
                        /*in*/ int    size) ;

int ReadHTML (/*i/o*/ register req * r,
	      /*in*/    char *    sInputfile,
              /*in*/    size_t *  nFileSize,
              /*out*/   SV   * *  ppBuf) ;


int OpenOutput (/*i/o*/ register req * r,
			/*in*/ const char *  sFilename) ;
int CloseOutput (/*i/o*/ tReq *             r, tComponentOutput * pOutput) ;
int owrite (/*i/o*/ register req * r,
			/*in*/ const void * ptr, 
                        /*in*/ size_t size) ;
void oflush (/*i/o*/ register req * r) ;
void oputc (/*i/o*/ register req * r,
			/*in*/ char c) ;
int oputs (/*i/o*/ register req * r,
			/*in*/ const char *  str) ;

void OutputToMemBuf (/*i/o*/ register req * r,
			/*in*/ char *  pBuf,
                     /*in*/ size_t  nBufSize) ;
char * OutputToStd (/*i/o*/ register req * r) ;


             
struct tBuf *   oBegin (/*i/o*/ register req * r) ;
void oRollback (/*i/o*/ register req * r,
			struct tBuf *   pBuf) ;
void oRollbackOutput (/*i/o*/ register req * r,
			struct tBuf *   pBuf) ;
void oCommit (/*i/o*/ register req * r,
			struct tBuf *   pBuf) ;
void oCommitToMem (/*i/o*/ register req * r,
			struct tBuf *   pBuf,
                   char *          pOut) ;

int GetContentLength (/*i/o*/ register req * r) ;

int OpenLog  (/*i/o*/  tApp * a) ;
int CloseLog (/*i/o*/  tApp * a) ;
int FlushLog (/*i/o*/  tApp * a) ;
int lprintf  (/*i/o*/ tApp * a,
	      /*in*/ const char *  sFormat,
              /*in*/ ...) ;
int lwrite   (/*i/o*/  tApp * a,
	      /*in*/  const void * ptr, 
              /*in*/  size_t size) ;

long GetLogFilePos (/*i/o*/  tApp * a) ;
int GetLogHandle   (/*i/o*/  tApp * a) ;

/* Memory Allocation */

void _free          (/*i/o*/ register req * r,
			     void * p) ;
void * _malloc      (/*i/o*/ register req * r, size_t  size) ;
void * _realloc     (/*i/o*/ register req * r,  void * ptr, size_t oldsize, size_t  size) ;
char * _memstrcat   (/*i/o*/ register req * r,
			     const char *s, ...) ;
char * _ep_strdup   (/*i/o*/ register req * r,
                     /*in*/  const char * str) ;
char * _ep_strndup  (/*i/o*/ register req * r,
                     /*in*/  const char *   str,
                     /*in*/  int            len) ;


/* ---- from epchar.c ----- */


/*
    Character Translation
*/

struct tCharTrans
    {
    char    c ;
    char *  sHtml ;
    } ;


extern struct tCharTrans Char2Html [] ;
extern struct tCharTrans Char2HtmlLatin2 [] ;
extern struct tCharTrans Char2HtmlMin [] ;
extern struct tCharTrans Char2Url  [] ; 
extern struct tCharTrans Char2XML  [] ; 
extern struct tCharTrans Html2Char [] ;
extern int sizeHtml2Char ;

#ifndef EP2
/* ---- from epcmd.c ----- */



int SearchCmd (/*i/o*/ register req * r,
			/*in*/  const char *    sCmdName,
                         /*in*/  int             nCmdLen,
                         /*in*/  const char *    sArg,
                         /*in*/  int             bIgnore,
                         /*out*/ struct tCmd * * ppCmd) ;

int ProcessCmd (/*i/o*/ register req * r,
			/*in*/ struct tCmd *  pCmd,
                        /*in*/ const char *    sArg) ;


SV * SplitFdat     (/*i/o*/ register req * r,
                           /*in*/  SV ** ppSVfdat,
                           /*out*/ SV ** ppSVerg,
                           /*in*/  char * pName,
                           /*in*/  STRLEN nlen) ;

#endif

/* ---- from eputil.c ----- */

const char * strnstr (/*in*/ const char *   pString,
                             /*in*/ const char *   pSubString,
			     /*in*/ int            nMax) ;

char * GetHashValue (/*in*/  tReq *         r,
                     /*in*/  HV *           pHash,
                     /*in*/  const char *   sKey,
                     /*in*/  int            nMaxLen,
                     /*out*/ char *         sValue) ;

char * GetHashValueLen (/*in*/  tReq *         r,
                        /*in*/  HV *           pHash,
                        /*in*/  const char *   sKey,
                        /*in*/  int            nLen,
                        /*in*/  int            nMaxLen,
                        /*out*/ char *         sValue) ;

IV    GetHashValueInt  (/*in*/  pTHX_
                        /*in*/  HV *           pHash,
                        /*in*/  const char *   sKey,
                        /*in*/  IV            nDefault) ;

UV    GetHashValueUInt (/*in*/  tReq *         r,
                        /*in*/  HV *           pHash,
                        /*in*/  const char *   sKey,
                        /*in*/  UV            nDefault) ;

#define GetHashValuePtr(r,pHash,sKey,nDefault) (void *)GetHashValueUInt(r,pHash,sKey,(UV)nDefault)

char * GetHashValueStr (/*in*/  pTHX_
                        /*in*/  HV *           pHash,
                        /*in*/  const char *   sKey,
                        /*in*/  char *         sDefault) ;

char * GetHashValueStrDup (/*in*/  pTHX_
                           /*in*/  tMemPool *     pPool,
                           /*in*/  HV *           pHash,
                           /*in*/  const char *   sKey,
                           /*in*/  char *         sDefault) ;

char * GetHashValueStrDupA (/*in*/  pTHX_
                           /*in*/  HV *           pHash,
                           /*in*/  const char *   sKey,
                           /*in*/  char *         sDefault) ;

SV * GetHashValueSVinc    (/*in*/  tReq *         r,
                           /*in*/  HV *           pHash,
                           /*in*/  const char *   sKey,
                           /*in*/  SV *         sDefault) ;

SV * GetHashValueSV       (/*in*/  tReq *         r,
                           /*in*/  HV *           pHash,
                           /*in*/  const char *   sKey) ;

void GetHashValueStrOrHash (/*in*/  tReq *         r,
                            /*in*/  HV *           pHash,
                            /*in*/  const char *   sKey,
                            /*out*/ char * *       sValue,
                            /*out*/ HV * *         pHV) ;

int GetHashValueHREF      (/*in*/  req *          r,
                           /*in*/  HV *           pHash,
                           /*in*/  const char *   sKey,
                           /*out*/ HV * *         ppHV) ;

int GetHashValueCREF      (/*in*/  req *          r,
                           /*in*/  HV *           pHash,
                           /*in*/  const char *   sKey,
                           /*out*/ CV * *         ppCV) ;
enum tHashItemType
    {
    hashtstr,
    hashtint,
    hashtsv
    } ;

SV * CreateHashRef   (/*in*/  tReq *         r,
                        /*in*/  char *   sKey, ...) ;

void SetHashValueStr   (/*in*/  tReq *         r,
                        /*in*/  HV *           pHash,
                        /*in*/  const char *   sKey,
                        /*in*/  char *         sValue) ;

void SetHashValueInt   (/*in*/  tReq *         r,
                        /*in*/  HV *           pHash,
                        /*in*/  const char *   sKey,
                        /*in*/  IV             nValue) ;



const char * GetHtmlArg (/*in*/  const char *    pTag,
                         /*in*/  const char *    pArg,
                         /*out*/ int *           pLen) ;

void OutputToHtml (/*i/o*/ register req * r,
 		   /*i/o*/ const char *   sData) ;

void OutputEscape (/*i/o*/ register req * r,
 		   /*in*/  const char *   sData,
 		   /*in*/  int            nDataLen,
 		   /*in*/  struct tCharTrans *   pEscTab,
 		   /*in*/  char           cEscChar) ;
SV * Escape	  (/*i/o*/ register req * r,
 		   /*in*/  const char *   sData,
 		   /*in*/  int            nDataLen,
 		   /*in*/  int            nEscMode,
 		   /*in*/  struct tCharTrans *   pEscTab,
 		   /*in*/  char           cEscChar) ;

int TransHtml (/*i/o*/ register req * r,
		/*i/o*/ char *         sData,
		/*in*/   int           nLen) ;

void TransHtmlSV (/*i/o*/ register req * r,
		  /*i/o*/ SV *           pSV) ;

int GetLineNo (/*i/o*/ register req * r) ;

int GetLineNoOf (/*i/o*/ register req * r,
               /*in*/   char * pPos) ;

#ifndef WIN32
#define strnicmp strncasecmp
#define stricmp strcasecmp
#else
#define strnicmp _strnicmp
#define stricmp _stricmp
#endif

void Dirname (/*in*/ const char * filename,
              /*out*/ char *      dirname,
              /*in*/  int         size) ;

char * sstrdup (/*in*/ tReq * r,
                /*in*/ char *   pString) ;


int SetSubTextPos (/*i/o*/ register req * r,
		   /*in*/  const char *   sName,
		   /*in*/  int		  sPos) ;

int GetSubTextPos (/*i/o*/ register req * r,
		   /*in*/  const char *   sName) ;


void ClearSymtab (/*i/o*/ register req * r,
		  /*in*/  const char *    sPackage,
                  /*in*/  int		 bDebug) ;

void UndefSub    (/*i/o*/ register req * r,
		  /*in*/  const char *    sName, 
		  /*in*/  const char *    sPackage) ;

void ChdirToSource (/*i/o*/ register req * r,
                    /*in*/  char *         sInputfile) ;

void embperl_SetCWDToFile  (/*i/o*/ register req * r,
                            /*in*/  const char *         sFilename) ;
char * embperl_File2Abs  (/*i/o*/ register req * r,
                        /*in*/  tMemPool *     pPool,
                        /*in*/  const char *         sFilename) ;
char * embperl_PathSearch    (/*i/o*/ register req * r,
                            /*in*/  tMemPool *     pPool,
                            /*in*/  const char *         sFilename,
                            /*in*/  int            nPathNdx) ;
char * embperl_PathStr      (/*i/o*/ register req * r,
                            /*in*/  const char *         sFilename) ;
AV * embperl_String2AV (/*in*/ tApp * pApp, 
                        /*in*/ const char * sData,
                        /*in*/ const char * sSeparator) ;
HV * embperl_String2HV (/*in*/ tApp * a, 
                        /*in*/ const char * sData,
                        /*in*/ char cSeparator,
                        /*in*/ HV *  pHV) ;


/* ---- from epeval.c ----- */

int CallCV  (/*i/o*/ register req * r,
		    /*in*/  const char *  sArg,
                    /*in*/  CV *          pSub,
                    /*in*/  int           flags,
                    /*out*/ SV **         pRet) ;

int EvalOnly           (/*i/o*/ register req * r,
			/*in*/  const char *  sArg,
                        /*in*/  SV **         ppSV,
                        /*in*/  int           flags,
  		        /*in*/  const char *  sName) ;

int EvalDirect (/*i/o*/ register req *	r,
		/*in*/  SV *		pArg,
                /*in*/  int		numArgs,
                /*in*/  SV **		pArgs) ;

int EvalNum (/*i/o*/ register req * r,
	     /*in*/  char *        sArg,
             /*in*/  int           nFilepos,
             /*out*/ int *         pNum) ;            

int Eval (/*i/o*/ register req * r,
	  /*in*/  const char *  sArg,
          /*in*/  int           nFilepos,
          /*out*/ SV **         pRet) ;

#ifdef EP2
int EvalStore (/*i/o*/ register req * r,
	      /*in*/  const char *  sArg,
	      /*in*/  int           nFilepos,
	      /*out*/ SV **         pRet) ;
#endif

int EvalTrans (/*i/o*/ register req * r,
	       /*in*/  char *   sArg,
               /*in*/  int      nFilepos,
               /*out*/ SV **    pRet) ;

int EvalTransFlags (/*i/o*/ register req * r,
 		    /*in*/  char *   sArg,
                   /*in*/  int      nFilepos,
                   /*in*/  int      flags,
                   /*out*/ SV **    pRet) ;

int EvalTransOnFirstCall (/*i/o*/ register req * r,
			  /*in*/  char *   sArg,
                          /*in*/  int      nFilepos,
                          /*out*/ SV **    pRet) ;            

int EvalBool (/*i/o*/ register req * r,
	      /*in*/  char *        sArg,
              /*in*/  int           nFilepos,
              /*out*/ int *         pTrue) ;

int EvalSub (/*i/o*/ register req * r,
	    /*in*/  const char *  sArg,
	    /*in*/  int           nFilepos,
	    /*in*/  const char *  sName) ;

int EvalMain (/*i/o*/ register req *  r) ;

int EvalConfig (/*i/o*/ tApp *          a,
		/*in*/  SV *            pSV, 
                /*in*/  int		numArgs,
                /*in*/  SV **		pArgs,
		/*in*/  const char *    sContext, 
		/*out*/ CV **           pCV) ;

int EvalRegEx  (/*i/o*/ tApp *          a,
		/*in*/  char *          sRegex, 
		/*in*/  const char *    sContext, 
		/*out*/ CV **           ppCV) ;


#ifdef EP2
int CallStoredCV  (/*i/o*/ register req * r,
		    /*in*/  const char *  sArg,
                    /*in*/  CV *          pSub,
                    /*in*/  int           numArgs,
                    /*in*/  SV **         pArgs,
                    /*in*/  int           flags,
                    /*out*/ SV **         pRet) ;
#endif



/* ---- from epdbg.c ----- */

int SetupDebugger (/*i/o*/ register req * r) ;



#ifdef EP2
#include "ep2.h"
#endif

/* memory debugging stuff */

#ifdef DMALLOC


SV * AddDMallocMagic (/*in*/ SV *	pSV,
		      /*in*/ char *     sText,
		      /*in*/ char *     sFile,
		      /*in*/ int        nLine) ;

#undef newSV
#define newSV(len) AddDMallocMagic(Perl_newSV(aTHX_ (len)), "newSV  ", __FILE__, __LINE__) 

#undef newSViv
#define newSViv(i) AddDMallocMagic(Perl_newSViv(aTHX_ (i)), "newSViv  ", __FILE__, __LINE__) 
#define newSVivDBG1(i,txt) AddDMallocMagic(Perl_newSViv(aTHX_ (i)), txt, __FILE__, __LINE__) 


#undef newSVnv
#define newSVnv(n) AddDMallocMagic(Perl_newSVnv(aTHX_ (n)), "newSVnv  ", __FILE__, __LINE__) 

#undef newSVpv
#define newSVpv(s,len) AddDMallocMagic(Perl_newSVpv(aTHX_ (s),(len)), "newSVpv  ", __FILE__, __LINE__) 

#undef newSVpvn
#define newSVpvn(s,len) AddDMallocMagic(Perl_newSVpvn(aTHX_ (s),(len)), "newSVpvn  ", __FILE__, __LINE__) 

#undef newSVrv
#define newSVrv(rv,c) AddDMallocMagic(Perl_newSVrv(aTHX_ (rv),(c)), "newSVrv  ", __FILE__, __LINE__) 

#undef newSVsv
#define newSVsv(sv) AddDMallocMagic(Perl_newSVsv(aTHX_ (sv)), "newSVsv  ", __FILE__, __LINE__) 


#undef newSVpvf2
#define newSVpvf2(sv) AddDMallocMagic((sv), "newSVsvf  ", __FILE__, __LINE__) ; SvTAINTED_off (sv) 



#undef perl_get_sv
#undef perl_get_cv
#undef perl_get_hv
#undef perl_get_av


#define perl_get_sv(name,create) AddDMallocMagic(Perl_get_sv(aTHX_ name,create), "perl_get_sv  ", __FILE__, __LINE__) 
#define perl_get_cv(name,create) (CV *)AddDMallocMagic((SV *)Perl_get_cv(aTHX_ name,create), "perl_get_cv  ", __FILE__, __LINE__) 
#define perl_get_hv(name,create) (HV *)AddDMallocMagic((SV *)Perl_get_hv(aTHX_ name,create), "perl_get_hv  ", __FILE__, __LINE__) 
#define perl_get_av(name,create) (AV *)AddDMallocMagic((SV *)Perl_get_av(aTHX_ name,create), "perl_get_av  ", __FILE__, __LINE__) 

#undef newHV
#define newHV() (HV *)AddDMallocMagic((SV *)Perl_newHV(aTHX), "newHV  ", __FILE__, __LINE__) 

#undef newAV
#define newAV() (AV *)AddDMallocMagic((SV *)Perl_newAV(aTHX), "newAV  ", __FILE__, __LINE__) 


#else

#define newSVivDBG1(i,txt) newSViv(i)
#define newSVpvf2(sv)

#endif
