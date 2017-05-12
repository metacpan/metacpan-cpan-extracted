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
#   $Id: epxalan.cpp 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################*/

/* undef some defines that clashs with c++ includes */
#undef bool
#undef HAS_BOOL

extern "C"
{

#include "../ep.h"
#include "../epmacro.h"
}

#undef assert
#undef vform


#include <Include/PlatformDefinitions.hpp>

#if defined(XALAN_OLD_STREAM_HEADERS)
#include <iostream.h>
#include <strstream.h>
#include <fstream.h>
#else
#include <iostream>
#include <strstream>
#include <fstream>
#endif

#include <util/PlatformUtils.hpp>
#include <XalanTransformer/XalanTransformer.hpp>



extern "C"
{

XalanTransformer * theXalanTransformer;

static int bInitDone = 0 ;


/*! Provider that reads compiles xalan stylesheet */

typedef struct tProviderXalanXSL
    {
    tProvider           Provider ;
    } tProviderXalanXSL ;


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderXalanXSL_New      					            */
/*                                                                          */
/*! 
*   \_en
*   Creates a new xalan stylesheet provider and fills it with data from the hash pParam
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
*   Erzeugt einen neue Provider für Xalan Stylesheets. Der ein Zeiger
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

static int ProviderXalanXSL_New (/*in*/ req *              r,
                          /*in*/ tCacheItem *       pItem,
                          /*in*/ tProviderClass *   pProviderClass,
                             /*in*/ HV *               pProviderParam,
                             /*in*/ SV *               pParam,
                             /*in*/ IV                 nParamIndex)


    {
    int                 rc ;
    
    if ((rc = Provider_NewDependOne (r, sizeof(tProviderXalanXSL), "stylesheet", pItem, pProviderClass, pProviderParam, pParam, nParamIndex)) != ok)
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

static int ProviderXalanXSL_AppendKey (/*in*/ req *              r,
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

    sv_catpv (pKey, "*xalan-compile-xsl") ;
    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderXalanXSL_GetContentPtr  				            */
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



static int ProviderXalanXSL_GetContentPtr  (/*in*/ req *            r,
                                            /*in*/ tProvider *      pProvider,
                                            /*in*/ void * *         pData,
                                            /*in*/ bool             bUseCache)

    {
    epTHX_
    int    rc ;
    char * p ;
    STRLEN len ;
    SV *   pSource ;
    const XalanCompiledStylesheet* pCompiledStylesheet = NULL ;

    tCacheItem * pFileCache = Cache_GetDependency(r, pProvider -> pCache, 0) ;

    if ((rc = Cache_GetContentSV (r, pFileCache, &pSource, bUseCache)) != ok)
        return rc ;
        
    if (!bUseCache)
        {
        // Our input streams...
        p   = SvPV (pSource, len) ;

        if (p == NULL || len == 0)
	    {
	    strncpy (r -> errdat1, "Xalan XML stylesheet", sizeof (r -> errdat1)) ;
	    return rcMissingInput ;
	    }
    

        r -> Component.pCurrPos = NULL ;
        r -> Component.nSourceline = 1 ;
        r -> Component.pSourcelinePos = NULL ;    
        r -> Component.pLineNoCurrPos = NULL ;    

        istrstream	theXMLStream(p, len);

        if (theXalanTransformer -> compileStylesheet(&theXMLStream, pCompiledStylesheet))
      	    {
	    Cache_ReleaseContent (r, pFileCache) ;
            strncpy (r -> errdat1, "XSL compile", sizeof (r -> errdat1)) ;
	    strncpy (r -> errdat2, theXalanTransformer -> getLastError(), sizeof (r -> errdat2) - 2) ;
	    return rcXalanError ;
	    }


        *pData = (void *)pCompiledStylesheet ;
        }

    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderXalanXSL_FreeContent 		                            */
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



static int ProviderXalanXSL_FreeContent(/*in*/ req *             r,
                                 /*in*/ tCacheItem * pItem)

    {
    XalanCompiledStylesheet* pCompiledStylesheet = (XalanCompiledStylesheet*)pItem -> pData ;
    if (pCompiledStylesheet)
        theXalanTransformer -> destroyStylesheet (pCompiledStylesheet) ;

    return ok ;
    }

/* ------------------------------------------------------------------------ */

static tProviderClass ProviderClassXalanXSL = 
    {   
    "text/*", 
    &ProviderXalanXSL_New, 
    &ProviderXalanXSL_AppendKey, 
    NULL,
    NULL,
    &ProviderXalanXSL_GetContentPtr,
    NULL,
    &ProviderXalanXSL_FreeContent,
    NULL,
    } ;

/*! Provider that reads compiles xalan stylesheet */

typedef struct tProviderXalanXML
    {
    tProvider           Provider ;
    } tProviderXalanXML ;


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderXalanXML_New      					            */
/*                                                                          */
/*! 
*   \_en
*   Creates a new xalan xml source provider and fills it with data from the hash pParam
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
*   Erzeugt einen neue Provider für Xalan XML Quellen. Der ein Zeiger
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

static int ProviderXalanXML_New (/*in*/ req *              r,
                          /*in*/ tCacheItem *       pItem,
                          /*in*/ tProviderClass *   pProviderClass,
                             /*in*/ HV *               pProviderParam,
                             /*in*/ SV *               pParam,
                             /*in*/ IV                 nParamIndex)


    {
    int                 rc ;
    
    if ((rc = Provider_NewDependOne (r, sizeof(tProviderXalanXML), "source", pItem, pProviderClass, pProviderParam, pParam, nParamIndex)) != ok)
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

static int ProviderXalanXML_AppendKey (/*in*/ req *              r,
                                   /*in*/ tProviderClass *   pProviderClass,
                                      /*in*/ HV *               pProviderParam,
                                      /*in*/ SV *               pParam,
                                      /*in*/ IV                 nParamIndex,
                                   /*i/o*/ SV *              pKey)
    {
    epTHX_
    int          rc ;

    if ((rc = Cache_AppendKey (r,  pProviderParam, "source", pParam, nParamIndex, pKey)) != ok)
        return rc;

    sv_catpv (pKey, "*xalan-parse-xml") ;
    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderXalanXML_GetContentPtr  				            */
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



static int ProviderXalanXML_GetContentPtr  (/*in*/ req *            r,
                                            /*in*/ tProvider *      pProvider,
                                            /*in*/ void * *         pData,
                                            /*in*/ bool             bUseCache)

    {
    epTHX_
    int    rc ;
    char * p ;
    STRLEN len ;
    SV *   pSource ;
    const XalanParsedSource * parsedXML = NULL ;

    tCacheItem * pFileCache = Cache_GetDependency(r, pProvider -> pCache, 0) ;
    if ((rc = Cache_GetContentSV (r, pFileCache, &pSource, bUseCache)) != ok)
        return rc ;
        
    if (!bUseCache)
        {
        // Our input streams...
        p   = SvPV (pSource, len) ;

        if (p == NULL || len == 0)
	    {
	    strncpy (r -> errdat1, "Xalan XML source", sizeof (r -> errdat1)) ;
	    return rcMissingInput ;
	    }
    
        r -> Component.pCurrPos = NULL ;
        r -> Component.nSourceline = 1 ;
        r -> Component.pSourcelinePos = NULL ;    
        r -> Component.pLineNoCurrPos = NULL ;    
    
        istrstream	theXMLStream(p, len);


        if (theXalanTransformer -> parseSource(&theXMLStream, parsedXML))
      	    {
	    Cache_ReleaseContent (r, pFileCache) ;
            strncpy (r -> errdat1, "XSL compile", sizeof (r -> errdat1)) ;
	    strncpy (r -> errdat2, theXalanTransformer -> getLastError(), sizeof (r -> errdat2) - 2) ;
	    return rcXalanError ;
	    }


        *pData = (void *)parsedXML ;
        }

    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderXalanXML_FreeContent 		                            */
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



static int ProviderXalanXML_FreeContent(/*in*/ req *             r,
                                 /*in*/ tCacheItem * pItem)

    {
    const XalanParsedSource * parsedXML  = (XalanParsedSource *)pItem -> pData ;
    if (parsedXML)
	theXalanTransformer -> destroyParsedSource (parsedXML);

    return ok ;
    }

/* ------------------------------------------------------------------------ */

static tProviderClass ProviderClassXalanXML = 
    {   
    "text/*", 
    &ProviderXalanXML_New, 
    &ProviderXalanXML_AppendKey, 
    NULL,
    NULL,
    &ProviderXalanXML_GetContentPtr,
    NULL,
    &ProviderXalanXML_FreeContent,
    NULL,
    } ;



/* ------------------------------------------------------------------------ */
/*                                                                          */
/* iowrite                                                                  */
/*                                                                          */
/* output callback                                                          */
/*                                                                          */
/* ------------------------------------------------------------------------ */

static long unsigned int  iowrite   (const char *buffer,
			long unsigned int len,
			void *context)

    {
    return owrite ((tReq *)context, buffer, len) ;
    }

#if 0
/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_Xalan_Text2Text                                                  */
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



int embperl_Xalan_Text2Text     (/*in*/  tReq *	  r,
                                 /*in*/  HV *     pReqParameter,
                                 /*in*/  SV *     pSource)

    {
    epTHX_
    int             rc ;
    HE *	    pEntry ;
    HV *            pParam ;
    SV *            pStylesheetParam ;
    SV * *          ppSV ;
    char *	    pKey ;
    SV *            pValue ;
    STRLEN          len ;
    IV              l ;
    int		    n ;
    const char * *  pParamArray ;
    const char *    sStylesheet ;
    char *          p ;


#if !defined(XALAN_NO_NAMESPACES)
	using std::istrstream;
#endif



    sStylesheet = GetHashValueStr (aTHX_ pReqParameter, "xsltstylesheet", NULL) ;
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
	    sprintf (r -> errdat2, "%s", pKey) ;
	    return rcNotHashRef ;
	    }

	n = hv_iterinit (pParam) ;
        
	if (!(pParamArray = (const char * *)_malloc(r, sizeof (const char *) * (n + 1) * 2)))
	    return rcOutOfMemory ;

	n = 0 ;
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



    // Our input streams...
    p   = SvPV (pSource, len) ;
    istrstream	theXMLStream(p, len);




    pStylesheetParam = sv_2mortal (CreateHashRef (r, 
        (char *)"provider",       hashtsv,  CreateHashRef (r, 
            (char *)"type",       hashtstr, (char *)"xalan-compile-xsl",
            (char *)"stylesheet", hashtsv,  CreateHashRef (r, 
                (char *)"provider", hashtsv, CreateHashRef (r, 
                    (char *)"type", hashtstr, (char *)"file",
                    (char *)"filename", hashtstr, sStylesheet,
                    NULL),
                (char *)"cache", hashtint, 0,
                NULL),
            NULL),
        NULL)) ;


    if (!SvROK (pStylesheetParam) || SvTYPE(SvRV(pStylesheetParam)) != SVt_PVHV)
        {
        strncpy (r -> errdat2, "stylesheet", sizeof(r -> errdat2) - 1) ;
        return rcNotHashRef ; 
        }

    tCacheItem * pXSLCache ;
    // does not work !!!!!!!!!!!!!!!!!!!!
    //if ((rc = Cache_New (r, (HV *)SvRV(pStylesheetParam), &pXSLCache)) != ok)
    //    return rc ;

    XalanCompiledStylesheet * pCompiledXSL ;
    
    bool bUseCache = 0 ;
    if ((rc = Cache_GetContentPtr (r, pXSLCache, (void * *)&pCompiledXSL, bUseCache)) != ok)
        return rc ;


    
    // Do the transform.

    const XalanParsedSource * parsedXML = 0;
    theXalanTransformer -> parseSource(&theXMLStream, parsedXML);
    
    int theResult = theXalanTransformer -> transform(*parsedXML, pCompiledXSL, r, iowrite, NULL);

    Cache_ReleaseContent (r, pXSLCache) ;

    if(theResult != 0)
	{
	strncpy (r -> errdat1, "XSLT", sizeof (r -> errdat1)) ;
	strncpy (r -> errdat2, theXalanTransformer -> getLastError(), sizeof (r -> errdat2) - 2) ;
	return rcXalanError ;
	}

    // Terminate Xalan.
    //XalanTransformer::terminate();

    // Call the static terminator for Xerces.
    //XMLPlatformUtils::Terminate();

    return(0);
    }

#endif

/*! Provider that reads compiles xalan stylesheet */

typedef struct tProviderXalan
    {
    tProvider           Provider ;
    SV *                pOutputSV ;
    HV *                pParamHV ;
    } tProviderXalan ;


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderXalan_New      					            */
/*                                                                          */
/*! 
*   \_en
*   Creates a new xalan provider and fills it with data from the hash pParam
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
*   Erzeugt einen neue Provider für Xalan.  Der ein Zeiger
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

int ProviderXalan_New (/*in*/ req *              r,
                          /*in*/ tCacheItem *       pItem,
                          /*in*/ tProviderClass *   pProviderClass,
                             /*in*/ HV *               pProviderParam,
                             /*in*/ SV *               pParam,
                             /*in*/ IV                 nParamIndex)


    {
    int                 rc ;
    
    if ((rc = Provider_NewDependOne (r, sizeof(tProviderXalan), "source", pItem, pProviderClass, pProviderParam, pParam, nParamIndex)) != ok)
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

static int ProviderXalan_AppendKey (/*in*/ req *              r,
                                   /*in*/ tProviderClass *   pProviderClass,
                                      /*in*/ HV *               pProviderParam,
                                      /*in*/ SV *               pParam,
                                      /*in*/ IV                 nParamIndex,
                                   /*i/o*/ SV *              pKey)
    {
    epTHX_
    int          rc ;

    if ((rc = Cache_AppendKey (r,  pProviderParam, "source", pParam, nParamIndex, pKey)) != ok)
        return rc;

    if ((rc = Cache_AppendKey (r, pProviderParam, "stylesheet", NULL, 0, pKey)) != ok)
        return rc;

    sv_catpv (pKey, "*xalan") ;
    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderLibXalan_UpdateParam   				            */
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

static int ProviderXalan_UpdateParam(/*in*/ req *              r,
                                   /*in*/ tProvider *        pProvider,
                                   /*in*/ HV *               pParam)
    {
    epTHX_
    int		    rc ;
    HV *	    pParamHV ;
    
    if ((rc = GetHashValueHREF  (r, pParam, "param", &pParamHV)) != ok)
        {
        pParamHV = r -> Component.Param.pXsltParam ;
        }

    if (((tProviderXalan *)pProvider) -> pParamHV)
	SvREFCNT_dec (((tProviderXalan *)pProvider) -> pParamHV) ;

    ((tProviderXalan *)pProvider) -> pParamHV = pParamHV ;
    if (pParamHV)
        {
        SV * pSV = (SV *)((tProviderXalan *)pProvider) -> pParamHV ;
#ifdef SOLARIS
        ATOMIC_INC(SvREFCNT((pSV))) ;
#else
        SvREFCNT_inc((pSV)) ;
#endif
        }

    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderXalan_iowrite                                                    */
/*                                                                          */
/* output callback                                                          */
/*                                                                          */
/* ------------------------------------------------------------------------ */

struct iowrite
    {
    tProviderXalan  * pProvider ;
    tReq * pReq ;
    } ;

static long unsigned int  ProviderXalan_iowrite   (const char *buffer,
			long unsigned int len,
			void *context)

    {
    tReq * r = ((struct iowrite *)context) -> pReq ;
    epTHX_ 

    sv_catpvn (((struct iowrite *)context) -> pProvider -> pOutputSV, (char *)buffer, len) ;
    return len ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderXalan_GetContentSV	  				            */
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



static int ProviderXalan_GetContentSV      (/*in*/ req *            r,
                                            /*in*/ tProvider *      pProvider,
                                            /*in*/ SV * *           pData,
                                            /*in*/ bool             bUseCache)

    {
    epTHX_
    int    rc ;
    XalanParsedSource *       parsedXML ;
    XalanCompiledStylesheet * pCompiledXSL ;
    HV *	    pParamHV ;
    HE *	    pEntry ;
    char *	    pKey ;
    SV *            pValue ;
    IV		    l ;    
    STRLEN	    len ;    
    struct iowrite iowrite ;
    
    r -> Component.pCurrPos = NULL ;
    r -> Component.nSourceline = 1 ;
    r -> Component.pSourcelinePos = NULL ;    
    r -> Component.pLineNoCurrPos = NULL ;    

    
    tCacheItem * pSrcCache = Cache_GetDependency(r, pProvider -> pCache, 0) ;
    tCacheItem * pXSLCache = Cache_GetDependency(r, pProvider -> pCache, 1) ;

    if ((rc = Cache_GetContentPtr  (r, pSrcCache, (void * *)&parsedXML, bUseCache)) != ok)
        return rc ;

    if ((rc = Cache_GetContentPtr (r, pXSLCache, (void * *)&pCompiledXSL, bUseCache)) != ok)
        return rc ;

    if (!bUseCache)
        {
        if (((tProviderXalan *)pProvider) -> pOutputSV)
            SvREFCNT_dec (((tProviderXalan *)pProvider) -> pOutputSV) ;

        ((tProviderXalan *)pProvider) -> pOutputSV = newSVpv("",0) ;

        pParamHV = ((tProviderXalan *)pProvider) -> pParamHV  ;

        if (pParamHV)
	    {
	    hv_iterinit (pParamHV) ;
	    while ((pEntry = hv_iternext (pParamHV)))
	        {
	        pKey     = hv_iterkey (pEntry, &l) ;
	        pValue   = hv_iterval (pParamHV, pEntry) ;
	        theXalanTransformer -> setStylesheetParam (XalanDOMString(pKey), XalanDOMString(SvPV(pValue, len))) ;
	        }
	    }
   
        iowrite.pProvider = (tProviderXalan *)pProvider ;
        iowrite.pReq = r ;

        // Do the transform.
        int theResult = theXalanTransformer -> transform(*parsedXML, pCompiledXSL, &iowrite, ProviderXalan_iowrite, NULL);

        if(theResult != 0)
	    {
	    strncpy (r -> errdat1, "XSLT", sizeof (r -> errdat1)) ;
	    strncpy (r -> errdat2, theXalanTransformer -> getLastError(), sizeof (r -> errdat2) - 2) ;
	    return rcXalanError ;
	    }

        *pData = iowrite.pProvider -> pOutputSV ;
#ifdef SOLARIS
        ATOMIC_INC(SvREFCNT((*pData))) ;
#else
        SvREFCNT_inc((*pData)) ;
#endif
        }

    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderXalan_FreeContent 		                            */
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



static int ProviderXalan_FreeContent(/*in*/ req *             r,
                                 /*in*/ tCacheItem * pItem)

    {
    epTHX_
    tProviderXalan * pProvider = ((tProviderXalan *)pItem -> pProvider) ;

    if (pProvider -> pOutputSV)
        SvREFCNT_dec (pProvider -> pOutputSV) ;

    pProvider -> pOutputSV = NULL ;
    
    /*
    if (pProvider -> pParamHV)
	SvREFCNT_dec (pProvider -> pParamHV) ;

    pProvider -> pParamHV = NULL ;
    */

    return ok ;
    }

/* ------------------------------------------------------------------------ */

static tProviderClass ProviderClassXalan = 
    {   
    "text/*", 
    &ProviderXalan_New, 
    &ProviderXalan_AppendKey, 
    &ProviderXalan_UpdateParam, 
    &ProviderXalan_GetContentSV,
    NULL,
    NULL,
    &ProviderXalan_FreeContent,
    NULL,
    } ;



/* ------------------------------------------------------------------------ */

int embperl_Xalan_Init ()
    {
    Cache_AddProviderClass ("xalan-compile-xsl", &ProviderClassXalanXSL) ;
    Cache_AddProviderClass ("xalan-parse-xml", &ProviderClassXalanXML) ;
    Cache_AddProviderClass ("xalan", &ProviderClassXalan) ;

    // Call the static initializer for Xerces.
    XMLPlatformUtils::Initialize();

    // Initialize Xalan.
    XalanTransformer::initialize();

    
    theXalanTransformer = new XalanTransformer ;

    return ok ;
    }





} /* extern C */

