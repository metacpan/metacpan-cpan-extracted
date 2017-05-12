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
#   $Id: epparse.c 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################*/


#include "ep.h"
#include "epmacro.h"



struct tTokenCmp
    {
    char *          pStart ;
    char *          pCurr ;
    int		nLen ;
    } ;



struct tTokenTable DefaultTokenTable ;


#define parse_malloc(a,b) malloc(b)

/* ------------------------------------------------------------------------ */
/* compare tokens                                                           */
/* ------------------------------------------------------------------------ */

static int CmpToken (/*in*/ const void *  p1,
                     /*in*/ const void *  p2)

    {
    return strcmp (*((const char * *)p1), *((const char * *)p2)) ;
    }
    
/* ------------------------------------------------------------------------ */
/* compare tokens                                                           */
/* ------------------------------------------------------------------------ */

static int RevCmpToken (/*in*/ const void *  p1,
                     /*in*/ const void *  p2)

    {
    return strcmp (*((const char * *)p2), *((const char * *)p1)) ;
    }
    
/* ------------------------------------------------------------------------ */
/* compare tokens for descending order                                      */
/* ------------------------------------------------------------------------ */

static int CmpTokenDesc (/*in*/ const void *  p1,
                     /*in*/ const void *  p2)

    {
    int i = strcmp (*((const char * *)p2), *((const char * *)p1)) ; 
    return i?i:strcmp (((const char * *)p1)[1], ((const char * *)p2)[1]) ; 
    }


	    
/* ------------------------------------------------------------------------ */
/*                                                                          */
/* CheckProcInfo                                                            */
/*                                                                          */
/* Check for processor information                                         */
/*                                                                          */
/* ------------------------------------------------------------------------ */

static int CheckProcInfo      (/*i/o*/ register req * r,
			/*in*/  HV *           pHash,
			/*in*/	struct tToken * pToken,
			/*i/o*/ void * *       ppCompilerInfo)
			

    {	
    HE *	    pEntry ;
    char *	    pKey ;
    SV * *	    ppSV ;
    SV * 	    pSVValue ;
    I32		    l	 ;
    HV *            pHVProcInfo ;
    int             n ;
    int             i ;
    int             m ;
    typedef struct tSortToken
        {
        char *	    pKey ;
        SV *	    pSVValue ;
        } tSortToken ;
    tSortToken * pSortTokenHash ;    
    epTHX ;
    
    ppSV = hv_fetch(pHash, "procinfo", sizeof ("procinfo") - 1, 0) ;  
    if (ppSV != NULL)
	{		
	if (*ppSV == NULL || !SvROK (*ppSV) || SvTYPE (SvRV (*ppSV)) != SVt_PVHV)
	    {
	    strncpy (r -> errdat1, "BuildTokenHash", sizeof (r -> errdat1)) ;
	    sprintf (r -> errdat2, "%s => procinfo", pToken -> sText) ;
	    return rcNotHashRef ;
	    }

	pHVProcInfo = (HV *)SvRV (*ppSV) ;

        m = 0 ;
        n = HvKEYS (pHVProcInfo) ;
        pSortTokenHash = (tSortToken *)malloc (sizeof (struct tSortToken) * n) ;
        hv_iterinit (pHVProcInfo) ;
        while ((pEntry = hv_iternext (pHVProcInfo)))
            {
            pKey     = hv_iterkey (pEntry, &l) ;
            pSVValue   = hv_iterval (pHVProcInfo, pEntry) ;
    
            pSortTokenHash[m].pKey = pKey ;    
            pSortTokenHash[m].pSVValue = pSVValue ;    
            m++ ;
            }
    
        qsort (pSortTokenHash, m, sizeof (struct tSortToken), RevCmpToken) ;
    
        i = 0 ;
        while (i < m)
            {
            pKey     = pSortTokenHash[i].pKey ;
            pSVValue   = pSortTokenHash[i].pSVValue ;
            i++ ;
        
	    if (pSVValue == NULL || !SvROK (pSVValue) || SvTYPE (SvRV (pSVValue)) != SVt_PVHV)
		{
		strncpy (r -> errdat1, "BuildTokenHash", sizeof (r -> errdat1)) ;
		sprintf (r -> errdat2, "%s => procinfo", pToken -> sText) ;
		return rcNotHashRef ;
		}
	    if (strcmp (pKey, "embperl") == 0)
		embperl_CompileInitItem (r, (HV *)(SvRV (pSVValue)), pToken -> nNodeName, pToken -> nNodeType, 1, ppCompilerInfo) ;
	    else if (strncmp (pKey, "embperl#", 8) == 0 && (n = atoi (pKey+8)) > 0)
		embperl_CompileInitItem (r, (HV *)(SvRV (pSVValue)), pToken -> nNodeName, pToken -> nNodeType, n, ppCompilerInfo) ;
	    }
	}	    


    return ok ;
    }


	    
	    


    
/* ------------------------------------------------------------------------ */
/*                                                                          */
/* BuildSubTokenTable                                                       */
/*                                                                          */
/* Build the C token table out of a Perl Hash                               */
/*                                                                          */
/* ------------------------------------------------------------------------ */

