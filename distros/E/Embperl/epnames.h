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
#   $Id: epnames.h 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################*/

/*
    Avoid namespace conflict with other packages
*/


#define oBegin                 EMBPERL2_oBegin            
#define oRollback              EMBPERL2_oRollback         
#define oRollbackOutput        EMBPERL2_oRollbackOutput
#define oCommit                EMBPERL2_oCommit           
#define oCommitToMem           EMBPERL2_oCommitToMem
#define OpenInput              EMBPERL2_OpenInput         
#define CloseInput             EMBPERL2_CloseInput        
#define ReadInputFile          EMBPERL2_ReadInputFile        
#define iread                  EMBPERL2_iread             
#define igets                  EMBPERL2_igets             
#define OpenOutput             EMBPERL2_OpenOutput        
#define CloseOutput            EMBPERL2_CloseOutput       
#define oputs                  EMBPERL2_oputs             
#define owrite                 EMBPERL2_owrite            
#define oputc                  EMBPERL2_oputc             
#define OpenLog                EMBPERL2_OpenLog           
#define CloseLog               EMBPERL2_CloseLog          
#define FlushLog               EMBPERL2_FlushLog          
#define lprintf                EMBPERL2_lprintf           
#define lwrite                 EMBPERL2_lwrite            
#define _free                  EMBPERL2__free             
#define _malloc                EMBPERL2__malloc           
#define LogError               EMBPERL2_LogError          
#define OutputToHtml           EMBPERL2_OutputToHtml      
#define OutputEscape           EMBPERL2_OutputEscape      
#define Eval                   EMBPERL2_Eval              
#define EvalNum                EMBPERL2_EvalNum           
#define EvalBool               EMBPERL2_EvalBool           
#define EvalConfig             EMBPERL2_EvalConfig
#define stristr                EMBPERL2_stristr           
#define strlower               EMBPERL2_strlower          
#define TransHtml              EMBPERL2_TransHtml         
#define TransHtmlSV            EMBPERL2_TransHtmlSV
#define GetHtmlArg             EMBPERL2_GetHtmlArg        
#define GetHashValueLen        EMBPERL2_GetHashValueLen   
#define GetHashValue           EMBPERL2_GetHashValue      
#define GetHashValueInt           EMBPERL2_GetHashValueInt
#define GetHashValueCREF           EMBPERL2_GetHashValueCREF      
#define GetHashValueHREF           EMBPERL2_GetHashValueHREF      
#define GetHashValueSV           EMBPERL2_GetHashValueSV      
#define GetHashValueSVinc           EMBPERL2_GetHashValueSVinc      
#define GetHashValueStrOrHash           EMBPERL2_GetHashValueStrOrHash      
#define GetHashValueUInt           EMBPERL2_GetHashValueUInt
#define GetHashValueStrDup     EMBPERL2_GetHashValueStrDup      
#define SetHashValueStr        EMBPERL2_SetHashValueStr      
#define CreateHashRef          EMBPERL2_CreateHashRef
#define ChdirToSource		EMBPERL2_ChdirToSource
#define Char2XML              EMBPERL2_Char2XML
#define Char2Html              EMBPERL2_Char2Html         
#define Html2Char              EMBPERL2_Html2Char         
#define sizeHtml2Char          EMBPERL2_sizeHtml2Char     
#define OutputToMemBuf         EMBPERL2_OutputToMemBuf
#define OutputToStd            EMBPERL2_OutputToStd
#define GetLogHandle           EMBPERL2_GetLogHandle
#define SearchCmd              EMBPERL2_SearchCmd     
#define ProcessCmd             EMBPERL2_ProcessCmd    
#define ProcessSub             EMBPERL2_ProcessSub
#define Char2Url               EMBPERL2_Char2Url            
#define CmdTab                 EMBPERL2_CmdTab              
#define EvalTrans              EMBPERL2_EvalTrans           
#define EvalMain               EMBPERL2_EvalMain
#define EvalTransFlags         EMBPERL2_EvalTransFlags
#define EvalTransOnFirstCall   EMBPERL2_EvalTransOnFirstCall           
#define EvalSub                EMBPERL2_EvalSub
#define EvalOnly               EMBPERL2_EvalOnly
#define CallCV                 EMBPERL2_CallCV
#define GetContentLength       EMBPERL2_GetContentLength    
#define GetLogFilePos          EMBPERL2_GetLogFilePos       
#define ReadHTML               EMBPERL2_ReadHTML            
#define ScanCmdEvalsInString   EMBPERL2_ScanCmdEvalsInString
#define EvalDirect             EMBPERL2_EvalDirect
#define GetLineNo              EMBPERL2_GetLineNo
#define GetLineNoOf            EMBPERL2_GetLineNoOf
#define Dirname                EMBPERL2_Dirname
#define CommitError            EMBPERL2_CommitError
#define RollbackError          EMBPERL2_RollbackError
#define _memstrcat             EMBPERL2__memstrcat
#define _ep_strdup             EMBPERL2__ep_strdup
#define _ep_strndup            EMBPERL2__ep_strndup
#define _realloc               EMBPERL2__realloc
#define ExecuteReq             EMBPERL2_ExecuteReq     
#define FreeConfData           EMBPERL2_FreeConfData   
#define FreeRequest            EMBPERL2_FreeRequest    
#define GetHashValueInt        EMBPERL2_GetHashValueInt
#define GetHashValueStr        EMBPERL2_GetHashValueStr
#define Init                   EMBPERL2_Init           
#define ResetHandler           EMBPERL2_ResetHandler   
#define SetupConfData          EMBPERL2_SetupConfData  
#define SetupFileData          EMBPERL2_SetupFileData  
#define SetupRequest           EMBPERL2_SetupRequest   
#define Term                   EMBPERL2_Term           
#define sstrdup                EMBPERL2_sstrdup        
#define strnstr                EMBPERL2_strnstr
#define ClearSymtab	       EMBPERL2_ClearSymtab
#define UndefSub	       EMBPERL2_UndefSub
#define _ep_memdup             EMBPERL2__ep_memdup
#define ProcessBlock           EMBPERL2_ProcessBlock
#define NewEscMode             EMBPERL2_NewEscMode
#define GetSubTextPos          EMBPERL2_GetSubTextPos
#define SetSubTextPos          EMBPERL2_SetSubTextPos
#define SetupDebugger          EMBPERL2_SetupDebugger
#define GetFileData            EMBPERL2_GetFileData
#define SplitFdat              EMBPERL2_SplitFdat
#define AddMagicAV             EMBPERL2_AddMagicAV

