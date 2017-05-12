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
#   $Id: epcache.c 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################*/

#include "ep.h"
#include "epmacro.h"


/* --- don't use Perl's memory management here --- */

#ifndef DMALLOC
#undef malloc
#undef realloc
#undef strdup
#undef free
#endif

HV * pProviders ;       /**< global hash that holds all known providers classes */
HV * pCacheItems ;      /**< hash which contains all CacheItems by Key */
tCacheItem * * pCachesToRelease = NULL ;





/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Cache_AddProviderClass				                    */
/*                                                                          */
/*! 
*   \_en
*   Add a provider class to list of known providers
*   @param  sName           Name of the Providerclass
*   @param  pProviderClass  Provider class record
*   @return                 error code
*   
*   \endif                                                                       
*
*   \_de									   
*   Fügt eine Providerklasse den der Liste der bekannten Providern hinzu
*   @param  sName           Name der Providerklasse
*   @param  pProviderClass  Provider class record
*   @return                 Fehlercode
*   
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

int Cache_AddProviderClass (/*in*/ const char *     sName,
                            /*in*/ tProviderClass * pClass)

    {
    SetHashValueInt (NULL, pProviders, sName, (IV)pClass) ;
    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Cache_Init      					                    */
/*                                                                          */
/*! 
*   \_en
*   Do global initialization of cache system
*   @return                 error code
*   
*   \endif                                                                       
*
*   \_de									   
*   Führt die globale Initialisierung des Cachesystems durch
*   @return                 Fehlercode
*   
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

int Cache_Init (/*in*/ tApp * a)

    {
    epaTHX_
    pProviders  = newHV () ;
    pCacheItems = newHV () ;

    ArrayNew (a, &pCachesToRelease, 16, sizeof (tCacheItem *)) ;

    /* lprintf (a, "XXXXX Cache_Init [%d/%d] pProviders=%x pCacheItems=%x pCachesToRelease=%x", _getpid(), GetCurrentThreadId(), pProviders, pCacheItems, pCachesToRelease) ; */
    
    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Cache_CleanupRequest  				                    */
/*                                                                          */
/*! 
*   \_en
*   Do cleanup at end of request
*   @param  r               Embperl request record
*   @return                 error code
*   
*   \endif                                                                       
*
*   \_de									   
*   Führt die Aufräumarbeiten am Requestende aus
*   @param  r               Embperl request record
*   @return                 Fehlercode
*   
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

int Cache_CleanupRequest (req * r)

    {
    if (pCachesToRelease)
        {
        int n = ArrayGetSize (r -> pApp, pCachesToRelease) ;
        int i ;

        /* lprintf (r -> pApp, "XXXXX Cache_CleanupRequest [%d/%d] pProviders=%x pCacheItems=%x pCachesToRelease=%x", _getpid(), GetCurrentThreadId(), pProviders, pCacheItems, pCachesToRelease) ; */

        for (i = 0; i < n; i++)
            Cache_FreeContent (r, pCachesToRelease[i]) ;

        ArraySetSize(r -> pApp, &pCachesToRelease, 0) ;
        }

    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Cache_ParamUpdate   						            */
