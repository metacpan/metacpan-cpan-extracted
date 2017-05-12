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
#   $Id: epnames.h,v 1.30.2.1 2003/01/22 08:23:35 richter Exp $
#
###################################################################################*/

/*
    Avoid namespace conflict with other packages
*/


#define oBegin                 EMBPERL_oBegin            
#define oRollback              EMBPERL_oRollback         
#define oRollbackOutput        EMBPERL_oRollbackOutput
#define oCommit                EMBPERL_oCommit           
#define oCommitToMem           EMBPERL_oCommitToMem
#define OpenInput              EMBPERL_OpenInput         
#define CloseInput             EMBPERL_CloseInput        
#define ReadInputFile          EMBPERL_ReadInputFile        
#define iread                  EMBPERL_iread             
#define igets                  EMBPERL_igets             
#define OpenOutput             EMBPERL_OpenOutput        
#define CloseOutput            EMBPERL_CloseOutput       
#define oputs                  EMBPERL_oputs             
#define owrite                 EMBPERL_owrite            
#define oputc                  EMBPERL_oputc             
#define OpenLog                EMBPERL_OpenLog           
#define CloseLog               EMBPERL_CloseLog          
#define FlushLog               EMBPERL_FlushLog          
#define lprintf                EMBPERL_lprintf           
#define lwrite                 EMBPERL_lwrite            
#define _free                  EMBPERL__free             
#define _malloc                EMBPERL__malloc           
#define LogError               EMBPERL_LogError          
#define OutputToHtml           EMBPERL_OutputToHtml      
#define OutputEscape           EMBPERL_OutputEscape      
#define Eval                   EMBPERL_Eval              
#define EvalNum                EMBPERL_EvalNum           
#define EvalBool               EMBPERL_EvalBool           
#define EvalConfig             EMBPERL_EvalConfig
#define stristr                EMBPERL_stristr           
#define strlower               EMBPERL_strlower          
#define TransHtml              EMBPERL_TransHtml         
#define TransHtmlSV            EMBPERL_TransHtmlSV
#define GetHtmlArg             EMBPERL_GetHtmlArg        
#define GetHashValueLen        EMBPERL_GetHashValueLen   
#define GetHashValue           EMBPERL_GetHashValue      
#define GetHashValueStrDup     EMBPERL_GetHashValueStrDup      
#define SetHashValueStr        EMBPERL_SetHashValueStr      
#define Char2Html              EMBPERL_Char2Html         
#define Html2Char              EMBPERL_Html2Char         
#define sizeHtml2Char          EMBPERL_sizeHtml2Char     
#define OutputToMemBuf         EMBPERL_OutputToMemBuf
#define OutputToStd            EMBPERL_OutputToStd
#define GetLogHandle           EMBPERL_GetLogHandle
#define SearchCmd              EMBPERL_SearchCmd     
#define ProcessCmd             EMBPERL_ProcessCmd    
#define ProcessSub             EMBPERL_ProcessSub
#define Char2Url               EMBPERL_Char2Url            
#define CmdTab                 EMBPERL_CmdTab              
#define EvalTrans              EMBPERL_EvalTrans           
#define EvalMain               EMBPERL_EvalMain
#define EvalTransFlags         EMBPERL_EvalTransFlags
#define EvalTransOnFirstCall   EMBPERL_EvalTransOnFirstCall           
#define EvalSub                EMBPERL_EvalSub
#define EvalOnly               EMBPERL_EvalOnly
#define CallCV                 EMBPERL_CallCV
#define GetContentLength       EMBPERL_GetContentLength    
#define GetLogFilePos          EMBPERL_GetLogFilePos       
#define ReadHTML               EMBPERL_ReadHTML            
#define ScanCmdEvalsInString   EMBPERL_ScanCmdEvalsInString
#define EvalDirect             EMBPERL_EvalDirect
#define GetLineNo              EMBPERL_GetLineNo
#define GetLineNoOf            EMBPERL_GetLineNoOf
#define Dirname                EMBPERL_Dirname
#define CommitError            EMBPERL_CommitError
#define RollbackError          EMBPERL_RollbackError
#define _memstrcat             EMBPERL__memstrcat
#define _ep_strdup             EMBPERL__ep_strdup
#define _ep_strndup            EMBPERL__ep_strndup
#define _realloc               EMBPERL__realloc
#define ExecuteReq             EMBPERL_ExecuteReq     
#define FreeConfData           EMBPERL_FreeConfData   
#define FreeRequest            EMBPERL_FreeRequest    
#define GetHashValueInt        EMBPERL_GetHashValueInt
#define GetHashValueStr        EMBPERL_GetHashValueStr
#define Init                   EMBPERL_Init           
#define ResetHandler           EMBPERL_ResetHandler   
#define SetupConfData          EMBPERL_SetupConfData  
#define SetupFileData          EMBPERL_SetupFileData  
#define SetupRequest           EMBPERL_SetupRequest   
#define Term                   EMBPERL_Term           
#define sstrdup                EMBPERL_sstrdup        
#define strnstr                EMBPERL_strnstr
#define ClearSymtab	       EMBPERL_ClearSymtab
#define UndefSub	       EMBPERL_UndefSub
#define _ep_memdup             EMBPERL__ep_memdup
#define ProcessBlock           EMBPERL_ProcessBlock
#define NewEscMode             EMBPERL_NewEscMode
#define GetSubTextPos          EMBPERL_GetSubTextPos
#define SetSubTextPos          EMBPERL_SetSubTextPos
#define SetupDebugger          EMBPERL_SetupDebugger
#define GetFileData            EMBPERL_GetFileData
#define SplitFdat              EMBPERL_SplitFdat
#define AddMagicAV             EMBPERL_AddMagicAV