#define InitialReq             EMBPERL2_InitialReq
#define pCurrReq               EMBPERL2_pCurrReq

#define ArrayAdd		    EMBPERL2_ArrayAdd		   
#define ArrayClone		    EMBPERL2_ArrayClone		   
#define ArrayFree		    EMBPERL2_ArrayFree		   
#define ArrayGetSize		    EMBPERL2_ArrayGetSize		   
#ifndef DMALLOC
#define ArrayNew		    EMBPERL2_ArrayNew		   
#define ArrayNewZero		    EMBPERL2_ArrayNewZero
#endif
#define ArraySet		    EMBPERL2_ArraySet		   
#define ArraySetSize		    EMBPERL2_ArraySetSize		   
#define ArraySub		    EMBPERL2_ArraySub		   
#define Attr_selfValue		    EMBPERL2_Attr_selfValue		   
#define BuildTokenTable		    EMBPERL2_BuildTokenTable		   
#define CallStoredCV		    EMBPERL2_CallStoredCV		   
#define DefaultTokenTable	    EMBPERL2_DefaultTokenTable	   
#define DomInit			    EMBPERL2_DomInit			   
#define DomStats		    EMBPERL2_DomStats		   
#define DomTree_alloc		    EMBPERL2_DomTree_alloc		   
#define DomTree_checkpoint	    EMBPERL2_DomTree_checkpoint	   
#define DomTree_clone		    EMBPERL2_DomTree_clone		   
#define DomTree_delete		    EMBPERL2_DomTree_delete		   
#define DomTree_discardAfterCheckpoint   EMBPERL2_DomTree_discardAfterCheckpoint
#define DomTree_mvtTab		    EMBPERL2_DomTree_mvtTab		   
#define DomTree_new		    EMBPERL2_DomTree_new		   
#define DomTree_selfCheckpoint	    EMBPERL2_DomTree_selfCheckpoint	   
#define DomTree_selfDiscardAfterCheckpoint   EMBPERL2_DomTree_selfDiscardAfterCheckpoint  
#define Element_selfGetAttribut     EMBPERL2_Element_selfGetAttribut    
#define Element_selfGetNthAttribut  EMBPERL2_Element_selfGetNthAttribut 
#define Element_selfRemoveAttribut  EMBPERL2_Element_selfRemoveAttribut 
#define Element_selfSetAttribut     EMBPERL2_Element_selfSetAttribut    
#define EvalStore		    EMBPERL2_EvalStore		   
#define NdxStringFree		    EMBPERL2_NdxStringFree		   
#define NodeList_toString	    EMBPERL2_NodeList_toString	   
#define Node_appendChild	    EMBPERL2_Node_appendChild	   
#define Node_childsText		    EMBPERL2_Node_childsText		   
#define Node_cloneNode		    EMBPERL2_Node_cloneNode		   
#define Node_insertAfter	    EMBPERL2_Node_insertAfter	   
#define Node_insertAfter_CDATA      EMBPERL2_Node_insertAfter_CDATA     
#define Node_newAndAppend	    EMBPERL2_Node_newAndAppend	   
#define Node_nextSibling	    EMBPERL2_Node_nextSibling	   
#define Node_previousSibling	    EMBPERL2_Node_previousSibling	   
#define Node_removeChild	    EMBPERL2_Node_removeChild	   
#define Node_replaceChildWithCDATA  EMBPERL2_Node_replaceChildWithCDATA 
#define Node_replaceChildWithNode   EMBPERL2_Node_replaceChildWithNode  
#define Node_replaceChildWithUrlDATA    EMBPERL2_Node_replaceChildWithUrlDATA
#define Node_selfCloneNode	    EMBPERL2_Node_selfCloneNode	   
#define Node_selfCondCloneNode      EMBPERL2_Node_selfCondCloneNode     
#define Node_selfExpand		    EMBPERL2_Node_selfExpand		   
#define Node_selfLastChild	    EMBPERL2_Node_selfLastChild	   
#define Node_selfNextSibling	    EMBPERL2_Node_selfNextSibling	   
#define Node_selfNthChild	    EMBPERL2_Node_selfNthChild	   
#define Node_selfPreviousSibling    EMBPERL2_Node_selfPreviousSibling   
#define Node_selfRemoveChild	    EMBPERL2_Node_selfRemoveChild	   
#define Node_toString		    EMBPERL2_Node_toString		   
#define Node_toString2		    EMBPERL2_Node_toString2		   
#define ParseFile		    EMBPERL2_ParseFile
#define String2NdxInc		    EMBPERL2_String2NdxInc		   
#define String2UniqueNdx	    EMBPERL2_String2UniqueNdx
#define StringAdd		    EMBPERL2_StringAdd		   
#define StringFree		    EMBPERL2_StringFree		   
#define StringNew		    EMBPERL2_StringNew		   
#define dom_free		    EMBPERL2_dom_free		   
#define dom_malloc		    EMBPERL2_dom_malloc		   
#define dom_realloc		    EMBPERL2_dom_realloc		   
#define mydie			    EMBPERL2_mydie			   
#define nCheckpointCache	    EMBPERL2_nCheckpointCache	   
#define nCheckpointCacheMask	    EMBPERL2_nCheckpointCacheMask	   
#define nInitialNodePadSize	    EMBPERL2_nInitialNodePadSize	   
#define pDomTrees		    EMBPERL2_pDomTrees		   
#define pFreeDomTrees		    EMBPERL2_pFreeDomTrees		   
#define pStringTableArray	    EMBPERL2_pStringTableArray	   
#define pStringTableHash	    EMBPERL2_pStringTableHash	   
#define str_free		    EMBPERL2_str_free		   
#define str_malloc		    EMBPERL2_str_malloc		   
#define str_realloc		    EMBPERL2_str_realloc		   
#define xCheckpointCache	    EMBPERL2_xCheckpointCache	   
#define xDocument		    EMBPERL2_xDocument		   
#define xDocumentFraq		    EMBPERL2_xDocumentFraq		   
#define xDomTreeAttr		    EMBPERL2_xDomTreeAttr		   
#define xNoName			    EMBPERL2_xNoName			   
#define xOrderIndexAttr		    EMBPERL2_xOrderIndexAttr		   
#define Escape		            EMBPERL2_Escape		   
#define embperl_ApacheAddModule     EMBPERL2_ApacheAddModule 
#define EvalRegEx                   EMBPERL2_EvalRegEx          
#define GetHashValueStrDupA	    EMBPERL2_GetHashValueStrDupA
#define GetSessionID	            EMBPERL2_GetSessionID	   
#define LogErrorParam	            EMBPERL2_LogErrorParam	   
#define Node_selfForceLevel	    EMBPERL2_Node_selfForceLevel
#define Node_selfLevelItem	    EMBPERL2_Node_selfLevelItem
#define dom_free_size	            EMBPERL2_dom_free_size	   
#define SetHashValueInt	            EMBPERL2_SetHashValueInt	   
#define pCacheItems	            EMBPERL2_pCacheItems	   
#define pCachesToRelease            EMBPERL2_pCachesToRelease   
#define pProviders                  EMBPERL2_pProviders         


