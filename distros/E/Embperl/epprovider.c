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
#   $Id: epprovider.c 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################*/


#include "ep.h"
#include "epmacro.h"
#include "ep_xs_typedefs.h"
#include "ep_xs_sv_convert.h"



/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Provider_New      					                    */
/*                                                                          */
/*! 
*   \_en
*   Creates a provider. 
*
*   @note   This function should not be called directly, but from another
*           ProviderXXX_New function
*   
*   @param  r               Embperl request record
*   @param  nSize           Size of provider struct
*   @param  pItem           CacheItem which holds the output of the provider
*   @param  pProviderClass  Provider class record
*                               source      Sourcetext provider
*   @param  pParam          Parameter Hash
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Erzeugt einen neuen Provider.
*
*   @note   Diese Funktion sollte nicht direkt aufgerufen werden, sondern
*           von einer anderen ProviderXXX_New Funktion aus
*  
*   @param  r               Embperl request record
*   @param  nSize           Größer der provider struct
*   @param  pItem           CacheItem welches die Ausgabe des Providers 
*                           speichert
*   @param  pProviderClass  Provider class record
*   @param  pParam          Parameter Hash
*                               source      Quellentext provider
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

int Provider_New            (/*in*/ req *              r,
                             /*in*/ size_t             nSize,
                             /*in*/ tCacheItem *       pItem,
                             /*in*/ tProviderClass *   pProviderClass,
                             /*in*/ HV *               pParam)


    {
    epTHX_
    tProvider *     pNew = (tProvider *)cache_malloc (r, nSize) ;
    
    if (!pNew)
        return rcOutOfMemory ;

    memset (pNew, 0, nSize) ;

    pNew -> pCache             = pItem ;
    pNew -> pProviderClass     = pProviderClass ;
    pNew -> sOutputType        = pProviderClass -> sOutputType ;

    pItem -> pProvider = (tProvider *)pNew ;

    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Provider_AddDependOne				                    */
/*                                                                          */
/*! 
*   \_en
*   Adds another dependency provider to a new provider. If only a string
*   is given for the dependend provider the fMatch functions of the
*   provider classes are called until a provider class is found.  
*
*   @note   This function should not be called directly, but from another
*           ProviderXXX_New function
*   
*   @param  r               Embperl request record
*   @param  nSize           Size of provider struct
*   @param  sSourceName     Name of the element in pParam that holds the source
*   @param  pItem           CacheItem which holds the output of the provider
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash of this Providers
*   @param  pParam          All Parameters 
*   @param  nParamIndex       If pParam is an AV, this parameter gives the index into the Array
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Fügt einen neuen Abhänigkeit für einen neuen Provider.
*   Wird nur eine Zeichenkette als Abhänigkeit übergeben, werden der Reihe
*   nach die fMatch Funktionen der Providerklassen aufgerufen, bis eine
*   passende Klasse gefunden wurde.
*
*   @note   Diese Funktion sollte nicht direkt aufgerufen werden, sondern
*           von einer anderen ProviderXXX_New Funktion aus
*  
*   @param  r               Embperl request record
*   @param  nSize           Größer der provider struct
*   @param  sSourceName     Name des Elements in pParam welches die Quelle enthält
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

int Provider_AddDependOne   (/*in*/ req *              r,
                             /*in*/ tProvider *        pProvider,
                             /*in*/ const char *       sSourceName,
                             /*in*/ tCacheItem *       pItem,
                             /*in*/ tProviderClass *   pProviderClass,
                             /*in*/ HV *               pProviderParam,
                             /*in*/ SV *               pParam,
                             /*in*/ IV                 nParamIndex)


    {
    epTHX_
    int          rc ;
    SV *         pSourceParam ;
    
    tCacheItem * pSubCache  ;
    
    pSourceParam = GetHashValueSV (r, pProviderParam, sSourceName) ;

    if (pSourceParam)
        {
        if ((rc = Cache_New (r, pSourceParam, -1, 0, &pSubCache)) != ok)
            {
            strcpy (r -> errdat2, sSourceName) ;
            return rc ;
            }
        }
    else if (pParam)
        {
        if ((rc = Cache_New (r, pParam, nParamIndex, 0, &pSubCache)) != ok)
            {
            strcpy (r -> errdat2, sSourceName) ;
            return rc ;
            }
        }
    else
        {
        strncpy (r -> errdat1, sSourceName, sizeof (r -> errdat1) - 1) ;
        strncpy (r -> errdat2, pItem -> sKey, sizeof (r -> errdat2) - 1) ;
        
        return rcMissingParam ;
        }


    if ((rc = Cache_AddDependency (r, pItem, pSubCache)) != ok)
        return rc ;
    

    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Provider_NewDependOne				                    */
/*                                                                          */
/*! 
*   \_en
*   Creates a provider which depends on another provider. If only a string
*   is given for the dependend provider the fMatch functions of the
*   provider classes are called until a provider class is found.  
*
*   @note   This function should not be called directly, but from another
*           ProviderXXX_New function
*   
*   @param  r               Embperl request record
*   @param  nSize           Size of provider struct
*   @param  sSourceName     Name of the element in pParam that holds the source
*   @param  pItem           CacheItem which holds the output of the provider
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash of this Providers
*   @param  pParam          All Parameters 
*   @param  nParamIndex       If pParam is a AV, this parameter gives the index into the Array
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Erzeugt einen neuen Provider der von einem anderem Provider abhängt.
*   Wird nur eine Zeichenkette als Abhänigkeit übergeben, werden der Reihe
*   nach die fMatch Funktionen der Providerklassen aufgerufen, bis eine
*   passende Klasse gefunden wurde.
*
*   @note   Diese Funktion sollte nicht direkt aufgerufen werden, sondern
*           von einer anderen ProviderXXX_New Funktion aus
*  
*   @param  r               Embperl request record
*   @param  nSize           Größer der provider struct
*   @param  sSourceName     Name des Elements in pParam welches die Quelle enthält
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

int Provider_NewDependOne   (/*in*/ req *              r,
                             /*in*/ size_t             nSize,
                             /*in*/ const char *       sSourceName,
                             /*in*/ tCacheItem *       pItem,
                             /*in*/ tProviderClass *   pProviderClass,
                             /*in*/ HV *               pProviderParam,
                             /*in*/ SV *               pParam,
                             /*in*/ IV                 nParamIndex)


    {
    int          rc ;
    
    if ((rc = Provider_New (r, nSize, pItem, pProviderClass, pProviderParam)) != ok)
        return rc ;

    if ((rc = Provider_AddDependOne (r, pItem -> pProvider, sSourceName, pItem, pProviderClass, pProviderParam, pParam, nParamIndex)) != ok)
        return rc ;

    return ok ;
    }




