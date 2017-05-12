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
#   $Id: eplibxslt.c 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################*/


#include "../ep.h"
#include "../epmacro.h"

#include <libxml/xmlmemory.h>
#include <libxml/debugXML.h>
#include <libxml/HTMLtree.h>
#include <libxml/xmlIO.h>
#include <libxml/DOCBparser.h>
#include <libxml/xinclude.h>
#include <libxml/catalog.h>
#include <libxslt/xsltconfig.h>
#include <libxslt/xslt.h>
#include <libxslt/xsltInternals.h>
#include <libxslt/transform.h>
#include <libxslt/xsltutils.h>
#include <libxslt/imports.h>

#ifdef WIN32
extern __declspec( dllimport ) int xmlLoadExtDtdDefaultValue;
#else
extern int xmlLoadExtDtdDefaultValue;
#endif

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* iowrite                                                                  */
/*                                                                          */
/* output callback                                                          */
/*                                                                          */
/* ------------------------------------------------------------------------ */

static int  iowrite   (void *context,
                const char *buffer,
                int len)

    {
    return owrite ((tReq *)context, buffer, len) ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_LibXSLT_Text2Text                                                */
/*                                                                          */
/* Do an XSL transformation using LibXSLT. Input and Output is Text.        */
/* The stylesheet is directly read from disk                                */
/*                                                                          */
/* in   pReqParameter   Parameter for request                               */
/*          xsltparameter   Hash which is passed as parameters to libxslt   */
/*          xsltstylesheet  filename of stylsheet                           */
/*      pSource         XML source in memory                                */
/*                                                                          */
/* ------------------------------------------------------------------------ */



int embperl_LibXSLT_Text2Text   (/*in*/  tReq *	  r,
                                 /*in*/  HV *     pReqParameter,
                                 /*in*/  SV *     pSource)

    {
    epTHX_
    xsltStylesheetPtr cur = NULL;
    xmlDocPtr	    doc ;
    xmlDocPtr	    res;
    HE *	    pEntry ;
    HV *            pParam ;
    SV * *          ppSV ;
    char *	    pKey ;
    SV *            pValue ;
    STRLEN          len ;
    I32             l ;
    int		    n ;
    const char * *  pParamArray ;
    const char *    sStylesheet ;
    char *          p ;
    xmlOutputBufferPtr obuf ;

    sStylesheet = GetHashValueStr (aTHX_ pReqParameter, "xsltstylesheet", r -> Component.Config.sXsltstylesheet) ;
    if (!sStylesheet)
	{
	strncpy (r -> errdat1, "XSLT", sizeof (r -> errdat1)) ;
	strncpy (r -> errdat2, "No stylesheet given", sizeof (r -> errdat2)) ;
	return 9999 ;
	}

    ppSV = hv_fetch (pReqParameter, "xsltparameter", sizeof("xsltparameter") - 1, 0) ;
    if (ppSV && *ppSV)
	{
	if (!SvROK (*ppSV) || SvTYPE ((SV *)(pParam = (HV *)SvRV (*ppSV))) != SVt_PVHV)
	    {
	    strncpy (r -> errdat1, "XSLT", sizeof (r -> errdat1)) ;
	    sprintf (r -> errdat2, "%s", "xsltparameter") ;
	    return rcNotHashRef ;
	    }

	n = 0 ;
	hv_iterinit (pParam) ;
	while ((pEntry = hv_iternext (pParam)))
	    {
	    n++ ;
	    }
        
	if (!(pParamArray = _malloc(r, sizeof (const char *) * (n + 1) * 2)))
	    return rcOutOfMemory ;

	n = 0 ;
	hv_iterinit (pParam) ;
	while ((pEntry = hv_iternext (pParam)))
	    {
	    pKey     = hv_iterkey (pEntry, &l) ;
	    pValue   = hv_iterval (pParam, pEntry) ;
	    pParamArray[n++] = pKey ;
	    pParamArray[n++] = SvPV (pValue, len) ;
	    }
	pParamArray[n++] = NULL ;
	}
    else
	{
	pParamArray = NULL ;
	}

    xmlSubstituteEntitiesDefault(1);
    xmlLoadExtDtdDefaultValue = 1;
    /* xmlSetGenericErrorFunc (stderr, NULL) ; */
    
    cur = xsltParseStylesheetFile((const xmlChar *)sStylesheet);
    p   = SvPV (pSource, len) ;
    doc = xmlParseMemory(p, len);
    res = xsltApplyStylesheet(cur, doc, pParamArray);

    
    obuf = xmlOutputBufferCreateIO (iowrite, NULL, r, NULL) ;
    
    xsltSaveResultTo(obuf, res, cur);

    xsltFreeStylesheet(cur);
    xmlFreeDoc(res);
    xmlFreeDoc(doc);

    xsltCleanupGlobals();
    xmlCleanupParser();

    return(0);
    }




/*! Provider that reads compiles LibXSLT stylesheet */

typedef struct tProviderLibXSLTXSL
    {
    tProvider           Provider ;
    } tProviderLibXSLTXSL ;


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderLibXSLTXSL_New      					            */
/*                                                                          */
/*! 
*   \_en
*   Creates a new LibXSLT stylesheet provider and fills it with data from the hash pParam
*   The resulting provider is put into the cache structure
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem which holds the output of the provider
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash of this Providers
*                               stylesheet  filename or provider for the
*                                           stylesheet 
*   @param  pParam          All Parameters 
*   @param  nParamIndex       If pParam is an AV, this parameter gives the index into the Array
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Erzeugt einen neue Provider für LibXSLT Stylesheets. Der ein Zeiger
*   auf den resultierenden Provider wird in die Cachestrutr eingefügt
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem welches die Ausgabe des Providers 
*                           speichert
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash dieses Providers
*                               stylesheet  dateiname oder provider für das
*                                           stylesheet 
*   @param  pParam          Parameter insgesamt
*   @param  nParamIndex       Wenn pParam ein AV ist, gibt dieser Parameter den Index an
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

static int ProviderLibXSLTXSL_New (/*in*/ req *              r,
                          /*in*/ tCacheItem *       pItem,
                          /*in*/ tProviderClass *   pProviderClass,
                             /*in*/ HV *               pProviderParam,
                             /*in*/ SV *               pParam,
                             /*in*/ IV                 nParamIndex)


    {
    int                 rc ;
    
    if ((rc = Provider_NewDependOne (r, sizeof(tProviderLibXSLTXSL), "stylesheet", pItem, pProviderClass, pProviderParam, pParam, nParamIndex)) != ok)
        return rc ;

    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderLibXSLTXSL_ErrorFunc					            */
/*                                                                          */
/*! 
*   \_en
*   Callback which is called when an error occurs
*   \endif                                                                       
*
*   \_de									   
*   Callback das im Fehlerfall aufgerufen wird
*   \endif                                                                       
*/

static void ProviderLibXSLT_ErrorFunc      (void *ctx, const char *msg, ...)

    {
    tReq * r ;
    SV * pSV  ;
    STRLEN l ;
    va_list args ;
    dTHX ;

    r = CurrReq ; /* we cannot use ctx to pass the request, because it's not thread safe */
    
    pSV = newSV (256) ;

    va_start(args, msg) ;
    sv_vsetpvfn(pSV, msg, strlen(msg), &args, Null(SV**), 0, Null(bool*)) ;
    va_end(args) ;
    
    if (!r)
        PerlIO_puts (PerlIO_stderr(), SvPV(pSV, l)) ;
    else
        {
        char * p = SvPV(pSV, l) ;
        if (l && p[l-1] == '\n')
            p[l-1] = '\0' ;
        
        strncpy (r -> errdat1, p, sizeof (r -> errdat1) - 1) ;
        LogError (r, rcLibXSLTError) ;
        }

    SvREFCNT_dec(pSV) ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderLibXSLT_ExternalEnityLoader          		            */
/*                                                                          */
/*! 
*   \_en
*   Callback which is called when to load an external entity. It does
*   an EMbperl path search before calling libxmls function to do the work.
*   \endif                                                                       
*
*   \_de									   
*   Callback das aufgerufen wird um externe Entities zu laden. Es wird eine
*   Suche im Embperl Pfad ausgeführt um danach libxml das eigentliche 
*   Laden zu überlassen.
*   \endif                                                                       
*/


static xmlExternalEntityLoader pCurrentExternalEntityLoader ;

static
xmlParserInputPtr
ProviderLibXSLT_ExternalEnityLoader(const char *URL, const char *ID,
                               xmlParserCtxtPtr ctxt) 
    {
    tReq * r ;
    char * sFile ;
    dTHX ;

    r = CurrReq ;
    sFile = embperl_PathSearch (r, r -> pPool, URL, r -> Component.nPathNdx) ;
    if (sFile && pCurrentExternalEntityLoader)
        return (*pCurrentExternalEntityLoader)(sFile, ID, ctxt) ;
    else
        {
        strncpy (r -> errdat1, URL, sizeof(r -> errdat1) - 1) ;
        LogError (r, rcNotFound) ;
        return NULL ;
        }
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderLibXSLTXSL_AppendKey    					            */
/*                                                                          */
/*! 
*   \_en
*   Append it's key to the keystring. If it depends on anything it must 
*   call Cache_AppendKey for any dependency.
*   
*   @param  r               Embperl request record
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash of this Providers
*                               stylesheet  filename or provider for the
*                                           stylesheet 
*   @param  pParam          All Parameters 
*   @param  nParamIndex       If pParam is an AV, this parameter gives the index into the Array
*   @param  pKey            Key to which string should be appended
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Hängt ein eigenen Schlüssel an den Schlüsselstring an. Wenn irgednwelche
*   Abhänigkeiten bestehen, muß Cache_AppendKey für alle Abhänigkeiten aufgerufen 
*   werden.
*   
*   @param  r               Embperl request record
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash dieses Providers
*                               stylesheet  dateiname oder provider für das
*                                           stylesheet 
*   @param  pParam          Parameter insgesamt
*   @param  nParamIndex       Wenn pParam ein AV ist, gibt dieser Parameter den Index an
*   @param  pKey            Schlüssel zu welchem hinzugefügt wird
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

static int ProviderLibXSLTXSL_AppendKey (/*in*/ req *              r,
                                   /*in*/ tProviderClass *   pProviderClass,
                                      /*in*/ HV *               pProviderParam,
                                      /*in*/ SV *               pParam,
                                      /*in*/ IV                 nParamIndex,
                                   /*i/o*/ SV *              pKey)
    {
    epTHX_
    int          rc ;

    if ((rc = Cache_AppendKey (r, pProviderParam, "stylesheet", pParam, nParamIndex, pKey)) != ok)
        return rc;

    sv_catpv (pKey, "*libxslt-compile-xsl") ;
    return ok ;
    }



/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderLibXSLTXSL_GetContentPtr  				            */
/*                                                                          */
/*! 
*   \_en
*   Get the whole content from the provider. 
*   This gets the stylesheet and compiles it
*   
*   @param  r               Embperl request record
*   @param  pProvider       The provider record
*   @param  pData           Returns the content
*   @param  bUseCache       Set if the content should not recomputed
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Holt den gesamt Inhalt vom Provider.
*   Die Funktion holt sich das Stylesheet und kompiliert es
*   
*   @param  r               Embperl request record
*   @param  pProvider       The provider record
*   @param  pData           Liefert den Inhalt
*   @param  bUseCache       Gesetzt wenn der Inhalt nicht neu berechnet werden soll
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



static int ProviderLibXSLTXSL_GetContentPtr     (/*in*/ req *            r,
                                        /*in*/ tProvider *      pProvider,
                                        /*in*/ void * *         pData,
                                        /*in*/ bool             bUseCache)

    {
    epTHX_
    int    rc ;
    char * p ;
    STRLEN len ;
    SV *   pSource ;
    xsltStylesheetPtr cur ;
    xmlDocPtr	    doc ;
    xmlExternalEntityLoader pLoader ;


    tCacheItem * pFileCache = Cache_GetDependency(r, pProvider -> pCache, 0) ;
    if ((rc = Cache_GetContentSV (r, pFileCache, &pSource, bUseCache)) != ok)
        return rc ;
        
    if (!bUseCache)
        {
        p   = SvPV (pSource, len) ;

        if (p == NULL || len == 0)
	    {
	    strncpy (r -> errdat1, "LibXSLT XML stylesheet", sizeof (r -> errdat1)) ;
	    return rcMissingInput ;
	    }

        r -> Component.pCurrPos = NULL ;
        r -> Component.nSourceline = 1 ;
        r -> Component.pSourcelinePos = NULL ;    
        r -> Component.pLineNoCurrPos = NULL ;    

        xmlSubstituteEntitiesDefault(1);
        xmlLoadExtDtdDefaultValue = 1;
        xmlSetGenericErrorFunc (NULL, &ProviderLibXSLT_ErrorFunc) ;
        pLoader = xmlGetExternalEntityLoader () ;
        if (pLoader != &ProviderLibXSLT_ExternalEnityLoader)
            pCurrentExternalEntityLoader = pLoader ;
        xmlSetExternalEntityLoader (&ProviderLibXSLT_ExternalEnityLoader) ;
        
        if ((doc = xmlParseMemory(p, len)) == NULL)
      	    {
	    Cache_ReleaseContent (r, pFileCache) ;
            strncpy (r -> errdat1, "XSL parse", sizeof (r -> errdat1)) ;
	    return rcLibXSLTError ;
	    }
        ;
	    
        if ((cur = xsltParseStylesheetDoc(doc)) == NULL)
      	    {
            xmlFreeDoc(doc) ;
	    Cache_ReleaseContent (r, pFileCache) ;
            strncpy (r -> errdat1, "XSL compile", sizeof (r -> errdat1)) ;
	    return rcLibXSLTError ;
	    }
    
        *pData = (void *)cur ;
        }

    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderLibXSLTXSL_FreeContent 		                            */
/*                                                                          */
/*! 
*   \_en
*   Free the cached data
*   
*   @param  r               Embperl request record
*   @param  pProvider       The provider record
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Gibt die gecachten Daten frei
*   
*   @param  r               Embperl request record
*   @param  pProvider       The provider record
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



static int ProviderLibXSLTXSL_FreeContent(/*in*/ req *             r,
                                 /*in*/ tCacheItem * pItem)

    {
    xsltStylesheetPtr  pCompiledStylesheet ;
    
    pCompiledStylesheet = (xsltStylesheetPtr)pItem -> pData ;
    if (pCompiledStylesheet)
        xsltFreeStylesheet(pCompiledStylesheet) ;


    return ok ;
    }

/* ------------------------------------------------------------------------ */

static tProviderClass ProviderClassLibXSLTXSL = 
    {   
    "text/*", 
    &ProviderLibXSLTXSL_New, 
    &ProviderLibXSLTXSL_AppendKey, 
    NULL,
    NULL,
    &ProviderLibXSLTXSL_GetContentPtr,
    NULL,
    &ProviderLibXSLTXSL_FreeContent,
    NULL,
    } ;



/*! Provider that reads compiles LibXSLT xml source */

typedef struct tProviderLibXSLTXML
    {
    tProvider           Provider ;
    } tProviderLibXSLTXML ;


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderLibXSLTXML_New      					            */
/*                                                                          */
/*! 
*   \_en
*   Creates a new LibXSLT xml source provider and fills it with data from the hash pParam
*   The resulting provider is put into the cache structure
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem which holds the output of the provider
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash of this Providers
*   @param  pParam          All Parameters 
*   @param  nParamIndex       If pParam is an AV, this parameter gives the index into the Array
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Erzeugt einen neue Provider für LibXSLT XML Quellen. Der ein Zeiger
*   auf den resultierenden Provider wird in die Cachestrutr eingefügt
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem welches die Ausgabe des Providers 
*                           speichert
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash dieses Providers
*   @param  pParam          Parameter insgesamt
*   @param  nParamIndex       Wenn pParam ein AV ist, gibt dieser Parameter den Index an
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

static int ProviderLibXSLTXML_New (/*in*/ req *              r,
                          /*in*/ tCacheItem *       pItem,
                          /*in*/ tProviderClass *   pProviderClass,
                             /*in*/ HV *               pProviderParam,
                             /*in*/ SV *               pParam,
                             /*in*/ IV                 nParamIndex)


    {
    int                 rc ;
    
    if ((rc = Provider_NewDependOne (r, sizeof(tProviderLibXSLTXML), "source", pItem, pProviderClass, pProviderParam, pParam, nParamIndex)) != ok)
        return rc ;

    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderFile_AppendKey    					            */
/*                                                                          */
/*! 
*   \_en
*   Append it's key to the keystring. If it depends on anything it must 
*   call Cache_AppendKey for any dependency.
*   
*   @param  r               Embperl request record
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash of this Providers
*   @param  pParam          All Parameters 
*   @param  nParamIndex       If pParam is an AV, this parameter gives the index into the Array
*   @param  pKey            Key to which string should be appended
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Hängt ein eigenen Schlüssel an den Schlüsselstring an. Wenn irgednwelche
*   Abhänigkeiten bestehen, muß Cache_AppendKey für alle Abhänigkeiten aufgerufen 
*   werden.
*   
*   @param  r               Embperl request record
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash dieses Providers
*   @param  pParam          Parameter insgesamt
*   @param  nParamIndex       Wenn pParam ein AV ist, gibt dieser Parameter den Index an
*   @param  pKey            Schlüssel zu welchem hinzugefügt wird
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

static int ProviderLibXSLTXML_AppendKey (/*in*/ req *              r,
                                   /*in*/ tProviderClass *   pProviderClass,
                                      /*in*/ HV *               pProviderParam,
                                      /*in*/ SV *               pParam,
                                      /*in*/ IV                 nParamIndex,
                                   /*i/o*/ SV *              pKey)
    {
    epTHX_
    int          rc ;

    if ((rc = Cache_AppendKey (r, pProviderParam, "source", pParam, nParamIndex, pKey)) != ok)
        return rc;

    sv_catpv (pKey, "*libxslt-parse-xml") ;
    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderLibXSLTXML_GetContentPtr  				            */
/*                                                                          */
/*! 
*   \_en
*   Get the whole content from the provider. 
*   This gets the stylesheet and compiles it
*   
*   @param  r               Embperl request record
*   @param  pProvider       The provider record
*   @param  pData           Returns the content
*   @param  bUseCache       Set if the content should not recomputed
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Holt den gesamt Inhalt vom Provider.
*   Die Funktion holt sich das Stylesheet und kompiliert es
*   
*   @param  r               Embperl request record
*   @param  pProvider       The provider record
*   @param  pData           Liefert den Inhalt
*   @param  bUseCache       Gesetzt wenn der Inhalt nicht neu berechnet werden soll
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



static int ProviderLibXSLTXML_GetContentPtr     (/*in*/ req *            r,
                                        /*in*/ tProvider *      pProvider,
                                        /*in*/ void * *         pData,
                                            /*in*/ bool                bUseCache)

    {
    epTHX_
    int    rc ;
    char * p ;
    STRLEN len ;
    SV *   pSource ;
    xmlDocPtr	    doc ;
    xmlExternalEntityLoader pLoader ;

    tCacheItem * pFileCache = Cache_GetDependency(r, pProvider -> pCache, 0) ;
    if ((rc = Cache_GetContentSV (r, pFileCache, &pSource, bUseCache)) != ok)
        return rc ;
        
    if (!bUseCache)
        {
        p   = SvPV (pSource, len) ;

        if (p == NULL || len == 0)
	    {
	    strncpy (r -> errdat1, "LibXSLT XML source", sizeof (r -> errdat1)) ;
	    return rcMissingInput ;
	    }

        r -> Component.pCurrPos = NULL ;
        r -> Component.nSourceline = 1 ;
        r -> Component.pSourcelinePos = NULL ;    
        r -> Component.pLineNoCurrPos = NULL ;    

        xmlSubstituteEntitiesDefault(1);
        xmlLoadExtDtdDefaultValue = 1;
        xmlSetGenericErrorFunc (NULL, &ProviderLibXSLT_ErrorFunc) ;
        pLoader = xmlGetExternalEntityLoader () ;
        if (pLoader != &ProviderLibXSLT_ExternalEnityLoader)
            pCurrentExternalEntityLoader = pLoader ;
        xmlSetExternalEntityLoader (&ProviderLibXSLT_ExternalEnityLoader) ;

        if ((doc = xmlParseMemory(p, len)) == NULL)
      	    {
	    Cache_ReleaseContent (r, pFileCache) ;
            strncpy (r -> errdat1, "XML parse", sizeof (r -> errdat1)) ;
	    return rcLibXSLTError ;
	    }

        *pData = (void *)doc ;
        }

    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderLibXSLTXML_FreeContent 		                            */
/*                                                                          */
/*! 
*   \_en
*   Free the cached data
*   
*   @param  r               Embperl request record
*   @param  pProvider       The provider record
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Gibt die gecachten Daten frei
*   
*   @param  r               Embperl request record
*   @param  pProvider       The provider record
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



static int ProviderLibXSLTXML_FreeContent(/*in*/ req *             r,
                                 /*in*/ tCacheItem * pItem)

    {
    if (pItem -> pData)
	{
	xmlFreeDoc((xmlDocPtr)pItem -> pData) ;
	}
    return ok ;
    }