#ifdef sv_undef
#undef sv_undef 
#endif
#define sv_undef ep_sv_undef

 
#ifndef PERL_VERSION
#include <patchlevel.h>
#define PERL_VERSION PATCHLEVEL
#define PERL_SUBVERSION SUBVERSION
#endif

#ifndef pTHX_
#define pTHX_
#endif
#ifndef pTHX
#define pTHX
#endif
#ifndef aTHX_
#define aTHX_
#endif
#ifndef aTHX
#define aTHX
#endif
#ifndef dTHX
#define dTHX
#define dTHXsem
#else
#define dTHXsem dTHX ;
#endif

#ifndef XSprePUSH
#define XSprePUSH (sp = PL_stack_base + ax - 1)
#endif

#ifndef SvUTF8
#define SvUTF8(x) 0
#endif

#if PERL_VERSION >= 5

#ifndef rs
#define rs PL_rs
#endif
#ifndef beginav
#define beginav PL_beginav
#endif
#ifndef defoutgv
#define defoutgv PL_defoutgv
#endif
#ifndef defstash
#define defstash PL_defstash
#endif
#ifndef egid
#define egid PL_egid
#endif
#ifndef endav
#define endav PL_endav
#endif
#ifndef envgv
#define envgv PL_envgv
#endif
#ifndef euid
#define euid PL_euid
#endif
#ifndef gid
#define gid PL_gid
#endif
#ifndef hints
#define hints PL_hints
#endif
#ifndef incgv
#define incgv PL_incgv
#endif
#ifndef pidstatus
#define pidstatus PL_pidstatus
#endif
#ifndef scopestack_ix
#define scopestack_ix PL_scopestack_ix
#endif
#ifndef siggv
#define siggv PL_siggv
#endif
#ifndef uid
#define uid PL_uid
#endif
#ifndef warnhook
#define warnhook PL_warnhook
#endif
#ifndef dowarn
#define dowarn PL_dowarn
#endif
#ifndef diehook
#define diehook PL_diehook
#endif
#ifndef perl_destruct_level
#define perl_destruct_level PL_perl_destruct_level 
#endif
#ifndef sv_count
#define sv_count PL_sv_count
#endif
#ifndef sv_objcount
#define sv_objcount PL_sv_objcount
#endif
#ifndef op_mask
#define op_mask PL_op_mask
#endif
#ifndef maxo
#define maxo PL_maxo
#endif