/* ------------------------------------------------------------------------ */
/*                                                                          */
/*!         Provider that reads input from file                             */
/*                                                                          */

typedef struct tProviderFile
    {
    tProvider           Provider ;
    const char *        sFilename ;         /**< Filename */
    } tProviderFile ;


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderFile_New      					            */
/*                                                                          */
/*! 
*   \_en
*   Creates a new file provider and fills it with data from the hash pParam
*   The resulting provider is put into the cache structure
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem which holds the output of the provider
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash of this Providers
*                               filename        filename
*   @param  pParam          All Parameters 
*   @param  nParamIndex       If pParam is an AV, this parameter gives the index into the Array
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Erzeugt einen neue Provider der daten aus Dateien ließt. Der ein Zeiger
*   auf den resultierenden Provider wird in die Cachestrutr eingefügt
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem welches die Ausgabe des Providers 
*                           speichert
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash dieses Providers
*                               filename        Dateiname
*   @param  pParam          Parameter insgesamt
*   @param  nParamIndex       Wenn pParam ein AV ist, gibt dieser Parameter den Index an
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

static int ProviderFile_New (/*in*/ req *              r,
                             /*in*/ tCacheItem *       pItem,
                             /*in*/ tProviderClass *   pProviderClass,
                             /*in*/ HV *               pProviderParam,
                             /*in*/ SV *               pParam,
                             /*in*/ IV                 nParamIndex)


    {
    epTHX_
    int          rc ;
    tProviderFile * pNew  ;
    char *          sFilename ;
    
    if ((rc = Provider_New (r, sizeof(tProviderFile), pItem, pProviderClass, pProviderParam)) != ok)
        return rc ;

    pNew = (tProviderFile *)pItem -> pProvider ;

    sFilename = GetHashValueStr (aTHX_ pProviderParam, "filename",  r -> Component.Param.sInputfile) ;
    pNew -> sFilename = embperl_PathSearch(r, NULL, sFilename, -1) ;
    if (!pNew -> sFilename)
        {
        strncpy (r -> errdat1, sFilename, sizeof (r -> errdat1) - 1) ;
        strncpy (r -> errdat2, embperl_PathStr(r, sFilename), sizeof (r -> errdat2) - 1) ;
        return rcNotFound ;
        }


    pItem -> sExpiresFilename           = strdup (pNew -> sFilename) ;

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
*   The file provider appends the filename
*   
*   @param  r               Embperl request record
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash of this Providers
*                               filename        filename
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
*   Der File Provider hängt den Dateinamen an.
*   
*   @param  r               Embperl request record
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash dieses Providers
*                               filename        Dateiname
*   @param  pParam          Parameter insgesamt
*   @param  nParamIndex       Wenn pParam ein AV ist, gibt dieser Parameter den Index an
*   @param  pKey            Schlüssel zu welchem hinzugefügt wird
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

static int ProviderFile_AppendKey (/*in*/ req *              r,
                                   /*in*/ tProviderClass *   pProviderClass,
                                   /*in*/ HV *               pProviderParam,
                                   /*in*/ SV *               pParam,
                                   /*in*/ IV                 nParamIndex,
                                   /*i/o*/ SV *              pKey)
    {
    epTHX_
    const char * sFilename  ;
    const char * sAbsFilename  ;

    sFilename = GetHashValueStr (aTHX_ pProviderParam, "filename",  r -> Component.Param.sInputfile) ;
    sAbsFilename = embperl_PathSearch(r, r -> pPool, (char *)sFilename, -1) ;
    if (!sAbsFilename)
        {
        strncpy (r -> errdat1, sFilename, sizeof (r -> errdat1) - 1) ;
        strncpy (r -> errdat2, embperl_PathStr(r, sFilename), sizeof (r -> errdat2) - 1) ;
        return rcNotFound ;
        }
    
    sv_catpvf (pKey, "*file:%s", sAbsFilename) ;
    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderFile_GetContentSV   					            */
/*                                                                          */
/*! 
*   \_en
*   Get the whole content from the provider. 
*   The file provider reads the whole file into memory
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
*   Der File Provider ließt die komplette Datei.
*   
*   @param  r               Embperl request record
*   @param  pProvider       The provider record
*   @param  pData           Liefert den Inhalt
*   @param  bUseCache       Gesetzt wenn der Inhalt nicht neu berechnet werden soll
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



static int ProviderFile_GetContentSV (/*in*/ req *             r,
                             /*in*/ tProvider *     pProvider,
                             /*in*/ SV * *              pData,
                             /*in*/ bool                bUseCache)

    {
    epTHX_
    size_t nSize = pProvider -> pCache -> FileStat.st_size ;
    int rc = ok ;
    
    r -> Component.sSourcefile = (char *)((tProviderFile *)pProvider) -> sFilename ;
    embperl_SetCWDToFile (r, r -> Component.sSourcefile) ;
    
    if (!bUseCache)
        {
        rc  = ReadHTML(r, (char *)((tProviderFile *)pProvider) -> sFilename, &nSize, pData) ;
    
        if (rc == ok)
            {
            SvREFCNT_inc (*pData) ;
            r -> Component.pBuf = SvPVX (*pData) ;
            r -> Component.pEndPos = r -> Component.pBuf + nSize ;
            r -> Component.pCurrPos = r -> Component.pBuf ;
            }
        }

    return rc ;
    }


/* ------------------------------------------------------------------------ */


tProviderClass ProviderClassFile = 
    {   
    "text/*", 
    &ProviderFile_New, 
    &ProviderFile_AppendKey, 
    NULL,
    &ProviderFile_GetContentSV,
    NULL,
    NULL,
    NULL,
    } ;


/* ------------------------------------------------------------------------ */
/*                                                                          */
/*!         Provider that reads input from memory                           */
/*                                                                          */

typedef struct tProviderMem
    {
    tProvider           Provider ;
    SV *                pSource ;           /**< Source */
    const char *        sName ;             /**< Name of memory provider */
    time_t              nLastModified ;     /**< Last modified */
    time_t              nLastModifiedWhileGet ;     /**< Last modified during last get */
    } tProviderMem ;


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderMem_New      					            */
/*                                                                          */
/*! 
*   \_en
*   Creates a new file provider and fills it with data from the hash pParam
*   The resulting provider is put into the cache structure
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem which holds the output of the provider
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash of this Providers
*                               name          name (used to compare mtime)
*                               source        source text
*                               mtime         last modification time
*   @param  pParam          All Parameters 
*   @param  nParamIndex       If pParam is an AV, this parameter gives the index into the Array
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Erzeugt einen neue Provider der daten aus Dateien ließt. Der ein Zeiger
*   auf den resultierenden Provider wird in die Cachestrutr eingefügt
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem welches die Ausgabe des Providers 
*                           speichert
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash dieses Providers
*                               name        Name (wird benutzt um mtime zu vergelichen)
*                               source      Quellentext
*                               mtime       Zeitpunkt der letzten Änderung
*   @param  pParam          Parameter insgesamt
*   @param  nParamIndex       Wenn pParam ein AV ist, gibt dieser Parameter den Index an
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

static int ProviderMem_New (/*in*/ req *              r,
                             /*in*/ tCacheItem *       pItem,
                             /*in*/ tProviderClass *   pProviderClass,
                             /*in*/ HV *               pProviderParam,
                             /*in*/ SV *               pParam,
                             /*in*/ IV                 nParamIndex)


    {
    epTHX_
    int          rc ;
    tProviderMem * pNew  ;
    
    if ((rc = Provider_New (r, sizeof(tProviderMem), pItem, pProviderClass, pProviderParam)) != ok)
        return rc ;

    pNew = (tProviderMem *)pItem -> pProvider ;

    pNew -> sName                   = GetHashValueStrDupA (aTHX_ pProviderParam, "name",  r -> Component.Param.sInputfile) ;
    /*
    pNew -> nLastModified           = GetHashValueUInt       (pParam, "mtime", 0) ;

    pSrc = GetHashValueSV     (r, pParam, "source") ;
    if (!pSrc)
        pNew -> pSource = NULL ;
    else if (SvROK(pSrc))
        pNew -> pSource = SvREFCNT_inc (SvRV(pSrc)) ;
    else
        pNew -> pSource = SvREFCNT_inc (pSrc) ;
    */

    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderMem_AppendKey    					            */
/*                                                                          */
/*! 
*   \_en
*   Append it's key to the keystring. If it depends on anything it must 
*   call Cache_AppendKey for any dependency.
*   The file provider appends the filename
*   
*   @param  r               Embperl request record
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash of this Providers
*                               name          name (used to compare mtime)
*                               source        source text
*                               mtime         last modification time
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
*   Der File Provider hängt den Dateinamen an.
*   
*   @param  r               Embperl request record
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash dieses Providers
*                               name        Name (wird benutzt um mtime zu vergelichen)
*                               source      Quellentext
*                               mtime       Zeitpunkt der letzten Änderung
*   @param  pParam          Parameter insgesamt
*   @param  nParamIndex       Wenn pParam ein AV ist, gibt dieser Parameter den Index an
*   @param  pKey            Schlüssel zu welchem hinzugefügt wird
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

static int ProviderMem_AppendKey (/*in*/ req *              r,
                                  /*in*/ tProviderClass *   pProviderClass,
                                  /*in*/ HV *               pProviderParam,
                                  /*in*/ SV *               pParam,
                                  /*in*/ IV                 nParamIndex,
                                  /*i/o*/ SV *              pKey)
    {
    epTHX_
    const char * sName = GetHashValueStr (aTHX_ pProviderParam, "name",  r -> Component.Param.sInputfile) ;
    sv_catpvf (pKey, "*memory:%s", sName) ;

    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderMem_UpdateParam    					            */
/*                                                                          */
/*! 
*   \_en
*   Update the parameter of the provider
*   
*   @param  r               Embperl request record
*   @param  pProvider       Provider record
*   @param  pParam          Parameter Hash
*                               name        name 
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
*                               name        name
*   @param  pKey            Schlüssel zu welchem hinzugefügt wird
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

static int ProviderMem_UpdateParam(/*in*/ req *              r,
                                   /*in*/ tProvider *        pProvider,
                                   /*in*/ HV *               pParam)
    {
    epTHX_
    SV           * pSrc ;

    if (((tProviderMem *)pProvider) -> pSource)
        SvREFCNT_dec (((tProviderMem *)pProvider) -> pSource) ;

    ((tProviderMem *)pProvider) -> nLastModified  = GetHashValueUInt (r, pParam, "mtime", r -> Component.Param.nMtime) ;
    
    pSrc = GetHashValueSV     (r, pParam, "source") ;
    if (!pSrc)
        ((tProviderMem *)pProvider) -> pSource = SvROK(r -> Component.Param.pInput)?SvREFCNT_inc (SvRV(r -> Component.Param.pInput)):NULL ;
    else if (SvROK(pSrc))
        ((tProviderMem *)pProvider) -> pSource = SvREFCNT_inc (SvRV(pSrc)) ;
    else
        ((tProviderMem *)pProvider) -> pSource = SvREFCNT_inc (pSrc) ;

    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderMem_GetContentSV   					            */
/*                                                                          */
/*! 
*   \_en
*   Get the whole content from the provider. 
*   The file provider reads the whole file into memory
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
*   Der File Provider ließt die komplette Datei.
*   
*   @param  r               Embperl request record
*   @param  pProvider       The provider record
*   @param  pData           Liefert den Inhalt
*   @param  bUseCache       Gesetzt wenn der Inhalt nicht neu berechnet werden soll
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



static int ProviderMem_GetContentSV (/*in*/ req *             r,
                             /*in*/ tProvider *     pProvider,
                             /*in*/ SV * *              pData,
                             /*in*/ bool                bUseCache)

    {
    epTHX_
    r -> Component.sSourcefile = ep_pstrcat(r -> pPool, "MEM:", (char *)((tProviderMem *)pProvider) -> sName, NULL) ;
        
    if (!bUseCache)
        {
        ((tProviderMem *)pProvider) -> nLastModifiedWhileGet = ((tProviderMem *)pProvider) -> nLastModified ; 
        if ((*pData = SvREFCNT_inc(((tProviderMem *)pProvider) -> pSource)))
            {
            SvREFCNT_inc (*pData) ;
            if (SvPOK(*pData))
                {
                r -> Component.pBuf = SvPVX (*pData) ;
                r -> Component.pEndPos = r -> Component.pBuf + SvCUR(*pData) ;
                r -> Component.pCurrPos = r -> Component.pBuf ;
                }
            else
                {
                r -> Component.pBuf = "" ;
                r -> Component.pEndPos = r -> Component.pBuf  ;
                r -> Component.pCurrPos = r -> Component.pBuf ;
                }    
            }
        }
    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderMem_FreeContent 	                                    */
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



int ProviderMem_FreeContent(/*in*/ req *             r,
                                /*in*/ tCacheItem * pItem)

    {
    epTHX_
    tProviderMem * pProvider = (tProviderMem *)(pItem -> pProvider) ;
    if (pItem -> pSVData && pProvider -> pSource)
        {
        SvREFCNT_dec (pProvider -> pSource) ;
        pProvider ->  pSource = NULL ;
        }

    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderMem_IsExpired    					            */
/*                                                                          */
/*! 
*   \_en
*   Check if content of provider is expired
*   
*   @param  r               Embperl request record
*   @param  pProvider       Provider 
*   @return                 TRUE if expired
*   \endif                                                                       
*
*   \_de									   
*   Prüft ob der Inhalt des Providers noch gültig ist.
*   
*   @param  r               Embperl request record
*   @param  pProvider       Provider 
*   @return                 WAHR wenn abgelaufen
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

static int ProviderMem_IsExpired  (/*in*/ req *              r,
                                   /*in*/ tProvider *        pProvider)

    {
    return ((tProviderMem *)pProvider) -> nLastModified == 0 || ((tProviderMem *)pProvider) -> nLastModified != ((tProviderMem *)pProvider) -> nLastModifiedWhileGet ; 
    }


/* ------------------------------------------------------------------------ */


tProviderClass ProviderClassMem = 
    {   
    "text/*", 
    &ProviderMem_New, 
    &ProviderMem_AppendKey, 
    &ProviderMem_UpdateParam, 
    &ProviderMem_GetContentSV,
    NULL,
    NULL,
    &ProviderMem_FreeContent,
    &ProviderMem_IsExpired, 
    } ;


/* ------------------------------------------------------------------------ */
/*                                                                          */
/*!         Provider for Embperl parser                                     */
/*                                                                          */

typedef struct tProviderEpParse
    {
    tProvider           Provider ;
    tTokenTable *       pTokenTable ;
    } tProviderEpParse ;


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderEpParse_New      					            */
/*                                                                          */
/*! 
*   \_en
*   Creates a new Embperl parser provider and fills it with data from the 
*   hash pParam. The resulting provider is put into the cache structure
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
*   Erzeugt einen neue Provider für den Embperl Parser. Der ein Zeiger
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

static int ProviderEpParse_New (/*in*/ req *              r,
                             /*in*/ tCacheItem *       pItem,
                             /*in*/ tProviderClass *   pProviderClass,
                             /*in*/ HV *               pProviderParam,
                             /*in*/ SV *               pParam,
                             /*in*/ IV                 nParamIndex)


    {
    epTHX_
    dSP ;
    int          rc ;
    int          num ;
    SV * pSyntaxSV ;
    SV * pSyntaxRV = NULL ;
    SV * pSyntaxPV ;
    tTokenTable * pSyntax ;
    const char * sSyntax = GetHashValueStr (aTHX_ pProviderParam, "syntax", r -> Component.Config.sSyntax) ;

    if ((rc = Provider_NewDependOne (r, sizeof(tProviderEpParse), "source", pItem, pProviderClass, pProviderParam, pParam, nParamIndex)) != ok)
        return rc ;

    pSyntaxPV = sv_2mortal(newSVpv ((char *)sSyntax, 0)) ;


    SPAGAIN ;
    PUSHMARK(sp);
    XPUSHs(pSyntaxPV);                
    PUTBACK;                        
    num = perl_call_pv ("Embperl::Syntax::GetSyntax", G_SCALAR /*| G_EVAL*/) ;
    tainted = 0 ;
    SPAGAIN;                        
    if (num == 1)
	pSyntaxRV = POPs ;
    PUTBACK;
    if (num != 1 || !SvROK (pSyntaxRV) || !(pSyntaxSV = SvRV(pSyntaxRV)) || SvTYPE((SV *)pSyntaxSV) != SVt_PVHV)
	{
	strncpy (r -> errdat1, sSyntax, sizeof (r -> errdat1) - 1) ;
	return rcUnknownSyntax ;
	}
    
    pSyntax = epxs_sv2_Embperl__Syntax(pSyntaxRV) ;
    ((tProviderEpParse *)pItem -> pProvider) -> pTokenTable = pSyntax ;
    
    pItem -> bCache = FALSE ; /* do not cache, because it's cached by the compiler */
    
    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderEpParse_AppendKey    					    */
/*                                                                          */
/*! 
*   \_en
*   Append it's key to the keystring. If it depends on anything it must 
*   call Cache_AppendKey for any dependency.
*   
*   @param  r               Embperl request record
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash of this Providers
*                               syntax      Syntax
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
*                               syntax      Syntax
*   @param  pParam          Parameter insgesamt
*   @param  nParamIndex       Wenn pParam ein AV ist, gibt dieser Parameter den Index an
*   @param  pKey            Schlüssel zu welchem hinzugefügt wird
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

static int ProviderEpParse_AppendKey (/*in*/ req *              r,
                                      /*in*/ tProviderClass *   pProviderClass,
                                      /*in*/ HV *               pProviderParam,
                                      /*in*/ SV *               pParam,
                                      /*in*/ IV                 nParamIndex,
                                      /*i/o*/ SV *              pKey)
    {
    epTHX_
    int          rc ;
    const char * sSyntax = GetHashValueStr (aTHX_ pProviderParam, "syntax", r -> Component.Config.sSyntax) ;
    
    if ((rc = Cache_AppendKey (r, pProviderParam, "source", pParam, nParamIndex, pKey)) != ok)
        return rc;

    sv_catpvf (pKey, "*epparse:%s", sSyntax) ;
    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderEpParse_GetContentIndex				            */
/*                                                                          */
/*! 
*   \_en
*   Get the whole content from the provider. 
*   The Embperl parser provider parsers the source and generates a DomTree
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
*   Der Embperl Parser Provider parsest die Quelle und erzeugt einen DomTree
*   
*   @param  r               Embperl request record
*   @param  pProvider       The provider record
*   @param  pData           Liefert den Inhalt
*   @param  bUseCache       Gesetzt wenn der Inhalt nicht neu berechnet werden soll
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



static int ProviderEpParse_GetContentIndex (/*in*/ req *             r,
                                            /*in*/ tProvider *       pProvider,
                                            /*in*/ tIndex *          pData,
                                            /*in*/ bool              bUseCache)

    {
    epTHX_
    int    rc ;
    char * p ;
    STRLEN len ;
    SV *   pSource ;
    tCacheItem * pFileCache = Cache_GetDependency(r, pProvider -> pCache, 0) ;
    if ((rc = Cache_GetContentSV (r, pFileCache, &pSource, bUseCache)) != ok)
        return rc ;
        
    r -> Component.pTokenTable = ((tProviderEpParse *)pProvider) -> pTokenTable ;
    if (!bUseCache)
        {
        p   = SvPV (pSource, len) ;
        if ((rc =  embperl_Parse (r, p, len, pData)) != ok)
            return rc ;
        }

    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderEpParse_FreeContent 		                                    */
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



int ProviderEpParse_FreeContent(/*in*/ req *             r,
                                /*in*/ tCacheItem * pItem)

    {
    /*
    Do not delete, because it's same dom tree as compiler 
    if (pItem -> xData)
        return DomTree_delete (r -> pApp, DomTree_self(pItem -> xData)) ;
    */
    return ok ;
    }

/* ------------------------------------------------------------------------ */


tProviderClass ProviderClassEpParse = 
    {   
    "X-Embperl/DomTree", 
    &ProviderEpParse_New, 
    &ProviderEpParse_AppendKey, 
    NULL,
    NULL,
    NULL,
    &ProviderEpParse_GetContentIndex,
    &ProviderEpParse_FreeContent,
    NULL,
    } ;




/* ------------------------------------------------------------------------ */
/*                                                                          */
/*!         Provider for Embperl compiler                                   */
/*                                                                          */

typedef struct tProviderEpCompile
    {
    tProvider           Provider ;
    SV *                pSVData ;
    char *              sPackage ;
    char *              sMainSub ;
    } tProviderEpCompile ;

static int  nPackageCount = 1 ;
static perl_mutex PackageCountMutex ;

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderEpCompile_New      					            */
/*                                                                          */
/*! 
*   \_en
*   Creates a new Embperl compile provider and fills it with data from the 
*   hash pParam. The resulting provider is put into the cache structure
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem which holds the output of the provider
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash of this Providers
*                               package     Packagename
*   @param  pParam          All Parameters 
*   @param  nParamIndex       If pParam is an AV, this parameter gives the index into the Array
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Erzeugt einen neue Provider für den Embperl Compiler. Der ein Zeiger
*   auf den resultierenden Provider wird in die Cachestrutr eingefügt
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem welches die Ausgabe des Providers 
*                           speichert
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash dieses Providers
*                               package     Packagename
*   @param  pParam          Parameter insgesamt
*   @param  nParamIndex       Wenn pParam ein AV ist, gibt dieser Parameter den Index an
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

static int ProviderEpCompile_New (/*in*/ req *              r,
                             /*in*/ tCacheItem *       pItem,
                             /*in*/ tProviderClass *   pProviderClass,
                             /*in*/ HV *               pProviderParam,
                             /*in*/ SV *               pParam,
                             /*in*/ IV                 nParamIndex)


    {
    epTHX_
    int          rc ;
    char *       sPackage ;
    char *       sMainSub ;
    
    if ((rc = Provider_NewDependOne (r, sizeof(tProviderEpCompile), "source", pItem, pProviderClass, pProviderParam, pParam, nParamIndex)) != ok)
        return rc ;

    /*if (r -> Config.bDebug)
	lprintf (r -> pApp,  "[%d]ep_acquire_mutex(PackageCountMutex)\n", r -> pThread -> nPid) ; */
    if ((sPackage = GetHashValueStrDupA (aTHX_ pProviderParam, "package", r -> Component.Config.sPackage))) 
        {
        int n ;
        ep_acquire_mutex(PackageCountMutex) ;
        n = nPackageCount++ ;
        ep_release_mutex(PackageCountMutex) ;
        ((tProviderEpCompile *)(pItem -> pProvider)) -> sPackage = sPackage ;
        sMainSub = ((tProviderEpCompile *)(pItem -> pProvider)) -> sMainSub = malloc (40) ;
        sprintf (sMainSub, "_ep_main%d", n) ;
        }
    else
        {
        int n ;
        ep_acquire_mutex(PackageCountMutex) ;
        n = nPackageCount++ ;
        ep_release_mutex(PackageCountMutex) ;
        sPackage = ((tProviderEpCompile *)(pItem -> pProvider)) -> sPackage = malloc (sizeof (EMBPERL_PACKAGE_STR) + 32) ;
        sprintf (sPackage, EMBPERL_PACKAGE_STR"::__%d", n) ;
        sMainSub = ((tProviderEpCompile *)(pItem -> pProvider)) -> sMainSub = malloc (40) ;
        sprintf (sMainSub, "_ep_main%d", n) ;
        }
    /*if (r -> Config.bDebug)
	lprintf (r -> pApp,  "[%d]ep_release_mutex(PackageCountMutex)\n", r -> pThread -> nPid) ; */

    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderEpCompile_AppendKey    					    */
/*                                                                          */
/*! 
*   \_en
*   Append it's key to the keystring. If it depends on anything it must 
*   call Cache_AppendKey for any dependency.
*   
*   @param  r               Embperl request record
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash of this Providers
*                               package     Packagename
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
*                               package     Packagename
*   @param  pParam          Parameter insgesamt
*   @param  nParamIndex       Wenn pParam ein AV ist, gibt dieser Parameter den Index an
*   @param  pKey            Schlüssel zu welchem hinzugefügt wird
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

static int ProviderEpCompile_AppendKey (/*in*/ req *              r,
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

    sv_catpvf (pKey, "*epcompile:%s", GetHashValueStr (aTHX_ pProviderParam, "package", r -> Component.Config.sPackage?r -> Component.Config.sPackage:"")) ;
    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderEpCompile_GetContentIndex				            */
/*                                                                          */
/*! 
*   \_en
*   Get the whole content from the provider. 
*   The Embperl compile provider compiles the source DomTRee and generates
*   a Perl program and a compiled DomTRee
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
*   Der Embperl Compile Provider überstzes den Quellen DOmTree und erzeugt
*   ein Perlprogramm und einen übersetzten DomTree
*   
*   @param  r               Embperl request record
*   @param  pProvider       The provider record
*   @param  pData           Liefert den Inhalt
*   @param  bUseCache       Gesetzt wenn der Inhalt nicht neu berechnet werden soll
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



static int ProviderEpCompile_GetContentIndex (/*in*/ req *             r,
                                            /*in*/ tProvider *         pProvider,
                                            /*in*/ tIndex *            pData,
                                            /*in*/ bool                bUseCache)

    {
    epTHX_
    int     rc ;
    tIndex  xSrcDomTree ;
    tCacheItem * pSrcCache ;
    SV *         pProg = NULL ;

    pSrcCache = Cache_GetDependency(r, pProvider -> pCache, 0) ;
    if ((rc = Cache_GetContentIndex (r, pSrcCache, &xSrcDomTree, bUseCache)) != ok)
        return rc ;
        
    r -> Component.sCurrPackage =  ((tProviderEpCompile *)(pProvider)) -> sPackage  ;
    r -> Component.sEvalPackage =  ((tProviderEpCompile *)(pProvider)) -> sPackage  ;
    r -> Component.nEvalPackage =  strlen (((tProviderEpCompile *)(pProvider)) -> sPackage)  ;
    r -> Component.sMainSub     =  ((tProviderEpCompile *)(pProvider)) -> sMainSub ;
    
    if (!bUseCache)
        {
        if ((rc =  embperl_Compile (r, xSrcDomTree, pData, &pProg )) != ok)
            {
	    ((tProviderEpCompile *)pProvider) -> pSVData = NULL ;
	    if (pProg)
	        SvREFCNT_dec (pProg) ;
     
            Cache_FreeContent (r, pSrcCache) ; /* make sure we don't leave an invalid dom tree */
	    return rc ;
	    }

        ((tProviderEpCompile *)pProvider) -> pSVData = pProg ;
        }

    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderEpCompile_GetContentIndex				            */
/*                                                                          */
/*! 
*   \_en
*   Get the whole content from the provider. 
*   The Embperl compile provider compiles the source DomTRee and generates
*   a Perl program and a compiled DomTRee
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
*   Der Embperl Compile Provider überstzes den Quellen DOmTree und erzeugt
*   ein Perlprogramm und einen übersetzten DomTree
*   
*   @param  r               Embperl request record
*   @param  pProvider       The provider record
*   @param  pData           Liefert den Inhalt
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



static int ProviderEpCompile_GetContentSV  (/*in*/ req *             r,
                                            /*in*/ tProvider *       pProvider,
                                            /*in*/ SV * *            pData,
                                            /*in*/ bool              bUseCache)

    {
    epTHX_
    if (!bUseCache)
        *pData = SvREFCNT_inc (((tProviderEpCompile *)pProvider) -> pSVData) ;

    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderEpCompile_FreeContent 	                                    */
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



int ProviderEpCompile_FreeContent(/*in*/ req *             r,
                                /*in*/ tCacheItem * pItem)

    {
    epTHX_

    if (pItem -> xData)
        return DomTree_delete (r -> pApp, DomTree_self(pItem -> xData)) ;

    /*
    if (((tProviderEpCompile *)(pItem -> pProvider)) -> sPackage)
        free (((tProviderEpCompile *)(pItem -> pProvider)) -> sPackage) ;
    */


    return ok ;
    }

/* ------------------------------------------------------------------------ */


tProviderClass ProviderClassEpCompile = 
    {   
    "X-Embperl/DomTree", 
    &ProviderEpCompile_New, 
    &ProviderEpCompile_AppendKey, 
    NULL,
    &ProviderEpCompile_GetContentSV,
    NULL,
    &ProviderEpCompile_GetContentIndex,
    &ProviderEpCompile_FreeContent,
    NULL,
    } ;



/* ------------------------------------------------------------------------ */
/*                                                                          */
/*!         Provider for Embperl Executer                                   */
/*                                                                          */

typedef struct tProviderEpRun
    {
    tProvider           Provider ;
    char *              sPackage ;
    } tProviderEpRun ;


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderEpRun_New      					            */
/*                                                                          */
/*! 
*   \_en
*   Creates a new Embperl run provider and fills it with data from the 
*   hash pParam. The resulting provider is put into the cache structure
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
*   Erzeugt einen neue Provider für den Embperl Executer. Der ein Zeiger
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

static int ProviderEpRun_New (/*in*/ req *              r,
                             /*in*/ tCacheItem *       pItem,
                             /*in*/ tProviderClass *   pProviderClass,
                             /*in*/ HV *               pProviderParam,
                             /*in*/ SV *               pParam,
                             /*in*/ IV                 nParamIndex)


    {
    int          rc ;
    
    if ((rc = Provider_NewDependOne (r, sizeof(tProviderEpRun), "source", pItem, pProviderClass, pProviderParam, pParam, nParamIndex)) != ok)
        return rc ;

    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderEpRun_AppendKey    					    */
/*                                                                          */
/*! 
*   \_en
*   Append it's key to the keystring. If it depends on anything it must 
*   call Cache_AppendKey for any dependency.
*   
*   @param  r               Embperl request record
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash of this Providers
*                               cache_key   
*                               cache_key_options   
*                               cache_key_func   
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
*                               cache_key   
*                               cache_key_options   
*                               cache_key_func   
*   @param  pParam          Parameter insgesamt
*   @param  nParamIndex       Wenn pParam ein AV ist, gibt dieser Parameter den Index an
*   @param  pKey            Schlüssel zu welchem hinzugefügt wird
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

static int ProviderEpRun_AppendKey (/*in*/ req *              r,
                                   /*in*/ tProviderClass *   pProviderClass,
                                      /*in*/ HV *               pProviderParam,
                                      /*in*/ SV *               pParam,
                                      /*in*/ IV                 nParamIndex,
                                   /*i/o*/ SV *              pKey)
    {
    epTHX_
    int          rc ;
    const char * sKey        = GetHashValueStr (aTHX_ pProviderParam, "cache_key", r -> Component.Config.sCacheKey) ;
    int          bKeyOptions = GetHashValueInt (aTHX_ pProviderParam, "cache_key_options", r -> Component.Config.bCacheKeyOptions) ;
    CV *         pKeyCV ; 

    if ((rc = Cache_AppendKey (r, pProviderParam, "source", pParam, nParamIndex, pKey)) != ok)
        return rc;

    sv_catpv (pKey, "*eprun:") ;

    if ((rc = GetHashValueCREF (r, pProviderParam, "cache_key_func", &pKeyCV)) != ok)
        return rc ;
    
    if (!pKeyCV)
        pKeyCV = r -> Component.Config.pCacheKeyFunc ;

    if (pKeyCV)
	{
	SV * pRet ;

	if ((rc = CallCV (r, "CacheKey", pKeyCV, 0, &pRet)) != ok)
	    return rc ;

	if (pRet && SvOK(pRet))
	    sv_catsv (pKey, pRet) ;
	}
    
    if ((bKeyOptions & ckoptPathInfo) && r -> Param.sPathInfo)
	sv_catpv (pKey, r -> Param.sPathInfo) ;

    if ((bKeyOptions & ckoptQueryInfo) && r -> Param.sQueryInfo)
	sv_catpv (pKey, r -> Param.sQueryInfo) ;
    
    if (sKey)
        sv_catpv (pKey, sKey) ;
    
    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* embperl_PreExecute                                                       */
/*                                                                          */
/* Looks for vars/subs inside compiled document                             */
/*                                                                          */
/* ------------------------------------------------------------------------ */

static int embperl_PreExecute	            (/*in*/  tReq *	  r,
				     /*in*/  tCacheItem * pCache,
                                     /*in*/  char *       sPackage)


    {
    epTHX_
    STRLEN      l ;
    SV *        pSV ;
    CV *        pCV ;
    SV *        pSVVar ;
    
    pSV = newSVpvf("%s::EXPIRES", sPackage) ;
    newSVpvf2(pSV) ;
    pCV = perl_get_cv (SvPV(pSV, l), 0) ;
    if (pCV)
	{
	SvREFCNT_dec (pCache -> pExpiresCV) ;
	pCache -> pExpiresCV = pCV ;
	SvREFCNT_inc (pCV) ;
	}    
    SvREFCNT_dec(pSV);
    
    pSV = newSVpvf("%s::EXPIRES", sPackage) ;
    newSVpvf2(pSV) ;
    pSVVar = perl_get_sv (SvPV(pSV, l), 0) ;
    if (pSVVar)
	{
	pCache -> nExpiresInTime = SvUV (pSVVar) ;
	}    
    SvREFCNT_dec(pSV);
    
    /*
    pSV = newSVpvf("%s::CACHE_KEY", r -> Component.sEvalPackage) ;
    newSVpvf2(pSV) ;
    pCV = perl_get_cv (SvPV(pSV, l), 0) ;
    if (pCV)
	{
	SvREFCNT_dec (pProcessor -> pCacheKeyCV) ;
	pProcessor -> pCacheKeyCV = pCV ;
	SvREFCNT_inc (pCV) ;
	}    
    SvREFCNT_dec(pSV);
    
    pSV = newSVpvf("%s::CACHE_KEY", r -> Component.sEvalPackage) ;
    newSVpvf2(pSV) ;
    pSVVar = perl_get_sv (SvPV(pSV, l), 0) ;
    if (pSVVar)
	{
	pProcessor -> sCacheKey = SvPV (pSVVar, l) ;
	}    
    SvREFCNT_dec(pSV);

    pSV = newSVpvf("%s::CACHE_KEY_OPTIONS", r -> Component.sEvalPackage) ;
    newSVpvf2(pSV) ;
    pSVVar = perl_get_sv (SvPV(pSV, l), 0) ;
    if (pSVVar)
	{
	pProcessor -> bCacheKeyOptions = SvIV (pSVVar) ;
	}    
    SvREFCNT_dec(pSV);
    */

    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderEpRun_IsExpired    					            */
/*                                                                          */
/*! 
*   \_en
*   Check if content of provider is expired
*   
*   @param  r               Embperl request record
*   @param  pProvider       Provider 
*   @return                 TRUE if expired
*   \endif                                                                       
*
*   \_de									   
*   Prüft ob der Inhalt des Providers noch gültig ist.
*   
*   @param  r               Embperl request record
*   @param  pProvider       Provider 
*   @return                 WAHR wenn abgelaufen
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

static int ProviderEpRun_IsExpired  (/*in*/ req *              r,
                                   /*in*/ tProvider *        pProvider)

    {
    int rc ;
    bool bCache = pProvider -> pCache -> bCache ;

    if (!((tProviderEpRun *)(pProvider)) -> sPackage)
        return FALSE ;

    /* update cache parameters */
    if ((rc =  embperl_PreExecute (r, pProvider -> pCache, ((tProviderEpRun *)(pProvider)) -> sPackage)) != ok)
        {
        LogError (r, rc) ;
        }
    if (pProvider -> pCache -> nExpiresInTime || pProvider -> pCache -> pExpiresCV)
        pProvider -> pCache -> bCache = 1 ;
    else
        {
        pProvider -> pCache -> bCache = 0 ;
        if (bCache)
            Cache_FreeContent (r, pProvider -> pCache) ;
        return TRUE ;
        }
        

    return FALSE ; 
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderEpRun_UpdateParam    					    */
/*                                                                          */
/*! 
*   \_en
*   Update the parameter of the provider
*   
*   @param  r               Embperl request record
*   @param  pProvider       Provider record
*   @param  pParam          Parameter Hash
*                               name        name 
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
*                               name        name
*   @param  pKey            Schlüssel zu welchem hinzugefügt wird
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

static int ProviderEpRun_UpdateParam(/*in*/ req *              r,
                                   /*in*/ tProvider *        pProvider,
                                   /*in*/ HV *               pParam)
    {
    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderEpRun_GetContentIndex				            */
/*                                                                          */
/*! 
*   \_en
*   Get the whole content from the provider. 
*   The Embperl Run provider executes the compiled DomTree & Perl program
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
*   Der Embperl Run Provider führt den übersetzen DomTree und das Perlprogramm aus
*   
*   @param  r               Embperl request record
*   @param  pProvider       The provider record
*   @param  pData           Liefert den Inhalt
*   @param  bUseCache       Gesetzt wenn der Inhalt nicht neu berechnet werden soll
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



static int ProviderEpRun_GetContentIndex   (/*in*/ req *             r,
                                            /*in*/ tProvider *       pProvider,
                                            /*in*/ tIndex *          pData,
                                            /*in*/ bool              bUseCache)

    {
    int         rc ;
    tIndex      xSrcDomTree ;
    CV *        pCV ;

    tCacheItem * pSrcCache = Cache_GetDependency(r, pProvider -> pCache, 0) ;

    if ((rc = Cache_GetContentSvIndex (r, pSrcCache, (SV **)&pCV, &xSrcDomTree, bUseCache)) != ok)
        return rc ;
        
    if (!bUseCache || !*pData || !pProvider -> pCache -> bCache)
        {
        if ((rc =  embperl_Execute (r, xSrcDomTree, pCV, pData)) != ok)
            return rc ;

        ((tProviderEpRun *)(pProvider)) -> sPackage = ((tProviderEpCompile *)(pSrcCache -> pProvider)) -> sPackage ;
        /* update cache parameter from source */
        ProviderEpRun_IsExpired  (r, pProvider) ;
        }

    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderEpRun_FreeContent 	                                    */
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



int ProviderEpRun_FreeContent(/*in*/ req *             r,
                                /*in*/ tCacheItem * pItem)

    {
    if (pItem -> xData)
        return DomTree_delete (r -> pApp, DomTree_self(pItem -> xData)) ;

    return ok ;
    }

/* ------------------------------------------------------------------------ */


tProviderClass ProviderClassEpRun = 
    {   
    "X-Embperl/DomTree", 
    &ProviderEpRun_New, 
    &ProviderEpRun_AppendKey, 
    NULL, 
    NULL,
    NULL,
    &ProviderEpRun_GetContentIndex,
    &ProviderEpRun_FreeContent,
    &ProviderEpRun_IsExpired,
    } ;



/* ------------------------------------------------------------------------ */
/*                                                                          */
/*!         Provider for Embperl DomTree to String converter                */
/*                                                                          */

typedef struct tProviderEpToString
    {
    tProvider           Provider ;
    } tProviderEpToString ;


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderEpToString_New      					            */
/*                                                                          */
/*! 
*   \_en
*   Creates a new DomTree to String provider and fills it with data from the 
*   hash pParam. The resulting provider is put into the cache structure
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
*   Erzeugt einen neue Provider für den Embperl zu Textkonverter. Der ein Zeiger
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

static int ProviderEpToString_New (/*in*/ req *              r,
                             /*in*/ tCacheItem *       pItem,
                             /*in*/ tProviderClass *   pProviderClass,
                             /*in*/ HV *               pProviderParam,
                             /*in*/ SV *               pParam,
                             /*in*/ IV                 nParamIndex)


    {
    int          rc ;
    
    if ((rc = Provider_NewDependOne (r, sizeof(tProviderEpToString), "source", pItem, pProviderClass, pProviderParam, pParam, nParamIndex)) != ok)
        return rc ;

    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderEpToString_AppendKey    					    */
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

static int ProviderEpToString_AppendKey (/*in*/ req *              r,
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

    sv_catpv (pKey, "*eptostring") ;
    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderEpToString_GetContentIndex				            */
/*                                                                          */
/*! 
*   \_en
*   Get the whole content from the provider. 
*   The Embperl parser provider parsers the source and generates a DomTree
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
*   Der Embperl Parser Provider parsest die Quelle und erzeugt einen DomTree
*   
*   @param  r               Embperl request record
*   @param  pProvider       The provider record
*   @param  pData           Liefert den Inhalt
*   @param  bUseCache       Gesetzt wenn der Inhalt nicht neu berechnet werden soll
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



static int ProviderEpToString_GetContentSV (/*in*/ req *             r,
                                            /*in*/ tProvider *       pProvider,
                                            /*in*/ SV * *            pData,
                                            /*in*/ bool              bUseCache)

    {
    epTHX_
    int     rc ;
    STRLEN  len ;
    tIndex  xSrcDomTree ;
    tCacheItem * pSrcCache ;
    SV * pOut ;
    char * pBuf ;
    tDomTree * pDomTree ;


    pSrcCache = Cache_GetDependency(r, pProvider -> pCache, 0) ;
    if ((rc = Cache_GetContentIndex (r, pSrcCache, &xSrcDomTree, bUseCache)) != ok)
        return rc ;

    if (!bUseCache)
        {
        if (xSrcDomTree == 0)
	    {
	    strncpy (r -> errdat1, "EpToString source", sizeof (r -> errdat1)) ;
	    return rcMissingInput ;
	    }

        
        oRollbackOutput (r, NULL) ;
        oBegin (r) ;
        pDomTree = DomTree_self (xSrcDomTree) ;
        Node_toString (r, pDomTree, pDomTree -> xDocument, 0) ;

        pOut = newSV (1) ;
        len = GetContentLength (r) + 1 ;
    
        SvGROW (pOut, len) ;
        pBuf = SvPVX (pOut) ;
        oCommitToMem (r, NULL, pBuf) ;
        oRollbackOutput (r, NULL) ;
        SvCUR_set (pOut, len - 1) ;
        SvPOK_on (pOut) ;

        *pData = pOut ;
        }

    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderEpToString_FreeContent 	                                    */
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



int ProviderEpToString_FreeContent(/*in*/ req *             r,
                                /*in*/ tCacheItem * pItem)

    {
    if (pItem -> xData)
        return DomTree_delete (r -> pApp, DomTree_self(pItem -> xData)) ;

    return ok ;
    }

/* ------------------------------------------------------------------------ */


tProviderClass ProviderClassEpToString = 
    {   
    "text/*", 
    &ProviderEpToString_New, 
    &ProviderEpToString_AppendKey, 
    NULL,
    &ProviderEpToString_GetContentSV,
    NULL,
    NULL,
    &ProviderEpToString_FreeContent,
    NULL,
    } ;



/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Provider_Init      					                    */
/*                                                                          */
/*! 
*   \_en
*   Register all the providers
*   @return                 error code
*   
*   \endif                                                                       
*
*   \_de									   
*   Provider registrieren
*   @return                 Fehlercode
*   
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

int Provider_Init (/*in*/ tApp * a)

    {
    Cache_AddProviderClass ("file",      &ProviderClassFile) ;
    Cache_AddProviderClass ("memory",    &ProviderClassMem) ;
    Cache_AddProviderClass ("epparse",   &ProviderClassEpParse) ;
    Cache_AddProviderClass ("epcompile", &ProviderClassEpCompile) ;
    Cache_AddProviderClass ("eprun",     &ProviderClassEpRun) ;
    Cache_AddProviderClass ("eptostring",&ProviderClassEpToString) ;

    ep_create_mutex(PackageCountMutex) ;


    return ok ;
    }