static int BuildSubTokenTable (/*i/o*/ register req * r,
				/*in*/ int            nLevel,
			       /*in*/  HV *           pHash,
			/*in*/  const char *   pKey,
			/*in*/  const char *   pAttr,
			/*in*/  const char *   pDefEnd,
			/*i/o*/ void * *       ppCompilerInfo,
			/*out*/ struct tTokenTable * * pTokenTable)

                     
    {
    SV * *  ppSV ;
    int	    rc ;
    epTHX ;
    
    nLevel++ ;

    ppSV = hv_fetch(pHash, (char *)pAttr, strlen (pAttr), 0) ;  
    if (ppSV != NULL)
	{		
	struct tTokenTable * pNewTokenTable ;
	HV *                 pSubHash ;

	if (*ppSV == NULL || !SvROK (*ppSV) || SvTYPE (SvRV (*ppSV)) != SVt_PVHV)
	    {
	    strncpy (r -> errdat1, "BuildTokenHash", sizeof (r -> errdat1)) ;
	    sprintf (r -> errdat2, "%s => %s", pKey, pAttr) ;
	    return rcNotHashRef ;
	    }
	
	pSubHash = (HV *)SvRV (*ppSV) ;
	if ((pNewTokenTable = (struct tTokenTable *)GetHashValueInt (aTHX_ pSubHash, "--cptr", 0)) == NULL)
	    {
	    if ((pNewTokenTable = parse_malloc (r, sizeof (struct tTokenTable))) == NULL)
		 return rcOutOfMemory ;

	    if (r -> Component.Config.bDebug & dbgBuildToken)
		lprintf (r -> pApp,  "[%d]TOKEN: %*c-> %s\n", r -> pThread -> nPid, nLevel*2, ' ', pAttr) ; 
	    if ((rc = BuildTokenTable (r, nLevel, NULL, pSubHash, pDefEnd, ppCompilerInfo, pNewTokenTable)))
		return rc ;    
	    if (r -> Component.Config.bDebug & dbgBuildToken)
		lprintf (r -> pApp,  "[%d]TOKEN: %*c<- %s\n", r -> pThread -> nPid, nLevel*2, ' ', pAttr) ; 
	    
	    if (pNewTokenTable -> numTokens == 0)
		{
		strncpy (r -> errdat1, "BuildTokenHash", sizeof (r -> errdat1)) ;
		sprintf (r -> errdat2, "%s => %s does not contain any tokens", pKey, pAttr) ;
		return rcTokenNotFound ;
		}

	    hv_store(pSubHash, "--cptr", sizeof ("--cptr") - 1, newSViv ((IV)pNewTokenTable), 0) ;
	    }
	else
	    if (r -> Component.Config.bDebug & dbgBuildToken)
	        lprintf (r -> pApp,  "[%d]TOKEN: %*c-> %s already build; numTokens=%d\n", r -> pThread -> nPid, nLevel*2, ' ', pAttr, pNewTokenTable->numTokens) ; 
	

	*pTokenTable = pNewTokenTable ;
	return  ok  ;
	}

    *pTokenTable = NULL ;
    return ok ;
    }
    

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* BuildTokenTable                                                          */
/*                                                                          */
/* Build the C token table out of a Perl Hash                               */
/*                                                                          */
/* ------------------------------------------------------------------------ */