#if PERL_SUBVERSION >= 50 || PERL_VERSION >= 6

#ifndef na
#define na PL_na
#endif
#ifndef tainted
#define tainted PL_tainted
#endif

#endif

#define SvGETMAGIC_P4(x)


#else  /* PERL_VERSION > 5 */

#ifndef ERRSV
#define ERRSV GvSV(errgv)
#endif

#ifndef dTHR
#define dTHR
#endif

#define SvGETMAGIC(x) STMT_START { if (SvGMAGICAL(x)) mg_get(x); } STMT_END
#define SvGETMAGIC_P4(x) SvGETMAGIC(x)

#endif /* PERL_VERSION > 5 */


#ifdef APACHE

#ifdef WIN32

#undef uid_t
#ifdef apache_uid_t
#define uid_t apache_uid_t
#undef apache_uid_t
#endif

#undef gid_t
#ifdef apache_gid_t
#define gid_t apache_gid_t
#undef apache_gid_t
#endif

#undef mode_t
#ifdef apache_mode_t
#define gid_t apache_mode_t
#undef apache_mode_t
#endif

#ifdef xxxapache_stat
#undef stat
#define stat apache_stat
#undef apache_stat
#endif

#ifdef apache_sleep
#undef sleep
#define sleep apache_sleep
#undef apache_sleep
#endif

