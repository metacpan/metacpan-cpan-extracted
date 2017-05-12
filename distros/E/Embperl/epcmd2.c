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
#   $Id: epcmd2.c 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################*/


#include "ep.h"
#include "epmacro.h"

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Split values in from %fdat                                                   */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


SV * SplitFdat     (/*i/o*/ register req * r,
                           /*in*/  SV ** ppSVfdat,
                           /*out*/ SV ** ppSVerg,
                           /*in*/  char * pName,
                           /*in*/  STRLEN nlen)

    {
    epTHX_
    STRLEN dlen ;
    char * pData ;
    char * s ;
    char * p ;
    
    if (ppSVerg && *ppSVerg && SvTYPE (*ppSVerg))
        {
        return *ppSVerg ;
        }

    pData = SvPV (*ppSVfdat, dlen) ;
    s = pData ;

    if ((p = strchr (s, r -> Config.cMultFieldSep)))
        { /* Multiple values -> put them into a hash */
        HV * pHV = newHV () ;
        int l ;

        while (p)
            {
            hv_store (pHV, s, p - s, &sv_undef, 0) ;
            s = p + 1 ;
            p = strchr (s, r -> Config.cMultFieldSep) ;
            }

        l = dlen - (s - pData) ;
        if (l > 0)
            hv_store (pHV, s, l, &sv_undef, 0) ;
        hv_store (r -> pThread -> pFormSplitHash, (char *)pName, nlen, (SV *)pHV, 0) ;
        if (r -> Component.Config.bDebug & dbgInput)
            lprintf (r -> pApp,  "[%d]INPU: <mult values>\n", r -> pThread -> nPid) ; 
        return (SV *)pHV;
        }
    else
        {
        SvREFCNT_inc (*ppSVfdat) ;
        hv_store (r -> pThread -> pFormSplitHash, (char *)pName, nlen, *ppSVfdat, 0) ;
        if (r -> Component.Config.bDebug & dbgInput)
            lprintf (r -> pApp,  "[%d]INPU: value = %s\n", r -> pThread -> nPid, SvPV(*ppSVfdat, na)) ; 
        return *ppSVfdat ;
        }
    }    

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* SetRemove Attribute on html tag ...                                          */
/*                                                                              */
/* ---------------------------------------------------------------------------- */



