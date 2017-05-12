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
#   $Id: eppublic.h 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################*/

struct tThreadData  ;
struct tApp  ;

int embperl_Init        (pTHX_
                         SV *          pApacheSrvSV,
                         SV *          pPerlParam,
                         server_rec *  ap_s) ;

#ifdef APACHE
int embperl_ApInitDone (void) ;
#else
#define embperl_ApInitDone 1 ;
#endif

int     embperl_InitRequest ( pTHX_     
                              SV *             pApacheReqSV,
                              SV *             pPerlParam,
                              tReq * *         ppReq) ;

int     embperl_InitRequestComponent ( pTHX_     
                              SV *             pApacheReqSV,
                              SV *             pPerlParam,
                              tReq * *         ppReq) ;

int     embperl_InitAppForRequest (/*in*/ pTHX_
                             /*in*/ SV *             pApacheReqSV,
                             /*in*/ SV *             pPerlParam,
                             /*out*/struct tThreadData * *  ppThread,
                             /*out*/struct tApp * *         ppApp,
                             /*out*/tApacheDirConfig * * ppApacheCfg) ;

int     embperl_RunRequest (tReq * r) ;
int     embperl_CleanupRequest (tReq *  r) ;

int     embperl_ExecuteRequest  (pTHX_
                                 SV *             pApacheReqSV,
                                 SV *             pPerlParam) ;
int     embperl_SetupComponent  (tReq *                 r,
                                SV *                   pPerlParam,
                                tComponent * *         ppComponent) ;
int     embperl_RunComponent(tComponent *          c) ;

int     embperl_CleanupComponent  (tComponent *          c) ;

int     embperl_ExecuteComponent(tReq *           r,
                                 SV *             pPerlParam) ;


const char * embperl_GetText (tReq *       r, 
                        const char * sMsgId) ;

char * embperl_GetDateTime (char * sResult) ;


#define ERRDATLEN 4096

#ifdef WIN32
#define pid_t int
#endif

