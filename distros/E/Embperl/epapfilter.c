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
#   $Id: epapfilter.c 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################*/


#include "ep.h"

#ifdef APACHE2

#include <util_filter.h>
#include <http_request.h>

/* ------------------------------------------------------------------------ */
/*                                                                          */
/*!         Provider that acts as Apache output filter                      */
/*                                                                          */

typedef struct tProviderApOutFilter
    {
    tProvider           Provider ;
    const char *        sURI ;         /**< Filename */
    } tProviderApOutFilter ;


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderApOutFilter_New    					            */
/*                                                                          */
/*! 
*   \_en
*   Creates a new Apache Output Filter provider and fills it with data from the hash pParam
*   The resulting provider is put into the cache structure
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem which holds the output of the provider
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash of this Providers
*                               subreq          URI
*   @param  pParam          All Parameters 
*   @param  nParamIndex       If pParam is an AV, this parameter gives the index into the Array
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Erzeugt einen neuen Apache Output Filter Provider. Der Zeiger
*   auf den resultierenden Provider wird in die Cache Struktur eingefügt
*   
*   @param  r               Embperl request record
*   @param  pItem           CacheItem welches die Ausgabe des Providers 
*                           speichert
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash dieses Providers
*                               subreq          URI
*   @param  pParam          Parameter insgesamt
*   @param  nParamIndex       Wenn pParam ein AV ist, gibt dieser Parameter den Index an
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

static int ProviderApOutFilter_New (/*in*/ req *              r,
                             /*in*/ tCacheItem *       pItem,
                             /*in*/ tProviderClass *   pProviderClass,
                             /*in*/ HV *               pProviderParam,
                             /*in*/ SV *               pParam,
                             /*in*/ IV                 nParamIndex)


    {
    epTHX_
    int          rc ;
    tProviderApOutFilter * pNew  ;
    char *          sURI ;
    
    if ((rc = Provider_New (r, sizeof(tProviderApOutFilter), pItem, pProviderClass, pProviderParam)) != ok)
        return rc ;

    pNew = (tProviderApOutFilter *)pItem -> pProvider ;

    sURI = GetHashValueStr (aTHX_ pProviderParam, "subreq",  r -> Component.Param.sSubreq) ;
    pNew -> sURI = sURI ;
    if (!pNew -> sURI)
        {
        strncpy (r -> errdat1, sURI, sizeof (r -> errdat1) - 1) ;
        return rcNotFound ;
        }

    return ok ;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderApOutFilter_AppendKey    				            */
/*                                                                          */
/*! 
*   \_en
*   Append it's key to the keystring. If it depends on anything it must 
*   call Cache_AppendKey for any dependency.
*   The Apache Output Filter provider appends the URI
*   
*   @param  r               Embperl request record
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash of this Providers
*                               subreq          URI
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
*   Der Apache Output Filter hängt die URI an.
*   
*   @param  r               Embperl request record
*   @param  pProviderClass  Provider class record
*   @param  pProviderParam  Parameter Hash dieses Providers
*                               subreq          URI
*   @param  pParam          Parameter insgesamt
*   @param  nParamIndex       Wenn pParam ein AV ist, gibt dieser Parameter den Index an
*   @param  pKey            Schlüssel zu welchem hinzugefügt wird
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

static int ProviderApOutFilter_AppendKey (/*in*/ req *              r,
                                   /*in*/ tProviderClass *   pProviderClass,
                                   /*in*/ HV *               pProviderParam,
                                   /*in*/ SV *               pParam,
                                   /*in*/ IV                 nParamIndex,
                                   /*i/o*/ SV *              pKey)
    {
    epTHX_
    const char * sURI  ;

    sURI = GetHashValueStr (aTHX_ pProviderParam, "subreq",  r -> Component.Param.sSubreq) ;
    if (!sURI)
        {
        strncpy (r -> errdat1, sURI, sizeof (r -> errdat1) - 1) ;
        return rcNotFound ;
        }
    
    sv_catpvf (pKey, "*subreq:%s", sURI) ;
    return ok ;
    }

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderApOutFilter_Callback    				            */
/*                                                                          */
/*! 
*   \_en
*   This callback is call from Apache when any output is available.
*   It gather the output in one SV.
*   
*   @param  f               Apache Filter Record
*   @param  bb              Apache Bucket Brigade
*   @return                 error code
*   \endif                                                                       
*
*   \_de									   
*   Dieses Callback wird von Apache aufgerufen, wenn Daten zur verfügung stehen.
*   Alle Daten werden in einem SV gesammelt.
*   
*   @param  f               Apache Filter Record
*   @param  bb              Apache Bucket Brigade
*   @return                 error code
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

struct tProviderApOutFilter_CallbackData
    {
    tReq *      pReq ;
    SV *        pData ;
    } ;


static apr_status_t ProviderApOutFilter_Callback(ap_filter_t *f, apr_bucket_brigade *bb)
    {
    /*request_rec *ap_r = f->r;*/
    struct tProviderApOutFilter_CallbackData * ctx = (struct tProviderApOutFilter_CallbackData *)(f->ctx);
    tReq * r = ctx -> pReq ;
    apr_bucket *b;
    apr_size_t len;
    const char *data;
    apr_status_t rv;
    char buf[4096];
    epTHX_


    //APR_BRIGADE_FOREACH(b, bb) 
    for (b = APR_BRIGADE_FIRST(bb);
         b != APR_BRIGADE_SENTINEL(bb);
         b = APR_BUCKET_NEXT(b)) 
        {
        /* APR_BUCKET_IS_EOS(b) does give undefined symbol, when running outside of Apache */
        /* if (APR_BUCKET_IS_EOS(b)) */
        if (strcmp (b -> type -> name, "EOS") == 0)
            {
            break;
            }

        rv = apr_bucket_read(b, &data, &len, APR_BLOCK_READ);
        if (rv != APR_SUCCESS) 
            {
            sprintf (buf, "%d", rv) ;
            LogErrorParam (r -> pApp, rcApacheErr, buf, "apr_bucket_read()");
            return rv;
            }

        if (len > 0)
            {
            if (!ctx -> pData)
                ctx -> pData = newSV(len) ;
            sv_catpvn (ctx -> pData, data, len) ;
            }
        }

    apr_brigade_destroy(bb);

    return APR_SUCCESS;
    }