static void embperlCmd_SetRemove (/*i/o*/ register req * r,
			     /*in*/ tDomTree *	    pDomTree,
			     /*in*/ tNode	    xNode,
			     /*in*/ tRepeatLevel    nRepeatLevel,
			     /*in*/ const char *    pName,
			     /*in*/ int             nNameLen,
			     /*in*/ const char *    pVal,
			     /*in*/ int             nValLen,
			     /*in*/ const char *    sAttrName, 
			     /*in*/ int             nAttrLen,
                             /*in*/ int             bSetInSource) 

    {
    epTHX_
    int	    bEqual = 0 ;
    SV **   ppSV = hv_fetch(r -> pThread -> pFormHash, (char *)pName, nNameLen, 0) ;  
    tNodeData * pNode = Node_selfLevel (r -> pApp, pDomTree, xNode, nRepeatLevel) ;
    SV *    pInputHashValue = NULL ;
    char * tmp = NULL ;

    if (ppSV)
	{
	SV **   ppSVerg = hv_fetch(r -> pThread -> pFormSplitHash, (char *)pName, nNameLen, 0) ;  
	SV *    pSV = SplitFdat (r, ppSV, ppSVerg, (char *)pName, nNameLen) ;
        tmp = malloc (nValLen) ;
        memcpy (tmp, pVal, nValLen) ;
        pVal = tmp ;
	
        if (SvTYPE (pSV) == SVt_PVHV)
	    { /* -> Hash -> check if key exists */
            nValLen = TransHtml (r, (char *)pVal, nValLen) ;
            if (hv_exists ((HV *)pSV, (char *)pVal, nValLen))
		{
		bEqual = 1 ;
		pInputHashValue = newSVpv ((nValLen?((char *)pVal):""), nValLen) ;
		}
	    }
	else
	    {
	    STRLEN   dlen ;
	    char * pData = SvPV (pSV, dlen) ;
            nValLen = TransHtml (r, (char *)pVal, nValLen) ;
	    if ((int)dlen == nValLen && strncmp (pVal, pData, dlen) == 0)
		{
		bEqual = 1 ;
		pInputHashValue = newSVsv(pSV) ; 
		}
	    }

	if (bEqual)
	    {
	    if (r -> Config.nOutputMode)   
	        Element_selfSetAttribut (r -> pApp, pDomTree, pNode, nRepeatLevel, sAttrName, nAttrLen, sAttrName, nAttrLen) ;
	    else    
	        Element_selfSetAttribut (r -> pApp, pDomTree, pNode, nRepeatLevel, sAttrName, nAttrLen, NULL, 0) ;
	    if (r -> Component.Config.bDebug & dbgInput)
		lprintf (r -> pApp,  "[%d]INPU: Set Attribut: Name: '%*.*s' Value: '%*.*s' Attribute: '%*.*s' nRepeatLevel=%d\n", r -> pThread -> nPid, nNameLen, nNameLen, pName, nValLen, nValLen, pVal, nAttrLen, nAttrLen, sAttrName, nRepeatLevel) ; 
            }
	else
	    {
	    Element_selfRemoveAttribut (r -> pApp, pDomTree, pNode, nRepeatLevel, sAttrName, nAttrLen) ;
	    if (r -> Component.Config.bDebug & dbgInput)
		lprintf (r -> pApp,  "[%d]INPU: Remove Attribut: Name: '%*.*s' Value: '%*.*s' Attribute: '%*.*s' nRepeatLevel=%d\n", r -> pThread -> nPid, nNameLen, nNameLen, pName, nValLen, nValLen, pVal, nAttrLen, nAttrLen, sAttrName, nRepeatLevel ) ; 
	    }
	}
    else
	{
	if (Element_selfGetAttribut (r -> pApp, pDomTree, pNode, sAttrName, nAttrLen))
	    {
	    hv_store (r -> pThread -> pInputHash, (char *)pName, nNameLen, newSVpv ((nValLen?((char *)pVal):""), nValLen), 0) ;
	    if (r -> Component.Config.bDebug & dbgInput)
		lprintf (r -> pApp,  "[%d]INPU: Has already Attribut: Name: '%*.*s' Value: '%*.*s' Attribute: '%*.*s' nRepeatLevel=%d\n", r -> pThread -> nPid, nNameLen, nNameLen, pName, nValLen, nValLen, pVal, nAttrLen, nAttrLen, sAttrName, nRepeatLevel ) ; 
	    }
	else
	    {
	    if (r -> Component.Config.bDebug & dbgInput)
		lprintf (r -> pApp,  "[%d]INPU: No value in %%fdat for Attribut: Name: '%*.*s' Value: '%*.*s' Attribute: '%*.*s' nRepeatLevel=%d\n", r -> pThread -> nPid, nNameLen, nNameLen, pName?pName:"", nValLen, nValLen, pVal?pVal:"", nAttrLen, nAttrLen, sAttrName, nRepeatLevel ) ; 
            }

	}

    if (pInputHashValue)
        hv_store (r -> pThread -> pInputHash, (char *)pName, nNameLen, pInputHashValue, 0) ; 
    else
        {
        if (!hv_exists (r -> pThread -> pInputHash, (char *)pName, nNameLen))
            hv_store (r -> pThread -> pInputHash, (char *)pName, nNameLen, newSVpv ("", 0), 0) ; 
        }

    if (tmp)
        free (tmp) ;
    
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* input checkbox/radio html tag ...                                            */
/*                                                                              */
/* ---------------------------------------------------------------------------- */



void embperlCmd_InputCheck (/*i/o*/ register req *     r,
			    /*in*/ tDomTree *	    pDomTree,
			    /*in*/ tNode	    xNode,
			    /*in*/ tRepeatLevel     nRepeatLevel,
			    /*in*/ const char *     pName,
			    /*in*/ int              nNameLen,
			    /*in*/ const char *     pVal,
			    /*in*/ int              nValLen, 
                            /*in*/ int              bSetInSource) 

    {
    embperlCmd_SetRemove (r, pDomTree, xNode, nRepeatLevel, pName, nNameLen, pVal, nValLen, "checked", 7, bSetInSource) ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* option html tag ...                                                          */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


void embperlCmd_Option (/*i/o*/ register req *  r,
			/*in*/ tDomTree *	pDomTree,
			/*in*/ tNode	        xNode,
		        /*in*/ tRepeatLevel     nRepeatLevel,
			/*in*/ const char *     pName,
			/*in*/ int              nNameLen,
			/*in*/ const char *     pVal,
			/*in*/ int              nValLen,
                        /*in*/ int              bSetInSource) 
                         

    {
    embperlCmd_SetRemove (r, pDomTree, xNode, nRepeatLevel, pName, nNameLen, pVal, nValLen, "selected", 8, bSetInSource) ;
    }





/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* hidden command ...                                                           */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


int embperlCmd_Hidden	(/*i/o*/ register req *     r,
			 /*in*/ tDomTree *	    pDomTree,
			 /*in*/ tNode		    xNode,
		         /*in*/ tRepeatLevel	    nRepeatLevel,
			 /*in*/ const char *	    sArg)

    {
    epTHX_
    char *  pKey ;
    SV *    psv ;
    SV * *  ppsv ;
    HV *    pAddHash = r -> pThread -> pFormHash ;
    HV *    pSubHash = r -> pThread -> pInputHash ;
    AV *    pSort    = NULL ;
    HE *    pEntry ;
    I32     l ;
    char *  sArgs ;
    char *  sVarName ;
    char    sVar[512] ;
    int     nMax ;
    STRLEN  nKey ;
    tNodeData * pNode ;
    tNodeData * pNewNode ;


    EPENTRY (CmdHidden) ;

    pNode = Node_selfCondCloneNode (r -> pApp, pDomTree, Node_selfLevel (r -> pApp, pDomTree, xNode, nRepeatLevel), nRepeatLevel) ;

    pNewNode = pNode ;

    sArgs = _ep_strdup (r, sArg) ;
    if (sArgs && *sArgs != '\0')
        {            
        strncpy (sVar, r -> Component.sEvalPackage, sizeof (sVar) - 5) ;
        sVar[r -> Component.nEvalPackage] = ':' ;
        sVar[r -> Component.nEvalPackage+1] = ':' ;
        sVar[sizeof(sVar) - 1] = '\0' ;
        nMax = sizeof(sVar) - r -> Component.nEvalPackage - 3 ;
        
        if ((sVarName = strtok (sArgs, ", \t\n")))
            {
            if (*sVarName == '%')
                sVarName++ ;
        
            strncpy (sVar + r -> Component.nEvalPackage + 2, sVarName, nMax) ;
            
            if ((pAddHash = perl_get_hv ((char *)sVar, FALSE)) == NULL)
                {
                strncpy (r -> errdat1, sVar, sizeof (r -> errdat1) - 1) ;
                _free (r, sArgs) ;
                return rcHashError ;
                }

            if ((sVarName = strtok (NULL, ", \t\n")))
                {
                if (*sVarName == '%')
                    sVarName++ ;
        
                strncpy (sVar + r -> Component.nEvalPackage + 2, sVarName, nMax) ;
        
                if ((pSubHash = perl_get_hv ((char *)sVar, FALSE)) == NULL)
                    {
                    strncpy (r -> errdat1, sVar, sizeof (r -> errdat1) - 1) ;
                    _free (r, sArgs) ;
                    return rcHashError ;
                    }

                if ((sVarName = strtok (NULL, ", \t\n")))
                    {
                    if (*sVarName == '@')
                        sVarName++ ;
        
                    strncpy (sVar + r -> Component.nEvalPackage + 2, sVarName, nMax) ;
        
                    if ((pSort = perl_get_av ((char *)sVar, FALSE)) == NULL)
                        {
                        strncpy (r -> errdat1, sVar, sizeof (r -> errdat1) - 1) ;
                        _free (r, sArgs) ;
                        return rcArrayError ;
                        }
                    }
                }
            }
        }
    else
        pSort = r -> pThread -> pFormArray ;


    /* oputc (r, '\n') ; */
    if (pSort)
        {
        int n = AvFILL (pSort) + 1 ;
        int i ;

        for (i = 0; i < n; i++)
            {
            ppsv = av_fetch (pSort, i, 0) ;
            if (ppsv && (pKey = SvPV(*ppsv, nKey)) && !hv_exists (pSubHash, pKey, nKey))
                {
                STRLEN lppsv ;
		ppsv = hv_fetch (pAddHash, pKey, nKey, 0) ;
                
               if (ppsv && (!(r -> Component.Config.bOptions & optNoHiddenEmptyValue) || *SvPV (*ppsv, lppsv)))
                    {
                    char * s ;
		    STRLEN     l ;
                    SV * sEscapedText ;
		    tNode xInputNode = Node_appendChild (r -> pApp, pDomTree, pNewNode -> xNdx, nRepeatLevel, ntypTag, 0, "input", 5, 0, 0, NULL) ;
                    tNode xAttr      = Node_appendChild (r -> pApp, pDomTree, xInputNode, nRepeatLevel, ntypAttr, 0, "type", 4, 0, 0, NULL) ;
                                       Node_appendChild (r -> pApp, pDomTree, xAttr, nRepeatLevel, ntypAttrValue, 0, "hidden", 6, 0, 0, NULL) ;
		    
                          xAttr      = Node_appendChild (r -> pApp, pDomTree, xInputNode, nRepeatLevel, ntypAttr, 0, "name", 4, 0, 0, NULL) ;
                                       Node_appendChild (r -> pApp, pDomTree, xAttr, nRepeatLevel, ntypAttrValue, 0, pKey, nKey, 0, 0, NULL) ;
                          xAttr      = Node_appendChild (r -> pApp, pDomTree, xInputNode, nRepeatLevel, ntypAttr, 0, "value", 5, 0, 0, NULL) ;

		    s = SvPV (*ppsv, l) ;			  
                    sEscapedText = Escape (r, s, l, r -> Component.nCurrEscMode, NULL, '\0') ;
                    s = SV2String (sEscapedText, l) ;
			  
	            Node_appendChild (r -> pApp, pDomTree, xAttr, nRepeatLevel, ntypAttrValue, 0, s, l, 0, 0, NULL) ;
                    SvREFCNT_dec (sEscapedText) ;
                    }
                }
            }
        }
    else
        {
        hv_iterinit (pAddHash) ;
        while ((pEntry = hv_iternext (pAddHash)))
            {
            STRLEN nKey ;
	    pKey = hv_iterkey (pEntry, &l) ;
	    nKey = strlen (pKey) ;
            if (!hv_exists (pSubHash, pKey, nKey))
                {
                STRLEN lpsv ;
		psv = hv_iterval (pAddHash, pEntry) ;

                if (!(r -> Component.Config.bOptions & optNoHiddenEmptyValue) || *SvPV (psv, lpsv)) 
                    {
                    char * s ;
		    STRLEN     l ;
                    SV * sEscapedText ;
		    tNode xInputNode = Node_appendChild (r -> pApp, pDomTree, pNewNode -> xNdx, nRepeatLevel, ntypTag, 0, "input", 5, 0, 0, NULL) ;
                    tNode xAttr      = Node_appendChild (r -> pApp, pDomTree, xInputNode, nRepeatLevel, ntypAttr, 0, "type", 4, 0, 0, NULL) ;
                                       Node_appendChild (r -> pApp, pDomTree, xAttr, nRepeatLevel, ntypAttrValue, 0, "hidden", 6, 0, 0, NULL) ;
		    
                          xAttr      = Node_appendChild (r -> pApp, pDomTree, xInputNode, nRepeatLevel, ntypAttr, 0, "name", 4, 0, 0, NULL) ;
                                       Node_appendChild (r -> pApp, pDomTree, xAttr, nRepeatLevel, ntypAttrValue, 0, pKey, nKey, 0, 0, NULL) ;
                          xAttr      = Node_appendChild (r -> pApp, pDomTree, xInputNode, nRepeatLevel, ntypAttr, 0, "value", 5, 0, 0, NULL) ;

		    s = SvPV (psv, l) ;			  
                    sEscapedText = Escape (r, s, l, r -> Component.nCurrEscMode, NULL, '\0') ;
                    s = SV2String (sEscapedText, l) ;
			  
	            Node_appendChild (r -> pApp, pDomTree, xAttr, nRepeatLevel, ntypAttrValue, 0, s, l, 0, 0, NULL) ;
                    SvREFCNT_dec (sEscapedText) ;
                    }
                }
            }
        }

    if (sArgs)
        _free (r, sArgs) ;

    return ok ;
    }




/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* ouput data inside a url                                                      */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


SV * Node_replaceChildWithUrlDATA (/*in*/ tReq *        r,
                                   /*in*/ tIndex	xDomTree, 
					  tIndex	xOldChild, 
				   /*in*/ tRepeatLevel  nRepeatLevel,
					  SV *		sText)
    
    {
    epTHX_
    STRLEN l ;
    char * s ;
    AV *   pAV ;    
    HV *   pHV ;    
    tDomTree * pDomTree = DomTree_self(xDomTree) ;

    if (SvROK(sText) && SvTYPE((pAV = (AV *)SvRV(sText))) == SVt_PVAV)
	{ /* Array reference inside URL */
	SV ** ppSV ;
	int i ;
	int f = AvFILL(pAV)  ;
        tNode xNode ;

        xOldChild = Node_replaceChildWithCDATA (r -> pApp, DomTree_self(xDomTree), xOldChild, nRepeatLevel, "", 0, 4, 0) ;

	for (i = 0; i <= f; i++)
	    {
	    ppSV = av_fetch (pAV, i, 0) ;
	    if (ppSV && *ppSV)
		{
		s = SV2String (*ppSV, l) ;
                xNode = Node_appendChild (r -> pApp, pDomTree, xOldChild, nRepeatLevel, (tNodeType)((r -> Component.nCurrEscMode & 3)?ntypTextHTML:ntypCDATA), 0, s, l, 0, 0, NULL) ;
		if (r -> Component.nCurrEscMode & 2) 
                    Node_selfLevel (r -> pApp, pDomTree, xNode, nRepeatLevel) -> bFlags |= nflgEscUrl ;
                }
	    if ((i & 1) == 0)
                Node_appendChild (r -> pApp, pDomTree, xOldChild, nRepeatLevel, ntypCDATA, 0, "=", 1, 0, 0, NULL) ;
	    else if (i < f)
                Node_appendChild (r -> pApp, pDomTree, xOldChild, nRepeatLevel, ntypCDATA, 0, "&amp;", 5, 0, 0, NULL) ;
	    }
    
	}

    else if (SvROK(sText) && SvTYPE((pHV = (HV *)SvRV(sText))) == SVt_PVHV)
	{ /* Hash reference inside URL */
        HE *	    pEntry ;
        char *	    pKey ;
        SV * 	    pSVValue ;
        tNode       xNode ;
        int         i = 0 ;
	I32	    l32 ;

        lprintf (r -> pApp, "xOldChild=%d, rl=%d\n", xOldChild, nRepeatLevel) ;
        xOldChild = Node_replaceChildWithCDATA (r -> pApp, DomTree_self(xDomTree), xOldChild, nRepeatLevel, "", 0, 4, 0) ;
        lprintf (r -> pApp, "a xOldChild=%d, rl=%d\n", xOldChild, nRepeatLevel) ;

	hv_iterinit (pHV) ;
	while ((pEntry = hv_iternext (pHV)))
	    {
            if (i++ > 0)
                Node_appendChild (r -> pApp, pDomTree, xOldChild, nRepeatLevel, ntypCDATA, 0, "&amp;", 5, 0, 0, NULL) ;
	    pKey     = hv_iterkey (pEntry, &l32) ;
            xNode = Node_appendChild (r -> pApp, pDomTree, xOldChild, nRepeatLevel, (tNodeType)((r -> Component.nCurrEscMode & 3)?ntypTextHTML:ntypCDATA), 0, pKey, l32, 0, 0, NULL) ;
	    if (r -> Component.nCurrEscMode & 2) 
                Node_self (pDomTree, xNode) -> bFlags |= nflgEscUrl ;

            Node_appendChild (r -> pApp, pDomTree, xOldChild, nRepeatLevel, ntypCDATA, 0, "=", 1, 0, 0, NULL) ;

	    pSVValue = hv_iterval (pHV , pEntry) ;
	    if (pSVValue)
		{
		s = SV2String (pSVValue, l) ;
                xNode = Node_appendChild (r -> pApp, pDomTree, xOldChild, nRepeatLevel, (tNodeType)((r -> Component.nCurrEscMode & 3)?ntypTextHTML:ntypCDATA), 0, s, l, 0, 0, NULL) ;
		if (r -> Component.nCurrEscMode & 2) 
                    Node_selfLevel (r -> pApp, pDomTree, xNode, nRepeatLevel) -> bFlags |= nflgEscUrl ;
                }
            }
        }
    else
        {
        char * s = SV2String (sText, l) ;
        Node_replaceChildWithCDATA (r -> pApp, DomTree_self(xDomTree), xOldChild, nRepeatLevel, s, l, (r -> Component.nCurrEscMode & 3) == 3?2 + (r -> Component.nCurrEscMode & 4):r -> Component.nCurrEscMode, 0) ;
        }

    r -> Component.nCurrEscMode = r -> Component.Config.nEscMode ;
    r -> Component.bEscModeSet = -1 ;
    /* SvREFCNT_inc (sText) ; */
    /* ST(0) = sText ;*/
    /* XSRETURN(1) ; */
    return sText ;
    }




/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* AddSessionIdToLink                                                           */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


int embperlCmd_AddSessionIdToLink  (/*i/o*/ register req *     r,
			            /*in*/ tDomTree *	    pDomTree,
			            /*in*/ tNode		    xNode,
		                    /*in*/ tRepeatLevel	    nRepeatLevel,
                                    /*in*/ char *            sAttrName)

    {
    tNodeData * pNode ;
    tAttrData * pAttr ;
    int         nAttrLen ;
    char      * pAttrString = NULL ;
    char      * pAttrValue ;
    int         l ;
    int         sl ;

    if (!r -> sSessionID)
        return ok ;

    pNode = Node_self(pDomTree,xNode) ;
    nAttrLen = strlen (sAttrName) ;
    pAttr = Element_selfGetAttribut (r -> pApp, pDomTree, pNode, sAttrName, nAttrLen) ;
    if (!pAttr)
        return ok ;

    pAttrValue = Attr_selfValue (r -> pApp, pDomTree, pAttr, nRepeatLevel, &pAttrString) ;

    sl = strlen (r -> sSessionID) ;
    if (!pAttrString)
        {
        l = strlen (pAttrValue) ;
        StringNew (r -> pApp, &pAttrString, l + 10 + sl) ;
	StringAdd (r -> pApp, &pAttrString, pAttrValue, l) ;
        
        }
    
    if (strchr(pAttrValue, '?'))
        {
        StringAdd (r -> pApp, &pAttrString, "&", 1) ;
        }
    else
        {
        StringAdd (r -> pApp, &pAttrString, "?", 1) ;
        }
    StringAdd (r -> pApp, &pAttrString, r -> sSessionID, sl) ;

    Element_selfSetAttribut (r -> pApp, pDomTree, pNode, nRepeatLevel, sAttrName, nAttrLen, pAttrString, ArrayGetSize (r -> pApp, pAttrString)) ;

    StringFree (r -> pApp, &pAttrString) ;

    return ok ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* AddSessionIdToHidden                                                         */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


int embperlCmd_AddSessionIdToHidden(/*i/o*/ register req *     r,
			            /*in*/ tDomTree *	    pDomTree,
			            /*in*/ tNode		    xNode,
		                    /*in*/ tRepeatLevel	    nRepeatLevel)

    {
    char * sid = r -> sSessionID ;
    tNodeData * pNode ;

    pNode = Node_self(pDomTree,xNode) ;
    if (sid)
        {
	char * val = strchr (sid, '=') ;
	if (val)
            {
            tNode xInputNode = Node_appendChild (r -> pApp, pDomTree, pNode -> xNdx,  nRepeatLevel, ntypTag, 0, "input", 5, 0, 0, NULL) ;
            tNode xAttr      = Node_appendChild (r -> pApp, pDomTree, xInputNode, nRepeatLevel, ntypAttr, 0, "type", 4, 0, 0, NULL) ;
                               Node_appendChild (r -> pApp, pDomTree, xAttr, nRepeatLevel, ntypAttrValue, 0, "hidden", 6, 0, 0, NULL) ;
    
                  xAttr      = Node_appendChild (r -> pApp, pDomTree, xInputNode, nRepeatLevel, ntypAttr, 0, "name", 4, 0, 0, NULL) ;
                               Node_appendChild (r -> pApp, pDomTree, xAttr, nRepeatLevel, ntypAttrValue, 0, sid, val - sid, 0, 0, NULL) ;
                  xAttr      = Node_appendChild (r -> pApp, pDomTree, xInputNode, nRepeatLevel, ntypAttr, 0, "value", 5, 0, 0, NULL) ;
	                       Node_appendChild (r -> pApp, pDomTree, xAttr, nRepeatLevel, ntypAttrValue, 0, val+1, strlen(val+1), 0, 0, NULL) ;
            }
        }
    
    return ok ;
    }
