/*###################################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2014 Gerald Richter
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: epcomp.c 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################*/


#include "ep.h"
#include "epmacro.h"

struct tEmbperlCmd
    {
    int             bValid ;
    const char * *  sPerlCode ;             /* perl code that should be inserted (maybe an array) */
    const char * *  sCompileTimePerlCode ;  /* perl code that should be directly executed (maybe an array) */
    const char *    sCompileTimePerlCodeEnd ;  /* perl code that should be directly executed at the end tag */
    const char *    sPerlCodeEnd ;          /* perl code that should be inserted at the end tag  */
    const char *    sStackName ;
    const char *    sPushStack ;
    const char *    sPopStack ;
    const char *    sMatchStack ;
    const char *    sStackName2 ;
    const char *    sPushStack2 ;
    const char *    sPopStack2 ;
    int		    numPerlCode ;
    int		    numCompileTimePerlCode ;
    int		    bRemoveNode ;
    int		    bPerlCodeRemove ;
    int		    bCompileChilds ;
    int		    nNodeType ;
    int		    nSwitchCodeType ;
    int		    bCallReturn ;
    const char *    sMayJump ;
    struct tEmbperlCmd * pNext ;
    } ;

typedef struct tEmbperlCmd tEmbperlCmd ;


struct tEmbperlCompilerInfo
    {
    tStringIndex nMaxEmbperlCmd ;
    tEmbperlCmd * pEmbperlCmds ;
    } ;

typedef struct tEmbperlCompilerInfo tEmbperlCompilerInfo ;

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_CompileInit                                                      */
/*                                                                          */
/*                                                                          */
/*                                                                          */
/* ------------------------------------------------------------------------ */