/* ------------------------------------------------------------------------ */

static tProviderClass ProviderClassLibXSLTXML = 
    {   
    "text/*", 
    &ProviderLibXSLTXML_New, 
    &ProviderLibXSLTXML_AppendKey, 
    NULL,
    NULL,
    &ProviderLibXSLTXML_GetContentPtr,
    NULL,
    &ProviderLibXSLTXML_FreeContent,
    NULL,
    } ;




/*! Provider that reads compiles LibXSLT stylesheet */

typedef struct tProviderLibXSLT
    {
    tProvider           Provider ;
    SV *                pOutputSV ;
    const char * *      pParamArray ;
    } tProviderLibXSLT ;

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderLibXSLT_iowrite                                                  */
/*                                                                          */
/* output callback                                                          */
/*                                                                          */
/* ------------------------------------------------------------------------ */

struct iowrite
    {
    tProviderLibXSLT  * pProvider ;
    tReq * pReq ;
    } ;

static  int  ProviderLibXSLT_iowrite   (void *context,
						     const char *buffer,
						     int len)

    {
    tReq * r = ((struct iowrite *)context) -> pReq ;
    epTHX_ 
    
    sv_catpvn (((struct iowrite *)context) -> pProvider -> pOutputSV, (char *)buffer, len) ;
    return len ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderLibXSLT_New      					            */
/*                                                                          */
/*! 
*   \_en
*   Creates a new LibXSLT provider and fills it with data from the hash pParam
*   The resulting provider is put into the cache structure
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem which holds the output of the provider
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash of this Providers
*                               stylesheet  filename or provider for the
*                                           stylesheet 
*   @param  pParam          All Parameters 
*   @param  nParamIndex       If pParam is an AV, this parameter gives the index into the Array
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Erzeugt einen neue Provider für LibXSLT.  Der ein Zeiger
*   auf den resultierenden Provider wird in die Cachestrutr eingefügt
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem welches die Ausgabe des Providers 
*                           speichert
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash dieses Providers
*                               stylesheet  dateiname oder provider für das
*                                           stylesheet 
*   @param  pParam          Parameter insgesamt
*   @param  nParamIndex       Wenn pParam ein AV ist, gibt dieser Parameter den Index an
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

int ProviderLibXSLT_New (/*in*/ req *              r,
                          /*in*/ tCacheItem *       pItem,
                          /*in*/ tProviderClass *   pProviderClass,
                             /*in*/ HV *               pProviderParam,
                             /*in*/ SV *               pParam,
                             /*in*/ IV                 nParamIndex)


    {
    int                 rc ;
    
    if ((rc = Provider_NewDependOne (r, sizeof(tProviderLibXSLT), "source", pItem, pProviderClass, pProviderParam, pParam, nParamIndex)) != ok)
        return rc ;

    if ((rc = Provider_AddDependOne (r, pItem -> pProvider, "stylesheet", pItem, pProviderClass, pProviderParam, NULL, 0)) != ok)
        return rc ;

    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderFile_AppendKey    					            */
/*                                                                          */
/*! 
*   \_en
*   Append it's key to the keystring. If it depends on anything it must 
*   call Cache_AppendKey for any dependency.
*   
*   @param  r               Embperl request record
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash of this Providers
*                               stylesheet  filename or provider for the
*                                           stylesheet 
*   @param  pParam          All Parameters 
*   @param  nParamIndex       If pParam is an AV, this parameter gives the index into the Array
*   @param  pKey            Key to which string should be appended
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Hängt ein eigenen Schlüssel an den Schlüsselstring an. Wenn irgednwelche
*   Abhänigkeiten bestehen, muß Cache_AppendKey für alle Abhänigkeiten aufgerufen 
*   werden.
*   
*   @param  r               Embperl request record
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash dieses Providers
*                               stylesheet  dateiname oder provider für das
*                                           stylesheet 
*   @param  pParam          Parameter insgesamt
*   @param  nParamIndex       Wenn pParam ein AV ist, gibt dieser Parameter den Index an
*   @param  pKey            Schlüssel zu welchem hinzugefügt wird
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

static int ProviderLibXSLT_AppendKey (/*in*/ req *              r,
                                   /*in*/ tProviderClass *   pProviderClass,
                                      /*in*/ HV *               pProviderParam,
                                      /*in*/ SV *               pParam,
                                      /*in*/ IV                 nParamIndex,
                                   /*i/o*/ SV *              pKey)
    {
    epTHX_
    int          rc ;

    if ((rc = Cache_AppendKey (r, pProviderParam, "source", pParam, nParamIndex, pKey)) != ok)
        return rc;

    if ((rc = Cache_AppendKey (r, pProviderParam, "stylesheet", NULL, 0, pKey)) != ok)
        return rc;

    sv_catpv (pKey, "*libxslt") ;
    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderLibXSLT_UpdateParam   				            */
/*                                                                          */
/*! 
*   \_en
*   Update the parameter of the provider
*   
*   @param  r               Embperl request record
*   @param  pProvider       Provider record
*   @param  pParam          Parameter Hash
*                               param        hash with parameter 
*   @param  pKey            Key to which string should be appended
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Aktualisiert die Parameter des Providers
*   
*   @param  r               Embperl request record
*   @param  pProvider       Provider record
*   @param  pParam          Parameter Hash
*                               param        hash mit parametern 
*   @param  pKey            Schlüssel zu welchem hinzugefügt wird
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

static int ProviderLibXSLT_UpdateParam(/*in*/ req *              r,
                                   /*in*/ tProvider *        pProvider,
                                   /*in*/ HV *               pParam)
    {
    epTHX_
    int		    rc ;
    HV *	    pParamHV ;
    HE *	    pEntry ;
    char *	    pKey ;
    SV *            pValue ;
    STRLEN          len ;
    I32		    l ;
    int		    n ;
    const char * *  pParamArray ;
    
    if ((rc = GetHashValueHREF  (r, pParam, "param", &pParamHV)) != ok)
        {
        pParamHV = r -> Component.Param.pXsltParam ;
        }

    if (((tProviderLibXSLT *)pProvider) -> pParamArray)
	{
	free ((void *)(((tProviderLibXSLT *)pProvider) -> pParamArray)) ;
	((tProviderLibXSLT *)pProvider) -> pParamArray = NULL ;
	}

    if (pParamHV)
	{
	n = hv_iterinit (pParamHV) ;
	if (!(pParamArray = malloc(sizeof (const char *) * (n + 1) * 2)))
	    return rcOutOfMemory ;

	n = 0 ;
	while ((pEntry = hv_iternext (pParamHV)))
	    {
	    pKey     = hv_iterkey (pEntry, &l) ;
	    pValue   = hv_iterval (pParamHV, pEntry) ;
	    pParamArray[n++] = pKey ;
	    pParamArray[n++] = SvPV (pValue, len) ;
	    }
	pParamArray[n++] = NULL ;
	((tProviderLibXSLT *)pProvider) -> pParamArray = pParamArray ;
	}
    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderLibXSLT_GetContentSV	  				            */
/*                                                                          */
/*! 
*   \_en
*   Get the whole content from the provider. 
*   This gets the stylesheet and compiles it
*   
*   @param  r               Embperl request record
*   @param  pProvider       The provider record
*   @param  pData           Returns the content
*   @param  bUseCache       Set if the content should not recomputed
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Holt den gesamt Inhalt vom Provider.
*   Die Funktion holt sich das Stylesheet und kompiliert es
*   
*   @param  r               Embperl request record
*   @param  pProvider       The provider record
*   @param  pData           Liefert den Inhalt
*   @param  bUseCache       Gesetzt wenn der Inhalt nicht neu berechnet werden soll
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



static int ProviderLibXSLT_GetContentSV    (/*in*/ req *            r,
                                            /*in*/ tProvider *      pProvider,
                                            /*in*/ SV * *           pData,
                                            /*in*/ bool             bUseCache)

    {
    epTHX_
    int    rc ;
    xsltStylesheetPtr cur ;
    xmlDocPtr	    doc ;
    xmlDocPtr	    res;
    xmlOutputBufferPtr obuf ;
    const xmlChar *encoding;
    struct iowrite iowrite ;
    
    tCacheItem * pSrcCache = Cache_GetDependency(r, pProvider -> pCache, 0) ;
    tCacheItem * pXSLCache = Cache_GetDependency(r, pProvider -> pCache, 1) ;

    if ((rc = Cache_GetContentPtr  (r, pSrcCache, (void * *)&doc, bUseCache)) != ok)
        return rc ;

    if ((rc = Cache_GetContentPtr (r, pXSLCache, (void * *)&cur, bUseCache)) != ok)
        return rc ;

    if (!bUseCache)
        {
        if (((tProviderLibXSLT *)pProvider) -> pOutputSV)
            SvREFCNT_dec (((tProviderLibXSLT *)pProvider) -> pOutputSV) ;

        ((tProviderLibXSLT *)pProvider) -> pOutputSV = newSVpv("", 0) ;

        r -> Component.pCurrPos = NULL ;
        r -> Component.nSourceline = 1 ;
        r -> Component.pSourcelinePos = NULL ;    
        r -> Component.pLineNoCurrPos = NULL ;    

        xmlSubstituteEntitiesDefault(1);
        xmlLoadExtDtdDefaultValue = 1;
        xmlSetGenericErrorFunc (NULL, &ProviderLibXSLT_ErrorFunc) ;

        res = xsltApplyStylesheet(cur, doc, ((tProviderLibXSLT *)pProvider) -> pParamArray);
        if(res == NULL)
	    {
	    strncpy (r -> errdat1, "XSLT", sizeof (r -> errdat1)) ;
	    return rcLibXSLTError ;
	    }
    
        iowrite.pProvider = (tProviderLibXSLT *)pProvider ;
        iowrite.pReq = r ;

        XSLT_GET_IMPORT_PTR(encoding, cur, encoding)
        if (encoding != NULL) 
            {
	    xmlCharEncodingHandlerPtr encoder;

	    encoder = xmlFindCharEncodingHandler((char *)encoding);
	    if ((encoder != NULL) &&
	        (xmlStrEqual((const xmlChar *)encoder->name,
			     (const xmlChar *) "UTF-8")))
	        encoder = NULL;
            obuf = xmlOutputBufferCreateIO (ProviderLibXSLT_iowrite, NULL, &iowrite, encoder) ;
            } 
        else 
            obuf = xmlOutputBufferCreateIO (ProviderLibXSLT_iowrite, NULL, &iowrite, NULL) ;
    
        if(obuf == NULL)
	    {
	    strncpy (r -> errdat1, "Cannot allocate output buffer", sizeof (r -> errdat1)) ;
	    return rcLibXSLTError ;
	    }

        xsltSaveResultTo(obuf, res, cur);

        xmlFreeDoc(res);
        xmlOutputBufferClose (obuf) ;

        *pData = ((tProviderLibXSLT *)pProvider) -> pOutputSV ;
        SvREFCNT_inc(*pData) ;
        }

    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderLibXSLT_FreeContent 		                            */
/*                                                                          */
/*! 
*   \_en
*   Free the cached data
*   
*   @param  r               Embperl request record
*   @param  pProvider       The provider record
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Gibt die gecachten Daten frei
*   
*   @param  r               Embperl request record
*   @param  pProvider       The provider record
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



static int ProviderLibXSLT_FreeContent(/*in*/ req *             r,
                                 /*in*/ tCacheItem * pItem)

    {
    epTHX_
    tProviderLibXSLT * pProvider = ((tProviderLibXSLT *)pItem -> pProvider) ;
    
    if (pProvider -> pOutputSV)
	{
	SvREFCNT_dec (pProvider -> pOutputSV) ;
	pProvider -> pOutputSV = NULL ;
	}
    
    /*
    if (pProvider -> pParamArray)
	{
	free (pProvider -> pParamArray) ;
	pProvider -> pParamArray = NULL ;
	}
    */
    return ok ;
    }

/* ------------------------------------------------------------------------ */

static tProviderClass ProviderClassLibXSLT = 
    {   
    "text/*", 
    &ProviderLibXSLT_New, 
    &ProviderLibXSLT_AppendKey, 
    &ProviderLibXSLT_UpdateParam, 
    &ProviderLibXSLT_GetContentSV,
    NULL,
    NULL,
    &ProviderLibXSLT_FreeContent,
    NULL,
    } ;



/* ------------------------------------------------------------------------ */

int embperl_LibXSLT_Init ()
    {
    Cache_AddProviderClass ("libxslt-compile-xsl", &ProviderClassLibXSLTXSL) ;
    Cache_AddProviderClass ("libxslt-parse-xml", &ProviderClassLibXSLTXML) ;
    Cache_AddProviderClass ("libxslt", &ProviderClassLibXSLT) ;

    return ok ;
    }