int BuildTokenTable (/*i/o*/ register req *	  r,
 		     /*in*/ int            nLevel,
                     /*in*/  const char *         sName,
		     /*in*/  HV *		  pTokenHash,
		     /*in*/  const char *         pDefEnd,
		     /*i/o*/ void * *		  ppCompilerInfo,
                     /*out*/ struct tTokenTable * pTokenTable)

                     
    {
    int		    rc ;
    SV *	    pToken ;
    HE *	    pEntry ;
    char *	    pKey ;
    const char *    c ;
    int		    numTokens ;
    struct tToken * pTable ;
    struct tToken * p ;
    I32		    l	 ;
    STRLEN	    len	 ;
    int		    n ;
    int             m ;
    int		    i ;
    typedef struct tSortToken
        {
        char *	    pKey ;
        SV *	    pToken ;
        } tSortToken ;
    tSortToken * pSortTokenHash ;    
    unsigned char * pStartChars = pTokenTable -> cStartChars ;
    unsigned char * pAllChars	= pTokenTable -> cAllChars ;
    epTHX ;

    tainted = 0 ;

    /* r -> Component.Config.bDebug |= dbgBuildToken ; */

    memset (pStartChars, 0, sizeof (pTokenTable -> cStartChars)) ;
    memset (pAllChars,   0, sizeof (pTokenTable -> cAllChars)) ;
    pTokenTable -> bLSearch = 0 ;    
    pTokenTable -> nDefNodeType = ntypCDATA ;
    pTokenTable -> pContainsToken = NULL ;
    pTokenTable -> pCompilerInfo = NULL ;
    pTokenTable -> sRootNode = NULL ;
    pTokenTable -> sName = sName ;
    if (ppCompilerInfo == NULL)
	ppCompilerInfo = &pTokenTable -> pCompilerInfo ;

    hv_store(pTokenHash, "--cptr", sizeof ("--cptr") - 1, newSViv ((IV)pTokenTable), 0) ;

    numTokens = 1 ;
    hv_iterinit (pTokenHash) ;
    while ((pEntry = hv_iternext (pTokenHash)))
	{
	pKey     = hv_iterkey (pEntry, &l) ;
	pToken   = hv_iterval (pTokenHash, pEntry) ;
        if (*pKey != '-') 
	    numTokens++ ;
        }
            
    if ((pTable = parse_malloc (r, sizeof (struct tToken) * numTokens)) == NULL)
         return rcOutOfMemory ;

    n = 0 ;
    hv_iterinit (pTokenHash) ;
    while ((pEntry = hv_iternext (pTokenHash)))
        {
        pKey     = hv_iterkey (pEntry, &l) ;
        pToken   = hv_iterval (pTokenHash, pEntry) ;
        
	if (*pKey == '-')
	    { /* special key */
	    if (strcmp (pKey, "-rootnode") == 0)
		{
		pTokenTable -> sRootNode = sstrdup (r, SvPV((SV *)pToken, len)) ;
		}
	    if (strcmp (pKey, "-defnodetype") == 0)
		{
		pTokenTable -> nDefNodeType = SvIV ((SV *)pToken) ;
		}
	    else if (strcmp (pKey, "-lsearch") == 0)
		{
		pTokenTable -> bLSearch = SvIV ((SV *)pToken) ;
		}
	    else if (strcmp (pKey, "-contains") == 0)
		{
		STRLEN l ;
		char * c = SvPV (pToken, l) ;
		while (*c)
		    {
		    pAllChars [tolower(*c) >> 3] |= 1 << (tolower(*c) & 7) ;
		    pAllChars [toupper(*c) >> 3] |= 1 << (toupper(*c) & 7) ;
		    c++ ;
		    }
		}
	    }
        }

    m = 0 ;
    n = HvKEYS (pTokenHash) ;
    pSortTokenHash = (tSortToken *)malloc (sizeof (struct tSortToken) * n) ;
    hv_iterinit (pTokenHash) ;
    while ((pEntry = hv_iternext (pTokenHash)))
        {
        pKey     = hv_iterkey (pEntry, &l) ;
        pToken   = hv_iterval (pTokenHash, pEntry) ;

        pSortTokenHash[m].pKey = pKey ;    
        pSortTokenHash[m].pToken = pToken ;    
        m++ ;
        }

    qsort (pSortTokenHash, m, sizeof (struct tSortToken), CmpToken) ;

    n = 0 ;
    i = 0 ;
    while (i < m)
        {
        HV *   pHash ;
	struct tTokenTable * pNewTokenTable ;
	char *  sContains ;
	char *  sC ;
        
        pKey     = pSortTokenHash[i].pKey ;
        pToken   = pSortTokenHash[i].pToken ;
        i++ ;
	    if (r -> Component.Config.bDebug & dbgBuildToken)
                lprintf (r -> pApp,  "[%d]TOKENKey: %s\n", r -> pThread -> nPid, pKey) ; 
        
	if (*pKey != '-')
	    {
	    if (!SvROK (pToken) || SvTYPE (SvRV (pToken)) != SVt_PVHV)
		{
		strncpy (r -> errdat1, "BuildTokenHash", sizeof (r -> errdat1)) ;
		sprintf (r -> errdat2, "%s", pKey) ;
		return rcNotHashRef ;
		}
	    pHash = (HV *)SvRV (pToken) ;
        
	    p = &pTable[n] ;
	    p -> sName     = pKey ;
	    p -> sText     = GetHashValueStrDup (aTHX_ r -> pThread -> pMainPool, pHash, "text", "") ;
            p -> nTextLen  = p -> sText?strlen (p -> sText):0 ;
	    p -> sEndText  = GetHashValueStrDup (aTHX_ r -> pThread -> pMainPool, pHash, "end", (char *)pDefEnd) ;
	    p -> sNodeName = GetHashValueStrDup (aTHX_ r -> pThread -> pMainPool, pHash, "nodename", NULL) ;
	    p -> nNodeType = (tNodeType)GetHashValueInt (aTHX_ pHash, "nodetype", ntypTag) ;
	    p -> bUnescape = GetHashValueInt (aTHX_ pHash, "unescape", 0) ;
	    p -> bAddFlags = GetHashValueInt (aTHX_ pHash, "addflags", 0) ;
	    p -> nCDataType = (tNodeType)GetHashValueInt (aTHX_ pHash, "cdatatype", pTokenTable -> nDefNodeType) ;
	    p -> nForceType = (tNodeType)GetHashValueInt (aTHX_ pHash, "forcetype", 0) ;
	    p -> bRemoveSpaces = GetHashValueInt (aTHX_ pHash, "removespaces", p -> nNodeType != ntypCDATA?2:0) ;
	    p -> bInsideMustExist = GetHashValueInt (aTHX_ pHash, "insidemustexist", 0) ;
	    p -> bMatchAll = GetHashValueInt (aTHX_ pHash, "matchall", 0) ;
	    p -> bDontEat  = GetHashValueInt (aTHX_ pHash, "donteat", 0) ;
	    p -> bExitInside= GetHashValueInt (aTHX_ pHash, "exitinside", 0) ;
	    p -> bAddFirstChild = GetHashValueInt (aTHX_ pHash, "addfirstchild", 0) ;
	    p -> pStartTag  = (struct tToken *)GetHashValueStrDup (aTHX_ r -> pThread -> pMainPool, pHash, "starttag", NULL) ;
	    p -> pEndTag    = (struct tToken *)GetHashValueStrDup (aTHX_ r -> pThread -> pMainPool, pHash, "endtag", NULL) ;
	    p -> sParseTimePerlCode =  GetHashValueStrDup (aTHX_ r -> pThread -> pMainPool, pHash, "parsetimeperlcode", NULL) ;
	    if ((sC = sContains  = GetHashValueStrDup (aTHX_ r -> pThread -> pMainPool, pHash, "contains", NULL)))
		{
		unsigned char * pC ;
		if ((p -> pContains = parse_malloc (r, sizeof (tCharMap))) == NULL)
		    return rcOutOfMemory ;

                pC = p -> pContains ;
		memset (pC, 0, sizeof (tCharMap)) ;
		while (*sContains)
		    {
		    pC[*sContains >> 3] |= 1 << (*sContains & 7) ;
	            pStartChars [*sContains >> 3] |= 1 << (*sContains & 7) ;
	            pStartChars [*sContains >> 3] |= 1 << (*sContains & 7) ;
		    sContains++ ;
		    }
		}
	    else
		p -> pContains = NULL ;

	    if (p -> bMatchAll)
                {
                memset (pStartChars, 0xff, sizeof(tCharMap)) ;
                }
	    else if ((c = p -> sText))
                {
	        pStartChars [toupper(*c) >> 3] |= 1 << (toupper(*c) & 7) ;
	        pStartChars [tolower(*c) >> 3] |= 1 << (tolower(*c) & 7) ;
        
	        while (*c)
		    {
		    pAllChars [tolower(*c) >> 3] |= 1 << (tolower(*c) & 7) ;
		    pAllChars [toupper(*c) >> 3] |= 1 << (toupper(*c) & 7) ;
		    c++ ;
		    }
                }	    

	    if (r -> Component.Config.bDebug & dbgBuildToken)
                lprintf (r -> pApp,  "[%d]TOKEN: %*c%s ... %s  unesc=%d nodetype=%d, cdatatype=%d, nodename=%s contains='%s' addfirstchild=%d\n", r -> pThread -> nPid, nLevel*2, ' ', p -> sText, p -> sEndText, p -> bUnescape, p -> nNodeType, p -> nCDataType, p -> sNodeName?p -> sNodeName:"<null>", sC?sC:"", p -> bAddFirstChild) ; 
        
	    if (p -> sNodeName)
		{
		if (p -> sNodeName[0] != '!')
		    p -> nNodeName = String2Ndx (r -> pApp, p -> sNodeName, strlen (p -> sNodeName)) ;
		else
		    p -> nNodeName = String2UniqueNdx (r -> pApp, p -> sNodeName + 1, strlen (p -> sNodeName + 1)) ;
		}
	    else
		p -> nNodeName = String2Ndx (r -> pApp, p -> sText, strlen (p -> sText)) ;


	    if ((rc = CheckProcInfo (r, pHash, p, ppCompilerInfo)) != ok)
		return rc ;

	    
	    if ((rc = BuildSubTokenTable (r, nLevel, pHash, pKey, "follow", p -> sEndText, ppCompilerInfo, &pNewTokenTable)))
		return rc ;
	    p -> pFollowedBy = pNewTokenTable ;

	    if ((rc = BuildSubTokenTable (r, nLevel, pHash, pKey, "inside", "", ppCompilerInfo, &pNewTokenTable)))
		return rc ;
	    p -> pInside     = pNewTokenTable ;

	    n++ ;
	    }
	}

    free (pSortTokenHash) ;
    
    qsort (pTable, numTokens - 1, sizeof (struct tToken), pTokenTable -> bLSearch?CmpTokenDesc:CmpToken) ;


    for (i = 0; i < n; i++)
	{
	if (pTable[i].pContains && !pTable[i].sText[0])
	    pTokenTable -> pContainsToken = &pTable[i] ;
        if (pTable[i].pEndTag)
	    {
	    char * s = (char *)pTable[i].pEndTag ;
	    int    j ;

	    pTable[i].pEndTag = NULL ;
	    for (j = 0; j < n; j++)
		{
		if (strcmp (pTable[j].sName, s) == 0)
		    pTable[i].pEndTag = &pTable[j] ;
		}
	    if (pTable[i].pEndTag == NULL)
		{
		strncpy (r -> errdat1, "BuildTokenHash", sizeof (r -> errdat1)) ;
		sprintf (r -> errdat2, " EndTag %s for %s not found", pTable[i].sText, s) ;
		return rcTokenNotFound ;
		}
	    
	    }
        if (pTable[i].pStartTag)
	    {
	    char * s = (char *)pTable[i].pStartTag ;
	    int    j ;

	    pTable[i].pStartTag = NULL ;
	    for (j = 0; j < n; j++)
		{
		if (strcmp (pTable[j].sName, s) == 0)
		    pTable[i].pStartTag = &pTable[j] ;
		}
	    if (pTable[i].pStartTag == NULL)
		{
		strncpy (r -> errdat1, "BuildTokenHash", sizeof (r -> errdat1)) ;
		sprintf (r -> errdat2, " StartTag %s for %s not found", pTable[i].sText, s) ;
		return rcTokenNotFound ;
		}
	    
	    }
        }

    
    p = &pTable[n] ;
    p -> sText = "" ;
    p -> nTextLen = 0 ;
    p -> sEndText = "" ;
    p -> pFollowedBy = NULL ;
    p -> pInside     = NULL ;
    
        
    pTokenTable -> pTokens   = pTable ;
    pTokenTable -> numTokens = numTokens - 1 ;
            
    return ok ;
    }
    