static int embperl_CompileInit (/*in*/ tApp * a,
                                /*out*/ tEmbperlCompilerInfo * * ppInfo)

    {
    epaTHX_
    tEmbperlCompilerInfo * pInfo = malloc (sizeof (tEmbperlCompilerInfo)) ;

    if (!pInfo)
	return rcOutOfMemory ;



    ArrayNewZero (a, &pInfo -> pEmbperlCmds, 256, sizeof (struct tEmbperlCmd)) ;
    ArraySet (a, &pInfo -> pEmbperlCmds, 0) ;
    pInfo -> nMaxEmbperlCmd = 1 ;
    *ppInfo = pInfo ;

    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_CompileInitItem                                                  */
/*                                                                          */
/*                                                                          */
/*                                                                          */
/* ------------------------------------------------------------------------ */

int embperl_CompileInitItem      (/*i/o*/ register req * r,
				  /*in*/  HV *           pHash,
				  /*in*/  int            nNodeName,
				  /*in*/  int            nNodeType,
				  /*in*/  int		 nTagSet,
				  /*in*/  void * *	 ppInfo)

    {
    epTHX_
    SV * * ppSV ;
    AV * pAV ;
    tEmbperlCmd *  pCmd ;
    tEmbperlCompilerInfo * pInfo = (tEmbperlCompilerInfo *)*ppInfo ;

    if (!pInfo)
	embperl_CompileInit (r -> pApp, (tEmbperlCompilerInfo * *)ppInfo) ;
    pInfo = (tEmbperlCompilerInfo *)*ppInfo ;
    


    ArraySet (r -> pApp, &pInfo -> pEmbperlCmds, nNodeName+1) ;

    if (pInfo -> nMaxEmbperlCmd < nNodeName)
	pInfo -> nMaxEmbperlCmd = nNodeName ;
    pCmd = &pInfo -> pEmbperlCmds[nNodeName] ;

    if (pCmd -> bValid)
        {
        tEmbperlCmd * pNewCmd ;
        if (pCmd -> bValid == nTagSet)
            return ok ;
        
        while (pCmd -> pNext)
            {
            if (pCmd -> bValid == nTagSet)
                return ok ;
            pCmd = pCmd -> pNext ;
            }

        if (pCmd -> bValid == nTagSet)
            return ok ;

        pNewCmd = malloc (sizeof (*pNewCmd)) ;
        pCmd -> pNext = pNewCmd ;
        pCmd = pNewCmd ;
        memset (pCmd, 0, sizeof(*pCmd)) ;
        }
    pCmd -> bValid = nTagSet ;

    ppSV = hv_fetch(pHash, "perlcode", 8, 0) ;  
    if (ppSV != NULL && *ppSV != NULL && 
        SvROK(*ppSV)  && SvTYPE((pAV = (AV *)SvRV(*ppSV))) == SVt_PVAV)
	{ /* Array reference  */
	int f = AvFILL(pAV) + 1 ;
        int i ;
        STRLEN l ;

        pCmd -> sPerlCode = malloc (f * sizeof (char *)) ;
        pCmd -> numPerlCode = f ;

        for (i = 0; i < f; i++)
	    {
	    ppSV = av_fetch (pAV, i, 0) ;
	    if (ppSV && *ppSV)
		pCmd -> sPerlCode[i] = strdup (SvPV (*ppSV, l)) ;
            else
		pCmd -> sPerlCode[i] = NULL ;
            }
        }
    else
        {
        if (ppSV)
            {
            STRLEN  l ; 
            
            pCmd -> sPerlCode = malloc (sizeof (char *)) ;
            pCmd -> numPerlCode = 1 ;
            pCmd -> sPerlCode[0] = sstrdup (r, SvPV (*ppSV, l)) ;
            }
        }
    

    ppSV = hv_fetch(pHash, "compiletimeperlcode", 19, 0) ;  
    if (ppSV != NULL && *ppSV != NULL && 
        SvROK(*ppSV) && SvTYPE((pAV = (AV *)SvRV(*ppSV))) == SVt_PVAV)
	{ /* Array reference  */
	int f = AvFILL(pAV) + 1 ;
        int i ;
        STRLEN l ;

        pCmd -> sCompileTimePerlCode = malloc (f * sizeof (char *)) ;
        pCmd -> numCompileTimePerlCode = f ;

        for (i = 0; i < f; i++)
	    {
	    ppSV = av_fetch (pAV, i, 0) ;
	    if (ppSV && *ppSV)
		pCmd -> sCompileTimePerlCode[i] = strdup (SvPV (*ppSV, l)) ;
            else
		pCmd -> sCompileTimePerlCode[i] = NULL ;
            }
        }
    else
        {
        if (ppSV)
            {
            STRLEN  l ; 
            
            pCmd -> sCompileTimePerlCode = malloc (sizeof (char *)) ;
            pCmd -> numCompileTimePerlCode = 1 ;
            pCmd -> sCompileTimePerlCode[0] = sstrdup (r, SvPV (*ppSV, l)) ;
            }
        }
    
    
    
    
    pCmd -> sPerlCodeEnd    = GetHashValueStrDup (aTHX_ r -> pThread -> pMainPool, pHash, "perlcodeend", NULL) ;
    pCmd -> sCompileTimePerlCodeEnd    = GetHashValueStrDup (aTHX_ r -> pThread -> pMainPool, pHash, "compiletimeperlcodeend", NULL) ;
    pCmd -> sStackName	    = GetHashValueStrDup (aTHX_ r -> pThread -> pMainPool, pHash, "stackname", NULL) ;
    pCmd -> sPushStack	    = GetHashValueStrDup (aTHX_ r -> pThread -> pMainPool, pHash, "push", NULL) ;
    pCmd -> sPopStack	    = GetHashValueStrDup (aTHX_ r -> pThread -> pMainPool, pHash, "pop", NULL) ;
    pCmd -> sMatchStack	    = GetHashValueStrDup (aTHX_ r -> pThread -> pMainPool, pHash, "stackmatch", NULL) ;
    pCmd -> sStackName2	    = GetHashValueStrDup (aTHX_ r -> pThread -> pMainPool, pHash, "stackname2", NULL) ;
    pCmd -> sPushStack2	    = GetHashValueStrDup (aTHX_ r -> pThread -> pMainPool, pHash, "push2", NULL) ;
    pCmd -> sPopStack2	    = GetHashValueStrDup (aTHX_ r -> pThread -> pMainPool, pHash, "pop2", NULL) ;
    pCmd -> bRemoveNode	    = GetHashValueInt    (aTHX_ pHash, "removenode", 0) ;
    pCmd -> sMayJump	    = GetHashValueStrDup (aTHX_ r -> pThread -> pMainPool, pHash, "mayjump", NULL) ;
    pCmd -> bPerlCodeRemove = GetHashValueInt	 (aTHX_ pHash, "perlcoderemove", 0) ;
    pCmd -> bCompileChilds  = GetHashValueInt	 (aTHX_ pHash, "compilechilds", 1) ;
    pCmd -> nSwitchCodeType = GetHashValueInt	 (aTHX_ pHash, "switchcodetype", 0) ;
    pCmd -> bCallReturn     = GetHashValueInt	 (aTHX_ pHash, "callreturn", 0) ;
    pCmd -> nNodeType	    = nNodeType == ntypStartEndTag?ntypStartTag:nNodeType ;
    pCmd -> pNext  = NULL ;

    pInfo -> pEmbperlCmds[nNodeName].bRemoveNode |= pCmd -> bRemoveNode ;
    /* pInfo -> pEmbperlCmds[nNodeName].bPerlCodeRemove |= pCmd -> bPerlCodeRemove ; */
    if (pCmd -> nSwitchCodeType)
	pInfo -> pEmbperlCmds[nNodeName].nSwitchCodeType = pCmd -> nSwitchCodeType ;
    if (pCmd -> sMayJump && !pInfo -> pEmbperlCmds[nNodeName].sMayJump)
	pInfo -> pEmbperlCmds[nNodeName].sMayJump = pCmd -> sMayJump ;

    if (r -> Component.Config.bDebug & dbgBuildToken) 
        lprintf (r -> pApp,  "[%d]EPCOMP: InitItem %s (#%d) perlcode=%s (num=%d) perlcodeend=%s compilechilds=%d removenode=%d nodetype=%d\n", 
	                  r -> pThread -> nPid, Ndx2String(nNodeName), nNodeName, 
			  pCmd -> sPerlCode?pCmd -> sPerlCode[0]:"", 
			  pCmd -> numPerlCode, 
			  pCmd -> sPerlCodeEnd?pCmd -> sPerlCodeEnd:"<undef>",
			  pCmd -> bCompileChilds, 
			  pCmd -> bRemoveNode, 
			  pCmd -> nNodeType) ; 

    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* strstrn			                                            */
/*                                                                          */
/* find substring of length n                                               */
/*                                                                          */
/* ------------------------------------------------------------------------ */

static const char * strstrn (const char * s1, const char * s2, int l)

    {
    while (*s1)
	{
	if ((s1 = strchr (s1, *s2)) == NULL)
	    return NULL ;
	if (strncmp (s1, s2, l) == 0)
	    return s1 ;
	s1++ ;
	}

    return NULL ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_CompileAddValue                                                  */
/*                                                                          */
/* Add value to perl code                                                   */
/*                                                                          */
/* ------------------------------------------------------------------------ */


static int embperl_CompileAddValue    (/*in*/  tReq * r,
                                       /*in*/  const char * sText,
				        const char * p,
					const char * q,
                                        const char * eq, 
					char op,
					char out,
                                       /*i/o*/  char * *      ppCode )




    {
    const char * or ;
    const char * e ;

    
    if (sText)
	{
	int l = strlen (sText) ;
	if (out == 3)
	    {
	    out = 2 ;
	    while (isspace (*sText))
		sText++, l-- ;
	    while (l > 0 && isspace (sText[l-1]))
		l-- ;
	    }

	if (op == '=' && eq)
	    {
	    eq++ ;
	    do
		{
		or = strchr (eq + 1, '|') ;
		e = or?or:q ;
		if (strnicmp (sText, eq, e - eq) == 0)
		    break ;
		if (or == NULL)
		    return 0 ;
		eq = or + 1 ;
		}
	    while (or) ;
	    }
	else if (op == '~' && eq)
	    {
	    eq++ ;
	    do 
		{
		char * f ;
		
		or = strchr (eq + 1, '|') ;
		e = or?or:q ;
		if ((f = (char *)strstrn (sText, eq, e - eq)))
		    if (!isalnum (f[e - eq]) && f[e - eq] != '_')
			break ;
		if (or == NULL)
		    return 0 ;
		eq = or + 1 ;
		}
	    while (or) ;
	    }
	else if (op == '!' && sText)
	    {
	    return 0 ;
	    }

        if (out)
	    {
	    if (out == 2)
		{
		const char * s = sText ;

                StringAdd (r -> pApp, ppCode, "'", 1) ;
		while (*s && l--)
                    {
                    if (*s == '\'')
                        {
                        if (sText < s)
                            StringAdd (r -> pApp, ppCode, sText, s - sText) ;
                        StringAdd (r -> pApp, ppCode, "\\'", 2) ;
                        sText = s + 1 ;
                        }
                    else if (*s == '\\')
                        {
                        if (sText < s)
                            StringAdd (r -> pApp, ppCode, sText, s - sText) ;
                        StringAdd (r -> pApp, ppCode, "\\\\", 2) ;
                        sText = s + 1 ;
                        }
                    s++ ;
                    }
                if (sText < s)
                    StringAdd (r -> pApp, ppCode, sText, s - sText) ;
		StringAdd (r -> pApp, ppCode, "'", 1) ;
		}
	    else if (out)            
		StringAdd (r -> pApp, ppCode, sText, 0) ;
	    }
        }
    else
        {
        if (op != '!' && op != 0)
	    return 0 ;
    	
	/*
        if (out == 2)
	    StringAdd (r -> pApp, ppCode, "''", 2) ;
	else */ if (out)           
	    StringAdd (r -> pApp, ppCode, "undef", 5) ;
	}

    return 1 ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_CompilePushStack                                                 */
/*                                                                          */
/* Push valuie on named stack                                               */
/*                                                                          */
/* ------------------------------------------------------------------------ */


static void embperl_CompilePushStack    (/*in*/  tReq * r,
                                         /*in*/ tDomTree *   pDomTree,
				              const char * sStackName,
				              const char * sStackValue)
                                              
    {
    epTHX_
    SV **   ppSV ;
    SV *    pSV ;
    AV *    pAV ;

    ppSV = hv_fetch((HV *)(pDomTree -> pSV), (char *)sStackName, strlen (sStackName), 1) ;  
    if (ppSV == NULL)
        return  ;

    if (*ppSV == NULL || !SvROK (*ppSV))
	{
	if (*ppSV)
	    SvREFCNT_dec (*ppSV) ;
        *ppSV = newRV_noinc ((SV *)(pAV = newAV ())) ;
        }
    else
        pAV = (AV *)SvRV (*ppSV) ;
        
        
    pSV = newSVpv ((char *)sStackValue, strlen (sStackValue)) ;
    SvUPGRADE (pSV, SVt_PVIV) ;
    SvIVX (pSV) = 0 ;
    av_push (pAV, pSV) ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_CompilePopStack                                                  */
/*                                                                          */
/* pop value from named stack                                               */
/*                                                                          */
/* ------------------------------------------------------------------------ */


static void embperl_CompilePopStack    (/*in*/  tReq * r,
                                        /*in*/ tDomTree *   pDomTree,
				              const char * sStackName)
                                              
    {
    epTHX_
    SV **   ppSV ;
    SV *    pSV ;

    ppSV = hv_fetch((HV *)(pDomTree -> pSV), (char *)sStackName, strlen (sStackName), 0) ;  
    if (ppSV == NULL || *ppSV == NULL || !SvROK (*ppSV))
        return  ;

    pSV = av_pop ((AV *)SvRV (*ppSV)) ;
    SvREFCNT_dec (pSV) ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_CompileMatchStack                                                */
/*                                                                          */
/* check if top of stack value matches given value                          */
/*                                                                          */
/* ------------------------------------------------------------------------ */


static int embperl_CompileMatchStack (/*in*/  tReq * r,
                                      /*in*/ tDomTree *   pDomTree,
					     tNodeData *  pNode,
					     const char * sStackName,
				             const char * sStackValue)
                                              
    {
    epTHX_
    SV **   ppSV ;
    SV *    pSV ;
    STRLEN  l ;
    char *  s ;

    ppSV = hv_fetch((HV *)(pDomTree -> pSV), (char *)sStackName, strlen (sStackName), 0) ;  
    if (ppSV == NULL || *ppSV == NULL || !SvROK (*ppSV))
        {
        strcpy (r -> errdat1, "CompileMatchStack") ;
        strncat (r -> errdat1, (char *)sStackName, sizeof (r -> errdat1) - 20) ;
        return rcHashError ;
        }
        
    pSV = av_pop ((AV *)SvRV (*ppSV)) ;

    s = SvPV (pSV, l) ;
    if (strcmp (s, sStackValue) == 0)
	{
        SvREFCNT_dec (pSV) ;
	return ok ;
	}
	
    strncpy (r -> errdat1, Node_selfNodeName (pNode), sizeof (r -> errdat1)) ;
    sprintf (r -> errdat2, "'%s', starttag should be '%s' or there is a 'end%s' missing", s, sStackValue, s) ;
    r -> Component.pCurrPos	 = NULL ;
    r -> Component.nSourceline = pNode -> nLinenumber ;

    SvREFCNT_dec (pSV) ;

    return rcTagMismatch ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_CompileAddStack                                                  */
/*                                                                          */
/* Add value of child node to perl code                                     */
/*                                                                          */
/* ------------------------------------------------------------------------ */


static int embperl_CompileAddStack    (/*in*/  tReq * r,
                                       /*in*/ tDomTree *   pDomTree,
				                const char * p,
					        const char * q,
					        char op,
					        char out,
                                                char str,
                                       /*i/o*/  char * *      ppCode )
    {
    epTHX_
    const char * eq = strchr (p, ':') ;
    const char * e = eq && eq < q?eq:q;
    STRLEN           l ;
    const char * sText = NULL ;
    SV **   ppSV ;
    AV *    pAV ;


    ppSV = hv_fetch((HV *)(pDomTree -> pSV), (char *)p, e - p, 0) ;  
    if (ppSV == NULL || *ppSV == NULL || !SvROK (*ppSV))
        return  op == '!'?1:0 ;

    pAV = (AV *)SvRV (*ppSV) ;

    if (SvTYPE (pAV) != SVt_PVAV)
        return  op == '!'?1:0 ;
    
    ppSV = av_fetch (pAV, av_len (pAV), 0) ;
    if (ppSV == NULL || *ppSV == NULL)
        return  op == '!'?1:0 ;

    if (str)
        {
        sText = SvPV (*ppSV, l) ;    
        (SvIVX (*ppSV))++ ;
        }
    else
        sText = SvIVX (*ppSV)?"1":NULL ;


    return embperl_CompileAddValue (r, sText, p, q, eq, op, out, ppCode) ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_CompileAddChildNode                                              */
/*                                                                          */
/* Add value of child node to perl code                                     */
/*                                                                          */
/* ------------------------------------------------------------------------ */


static int embperl_CompileAddChildNode (/*in*/  tReq * r,
                                        /*in*/ tDomTree *   pDomTree,
    		                        /*in*/ tNodeData *	 pNode,
				        const char * p,
					const char * q,
					char op,
					char out,
                                       /*i/o*/  char * *      ppCode )



    {
    const char * eq = strchr (p, ':') ;
    int nChildNo = atoi (p) ;
    struct tNodeData * pChildNode = Node_selfNthChild (r -> pApp, pDomTree, pNode, 0, nChildNo) ;
    const char * sText = NULL ;
    
    if (pChildNode)
	sText = Node_selfNodeName(pChildNode) ;

    return embperl_CompileAddValue (r, sText, p, q, eq, op, out, ppCode) ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_CompileAddSiblingNode                                            */
/*                                                                          */
/* Add value of sibling node to perl code                                   */
/*                                                                          */
/* ------------------------------------------------------------------------ */


static int embperl_CompileAddSiblingNode (/*in*/  tReq * r,
                                          /*in*/ tDomTree *   pDomTree,
    		                          /*in*/ tNodeData *	 pNode,
				        const char * p,
					const char * q,
					char op,
					char out,
                                       /*i/o*/  char * *      ppCode )



    {
    const char * eq = strchr (p, ':') ;
    int nChildNo = atoi (p) ;
    struct tNodeData * pChildNode  ;
    const char * sText = NULL ;
    
    if (nChildNo == 0)
	pChildNode = pNode ; 
    else if (nChildNo > 0)
	{
	nChildNo-- ;
	pChildNode = Node_selfNextSibling (r -> pApp, pDomTree, pNode, 0) ;
	while (pChildNode && nChildNo-- > 0)
	    pChildNode = Node_selfNextSibling (r -> pApp, pDomTree, pChildNode, 0) ;
	    
	}
    else
	{
	nChildNo++ ;
	pChildNode = Node_selfPreviousSibling (r -> pApp, pDomTree, pNode, 0) ;
	while (pChildNode && nChildNo++ < 0)
	    pChildNode = Node_selfPreviousSibling (r -> pApp, pDomTree, pChildNode, 0) ;
	    
	}
    
    if (pChildNode)
	sText = Node_selfNodeName(pChildNode) ;

    return embperl_CompileAddValue (r, sText, p, q, eq, op, out, ppCode) ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_CompileAddAttribut                                               */
/*                                                                          */
/* Add value of child node to perl code                                     */
/*                                                                          */
/* ------------------------------------------------------------------------ */


static int embperl_CompileAddAttribut (/*in*/  tReq * r,
                                       /*in*/   tDomTree *   pDomTree,
    		                       /*in*/   tNodeData *	 pNode,
				                const char * p,
					        const char * q,
					        char op,
					        char out,
                                       /*i/o*/  char * *      ppCode )



    {
    const char * eq = strchr (p, ':') ;
    const char * e = eq && eq < q?eq:q;
    tAttrData * pChildNode = Element_selfGetAttribut (r -> pApp, pDomTree, pNode, p, e - p) ;
    const char * sText = NULL ;
    char buf [128] ;

    
    if (pChildNode)
	{
	if (pChildNode -> bFlags & aflgAttrChilds)
	    {
	    sprintf (buf, "XML::Embperl::DOM::Attr::iValue ($_ep_DomTree,%ld)", pChildNode -> xNdx) ;
	    sText = buf ;
	    if (out == 2)
		out = 1 ;
	    }
	else
	    {
	    sText = Ndx2String (pChildNode -> xValue) ;
	    }

        }
    
    return embperl_CompileAddValue (r, sText, p, q, eq, op, out, ppCode) ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_CompileToPerlCode                                                */
/*                                                                          */
/* Compile one command inside a node                                        */
/*                                                                          */
/* ------------------------------------------------------------------------ */


static int embperl_CompileToPerlCode  (/*in*/ tReq * r,
                                       /*in*/ tDomTree *    pDomTree,
    		                       /*in*/ tNodeData *   pNode,
                                       /*in*/ const char *  sPerlCode,
                                       /*out*/ char * *     ppCode )


    {
    const char * p ;
    const char * q ;
    int    valid = 1 ;
    tNode   xCurrNode = 0 ;

    StringNew (r -> pApp, ppCode, 512) ;
    if (sPerlCode)
	{
	p = strchr (sPerlCode, '%') ;	
	while (p)
	    {
	    int n = p - sPerlCode ;
	    if (n)
		StringAdd (r -> pApp, ppCode, sPerlCode, n) ;
	    q = strchr (p+1, '%') ;	
	    if (q)
		{
		char  type  ;
		char  op  ;
		char  out = 1 ;

		p++ ;
		type = *p ;
		p++ ;
		op = *p ;
		if (op != '=' && op != '*' && op != '!' && op != '~')
		    op = 0 ;
		else
		    p++ ;

		if (*p == '-')
		    out = 0, p++ ;
		else if (*p == '\'')
		    out = 2, p++ ;
		else if (*p == '"')
		    out = 3, p++ ;

		
		if (type == '#')
		    {
		    if (!embperl_CompileAddChildNode (r, pDomTree, pNode ,p, q, op, out, ppCode))
			{
			valid = 0 ;
			break ;
			}
		    }
		else if (type == '>')
		    {
		    if (!embperl_CompileAddSiblingNode (r, pDomTree, pNode ,p, q, op, out, ppCode))
			{
			valid = 0 ;
			break ;
			}
		    }
		else if (type == '&')
		    {
		    if (!embperl_CompileAddAttribut (r, pDomTree, pNode ,p, q, op, out, ppCode))
			{
			valid = 0 ;
			break ;
			}
		    }
		else if (type == '^')
		    {
		    if (!embperl_CompileAddStack (r, pDomTree, p, q, op, out, 1, ppCode))
			{
			valid = 0 ;
			break ;
			}
		    }
		else if (type == '?')
		    {
		    if (!embperl_CompileAddStack (r, pDomTree, p, q, op, out, 0, ppCode))
			{
			valid = 0 ;
			break ;
			}
		    }
		else if (type == '%')
		    {
		    StringAdd (r -> pApp, ppCode, "%", 1) ; 
		    }
		else if (type == '$')
		    {
		    if (*p == 'n')
			{
			char s [20] ;
			int  l = sprintf (s, "$_ep_DomTree,%ld", pNode -> xNdx) ;
			StringAdd (r -> pApp, ppCode, s, l) ; 
			}
		    else if (*p == 't')
			{
			StringAdd (r -> pApp, ppCode, "$_ep_DomTree", 0) ; 
			}
		    else if (*p == 'x')
			{
			char s [20] ;
			int  l = sprintf (s, "%ld", pNode -> xNdx) ;
			StringAdd (r -> pApp, ppCode, s, l) ; 
			}
		    else if (*p == 'l')
			{
			char s [20] ;
			int  l = sprintf (s, "%ld", pDomTree -> xLastNode) ;
			StringAdd (r -> pApp, ppCode, s, l) ; 
			}
		    else if (*p == 'c')
			{
			char s [20] ;
			if (pDomTree -> xLastNode != pDomTree -> xCurrNode)
			    {
			    int  l = sprintf (s, "$_ep_node=%ld;", pDomTree -> xLastNode) ;
			    StringAdd (r -> pApp, ppCode, s, l) ; 
			    xCurrNode = pDomTree -> xLastNode ;
			    }
			}
		    else if (*p == 'q')
			{
			char s [20] ;
			int  l = sprintf (s, "%hd", pDomTree -> xNdx) ;
			StringAdd (r -> pApp, ppCode, s, l) ; 
			}
		    else if (*p == 'p')
			{
			char s [20] ;
			int  l = sprintf (s, "%u", ArrayGetSize (r -> pApp, pDomTree -> pCheckpoints)) ;
			StringAdd (r -> pApp, ppCode, s, l) ; 
			}
		    else if (*p == 'k')
			{
			char s [40] ;
                        int  l ;
	                tIndex nCheckpointArrayOffset = ArrayAdd (r -> pApp, &pDomTree -> pCheckpoints, 1) ;
	                pDomTree -> pCheckpoints[nCheckpointArrayOffset].xNode = pNode -> xNdx ;
	                l = sprintf (s, " _ep_cp(%ld) ;\n", nCheckpointArrayOffset) ;
			StringAdd (r -> pApp, ppCode, s, l) ; 

	                if (r -> Component.Config.bDebug & dbgCompile)
	                    lprintf (r -> pApp, "[%d]EPCOMP: #%d L%d Checkpoint\n", r -> pThread -> nPid, pNode -> xNdx, pNode -> nLinenumber) ;
                        }
                    
                    
                    }

		sPerlCode = q + 1 ;
		p = strchr (sPerlCode, '%') ;	
		}
	    else
		{
		sPerlCode = p ;
		p = NULL ; 
		}
	    }
	if (valid)
	    {
	    StringAdd (r -> pApp, ppCode, sPerlCode,  0) ; 
	    if (xCurrNode)
    		pDomTree -> xCurrNode = xCurrNode ;
	    }
				    
	}
    return valid ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_CompileCleanupSpaces                                             */
/*                                                                          */
/* remove any following spaces                                              */
/*                                                                          */
/* ------------------------------------------------------------------------ */


static int embperl_CompileCleanupSpaces  (/*in*/  tReq *	r,
					  /*in*/  tDomTree *	pDomTree,
					  /*in*/  tNodeData *	pNode,
					  /*i/o*/ tEmbperlCmd *	pCmd)


    {
    if ((pCmd -> bRemoveNode & 6) && (r -> Component.Config.bOptions & optKeepSpaces) == 0)
	{
	tNodeData *  pNextNode   = Node_selfFirstChild (r -> pApp, pDomTree, pNode, 0) ;
	if ((pCmd -> bRemoveNode & 1) || !pCmd -> bCompileChilds || pNextNode == NULL || (pNextNode -> nType != ntypText && pNextNode -> nType != ntypCDATA))
	    pNextNode    = Node_selfNextSibling (r -> pApp, pDomTree, pNode, 0) ;
	if (pNextNode)
	    {
	    const char * sText        = Node_selfNodeName (pNextNode) ;
	    const char * p            = sText ;

	    while (*p && isspace (*p))
		p++;
	    if (p > sText && (pCmd -> bRemoveNode & 4))
		p-- ;

	    if (p > sText)
		{ /* remove spaces */
		if (*p)
		    Node_replaceChildWithCDATA(r -> pApp, pDomTree, pNextNode -> xNdx, 0, p, strlen (p), -1, 0) ;
		else
		    Node_selfRemoveChild(r -> pApp, pDomTree, -1, pNextNode) ;
		}

	    }
	}
    return ok ;
    }



/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_CompileCmd							    */
/*                                                                          */
/* Compile one cmd of one node						    */
/*                                                                          */
/* ------------------------------------------------------------------------ */


static int embperl_CompileCmd  (/*in*/	tReq *	       r,
			 /*in*/  tDomTree *	pDomTree,
			 /*in*/  tNodeData *	pNode,
			 /*in*/  tEmbperlCmd *	pCmd,
			 /*out*/ int *		nStartCodeOffset)


    {
    epTHX_
    char *          pCode = NULL ; 
    char *          pCTCode = NULL ; 
    char *          sSourcefile ;
    int             nSourcefile ;
    int i ;
    SV *        args[4] ;
    int nCodeLen = 0 ;
    int found = 0 ;
    char *use_utf8 = "" ;

    if (strcmp (r -> Component.Config.sInputCharset, "utf8") == 0)
        use_utf8 = "use utf8;" ;
        
   r -> Component.pCodeSV = NULL ;

    Ndx2StringLen (pDomTree -> xFilename, sSourcefile, nSourcefile) ;

    if (pCmd -> nNodeType != pNode -> nType)
	return ok ;

    for (i = 0; i < pCmd -> numPerlCode; i++)
	if (embperl_CompileToPerlCode (r, pDomTree, pNode, pCmd -> sPerlCode[i], &pCode))
	    {
	    found = 1 ;
	    break ;
	    }

    if (found && pCode)
	{
	nCodeLen = ArrayGetSize (r -> pApp, pCode) ;

	if (nCodeLen)
	    {
	    char buf [32] ;

	    if (pNode ->  nLinenumber && pNode ->  nLinenumber != pDomTree -> nLastLinenumber )
		{
		int l2 = sprintf (buf, "#line %d \"", pDomTree -> nLastLinenumber = pNode ->	nLinenumber) ;

		StringAdd (r -> pApp, r -> Component.pProg, buf, l2) ;
		StringAdd (r -> pApp, r -> Component.pProg, sSourcefile, nSourcefile) ;
		StringAdd (r -> pApp, r -> Component.pProg, "\"\n", 2) ;
		}

	    if (pCmd -> bPerlCodeRemove)
		*nStartCodeOffset = StringAdd (r -> pApp, r -> Component.pProg, " ", 1) ;
	    }
	else
	    {
	    StringFree (r -> pApp, &pCode) ;
	    pCode = NULL ;
	    }
	}
    else
	{
	StringFree (r -> pApp, &pCode) ;
	pCode = NULL ;
	}

    for (i = 0; i < pCmd -> numCompileTimePerlCode; i++)
	{
	if (embperl_CompileToPerlCode (r, pDomTree, pNode, pCmd -> sCompileTimePerlCode[i], &pCTCode))
	    {
	    SV * pSV ;
	    int   rc ;

	    if (pCTCode)
		{
		int l = ArrayGetSize (r -> pApp, pCTCode) ;
		int i = l ;
		char *p = pCTCode ;

		if (r -> Component.Config.bDebug & dbgCompile)
		    lprintf (r -> pApp,  "[%d]EPCOMP: #%d L%d CompileTimeCode:    %*.*s\n", r -> pThread -> nPid, pNode -> xNdx, pNode -> nLinenumber, l, l, pCTCode) ;

                if (p[0] == '#' && p[1] == '!' && p[2] == '-')
                    {
		    p[0] = ' ' ;
                    p[1] = ' ' ;
                    p[2] = ' ' ;
                    while (i--)
		        { /* keep everything on one line, to make linenumbers correct */
		        if (*p == '\r' || *p == '\n')
			    *p = ' ' ;
		        p++ ;
		        }
                    }		

                pSV = newSVpvf("package %s ; %s\n#line %d \"%s\"\n%*.*s",
			r -> Component.sEvalPackage, use_utf8, pNode ->	nLinenumber, sSourcefile, l,l, pCTCode) ;
		newSVpvf2(pSV) ;
		args[0] = r -> _perlsv ;
		if (pCode)
		    {			
		    r -> Component.pCodeSV = newSVpv (pCode, nCodeLen) ;
		    }
		else
		    r -> Component.pCodeSV = &sv_undef ; 
                SvTAINTED_off (pSV) ;
                if ((rc = EvalDirect (r, pSV, 1, args)) != ok)
		    LogError (r, rc) ;
		SvREFCNT_dec(pSV);
		}
	    break ;
	    }
	}

    if (r -> Component.pCodeSV && SvOK(r -> Component.pCodeSV))
	{
	STRLEN l ;
	char * p = SvPV (r -> Component.pCodeSV, l) ;
	StringAdd (r -> pApp, r -> Component.pProg, p, l ) ;
	StringAdd (r -> pApp, r -> Component.pProg, "\n",  1) ;
	if (r -> Component.Config.bDebug & dbgCompile)
	    lprintf (r -> pApp,  "[%d]EPCOMP: #%d L%d Code:    %s\n", r -> pThread -> nPid, pNode -> xNdx, pNode -> nLinenumber, p) ;
	}
    else if (pCode)
	{
	StringAdd (r -> pApp, r -> Component.pProg, pCode, nCodeLen ) ;
	StringAdd (r -> pApp, r -> Component.pProg, "\n",  1) ;
	if (r -> Component.Config.bDebug & dbgCompile)
	    lprintf (r -> pApp,  "[%d]EPCOMP: #%d L%d Code:    %*.*s\n", r -> pThread -> nPid, pNode -> xNdx, pNode -> nLinenumber, nCodeLen, nCodeLen, pCode) ;
	}    
    
    StringFree (r -> pApp, &pCode) ;
    StringFree (r -> pApp, &pCTCode) ;

    if (r -> Component.pCodeSV)
	{
	SvREFCNT_dec(r -> Component.pCodeSV);
	r -> Component.pCodeSV = NULL ;
	}
    return ok ;
    }



/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_CompilePostProcess						    */
/*                                                                          */
/* Do some postprocessing after compiling				    */
/*                                                                          */
/* ------------------------------------------------------------------------ */


static int embperl_CompilePostProcess  (/*in*/	tReq *	       r,
			 /*in*/  tDomTree *	pDomTree,
			 /*in*/  tNodeData *	pNode,
			 /*in*/  tEmbperlCmd *	pCmd,
			 /*in*/  int		nCheckpointCodeOffset,
			 /*in*/  int		nCheckpointArrayOffset,
			 /*i/o*/ int *		bCheckpointPending)


    {
    int rc ;
    char *          sStackValue = NULL ;


    embperl_CompileCleanupSpaces (r, pDomTree, pNode, pCmd) ;

    if (pCmd -> sMayJump)
	if (embperl_CompileToPerlCode (r, pDomTree, pNode, pCmd -> sMayJump, &sStackValue))
	    {
	    if (*bCheckpointPending <= 0)
                *bCheckpointPending = -1 ;
	    if (r -> Component.Config.bDebug & dbgCompile)
		lprintf (r -> pApp,  "[%d]EPCOMP: #%d L%d Set Checkpoint pending\n", r -> pThread -> nPid, pNode -> xNdx, pNode -> nLinenumber) ;
	    }

    if (pCmd -> bRemoveNode & 1)
	pNode -> bFlags = 0 ; 
    else if (pCmd -> bRemoveNode & 8)
	pNode -> bFlags |= nflgIgnore ;
    if (pCmd -> bRemoveNode & 16)
	{
	tNodeData * pChild ;
	while ((pChild = Node_selfFirstChild (r -> pApp, pDomTree, pNode, 0)))
	    {
	    Node_selfRemoveChild (r -> pApp, pDomTree, pNode -> xNdx, pChild) ;
	    }
	}
    else if (pCmd -> bRemoveNode & 32)
	{
	tNodeData * pChild = Node_selfFirstChild (r -> pApp, pDomTree, pNode, 0) ;
	while (pChild)
	    {
	    pChild -> bFlags |= nflgIgnore ;
            pChild = Node_selfNextSibling (r -> pApp, pDomTree, pChild, 0) ;

	    }
	}


    if (nCheckpointCodeOffset && (pNode -> bFlags == 0 || (pNode -> bFlags & nflgIgnore)))
	{
	(*r -> Component.pProg)[nCheckpointCodeOffset] = '#' ;
	nCheckpointArrayOffset = ArraySub (r -> pApp, &pDomTree -> pCheckpoints, 1) ;
        if (r -> Component.Config.bDebug & dbgCompile)
	    lprintf (r -> pApp,  "[%d]EPCOMP: #%d L%d Remove Checkpoint\n", r -> pThread -> nPid, pNode -> xNdx, pNode -> nLinenumber) ;
	nCheckpointCodeOffset = 0 ;
        if (*bCheckpointPending <= 0)
	    *bCheckpointPending = -1 ; /* set checkpoint on next possibility */
        }

    if (*bCheckpointPending < 0 && (pNode -> bFlags & nflgIgnore))
	{
	int l ;
	char buf [80] ;

	nCheckpointArrayOffset = ArrayAdd (r -> pApp, &pDomTree -> pCheckpoints, 1) ;
	pDomTree -> pCheckpoints[nCheckpointArrayOffset].xNode = pNode -> xNdx ;
	*bCheckpointPending = 0 ;
	l = sprintf (buf, " _ep_cp(%d) ;\n", nCheckpointArrayOffset) ;
	nCheckpointCodeOffset = StringAdd (r -> pApp, r -> Component.pProg, buf,	l) ;

	if (r -> Component.Config.bDebug & dbgCompile)
	    lprintf (r -> pApp,  "[%d]EPCOMP: #%d L%d Checkpoint\n", r -> pThread -> nPid, pNode -> xNdx, pNode -> nLinenumber) ;

	}

    if (pCmd -> sPopStack)
	embperl_CompilePopStack (r, pDomTree, pCmd -> sPopStack) ;
    if (pCmd -> sPopStack2)
	embperl_CompilePopStack (r, pDomTree, pCmd -> sPopStack2) ;

    if (pCmd -> sStackName)
	{
	if (pCmd -> sMatchStack && pNode -> nType != ntypStartTag && pNode -> nType != ntypDocument && pNode -> nType != ntypDocumentFraq)
	    {
	    if (embperl_CompileToPerlCode (r, pDomTree, pNode, pCmd -> sMatchStack, &sStackValue))
		if ((rc = embperl_CompileMatchStack (r, pDomTree, pNode, pCmd -> sStackName, sStackValue)) != ok)
		    {
		    StringFree (r -> pApp, &sStackValue) ;
		    return rc ;
		    }
	    }
	if (pCmd -> sPushStack)
	    {
	    if (embperl_CompileToPerlCode (r, pDomTree, pNode, pCmd -> sPushStack, &sStackValue))
		embperl_CompilePushStack (r, pDomTree, pCmd -> sStackName, sStackValue) ;
	    }
	}
    if (pCmd -> sStackName2 && pCmd -> sPushStack2)
	{
	if (embperl_CompileToPerlCode (r, pDomTree, pNode, pCmd -> sPushStack2, &sStackValue))
	    {
	    embperl_CompilePushStack (r, pDomTree, pCmd -> sStackName2, sStackValue) ;
	    }
	}

    StringFree (r -> pApp, &sStackValue) ;

    return ok ;
    }
    
    



/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_CompileCmdEnd						   */
/*                                                                          */
/* Compile the end of the node						    */
/*                                                                          */
/* ------------------------------------------------------------------------ */


static int embperl_CompileCmdEnd (/*in*/  tReq *	 r,
			 /*in*/  tDomTree *	pDomTree,
			 /*in*/  tNodeData *	pNode,
			 /*in*/  tEmbperlCmd *	pCmd,
			 /*in*/  int		nStartCodeOffset,
			 /*i/o*/ int *		bCheckpointPending)


    {
    epTHX_
    int rc ;
    char *          sStackValue = NULL ;
    char *          pCode = NULL ; 
    char *          pCTCode = NULL ; 
    SV *	    args[4] ;
    STRLEN	    nCodeLen  = 0 ;
    char *use_utf8 = "" ;

    if (strcmp (r -> Component.Config.sInputCharset, "utf8") == 0)
        use_utf8 = "use utf8;" ;


    if (pCmd -> nNodeType != pNode -> nType)
	return ok ;


    if (pCmd)
	{
        if (pCmd -> sPerlCodeEnd && embperl_CompileToPerlCode (r, pDomTree, pNode, pCmd -> sPerlCodeEnd, &pCode))
            nCodeLen = ArrayGetSize (r -> pApp, pCode) ;
	    
	if (embperl_CompileToPerlCode (r, pDomTree, pNode, pCmd -> sCompileTimePerlCodeEnd, &pCTCode))
	    {
	    SV * pSV ;
	    int   rc ;

	    if (pCTCode && *pCTCode)
		{
		int l = ArrayGetSize (r -> pApp, pCTCode) ;
		char *          sSourcefile ;
		int             nSourcefile ;
		int i = l ;
		char * p = pCTCode ;
		
		Ndx2StringLen (pDomTree -> xFilename, sSourcefile, nSourcefile) ;

		if (r -> Component.Config.bDebug & dbgCompile)
		    lprintf (r -> pApp,  "[%d]EPCOMP: #%d L%d CompileTimeCodeEnd:    %*.*s\n", r -> pThread -> nPid, pNode -> xNdx, pNode -> nLinenumber, l, l, pCTCode) ;

                if (p[0] == '#' && p[1] == '!' && p[2] == '-')
                    {
		    p[0] = ' ' ;
                    p[1] = ' ' ;
                    p[2] = ' ' ;
                    while (i--)
		        { /* keep everything on one line, to make linenumbers correct */
		        if (*p == '\r' || *p == '\n')
			    *p = ' ' ;
		        p++ ;
		        }
                    }		

		
		pSV = newSVpvf("package %s ; %s\n#line %d \"%s\"\n%*.*s",
			r -> Component.sEvalPackage, use_utf8, pNode ->	nLinenumber, sSourcefile, l,l, pCTCode) ;
		newSVpvf2(pSV) ;
		args[0] = r -> _perlsv ;
		if (pCode)
		    {			
		    r -> Component.pCodeSV = newSVpv (pCode, nCodeLen) ;
		    }
		else
		    r -> Component.pCodeSV = &sv_undef ; 
		if ((rc = EvalDirect (r, pSV, 1, args)) != ok)
		    LogError (r, rc) ;
		SvREFCNT_dec(pSV);
		}
	    }

	if (r -> Component.pCodeSV)
	    {
	    if (SvOK (r -> Component.pCodeSV))
		{
		char * p = SvPV (r -> Component.pCodeSV, nCodeLen) ;
		if (nCodeLen)
		    {			
		    StringAdd (r -> pApp, r -> Component.pProg, p, nCodeLen ) ;
		    StringAdd (r -> pApp, r -> Component.pProg, "\n",  1) ;
		    if (r -> Component.Config.bDebug & dbgCompile)
			lprintf (r -> pApp,  "[%d]EPCOMP: #%d L%d CodeEnd:    %s\n", r -> pThread -> nPid, pNode -> xNdx, pNode -> nLinenumber, p) ;
		    }
		}
	    }
	else if (pCode && nCodeLen)
	    {
	    StringAdd (r -> pApp, r -> Component.pProg, pCode, nCodeLen ) ;
	    StringAdd (r -> pApp, r -> Component.pProg, "\n",  1) ;
	    if (r -> Component.Config.bDebug & dbgCompile)
		lprintf (r -> pApp,  "[%d]EPCOMP: #%d L%d CodeEnd:    %*.*s\n", r -> pThread -> nPid, pNode -> xNdx, pNode -> nLinenumber, nCodeLen, nCodeLen, pCode) ;
	    }    
	if (nCodeLen == 0)
	    {
	    if (pCmd -> bPerlCodeRemove && nStartCodeOffset)
		{
		(*r -> Component.pProg)[nStartCodeOffset] = '#' ;
		if (r -> Component.Config.bDebug & dbgCompile)
		    lprintf (r -> pApp,  "[%d]EPCOMP: #%d L%d Remove Codeblock\n", r -> pThread -> nPid, pNode -> xNdx, pNode -> nLinenumber) ; 
		}
	    }
        if (pCmd -> sPerlCodeEnd && pCmd -> sMayJump)
            if (embperl_CompileToPerlCode (r, pDomTree, pNode, pCmd -> sMayJump, &sStackValue))
	        {
	        if (*bCheckpointPending <= 0)
		    *bCheckpointPending = -1 ;
		if (r -> Component.Config.bDebug & dbgCompile)
		    lprintf (r -> pApp,  "[%d]EPCOMP: #%d L%d Set Checkpoint pending\n", r -> pThread -> nPid, pNode -> xNdx, pNode -> nLinenumber) ; 
	        }
	if (pCmd -> sStackName  && (pNode -> nType == ntypStartTag || pNode -> nType == ntypDocument || pNode -> nType == ntypDocumentFraq))
	    {
	    if (pCmd -> sMatchStack)
		{
		if (embperl_CompileToPerlCode (r, pDomTree, pNode, pCmd -> sMatchStack, &sStackValue))
		    {
		    if ((rc = embperl_CompileMatchStack (r, pDomTree, pNode, pCmd -> sStackName, sStackValue)) != ok)
			{
			StringFree (r -> pApp, &pCode) ;
			StringFree (r -> pApp, &pCTCode) ;
			StringFree (r -> pApp, &sStackValue) ;
			return rc ;
			}
		    }
		}
	    else if (pCmd -> sPushStack && pCmd -> sPerlCodeEnd)
		embperl_CompilePopStack (r, pDomTree, pCmd -> sStackName) ;
	    }

        if (pCmd -> sStackName2 && pCmd -> sPushStack2 && pCmd -> sPerlCodeEnd)
            embperl_CompilePopStack (r, pDomTree, pCmd -> sStackName2) ;
  
	if (pCmd -> nSwitchCodeType == 1)
            {
            r -> Component.pProg = &r -> Component.pProgRun ;
	    if (*bCheckpointPending <= 0)
	        *bCheckpointPending = -1 ;
	    if (r -> Component.Config.bDebug & dbgCompile)
		lprintf (r -> pApp,  "[%d]EPCOMP: #%d L%d Set Checkpoint pending (switch to ProgRun)\n", r -> pThread -> nPid, pNode -> xNdx, pNode -> nLinenumber) ;
            }
        }


    StringFree (r -> pApp, &pCode) ;
    StringFree (r -> pApp, &pCTCode) ;

    if (r -> Component.pCodeSV)
	{
	SvREFCNT_dec(r -> Component.pCodeSV);
	r -> Component.pCodeSV = NULL ;
	}
	    
    StringFree (r -> pApp, &sStackValue) ;

    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_CompileNode                                                      */
/*                                                                          */
/* Compile one node and his children                                          */
/*                                                                          */
/* ------------------------------------------------------------------------ */


int embperl_CompileNode (/*in*/  tReq *         r,
			 /*in*/  tDomTree *	pDomTree,
			 /*in*/  tNode		xNode,
			 /*i/o*/ int *		bCheckpointPending)


    {
    int rc ;
    tNode           xChildNode  ;
    tStringIndex    nNdx  ;
    tEmbperlCmd *   pCmd  ;
    tEmbperlCmd *   pCmdHead  ;
    tEmbperlCmd *   pCmdLast  ;
    tEmbperlCmd *   pCmdNext  ;
    tEmbperlCmd *   pCmdIter  ;
    tNodeData *     pNode = Node_self (pDomTree, xNode) ;
    tAttrData *     pAttr ;
    int             nAttr = 0 ;
    int		    nStartCodeOffset = 0 ;               
    int		    nCheckpointCodeOffset = 0 ;               
    int		    nCheckpointArrayOffset = 0 ;               
    tEmbperlCompilerInfo * pInfo = (tEmbperlCompilerInfo *)(*(void * *)r -> Component.pTokenTable) ;
    tIndex          xDomTree = pDomTree -> xNdx ;

    pCmd = NULL ;
    
    nNdx = Node_selfNodeNameNdx (pNode) ;

    if (nNdx <= pInfo -> nMaxEmbperlCmd)
	{
	pCmd = pCmdHead = &(pInfo -> pEmbperlCmds[nNdx]) ;
        pCmdLast = NULL ;
        /* ??if (pCmd -> nNodeType != pNode -> nType) */
	/*	 pCmd = NULL ; */
	}
    else
	pCmd = pCmdHead = pCmdLast = NULL ;
    

    if (r -> Component.Config.bDebug & dbgCompile)
        {
        char buf[20] ;
        lprintf (r -> pApp,  "[%d]EPCOMP: #%d L%d -------> parent=%d node=%d type=%d text=%s (#%d,%s) %s\n", 
		     r -> pThread -> nPid, pNode -> xNdx, pNode -> nLinenumber, 
		     Node_parentNode  (r -> pApp, pDomTree, pNode -> xNdx, 0), pNode -> xNdx,
                     pNode -> nType, Node_selfNodeName(pNode), nNdx, pCmd?"compile":"-", (pCmd && pCmd -> bRemoveNode)?(sprintf (buf, "removenode=%d", pCmd -> bRemoveNode), buf):"") ;
        }
    

    if (pCmd == NULL || (pCmd -> bRemoveNode & 1) == 0)
        pDomTree -> xLastNode = xNode ;

    /*    if (*bCheckpointPending && (pNode -> nType == ntypText || pNode -> nType == ntypCDATA) && pNode -> bFlags && (pNode -> bFlags & nflgIgnore) == 0) */
    /*    if (*bCheckpointPending &&	 pNode -> bFlags && (pNode -> bFlags & nflgIgnore) == 0) */
    if (*bCheckpointPending < 0  &&	!(pCmd && pCmd -> nSwitchCodeType == 2) && pNode -> bFlags && (pNode -> bFlags & nflgIgnore) == 0)
	{
	int l ;
	char buf [80] ;
	
	nCheckpointArrayOffset = ArrayAdd (r -> pApp, &pDomTree -> pCheckpoints, 1) ;
	pDomTree -> pCheckpoints[nCheckpointArrayOffset].xNode = xNode ;
	*bCheckpointPending = 0 ;
	l = sprintf (buf, " _ep_cp(%d) ;\n", nCheckpointArrayOffset) ;
	nCheckpointCodeOffset = StringAdd (r -> pApp, r -> Component.pProg, buf,  l) ; 

	if (r -> Component.Config.bDebug & dbgCompile)
	    lprintf (r -> pApp,  "[%d]EPCOMP: #%d L%d Checkpoint\n", r -> pThread -> nPid, pNode -> xNdx, pNode -> nLinenumber) ; 
	
	}

    if (pCmd && pCmd -> nSwitchCodeType == 2)
        {
        r -> Component.pProg = &r -> Component.pProgDef ;
        nCheckpointArrayOffset = 0 ;
        nCheckpointCodeOffset = 0 ;
        }
	
    if (pCmd == NULL || (pCmd -> bRemoveNode & 8) == 0 || (pCmd -> bRemoveNode & 64))
        { /* calculate attributes before tag, but not when tag should be ignored in output stream */
        int bSaveCP = *bCheckpointPending ;
        if (pCmd && (pCmd -> bRemoveNode & 64))
            *bCheckpointPending = 1 ;
        
        while ((pAttr = Element_selfGetNthAttribut (r -> pApp, pDomTree, pNode, nAttr++)))
	    {
            if (pAttr -> bFlags & aflgAttrChilds)
                {
                tNodeData * pChild = Node_selfFirstChild (r -> pApp, pDomTree, (tNodeData *)pAttr, 0) ;
                tNodeData * pNext ;

                while (pChild)
                    {
                    embperl_CompileNode (r, pDomTree, pChild -> xNdx, bCheckpointPending) ;
	            pDomTree = DomTree_self (xDomTree) ; /* addr may have changed */
                    pNext = Node_selfNextSibling (r -> pApp, pDomTree, pChild, 0) ;
                    if (pChild -> bFlags == 0)
                        Node_selfRemoveChild(r -> pApp, pDomTree, -1, pChild) ;
                    pChild = pNext ;
                    }
                }                

	    }
        if (pCmd && (pCmd -> bRemoveNode & 64))
            *bCheckpointPending = bSaveCP ;

        }            
    

    while (pCmd)
	{
	if ((rc = embperl_CompileCmd (r, pDomTree, pNode, pCmd, &nStartCodeOffset)) != ok)
	    return rc ;
	pDomTree = DomTree_self (xDomTree) ; /* addr may have changed */
        pCmdLast = pCmd ;
        pCmd = pCmd -> pNext ;
	}

    pCmd = pCmdLast ;
    if (pCmd)
        if ((rc = embperl_CompilePostProcess (r, pDomTree, pNode, pCmd, nCheckpointCodeOffset, nCheckpointArrayOffset, bCheckpointPending)) != ok)
	    return rc ;


    if (pCmd == NULL || pCmd -> bCompileChilds)
	{
	tNodeData * pChildNode ;

	xChildNode = pNode -> bFlags?Node_firstChild (r -> pApp, pDomTree, xNode, 0):0 ;

	while (xChildNode)
	    {
	    if ((rc = embperl_CompileNode (r, pDomTree, xChildNode, bCheckpointPending)) != ok)
		return rc ;

	    pDomTree = DomTree_self (xDomTree) ; /* addr may have changed */
	    pChildNode = Node_self (pDomTree, xChildNode) ;
            xChildNode  = Node_nextSibling (r -> pApp, pDomTree, xChildNode, 0) ;
            if (pChildNode -> bFlags == 0)
                Node_selfRemoveChild(r -> pApp, pDomTree, -1, pChildNode) ;
            }
	}
	    

    while (pCmd)
	{
	if ((rc = embperl_CompileCmdEnd (r, pDomTree, pNode, pCmd, nStartCodeOffset, bCheckpointPending)) != ok)
	    return rc ;
        pCmdIter = pCmdHead ;
        pCmdNext = NULL ;
        while (pCmdIter && pCmdIter != pCmd)
            {
            pCmdNext = pCmdIter ;
            pCmdIter = pCmdIter -> pNext ;
            }
	pCmd = pCmdNext ;
        }

    if (pCmdHead && pCmdHead -> nSwitchCodeType == 2)
        {
        r -> Component.pProg = &r -> Component.pProgRun ;
        nCheckpointArrayOffset = 0 ;
        nCheckpointCodeOffset = 0 ;
        }


    return ok ;
    }



/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_CompileDomTree						    */
/*                                                                          */
/* Compile root node and his children					    */
/*                                                                          */
/* ------------------------------------------------------------------------ */


static int embperl_CompileDomTree (/*in*/  tReq *	  r,
				   /*in*/  tDomTree *	  pDomTree)



    {
    int rc ;
    int         bCheckpointPending = 0 ;
    tIndex      xDomTree = pDomTree -> xNdx ;


    pDomTree -> xCurrNode = 0 ;

    if ((rc = embperl_CompileNode (r, pDomTree, pDomTree -> xDocument, &bCheckpointPending)) != ok)
	return rc ;

    pDomTree = DomTree_self (xDomTree) ; /* addr may have changed */

    if (bCheckpointPending)
	{
	int l ;
	char buf [80] ;

	int nCheckpointArrayOffset = ArrayAdd (r -> pApp, &pDomTree -> pCheckpoints, 1) ;
	pDomTree -> pCheckpoints[nCheckpointArrayOffset].xNode = -1 ;
	l = sprintf (buf, " _ep_cp(%d) ;\n", nCheckpointArrayOffset) ;
	StringAdd (r -> pApp, r -> Component.pProg, buf,	l) ;

	if (r -> Component.Config.bDebug & dbgCompile)
	    lprintf (r -> pApp,  "[%d]EPCOMP: #%d  Checkpoint\n", r -> pThread -> nPid, -1) ;

	}
    
    return ok ;
    }



/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_Compile                                                          */
/*                                                                          */
/* Compile the whole document                                               */
/*                                                                          */
/* ------------------------------------------------------------------------ */

int embperl_Compile                 (/*in*/  tReq *	  r,
				     /*in*/  tIndex       xDomTree,
				     /*out*/ tIndex *     pxResultDomTree,
                                     /*out*/ SV * *       pProg) 


    {
    epTHX_
    int rc ;
    tDomTree * pDomTree = DomTree_self (*pxResultDomTree = xDomTree) ;
    char *      sSourcefile = DomTree_selfFilename (pDomTree)  ;
    clock_t	cl1 = clock () ;
    clock_t	cl2  ;
    clock_t	cl3  ;
    clock_t	cl4  ;
    STRLEN      l ;
    SV *        pSV ;
    SV *        args[2] ;
    /*
    int         nStep = r -> Buf.pFile -> nFilesize / 4 ;
    if (nStep < 1024)
        nStep = 1024 ;
    else if (nStep > 4096)
        nStep = 4096 ;
    */
    int nStep = 8192 ;
    char *use_utf8 = "" ;

    if (strcmp (r -> Component.Config.sInputCharset, "utf8") == 0)
        use_utf8 = "use utf8;" ;

    if (r -> Component.Config.bDebug & dbgCompile)
	lprintf (r -> pApp,  "[%d]EPCOMP: Start compiling %s DomTree = %d\n", r -> pThread -> nPid, sSourcefile, xDomTree) ; 

    if (r -> Component.Config.bOptions & optChdirToSource)
        ChdirToSource (r, sSourcefile) ; 

    r -> Component.nPhase  = phCompile ;

    r -> Component.pProgRun = NULL ;
    r -> Component.pProgDef = NULL ;

    StringNew (r -> pApp, &r -> Component.pProgRun, nStep ) ;
    StringNew (r -> pApp, &r -> Component.pProgDef, nStep ) ;
    r -> Component.pProg = &r -> Component.pProgRun ;

    pDomTree -> pSV = (SV *)newHV () ;
    if (pDomTree -> pCheckpoints)
	ArraySetSize (r -> pApp, &pDomTree -> pCheckpoints, 0) ;
    else
	ArrayNew (r -> pApp, &pDomTree -> pCheckpoints, 256, sizeof (tDomTreeCheckpoint)) ;
    ArrayAdd (r -> pApp, &pDomTree -> pCheckpoints, 1) ;
    pDomTree -> pCheckpoints[0].xNode = 0 ;

    if ((rc = embperl_CompileDomTree (r, pDomTree)) != ok)
	{
        /*
        *ppSV = newSVpvf ("%s\t%s", r -> errdat1, r -> errdat2) ;
	SvUPGRADE (*ppSV, SVt_PVIV) ;
	SvIVX (*ppSV) = rc ;
	if (r -> Component.xCurrDomTree)
	    {
	    DomTree_delete(DomTree_self(r -> Component.xCurrDomTree)) ;
	    r -> Component.xCurrDomTree = 0 ;
	    }
	*/
        StringFree (r -> pApp, &r -> Component.pProgRun) ;
	StringFree (r -> pApp, &r -> Component.pProgDef) ;
	ArrayFree (r -> pApp, &pDomTree -> pCheckpoints) ;
	pDomTree -> pCheckpoints = NULL ;

	pDomTree = DomTree_self (xDomTree) ;
	DomTree_delete (r -> pApp, pDomTree) ;
	*pxResultDomTree = 0 ;

	return rc ;
	}

    pDomTree = DomTree_self (xDomTree) ; /* addr may have changed */

    SvREFCNT_dec (pDomTree -> pSV) ;
    pDomTree -> pSV = NULL ;

    StringAdd (r -> pApp, &r -> Component.pProgRun, "", 1) ;
    StringAdd (r -> pApp, &r -> Component.pProgDef, r -> Component.Config.sTopInclude?r -> Component.Config.sTopInclude:"", 0) ;

    cl2 = clock () ;

    r -> Component.nPhase  = phRunAfterCompile ;
    
    l = ArrayGetSize (r -> pApp, r -> Component.pProgDef) ;
    if (l > 1 && r -> Component.Config.bDebug & dbgCompile)
	lprintf (r -> pApp,  "[%d]EPCOMP: AfterCompileTimeCode:    %*.*s\n", r -> pThread -> nPid, l, l, r -> Component.pProgDef) ; 

    if (l > 1)
	{
	pSV = newSVpvf("package %s ; %s\n%*.*s", r -> Component.sEvalPackage, use_utf8, (int)l,(int)l, r -> Component.pProgDef) ;
	newSVpvf2(pSV) ;
	args[0] = r -> _perlsv ;
	args[1] = pDomTree -> pDomTreeSV ;
	if ((rc = EvalDirect (r, pSV, 0, args)) != ok)
	    LogError (r, rc) ;
	SvREFCNT_dec(pSV);
	}

    cl3 = clock () ;
    
    r -> Component.nPhase  = phPerlCompile ;

    if (PERLDB_LINE)
	{ /* feed source to file gv (@/%_<filename) if we are running under the debugger */
	GV * pGVFile = gv_fetchfile (sSourcefile) ;
	AV * pDebugArray = GvAV (pGVFile) ;

	
	char * p = r -> Component.pBuf ;
	char * end ;
	I32    i = 1 ;
	while (*p)
	    {
	    end = strchr (p, '\n') ;
	    if (end)
		{		
		SV * pLine  ;
		pLine = newSVpv (p, end - p + 1) ;
		SvUPGRADE (pLine, SVt_PVMG) ;
		av_store (pDebugArray, i++, pLine) ;
		p = end + 1 ;
		}
	    else if (p < r -> Component.pEndPos)
		{
		SV * pLine  ;
		pLine = newSVpv (p, r -> Component.pEndPos - p + 1) ;
		SvUPGRADE (pLine, SVt_PVMG) ;
		av_store (pDebugArray, i++, pLine) ;
		break ;
		}
	    }
	if (r -> Component.Config.bDebug)
	    lprintf (r -> pApp,  "Setup source code for interactive debugger\n") ;
	}    
    
    /*
     * Does not work with perl >= 5.14
     */
#if PERL_VERSION < 14
     UndefSub (r, r -> Component.sMainSub, r -> Component.sCurrPackage) ;
#endif

    rc = EvalOnly (r, r -> Component.pProgRun, pProg, G_SCALAR, r -> Component.sMainSub) ;
    
    StringFree (r -> pApp, &r -> Component.pProgRun) ;
    StringFree (r -> pApp, &r -> Component.pProgDef) ;

    if (rc != ok && xDomTree)
	{
	pDomTree = DomTree_self (xDomTree) ;
	if (pDomTree)
	    DomTree_delete (r -> pApp, pDomTree) ;
	*pxResultDomTree = 0 ;
	}

    cl4 = clock () ;

#ifdef CLOCKS_PER_SEC
    if (r -> Component.Config.bDebug)
	{
	lprintf (r -> pApp,  "[%d]PERF: Compile Start Time:	    %d ms \n", r -> pThread -> nPid, ((cl1 - r -> startclock) * 1000 / CLOCKS_PER_SEC)) ;
	lprintf (r -> pApp,  "[%d]PERF: Compile End Time:	    %d ms \n", r -> pThread -> nPid, ((cl2 - r -> startclock) * 1000 / CLOCKS_PER_SEC)) ;
	lprintf (r -> pApp,  "[%d]PERF: After Compile Exec End Time: %d ms \n", r -> pThread -> nPid, ((cl3 - r -> startclock) * 1000 / CLOCKS_PER_SEC)) ;
	lprintf (r -> pApp,  "[%d]PERF: Perl Compile End Time:	    %d ms \n", r -> pThread -> nPid, ((cl4 - r -> startclock) * 1000 / CLOCKS_PER_SEC)) ;
	lprintf (r -> pApp,  "[%d]PERF: Compile Time:		    %d ms \n", r -> pThread -> nPid, ((cl4 - cl1) * 1000 / CLOCKS_PER_SEC)) ;
	DomStats (r -> pApp) ;
	}
#endif        

    return rc ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_Executer                                                         */
/*                                                                          */
/* ------------------------------------------------------------------------ */

static int embperl_Execute2         (/*in*/  tReq *	  r,
				     /*in*/  tIndex       xSrcDomTree,
                                     /*in*/  CV *         pCV,
				     /*in*/  tIndex  *    pResultDomTree)


    {
    epTHX_
    int rc ;
    tDomTree * pCurrDomTree ;
    clock_t	cl1 = clock () ;
    clock_t	cl2 ;
    SV *        pSV ;
    char * sSubName  ;

    tainted         = 0 ;
    r -> Component.xCurrDomTree = xSrcDomTree ;

    sSubName = r -> Component.Param.sSub ;

    if (sSubName && !*sSubName)
	sSubName = NULL ;
    rc = ok ;
    cl1 = clock () ;
    

    r -> Component.nPhase  = phRun ;

	
    r -> Component.nCurrCheckpoint = 1 ;
    r -> Component.nCurrRepeatLevel = 0 ;
    r -> Component.xSourceDomTree = r -> Component.xCurrDomTree ;
    if (!(r -> Component.xCurrDomTree  = DomTree_clone (r -> pApp, DomTree_self (xSrcDomTree), &pCurrDomTree, sSubName?1:0)))
	return 1 ;

    *pResultDomTree = r -> Component.xCurrDomTree ;
    /* -> is done by cache management -> av_push (r -> pDomTreeAV, pCurrDomTree -> pDomTreeSV) ; */
    pCurrDomTree = DomTree_self (r -> Component.xCurrDomTree) ; 
    ArrayNewZero (r -> pApp, &pCurrDomTree -> pCheckpointStatus, ArrayGetSize (r -> pApp, pCurrDomTree -> pCheckpoints), sizeof(tDomTreeCheckpointStatus)) ;

    if (pCV)
	{
	SV * args[2] ;
	STRLEN l ;
	SV * sDomTreeSV = newSVpvf ("%s::%s", r -> Component.sEvalPackage, "_ep_DomTree") ;
	SV * pDomTreeSV = perl_get_sv (SvPV (sDomTreeSV, l), TRUE) ;
	IV xOldDomTree = 0 ;
	newSVpvf2(sDomTreeSV) ;
	
	if (SvIOK (pDomTreeSV))
	    xOldDomTree = SvIVX (pDomTreeSV) ;

	sv_setiv (pDomTreeSV, r -> Component.xCurrDomTree) ;
        SvREFCNT_dec (sDomTreeSV) ;

    	av_push (r -> pCleanupAV, newRV_inc (pDomTreeSV)) ;
	
	args[0] = r -> _perlsv ;
	if (sSubName)
	    {
	    SV * pSVName = newSVpvf ("%s::_ep_sub_%s", r -> Component.sEvalPackage, sSubName) ;
	    newSVpvf2(pSVName) ;
            pCurrDomTree -> xDocument = 0 ; /* set by first checkpoint */
	    rc = CallStoredCV (r, r -> Component.pProgRun, (CV *)pSVName, 1, args, 0, &pSV) ;
	    if (pSVName)
		SvREFCNT_dec (pSVName) ;
	    if (pSV)
		SvREFCNT_dec (pSV) ;
	    }
	else
	    {
	    rc = CallStoredCV (r, r -> Component.pProgRun, (CV *)pCV, 1, args, 0, &pSV) ;
	    if (pSV)
		SvREFCNT_dec (pSV) ;
	    }

	pCurrDomTree = DomTree_self (r -> Component.xCurrDomTree) ; /* relookup DomTree in case it has moved */
	cl2 = clock () ;
#ifdef CLOCKS_PER_SEC
	if (r -> Component.Config.bDebug)
	    {
	    lprintf (r -> pApp,  "[%d]PERF: Run Start Time: %d ms \n", r -> pThread -> nPid, ((cl1 - r -> startclock) * 1000 / CLOCKS_PER_SEC)) ;
	    lprintf (r -> pApp,  "[%d]PERF: Run End Time:   %d ms \n", r -> pThread -> nPid, ((cl2 - r -> startclock) * 1000 / CLOCKS_PER_SEC)) ;
	    lprintf (r -> pApp,  "[%d]PERF: Run Time:       %d ms \n", r -> pThread -> nPid, ((cl2 - cl1) * 1000 / CLOCKS_PER_SEC)) ;
	    DomStats (r -> pApp) ;
	    }
#endif    

	sv_setiv (pDomTreeSV, xOldDomTree) ;
	}

    ArrayFree (r -> pApp, &pCurrDomTree -> pCheckpointStatus) ;

    if (rc != ok && rc != rcEvalErr)
        return rc ;

    r -> Component.nPhase  = phTerm ;
    
    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_Execute                                                          */
/*                                                                          */
/* ------------------------------------------------------------------------ */

int embperl_Execute	            (/*in*/  tReq *	  r,
				     /*in*/  tIndex       xSrcDomTree,
                                     /*in*/  CV *         pCV,
				     /*in*/  tIndex  *    pResultDomTree)


    {
    epTHX_
    int	    rc  = ok ;
    char *  sSourcefile = r -> Component.sSourcefile  ; 
    
    tainted         = 0 ;

    if (!r -> bError)
	{
        tComponent * c = &r -> Component ;
        GV * gv ;
        HV * pStash = gv_stashpv (c -> sCurrPackage, 1) ;

        
        if (r -> Component.Config.nCleanup > -1 && (r -> Component.Config.bOptions & optDisableVarCleanup) == 0)
            SetHashValueInt (r, r -> pCleanupPackagesHV, r -> Component.sCurrPackage, 1) ;
        
        /* --- change working directory --- */
        if (r -> Component.Config.bOptions & optChdirToSource)
            ChdirToSource (r, sSourcefile) ; 


        if (c -> Param.pParam)
            {
            gv = *((GV **)hv_fetch    (pStash, "param", 5, 0)) ;
            /* gv = r -> pThread -> pParamArrayGV ; */
            save_ary (gv) ;
            SvREFCNT_dec((SV *)GvAV(gv)) ;
            GvAV(gv) = (AV *)SvREFCNT_inc(c -> Param.pParam) ;
            }
    
        if (c -> Param.pFormHash)
            {
            gv = *((GV **)hv_fetch    (pStash, "fdat", 4, 0)) ;
            /* gv = r -> pThread -> pFormHashGV ; */
            save_hash (gv) ;
            SvREFCNT_dec((SV *)GvHV(gv)) ;
            GvHV(gv) = (HV *)SvREFCNT_inc(c -> Param.pFormHash) ;
            }

        if (c -> Param.pFormArray || c -> Param.pFormHash)
            {
            gv = *((GV **)hv_fetch    (pStash, "ffld", 4, 0)) ;
            /* gv = r -> pThread -> pFormArrayGV ; */
            save_ary (gv) ;
            SvREFCNT_dec((SV *)GvAV(gv)) ;
            if (c -> Param.pFormArray)
                GvAV(gv) = (AV *)SvREFCNT_inc(c -> Param.pFormArray) ;
            else
                {
                /* SVREFCNT_dec (pAV) is done by LEAVE, because of save_ary above (you can savely ignore dmalloc logged error) */
                AV * pAV = newAV ();
                HE *   pEntry ;
                char * pKey ;
                I32    l ;
                GvAV(gv) = pAV ;
                hv_iterinit (c -> Param.pFormHash) ;
                while ((pEntry = hv_iternext (c -> Param.pFormHash)))
                    {
                    pKey = hv_iterkey (pEntry, &l) ;
                    av_push (pAV, newSVpv(pKey, l)) ;
                    }
                }
            
            }
        else
            {
            


            }
        
        rc = embperl_Execute2 (r, xSrcDomTree, pCV, pResultDomTree) ;


	/* --- restore working directory --- */
        if (r -> Component.sResetDir[0])
	    {
#ifdef WIN32
   	    _chdrive (r -> Component.nResetDrive) ;
#endif
	    chdir (r -> Component.sResetDir) ;
	    strcpy (r -> Component.sCWD,r -> Component.sResetDir) ;
	    r -> Component.sResetDir[0] = '\0' ;
            }
        }
    else
        *pResultDomTree = 0 ;

    r -> Component.nPhase  = phTerm ;
    
    return rc ;
    }



/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_ExecuteSubStart                                                  */
/*                                                                          */
/* Setup the start of a sub                                                 */
/*                                                                          */
/* in   pDomTreeSV	SV which holds the DomTree in the current package   */
/* in   xDomTree	Source DomTree                                      */
/* in   pSaveAV		Array to save some values                           */
/*                                                                          */
/* ------------------------------------------------------------------------ */


int embperl_ExecuteSubStart         (/*in*/  tReq *	  r,
				     /*in*/  SV *         pDomTreeSV,
				     /*in*/  tIndex       xDomTree,
				     /*in*/  AV *         pSaveAV)

    {
    epTHX_
    tIndex xOrgDomTree = -1  ;
    tIndex xOldDomTree  ;
    tDomTree * pDomTree ;
    tDomTree * pCurrDomTree ;

    if (!r || !r -> Component.bReqRunning)
    	{
    	LogErrorParam (r?r -> pApp:NULL, rcSubCallNotRequest, "", "") ;
    	return rcSubCallNotRequest ;
    	}

    av_push (pSaveAV, newSViv (r -> Component.xCurrDomTree)) ;
    av_push (pSaveAV, newSViv (r -> Component.xCurrNode)) ;
    av_push (pSaveAV, newSViv (r -> Component.nCurrRepeatLevel)) ;
    av_push (pSaveAV, newSViv (r -> Component.nCurrCheckpoint)) ;
    av_push (pSaveAV, newSViv (r -> Component.bSubNotEmpty)) ;

    pDomTree = DomTree_self (xDomTree) ;

    xOldDomTree = r -> Component.xCurrDomTree ;

    if (!(r -> Component.xCurrDomTree  = DomTree_clone (r -> pApp, pDomTree, &pCurrDomTree, 1)))
	    return 0 ;
    ArrayNewZero (r -> pApp, &pCurrDomTree -> pCheckpointStatus, ArrayGetSize (r -> pApp, pCurrDomTree -> pCheckpoints), sizeof(tDomTreeCheckpointStatus)) ;
    r -> Component.nCurrCheckpoint  = 1 ;
    r -> Component.nCurrRepeatLevel = 0 ;
    r -> Component.xCurrNode        = 0 ;  
    r -> Component.bSubNotEmpty     = 0 ;
    pCurrDomTree -> xDocument       = 0 ; /* set by first checkpoint */
    
    av_push (r -> pDomTreeAV, pCurrDomTree -> pDomTreeSV) ;
    av_push (r -> pCleanupAV, newRV_inc (pDomTreeSV)) ;

    sv_setiv (pDomTreeSV, r -> Component.xCurrDomTree) ;

    if (r -> Component.Config.bDebug & dbgRun)
	lprintf (r -> pApp,  "[%d]SUB: Enter from DomTree=%d into new DomTree=%d, Source DomTree=%d (org=%d)\n", r -> pThread -> nPid, xOldDomTree, r -> Component.xCurrDomTree, xDomTree, xOrgDomTree) ; 

    return r -> Component.xCurrDomTree ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_ExecuteSubEnd                                                    */
/*                                                                          */
/* End a sub                                                                */
/*                                                                          */
/* in   pSaveAV		Array to save some values                           */
/*                                                                          */
/* ------------------------------------------------------------------------ */


int embperl_ExecuteSubEnd           (/*in*/  tReq *	  r,
				     /*in*/  SV *         pDomTreeSV,
				     /*in*/  AV *         pSaveAV)

    {
    epTHX_
    tIndex xSubDomTree = r -> Component.xCurrDomTree ;
    tIndex xDocFraq ;
    int    bSubNotEmpty = r -> Component.bSubNotEmpty ;
    tDomTree * pCallerDomTree  ;
    tDomTree * pSubDomTree = DomTree_self (xSubDomTree) ;

    if (AvFILL (pSaveAV) < 1)
	return ok ;
    
    if (r -> Component.xCurrNode == 0)
        bSubNotEmpty = 1 ;

    ArrayFree (r -> pApp, &pSubDomTree -> pCheckpointStatus) ;

    r -> Component.xCurrDomTree = SvIV (* av_fetch (pSaveAV, 0, 0)) ;
    r -> Component.xCurrNode    = SvIV (* av_fetch (pSaveAV, 1, 0)) ;
    r -> Component.nCurrRepeatLevel = (tRepeatLevel)SvIV (* av_fetch (pSaveAV, 2, 0)) ;
    r -> Component.nCurrCheckpoint = SvIV (* av_fetch (pSaveAV, 3, 0)) ;
    r -> Component.bSubNotEmpty = SvIV (* av_fetch (pSaveAV, 4, 0)) + bSubNotEmpty;

    sv_setiv (pDomTreeSV, r -> Component.xCurrDomTree) ;
    pCallerDomTree = DomTree_self (r -> Component.xCurrDomTree) ;

    if (bSubNotEmpty && r -> Component.xCurrNode)
        r -> Component.xCurrNode = xDocFraq = Node_insertAfter (r -> pApp, pSubDomTree, pSubDomTree -> xDocument, 0, pCallerDomTree, r -> Component.xCurrNode, r -> Component.nCurrRepeatLevel) ;

    if (r -> Component.Config.bDebug & dbgRun)
	lprintf (r -> pApp,  "[%d]SUB: Leave from DomTree=%d back to DomTree=%d RepeatLevel=%d\n", r -> pThread -> nPid, xSubDomTree, r -> Component.xCurrDomTree, r -> Component.nCurrRepeatLevel) ; 

    return ok ;
    }

