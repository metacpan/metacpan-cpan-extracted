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
#   $Id: eputil.c 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################*/


#include "ep.h"
#include "epmacro.h"


/* ---------------------------------------------------------------------------- */
/* Output a string and escape html special character to html special            */
/* representation (&xxx;)                                                       */
/*                                                                              */
/* i/o sData     = input:  perl string                                          */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

void OutputToHtml (/*i/o*/ register req * r,
 		   /*i/o*/ const char *   sData)

    {
    char * pHtml  ;
    const char * p = sData ;
    
    EPENTRY (OutputToHtml) ;

    if (r -> Component.pCurrEscape == NULL)
        {
        oputs (r, sData) ;
        return ;
        }

    
    while (*sData)
        {
        if (*sData == '\\' && (r -> Component.nCurrEscMode & escEscape) == 0)
            {
            if (p != sData)
                owrite (r, p, sData - p) ;
            sData++ ;
            p = sData ;
            }
        else
            {
            pHtml = r -> Component.pCurrEscape[(unsigned char)(*sData)].sHtml ;
            if (*pHtml)
                {
                if (p != sData)
                    owrite (r, p, sData - p) ;
                oputs (r, pHtml) ;
                p = sData + 1;
                }
            }
        sData++ ;
        }
    if (p != sData)
        owrite (r, p, sData - p) ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Output a string and escape it                                                */
/*                                                                              */
/* in sData     = input:  string                                                */
/*    nDataLen  = input:  length of string                                      */
/*    pEscTab   = input:  escape table                                          */
/*    cEscChar  = input:  char to escape escaping (0 = off)                     */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

void OutputEscape (/*i/o*/ register req * r,
 		   /*in*/  const char *   sData,
 		   /*in*/  int            nDataLen,
 		   /*in*/  struct tCharTrans *   pEscTab,
 		   /*in*/  char           cEscChar)

    {
    char * pHtml  ;
    const char * p ;
    int	         l ;

    EPENTRY (OutputEscape) ;

    if (pEscTab == NULL)
        {
        owrite (r, sData, nDataLen) ;
        return ;
        }

    p = sData ;
    l = nDataLen ;

    while (l > 0)
        {
        if (cEscChar && *sData == cEscChar)
            {
            if (p != sData)
                owrite (r, p, sData - p) ;
            sData++, l-- ;
            p = sData ;
            }
        else
            {
            pHtml = pEscTab[(unsigned char)(*sData)].sHtml ;
            if (*pHtml)
                {
                if (p != sData)
                    owrite (r, p, sData - p) ;
                oputs (r, pHtml) ;
                p = sData + 1;
                }
            }
        sData++, l-- ;
        }
    if (p != sData)
        owrite (r, p, sData - p) ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Escape a string and return a sv                                              */
/*                                                                              */
/* in sData     = input:  string                                                */
/*    nDataLen  = input:  length of string                                      */
/*    pEscTab   = input:  escape table                                          */
/*    cEscChar  = input:  char to escape escaping (0 = off)                     */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

SV * Escape	  (/*i/o*/ register req * r,
 		   /*in*/  const char *   sData,
 		   /*in*/  int            nDataLen,
 		   /*in*/  int            nEscMode,
 		   /*in*/  struct tCharTrans *   pEscTab,
 		   /*in*/  char           cEscChar)

    {
    epTHX_
    char * pHtml  ;
    const char * p ;
    int	         l ;
    SV *         pSV = newSVpv("",0) ;

    EPENTRY (Escape) ;


    if (nEscMode >= 0)
	{	    
	if ((nEscMode & escXML) && !r -> Component.bEscInUrl)
	    pEscTab = Char2XML ;
	else if ((nEscMode & escHtml) && !r -> Component.bEscInUrl)
	    {
    	    struct tCharTrans * pChar2Html  ;

    	    if (nEscMode & escHtmlUtf8)
	    	pChar2Html = Char2HtmlMin ;
    	    else if (r -> Config.nOutputEscCharset == ocharsetLatin1)
	    	pChar2Html = Char2Html ;
	    else if (r -> Config.nOutputEscCharset == ocharsetLatin2)
	    	pChar2Html = Char2HtmlLatin2 ;
	    else
	    	pChar2Html = Char2HtmlMin ;
    	    pEscTab = pChar2Html ;
    	    }
	else if (nEscMode & escUrl)
	    pEscTab = Char2Url ;
	else 
	    pEscTab = NULL ;
	if (nEscMode & escEscape)
	    cEscChar = '\0' ;
	else
	    cEscChar = '\\' ;
	}

    if (pEscTab == NULL)
        {
        sv_setpvn (pSV, sData, nDataLen) ;
        return pSV ;
        }

    p = sData ;
    l = nDataLen ;

    while (l > 0)
        {
        if (cEscChar && *sData == cEscChar)
            {
            if (p != sData)
		sv_catpvn (pSV, (char *)p, sData - p) ;
            sData++, l-- ;
            p = sData ;
            }
        else
            {
            pHtml = pEscTab[(unsigned char)(*sData)].sHtml ;
            if (*pHtml)
                {
                if (p != sData)
                    sv_catpvn (pSV, (char *)p, sData - p) ;
                sv_catpv (pSV, pHtml) ;
                p = sData + 1;
                }
            }
        sData++, l-- ;
        }
    if (p != sData)
        sv_catpvn (pSV, (char *)p, sData - p) ;
    return pSV ;
    }

#if 0

/* ---------------------------------------------------------------------------- */
/* find substring ignore case                                                   */
/*                                                                              */
/* in  pSring  = string to search in (any case)                                 */
/* in  pSubStr = string to search for (must be upper case)                      */
/*                                                                              */
/* out ret  = pointer to pSubStr in pStringvalue or NULL if not found           */
/*                                                                              */
/* ---------------------------------------------------------------------------- */



static const char * stristr (/*in*/ const char *   pString,
                             /*in*/ const char *   pSubString)

    {
    char c = *pSubString ;
    int  l = strlen (pSubString) ;
    
    do
        {
        while (*pString && toupper (*pString) != c)
            pString++ ;

        if (*pString == '\0')
            return NULL ;

        if (strnicmp (pString, pSubString, l) == 0)
            return pString ;
        pString++ ;
        }
    
    while (TRUE) ;
    }



/* ---------------------------------------------------------------------------- */
/* make string lower case */
/* */
/* i/o  pSring  = string to search in (any case) */
/* */
/* ---------------------------------------------------------------------------- */


static char * strlower (/*in*/ char *   pString)

    {
    char * p = pString ;
    
    while (*p)
        {
        *p = tolower (*p) ;
        p++ ;
        }

    return pString ;
    }

#endif


/* ---------------------------------------------------------------------------- */
/* find substring with max len                                                  */
/*                                                                              */
/* in  pSring  = string to search in						*/
/* in  pSubStr = string to search for						*/
/*                                                                              */
/* out ret  = pointer to pSubStr in pStringvalue or NULL if not found           */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


 
const char * strnstr (/*in*/ const char *   pString,
                             /*in*/ const char *   pSubString,
			     /*in*/ int            nMax)

    {
    char c = *pSubString ;
    int  l = strlen (pSubString) ;
    
    while (nMax-- > 0)
        {
        while (*pString && *pString != c)
            pString++ ;

        if (*pString == '\0')
            return NULL ;

        if (strncmp (pString, pSubString, l) == 0)
            return pString ;
        pString++ ;
        }
    return NULL ;
    }



/* ---------------------------------------------------------------------------- */
/* save strdup                                                                  */
/*                                                                              */
/* in  pSring  = string to save on memory heap                                  */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


char * sstrdup (/*in*/ tReq * r,
                /*in*/ char *   pString)

    {
    epTHX_
    char * p ;
    
    if (pString == NULL)
        return NULL ;

    p = malloc (strlen (pString) + 1) ;

    strcpy (p, pString) ;

    return p ;
    }



/* */
/* compare html escapes */
/* */

static int CmpCharTrans (/*in*/ const void *  pKey,
                         /*in*/ const void *  pEntry)

    {
    return strcmp ((const char *)pKey, ((struct tCharTrans *)pEntry) -> sHtml) ;
    }



/* ------------------------------------------------------------------------- */
/*                                                                           */
/* replace html special character representation (&xxx;) with correct chars  */
/* and delete all html tags                                                  */
/* The Replacement is done in place, the whole string will become shorter    */
/* and is padded with spaces                                                 */
/* tags and special charcters which are preceeded by a \ are not translated  */
/* carrige returns are replaced by spaces                                    */
/* if optRawInput is set the functions do just nothing                       */
/* 								             */
/* i/o sData     = input:  html string                                       */
/*                 output: perl string                                       */
/* in  nLen      = length of sData on input (or 0 for null terminated)       */
/*                                                                           */
/* ------------------------------------------------------------------------- */

int   TransHtml (/*i/o*/ register req * r,
		/*i/o*/ char *         sData,
		/*in*/   int           nLen)

    {
    char * p = sData ;
    char * s ;
    char * e ;
    struct tCharTrans * pChar ;
    int   bInUrl    = r -> Component.bEscInUrl ;
    bool  bUrlEsc   = r -> Component.Config.nInputEscMode & iescUrl ;
    bool  bHtmlEsc  = r -> Component.Config.nInputEscMode & iescHtml ;
    bool  bRemove   = r -> Component.Config.nInputEscMode & iescRemoveTags ;

    if (bUrlEsc && bHtmlEsc && !bInUrl)
        bUrlEsc = 0 ;

    EPENTRY (TransHtml) ;
	
    if (bInUrl == 16)
	{ 
	/* Just remove \ and }{ for rtf */
	if (nLen == 0)
	    nLen = strlen (sData) ;
	e = sData + nLen ;
	while (p < e)
	    {
	    if (*p == '}' && p[1] == '{')
	    	*p++ = ' ', *p++ = ' ' ;
	    if (*p == '\\' && p[1] != '\0')
	    	*p++ = ' ' ;
	    p++ ;
	    }	
	return nLen ; 	
        }

    if (r -> Component.Config.nInputEscMode == iescNone)
	{ 
#if PERL_VERSION < 5
	/* Just remove CR for raw input for perl 5.004 */
	if (nLen == 0)
	    nLen = strlen (sData) ;
	e = sData + nLen ;
	while (p < e)
	    {
	    if (*p == '\r')
	    	*p = ' ' ;
	    p++ ;
	    }	
#endif
	return nLen ; 	
        }
        
    s = NULL ;
    if (nLen == 0)
        nLen = strlen (sData) ;
    e = sData + nLen ;

    while (p < e)
	{
	if (*p == '\\')
	    {
        
	    if (bRemove && p[1] == '<')
		{ /*  Quote next HTML tag */
		memmove (p, p + 1, e - p - 1) ;
		e[-1] = ' ' ;
		p++ ;
		while (p < e && *p != '>')
		    p++ ;
		}
	    else if (bHtmlEsc && p[1] == '&')
		{ /*  Quote next HTML char */
		memmove (p, p + 1, e - p - 1) ;
		e[-1] = ' ' ;
		p++ ;
		while (p < e && *p != ';')
		    p++ ;
		}
	    else if (bUrlEsc && p[1] == '%')
		{ /*  Quote next URL escape */
		memmove (p, p + 1, e - p - 1) ;
		e[-1] = ' ' ;
		p += 3 ;
		}
	    else
		p++ ; /* Nothing to quote */
	    }
#if PERL_VERSION < 5
	/* remove CR for perl 5.004 */
	else if (*p == '\r')
	    {
	    *p++ = ' ' ;
	    }
#endif
	else
	    {
	    if (bRemove && p[0] == '<' && (isalpha (p[1]) || p[1] == '/'))
		{ /*  count HTML tag length */
		s = p ;
		p++ ;
		while (p < e && *p != '>')
		    p++ ;
		if (p < e)
		    p++ ;
		else
		    { /* missing left '>' -> no html tag  */
		    p = s ;
		    s = NULL ;
		    }
		}
	    else if (bHtmlEsc && p[0] == '&')
		{ /*  count HTML char length */
		s = p ;
		p++ ;
		while (p < e && *p != ';')
		    p++ ;

		if (p < e)
		    {
		    *p = '\0' ;
		    p++ ;
		    pChar = (struct tCharTrans *)bsearch (s, Html2Char, sizeHtml2Char, sizeof (struct tCharTrans), CmpCharTrans) ;
		    if (pChar)
			*s++ = pChar -> c ;
		    else
			{
			*(p-1)=';' ;
			p = s ;
			s = NULL ;
			}
		    }
		else
		    {
		    p = s ;
		    s = NULL ;
		    }
		}
	    else if (bUrlEsc && p[0] == '%' && isdigit (p[1]) && isxdigit (p[2]))
		{ 

		s = p ;
		p += 3 ;
                *s++ = ((toupper (p[-2]) - (isdigit (p[-2])?'0':('A' - 10))) << 4) 
                      + (toupper (p[-1]) - (isdigit (p[-1])?'0':('A' - 10)))  ;
		}
	    if (s && (p - s) > 0)
		{ /* copy rest of string, pad with spaces */
		memmove (s, p, e - p + 1) ;
		memset (e - (p - s), ' ', (p - s)) ;
		nLen -= p - s ;
		p = s ;
		s = NULL ;
		}
	    else
		if (p < e)
		    p++ ;
	    }
	}

    return nLen ;
    }



void TransHtmlSV (/*i/o*/ register req * r,
		  /*i/o*/ SV *           pSV) 

    {
    epTHX_
    STRLEN vlen ;
    STRLEN nlen ;
    char * pVal = SvPV (pSV, vlen) ;

    nlen = TransHtml (r, pVal, vlen) ;

    pVal[nlen] = '\0' ;
    SvCUR_set(pSV, nlen) ;
    }		  


/* ---------------------------------------------------------------------------- */
/* get argument from html tag  */
/* */
/* in  pTag = html tag args  (eg. arg=val arg=val .... >) */
/* in  pArg = name of argument (must be upper case) */
/* */
/* out pLen = length of value */
/* out ret  = pointer to value or NULL if not found */
/* */
/* ---------------------------------------------------------------------------- */

const char * GetHtmlArg (/*in*/  const char *    pTag,
                         /*in*/  const char *    pArg,
                         /*out*/ int *           pLen)

    {
    const char * pVal ;
    const char * pEnd ;
    int l ;

    /*EPENTRY (GetHtmlArg) ;*/

    l = strlen (pArg) ;
    while (*pTag)
        {
        *pLen = 0 ;

        while (*pTag && !isalpha (*pTag))
            pTag++ ; 

        pVal = pTag ;
        while (*pVal && !isspace (*pVal) && *pVal != '=' && *pVal != '>')
            pVal++ ;

        while (*pVal && isspace (*pVal))
            pVal++ ;

        if (*pVal == '=')
            {
            pVal++ ;
            while (*pVal && isspace (*pVal))
                pVal++ ;
        
            pEnd = pVal ;
            if (*pVal == '"' || *pVal == '\'')
                {
		char nType = '\0';
                char q = *pVal++ ;
                pEnd++ ;

		while ((*pEnd != q || nType) && *pEnd != '\0')
		    {
		    if (nType == '\0' && *pEnd == '[' && (pEnd[1] == '+' || pEnd[1] == '-' || pEnd[1] == '$' || pEnd[1] == '!' || pEnd[1] == '#'))
			nType = *++pEnd ;
		    else if (nType && *pEnd == nType && pEnd[1] == ']')
			{
			nType = '\0';
			pEnd++ ;
			}
                    pEnd++ ;
		    }
		}
            else
                {
		char nType = '\0';
		while ((!isspace (*pEnd) || nType) && *pEnd != '\0'  && *pEnd != '>')
		    {
		    if (nType == '\0' && *pEnd == '[' && (pEnd[1] == '+' || pEnd[1] == '-' || pEnd[1] == '$' || pEnd[1] == '!' || pEnd[1] == '#'))
			nType = *++pEnd ;
		    else if (nType && *pEnd == nType && pEnd[1] == ']')
			{
			nType = '\0';
			pEnd++ ;
			}
                    pEnd++ ;
		    }
                }

            *pLen = pEnd - pVal ;
            }
        else
            pEnd = pVal ;

        
        if (strnicmp (pTag, pArg, l) == 0 && (pTag[l] == '=' || isspace (pTag[l]) || pTag[l] == '>' || pTag[l] == '\0'))
            {
            if (*pLen > 0)
                return pVal ;
            else
                return pTag ;
            }

        pTag = pEnd ;
        }

    *pLen = 0 ;
    return NULL ;
    }


    
    
/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Get a Value out of a perl hash                                               */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


char * GetHashValueLen (/*in*/  tReq *         r,
                        /*in*/  HV *           pHash,
                        /*in*/  const char *   sKey,
                        /*in*/  int            nLen,
                        /*in*/  int            nMaxLen,
                        /*out*/ char *         sValue)

    {
    epTHX_
    SV **   ppSV ;
    char *  p ;
    STRLEN  len ;        

    /*EPENTRY (GetHashValueLen) ;*/

    ppSV = hv_fetch(pHash, (char *)sKey, nLen, 0) ;  
    if (ppSV != NULL)
        {
        p = SvPV (*ppSV ,len) ;
        if (len >= (STRLEN)nMaxLen)
            len = nMaxLen - 1 ;        
        strncpy (sValue, p, len) ;
        }
    else
        len = 0 ;

    sValue[len] = '\0' ;
        
    return sValue ;
    }


char * GetHashValue (/*in*/  tReq *         r,
                     /*in*/  HV *           pHash,
                     /*in*/  const char *   sKey,
                     /*in*/  int            nMaxLen,
                     /*out*/ char *         sValue)
    {
    return GetHashValueLen (r, pHash, sKey, strlen (sKey), nMaxLen, sValue) ;
    }




IV    GetHashValueInt (/*in*/  pTHX_
                        /*in*/  HV *           pHash,
                        /*in*/  const char *   sKey,
                        /*in*/  IV            nDefault)

    {
    SV **   ppSV ;

    /*EPENTRY (GetHashValueInt) ;*/

    ppSV = hv_fetch(pHash, (char *)sKey, strlen (sKey), 0) ;  
    if (ppSV != NULL)
        return SvIV (*ppSV) ;
        
    return nDefault ;
    }

UV    GetHashValueUInt (/*in*/  tReq *         r,
                        /*in*/  HV *           pHash,
                        /*in*/  const char *   sKey,
                        /*in*/  UV            nDefault)

    {
    SV **   ppSV ;
#ifdef PERL_IMPLICIT_CONTEXT
    pTHX ;
    if (r)
        {
        aTHX = r -> pPerlTHX ;
        }
    else
        {
        aTHX = PERL_GET_THX ;
        }
#endif

    /*EPENTRY (GetHashValueInt) ;*/
    
    ppSV = hv_fetch(pHash, (char *)sKey, strlen (sKey), 0) ;  
    if (ppSV != NULL && *ppSV && SvOK(*ppSV))
        {
        return SvUV ((*ppSV)) ;
        }

    return nDefault ;
    }


char * GetHashValueStr (/*in*/  pTHX_
                        /*in*/  HV *           pHash,
                        /*in*/  const char *   sKey,
                        /*in*/  char *         sDefault)

    {
    SV **   ppSV ;
    STRLEN  l ;

    /*EPENTRY (GetHashValueInt) ;*/

    ppSV = hv_fetch(pHash, (char *)sKey, strlen (sKey), 0) ;  
    if (ppSV != NULL)
        return SvPV (*ppSV, l) ;
        
    return sDefault ;
    }

char * GetHashValueStrDup (/*in*/  pTHX_
                           /*in*/  tMemPool *     pPool,
                           /*in*/  HV *           pHash,
                           /*in*/  const char *   sKey,
                           /*in*/  char *         sDefault)
    {
    SV **   ppSV ;
    STRLEN  l ;
    char *  s ;

    ppSV = hv_fetch(pHash, (char *)sKey, strlen (sKey), 0) ;  
    if (ppSV != NULL)
        {
	if ((s = SvPV (*ppSV, l)))
	    return ep_pstrdup (pPool, s);
	else
	    return NULL ;
	}

    if (sDefault)
        return ep_pstrdup (pPool, sDefault) ;
    else
	return NULL ;
    }

char * GetHashValueStrDupA (/*in*/  pTHX_
                           /*in*/  HV *           pHash,
                           /*in*/  const char *   sKey,
                           /*in*/  char *         sDefault)
    {
    SV **   ppSV ;
    STRLEN  l ;
    char *  s ;

    ppSV = hv_fetch(pHash, (char *)sKey, strlen (sKey), 0) ;  
    if (ppSV != NULL)
        {
	if ((s = SvPV (*ppSV, l)))
	    return strdup (s);
	else
	    return NULL ;
	}

    if (sDefault)
        return strdup (sDefault) ;
    else
	return NULL ;
    }


void GetHashValueStrOrHash (/*in*/  tReq *         r,
                            /*in*/  HV *           pHash,
                              /*in*/  const char *   sKey,
                              /*out*/ char * *       sValue,
                              /*out*/ HV * *         pHV)

    {
    epTHX_
    SV **   ppSV ;
    STRLEN  l ;

    ppSV = hv_fetch(pHash, (char *)sKey, strlen (sKey), 0) ;  
    if (ppSV != NULL)
        {
        if (!SvROK(*ppSV) || SvTYPE (SvRV(*ppSV)) != SVt_PVHV)
            *sValue = SvPV (*ppSV, l), *pHV = NULL ;
        else
            *pHV = (HV *)SvRV(*ppSV), *sValue = NULL ;
        }
    }


SV * GetHashValueSVinc    (/*in*/  tReq *         r,
                           /*in*/  HV *           pHash,
                           /*in*/  const char *   sKey,
                           /*in*/  SV *         sDefault)
    {
    epTHX_
    SV **   ppSV ;

    ppSV = hv_fetch(pHash, (char *)sKey, strlen (sKey), 0) ;  
    if (ppSV != NULL)
        {
	SvREFCNT_inc (*ppSV) ;
        return *ppSV ;
	}

    if (sDefault)
        return SvREFCNT_inc (sDefault) ;
    else
	return NULL ;
    }


SV * GetHashValueSV    (/*in*/  tReq *         r,
                        /*in*/  HV *           pHash,
                           /*in*/  const char *   sKey)
    {
    epTHX_
    SV **   ppSV ;

    ppSV = hv_fetch(pHash, (char *)sKey, strlen (sKey), 0) ;  
    if (ppSV != NULL)
        {
        return *ppSV ;
	}

    return NULL ;
    }

int GetHashValueHREF      (/*in*/  req *          r,
                           /*in*/  HV *           pHash,
                           /*in*/  const char *   sKey,
                           /*out*/ HV * *         ppHV)
    {
    epTHX_
    SV **   ppSV ;
    HV *    pHV ;

    ppSV = hv_fetch(pHash, (char *)sKey, strlen (sKey), 0) ;  
    if (ppSV != NULL)
        {
        if (!SvROK(*ppSV))
            {
            strncpy (r -> errdat2, sKey, sizeof(r -> errdat1) - 1) ;
            return rcNotHashRef ; 
            }
        pHV = (HV *)SvRV(*ppSV) ;
        if (SvTYPE(pHV) != SVt_PVHV)
            {
            strncpy (r -> errdat2, sKey, sizeof(r -> errdat1) - 1) ;
            return rcNotHashRef ; 
            }
        *ppHV = pHV ;
        return ok ;
	}

    strncpy (r -> errdat2, sKey, sizeof(r -> errdat1) - 1) ;
    return rcNotHashRef ; 
    }


int GetHashValueCREF      (/*in*/  req *          r,
                           /*in*/  HV *           pHash,
                           /*in*/  const char *   sKey,
                           /*out*/ CV * *         ppCV)
    {
    epTHX_
    int     rc ;
    SV **   ppSV ;
    CV *    pCV ;

    ppSV = hv_fetch(pHash, (char *)sKey, strlen (sKey), 0) ;  
    if (ppSV != NULL)
        {
        if (SvPOK(*ppSV))
            {
	    if ((rc = EvalConfig (r -> pApp, *ppSV, 0, NULL, sKey, ppCV)) != ok)
	        return rc ;
            return ok ;
            }
        if (!SvROK(*ppSV))
            {
            strncpy (r -> errdat2, sKey, sizeof(r -> errdat1) - 1) ;
            return rcNotCodeRef ; 
            }
        pCV = (CV *)SvRV(*ppSV) ;
        if (SvTYPE(pCV) != SVt_PVCV)
            {
            strncpy (r -> errdat2, sKey, sizeof(r -> errdat1) - 1) ;
            return rcNotCodeRef ; 
            }
        *ppCV = (CV *)SvREFCNT_inc ((SV *)pCV) ;
        return ok ;
	}

    *ppCV = NULL ;
    return ok ; 
    }


void SetHashValueStr   (/*in*/  tReq *         r,
                        /*in*/  HV *           pHash,
                        /*in*/  const char *   sKey,
                        /*in*/  char *         sValue)

    {
    epTHX_
    SV *   pSV = newSVpv (sValue, 0) ;

    /*EPENTRY (GetHashValueInt) ;*/

    hv_store(pHash, (char *)sKey, strlen (sKey), pSV, 0) ;  
    }

void SetHashValueInt   (/*in*/  tReq *         r,
                        /*in*/  HV *           pHash,
                        /*in*/  const char *   sKey,
                        /*in*/  IV             nValue)

    {
    SV *   pSV  ;
#ifdef PERL_IMPLICIT_CONTEXT
    pTHX ;
    if (r)
        aTHX = r -> pPerlTHX ;
    else
        aTHX = PERL_GET_THX ;
#endif

    /*EPENTRY (GetHashValueInt) ;*/

    tainted = 0 ; /* doesn't make sense to taint an integer */
    pSV = newSViv (nValue) ;
    hv_store(pHash, (char *)sKey, strlen (sKey), pSV, 0) ;  

    }


SV * CreateHashRef   (/*in*/  tReq *         r,
                      /*in*/  char *   sKey, ...)
    
    {
    epTHX_
    va_list         marker;
    SV *            pVal ;
    HV *            pHash = newHV() ;
    int             nType ;

    va_start (marker, sKey);     
    while (sKey)
        {
        nType = va_arg (marker, int) ;
        if (nType == hashtstr)
            {
            char * p = va_arg(marker, char *) ;
            if (p)
                pVal = newSVpv (p, 0) ;
            else
                pVal = NULL ;
            }
        else if (nType == hashtint)
            pVal = newSViv (va_arg(marker, int)) ;
        else
            pVal = va_arg(marker, SV *) ;

        if (pVal)
            hv_store (pHash, sKey, strlen(sKey), pVal, 0) ;
        sKey = va_arg(marker, char *) ;
        }
    va_end (marker) ;

    return newRV_noinc ((SV *)pHash) ;
    }



/* ------------------------------------------------------------------------- */
/*                                                                           */
/* GetLineNo								     */
/*                                                                           */
/* Counts the \n between pCurrPos and pSourcelinePos and in-/decrements      */
/* nSourceline accordingly                                                   */
/*                                                                           */
/* return Linenumber of pCurrPos                                             */
/*                                                                           */
/* ------------------------------------------------------------------------- */


int GetLineNoOf (/*i/o*/ register req * r,
               /*in*/   char * pPos)

    {

    
    if (r -> Component.pSourcelinePos == NULL)
	return r -> Component.nSourceline = r -> Component.Param.nFirstLine ;

    if (r -> Component.pLineNoCurrPos)
        pPos = r -> Component.pLineNoCurrPos ;

    if (pPos == NULL || pPos == r -> Component.pSourcelinePos || pPos < r -> Component.pBuf || pPos > r -> Component.pEndPos)
        return r -> Component.nSourceline ;


    if (pPos > r -> Component.pSourcelinePos)
        {
        char * p = r -> Component.pSourcelinePos ;

        while (p < pPos && p < r -> Component.pEndPos)
            {
            if (*p++ == '\n')
                r -> Component.nSourceline++ ;
            }
        }
    else
        {
        char * p = r -> Component.pSourcelinePos ;

        while (p > pPos && p > r -> Component.pBuf)
            {
            if (*--p == '\n')
                r -> Component.nSourceline-- ;
            }
        }

    r -> Component.pSourcelinePos = pPos ;
    return r -> Component.nSourceline ;
    }


int GetLineNo (/*i/o*/ register req * r)

    {
    char * pPos  ;

    if (r == NULL) 
        return 0 ;
    
    pPos = r -> Component.pCurrPos ;
    return GetLineNoOf (r, pPos) ;
    }




#ifdef EP2

/* ------------------------------------------------------------------------- */
/*                                                                           */
/* ClearSymtab								     */
/*                                                                           */
/*                                                                           */
/* in	sPackage = package which symtab should be cleared                    */
/*                                                                           */
/* ------------------------------------------------------------------------- */



void ClearSymtab (/*i/o*/ register req * r,
		  /*in*/  const char *   sPackage,
                  /*in*/  int		 bDebug) 

    {
    /*dTHXsem */
    SV *	val;
    char *	key;
    I32		klen;
    
    SV *	sv;
    HV *	hv;
    AV *	av;
    struct io *	io ;
    HV *	symtab ;
    STRLEN	l ;
    CV *	pCV ;
    SV *	pSV ;
    SV * *	ppSV ;
    SV *	pSVErr ;
    HV *	pCleanupHV ;
    char *      s ;
    char *      sObjName ;
    /*
    GV *	pFileGV ;
    GV *	symtabgv ;
    GV *	symtabfilegv ;
    */

    dTHR;
    epTHX_

    if ((symtab = gv_stashpv ((char *)sPackage, 0)) == NULL)
	return ;

    ppSV = hv_fetch (symtab, "_ep_DomTree", sizeof ("_ep_DomTree") - 1, 0) ;
    if (!ppSV || !*ppSV)
	{
	if (bDebug)
	    lprintf (r -> pApp,  "[%d]CUP: No Perl code in %s\n", r -> pThread -> nPid, sPackage) ;
	return ;
	}

    /*
    symtabgv = (GV *)*ppSV ;
    symtabfilegv = (GV *)GvFILEGV (symtabgv) ;
    */

    pSV = newSVpvf ("%s::CLEANUP", sPackage) ;
    newSVpvf2(pSV) ;
    s   = SvPV (pSV, l) ;
    pCV = perl_get_cv (s, 0) ;
    if (pCV)
	{
	dSP ;
	if (bDebug)
	    lprintf (r -> pApp,  "[%d]CUP: Call &%s::CLEANUP\n", r -> pThread -> nPid, sPackage) ;
	PUSHMARK(sp) ;
	perl_call_sv ((SV *)pCV, G_EVAL | G_NOARGS | G_DISCARD) ;
	pSVErr = ERRSV ;
	if (SvTRUE (pSVErr))
	    {
	    STRLEN l ;
	    char * p = SvPV (pSVErr, l) ;
	    if (l > sizeof (r -> errdat1) - 1)
		l = sizeof (r -> errdat1) - 1 ;
	    strncpy (r -> errdat1, p, l) ;
	    if (l > 0 && r -> errdat1[l-1] == '\n')
		l-- ;
	    r -> errdat1[l] = '\0' ;
     
	    LogError (r, rcEvalErr) ;

	    sv_setpv(pSVErr,"");
	    }
	}
    
    
    pCleanupHV = perl_get_hv (s, 1) ;
    
    SvREFCNT_dec(pSV) ;

    (void)hv_iterinit(symtab);
    while ((val = hv_iternextsv(symtab, &key, &klen))) 
	{
	if(SvTYPE(val) != SVt_PVGV || SvANY(val) == NULL)
	    {
	    /*
            if (bDebug)
	        lprintf (r -> pApp,  "[%d]CUP: Ignore %s because it's no gv\n", r -> pThread -> nPid, key) ;
	    */
	    continue;
	    }

	s = GvNAME((GV *)val) ;
	l = strlen (s) ;

	ppSV = hv_fetch (pCleanupHV, s, l, 0) ;

	if (ppSV && *ppSV && SvIV (*ppSV) == 0)
	    {
	    /*
            if (bDebug)
	        lprintf (r -> pApp,  "[%d]CUP: Ignore %s because it's in %%CLEANUP\n", r -> pThread -> nPid, s) ;
            */
	    continue ;
	    }

	
	if (!(ppSV && *ppSV && SvTRUE (*ppSV)))
	    {
	    if(GvIMPORTED((GV*)val))
		{
		/*
                if (bDebug)
		    lprintf (r -> pApp,  "[%d]CUP: Ignore %s because it's imported\n", r -> pThread -> nPid, s) ;
                */
		continue ;
		}
	    
	    if (s[0] == ':' && s[1] == ':')
		{
		/*
                if (bDebug)
		    lprintf (r -> pApp,  "[%d]CUP: Ignore %s because it's special\n", r -> pThread -> nPid, s) ;
		*/
                continue ;
		}
	    
	    /*
	    pFileGV = GvFILEGV ((GV *)val) ;
	    if (pFileGV != symtabfilegv)
		{
		if (bDebug)
		    lprintf (r -> pApp,  "[%d]CUP: Ignore %s because it's defined in another source file (%s)\n", r -> pThread -> nPid, s, GvFILE((GV *)val)) ;
		continue ;
		}
	    */
	    }
	
	sObjName = NULL ;
	
        /* lprintf (r -> pApp,  "[%d]CUP: type = %d flags=%x\n", r -> pThread -> nPid, SvTYPE (GvSV((GV*)val)), SvFLAGS (GvSV((GV*)val))) ; */
        if((sv = GvSV((GV*)val)) && SvTYPE (sv) == SVt_PVMG)
	    {
            HV * pStash = SvSTASH (sv) ;

            if (pStash)
                {
                sObjName = HvNAME(pStash) ;
                if (sObjName && strcmp (sObjName, "DBIx::Recordset") == 0)
                    {
                    SV * pSV = newSVpvf ("DBIx::Recordset::Undef ('%s')", s) ;
		    newSVpvf2(pSV) ;

	            if (bDebug)
	                lprintf (r -> pApp,  "[%d]CUP: Recordset *%s\n", r -> pThread -> nPid, s) ;
                    EvalDirect (r, pSV, 0, NULL) ;
                    SvREFCNT_dec (pSV) ;
                    }
                }
            }

        if((sv = GvSV((GV*)val)) && SvROK (sv) && SvOBJECT (SvRV(sv)))
	    {
            HV * pStash = SvSTASH (SvRV(sv)) ;
	    /* lprintf (r -> pApp,  "[%d]CUP: rv type = %d\n", r -> pThread -> nPid, SvTYPE (SvRV(GvSV((GV*)val)))) ; */
            if (pStash)
                {
                sObjName = HvNAME(pStash) ;
                if (sObjName && strcmp (sObjName, "DBIx::Recordset") == 0)
                    {
                    SV * pSV = newSVpvf ("DBIx::Recordset::Undef ('%s')", s) ;
		    newSVpvf2(pSV) ;

	            if (bDebug)
	                lprintf (r -> pApp,  "[%d]CUP: Recordset *%s\n", r -> pThread -> nPid, s) ;
                    EvalDirect (r, pSV, 0, NULL) ;
                    SvREFCNT_dec (pSV) ;
                    }
                }
            }
	if((sv = GvSV((GV*)val)) && (SvOK (sv) || SvROK (sv)))
	    {
	    if (bDebug)
                lprintf (r -> pApp,  "[%d]CUP: $%s = %s %s%s\n", r -> pThread -> nPid, s, SvPV (sv, l), sObjName?" Object of ":"", sObjName?sObjName:"") ;
	
	    if ((sv = GvSV((GV*)val)) && SvREADONLY (sv))
	        {
	        /*
                if (bDebug)
	            lprintf (r -> pApp,  "[%d]CUP: Ignore %s because it's readonly\n", r -> pThread -> nPid, s) ;
	        */
                }
            else
                {
	        sv_unmagic (sv, 'q') ; /* untie */
	        sv_setsv(sv, &sv_undef);
                }
	    }
	if((hv = GvHV((GV*)val)))
	    {
	    if (bDebug)
	        lprintf (r -> pApp,  "[%d]CUP: %%%s = ...\n", r -> pThread -> nPid, s) ;
            sv_unmagic ((SV *)hv, 'P') ; /* untie */
	    hv_clear(hv);
	    }
	if((av = GvAV((GV*)val)))
	    {
	    if (bDebug)
	        lprintf (r -> pApp,  "[%d]CUP: @%s = ...\n", r -> pThread -> nPid, s) ;
	    sv_unmagic ((SV *)av, 'P') ; /* untie */
	    av_clear(av);
	    }
	if((io = GvIO((GV*)val)))
	    {
	    if (bDebug)
	        lprintf (r -> pApp,  "[%d]CUP: IO %s = ...\n", r -> pThread -> nPid, s) ;
	    /* sv_unmagic ((SV *)io, 'q') ; */ /* untie */
	    /* do_close((GV *)val, 0); */
	    }
	}
    }

#endif


/* ------------------------------------------------------------------------- */
/*                                                                           */
/* UndefSub 								     */
/*                                                                           */
/*                                                                           */
/* in	sName = name of sub                                                  */
/* in   sPackage = package name						     */
/*                                                                           */
/* ------------------------------------------------------------------------- */



void UndefSub    (/*i/o*/ register req * r,
		  /*in*/  const char *    sName, 
		  /*in*/  const char *    sPackage) 


    {
    CV * pCV ;
    int    l = strlen (sName) + strlen (sPackage) ;
    char * sFullname = _malloc (r, l + 3) ;
    epTHX_

    strcpy (sFullname, sPackage) ; 
    strcat (sFullname, "::") ; 
    strcat (sFullname, sName) ; 
    if (!(pCV = perl_get_cv (sFullname, 0)))
	{
	_free (r, sFullname) ;
	return ;
	}

    _free (r, sFullname) ;
 
    cv_undef (pCV) ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Get Session ID                                                               */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


char * GetSessionID (/*i/o*/ register req * r,
   		     /*in*/  HV * pSessionHash,
		     /*out*/ char * * ppInitialID,
		     /*out*/ IV * pModified)
    
    {
    SV *    pSVID = NULL ;
    MAGIC * pMG ;
    char *  pUID = "" ;
    STRLEN  ulen = 0 ;
    STRLEN  ilen = 0 ;
    epTHX_

    if (r -> nSessionMgnt)
	{			
	SV * pUserHashObj = NULL ;
	if ((pMG = mg_find((SV *)pSessionHash,'P')))
	    {
	    dSP;                            /* initialize stack pointer      */
	    int n ;
	    pUserHashObj = pMG -> mg_obj ;

	    PUSHMARK(sp);                   /* remember the stack pointer    */
	    XPUSHs(pUserHashObj) ;            /* push pointer to obeject */
	    PUTBACK;
	    n = perl_call_method ("getids", G_ARRAY) ; /* call the function             */
	    SPAGAIN;
	    if (n > 2)
		{
		int  savewarn = dowarn ;
		dowarn = 0 ; /* no warnings here */
		*pModified = POPi ;
		pSVID = POPs;
		pUID = SvPV (pSVID, ulen) ;
		pSVID = POPs;
		*ppInitialID = SvPV (pSVID, ilen) ;
		dowarn = savewarn ;
		}
	    PUTBACK;
	    }
        }
    return pUID ;
    }

/* ------------------------------------------------------------------------- */
/*                                                                           */
/* dirname								     */
/*                                                                           */
/* returns dir name of file                                                  */
/*                                                                           */
/* ------------------------------------------------------------------------- */



static void dirname (/*in*/ const char * filename,
              /*out*/ char *      dirname,
              /*in*/  int         size)

    {
    char * p = strrchr (filename, '/') ;

    if (p == NULL)
        {
        strncpy (dirname, ".", size) ;
        return ;
        }

    if (size - 1 > p - filename)
        size = p - filename ;

    strncpy (dirname, filename, size) ;
    dirname[size] = '\0' ;

    return ;
    }


#ifdef WIN32
#define isAbsPath(sFilename) \
            (sFilename[0] == '/' || sFilename[0] == '\\' ||   \
                (isalpha(sFilename[0]) && sFilename[1] == ':' && \
	            (sFilename[2] == '\\' || sFilename[2] == '/') \
                ) \
            ) 
#else
#define isAbsPath(sFilename)  (sFilename[0] == '/')  
#endif                  

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Make filename absolut                                                        */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

char * embperl_File2Abs  (/*i/o*/ register req * r,
                        /*in*/  tMemPool *     pPool,
                        /*in*/  const char *         sFilename)
    {
    epTHX_
#ifdef WIN32
    char * c ;
#endif
    char * sAbsname ;

    if (sFilename == NULL)
        return NULL ;


    /* is it a relative filename? -> append path */
    if (!isAbsPath(sFilename))
        {
        int l = strlen (sFilename) + strlen (r -> Component.sCWD) + 2 ;
        
        sAbsname                  = pPool?ep_palloc(pPool, l):malloc (l) ;
        strcpy (sAbsname, r -> Component.sCWD) ;
        strcat (sAbsname, PATH_SEPARATOR_STR) ;
        strcat (sAbsname, sFilename) ;
        }
    else
        sAbsname = pPool?ep_pstrdup (pPool, sFilename):strdup (sFilename) ;

#ifdef WIN32
    c = sAbsname ;
    while (*c)
	{ /* convert / to \ */
 	if (*c == '/')
	    *c = '\\' ;
	c++ ;
	}
#endif

    return sAbsname ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Change CWD to sourcefile dir                                                 */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

void embperl_SetCWDToFile  (/*i/o*/ register req * r,
                            /*in*/  const char *         sFilename)

    {
    epTHX_
    
    char * sAbsFilename ;
    char * p ;


    if ((r -> Component.Config.bOptions & optDisableChdir) || 
          sFilename == NULL || *sFilename == '\0' ||
          r -> Component.Param.pInput)
          return ; 

        
        
    sAbsFilename = embperl_File2Abs(r, r -> pPool, sFilename) ;

    p = strrchr(sAbsFilename, PATH_SEPARATOR_CHAR) ;

    while (p && p > sAbsFilename + 2 && p[-1] == '.' && p[-2] == '.' && p[-3] == PATH_SEPARATOR_CHAR)
        {
        p[-3] = '\0' ;
        p = strrchr(sAbsFilename, PATH_SEPARATOR_CHAR) ;
        }


    r -> Component.sCWD = sAbsFilename ;
    if (p)
        *p = '\0' ;
    }

/* ------------------------------------------------------------------------- */
/*                                                                           */
/* Dirname                                                                   */
/*                                                                           */
/* returns dir name of file                                                  */
/*                                                                           */
/* ------------------------------------------------------------------------- */



void Dirname (/*in*/ const char * filename,
              /*out*/ char *      dirname,
              /*in*/  int         size)

    {
    char * p = strrchr (filename, '/') ;

    if (p == NULL)
        {
        strncpy (dirname, ".", size) ;
        return ;
        }

    if (size - 1 > p - filename)
        size = p - filename ;

    strncpy (dirname, filename, size) ;
    dirname[size] = '\0' ;

    return ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Change Dir to sourcefile dir                                                 */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

void ChdirToSource (/*i/o*/ register req * r,
                    /*in*/  char *         sInputfile)

    {
    if ((r -> Component.Config.bOptions & optDisableChdir) == 0 &&
        sInputfile != NULL && *sInputfile != '\0' && 
        !r -> Component.Param.pInput && !r -> Component.sResetDir[0])
        {
        char dir[PATH_MAX];
#ifdef WIN32
        char drive[_MAX_DRIVE];
        char fname[_MAX_FNAME];
        char ext[_MAX_EXT];
        char * c = sInputfile ;

        while (*c)
            { /* convert / to \ */
            if (*c == '/')
                *c = '\\' ;
            c++ ;
            }

        r -> nResetDrive = _getdrive () ;
        getcwd (r -> Component.sResetDir, sizeof (r -> Component.sResetDir) - 1) ;

        _splitpath(sInputfile, drive, dir, fname, ext );
        _chdrive (drive[0] - 'A' + 1) ;
#else
        Dirname (sInputfile, dir, sizeof (dir) - 1) ;
        getcwd (r -> Component.sResetDir, sizeof (r -> Component.sResetDir) - 1) ;
#endif
        if (dir[0])
            {
            if (chdir (dir) < 0)
                {
                strncpy (r -> errdat1, dir, sizeof(r -> errdat1) - 1) ;
                LogError (r, rcChdirError) ;
                }
            else
                {
                if (!(dir[0] == '/'  
            #ifdef WIN32
                    ||
                    dir[0] == '\\' || 
                        (isalpha(dir[0]) && dir[1] == ':' && 
                          (dir[2] == '\\' || dir[2] == '/')) 
            #endif                  
                    ))            
                    {
                    strcpy (r->Component.sCWD,r -> Component.sResetDir) ;
                    strcat (r->Component.sCWD,"/") ;
                    strcat (r->Component.sCWD,dir) ;
                    }
                else
                    strcpy (r->Component.sCWD,dir) ;
                }
            }
        else
            r -> Component.Config.bOptions |= optDisableChdir ;
        }
    else
        r -> Component.Config.bOptions |= optDisableChdir ;
    }
    
/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Path serach                                                                  */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

char * embperl_PathSearch  (/*i/o*/ register req * r,
                            /*in*/  tMemPool *     pPool,
                            /*in*/  const char *   sFilename,
                            /*in*/  int            nPathNdx)

    {
    epTHX_
    AV *pPathAV = r -> Config.pPathAV ;
    int skip = 0 ; 
    int i ;
    struct stat st ;
    char * absfn = NULL ;
    char * fn ;
    STRLEN l ;

    if (r -> Config.bDebug & dbgObjectSearch)
        lprintf (r -> pApp,  "[%d]Search for %s\n", r -> pThread -> nPid, sFilename) ; 

    if (isAbsPath(sFilename) || !pPathAV || AvFILL (pPathAV) < r -> Component.nPathNdx)
        {
        absfn = embperl_File2Abs (r, pPool, sFilename) ;
        if (r -> Config.bDebug & dbgObjectSearch)
            lprintf (r -> pApp,  "[%d]Search: nothing to search return %s\n", r -> pThread -> nPid, absfn) ; 
        return absfn ;
        }

    while (sFilename[0] == '.' && sFilename[1] == '.' &&  (sFilename[2] == '/' || sFilename[2] == '\\'))
        {
        skip++ ;
        sFilename += 3 ;
        }
    if (skip)
        skip += nPathNdx >= 0?nPathNdx:r -> Component.pPrev?r -> Component.pPrev -> nPathNdx:0 ;

    if (skip == 0 && sFilename[0] == '.' && (sFilename[1] == '/' || sFilename[1] == '\\'))
        {
        absfn = embperl_File2Abs (r, pPool, sFilename) ;
        if (stat (absfn, &st) == 0)
            {
            if (r -> Config.bDebug & dbgObjectSearch)
                lprintf (r -> pApp,  "[%d]Search: starts with ./ return %s\n", r -> pThread -> nPid, absfn) ; 
            return absfn ;
            }
        if (r -> Config.bDebug & dbgObjectSearch)
            lprintf (r -> pApp,  "[%d]Search: starts with ./, but not found\n", r -> pThread -> nPid) ; 
        return NULL ;
        }        


    for (i = skip ; i <= AvFILL (pPathAV); i++)
	{
        fn = ep_pstrcat(r -> pPool, SvPV(*av_fetch (pPathAV, i, 0), l), PATH_SEPARATOR_STR, sFilename, NULL) ;
        if (r -> Config.bDebug & dbgObjectSearch)
            lprintf (r -> pApp,  "[%d]Search: #%d test dir=%s, fn=%s (skip=%d)\n", r -> pThread -> nPid,  
                                        i,  SvPV(*av_fetch (pPathAV, i, 0), l), fn, skip) ; 
        if (stat (fn, &st) == 0)
            {
            r -> Component.nPathNdx = i ;        
            absfn = embperl_File2Abs (r, pPool, fn) ;
            if (r -> Config.bDebug & dbgObjectSearch)
                lprintf (r -> pApp,  "[%d]Search: found %s\n", r -> pThread -> nPid, absfn) ; 
            return absfn ;
            }
        }

    if (r -> Config.bDebug & dbgObjectSearch)
        lprintf (r -> pApp,  "[%d]Search: not found %s\n", r -> pThread -> nPid) ; 

    return NULL ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Path str                                                                     */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

char * embperl_PathStr      (/*i/o*/ register req * r,
                            /*in*/  const char *         sFilename)

    {
    epTHX_
    AV *pPathAV = r -> Config.pPathAV ;
    int skip = r -> Component.pPrev?r -> Component.pPrev -> nPathNdx:0 ;
    int i ;
    char * fn ;
    char * pPath = "" ;
    STRLEN l ;

    if (isAbsPath(sFilename) || !pPathAV || AvFILL (pPathAV) < r -> Component.nPathNdx)
        return embperl_File2Abs (r, r -> pPool, sFilename) ;

    while (sFilename[0] == '.' && sFilename[1] == '.' &&  (sFilename[2] == '/' || sFilename[2] == '\\'))
        {
        skip++ ;
        sFilename += 3 ;
        }
    
    for (i = skip ; i <= AvFILL (pPathAV); i++)
	{
        fn = ep_pstrcat(r -> pPool, SvPV(*av_fetch (pPathAV, i, 0), l), PATH_SEPARATOR_STR, sFilename, NULL) ;
        pPath = ep_pstrcat(r -> pPool, pPath, fn, ";", NULL) ;
        }

    return pPath ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Split string into Array                                                      */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


AV * embperl_String2AV (/*in*/ tApp * a, 
                        /*in*/ const char * sData,
                        /*in*/ const char * sSeparator)
                        
    {
    AV * pAV ;
#ifdef PERL_IMPLICIT_CONTEXT
    pTHX ;
    
    if (a)
        aTHX = a -> pPerlTHX ;
    else
        aTHX = PERL_GET_THX ;
#endif

    pAV = newAV () ;


    while (*sData)
        {
        int n = strcspn (sData, sSeparator) ;
        if (n > 0)
            av_push (pAV, newSVpv((char *)sData, n)) ;
        sData += n ;
        if (*sData)
            sData++ ;
        }

    return pAV ;
    }



/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Split string into hash                                                       */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


HV * embperl_String2HV (/*in*/ tApp * a, 
                        /*in*/ const char * sData,
                        /*in*/ char cSeparator,
                        /*in*/ HV *  pHV) 
                        
    {
    char * p ;
    char  q ;
    char * pVal ;
    char * pKeyEnd ;
#ifdef PERL_IMPLICIT_CONTEXT
    pTHX ;
    
    if (a)
        aTHX = a -> pPerlTHX ;
    else
        aTHX = PERL_GET_THX ;
#endif

    if (!pHV)
        pHV = newHV () ;


    while (*sData)
        {
        while (isspace(*sData))
            sData++ ;
        
        if (*sData == '\'' || *sData == '"')
            q = *sData++ ;
        else
            q = cSeparator ;

        p = strchr (sData, '=') ;
        if (!p)
            break ;
        pKeyEnd = p ;    
        while (pKeyEnd > sData && isspace(pKeyEnd[-1]))
            pKeyEnd-- ;
        
        p++ ;
        while (isspace(*p))
            p++ ;

        if (*p == '\'' || *p == '"')
            q = *p++ ;
        
        pVal = p ;
        while (*p && *p != q)
            p++ ;

        hv_store(pHV, sData, pKeyEnd - sData, newSVpv(pVal, p - pVal), 0) ;
        sData = p ;
        if (*sData)
            sData++ ;
        }

    return pHV ;
    }




/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Seach message for id                                                         */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

static char * embperl_GetText1 (/*in*/ tReq *       r, 
                        /*in*/ const char *         sMsgId,
                        /*in*/ AV *                 arr)
                        
    {
    epTHX_
    IV      len ;
    IV      i ;
    SV **   ppSV ;
    STRLEN  l ;

    if (!arr || SvTYPE(arr) != SVt_PVAV)
        return NULL ;

    len = av_len(arr);
    for (i = len; i >= 0; i--) 
 	{
 	SV * * pHVREF = av_fetch(arr, i, 0);
        if (pHVREF && *pHVREF && SvROK (*pHVREF))
            {
            HV * pHV = (HV *)SvRV (*pHVREF) ;
    	    if (SvTYPE (pHV) == SVt_PVCV)
		{
		SV * pSVErr ;
		SV * pRet ;
		int num ;
				
		dSP ;
		PUSHMARK(sp) ;
		XPUSHs (sv_2mortal(newSVpv(sMsgId,0))) ;
		PUTBACK ;
		num = perl_call_sv ((SV *)pHV, G_EVAL) ;
		pSVErr = ERRSV ;
		if (SvTRUE (pSVErr))
	    	    {
	    	    STRLEN l ;
	    	    char * p = SvPV (pSVErr, l) ;
	            if (l > sizeof (r -> errdat1) - 1)
		       	l = sizeof (r -> errdat1) - 1 ;
	            strncpy (r -> errdat1, p, l) ;
	            if (l > 0 && r -> errdat1[l-1] == '\n')
		        l-- ;
	            r -> errdat1[l] = '\0' ;
     
	            LogError (r, rcEvalErr) ;

	            sv_setpv(pSVErr,"");
		    return NULL ;	
	            }
	        else
	            {
	            SPAGAIN ;
	            if (num > 0)
	                pRet = POPs ;
	            PUTBACK ;
	            return num && pRet && SvOK(pRet)?SvPV (pRet, l):NULL ;
	            }    
		}

            if (SvTYPE (pHV) != SVt_PVHV)
                continue ;

            ppSV = hv_fetch(pHV, (char *)sMsgId, strlen (sMsgId), 0) ;  
            if (ppSV != NULL)
	        {
                return SvOK(*ppSV)?SvPV (*ppSV, l):NULL ;
                }
            }
        }
    return NULL ;
    }


const char * embperl_GetText (/*in*/ tReq *       r, 
                        /*in*/ const char * sMsgId)
                        
    {
    epTHX_
    char *  pMsg ;

    if ((pMsg = embperl_GetText1(r, sMsgId, r -> pMessages)))
        return pMsg ;
    
    if ((pMsg = embperl_GetText1(r, sMsgId, r -> pDefaultMessages)))
        return pMsg ;

    return sMsgId ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_OptionListSearch				                    */
/*                                                                          */
/*! 
*   \_en
*   Lookup a number of options from a list and return numeric equivalent
*   @param  pList           Option/Valus pairs
*   @param  bMult           Allow multiple options
*   @param  sCmd            Configurationdirective (for errormessage)
*   @param  sOptions        Option string
*   @param  pnValue         Returns option value
*   @return                 error code
*   
*   \endif                                                                       
*
*   \_de									   
*   Ermittelt aus einer Liste von Optionen das numerische Equivalent
*   @param  pList           Option/Wertepaare
*   @param  bMult           Mehrfachoptionen erlaubt
*   @param  sCmd            Konfigurationsdirektive (für Fehlermeldung)
*   @param  sOptions        Optionszeichenkette
*   @param  pnValue         Liefert den Optionswert zurück
*   @return                 Fehlercode
*   
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */


int embperl_OptionListSearch (/*in*/ tOptionEntry * pList,
                              /*in*/ bool          bMult,
                              /*in*/ const char *  sCmd,
                              /*in*/ const char *  sOptions,
                              /*in*/ int *         pnValue)
    {
    char * sKeyword ;
    char * sOpts = strdup (sOptions) ;
    dTHX ;

    *pnValue = 0 ;
    
    sKeyword = strtok (sOpts, ", \t\n") ;
    while (sKeyword)
        {
        tOptionEntry * pEntry = pList ;
        bool found = 0 ;

        while (pEntry -> sOption)
            {
            if (stricmp (sKeyword, pEntry -> sOption) == 0)
                {
                *pnValue |= pEntry -> nValue ;
                if (!bMult)
                    {
                    if (sOpts)
                        free (sOpts) ;

                    return ok ;
                    }
                found = 1 ;
                }
            }
        if (!found)
            {
            LogErrorParam (NULL, rcUnknownOption, sKeyword, sCmd) ;
            if (sOpts)
                free (sOpts) ;

            return rcUnknownOption ;
            }

        
        }

    
    if (sOpts)
        free (sOpts) ;

    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_CalcExpires 				                            */
/*                                                                          */
/*! 
*   \_en
*   Convert Expires time to HTTP format
*   @param  sTime           Time to convert
*   @param  sResult	    Buffer for result
*   @param  bHTTP           http format
*   @return                 error code
*   
*   \endif                                                                       
*
*   \_de									   
*   Kovertiert Zeitangabe in HTTP Format
*   @param  sTime           Zeit die konvertioert werden soll
*   @param  sResult	    Buffer für resultat
*   @param  bHTTP           http format
*   @return                 Fehlercode
*   
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

/* parts from libareq */

#define Mult_s 1
#define Mult_m 60
#define Mult_h (60*60)
#define Mult_d (60*60*24)
#define Mult_M (60*60*24*30)
#define Mult_y (60*60*24*365)

static int expire_mult(char s)
{
    switch (s) {
    case 's':
	return Mult_s;
    case 'm':
	return Mult_m;
    case 'h':
	return Mult_h;
    case 'd':
	return Mult_d;
    case 'M':
	return Mult_M;
    case 'y':
	return Mult_y;
    default:
	return 1;
    };
}

static time_t expire_calc(const char *time_str)
{
    int is_neg = 0, offset = 0;
    char buf[256];
    int ix = 0;

    if (*time_str == '-') {
	is_neg = 1;
	++time_str;
    }
    else if (*time_str == '+') {
	++time_str;
    }
    else if (!stricmp(time_str, "now")) {
	/*ok*/
    }
    else {
	return 0;
    }

    while (*time_str && isdigit(*time_str)) {
	buf[ix++] = *time_str++;
    }
    buf[ix] = '\0';
    offset = atoi(buf);

    return time(NULL) +
	(expire_mult(*time_str) * (is_neg ? (0 - offset) : offset));
}

static const char ep_month_snames[12][4] =
    {
    "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    };
static const char ep_day_snames[7][4] =
    {
    "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"
    };
        

const char * embperl_CalcExpires(const char *sTime, char * sResult, int bHTTP)
{
    time_t when;
#ifdef WIN32
    struct tm *tms;
#else
    struct tm tms;
#endif
    int sep = bHTTP ? ' ' : '-';
    dTHX ;

    if (!sTime) {
	return NULL;
    }

    when = expire_calc(sTime);

    if (!when) {
	strcpy( sResult, sTime );
	return sResult ;
    }

#ifdef WIN32
    tms = gmtime(&when);
    sprintf(sResult,  "%s, %.2d%c%s%c%.2d %.2d:%.2d:%.2d GMT", 
                      ep_day_snames[tms->tm_wday],
                      tms->tm_mday, sep, ep_month_snames[tms->tm_mon], sep,
                      tms->tm_year + 1900,
                      tms->tm_hour, tms->tm_min, tms->tm_sec);
#else
    gmtime_r(&when, &tms);
    sprintf(sResult,
		       "%s, %.2d%c%s%c%.2d %.2d:%.2d:%.2d GMT",
		       ep_day_snames[tms.tm_wday],
		       tms.tm_mday, sep, ep_month_snames[tms.tm_mon], sep,
		       tms.tm_year + 1900,
		       tms.tm_hour, tms.tm_min, tms.tm_sec);
#endif
    return sResult ;
}



#ifdef WIN32
extern long _timezone;
#else
#if !defined(__BSD_VISIBLE) && !defined(__DARWIN_UNIX03)
extern long timezone;
#endif
#endif


char * embperl_GetDateTime (char * sResult)
{
    time_t when = time(NULL);
    int sep =  ' ' ;
    int tz ;
#ifdef WIN32
    struct tm *tms;
#else
    struct tm tms;
#endif
    dTHX ;

#ifdef WIN32
    tms = localtime(&when);
    sprintf(sResult,  "%s, %.2d%c%s%c%.2d %.2d:%.2d:%.2d %s%04d", 
                      ep_day_snames[tms->tm_wday],
                      tms->tm_mday, sep, ep_month_snames[tms->tm_mon], sep,
                      tms->tm_year + 1900,
                      tms->tm_hour, tms->tm_min, tms->tm_sec, tz > 0?"+":"", tz);
#else
    localtime_r(&when, &tms);
#if !defined(__BSD_VISIBLE) && !defined(__DARWIN_UNIX03)
    tz = -timezone / 36 + (tms.tm_isdst?100:0) ;
#else
    tz = -tms.tm_gmtoff / 36 + (tms.tm_isdst?100:0) ;
#endif
    sprintf(sResult,
		       "%s, %.2d%c%s%c%.2d %.2d:%.2d:%.2d %s%04d",
		       ep_day_snames[tms.tm_wday],
		       tms.tm_mday, sep, ep_month_snames[tms.tm_mon], sep,
		       tms.tm_year + 1900,
		       tms.tm_hour, tms.tm_min, tms.tm_sec, tz > 0?"+":"", tz);
#endif
    return sResult ;
}



/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Memory debugging functions                                                   */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


#ifdef DMALLOC

static int RemoveDMallocMagic (pTHX_ SV * pSV, MAGIC * mg)

    {
    char * s = *((char * *)(mg -> mg_ptr)) ;
    _free_leap(__FILE__, __LINE__, s) ;
    return ok ;
    }

static MGVTBL DMalloc_mvtTab = { NULL, NULL, NULL, NULL, RemoveDMallocMagic } ;

#define MGTTYPE '!'

SV * AddDMallocMagic (/*in*/ SV *	pSV,
		      /*in*/ char *     sText,
		      /*in*/ char *     sFile,
		      /*in*/ int        nLine) 

    {
    dTHX ;

    if (pSV && (!SvMAGICAL(pSV) || !mg_find (pSV, MGTTYPE)))
	{
	char * s = _strdup_leap(sFile, nLine, sText) ;
	struct magic * pMagic ;
    
	if ((!SvMAGICAL(pSV) || !(pMagic = mg_find (pSV, MGTTYPE))))
	    {
	    sv_magicext ((SV *)pSV, NULL, MGTTYPE, &DMalloc_mvtTab, (char *)&s, sizeof (s)) ;
	    /* sv_magic ((SV *)pSV, NULL, MGTTYPE, (char *)&s, sizeof (s)) ; */
	    pMagic = mg_find (pSV, MGTTYPE) ;
	    }

	if (pMagic)
	    {
	    /* pMagic -> mg_virtual = &DMalloc_mvtTab ; */
	    }
	else
	    {
	    LogError (CurrReq, rcMagicError) ;
	    }
	}

    return pSV ;
    }


#endif