/*                                                                          */


  
int Cache_ParamUpdate (/*in*/ req *             r,
                       /*in*/ HV *              pProviderParam,
                       /*in*/ bool              bTopLevel,
                       /*in*/ char *            sLogText,
                       /*in*/ tCacheItem *      pNew)


    {
    epTHX_
    char * exfn ;
    int    rc ;

    pNew -> nExpiresInTime      = GetHashValueInt (aTHX_ pProviderParam, "expires_in", bTopLevel?r -> Component.Config.nExpiresIn:0) ;
    if (pNew -> pExpiresCV)
        SvREFCNT_dec (pNew -> pExpiresCV) ;
    if ((rc = GetHashValueCREF  (r, pProviderParam, "expires_func", &pNew -> pExpiresCV)) != ok)
        return rc ;
    if (!pNew -> pExpiresCV && bTopLevel)
        pNew -> pExpiresCV = (CV *)SvREFCNT_inc((SV *)r -> Component.Config.pExpiredFunc) ;
    
    exfn = GetHashValueStrDupA (aTHX_ pProviderParam, "expires_filename", bTopLevel?r -> Component.Config.sExpiresFilename:NULL) ;
    if (pNew -> sExpiresFilename)
	{
	if (exfn)
	    {
	    /* lprintf (r -> pApp,  "exfn=%s\n", exfn) ; */
	    free ((void *)pNew -> sExpiresFilename) ;
	    pNew -> sExpiresFilename    = exfn ;
	    }
	}
    else
	pNew -> sExpiresFilename    = exfn ;

    pNew -> bCache              = (bool)GetHashValueInt (aTHX_ pProviderParam, "cache", exfn || pNew -> pExpiresCV || pNew -> nExpiresInTime?1:0) ;

    if (sLogText && (r -> Component.Config.bDebug & dbgCache))
        lprintf (r -> pApp,  "[%d]CACHE: %s CacheItem %s; expires_in=%d expires_func=%s expires_filename=%s cache=%s\n",
                            r -> pThread -> nPid, sLogText, pNew -> sKey, pNew -> nExpiresInTime,
                           pNew -> pExpiresCV?"yes":"no", pNew -> sExpiresFilename?pNew -> sExpiresFilename:"",
                           pNew -> bCache?"yes":"no") ; 

    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Cache_New      						            */
/*                                                                          */
/*! 
*   \_en
*   Checks if a CacheItem which matches the parameters already exists, if
*   not it creates a new CacheItem and fills it with data from the hash 
*   pParam
*   
*   @param  r               Embperl request record
*   @param  pParam          Parameter  (PV,HV,AV)
*                               expires_in  number of seconds when the item 
*                                           expires, 0 = expires never
*                               expires_func    Perl Function (coderef) that
*                                               is called and item is expired
*                                               if it returns TRUE
*                               expires_filename    item expires when modification
*                                                   time of file changes
*                               cache               set to zero to not cache the content
*                               provider            parameter for the provider 
*   @param  nParamNdx       If pParam is a AV, this parameter gives the index into the Array
*   @param  bTopLevel       True if last elemet before output. In this case the cache parameters
*                           defaults to the ones from Componet.Config
*   @param  pItem           Return of the new Items
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Prüft ob ein passendes CacheItem bereits vorhanden ist, wenn nicht 
*   erzeugt die Funktion ein neues CacheItem und füllte es mit den Daten aus 
*   pParam
*   
*   @param  r               Embperl request record
*   @param  pParam          Parameter (PV,HV,AV)
*                               expires_in  anzahl der Sekunden wenn Item
*                                           abläuft; 0 = nie
*                               expires_func    Perl Funktion (coderef) die
*                                               aufgerufen wird. Wenn sie wahr
*                                               zurückgibt ist das Item abgelaufen
*                               expires_filename    Item ist abgelaufen wenn 
*                                                   Dateidatum sich ändert
*                               cache               Auf Null setzen damit Inhalt
*                                                   nicht gecacht wird
*                               provider            parameter für Provider
*   @param  nParamNdx       Wenn pParam ein AV ist, gibt dieser Parameter den Index an
*   @param  bTopLevel       Wahr wenn letztes Element vor der Ausgabe, dann werden
*                           die Cache Parameter aus Componet.Config herangezogen
*   @param  pItem           Rückgabe des neuen Items
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

int Cache_New (/*in*/ req *             r,
               /*in*/ SV *              pParam,
               /*in*/ IV                nParamNdx,
               /*in*/ bool              bTopLevel,
               /*in*/ tCacheItem * *    pItem)


    {
    epTHX_
    int          rc ;
    HV *         pProviderParam ;
    char *       sProvider ;
    tProviderClass *  pProviderClass ;
    tCacheItem * pNew = NULL ;
    SV *         pKey = NULL ;
    const char * sKey = "" ;
    STRLEN       len ;

    /* lprintf (r -> pApp, "XXXXX Cache_New [%d/%d] pProviders=%x %s  pCacheItems=%x %s  pCachesToRelease=%x %s\n", _getpid(), GetCurrentThreadId(), pProviders, IsBadReadPtr (pProviders,4 )?"bad":"ok", pCacheItems, IsBadReadPtr (pCacheItems, 4)?"bad":"ok", pCachesToRelease, IsBadReadPtr (pCachesToRelease, 4)?"bad":"ok") ; */

    if (SvROK(pParam))
        pParam = SvRV (pParam) ;

    if (SvTYPE(pParam) == SVt_PV)
        {
        /* change this to auto match later on ... */
        pProviderParam = (HV *)SvRV(sv_2mortal (CreateHashRef (r, 
                "type", hashtstr, "file",
                "filename", hashtsv, pParam,
                NULL) 
            )) ;
        }
    else if (SvTYPE(pParam) == SVt_PVAV)
        {
        SV * * ppRV = av_fetch ((AV *)pParam, nParamNdx, 0) ;
        if (!ppRV || !*ppRV)
            {
	    strncpy (r -> errdat1, "<provider missing>", sizeof(r -> errdat1) - 1) ;
            return rcUnknownProvider ;
            }
        if (!SvROK (*ppRV) || SvTYPE(pProviderParam = (HV *)SvRV (*ppRV)) != SVt_PVHV)
            {
	    strncpy (r -> errdat1, "<provider missing, element is no hashref>", sizeof(r -> errdat1) - 1) ;
            return rcUnknownProvider ;
            }
        }
    else if (SvTYPE(pParam) == SVt_PVHV)
        {
        pProviderParam = (HV *)pParam ;
        }
    else
        {
        strncpy (r -> errdat1, "<provider missing, no description found>", sizeof(r -> errdat1) - 1) ;
        return rcUnknownProvider ;
        }

    
    sProvider      = GetHashValueStr  (aTHX_  pProviderParam, "type", "") ;
    pProviderClass = (tProviderClass *)GetHashValuePtr (r, pProviders, sProvider, NULL) ;
    if (!pProviderClass)
        {
        if (*sProvider)
	    strncpy (r -> errdat1, sProvider, sizeof(r -> errdat1) - 1) ;
	else
	    strncpy (r -> errdat1, "<provider missing>", sizeof(r -> errdat1) - 1) ;

        return rcUnknownProvider ;
        }
    pKey = newSVpv ("", 0) ;
    if (pProviderClass -> fAppendKey)
        if ((rc = (*pProviderClass -> fAppendKey)(r, pProviderClass, pProviderParam, pParam, nParamNdx - 1, pKey)) != ok)
            return rc ;

    sKey = SvPV(pKey, len) ;
    if ((pNew = Cache_GetByKey (r, sKey)))
        {
        Cache_ParamUpdate (r, pProviderParam, bTopLevel, "Update", pNew) ;
        

        if (pProviderClass -> fUpdateParam)
            if ((rc = (*pProviderClass -> fUpdateParam)(r, pNew -> pProvider, pProviderParam)) != ok)
                return rc ;
        }        

    if (!pNew)
        {
        pNew = cache_malloc (r, sizeof(tCacheItem)) ;
        if (!pNew)
            {
            if (pKey)
                SvREFCNT_dec (pKey) ;
            return rcOutOfMemory ;
            }

        *pItem = NULL ;
        memset (pNew, 0, sizeof (tCacheItem)) ;

        Cache_ParamUpdate (r, pProviderParam, bTopLevel, NULL, pNew) ;
        pNew -> sKey                = strdup (sKey) ;

        if (pProviderParam)
            {
            if ((rc = (*pProviderClass -> fNew)(r, pNew, pProviderClass, pProviderParam, pParam, nParamNdx - 1)) != ok)
                {
                if (pKey)
                    SvREFCNT_dec (pKey) ;
                cache_free (r, pNew) ;
                return rc ;
                }
            if (pProviderClass -> fUpdateParam)
                if ((rc = (*pProviderClass -> fUpdateParam)(r, pNew -> pProvider, pProviderParam)) != ok)
                    return rc ;
            }

        
        if (r -> Component.Config.bDebug & dbgCache)
            lprintf (r -> pApp,  "[%d]CACHE: Created new CacheItem %s; expires_in=%d expires_func=%s expires_filename=%s cache=%s\n",
                               r -> pThread -> nPid, sKey, pNew -> nExpiresInTime,
                               pNew -> pExpiresCV?"yes":"no", pNew -> sExpiresFilename?pNew -> sExpiresFilename:"",
                               pNew -> bCache?"yes":"no") ; 
        SetHashValueInt (r, pCacheItems, sKey, (IV)pNew) ;
        }

    if (pKey)
        SvREFCNT_dec (pKey) ;
    *pItem = pNew ;

    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Cache_AppendKey    					                    */
/*                                                                          */
/*! 
*   \_en
*   Append it's key to the keystring. If it depends on anything it must 
*   call Cache_AppendKey for any dependency.
*   The file provider appends the filename
*   
*   @param  r               Embperl request record
*   @param  pParam          Parameter Hash
*   @param  sSubProvider    sub provider parameter
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
*   @param  pParam          Parameter Hash
*   @param  sSubProvider    sub provider parameter
*   @param  pKey            Schlüssel zu welchem hinzugefügt wird
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

int Cache_AppendKey               (/*in*/ req *              r,
                                   /*in*/ HV *               pProviderParam,
                                   /*in*/ const char *       sSubProvider, 
                                   /*in*/ SV *               pParam,
                                   /*in*/ IV                 nParamIndex,
                                   /*i/o*/ SV *              pKey)
    {
    epTHX_
    int  rc ;
    char *       sProvider ;
    tProviderClass *  pProviderClass ;
    STRLEN       len ;
    tCacheItem * pItem ;

    SV * pSubParam = GetHashValueSV  (r, pProviderParam, sSubProvider) ;
    
    if (pSubParam)
        pParam = pSubParam ;
    
    if (!pParam)
        {
        strncpy (r -> errdat1, sSubProvider, sizeof (r -> errdat1) - 1) ;
        
        return rcMissingParam ;
        }

    
    if (SvROK(pParam))
        pParam = SvRV (pParam) ;

    if (SvTYPE(pParam) == SVt_PV)
        {
        /* change this to auto match later on ... */
        pProviderParam = (HV *)SvRV(sv_2mortal (CreateHashRef (r, 
                "type", hashtstr, "file",
                "filename", hashtsv, pParam,
                NULL) 
            )) ;
        }
    else if (SvTYPE(pParam) == SVt_PVAV)
        {
        SV * * ppRV = av_fetch ((AV *)pParam, nParamIndex, 0) ;
        if (!ppRV || !*ppRV)
            {
	    strncpy (r -> errdat1, "<provider missing>", sizeof(r -> errdat1) - 1) ;

            return rcUnknownProvider ;
            }
        if (!SvROK (*ppRV) || SvTYPE(pProviderParam = (HV *)SvRV (*ppRV)) != SVt_PVHV)
            {
	    strncpy (r -> errdat1, "<provider missing, element is no hashref>", sizeof(r -> errdat1) - 1) ;

            return rcUnknownProvider ;
            }
        }
    else if (SvTYPE(pParam) == SVt_PVHV)
        {
        pProviderParam = (HV *)pParam ;
        }
    else
        {
        strncpy (r -> errdat1, "<provider missing, no description found>", sizeof(r -> errdat1) - 1) ;

        return rcUnknownProvider ;
        }


    sProvider      = GetHashValueStr  (aTHX_  pProviderParam, "type", "") ;
    pProviderClass = (tProviderClass *)GetHashValuePtr (r, pProviders, sProvider, NULL) ;
    if (!pProviderClass)
        {
        if (*sProvider)
	    strncpy (r -> errdat1, sProvider, sizeof(r -> errdat1) - 1) ;
	else
	    strncpy (r -> errdat1, "<provider missing>", sizeof(r -> errdat1) - 1) ;
        return rcUnknownProvider ;
        }
    if (pProviderClass -> fAppendKey)
        if ((rc = (*pProviderClass -> fAppendKey)(r, pProviderClass, pProviderParam, pParam, nParamIndex - 1, pKey)) != ok)
	    {
	    if (r -> Component.Config.bDebug & dbgCache)
		lprintf (r -> pApp,  "[%d]CACHE: Error in Update CacheItem provider=%s\n",
		r -> pThread -> nPid,  sProvider) ;
            return rc ;
	    }
    if ((pItem = Cache_GetByKey (r, SvPV(pKey, len))))
        {
        int bCache = pItem -> bCache ;

        Cache_ParamUpdate (r, pProviderParam, 0, "Update", pItem) ;

        if (!pItem -> bCache && bCache)
            Cache_FreeContent (r, pItem) ;


        if (pProviderClass -> fUpdateParam)
            if ((rc = (*pProviderClass -> fUpdateParam)(r, pItem -> pProvider, pProviderParam)) != ok)
                return rc ;
        }        

    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Cache_GetByKey  						            */
/*                                                                          */
/*! 
*   \_en
*   Gets an CacheItem by it's key.
*   
*   @param  r               Embperl request record
*   @param  sKey            Key
*   @return                 Returns the cache item specified by the key if found
*   \endif                                                                       
*
*   \_de									   
*   Liefert das durch den Schlüssel angegeben CacheItem zurück. 
*   
*   @param  r               Embperl request record
*   @param  sKey            Key
*   @return                 Liefert das CacheItem welches durch den Schlüssel
*                           angegeben wird, soweit gefunden.
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

tCacheItem * Cache_GetByKey    (/*in*/ req *       r,
                                /*in*/ const char * sKey)

    {
    tCacheItem * pItem ;
    
    pItem = (tCacheItem *)GetHashValuePtr (r, pCacheItems, sKey, NULL) ;

    return pItem ;
    }