/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ExecParseTimeCode                                                        */
/*                                                                          */
/* executes Perl code at parse time                                         */
/*                                                                          */
/* ------------------------------------------------------------------------ */

static int ExecParseTimeCode (/*i/o*/	register req *	    r,
			      /*in */	struct tToken *	    pToken, 
		  	      /*in */	char * 		    pCurr, 
					int		    nLen,
					int                 nLinenumber)

    {
    SV * pSV ;
    int  rc ;
    const char * sPCode = pToken -> sParseTimePerlCode ;
    int          plen = strlen (sPCode) ;
    char *       sCode ;
    const char *  p ;
    int          n ;
    SV *        args[2] ;
    epTHX ;

    if ((p = strnstr (sPCode, "%%", nLen)))
	{
	sCode = parse_malloc (r, nLen + plen + 1) ;
	n = p - sPCode ;
	memcpy (sCode, sPCode, n) ;
	memcpy (sCode + n, pCurr, nLen) ;
	memcpy (sCode + n + nLen, sPCode + n + 2, plen - n - 2) ;
	nLen = nLen + plen - 2 ;
	sCode[nLen] = '\0' ;
	}
    else
	{
	sCode = (char *)sPCode ;
	nLen = plen ;
	}
    
    if (nLen && r -> Component.Config.bDebug & dbgParse)
	lprintf (r -> pApp,  "[%d]PARSE: ParseTimeCode:    %*.*s\n", r -> pThread -> nPid, nLen, nLen, sCode) ; 

    pSV = newSVpvf("package %s ;\nmy ($_ep_req) = @_;\n#line %d \"%s\"\n%*.*s",
	    "Embperl::Parser" /*r -> Component.sEvalPackage*/, nLinenumber, r -> Component.sSourcefile, nLen, nLen, sCode) ;
    newSVpvf2(pSV) ;
    args[0] = r -> _perlsv ;
    if ((rc = EvalDirect (r, pSV, 1, args)) != ok)
	LogError (r, rc) ;
    SvREFCNT_dec(pSV);

    return rc ;
    }





    
/* ------------------------------------------------------------------------ */
/* compare tokens                                                           */
/* ------------------------------------------------------------------------ */