#define InitialReq             EMBPERL_InitialReq
#define pCurrReq               EMBPERL_pCurrReq

#define ArrayAdd		    EMBPERL_ArrayAdd		   
#define ArrayClone		    EMBPERL_ArrayClone		   
#define ArrayFree		    EMBPERL_ArrayFree		   
#define ArrayGetSize		    EMBPERL_ArrayGetSize		   
#define ArrayNew		    EMBPERL_ArrayNew		   
#define ArraySet		    EMBPERL_ArraySet		   
#define ArraySetSize		    EMBPERL_ArraySetSize		   
#define ArraySub		    EMBPERL_ArraySub		   
#define Attr_selfValue		    EMBPERL_Attr_selfValue		   
#define BuildTokenTable		    EMBPERL_BuildTokenTable		   
#define CallStoredCV		    EMBPERL_CallStoredCV		   
#define DefaultTokenTable	    EMBPERL_DefaultTokenTable	   
#define DomInit			    EMBPERL_DomInit			   
#define DomStats		    EMBPERL_DomStats		   
#define DomTree_alloc		    EMBPERL_DomTree_alloc		   
#define DomTree_checkpoint	    EMBPERL_DomTree_checkpoint	   
#define DomTree_clone		    EMBPERL_DomTree_clone		   
#define DomTree_delete		    EMBPERL_DomTree_delete		   
#define DomTree_discardAfterCheckpoint   EMBPERL_DomTree_discardAfterCheckpoint
#define DomTree_mvtTab		    EMBPERL_DomTree_mvtTab		   
#define DomTree_new		    EMBPERL_DomTree_new		   
#define DomTree_selfCheckpoint	    EMBPERL_DomTree_selfCheckpoint	   
#define DomTree_selfDiscardAfterCheckpoint   EMBPERL_DomTree_selfDiscardAfterCheckpoint  
#define Element_selfGetAttribut     EMBPERL_Element_selfGetAttribut    
#define Element_selfGetNthAttribut  EMBPERL_Element_selfGetNthAttribut 
#define Element_selfRemoveAttribut  EMBPERL_Element_selfRemoveAttribut 
#define Element_selfSetAttribut     EMBPERL_Element_selfSetAttribut    
#define EvalStore		    EMBPERL_EvalStore		   
#define NdxStringFree		    EMBPERL_NdxStringFree		   
#define NodeList_toString	    EMBPERL_NodeList_toString	   
#define Node_appendChild	    EMBPERL_Node_appendChild	   
#define Node_childsText		    EMBPERL_Node_childsText		   
#define Node_cloneNode		    EMBPERL_Node_cloneNode		   
#define Node_insertAfter	    EMBPERL_Node_insertAfter	   
#define Node_insertAfter_CDATA      EMBPERL_Node_insertAfter_CDATA     
#define Node_newAndAppend	    EMBPERL_Node_newAndAppend	   
#define Node_nextSibling	    EMBPERL_Node_nextSibling	   
#define Node_previousSibling	    EMBPERL_Node_previousSibling	   
#define Node_removeChild	    EMBPERL_Node_removeChild	   
#define Node_replaceChildWithCDATA  EMBPERL_Node_replaceChildWithCDATA 
#define Node_replaceChildWithNode   EMBPERL_Node_replaceChildWithNode  
#define Node_replaceChildWithUrlDATA    EMBPERL_Node_replaceChildWithUrlDATA
#define Node_selfCloneNode	    EMBPERL_Node_selfCloneNode	   
#define Node_selfCondCloneNode      EMBPERL_Node_selfCondCloneNode     
#define Node_selfExpand		    EMBPERL_Node_selfExpand		   
#define Node_selfLastChild	    EMBPERL_Node_selfLastChild	   
#define Node_selfNextSibling	    EMBPERL_Node_selfNextSibling	   
#define Node_selfNthChild	    EMBPERL_Node_selfNthChild	   
#define Node_selfPreviousSibling    EMBPERL_Node_selfPreviousSibling   
#define Node_selfRemoveChild	    EMBPERL_Node_selfRemoveChild	   
#define Node_toString		    EMBPERL_Node_toString		   
#define Node_toString2		    EMBPERL_Node_toString2		   
#define ParseFile		    EMBPERL_ParseFile
#define String2NdxInc		    EMBPERL_String2NdxInc		   
#define StringAdd		    EMBPERL_StringAdd		   
#define StringFree		    EMBPERL_StringFree		   
#define StringNew		    EMBPERL_StringNew		   
#define dom_free		    EMBPERL_dom_free		   
#define dom_malloc		    EMBPERL_dom_malloc		   
#define dom_realloc		    EMBPERL_dom_realloc		   
#define mydie			    EMBPERL_mydie			   
#define nCheckpointCache	    EMBPERL_nCheckpointCache	   
#define nCheckpointCacheMask	    EMBPERL_nCheckpointCacheMask	   
#define nInitialNodePadSize	    EMBPERL_nInitialNodePadSize	   
#define pDomTrees		    EMBPERL_pDomTrees		   
#define pFreeDomTrees		    EMBPERL_pFreeDomTrees		   
#define pStringTableArray	    EMBPERL_pStringTableArray	   
#define pStringTableHash	    EMBPERL_pStringTableHash	   
#define str_free		    EMBPERL_str_free		   
#define str_malloc		    EMBPERL_str_malloc		   
#define str_realloc		    EMBPERL_str_realloc		   
#define xCheckpointCache	    EMBPERL_xCheckpointCache	   
#define xDocument		    EMBPERL_xDocument		   
#define xDocumentFraq		    EMBPERL_xDocumentFraq		   
#define xDomTreeAttr		    EMBPERL_xDomTreeAttr		   
#define xNoName			    EMBPERL_xNoName			   
#define xOrderIndexAttr		    EMBPERL_xOrderIndexAttr		   
#define Escape		            EMBPERL_Escape		   
#define GetSessionID		    EMBPERL_GetSessionID 
 
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
#ifndef sv_undef
#define sv_undef PL_sv_undef
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

#define ep_sv_undef sv_undef

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

#ifdef apache_stat
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

