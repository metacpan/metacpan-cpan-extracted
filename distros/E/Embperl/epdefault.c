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
#   $Id: epdefault.c 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################*/



/*---------------------------------------------------------------------------
* embperl_DefaultAppConfig
*/
/*!
*
* \_en									   
* initialze Config defaults
* \endif                                                                       
*
* \_de									   
* Initialisiert Config Defaults
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */


static void embperl_DefaultAppConfig (/*in*/ tAppConfig  *pCfg) 

    {
    pCfg -> sAppName    = "Embperl" ;
    pCfg -> sCookieName = "EMBPERL_UID" ;
    pCfg -> sSessionHandlerClass = "Apache::SessionX" ;
#ifdef WIN32
    pCfg -> sLog        = "\\embperl.log" ;
#else
    pCfg -> sLog        = "/tmp/embperl.log" ;
#endif
    pCfg -> bDebug      = dbgNone ;
    pCfg -> nMailErrorsResetTime = 60 ;
    pCfg -> nMailErrorsResendTime = 60 * 15 ;
    }



    
/*---------------------------------------------------------------------------
* embperl_DefaultReqConfig
*/
/*!
*
* \_en									   
* initialze ReqConfig defaults
* \endif                                                                       
*
* \_de									   
* Initialisiert ReqConfig Defaults
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */


static void embperl_DefaultReqConfig (/*in*/ tReqConfig  *pCfg) 

    {
    pCfg -> cMultFieldSep = '\t' ;
    pCfg -> nSessionMode = smodeUDatCookie ;
    pCfg -> nOutputEscCharset = ocharsetLatin1 ;
    }



/*---------------------------------------------------------------------------
* embperl_DefaultComponentConfig
*/
/*!
*
* \_en									   
* initialze Config defaults
* \endif                                                                       
*
* \_de									   
* Initialisiert Config Defaults
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */


static void embperl_DefaultComponentConfig (/*in*/ tComponentConfig  *pCfg) 

    {
    pCfg -> bDebug = dbgNone ;
    /* pCfg -> bOptions = optRawInput | optAllFormData ; */
    pCfg -> nEscMode = escStd ;
    pCfg -> bCacheKeyOptions = ckoptDefault ;
    pCfg -> sSyntax = "Embperl" ;
    pCfg -> sInputCharset = "iso-8859-1" ;
#ifdef LIBXSLT
    pCfg -> sXsltproc = "libxslt" ;
#else
#ifdef XALAN
    pCfg -> sXsltproc = "xalan" ;
#endif
#endif
    }