/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ProviderApOutFilter_GetContentSV  				            */
/*                                                                          */
/*! 
*   \_en
*   Get the whole content from the provider. 
*   The Apache Output Filter provider starts a subreqest and reads the 
*   whole result into memory
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
*   Der Apache Output Filter Provider started einen Sub-Request und
*   ließt das komplette Ergebnis in den Speicher
*   
*   
*   @param  r               Embperl request record
*   @param  pProvider       The provider record
*   @param  pData           Liefert den Inhalt
*   @param  bUseCache       Gesetzt wenn der Inhalt nicht neu berechnet werden soll
*   @return                 Fehlercode
*   \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



static int ProviderApOutFilter_GetContentSV (/*in*/ req *             r,
                             /*in*/ tProvider *     pProvider,
                             /*in*/ SV * *              pData,
                             /*in*/ bool                bUseCache)

    {
    epTHX_
    int rc = ok ;
    char * sURI ;
    request_rec *rr = NULL;
    struct tProviderApOutFilter_CallbackData ctx ;
    ap_filter_rec_t frec ;
    ap_filter_t filter ;

    ctx.pReq    = r ;
    ctx.pData   = NULL ;
    
    memset (&frec, 0, sizeof(frec)) ;
    frec.name = "Embperl_ProviderApOutFilter" ;
    frec.filter_func.out_func = &ProviderApOutFilter_Callback ;
    frec.next        = NULL ;
    frec.ftype       = AP_FTYPE_RESOURCE ;
        
    filter.frec = &frec ;
    filter.ctx  = &ctx ;
    filter.next = NULL ;
    filter.r    = r -> pApacheReq ;
    filter.c    = filter.r -> connection ;


    sURI = r -> Component.sSourcefile = (char *)((tProviderApOutFilter *)pProvider) -> sURI ;

    if (!bUseCache)
        {
        if (strncmp(sURI, "http://", 7) == 0 || strncmp(sURI, "ftp://", 7) == 0)
            rr = ap_sub_req_lookup_file(apr_pstrcat (r -> pApacheReq -> pool, "proxy:", sURI, NULL), r -> pApacheReq, &filter);
        else
            rr = ap_sub_req_lookup_uri(sURI, r -> pApacheReq, &filter);

        if (!rr || rr->status != HTTP_OK) 
            {
            rc = rr->status ;
            strncpy (r -> errdat1, r -> Component.sSourcefile, sizeof (r -> errdat1)) ;
            return rr -> status ;
            }

        rc = ap_run_sub_req(rr) ;

        if (rc || rr->status != HTTP_OK) 
            {
            if (rc == 0)
                {
                strncpy (r -> errdat1, r -> Component.sSourcefile, sizeof (r -> errdat1)) ;
                return rr -> status ;
                }
            else
                {
                sprintf (r -> errdat1, "%d (status=%d)", rc, rr -> status) ;
                strncpy (r -> errdat2, r -> Component.sSourcefile, sizeof (r -> errdat2)) ;
                return rc;
                }
            }
            
        if (rr != NULL) 
            ap_destroy_sub_req(rr);

   
        if (rc == ok)
            {
            /* SvREFCNT_inc (ctx.pData) ; */
            if (ctx.pData)
                {
                r -> Component.pBuf = SvPVX (ctx.pData) ;
                r -> Component.pEndPos = r -> Component.pBuf + SvLEN(ctx.pData) ;
                r -> Component.pCurrPos = r -> Component.pBuf ;
                }
            *pData = ctx.pData ;
            }
        }

    return rc ;
    }


/* ------------------------------------------------------------------------ */


tProviderClass ProviderClassApOutFilter = 
    {   
    "text/*", 
    &ProviderApOutFilter_New, 
    &ProviderApOutFilter_AppendKey, 
    NULL,
    &ProviderApOutFilter_GetContentSV,
    NULL,
    NULL,
    NULL,
    } ;

/* ------------------------------------------------------------------------ */
/*                                                                          */
/* ApFilter_Init      					                    */
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

int ApFilter_Init (/*in*/ tApp * a)

    {
    Cache_AddProviderClass ("apoutfilter",      &ProviderClassApOutFilter) ;

    return ok ;
    }



#endif /* APACHE2 */