/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Cache_AddDependency  						    */
/*                                                                          */
/*! 
*   \_en
*   Adds a CacheItem on which this cache items depends
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem which depends on pDependsOn
*   @param  pDependsOn      CacheItem on which pItem depends
*   @return                 0 on success
*   \endif                                                                       
*
*   \_de									   
*   Fügt ein CacheItem von welches Adds a CacheItem on which this cache items depends
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem welches von pDependsOn anhängt
*   @param  pDependsOn      CacheItem von welchem pItem abhängt
*   @return                 0 wenn fehlerfrei ausgeführt
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */




int Cache_AddDependency (/*in*/ req *       r,
                         /*in*/ tCacheItem *    pItem,
                         /*in*/ tCacheItem *    pDependsOn)

    {
    int n ;
    
    if (!pItem -> pDependsOn)
        ArrayNew (r -> pApp, &pItem -> pDependsOn, 2, sizeof (tCacheItem *)) ;

    n = ArrayAdd (r -> pApp, &pItem -> pDependsOn, 1) ;
    pItem -> pDependsOn[n] = pDependsOn ;


    if (!pDependsOn -> pNeededFor)
        ArrayNew (r -> pApp, &pDependsOn -> pNeededFor, 2, sizeof (tCacheItem *)) ;

    n = ArrayAdd (r -> pApp, &pDependsOn -> pNeededFor, 1) ;
    pDependsOn -> pNeededFor[n] = pItem ;

    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Cache_GetDependency  						    */
/*                                                                          */
/*! 
*   \_en
*   Get the Nth CacheItem on which this cache depends
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem 
*   @param  n               Dependency number
*   @return                 Nth Dependency CacheItem
*   \endif                                                                       
*
*   \_de									   
*   Gibt das Nte CacheItem von dem pItem abhängt zurück
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem
*   @param  n               Number der Abhänigkeit
*   @return                 Ntes CacheItem von welchem pItem abhängt
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */




tCacheItem * Cache_GetDependency (/*in*/ req *           r,
                                  /*in*/ tCacheItem *    pItem,
                                  /*in*/ int             n)

    {
    if (!pItem -> pDependsOn || ArrayGetSize (r -> pApp, pItem -> pDependsOn) < n || n < 0)
        return NULL ;

    return pItem -> pDependsOn[n] ;
    }



/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Cache_IsExpired  							    */
/*                                                                          */
/*! 
*   \_en
*   Checks if the cache item or a cache item on which this one depends is
*   expired
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem which should be checked
*   @param  nLastUpdated    When a item on which this one depends, was 
*                           updated after the given request count, then
*                           this item is expired
*   @return                 TRUE if expired, otherwise FALSE
*   \endif                                                                       
*
*   \_de									   
*   Prüft ob das CacheItem oder eines von welchem dieses abhängt nihct
*   mehr gültig ist
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem welches überprüft werden soll
*   @param  nLastUpdated    Wenn ein Item von welchem dieses Item abhängt
*                           nach dem angegebenen Request Count geändert 
*                           wurde ist diese Item nicht mehr gültig
*   @return                 wahr wenn ungültig, ansonsten falsch
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */




int Cache_IsExpired     (/*in*/ req *           r,
                         /*in*/ tCacheItem *    pItem,
                         /*in*/ int             nLastUpdated)


    {
    epTHX_
    int          rc ;
    tCacheItem * pSubItem ;
    int          i ;
    int		 numItems = pItem -> pDependsOn?ArrayGetSize (r -> pApp, pItem -> pDependsOn):0 ;

    if (nLastUpdated < pItem -> nLastUpdated)
        return TRUE ;

    if (pItem -> pProvider -> pProviderClass -> fExpires)
        {
        if ((*pItem ->  pProvider -> pProviderClass -> fExpires)(r, pItem ->  pProvider))
            { 
            if (r -> Component.Config.bDebug & dbgCache)
                lprintf (r -> pApp,  "[%d]CACHE: %s expired because provider C sub returned TRUE\n", r -> pThread -> nPid,  pItem -> sKey) ; 
            Cache_FreeContent (r, pItem) ;
	    return pItem -> bExpired = TRUE ;
            }
        }

    if (pItem -> bExpired || pItem -> nLastChecked == r -> nRequestCount)
	return pItem -> bExpired ; /* we already have checked this or know that is it expired */

    pItem -> nLastChecked = r -> nRequestCount ;

    /* first check dependency */
    for (i = 0; i < numItems; i++)
	{
	pSubItem = pItem -> pDependsOn[i] ;
	if (Cache_IsExpired (r, pSubItem, pItem -> nLastUpdated))
            {
            if (r -> Component.Config.bDebug & dbgCache)
                lprintf (r -> pApp,  "[%d]CACHE: %s expired because dependencies is expired or newer\n", r -> pThread -> nPid, pItem -> sKey) ; 
            Cache_FreeContent (r, pItem) ;
            return pItem -> bExpired = TRUE ;
            }
	}

    if (pItem -> nExpiresInTime && pItem -> nLastModified + pItem -> nExpiresInTime < r -> nRequestTime)
        {
        if (r -> Component.Config.bDebug & dbgCache)
            lprintf (r -> pApp,  "[%d]CACHE: %s expired because of timeout (%d sec)\n", r -> pThread -> nPid, pItem -> sKey, pItem -> nExpiresInTime) ; 
        Cache_FreeContent (r, pItem) ;
        return pItem -> bExpired = TRUE ;
        }

    if (pItem -> sExpiresFilename)
        {
#ifdef WIN32
        if (_stat (pItem -> sExpiresFilename, &pItem -> FileStat))
#else
        if (stat (pItem -> sExpiresFilename, &pItem -> FileStat))
#endif
            {
            if (r -> Component.Config.bDebug & dbgCache)
                lprintf (r -> pApp,  "[%d]CACHE: %s expired because cannot stat file %s\n", r -> pThread -> nPid,  pItem -> sKey, pItem -> sExpiresFilename) ; 
            Cache_FreeContent (r, pItem) ;
	    return pItem -> bExpired = TRUE ;
            }

        if (r -> Component.Config.bDebug & dbgCache)
            lprintf (r -> pApp,  "[%d]CACHE: %s stat file %s mtime=%d size=%d\n", r -> pThread -> nPid, pItem -> sKey, pItem -> sExpiresFilename, pItem -> FileStat.st_mtime, pItem -> FileStat.st_size) ; 
        if (pItem -> nFileModified != pItem -> FileStat.st_mtime)
            {
            if (r -> Component.Config.bDebug & dbgCache)
                lprintf (r -> pApp,  "[%d]CACHE: %s expired because file %s changed\n", r -> pThread -> nPid, pItem -> sKey, pItem -> sExpiresFilename) ; 
	    pItem -> nFileModified = pItem -> FileStat.st_mtime ;
            Cache_FreeContent (r, pItem) ;
            return pItem -> bExpired = TRUE ;
            }
        }
    
    
    if (pItem -> pExpiresCV)
        {
        SV * pRet ;

        if ((rc = CallCV (r, "Expired?", pItem -> pExpiresCV, 0, &pRet)) != ok)
            {
            LogError (r, rc) ;
            Cache_FreeContent (r, pItem) ;
	    return pItem -> bExpired = TRUE ;
            }
    
        if (pRet && SvTRUE(pRet))
            { /* Expire the entry */
            if (r -> Component.Config.bDebug & dbgCache)
                lprintf (r -> pApp,  "[%d]CACHE: %s expired because expirey Perl sub returned TRUE\n", r -> pThread -> nPid,  pItem -> sKey) ; 
            Cache_FreeContent (r, pItem) ;
	    return pItem -> bExpired = TRUE ;
            }
        }

    if (pItem -> fExpires)
        {
        if ((*pItem -> fExpires)(pItem))
            { 
            if (r -> Component.Config.bDebug & dbgCache)
                lprintf (r -> pApp,  "[%d]CACHE: %s expired because expirey C sub returned TRUE\n", r -> pThread -> nPid,  pItem -> sKey) ; 
            Cache_FreeContent (r, pItem) ;
	    return pItem -> bExpired = TRUE ;
            }
        }

    if (r -> Component.Config.bDebug & dbgCache)
        lprintf (r -> pApp,  "[%d]CACHE: %s NOT expired\n", r -> pThread -> nPid,  pItem -> sKey) ; 

    return FALSE ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Cache_SetNotExpired  					            */
/*                                                                          */
/*! 
*   \_en
*   Reset expired flag and last modification time
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem which should be checked
*   @return                 TRUE if expired, otherwise FALSE
*   \endif                                                                       
*
*   \_de									   
*   Abgelaufen Flag zurücksetzen und Zeitpunkt der letzten Änderung setzen
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem welches überprüft werden soll
*   @return                 wahr wenn ungültig, ansonsten falsch
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */


int Cache_SetNotExpired (/*in*/ req *       r,
                         /*in*/ tCacheItem *    pItem)

    {
    pItem -> nLastChecked   = r -> nRequestCount ;
    pItem -> nLastUpdated   = r -> nRequestCount ;
    pItem -> nLastModified  = r -> nRequestTime ;
    pItem -> bExpired       = FALSE ;

    if (!pItem -> bCache)
        {
        int n = ArrayAdd(r -> pApp, &pCachesToRelease, 1) ;
        pCachesToRelease[n] = pItem ;
        }

    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Cache_GetContentSV  					                    */
/*                                                                          */
/*! 
*   \_en
*   Get the whole content as SV, if not expired from the cache, otherwise ask
*   the provider to fetch it. This will also put a read lock on the
*   Cacheitem. When you are done with the content call ReleaseContent
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem which should be checked
*   @param  pData           Returns the content
*   @param  bUseCache       Set if the content should not recomputed
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Holt den gesamt Inhalt als SV soweit nich abgelaufen aus dem Cache, ansonsten
*   wird der Provider beauftragt ihn einzulesen. Zusätzlich wird ein
*   Read Lock gesetzt. Nach der Bearbeitetung des Inhalts sollte deshalb
*   ReleaseLock zum freigeben aufgerufen werden.
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem welches überprüft werden soll
*   @param  pData           Liefert den Inhalt
*   @param  bUseCache       Gesetzt wenn der Inhalt nicht neu berechnet werden soll
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



int Cache_GetContentSV      (/*in*/ req *             r,
                             /*in*/ tCacheItem        *pItem,
                             /*in*/ SV * *            pData,
                             /*in*/ bool              bUseCache) 

    {
    epTHX_
    int rc ;

    if (!bUseCache && (Cache_IsExpired (r, pItem, pItem -> nLastUpdated) || !pItem -> pSVData))
        {
        if (pItem -> pProvider -> pProviderClass -> fGetContentSV)
            if ((rc = ((*pItem -> pProvider -> pProviderClass -> fGetContentSV) (r, pItem -> pProvider, pData, FALSE))) != ok)
		{
                Cache_FreeContent (r, pItem)  ;
		return rc ;
		}
        Cache_SetNotExpired (r, pItem) ;
        if (pItem -> pSVData)
            SvREFCNT_dec (pItem -> pSVData) ;
        pItem -> pSVData = *pData ;
        }
    else
        {
        if (r -> Component.Config.bDebug & dbgCache)
            lprintf (r -> pApp,  "[%d]CACHE: %s take from cache\n", r -> pThread -> nPid,  pItem -> sKey) ; 
        *pData = pItem -> pSVData  ;
        if (pItem -> pProvider -> pProviderClass -> fGetContentSV)
            if ((rc = ((*pItem -> pProvider -> pProviderClass -> fGetContentSV) (r, pItem -> pProvider, pData, TRUE))) != ok)
		{
                Cache_FreeContent (r, pItem)  ;
		return rc ;
		}
        }


    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Cache_GetContentPtr					                    */
/*                                                                          */
/*! 
*   \_en
*   Get the whole content as pointer, if not expired from the cache, otherwise ask
*   the provider to fetch it. This will also put a read lock on the
*   Cacheitem. When you are done with the content call ReleaseContent
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem which should be checked
*   @param  pData           Returns the content
*   @param  bUseCache       Set if the content should not recomputed
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Holt den gesamt Inhalt als Zeiger soweit nich abgelaufen aus dem Cache, ansonsten
*   wird der Provider beauftragt ihn einzulesen. Zusätzlich wird ein
*   Read Lock gesetzt. Nach der Bearbeitetung des Inhalts sollte deshalb
*   ReleaseLock zum freigeben aufgerufen werden.
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem welches überprüft werden soll
*   @param  pData           Liefert den Inhalt
*   @param  bUseCache       Gesetzt wenn der Inhalt nicht neu berechnet werden soll
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



int Cache_GetContentPtr     (/*in*/ req *             r,
                             /*in*/ tCacheItem        *pItem,
                             /*in*/ void * *          pData,
                             /*in*/ bool              bUseCache) 

    {
    int rc ;

    if (!bUseCache && (Cache_IsExpired (r, pItem, pItem -> nLastUpdated) || !pItem -> pData))
        {
        if (r -> Component.Config.bDebug & dbgCache)
            lprintf (r -> pApp,  "[%d]CACHE: %s get from provider\n", r -> pThread -> nPid,  pItem -> sKey) ; 
        if (pItem -> pProvider -> pProviderClass -> fGetContentPtr)
            if ((rc = (*pItem -> pProvider -> pProviderClass -> fGetContentPtr) (r, pItem -> pProvider, pData, FALSE)) != ok)
		{
                Cache_FreeContent (r, pItem)  ;
                return rc ;
		}
        pItem -> pData = *pData ;
        Cache_SetNotExpired (r, pItem) ;
        }
    else
        {
        if (r -> Component.Config.bDebug & dbgCache)
            lprintf (r -> pApp,  "[%d]CACHE: %s take from cache\n", r -> pThread -> nPid,  pItem -> sKey) ; 
        *pData = pItem -> pData ;
        if (pItem -> pProvider -> pProviderClass -> fGetContentPtr)
            if ((rc = (*pItem -> pProvider -> pProviderClass -> fGetContentPtr) (r, pItem -> pProvider, pData, TRUE)) != ok)
		{
                Cache_FreeContent (r, pItem)  ;
                return rc ;
		}
        }
    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Cache_GetContentIndex			                            */
/*                                                                          */
/*! 
*   \_en
*   Get the whole content as pointer, if not expired from the cache, otherwise ask
*   the provider to fetch it. This will also put a read lock on the
*   Cacheitem. When you are done with the content call ReleaseContent
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem which should be checked
*   @param  pData           Returns the content
*   @param  bUseCache       Set if the content should not recomputed
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Holt den gesamt Inhalt als Zeiger soweit nich abgelaufen aus dem Cache, ansonsten
*   wird der Provider beauftragt ihn einzulesen. Zusätzlich wird ein
*   Read Lock gesetzt. Nach der Bearbeitetung des Inhalts sollte deshalb
*   ReleaseLock zum freigeben aufgerufen werden.
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem welches überprüft werden soll
*   @param  pData           Liefert den Inhalt
*   @param  bUseCache       Gesetzt wenn der Inhalt nicht neu berechnet werden soll
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



int Cache_GetContentIndex   (/*in*/ req *             r,
                             /*in*/ tCacheItem        *pItem,
                             /*in*/ tIndex *          pData,
                             /*in*/ bool              bUseCache) 

    {
    int rc ;

    if (!bUseCache && (Cache_IsExpired (r, pItem, pItem -> nLastUpdated) || !pItem -> xData))
        {
        if (r -> Component.Config.bDebug & dbgCache)
            lprintf (r -> pApp,  "[%d]CACHE: %s get from provider\n", r -> pThread -> nPid,  pItem -> sKey) ; 
        if (pItem -> pProvider -> pProviderClass -> fGetContentIndex)
            if ((rc = (*pItem -> pProvider -> pProviderClass -> fGetContentIndex) (r, pItem -> pProvider, pData, FALSE)) != ok)
		{
                Cache_FreeContent (r, pItem)  ;
                return rc ;
		}
        pItem -> xData = *pData ;
        Cache_SetNotExpired (r, pItem) ;
        }
    else
        {
        if (r -> Component.Config.bDebug & dbgCache)
            lprintf (r -> pApp,  "[%d]CACHE: %s take from cache\n", r -> pThread -> nPid,  pItem -> sKey) ; 
        *pData = pItem -> xData ;
        if (pItem -> pProvider -> pProviderClass -> fGetContentIndex)
            if ((rc = (*pItem -> pProvider -> pProviderClass -> fGetContentIndex) (r, pItem -> pProvider, pData, TRUE)) != ok)
		{
                Cache_FreeContent (r, pItem)  ;
                return rc ;
		}
        }
    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Cache_GetContentSvIndex			                            */
/*                                                                          */
/*! 
*   \_en
*   Get the whole content as pointer, if not expired from the cache, otherwise ask
*   the provider to fetch it. This will also put a read lock on the
*   Cacheitem. When you are done with the content call ReleaseContent
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem which should be checked
*   @param  pData           Returns the content
*   @param  bUseCache       Set if the content should not recomputed
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Holt den gesamt Inhalt als Zeiger soweit nich abgelaufen aus dem Cache, ansonsten
*   wird der Provider beauftragt ihn einzulesen. Zusätzlich wird ein
*   Read Lock gesetzt. Nach der Bearbeitetung des Inhalts sollte deshalb
*   ReleaseLock zum freigeben aufgerufen werden.
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem welches überprüft werden soll
*   @param  pData           Liefert den Inhalt
*   @param  bUseCache       Gesetzt wenn der Inhalt nicht neu berechnet werden soll
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



int Cache_GetContentSvIndex   (/*in*/ req *             r,
                             /*in*/ tCacheItem        *pItem,
                             /*in*/ SV * *            pSVData,
                             /*in*/ tIndex *          pData,
                             /*in*/ bool              bUseCache) 

    {
    int rc ;
    bool bUpdate = FALSE ;

    if (!bUseCache && (Cache_IsExpired (r, pItem, pItem -> nLastUpdated)))
        {
        pItem -> xData = 0 ;
        pItem -> pSVData = NULL ;
        }
    if (!pItem -> xData)
        {
        if (r -> Component.Config.bDebug & dbgCache)
            lprintf (r -> pApp,  "[%d]CACHE: %s get from provider\n", r -> pThread -> nPid,  pItem -> sKey) ; 
        if (pItem -> pProvider -> pProviderClass -> fGetContentIndex)
            if ((rc = (*pItem -> pProvider -> pProviderClass -> fGetContentIndex) (r, pItem -> pProvider, pData, FALSE)) != ok)
		{
                Cache_FreeContent (r, pItem)  ;
                return rc ;
		}
        pItem -> xData = *pData ;
        bUpdate = TRUE ;
        }
    else
        {
        *pData = pItem -> xData ;
        if (pItem -> pProvider -> pProviderClass -> fGetContentIndex)
            if ((rc = (*pItem -> pProvider -> pProviderClass -> fGetContentIndex) (r, pItem -> pProvider, pData, TRUE)) != ok)
		{
                Cache_FreeContent (r, pItem)  ;
                return rc ;
		}
        }

    if (!pItem -> pSVData)
        {
        if ((r -> Component.Config.bDebug & dbgCache) && !bUpdate)
            lprintf (r -> pApp,  "[%d]CACHE: %s get from provider\n", r -> pThread -> nPid,  pItem -> sKey) ; 
        if (pItem -> pProvider -> pProviderClass -> fGetContentSV)
            if ((rc = (*pItem -> pProvider -> pProviderClass -> fGetContentSV) (r, pItem -> pProvider, pSVData, FALSE)) != ok)
		{
                Cache_FreeContent (r, pItem)  ;
                return rc ;
		}
        pItem -> pSVData = *pSVData ;
        bUpdate = TRUE ;
        }
    else
        *pSVData = pItem -> pSVData ;

    if (bUpdate)
        {
        Cache_SetNotExpired (r, pItem) ;
        }
    else
        {
        if (r -> Component.Config.bDebug & dbgCache)
            lprintf (r -> pApp,  "[%d]CACHE: %s taken from cache\n", r -> pThread -> nPid,  pItem -> sKey) ; 
        }
    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Cache_ReleaseContent   				                    */
/*                                                                          */
/*! 
*   \_en
*   Removes the read and/or write lock from the content.
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem which should be checked
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Gibt den Read und/oder Write Lock wieder frei.
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem welches überprüft werden soll
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



int Cache_ReleaseContent        (/*in*/ req *             r,
                                 /*in*/ tCacheItem        *pItem)

    {
    /* locking not yet implemented */
    tCacheItem * pSubItem ;
    int          i ;
    int		 numItems = pItem -> pDependsOn?ArrayGetSize (r -> pApp, pItem -> pDependsOn):0 ;

    if (!pItem -> bCache)
        Cache_FreeContent (r, pItem) ;

    for (i = 0; i < numItems; i++)
	{
	pSubItem = pItem -> pDependsOn[i] ;
	Cache_ReleaseContent (r, pSubItem) ;
	}

    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* Cache_FreeContent   				                            */
/*                                                                          */
/*! 
*   \_en
*   Free the cached data
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Gibt die gecachten Daten frei
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



int Cache_FreeContent           (/*in*/ req *             r,
                                 /*in*/ tCacheItem        *pItem)

    {
    epTHX_
    int rc ;
    
    if ((r -> Component.Config.bDebug & dbgCache) && (pItem -> pSVData || pItem -> pData || pItem -> xData))
        lprintf (r -> pApp,  "[%d]CACHE: Free content for %s\n", r -> pThread -> nPid, pItem -> sKey) ; 

    if (pItem -> pProvider -> pProviderClass -> fFreeContent)
        if ((rc = (*pItem -> pProvider -> pProviderClass -> fFreeContent) (r, pItem)) != ok)
            return rc ;
    
    if (pItem -> pSVData)
        {
        SvREFCNT_dec (pItem -> pSVData) ;
        pItem -> pSVData = NULL ;
        }
    pItem -> pData = NULL ;
    pItem -> xData = 0 ;

    return ok ;
    }