#if PERL_VERSION >= 6

#ifdef apache_opendir
#undef opendir
#define opendir apache_opendir
#undef apache_opendir
#endif

#ifdef apache_readdir
#undef readdir
#define readdir apache_readdir
#undef apache_readdir
#endif

#ifdef apache_closedir
#undef closedir
#define closedir apache_closedir
#undef apache_closedir
#endif

#ifdef apache_crypt
#undef crypt
#define crypt apache_crypt
#undef apache_crypt
#endif

#endif /* endif PERL_IS_5_6 */

#endif /* endif WIN32 */

#endif /* APACHE */


#ifndef INT2PTR

/* taken from perl 5.6.1 perl.h */

#if (IVSIZE == PTRSIZE) && (UVSIZE == PTRSIZE)
#  define PTRV			UV
#  define INT2PTR(any,d)	(any)(d)
#else
#  if PTRSIZE == LONGSIZE 
#    define PTRV		unsigned long
#  else
#    define PTRV		unsigned
#  endif
#  define INT2PTR(any,d)	(any)(PTRV)(d)
#endif
#define NUM2PTR(any,d)	(any)(PTRV)(d)
#define PTR2IV(p)	INT2PTR(IV,p)
#define PTR2UV(p)	INT2PTR(UV,p)
#define PTR2NV(p)	NUM2PTR(NV,p)
#if PTRSIZE == LONGSIZE 
#  define PTR2ul(p)	(unsigned long)(p)
#else
#  define PTR2ul(p)	INT2PTR(unsigned long,p)	
#endif

#endif


/* make some defines to use same type in Apache 1 & Apache 2 */

#ifndef APACHE2

#define apr_pstrdup         ap_pstrdup
#define apr_palloc          ap_palloc
#define apr_pcalloc         ap_pcalloc
#define apr_pool_t          pool
#define apr_array_header_t  array_header
#define apr_table_entry_t   table_entry
#define apr_table_elts      table_elts
#define apr_table_get       ap_table_get
#define apr_table_do        ap_table_do
#define apr_table_set       ap_table_set
#define apr_table_add       ap_table_add

#endif


/* define some types, that are necessary in non Apache mode and will be passed as dummy parameters */

#ifndef APACHE

typedef void request_rec ;
typedef void server_rec ;
typedef void apr_pool_t ;

#endif


#ifdef APACHE
#ifdef APACHE2
#define APLOG_STATUSCODE  0,
#else
#define APLOG_STATUSCODE
#endif
#endif

/* perl 5.13.10+ does not allow assigning to GvCV anymore */

#ifndef GvCV_set
#define GvCV_set(gv,cv)  (GvGP(gv)->gp_cv=(cv))
#endif
