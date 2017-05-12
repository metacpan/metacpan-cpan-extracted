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
#   $Id: eputil.c,v 1.26 2001/09/01 21:31:10 richter Exp $
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

    if (r -> pCurrEscape == NULL)
        {
        oputs (r, sData) ;
        return ;
        }

    
    while (*sData)
        {
        if (*sData == '\\' && (r -> nCurrEscMode & escEscape) == 0)
            {
            if (p != sData)
                owrite (r, p, sData - p) ;
            sData++ ;
            p = sData ;
            }
        else
            {
            pHtml = r -> pCurrEscape[(unsigned char)(*sData)].sHtml ;
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
    char * pHtml  ;
    const char * p ;
    int	         l ;
    SV *         pSV = newSVpv("",0) ;

    EPENTRY (Escape) ;


    if (nEscMode >= 0)
	{	    
	if (nEscMode & escHtml && !r -> bEscInUrl)
	    pEscTab = Char2Html ;
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


char * sstrdup (/*in*/ char *   pString)

    {
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
    int  bInUrl = r -> bEscInUrl ;

    EPENTRY (TransHtml) ;
	
    if (r -> bOptions & optRawInput)
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
        
#ifdef EP2
    if (bInUrl == 16)
	{ 
	/* Just remove \ for rtf */
	if (nLen == 0)
	    nLen = strlen (sData) ;
	e = sData + nLen ;
	while (p < e)
	    {
	    if (*p == '\\' && p[1] != '\0')
	    	*p++ = ' ' ;
	    p++ ;
	    }	
	return nLen ; 	
        }
#endif

    s = NULL ;
    if (nLen == 0)
        nLen = strlen (sData) ;
    e = sData + nLen ;

    while (p < e)
	{
	if (*p == '\\')
	    {
        
	    if (p[1] == '<')
		{ /*  Quote next HTML tag */
		memmove (p, p + 1, e - p - 1) ;
		e[-1] = ' ' ;
		p++ ;
		while (p < e && *p != '>')
		    p++ ;
		}
	    else if (p[1] == '&')
		{ /*  Quote next HTML char */
		memmove (p, p + 1, e - p - 1) ;
		e[-1] = ' ' ;
		p++ ;
		while (p < e && *p != ';')
		    p++ ;
		}
	    else if (bInUrl && p[1] == '%')
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
	    if (p[0] == '<' && (isalpha (p[1]) || p[1] == '/'))
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
	    else if (p[0] == '&')
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
	    else if (bInUrl && p[0] == '%' && isdigit (p[1]) && isxdigit (p[2]))
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
            if (*pLen > 0)
                return pVal ;
            else
                return pTag ;

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


char * GetHashValueLen (/*in*/  HV *           pHash,
                        /*in*/  const char *   sKey,
                        /*in*/  int            nLen,
                        /*in*/  int            nMaxLen,
                        /*out*/ char *         sValue)

    {
    SV **   ppSV ;
    char *  p ;
    STRLEN  len ;        

    /*EPENTRY (GetHashValueLen) ;*/

    ppSV = hv_fetch(pHash, (char *)sKey, nLen, 0) ;  
    if (ppSV != NULL)
        {
        p = SvPV (*ppSV ,len) ;
        if (len >= nMaxLen)
            len = nMaxLen - 1 ;        
        strncpy (sValue, p, len) ;
        }
    else
        len = 0 ;

    sValue[len] = '\0' ;
        
    return sValue ;
    }


char * GetHashValue (/*in*/  HV *           pHash,
                     /*in*/  const char *   sKey,
                     /*in*/  int            nMaxLen,
                     /*out*/ char *         sValue)
    {
    return GetHashValueLen (pHash, sKey, strlen (sKey), nMaxLen, sValue) ;
    }




IV    GetHashValueInt (/*in*/  HV *           pHash,
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


char * GetHashValueStr (/*in*/  HV *           pHash,
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

char * GetHashValueStrDup (/*in*/  HV *           pHash,
                           /*in*/  const char *   sKey,
                           /*in*/  char *         sDefault)
    {
    SV **   ppSV ;
    STRLEN  l ;
    char *  s ;

    ppSV = hv_fetch(pHash, (char *)sKey, strlen (sKey), 0) ;  
    if (ppSV != NULL)
        {
	if (s = SvPV (*ppSV, l))
	    return strdup (s);
	else
	    return NULL ;
	}

    if (sDefault)
        return strdup (sDefault) ;
    else
	return NULL ;
    }


void SetHashValueStr   (/*in*/  HV *           pHash,
                        /*in*/  const char *   sKey,
                        /*in*/  char *         sValue)

    {
    SV *   pSV = newSVpv (sValue, 0) ;

    /*EPENTRY (GetHashValueInt) ;*/

    hv_store(pHash, (char *)sKey, strlen (sKey), pSV, 0) ;  
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
               /*in*/  char * pPos)

    {

    
    if (r -> Buf.pSourcelinePos == NULL)
	if (r -> Buf.pFile == NULL)
	    return 0 ;
	else
	    return r -> Buf.nSourceline = r -> Buf.pFile -> nFirstLine ;

    if (r -> Buf.pLineNoCurrPos)
        pPos = r -> Buf.pLineNoCurrPos ;

    if (pPos == NULL || pPos == r -> Buf.pSourcelinePos || pPos < r -> Buf.pBuf || pPos > r -> Buf.pEndPos)
        return r -> Buf.nSourceline ;


    if (pPos > r -> Buf.pSourcelinePos)
        {
        char * p = r -> Buf.pSourcelinePos ;

        while (p < pPos && p < r -> Buf.pEndPos)
            {
            if (*p++ == '\n')
                r -> Buf.nSourceline++ ;
            }
        }
    else
        {
        char * p = r -> Buf.pSourcelinePos ;

        while (p > pPos && p > r -> Buf.pBuf)
            {
            if (*--p == '\n')
                r -> Buf.nSourceline-- ;
            }
        }

    r -> Buf.pSourcelinePos = pPos ;
    return r -> Buf.nSourceline ;
    }


int GetLineNo (/*i/o*/ register req * r)

    {
    char * pPos = r -> Buf.pCurrPos ;
    
    return GetLineNoOf (r, pPos) ;
    }


/* ------------------------------------------------------------------------- */
/*                                                                           */
/* Dirname								     */
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



/* ------------------------------------------------------------------------- */
/*                                                                           */
/* GetSubTextPos						             */
/*                                                                           */
/*                                                                           */
/* in	sName = name of sub                                                  */
/*                                                                           */
/* returns the position within the file for a given Embperl sub              */
/*                                                                           */
/* ------------------------------------------------------------------------- */


int GetSubTextPos (/*i/o*/ register req * r,
		   /*in*/  const char *   sName) 

    {
    SV **   ppSV ;
    const char *  sKey  ;
    char    sKeyBuf[sizeof (int) + 4] ;
    int	    l ;    
    
    EPENTRY (Eval) ;

    while (isspace(*sName))
	sName++ ;

    l = strlen (sName) ;
    while (l > 0 && isspace(sName[l-1]))
	l-- ;
    
    sKey = sName ;
    if (l < sizeof (int))
	{ /* right pad name with spaces to make sure name is longer then sizeof (int) */
	  /* distiguish it from filepos entrys */
	memset (sKeyBuf, ' ', sizeof (sKeyBuf) - 1) ;
	sKeyBuf[sizeof(sKeyBuf) - 1] = '\0' ;
	memcpy (sKeyBuf, sName, l) ;
	sKey = sKeyBuf ;
	l = sizeof(sKeyBuf) - 1 ;
	}
    
    
    ppSV = hv_fetch(r -> Buf.pFile -> pCacheHash, (char *)sKey, l, 0) ;  
    if (ppSV == NULL || *ppSV == NULL) /* || SvTYPE (*ppSV) != SVt_IV)*/
        return 0 ;

    return SvIV (*ppSV) ;    
    }


/* ------------------------------------------------------------------------- */
/*                                                                           */
/* SetSubTextPos						             */
/*                                                                           */
/*                                                                            */
/* in	sName = name of sub                                                  */
/* in   nPos  = position within the file for a given Embperl sub             */
/*                                                                           */
/* ------------------------------------------------------------------------- */


int SetSubTextPos (/*i/o*/ register req * r,
		   /*in*/  const char *   sName,
		   /*in*/  int		  nPos) 

    {
    SV **   ppSV ;
    const char *  sKey ;
    char    sKeyBuf[sizeof (int) + 4] ;
    int	    l ;    
    
    EPENTRY (Eval) ;

    while (isspace(*sName))
	sName++ ;

    l = strlen (sName) ;
    while (l > 0 && isspace(sName[l-1]))
	l-- ;
    
    sKey = sName ;
    if (l < sizeof (int))
	{ /* right pad name with spaces to make sure name is longer then sizeof (int) */
	  /* distiguish it from filepos entrys */
	memset (sKeyBuf, ' ', sizeof (sKeyBuf) - 1) ;
	sKeyBuf[sizeof(sKeyBuf) - 1] = '\0' ;
	memcpy (sKeyBuf, sName, l) ;
	sKey = sKeyBuf ;
	l = sizeof(sKeyBuf) - 1 ;
	}
    
    
    ppSV = hv_fetch(r -> Buf.pFile -> pCacheHash, (char *)sKey, l, 1) ;  
    if (ppSV == NULL)
        return rcHashError ;

    SvREFCNT_dec (*ppSV) ;  
    *ppSV = newSViv (nPos) ;
    
    return ok ;
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
    dTHXsem 
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
    GV *	pFileGV ;
    char *      sObjName ;
    /*
    GV *	symtabgv ;
    GV *	symtabfilegv ;
    */

    dTHR;

    if ((symtab = gv_stashpv ((char *)sPackage, 0)) == NULL)
	return ;

    ppSV = hv_fetch (symtab, EPMAINSUB, sizeof (EPMAINSUB) - 1, 0) ;
    if (!ppSV || !*ppSV)
	{
	if (bDebug)
	    lprintf (r, "[%d]CUP: No Perl code in %s\n", r -> nPid, sPackage) ;
	return ;
	}

    /*
    symtabgv = (GV *)*ppSV ;
    symtabfilegv = (GV *)GvFILEGV (symtabgv) ;
    */

    pSV = newSVpvf ("%s::CLEANUP", sPackage) ;
    s   = SvPV (pSV, l) ;
    pCV = perl_get_cv (s, 0) ;
    if (pCV)
	{
	if (bDebug)
	    lprintf (r, "[%d]CUP: Call &%s::CLEANUP\n", r -> nPid, sPackage) ;
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
	    if (bDebug)
	        lprintf (r, "[%d]CUP: Ignore %s because it's no gv\n", r -> nPid, key) ;
	    
	    continue;
	    }

	s = GvNAME((GV *)val) ;
	l = strlen (s) ;

	ppSV = hv_fetch (pCleanupHV, s, l, 0) ;

	if (ppSV && *ppSV && SvIV (*ppSV) == 0)
	    {
	    if (bDebug)
	        lprintf (r, "[%d]CUP: Ignore %s because it's in %%CLEANUP\n", r -> nPid, s) ;
	    continue ;
	    }

	
	if (!(ppSV && *ppSV && SvTRUE (*ppSV)))
	    {
	    if(GvIMPORTED((GV*)val))
		{
		if (bDebug)
		    lprintf (r, "[%d]CUP: Ignore %s because it's imported\n", r -> nPid, s) ;
		continue ;
		}
	    
	    if (s[0] == ':' && s[1] == ':')
		{
		if (bDebug)
		    lprintf (r, "[%d]CUP: Ignore %s because it's special\n", r -> nPid, s) ;
		continue ;
		}
	    
	    /*
	    pFileGV = GvFILEGV ((GV *)val) ;
	    if (pFileGV != symtabfilegv)
		{
		if (bDebug)
		    lprintf (r, "[%d]CUP: Ignore %s because it's defined in another source file (%s)\n", r -> nPid, s, GvFILE((GV *)val)) ;
		continue ;
		}
	    */
	    }
	
	sObjName = NULL ;
	
        /* lprintf (r, "[%d]CUP: type = %d flags=%x\n", r -> nPid, SvTYPE (GvSV((GV*)val)), SvFLAGS (GvSV((GV*)val))) ; */
        if((sv = GvSV((GV*)val)) && SvTYPE (sv) == SVt_PVMG)
	    {
            HV * pStash = SvSTASH (sv) ;

            if (pStash)
                {
                sObjName = HvNAME(pStash) ;
                if (sObjName && strcmp (sObjName, "DBIx::Recordset") == 0)
                    {
                    SV * pSV = newSVpvf ("DBIx::Recordset::Undef ('%s')", s) ;

	            if (bDebug)
	                lprintf (r, "[%d]CUP: Recordset *%s\n", r -> nPid, s) ;
                    EvalDirect (r, pSV, 0, NULL) ;
                    SvREFCNT_dec (pSV) ;
                    }
                }
            }

        if((sv = GvSV((GV*)val)) && SvROK (sv) && SvOBJECT (SvRV(sv)))
	    {
            HV * pStash = SvSTASH (SvRV(sv)) ;
	    /* lprintf (r, "[%d]CUP: rv type = %d\n", r -> nPid, SvTYPE (SvRV(GvSV((GV*)val)))) ; */
            if (pStash)
                {
                sObjName = HvNAME(pStash) ;
                if (sObjName && strcmp (sObjName, "DBIx::Recordset") == 0)
                    {
                    SV * pSV = newSVpvf ("DBIx::Recordset::Undef ('%s')", s) ;

	            if (bDebug)
	                lprintf (r, "[%d]CUP: Recordset *%s\n", r -> nPid, s) ;
                    EvalDirect (r, pSV, 0, NULL) ;
                    SvREFCNT_dec (pSV) ;
                    }
                }
            }
	if((sv = GvSV((GV*)val)) && (SvOK (sv) || SvROK (sv)))
	    {
	    if (bDebug)
                lprintf (r, "[%d]CUP: $%s = %s %s%s\n", r -> nPid, s, SvPV (sv, l), sObjName?" Object of ":"", sObjName?sObjName:"") ;
	
	    if ((sv = GvSV((GV*)val)) && SvREADONLY (sv))
	        {
	        if (bDebug)
	            lprintf (r, "[%d]CUP: Ignore %s because it's readonly\n", r -> nPid, s) ;
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
	        lprintf (r, "[%d]CUP: %%%s = ...\n", r -> nPid, s) ;
            sv_unmagic ((SV *)hv, 'P') ; /* untie */
	    hv_clear(hv);
	    }
	if((av = GvAV((GV*)val)))
	    {
	    if (bDebug)
	        lprintf (r, "[%d]CUP: @%s = ...\n", r -> nPid, s) ;
	    sv_unmagic ((SV *)av, 'P') ; /* untie */
	    av_clear(av);
	    }
	if((io = GvIO((GV*)val)))
	    {
	    if (bDebug)
	        lprintf (r, "[%d]CUP: IO %s = ...\n", r -> nPid, s) ;
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

    strcpy (sFullname, sPackage) ; 
    strcat (sFullname, "::") ; 
    strcat (sFullname, sName) ; 

    if (!(pCV = perl_get_cv (sFullname, FALSE)))
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
    SV **   ppSVID ;
    SV *    pSVID = NULL ;
    MAGIC * pMG ;
    char *  pUID = "" ;
    STRLEN  ulen = 0 ;
    STRLEN  ilen = 0 ;

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