static int CmpTokenN (/*in*/ const void *  p1,
                     /*in*/ const void *  p2)

    {
    struct tTokenCmp * c = (struct tTokenCmp *)p1 ;
    int                i ;
    int	p1Len = c -> nLen ;
    int p2Len = ((struct tToken *)p2) -> nTextLen ;

    if ((i = strnicmp (c -> pStart, *((const char * *)p2), p1Len)) == 0)
	{
	if (p1Len == p2Len)
	    return 0 ;
	else if (p1Len > p2Len)
	    return 1 ;
	return -1 ;
	}
    return i ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ParseTokens                                                              */
/*                                                                          */
/* Parse a text for tokens                                                  */
/*                                                                          */
/* ------------------------------------------------------------------------ */

static int ParseTokens (/*i/o*/ register req *		r,
			/*in */ char * *		ppCurr, 
				char *			pEnd, 
				struct tTokenTable *	pTokenTable, 
				const char *		sEndText,
				const unsigned char *	pParentContains,
				tNodeType		nCDataType,
				tNodeType		nForceType,
				int			bUnescape,
				int			bInsideMustExist, 
				int			bRemoveSpaces, 
				tStringIndex 		nParentNodeName,
				tNode			xParentNode,
				int			level, 
				char *		        pCDATAStart, 
				const char *		sStopText,
                                int                     bDontEat) 

    {
    unsigned char * pStartChars = pTokenTable -> cStartChars ;
    struct tTokenCmp c ;    
    int nEndText = sEndText?strlen (sEndText):0 ;    
    char * pCurr = *ppCurr  ;
    char * pCurrStart = pCDATAStart?pCDATAStart:pCurr ;
    tNode xNewNode ;
    int	    rc = 0 ;
    tDomTree * pDomTree = DomTree_self (r -> Component.xCurrDomTree) ;
    int  numInside      = 0 ;
    
    if (nEndText == 0 && sStopText)
	{
	sEndText = sStopText ;
	nEndText = sEndText?strlen (sEndText):0 ;    
	}
    else
	sStopText = NULL ;


    while (pCurr < pEnd)
        {
	struct tToken *	    pToken	    = NULL ;
        int                 bFollow         = 0 ;

	if (level == 0 && pTokenTable != r -> Component.pTokenTable)
	    { /* syntax has changed */
	    pTokenTable = r -> Component.pTokenTable ;
	    pStartChars = pTokenTable -> cStartChars ;
	    }
	
        if (pStartChars [*pCurr >> 3] & 1 << (*pCurr & 7))
            { /* valid token start char found */
	    struct tTokenTable *    pNextTokenTab   = pTokenTable ;
	    tStringIndex 	    nNodeName	    = 0 ;
	    char *	            pCurrTokenStart = pCurr ;

	    
	    do
                {
		struct tToken * pTokenTab = pNextTokenTab -> pTokens ;
		int             numTokens = pNextTokenTab -> numTokens ;
		unsigned char * pAllChars = pNextTokenTab -> cAllChars ;

	        bFollow++ ;

                if (pNextTokenTab -> bLSearch)
		    { /* search linear thru the tokens */
		    int r = 1 ;
		    int i ;

		    for (i = 0, pToken = pTokenTab; i < numTokens; i++, pToken++)
			{
			if (pToken -> bMatchAll && (numInside == 0 || pToken -> bMatchAll > 0))
			    {
			    r = 0 ;
			    break ;
			    }
			if (pToken -> nTextLen == 0)
			    continue ;
			r = strnicmp (pCurr, pToken -> sText, pToken -> nTextLen)  ;
			/* if ((r == 0 && !(pAllChars [pCurr[pToken -> nTextLen] >> 3] & (1 << (pCurr[pToken -> nTextLen] & 7)))) || */
			if (r == 0  ||
			        (*pCurr > *(pToken -> sText) && pStartChars[0] != 0xff))
			    break ;
			}
		    if (r != 0)
		    	pToken = NULL ;
		    else if (!pToken -> bMatchAll && (pToken -> bDontEat & 1) == 0)
			pCurr += pToken -> nTextLen ;
		    }
		else
		    { /* do a binary search for tokens */
		    c.pStart = pCurr ;

		    while (pAllChars [*pCurr >> 3] & (1 << (*pCurr & 7)))
			pCurr++ ;
                
		    c.nLen = pCurr - c.pStart ;
		    pToken = (struct tToken *)bsearch (&c, pTokenTab, numTokens, sizeof (struct tToken), CmpTokenN) ;
		    if (!pToken)
		    	{
		    	pCurr = c.pStart ;
		    /*	bFollow = 0 ; */
		    	}
		    }

		if (pToken)
                    {
		    numInside++ ;
                    if (pToken -> bRemoveSpaces & 2)
			while (isspace (*pCurr))
			    pCurr++ ;
		    else if (pToken -> bRemoveSpaces & 8)
			while ((*pCurr == ' ' || *pCurr == '\t'  || *pCurr == '\r'))
			    pCurr++ ;
		    
		    if (pToken -> sNodeName)
			nNodeName = pToken -> nNodeName ;
                    }
                else
		    {
		    pToken = pNextTokenTab -> pContainsToken ;
		    /*
		    if (pToken = pNextTokenTab -> pContainsToken)
		    	{
		    	unsigned char * pContains ;
		    	if (!(pToken -> pInside) && (!(pContains = pToken -> pContains) || !(pContains [*pCurr >> 3] & (1 << (*pCurr & 7)))))
	    	    	    pToken = NULL ;
		    	}
		    */		    
    		    if (pToken && pToken -> sNodeName)
			nNodeName = pToken -> nNodeName ;
		    
		    break ;
		    }

	
		}
            while ((pNextTokenTab = pToken -> pFollowedBy)) ;
            
            if (pToken)
                { /* matching token found */       
                struct tTokenTable * pInside ;                

		if (pCurrStart < pCurrTokenStart)
		    {
		    if (nCDataType)
			{ /* add text before current token as node */
			const char * pEnd = pCurrTokenStart - 1;
			if (pToken -> bRemoveSpaces & 1)
			    while (pEnd >= pCurrStart && isspace (*pEnd))
				pEnd-- ;
			else if (pToken -> bRemoveSpaces & 4)
			    while (pEnd >= pCurrStart && (*pEnd == ' ' || *pEnd == '\t'  || *pEnd == '\r'))
				pEnd-- ;
			else if (pToken -> bRemoveSpaces & 16)
			    {
			    while (pEnd >= pCurrStart && isspace (*pEnd))
				pEnd-- ;
			    if (pEnd >= pCurrStart && pEnd < pCurrTokenStart - 1)
				pEnd++ ;
			    }

			if (bUnescape)
                            {
                            int newlen ;
                            r -> Component.bEscInUrl = bUnescape - 1 ;
                            newlen = TransHtml (r, pCurrStart, pEnd - pCurrStart + 1) ;
                            pEnd = pCurrStart + newlen - 1 ;
                            r -> Component.bEscInUrl = 0 ;
                            }

			
			if (pEnd - pCurrStart + 1)
			    if (!(xNewNode = Node_appendChild (r -> pApp, pDomTree, xParentNode, 0, nCDataType, 0, pCurrStart, pEnd - pCurrStart + 1, level, GetLineNoOf (r, pCurrStart), NULL)))
				return 1 ;
			}
		    pCurrStart = pCurrTokenStart ;
		    }
            
		if (nNodeName == 0)
		    nNodeName = pToken -> nNodeName ;
		
		if (pToken -> nNodeType == ntypEndTag && level > 0)
		    { /* end token found */
		    tNodeData * pStartTag ;
		    char * pEndCurr = strstr (pCurr, pToken -> sEndText) ;
                    if (!pEndCurr && pToken -> sEndText[0] == '\n' && pToken -> sEndText[1] == '\n' && sEndText[2] == '\0')
                        {
                        pEndCurr = strstr (pCurr, "\n\r\n") ;
                        if (pEndCurr && pEndCurr[-1] == '\r')
                            pEndCurr-- ;
                        }
                    if (pEndCurr)
			{ 
			tNode xNewAttrNode ;
                        if (pEndCurr - pCurr && pToken -> nCDataType && pToken -> nCDataType != ntypCDATA)
			    { /* add text before end of token as node */
                            char * pEnd = pEndCurr ;
                            char c;

                            if (pToken -> bRemoveSpaces & 32)
			        while (pEnd > pCurrStart && isspace (*(pEnd-1)))
				    pEnd-- ;
			    else if (pToken -> bRemoveSpaces & 64)
			        while (pEnd > pCurrStart && ((c = *(pEnd-1)) == ' ' || c == '\t'  || c == '\r'))
				    pEnd-- ;

			    if (pToken -> bUnescape)
                                {
                                int newlen ;
                                r -> Component.bEscInUrl = pToken -> bUnescape - 1 ;
				newlen = TransHtml (r, pCurr, pEnd - pCurr) ;
                                pEnd = pCurr + newlen ;
                                r -> Component.bEscInUrl = 0 ;
                                }

			    if (!(xNewAttrNode = Node_appendChild (r -> pApp, pDomTree, xParentNode, 0, pToken -> nCDataType, 0, pCurr, pEnd - pCurr, level+1, GetLineNoOf (r, pCurr), NULL)))
				return 1 ;
			    if (pToken -> bAddFlags)
                                Node_self (pDomTree, xNewAttrNode) -> bFlags |= pToken -> bAddFlags ;
                            
                            }
			pCurr = pEndCurr + strlen (pToken -> sEndText) ;
			}
		    level-- ;
		    xParentNode = Node_parentNode  (r -> pApp, pDomTree, xParentNode, 0) ;
		    pStartTag = Node_selfLastChild (r -> pApp, pDomTree, Node_self (pDomTree, xParentNode), 0) ;
		    if (pStartTag -> nText != pToken -> nNodeName && 
                        (pToken -> pStartTag == NULL 
                        || pStartTag -> nText != pToken -> pStartTag -> nNodeName))
			{
			strncpy (r -> errdat2, Ndx2String (pStartTag -> nText), sizeof (r -> errdat2)) ;	
			strncpy (r -> errdat1, Ndx2String (pToken -> nNodeName), sizeof (r -> errdat1)) ;	
			r -> Component.pCurrPos = pCurrTokenStart ;
			return rcTagMismatch ;
			}
		    }
		else
		    {
		    if (pToken -> nNodeType == ntypEndStartTag && level > 0)
			{
			xParentNode = Node_parentNode  (r -> pApp, pDomTree, xParentNode, 0) ;
			level-- ;
			}
		    if ((pToken -> nNodeType && pToken -> nNodeType != ntypCDATA) || pToken -> sNodeName)
			{
			/* add token as node if not cdata*/
			tNodeType nType = pToken -> nNodeType ;
			if (nType == ntypStartEndTag)
			    nType = ntypStartTag ;

			if (!(xNewNode = Node_appendChild (r -> pApp, pDomTree, xParentNode, 0, nType, (nCDataType == ntypAttrValue && pToken -> nNodeType != ntypAttr)?(pToken -> nForceType?2:1):0, NULL, nNodeName, level, GetLineNoOf (r, pCurrTokenStart), pToken -> sText)))
			    {
			    r -> Component.pCurrPos = pCurrTokenStart ;

			    return rc ;
			    }
			if (pToken -> bAddFlags)
                            Node_self (pDomTree, xNewNode) -> bFlags |= pToken -> bAddFlags ;
			if (!pToken -> pInside)
			    bInsideMustExist = 0 ;

                        if (pToken -> bAddFirstChild)
                            {
                            if (!(Node_appendChild (r -> pApp, pDomTree, xNewNode, 0, nCDataType,
                                            0, 
                                            "", 0, 
					     0, 0, NULL)))
			        {
			        return rc ;
			        }
                            }
			}
		    else
			{
			xNewNode = xParentNode ;
			}

		    if ((pInside = pToken -> pInside))
			{ /* parse for further tokens inside of this token */
                        rc = ParseTokens (r, &pCurr, pEnd, pInside, 
					    pToken -> sEndText,
					    pToken -> pContains,
					    (tNodeType)(pToken -> nCDataType == ntypCDATA && !pToken -> sNodeName?ntypAttrValue:pToken -> nCDataType),
					    0,
					    pToken -> bUnescape, 
					    pToken -> bInsideMustExist + bInsideMustExist, 
					    pToken -> bRemoveSpaces, 
					    nNodeName,
					    xNewNode,
					    level+1,
					    pToken -> nNodeType == ntypCDATA?pCurrTokenStart:NULL,
					    sEndText && *sEndText?sEndText:NULL,
                                            pToken -> bDontEat) ;
			if (rc == ok)
			    bInsideMustExist = 0 ;
			else if (pToken -> bInsideMustExist && rc == rcTokenNotFound)
			    {
			    rc = ok ;
			    /*
			    pToken = NULL ;
			    bFollow = 0 ;
			    sEndText = NULL ;
			    nEndText = 0 ;
	    		    pCurr  = pCurrTokenStart  ;
			    */
			    if (xNewNode != xParentNode)
				{
				Node_removeChild (r -> pApp, pDomTree, xParentNode, xNewNode, 0) ; 
				if (r -> Component.Config.bDebug & dbgParse)
				    lprintf (r -> pApp,  "[%d]PARSE: DelNode: +%02d %*s parent=%d node=%d\n", 
	                             r -> pThread -> nPid, level, level * 2, "", xParentNode, xNewNode) ; 
				}
				
			    /* add as cdata*/
			    if (!(xNewNode = Node_appendChild (r -> pApp, pDomTree, xParentNode, 0, (tNodeType)pTokenTable -> nDefNodeType, 0, pCurrStart, pCurr - pCurrStart, level, GetLineNoOf (r, pCurrStart), NULL)))
				return 1 ;
			    }
			else if (rc != rcTokenNotFound)
                            {
                            return rc ;
                            }
			 if (pToken -> nNodeType == ntypStartEndTag)
			    {
			    xParentNode = Node_parentNode  (r -> pApp, pDomTree, xNewNode, 0) ;
			    pToken = NULL ;
			    bFollow = 2 ;
			    }
			}    
		    else
			{ /* nothing more inside of this token allowed, so search for the end of the token */
			char * pEndCurr ;
			unsigned char * pContains ;
			int nSkip = 0 ;
			if ((pContains = pToken -> pContains))
			    {
			    pEndCurr = pCurr ;
			    while (pContains [*pEndCurr >> 3] & (1 << (*pEndCurr & 7)))
                                pEndCurr++ ;
			    nSkip = 0 ;
			    /*
			    if (pEndCurr == pCurr)
				{
				pEndCurr = NULL ;
				pToken   = NULL ;
				}
			    */	
			    }
			else
			    {
			    pEndCurr = NULL ;
                            if (strcmp (pToken -> sEndText, "\n\n") == 0)
                                {
                                if ((pEndCurr = strstr (pCurr, "\n\r\n")))
                                    {
                                    if (pEndCurr[-1] == '\r')
                                        {
                                        pEndCurr-- ;
                                        nSkip = pCurr[4] == '\r'?5:4 ;
                                        }
                                    else
                                        nSkip = pCurr[3] == '\r'?4:3 ;
                                    }
                                }
                            if (!pEndCurr)
                                {
                                pEndCurr = strstr (pCurr, pToken -> sEndText) ;
                                nSkip = strlen (pToken -> sEndText) ;
                                }
			    if (pToken -> bDontEat & 2)
                                nSkip = 0 ;
                            
                            if (pToken -> nNodeType == ntypCDATA && pEndCurr && !pToken -> sNodeName)
				{
				pEndCurr += nSkip ;
				nSkip = 0 ;
				pCurr = pCurrTokenStart ;
				}
			    }

			if (pEndCurr)
			    {
			    tNode xNewAttrNode ;
                            if (pEndCurr - pCurr && pToken -> nCDataType)
				{
				int nLine ;
                                char * pEnd = pEndCurr ;
                                char c;

                                if (pToken -> bRemoveSpaces & 32)
			            while (pEnd > pCurrStart && isspace (*(pEnd-1)))
				        pEnd-- ;
			        else if (pToken -> bRemoveSpaces & 64)
			            while (pEnd > pCurrStart && ((c = *(pEnd-1)) == ' ' || c == '\t'  || c == '\r'))
				        pEnd-- ;
				
                                if (pToken -> bUnescape)
                                    {
                                    int newlen ;
                                    r -> Component.bEscInUrl = pToken -> bUnescape - 1 ;
				    newlen = TransHtml (r, pCurr, pEnd - pCurr) ;
                                    pEnd = pCurr + newlen ;
                                    r -> Component.bEscInUrl = 0 ;
                                    }


				if (!(xNewAttrNode = Node_appendChild (r -> pApp, pDomTree, xNewNode, 0, pToken -> nCDataType, 
									0, pCurr, pEnd - pCurr, level+1, 
									nLine = GetLineNoOf (r, pCurr), pToken -> sText)))
				    return 1 ;
			        if (pToken -> bAddFlags)
                                    Node_self (pDomTree, xNewAttrNode) -> bFlags |= pToken -> bAddFlags ;
				if (pToken -> sParseTimePerlCode)
				    if ((rc = ExecParseTimeCode (r, pToken, pCurr, pEnd - pCurr, nLine)) != ok)
                                        {
                                        r -> Component.pCurrPos = pCurrTokenStart ;
					return rc ;
                                        }
				}

			     if (pToken -> nNodeType == ntypStartEndTag)
				{
				xParentNode = Node_parentNode  (r -> pApp, pDomTree, xNewNode, 0) ;
				pToken = NULL ;
				}

			    
			    pCurr = pEndCurr + nSkip ;
			    }
			}

		    if (pToken && (pToken -> nNodeType == ntypStartTag || 
			           pToken -> nNodeType == ntypEndStartTag ||
				   pToken -> nNodeType == ntypStartEndTag))
			{
			if (level++ > 1000)
                            {
                            r -> Component.pCurrPos = pCurrTokenStart ;
                            return rcTooDeepNested ;
                            }
			xParentNode = xNewNode ;
		        nCDataType = pTokenTable -> nDefNodeType ;
			}
		    }
		pCurrStart = pCurr ;
                }
	    }
        if (pParentContains && ((pParentContains [*pCurr >> 3] & 1 << (*pCurr & 7)) == 0) )
            {
	    if (pCurr - pCurrStart && nCDataType)
		{
		if (!(xNewNode = Node_appendChild (r -> pApp, pDomTree, xParentNode, 0, nCDataType, 0, 
		                                   pCurrStart, pCurr - pCurrStart, level, 
						   GetLineNoOf (r, pCurrStart), NULL)))
		    return 1 ;
		}
            *ppCurr = pCurr ;
            return bInsideMustExist?rcTokenNotFound:ok ;
            }
        else if (sEndText == NULL ||
	    ((*pCurr == *sEndText && (strncmp (pCurr, sEndText, nEndText) == 0)) || 
                (pCurr[0] == '\n' && pCurr[1] == '\r' && pCurr[2] == '\n' && sEndText[1] == '\n' && sEndText[2] == '\0')) ||
             (pCurr[0] == '\r' && pCurr[1] == '\n' && pCurr[2] == '\r' && pCurr[3] == '\n' && sEndText[0] == '\n'  && sEndText[1] == '\n' && sEndText[2] == '\0')
                )
            {
            char * pEnd  ;
	    if (pCDATAStart)
		pCurr += nEndText ;
            pEnd = pCurr - 1 ;

            if (bRemoveSpaces & 32)
		while (pEnd >= pCurrStart && isspace (*pEnd))
		    pEnd-- ;
	    else if (bRemoveSpaces & 64)
		while (pEnd >= pCurrStart && (*pEnd == ' ' || *pEnd == '\t'  || *pEnd == '\r'))
		    pEnd-- ;

            if ((pEnd - pCurrStart + 1 != 0 || nCDataType == ntypAttrValue) && nCDataType)
		if (!(xNewNode = Node_appendChild (r -> pApp, pDomTree,  xParentNode, 0, nCDataType, 0, 
						    pCurrStart, pEnd - pCurrStart + 1, level, 
						    GetLineNoOf (r, pCurr), NULL)))
		    return 1 ;

            if (!pCDATAStart && !sStopText && (bDontEat & 2) == 0)
		pCurr += nEndText ;
            *ppCurr = pCurr ;
            return bInsideMustExist?rcTokenNotFound:ok ;
            }
        else if (!pToken && bFollow < 2)
	    pCurr++ ;

        if (pToken && (pToken -> bExitInside))
            {
            *ppCurr = pCurr ;
            return ok ;
            }
        }
        
    if (nCDataType && pCurr - pCurrStart)
	if (!(xNewNode = Node_appendChild (r -> pApp, pDomTree, xParentNode, 0, nCDataType, 0,
					    pCurrStart, pCurr - pCurrStart, level, 
					    GetLineNoOf (r, pCurrStart), NULL)))
	    return 1 ;

    *ppCurr = pCurr ;
    return bInsideMustExist?rcTokenNotFound:ok ;
    }



/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_Parse                                                            */
/*                                                                          */
/*! 
*   \_en
*   Parse source into given DomTree
*   
*   @param  r               Embperl request record
*   @param  pSource         Sourcetext
*   @param  nLen            Length of Sourcetext
*   @param  pDomTree	    Destination DomTree
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Parst die Quelle in den gegebenen  DomTree
*   
*   @param  r               Embperl request record
*   @param  pSource         Quellentext
*   @param  nLen            Länge des Quellentext
*   @param  pDomTree	    Ziel DomTree
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */


static int embperl_ParseSource (/*i/o*/ register req * r,
                   /*in*/  char *   pSource,
                   /*in*/  size_t         nLen,
		   /*in*/  tDomTree * pDomTree)

    {
    char * pStart = pSource ;
    char * pEnd   = pSource + nLen ;
    int	    rc ;
    tNode   xDocNode ;
    tNode   xDocNode2 ;
    tNode   xNode ;
    tTokenTable * pTokenTableSave ;
    clock_t	cl1 = clock () ;
    clock_t	cl2 ;

    r -> Component.pBuf    = (char *)pStart ;
    r -> Component.pEndPos = (char *)pEnd ;
    r -> Component.pSourcelinePos = r -> Component.pCurrPos = r -> Component.pBuf ;

    if (r -> Component.Config.bDebug & dbgParse)
	lprintf (r -> pApp,  "[%d]PARSE: Start parsing %s DomTree = %d\n", r -> pThread -> nPid, r -> Component.sSourcefile, r -> Component.xCurrDomTree) ; 
    
    pDomTree -> xFilename = String2Ndx (r -> pApp, r -> Component.sSourcefile, strlen (r -> Component.sSourcefile)) ;
    
    if (!(xDocNode = Node_appendChild (r -> pApp, pDomTree, 0, 0, ntypTag, 0, "attr", 3, 0, 0, NULL)))
	return rcOutOfMemory ;

    if (!(xDocNode = Node_appendChild (r -> pApp, pDomTree,  0, 0, (tNodeType)((r -> Component.pPrev)?ntypDocumentFraq:ntypDocument), 0, 
					NULL, r -> Component.pPrev?xDocumentFraq:xDocument, 0, 0, NULL)))
	return rcOutOfMemory ;
    
    xDocNode2 = xDocNode ;
    if (r -> Component.pTokenTable -> sRootNode)
        {
        /* Add at least one child node before root node to make insertafter at the beginning of the document work */
        if (!(Node_appendChild (r -> pApp, pDomTree,  xDocNode, 0, ntypCDATA, 0,
                                            "", 0, 
					     0, 0, NULL)))
	    return rcOutOfMemory ;

        if (!(xDocNode2 = Node_appendChild (r -> pApp, pDomTree,  xDocNode, 0, ntypStartTag, 0,
                                            r -> Component.pTokenTable -> sRootNode,
                                            strlen (r -> Component.pTokenTable -> sRootNode), 
					     0, 0, NULL)))
	    return rcOutOfMemory ;
        }
    
    if (!(xNode = Node_appendChild (r -> pApp, pDomTree, xDocNode, 0, ntypAttr, 0, NULL, xDomTreeAttr, 0, 0, NULL)))
	return rcOutOfMemory ;

    if (!(xNode = Node_appendChild (r -> pApp, pDomTree, xNode, 0, ntypAttrValue, 0, (char *)&(r -> Component.xCurrDomTree), sizeof (r -> Component.xCurrDomTree), 0, 0, NULL)))
	return rcOutOfMemory ;

    /* Add at least one child node to document to make insertafter at the beginning of the document work */
    if (!(xNode = Node_appendChild (r -> pApp, pDomTree, xDocNode2, 0, ntypCDATA, 0, "", 0, 0, 0, NULL)))
	return rcOutOfMemory ;

    pDomTree -> xDocument = xDocNode ;

    pTokenTableSave = r -> Component.pTokenTable ;
    
    if ((rc = ParseTokens (r, &pStart, pEnd, r -> Component.pTokenTable, "", NULL, (tNodeType)r -> Component.pTokenTable -> nDefNodeType, 0, 0, 0, 0, String2Ndx (r -> pApp, "root", 4), xDocNode2, 0, NULL, NULL, 0)) != ok)
	return rc ; 
    
    /* Add one child node end the end to catch loops that end at the very last node */
    if (!(xNode = Node_appendChild (r -> pApp, pDomTree, xDocNode2, 0, ntypCDATA, 0, "", 0, 0, 0, NULL)))
	return rcOutOfMemory ;

    r -> Component.pTokenTable = pTokenTableSave ;


#ifdef CLOCKS_PER_SEC
    if (r -> Component.Config.bDebug)
	{
        cl2 = clock () ;
	lprintf (r -> pApp,  "[%d]PERF: Parse Start Time:	    %d ms \n", r -> pThread -> nPid, ((cl1 - r -> startclock) * 1000 / CLOCKS_PER_SEC)) ;
	lprintf (r -> pApp,  "[%d]PERF: Parse End Time:		    %d ms \n", r -> pThread -> nPid, ((cl2 - r -> startclock) * 1000 / CLOCKS_PER_SEC)) ;
	lprintf (r -> pApp,  "[%d]PERF: Parse Time:		    %d ms \n", r -> pThread -> nPid, ((cl2 - cl1) * 1000 / CLOCKS_PER_SEC)) ;
	DomStats (r -> pApp) ;
	}
#endif        

    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_Parse                                                            */
/*                                                                          */
/*! 
*   \_en
*   Parse source and create DomTree
*   
*   @param  r               Embperl request record
*   @param  pSource         Sourcetext
*   @param  nLen            Length of Sourcetext
*   @param  pxDomTree	    Returns DomTree index
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Parst die Quelle und erzeugt einen DomTree
*   
*   @param  r               Embperl request record
*   @param  pSource         Quellentext
*   @param  nLen            Länge des Quellentext
*   @param  pxDomTree	    Gibt DomTree Index zurück
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */


int embperl_Parse (/*i/o*/ register req * r,
                   /*in*/  char *	  pSource,
                   /*in*/  size_t         nLen,
                   /*out*/ tIndex *       pxDomTree)

    {
    int	    rc ;
    tDomTree * pDomTree  ;
    
    if (!(r -> Component.xCurrDomTree  = DomTree_new (r -> pApp, &pDomTree)))
	return rcOutOfMemory ;

    if ((rc = embperl_ParseSource (r, pSource, nLen, pDomTree)) != ok)
	{
	pDomTree = DomTree_self (r -> Component.xCurrDomTree) ;
	*pxDomTree = r -> Component.xCurrDomTree  = 0 ;
	DomTree_delete (r -> pApp, pDomTree) ;
	return rc ;
	}

    *pxDomTree = r -> Component.xCurrDomTree  ;
    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ParseFile                                                                */
/*                                                                          */
/* Parse a source file                                                      */
/*                                                                          */
/* ------------------------------------------------------------------------ */


int ParseFile (/*i/o*/ register req * r)

    {
    char * pStart = r -> Component.pBuf ;
    char * pEnd   = r -> Component.pEndPos ;
    tIndex xDomTree ;

    return embperl_Parse (r, pStart, pEnd - pStart, &xDomTree) ;
    }

