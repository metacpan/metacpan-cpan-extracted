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
#   $Id: epinit.c 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################*/


#include "ep.h"
#include "epmacro.h"
#include "xs/ep_xs_typedefs.h"
#include "xs/ep_xs_sv_convert.h"

#include "epdefault.c"

SV   ep_sv_undef ; /* we need our own undef value, because when 
                      storing a PL_sv_undef with Perl 5.8.0 in a hash
                      Perl takes it as a placeholder and pretents it isn't there :-( */

#ifndef PERL_IMPLICIT_CONTEXT

SV * embperl_ThreadDataRV ;

#define SINGLETHREAD

#endif



#define OPTPREFIX               EMBPERL_PACKAGE_STR

#define EMBPERL_APP_PACKAGE     EMBPERL_PACKAGE_STR"::Application"
#define EMBPERL_REQ_PACKAGE     EMBPERL_PACKAGE_STR"::Req"
#define EMBPERL_THREAD_PACKAGE  EMBPERL_PACKAGE_STR"::Thread"

#define FDAT_NAME               "fdat"
#define EMBPERL_FDAT_NAME       EMBPERL_PACKAGE_STR"::"FDAT_NAME
#define EMBPERL_SPLIFDAT_NAME   EMBPERL_PACKAGE_STR"::splitfdat"
#define FFLD_NAME               "ffld"
#define EMBPERL_FFLD_NAME       EMBPERL_PACKAGE_STR"::"FFLD_NAME
#define EMBPERL_HDR_NAME        EMBPERL_PACKAGE_STR"::http_headers_out"
#define EMBPERL_IDAT_NAME       EMBPERL_PACKAGE_STR"::idat"
#define PARAM_NAME              "param"
#define EMBPERL_PARAM_NAME      EMBPERL_PACKAGE_STR"::"PARAM_NAME
#define EMBPERL_REQ_NAME        EMBPERL_PACKAGE_STR"::req"
#define EMBPERL_APP_NAME        EMBPERL_PACKAGE_STR"::app"
#define EMBPERL_ENV_NAME        "ENV"

#define EMBPERL_EscMode_NAME    EMBPERL_PACKAGE_STR"::escmode"
#define EMBPERL_CurrNode_NAME    EMBPERL_PACKAGE_STR"::_ep_node"


static int  bInitDone = 0 ; /* c part is already initialized */
static int  nRequestCount = 1 ;
static perl_mutex RequestCountMutex ;

static tMemPool * pMainPool ;

static tReq NullRequest ; /* a request object with all zero, to point for deleted objects */

/* -------------------------------------------------------------------------
*
* Options lists for configuration 
*
*/

#define OPTION(a,b) { #a, a}, { #b, a},

tOptionEntry OptionsDEBUG[] =
    {
    OPTION(dbgStd, std)
    OPTION(dbgMem,Mem)
    OPTION(dbgEval,Eval)
    OPTION(dbgCmd,Cmd)
    OPTION(dbgEnv,Env)
    OPTION(dbgForm,Form)
    OPTION(dbgTab,Tab)
    OPTION(dbgInput,Input)
    OPTION(dbgFlushOutput,FlushOutput)
    OPTION(dbgFlushLog,FlushLog)
    OPTION(dbgAllCmds,AllCmds)
    OPTION(dbgSource,Source)
    OPTION(dbgFunc,Func)
    OPTION(dbgLogLink,LogLink)
    OPTION(dbgDefEval,DefEval)
    OPTION(dbgOutput,Output)
    OPTION(dbgDOM,DOM)
    OPTION(dbgRun,Run)
    OPTION(dbgHeadersIn,HeadersIn)
    OPTION(dbgShowCleanup,ShowCleanup)
    OPTION(dbgProfile,Profile)
    OPTION(dbgSession,Session)
    OPTION(dbgImport,Import)
    OPTION(dbgBuildToken,BuildToken)
    OPTION(dbgParse,Parse)
    OPTION(dbgObjectSearch,ObjectSearch)
    OPTION(dbgCache,Cache)
    OPTION(dbgCompile,Compile)
    OPTION(dbgXML,XML)
    OPTION(dbgXSLT,XSLT)
    OPTION(dbgCheckpoint,Checkpoint)
    OPTION(dbgAll,All)
    } ;

#define OPTION_OPT(a) OPTION(opt##a, a) 

tOptionEntry OptionsOPTIONS[] =
    {
    OPTION_OPT(DisableVarCleanup)
    OPTION_OPT(DisableEmbperlErrorPage)
    OPTION_OPT(SafeNamespace)
    OPTION_OPT(OpcodeMask)
    OPTION_OPT(RawInput)
    OPTION_OPT(SendHttpHeader)
    OPTION_OPT(EarlyHttpHeader)
    OPTION_OPT(DisableChdir)
    OPTION_OPT(DisableFormData)
    OPTION_OPT(DisableHtmlScan)
    OPTION_OPT(DisableInputScan)
    OPTION_OPT(DisableTableScan)
    OPTION_OPT(DisableMetaScan)
    OPTION_OPT(AllFormData)
    OPTION_OPT(RedirectStdout)
    OPTION_OPT(UndefToEmptyValue)
    OPTION_OPT(NoHiddenEmptyValue)
    OPTION_OPT(AllowZeroFilesize)
    OPTION_OPT(ReturnError)
    OPTION_OPT(KeepSrcInMemory)
    OPTION_OPT(KeepSpaces)
    OPTION_OPT(OpenLogEarly)
    OPTION_OPT(NoUncloseWarn)
    OPTION_OPT(DisableSelectScan)
    OPTION_OPT(ShowBacktrace)
    OPTION_OPT(EnableChdir)
    OPTION_OPT(FormDataNoUtf8)
    } ;


#define OPTION_ESC(a) OPTION(esc##a, a) 

tOptionEntry OptionsESCMODE[] =
    {
    OPTION_ESC(None)
    OPTION_ESC(Html)
    OPTION_ESC(Url)
    OPTION_ESC(Escape)
    OPTION_ESC(XML)
    OPTION_ESC(Std)
    } ;


#define OPTION_IESC(a) OPTION(iesc##a, a) 

tOptionEntry OptionsINPUT_ESCMODE[] =
    {
    OPTION_IESC(None)
    OPTION_IESC(Html)
    OPTION_IESC(Url)
    OPTION_IESC(RemoveTags)
    } ;

#define OPTION_OMODE(a) OPTION(omode##a, a) 

tOptionEntry OptionsOUTPUT_MODE[] =
    {
    OPTION_OMODE(Html)
    OPTION_OMODE(Xml)
    } ;

#define OPTION_OCHARSET(a) OPTION(ocharset##a, a) 

tOptionEntry OptionsOUTPUT_ESC_CHARSET[] =
    {
    OPTION_OCHARSET(Utf8)
    OPTION_OCHARSET(Latin1)
    OPTION_OCHARSET(Latin2)
    } ;

#define OPTION_SMODE(a) OPTION(smode##a, a) 

tOptionEntry OptionsSESSION_MODE[] =
    {
    OPTION_SMODE(None)
    OPTION_SMODE(UDatCookie)
    OPTION_SMODE(UDatParam)
    OPTION_SMODE(UDatUrl)
    OPTION_SMODE(SDatParam)
    } ;


/*---------------------------------------------------------------------------
* embperl_SetupThread
*/
/*!
*
* \_en									   
* Setup an thread object. Either take an existing one, if this thread
* already has a azocitaed object or create a new one.
*                                                                          
* \endif                                                                       
*
* \_de									   
* Initialisiert ein Threadobjekt. Ist dem Thread schon ein Objekt zugeorndet
* wird das bestehende genutzt, ansonsten ein neues zur?ck geliefert.
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



int    embperl_SetupThread  (/*in*/ pTHX_
                             /*out*/tThreadData * *  ppThread)


    {
    tThreadData * pThread ;
    SV * *        ppSV ;

#ifdef SINGLETHREAD
    ppSV = &embperl_ThreadDataRV ;
#else
    ppSV = hv_fetch (PL_modglobal, "Embperl::Thread", 15, 1) ;
#endif
    if (!ppSV)
	{
	LogErrorParam (NULL, rcHashError, "PL_modglobal (key=Embperl::Thread)", "") ;
        return rcHashError ;
	}
	
    if (!*ppSV || !SvOK(*ppSV))
        {
        SV * pThreadRV ;
        SV * pThreadSV ;
        HV * pStash = gv_stashpv (EMBPERL_PACKAGE_STR, 1) ;
        tMemPool * pPool = ep_make_sub_pool (pMainPool) ;

        epxs_Embperl__Thread_create_obj(pThread,pThreadSV,pThreadRV,ep_palloc(pPool,sizeof(*pThread))) ;
#ifdef PERL_IMPLICIT_CONTEXT
        pThread -> pPerlTHX = aTHX ;
#endif
        pThread -> pPool         = pPool ;
        pThread -> pMainPool     = pMainPool ;
        pThread -> nPid          = getpid () ; 
        pThread -> pApplications = newHV () ;
        pThread -> pFormHash     = perl_get_hv (EMBPERL_FDAT_NAME, GV_ADD | GV_ADDMULTI) ;
        SvREFCNT_inc(pThread -> pFormHash) ;
        pThread -> pFormHashGV   = *((GV **)hv_fetch    (pStash, FDAT_NAME, sizeof (FDAT_NAME) - 1, 0)) ;
        pThread -> pFormSplitHash = perl_get_hv (EMBPERL_SPLIFDAT_NAME,  GV_ADD | GV_ADDMULTI) ;
        SvREFCNT_inc(pThread -> pFormSplitHash) ;
        pThread -> pFormArray    = perl_get_av (EMBPERL_FFLD_NAME,  GV_ADD | GV_ADDMULTI) ;
        SvREFCNT_inc(pThread -> pFormArray) ;
        pThread -> pFormArrayGV  = *((GV **)hv_fetch    (pStash, FFLD_NAME, sizeof (FFLD_NAME) - 1, 0)) ;
        pThread -> pHeaderHash   = perl_get_hv (EMBPERL_HDR_NAME,  GV_ADD | GV_ADDMULTI) ;
        SvREFCNT_inc(pThread -> pHeaderHash) ;
        pThread -> pInputHash    = perl_get_hv (EMBPERL_IDAT_NAME,  GV_ADD | GV_ADDMULTI) ;
        SvREFCNT_inc(pThread -> pInputHash) ;
#ifdef DMALLOC
        pThread -> pEnvHash      = Perl_get_hv(aTHX_ EMBPERL_ENV_NAME,  GV_ADD | GV_ADDMULTI) ;
#else
        pThread -> pEnvHash      = perl_get_hv (EMBPERL_ENV_NAME,  GV_ADD | GV_ADDMULTI) ;
#endif        
        SvREFCNT_inc(pThread -> pEnvHash) ;
        pThread -> pParamArray   = perl_get_av (EMBPERL_PARAM_NAME,  GV_ADD | GV_ADDMULTI) ;
        SvREFCNT_inc(pThread -> pParamArray) ;
        pThread -> pParamArrayGV = *((GV **)hv_fetch    (pStash, PARAM_NAME, sizeof (PARAM_NAME) - 1, 0)) ;
        pThread -> pReqRV        = perl_get_sv (EMBPERL_REQ_NAME,  GV_ADD | GV_ADDMULTI) ;
        SvREFCNT_inc(pThread -> pReqRV) ;
        pThread -> pAppRV        = perl_get_sv (EMBPERL_APP_NAME,  GV_ADD | GV_ADDMULTI) ;
        SvREFCNT_inc(pThread -> pAppRV) ;
        *ppSV = pThreadRV ;
        }
    else
        {
        pThread = epxs_sv2_Embperl__Thread(*ppSV) ;
        }

    *ppThread = pThread ;
    return ok ;
    }



/*---------------------------------------------------------------------------
* embperl_GetThread
*/
/*!
*
* \_en									   
* Returns already has a azocitaed object thread object. The thread object
* must be setup before via embperl_SetupThread
* \endif                                                                       
*
* \_de									   
* Liefert das diesem Thread zugeordnete Thread-Objekt zur?ck. Das Objekt mu?
* vorher mittels embperl_SetupThread initialisiert worden sein.
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



tThreadData * embperl_GetThread  (/*in*/ pTHX)

    {    
    tThreadData * pThread ; 
    int           rc ;

    if ((rc = embperl_SetupThread (aTHX_ &pThread)) != ok)
        {
        LogError (NULL, rc) ;
        return NULL ;
        }

    return pThread ;
    }

/*---------------------------------------------------------------------------
* embperl_EndPass1
*/
/*!
*
* \_en									   
* Call when configuration pass 1 of apache is done.
* \endif                                                                       
*
* \_de									   
* Wird aufgerufen wenn Pass 1 des Einlesens der Konfiguration beendet ist.
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



int    embperl_EndPass1  (void)


    {
    tThreadData * pThread  ;
    dTHX ;
    pThread = embperl_GetThread  (aTHX) ;
    
    hv_clear (pThread -> pApplications) ;

    return ok ;
    }


/*---------------------------------------------------------------------------
* embperl_CreateSessionObject
*/
/*!
*
* \_en									   
* Creates a new session object.
*                                                                          
* \endif                                                                       
*
* \_de									   
* Erzeugt eine neues Sessionobjekt.
*                                                                          
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



static int embperl_CreateSessionObject(/*in*/ tApp *       a,
                                       /*in*/ HV *         pArgs,
                                       /*out*/ HV * *      ppHash,
                                       /*out*/ SV * *      ppObj)


    {
    epaTHX_
    dSP ;
    tAppConfig * pCfg = &a -> Config ;
    char *       sPackage = pCfg -> sSessionHandlerClass ;
    HV * pHash = newHV () ;
    SV * pTie = NULL  ;
    int n ;
    SV * pSVCode ;

    pSVCode = newSVpvf ("require %s", sPackage) ; 
    newSVpvf2(pSVCode) ;
    /* there is no c api to the require function, eval it... */
    perl_eval_sv(pSVCode, G_EVAL | G_DISCARD) ;
    SvREFCNT_dec(pSVCode);
    tainted = 0 ;

    if (SvTRUE (ERRSV))
	{
        STRLEN l ;
        if (strcmp (sPackage, "Apache::SessionX") != 0 ||
              GetHashValueStr (aTHX_ a -> pThread -> pEnvHash, "GATEWAY_INTERFACE", NULL))
            LogErrorParam (a, rcSetupSessionErr, SvPV (ERRSV, l), NULL) ;
        sv_setpv(ERRSV,"");
        return rcEvalErr ;
        }

    SPAGAIN;
    PUSHMARK(sp);
    XPUSHs(sv_2mortal(newSVpv(sPackage, 0))); 
    XPUSHs(&sv_undef); /* id */ 
    XPUSHs(sv_2mortal (newRV((SV *)pArgs))); 
    PUTBACK;                        
    n = perl_call_method ("TIEHASH", G_EVAL | G_SCALAR) ;
    SPAGAIN;
    if (n > 0)
        pTie = POPs ;
    PUTBACK;
    if (SvTRUE (ERRSV))
	{
        STRLEN l ;
        LogErrorParam (a, rcSetupSessionErr, SvPV (ERRSV, l), NULL) ;
        sv_setpv(ERRSV,"");
        return rcEvalErr ;
        }
    if (n == 0 || !SvROK(pTie))
        {
        LogErrorParam (a, rcSetupSessionErr, "TIEHASH didn't returns a hashref", sPackage) ;
        return rcNotHashRef ;
        }
    hv_magic(pHash, (GV *)pTie, 'P') ;

    *ppHash = pHash ;
    *ppObj  = SvREFCNT_inc(pTie) ;

    return ok ;
    }

/*---------------------------------------------------------------------------
* embperl_SetupSessionObjects
*/
/*!
*
* \_en									   
* Setup the session onbjects.
*                                                                          
* \endif                                                                       
*
* \_de									   
* Initialisiert neue Sessionobjekte.
*                                                                          
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



int    embperl_SetupSessionObjects    (/*in*/ tApp *       a)


    {
    epaTHX_
    int   rc ;
    SV *  pStore ;
    SV ** ppStore ;
    SV *  pLocker ;
    SV ** ppLocker ;
    SV *  pSerializer ;
    SV ** ppSerializer ;
    SV *  pGenerator ;
    SV ** ppGenerator ;
    tAppConfig * pCfg = &a -> Config ;
    HV *  pArgs = pCfg -> pSessionArgs ;
    HV *  pArgs1 ;
    HV *  pArgs2 ;
    HV *  pArgs3 ;
    dSP ;

    
    if (strcmp (pCfg -> sSessionHandlerClass, "no") == 0)
        return ok ;

    if (!pArgs)
        pCfg ->  pSessionArgs = pArgs = newHV() ;
    
    if (pCfg ->  pSessionClasses)
        {
        if ((ppStore = av_fetch (pCfg ->  pSessionClasses, 0, 0)))
            pStore = SvREFCNT_inc(*ppStore) ;
        else
            pStore = newSVpv("File", 4) ;
        hv_store (pArgs, "Store", 5, pStore, 0) ;

        if ((ppLocker = av_fetch (pCfg ->  pSessionClasses, 1, 0)))
            pLocker = SvREFCNT_inc(*ppLocker) ;
        else
            pLocker = newSVpv("Null", 4) ;
        hv_store (pArgs, "Lock", 4, pLocker, 0) ;

        if ((ppSerializer = av_fetch (pCfg ->  pSessionClasses, 2, 0)))
            pSerializer = SvREFCNT_inc(*ppSerializer) ;
        else
            pSerializer = newSVpv("Storable", 8) ;
        hv_store (pArgs, "Serialize", 9, pSerializer, 0) ;

        if ((ppGenerator = av_fetch (pCfg ->  pSessionClasses, 3, 0)))
            pGenerator = SvREFCNT_inc(*ppGenerator) ;
        else
            pGenerator = newSVpv("MD5", 3) ;
        hv_store (pArgs, "Generate", 8, pGenerator, 0) ;
        }
    else
        {
        /* workaround for perl bug in newHVhv when to less hash entries */
        hv_store (pArgs, "__dummy1__", 10, newSViv (1), 0) ;
        hv_store (pArgs, "__dummy2__", 10, newSViv (1), 0) ;
        hv_store (pArgs, "__dummy3__", 10, newSViv (1), 0) ;
        hv_store (pArgs, "__dummy4__", 10, newSViv (1), 0) ;
        }

    if (pCfg ->  sSessionConfig)
        hv_store (pArgs, "config", 5, newSVpv (pCfg ->  sSessionConfig, 0), 0) ;

    hv_store (pArgs, "lazy", 4, newSViv (1), 0) ;
    hv_store (pArgs, "create_unknown", 14, newSViv (1), 0) ;

    pArgs1 = newHVhv(pArgs) ;
    hv_store (pArgs1, "Transaction", 11, newSViv (1), 0) ;
    pArgs2 = newHVhv(pArgs) ;
    hv_store (pArgs2, "recreate_id", 11, newSViv (1), 0) ;
    pArgs3 = newHVhv(pArgs2) ;

    if ((rc = embperl_CreateSessionObject (a, pArgs1, &a -> pAppHash, &a -> pAppObj)) != ok)
        return rc ;

    SPAGAIN ;
    PUSHMARK(sp);
    XPUSHs(a -> pAppObj); 
    XPUSHs(sv_2mortal (newSVpv(a -> Config.sAppName, 0))); 
    PUTBACK;                        
    perl_call_method ("setidfrom", G_DISCARD) ;

    if ((rc = embperl_CreateSessionObject (a, pArgs2, &a -> pUserHash, &a -> pUserObj)) != ok)
        return rc ;

    hv_store (pArgs3, "newid", 5, newSViv (1), 0) ;

    if ((rc = embperl_CreateSessionObject (a, pArgs3, &a -> pStateHash, &a -> pStateObj)) != ok)
        return rc ;


    return ok ;
    }


/*---------------------------------------------------------------------------
* embperl_SetupApp
*/
/*!
*
* \_en									   
* Setup an application object. Either take an existing one, if the
* application is already created for that thread or create a new
* one.
*                                                                          
* @param   pThread          per thread data
* @param   pApacheCfg       apache configuration vector
* @param   pPerlParam       parameters passed from Perl
* \endif                                                                       
*
* \_de									   
* Initialisiert ein Applicationobjekt. Entweder wird ein bereits bestehendes
* benutzt, oder falls nicht vorhanden, ein neues erzeugt.
*                                                                          
* @param   pThread          per thread daten
* @param   pApacheCfg       apache Konfigurations Vector
* @param   pPerlParam       Parameter die von Perl aus ?bergeben wurden
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



int    embperl_SetupApp     (/*in*/ pTHX_
                             /*in*/ tThreadData *  pThread,
                             /*in*/ tApacheDirConfig * pApacheCfg,
                             /*in*/ SV *           pPerlParam,
                             /*out*/tApp * *       ppApp)


    {
    char * sAppName = NULL ;
    tApp * pApp = NULL ;
    HV * pParam = NULL ;


    if (pPerlParam && SvROK(pPerlParam))
        {
        pParam = (HV *)SvRV(pPerlParam) ;
        sAppName        = GetHashValueStr (aTHX_ pParam, "app_name", NULL) ;
        if (!sAppName) // backward compability to broken appname 
            sAppName        = GetHashValueStr (aTHX_ pParam, "appname", NULL) ;
        }

    if (!sAppName)
        {
#ifdef APACHE
        if (pApacheCfg)
            sAppName = embperl_GetApacheAppName (pApacheCfg) ;
        else
#endif
            sAppName = embperl_GetCGIAppName (pThread) ;
        }
    
    if (sAppName)
        pApp = (tApp * )GetHashValuePtr (NULL, pThread -> pApplications, sAppName, NULL) ;

  
    if (!pApp)
        {
        int  rc ;
        SV * pAppSV ;
        SV * pAppRV ;
        SV * pSV ;
        SV * pRV ;
        tAppConfig * pCfg ;
        
        tMemPool * pPool = ep_make_sub_pool (pThread -> pPool) ;

        
        epxs_Embperl__App_create_obj(pApp,pAppSV,pAppRV,ep_palloc(pPool,sizeof(*pApp))) ;
        epxs_Embperl__App__Config_create_obj(pCfg,pSV,pRV,&pApp -> Config) ;
#ifdef PERL_IMPLICIT_CONTEXT
        pApp -> pPerlTHX = aTHX ;
#endif
        pApp -> pPool         = pPool ;
        pCfg -> pPool         = pPool ;

#ifdef APACHE
        if (pApacheCfg)
            embperl_GetApacheAppConfig (pThread, pPool, pApacheCfg, &pApp -> Config) ;
        else
#endif
            {
            bool   bUseEnv = 0 ;
            bool   bUseRedirectEnv = 0 ;
            if (pParam)
                {
                bUseEnv         = (bool)GetHashValueInt (aTHX_ pParam, "use_env", 0) ;
                bUseRedirectEnv = (bool)GetHashValueInt (aTHX_ pParam, "use_redirect_env", 0) ;
                }

            embperl_GetCGIAppConfig (pThread, pPool, &pApp -> Config, bUseEnv, bUseRedirectEnv, 1) ;
            }

        SetHashValueInt (NULL, pThread -> pApplications, sAppName, (IV)pApp) ;
        
        pApp -> pThread = pThread ;

        if (pParam)
            Embperl__App__Config_new_init(aTHX_ &pApp -> Config, (SV *)pParam, 0) ;

        tainted = 0 ;

        if (pApp -> Config.sLog && pApp -> Config.sLog[0])
            {
            if ((rc = OpenLog (pApp)) != ok)
	        { 
                pApp -> Config.bDebug = 0 ; /* Turn debbuging off, only errors will go to stderr */
	        LogErrorParam (pApp, rc, pApp -> Config.sLog, Strerror(errno)) ;
	        }
            }

        if (pApp -> Config.sAppHandlerClass)
            {
            HV * stash = gv_stashpv(pApp -> Config.sAppHandlerClass, TRUE) ;
            sv_bless(pApp -> _perlsv, stash) ;
            }
        

        embperl_SetupSessionObjects (pApp) ;
        }

    sv_setsv(pThread -> pAppRV, pApp -> _perlsv) ;   
    
    *ppApp = pApp ;

    return ok ;
    }



static int notused ;

#if 0
INTMG (TabCount, pCurrReq -> TableStack.State.nCount, pCurrReq -> TableStack.State.nCountUsed, ;) 
INTMG (TabRow, pCurrReq -> TableStack.State.nRow, pCurrReq -> TableStack.State.nRowUsed, ;) 
INTMG (TabCol, pCurrReq -> TableStack.State.nCol, pCurrReq -> TableStack.State.nColUsed, ;) 
INTMG (TabMaxRow, pCurrReq -> nTabMaxRow, notused,  ;) 
INTMG (TabMaxCol, pCurrReq -> nTabMaxCol, notused, ;) 
INTMG (TabMode, pCurrReq -> nTabMode, notused, ;) 
#endif
INTMG_COMP (EscMode, Config.nEscMode, notused, NewEscMode (CurrReq, pSV)) 
#ifdef EP2
INTMGshort_COMP (CurrNode, xCurrNode) 
#endif

OPTMGRD_COMP (optDisableVarCleanup       , Config.bOptions) 
OPTMG_COMP    (optDisableEmbperlErrorPage, Config.bOptions) 
OPTMG_COMP    (optReturnError            , Config.bOptions) 
OPTMGRD_COMP (optSafeNamespace           , Config.bOptions) 
OPTMGRD_COMP (optOpcodeMask              , Config.bOptions) 
OPTMG_COMP    (optRawInput               , Config.bOptions) 
OPTMG_COMP    (optSendHttpHeader         , Config.bOptions) 
OPTMGRD_COMP (optDisableChdir            , Config.bOptions) 
OPTMG_COMP    (optDisableHtmlScan        , Config.bOptions) 
OPTMGRD_COMP (optEarlyHttpHeader         , Config.bOptions) 
OPTMGRD_COMP (optDisableFormData         , Config.bOptions) 
OPTMG_COMP    (optDisableInputScan       , Config.bOptions) 
OPTMG_COMP    (optDisableTableScan       , Config.bOptions) 
OPTMG_COMP    (optDisableMetaScan        , Config.bOptions) 
OPTMGRD_COMP (optAllFormData             , Config.bOptions) 
OPTMGRD_COMP (optRedirectStdout          , Config.bOptions) 
OPTMG_COMP    (optUndefToEmptyValue      , Config.bOptions) 
OPTMG_COMP    (optNoHiddenEmptyValue     , Config.bOptions) 
OPTMGRD_COMP (optAllowZeroFilesize       , Config.bOptions) 
OPTMGRD_COMP (optKeepSrcInMemory         , Config.bOptions) 
OPTMG_COMP    (optKeepSpaces             , Config.bOptions) 
OPTMG_COMP    (optOpenLogEarly           , Config.bOptions) 
OPTMG_COMP    (optNoUncloseWarn          , Config.bOptions) 


OPTMG_COMP    (dbgStd          , Config.bDebug) 
OPTMG_COMP    (dbgMem          , Config.bDebug) 
OPTMG_COMP    (dbgEval         , Config.bDebug) 
OPTMG_COMP    (dbgCmd          , Config.bDebug) 
OPTMG_COMP    (dbgEnv          , Config.bDebug) 
OPTMG_COMP    (dbgForm         , Config.bDebug) 
OPTMG_COMP    (dbgTab          , Config.bDebug) 
OPTMG_COMP    (dbgInput        , Config.bDebug) 
OPTMG_COMP    (dbgFlushOutput  , Config.bDebug) 
OPTMG_COMP    (dbgFlushLog     , Config.bDebug) 
OPTMG_COMP    (dbgAllCmds      , Config.bDebug) 
OPTMG_COMP    (dbgSource       , Config.bDebug) 
OPTMG_COMP    (dbgFunc         , Config.bDebug) 
OPTMG_COMP    (dbgLogLink      , Config.bDebug) 
OPTMG_COMP    (dbgDefEval      , Config.bDebug) 
OPTMG_COMP    (dbgHeadersIn    , Config.bDebug) 
OPTMG_COMP    (dbgShowCleanup  , Config.bDebug) 
OPTMG_COMP    (dbgProfile      , Config.bDebug) 
OPTMG_COMP    (dbgSession      , Config.bDebug) 
OPTMG_COMP    (dbgImport       , Config.bDebug) 


    
/* ---------------------------------------------------------------------------- */
/* add magic to integer var */
/* */
/* in  sVarName = Name of varibale */
/* in  pVirtTab = pointer to virtual table */
/* */
/* ---------------------------------------------------------------------------- */

static int AddMagic (/*i/o*/ tApp * a,
 		     /*in*/ char *     sVarName,
                     /*in*/ MGVTBL *   pVirtTab) 

    {
    SV * pSV ;
    struct magic * pMagic ;
    epaTHX ;

    EPENTRY (AddMagic) ;

    
    pSV = perl_get_sv (sVarName, TRUE) ;
    sv_magic (pSV, NULL, 0, sVarName, strlen (sVarName)) ;
    sv_setiv (pSV, 0) ;
    pMagic = mg_find (pSV, 0) ;

    if (pMagic)
        pMagic -> mg_virtual = pVirtTab ;
    else
        {
        LogError (NULL, rcMagicError) ;
        return 1 ;
        }

    perl_get_sv (sVarName, TRUE) ; /* avoid warning */

    return ok ;
    }

    
/* ---------------------------------------------------------------------------- */
/* add magic to array								*/
/*										*/
/* in  sVarName = Name of varibale						*/
/* in  pVirtTab = pointer to virtual table					*/
/*										*/
/* ---------------------------------------------------------------------------- */

int AddMagicAV (/*i/o*/ register req * r,
		/*in*/ char *     sVarName,
                /*in*/ MGVTBL *   pVirtTab) 

    {
    SV * pSV ;
    struct magic * pMagic ;
    epTHX ;

    EPENTRY (AddMagicAV) ;

    
    pSV = (SV *)perl_get_av (sVarName, TRUE) ;
    sv_magic (pSV, NULL, 'P', sVarName, strlen (sVarName)) ;
    pMagic = mg_find (pSV, 0) ;

    if (pMagic)
        pMagic -> mg_virtual = pVirtTab ;
    else
        {
        LogError (r, rcMagicError) ;
        return 1 ;
        }


    return ok ;
    }



/* ---------------------------------------------------------------------------- */
/* init embperl module */
/* */
/* in  nIOType = type of requested i/o */
/* */
/* ---------------------------------------------------------------------------- */

int embperl_Init        (/*in*/ pTHX_
                         /*in*/ SV *          pApacheSrvSV,
                         /*in*/ SV *          pPerlParam,
                         /*in*/ server_rec *  ap_s)

    {
    int     rc ;
    tThreadData * pThread ;
    tApp        * pApp ;
    tApacheDirConfig * pApacheCfg = NULL ;


    memcpy (&ep_sv_undef, &PL_sv_undef, sizeof (PL_sv_undef)) ;

#ifdef APACHE
    if (pApacheSrvSV && SvROK (pApacheSrvSV))
        {
        /* when running under mod_perl only register the module */
        /*  rest will be call from module initialzation when config has been read */
        ap_s = epxs_sv2_Apache__Server(pApacheSrvSV) ;
        embperl_ApacheAddModule () ;
#ifdef APACHE2
#else
        return ok ;
#endif
        }
#endif

    if (!pMainPool)
        pMainPool = ep_init_alloc() ;
    
    if ((rc = embperl_SetupThread (aTHX_ &pThread)) != ok)
        return rc ;
    
#ifdef APACHE
    if (ap_s)
        {
        embperl_GetApacheConfig (pThread, NULL, ap_s, &pApacheCfg) ;
        }
#endif

    if ((rc = embperl_SetupApp (aTHX_ pThread, pApacheCfg, pPerlParam, &pApp)) != ok)
        return rc ;
      


    ADDINTMG (EscMode) 
    ADDINTMG (CurrNode) 
    
    ADDOPTMG (optDisableVarCleanup      ) 
    ADDOPTMG (optDisableEmbperlErrorPage) 
    ADDOPTMG (optReturnError) 
    ADDOPTMG (optSafeNamespace          ) 
    ADDOPTMG (optOpcodeMask             ) 
    ADDOPTMG (optRawInput               ) 
    ADDOPTMG (optSendHttpHeader         ) 
    ADDOPTMG (optDisableChdir           ) 
    ADDOPTMG (optDisableHtmlScan        ) 
    ADDOPTMG (optEarlyHttpHeader        ) 
    ADDOPTMG (optDisableFormData        ) 
    ADDOPTMG (optDisableInputScan       ) 
    ADDOPTMG (optDisableTableScan       ) 
    ADDOPTMG (optDisableMetaScan        ) 
    ADDOPTMG (optAllFormData            ) 
    ADDOPTMG (optRedirectStdout         ) 
    ADDOPTMG (optUndefToEmptyValue      ) 
    ADDOPTMG (optNoHiddenEmptyValue     ) 
    ADDOPTMG (optAllowZeroFilesize      ) 
    ADDOPTMG (optKeepSrcInMemory       ) 
    ADDOPTMG (optKeepSpaces            ) 
    ADDOPTMG (optOpenLogEarly          ) 
    ADDOPTMG (optNoUncloseWarn         ) 

    ADDOPTMG   (dbgStd         ) 
    ADDOPTMG   (dbgMem         ) 
    ADDOPTMG   (dbgEval        ) 
    ADDOPTMG   (dbgCmd         ) 
    ADDOPTMG   (dbgEnv         ) 
    ADDOPTMG   (dbgForm        ) 
    ADDOPTMG   (dbgTab         ) 
    ADDOPTMG   (dbgInput       ) 
    ADDOPTMG   (dbgFlushOutput ) 
    ADDOPTMG   (dbgFlushLog    ) 
    ADDOPTMG   (dbgAllCmds     ) 
    ADDOPTMG   (dbgSource      ) 
    ADDOPTMG   (dbgFunc        ) 
    ADDOPTMG   (dbgLogLink     ) 
    ADDOPTMG   (dbgDefEval     ) 
    ADDOPTMG   (dbgHeadersIn   ) 
    ADDOPTMG   (dbgShowCleanup ) 
    ADDOPTMG   (dbgProfile     ) 
    ADDOPTMG   (dbgSession     ) 
    ADDOPTMG   (dbgImport      ) 
   
    if (bInitDone)
        return ok ; /* the rest needs to be done only once per process */

#if defined (_MDEBUG) && defined (WIN32)
    _CrtSetReportHook( EmbperlCRTDebugOutput );
#endif

    DomInit (pApp) ;
    Cache_Init (pApp) ;
    Provider_Init (pApp) ;
#ifdef APACHE2
    ApFilter_Init (pApp) ;
#endif
#ifdef XALAN
    embperl_Xalan_Init () ;
#endif
#ifdef LIBXSLT
    embperl_LibXSLT_Init () ;
#endif

    ep_create_mutex(RequestCountMutex) ;
    
    bInitDone = 1 ;

#ifdef APACHE
    {
    int preload = 1 ;
    if (ap_s)
        {
        module * m ;
        if ((m = ap_find_linked_module("mod_perl.c")))
            {
            if (m -> dynamic_load_handle)
                preload = 0 ;
            }
        }            
    if (preload)
        {
        dSP;
        PUSHMARK(sp) ;
        perl_call_pv ("Embperl::PreLoadFiles", G_DISCARD) ;
        }
    }    
#else
    {
    dSP;
    PUSHMARK(sp) ;
    perl_call_pv ("Embperl::PreLoadFiles", G_DISCARD) ;
    }
#endif    
    

    return rc ;
    }
    

/*---------------------------------------------------------------------------
* embperl_GetFormData
*/
/*!
*
* \_en									   
* Takes the given form data and put them in %fdat/@ffld
* \endif                                                                       
*
* \_de									   
* Nimmt die ?bergebenen Formulardaten und legt sie in %fdat/@ffld ab
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

static int embperl_GetFormData (/*i/o*/ register req * r,
			        /*in*/ char * pQueryString,
                                /*in*/ int    nLen)

    {
    int     num ;
    char *  p ;
    char *  pMem ;
    int     nVal ;
    int     nKey ;
    char *  pKey ;
    char *  pVal ;
    SV *    pSVV ;
    SV *    pSVK ;
    SV * *  ppSV ;

    AV *    pFormArray      = r -> pThread -> pFormArray ;
    HV *    pFormHash       = r -> pThread -> pFormHash ;
    bool    bAll            = (r -> Config.bOptions & optAllFormData) != 0 ;
    bool    bNoUtf8         = (r -> Config.bOptions & optFormDataNoUtf8) != 0 ;
    bool    bDebug          = (r -> Config.bDebug   & dbgForm) != 0 ;
    int     mayutf8  = 0 ;
    bool    bInValue = 0 ;
    char    c ;
    epTHX ;

    if (nLen == 0)
        return ok ;
    
    if ((pMem = _malloc (r, nLen + 4)) == NULL)
        return rcOutOfMemory ;

    p = pMem ;


    nKey = nVal = 0 ;
    pKey = pVal = p ;
    while (1)
        {
        switch (nLen > 0?*pQueryString:'\0')
            {
            case '+':
                pQueryString++ ;
                nLen-- ;
                *p++ = ' ' ;
                break ;
            
            case '%':
                pQueryString++ ;
                nLen-- ;
                num = 0 ;
                if (*pQueryString)
                    {
                    if (toupper (*pQueryString) >= 'A')
                        num += (toupper (*pQueryString) - 'A' + 10) << 4 ;
                    else
                        num += ((*pQueryString) - '0') << 4 ;
                    pQueryString++ ;
                    }
                if (*pQueryString)
                    {
                    if (toupper (*pQueryString) >= 'A')
                        num += (toupper (*pQueryString) - 'A' + 10) ;
                    else
                        num += ((*pQueryString) - '0') ;
                    pQueryString++ ;
                    nLen-- ;
                    }
                *p++ = num ;
                break ;
            case ';':
            case '&':
                bInValue = 0 ;
                pQueryString++ ;
                nLen-- ;
            case '\0':
                nVal = p - pVal ;
                *p++ = '\0' ;
            
                if (nKey > 0 && (nVal > 0 || (bAll)))
                    {
                    char * sid = NULL ;
                    sid = r -> pApp -> Config.sCookieName ;
		    if (sid)
			{ /* remove session id  */
			if (strncmp (pKey, sid, nKey) != 0)
			    sid = NULL ;
		        else
                            {
                            char * p = strchr(pVal, ':') ;
                            if (p && *p)
                                {
                                char * p2 = strchr(p+1, ':') ;
                                if (p2)
                                    *p2 = '\0' ;
                                r -> sSessionUserID = ep_pstrdup (r -> pPool, p + 1) ;
                                *p = '\0' ;
                                }
                            if (*pVal)
                                r -> sSessionStateID = ep_pstrdup (r -> pPool, pVal) ;
                            }
                        }

		    if (sid == NULL)
			{ /* field is not the session id */
			if (pVal > pKey)
			    pVal[-1] = '\0' ;
                    
			if ((ppSV = hv_fetch (pFormHash, pKey, nKey, 0)))
			    { /* Field exists already -> append separator and field value */
			    sv_catpvn (*ppSV, &r -> Config.cMultFieldSep , 1) ;
			    sv_catpvn (*ppSV, pVal, nVal) ;
			    }
			else
			    { /* New Field -> store it */
			    pSVV = newSVpv (pVal, nVal) ;
#ifdef UTF8_IS_START
			    if (mayutf8 && is_utf8_string((U8*)pVal, nVal))
			    	SvUTF8_on (pSVV) ;
#endif
			    if (hv_store (pFormHash, pKey, nKey, pSVV, 0) == NULL)
				{
				_free (r, pMem) ;
				strcpy (r -> errdat1, "fdat") ;
				return rcHashError ;
				}

			    pSVK = newSVpv (pKey, nKey) ;

			    av_push (pFormArray, pSVK) ;
			    }

                
			if (bDebug)
			    lprintf (r -> pApp,  "[%d]FORM: %s=%s\n", r -> pThread -> nPid, pKey, pVal) ; 
			}
                    }
                pKey = pVal = p ;
                nKey = nVal = 0 ;
		mayutf8 = 0 ;
				                
                if (*pQueryString == '\0')
                    {
                    _free (r, pMem) ;
                    return ok ;
                    }
                
                
                break ;
            case '=':
                if (!bInValue)
                    {
                    nKey = p - pKey ;
                    *p++ = r -> Config.cMultFieldSep ;
                    nVal = 0 ;
                    pVal = p ;
                    pQueryString++ ;
                    nLen-- ;
                    bInValue = 1 ;
                    break ;
                    }
                /* fall through */    
            default:
                c = *p++ = *pQueryString++ ;
                nLen-- ;
#ifdef UTF8_IS_START
                if (!bNoUtf8)
                    mayutf8 += UTF8_IS_START(c) ;
#endif
                break ;
            }
        }

    return ok ;
    }


/*---------------------------------------------------------------------------
* embperl_SetupFormData
*/
/*!
*
* \_en									   
* Get the posted form data and put them in %fdat/@ffld
* \endif                                                                       
*
* \_de									   
* Lie?t die formular daten ein und legt sie in %fdat/@ffld ab
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */


static int embperl_SetupFormData (/*i/o*/ register req * r)

    {
    epTHX_
    char *  p = NULL ;
    char *  f ;
    int     rc = ok ;
    STRLEN  len   = 0 ;
    char    sLen [20] ;
    const char * sType ;

    hv_clear (r -> pThread -> pFormHash) ;
    hv_clear (r -> pThread -> pFormSplitHash) ;
    av_clear (r -> pThread -> pFormArray) ;
    hv_clear (r -> pThread -> pInputHash) ;

    if  (r -> Config.bOptions & optDisableFormData)
        return ok ;
    
    /* print out of env set tainted, so reset it now */
    tainted = 0 ;

#ifdef APACHE
    if (r -> pApacheReq)
        {
        const char * sLength = apr_table_get(r -> pApacheReq->headers_in, "Content-Length") ;
        sType   = apr_table_get(r -> pApacheReq->headers_in, "Content-Type") ;
	len = sLength?atoi (sLength):0 ;
	}
    else
#endif
	{
	sLen [0] = '\0' ;
	GetHashValue (r, r -> pThread -> pEnvHash, "CONTENT_LENGTH", sizeof (sLen) - 1, sLen) ;
	sType = GetHashValueStr (aTHX_ r -> pThread -> pEnvHash, "CONTENT_TYPE", "") ;
	len = atoi (sLen) ;
	}

    if (sType && strncmp (sType, "multipart/form-data", 19) == 0)
        {
        dSP ;

        PUSHMARK(sp);
	XPUSHs(r -> _perlsv); 
	PUTBACK;                        
	perl_call_method ("get_multipart_formdata", G_EVAL) ;
        if (SvTRUE (ERRSV))
	    {
            STRLEN l ;
            strncpy (r -> errdat1, SvPV (ERRSV, l), sizeof (r -> errdat1) - 1) ;
	    LogError (r, rcEvalErr) ; 
            sv_setpv(ERRSV,"");
            POPs ; /* cleanup stack */
            }
	tainted = 0 ;
        return ok ;
        }
   
    
    if (len == 0)
        {
        p = r -> Param.sQueryInfo ;
        len = p?strlen (p):0 ;
        f = NULL ;
        }
    else
        {
        if ((p = _malloc (r, len + 1)) == NULL)
            return rcOutOfMemory ;

        if ((rc = OpenInput (r, NULL)) != ok)
            {
            _free (r, p) ;
            return rc ;
            }
        iread (r, p, len) ;
        CloseInput (r) ;
        
        p[len] = '\0' ;
        f = p ;
        }
        
    if (r  -> Config.bDebug & dbgForm)
        lprintf (r -> pApp,   "[%d]Formdata... length = %d\n", r -> pThread -> nPid, len) ;    

    rc = embperl_GetFormData (r, p, len) ;
    
    if (len > 0 && f)
	{
	r -> Param.sQueryInfo = f ;
	f[len] = '\0' ;
	}

    return rc ;
    }


/*---------------------------------------------------------------------------
* embperl_LogStartReq
*/
/*!
*
* \_en									   
* Log request startup, headers and environment
* \endif                                                                       
*
* \_de									   
* Logged den Requeststart, HTTP-Header und Umgebungsvariablen
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */


static void embperl_LogStartReq (/*i/o*/ req * r)

    {
    epTHX ;
    
    if (r -> Config.bDebug)
        {
        time_t t = time(NULL) ;
        lprintf (r -> pApp,  "[%d]REQ: ***** Start Request at %s", r -> pThread -> nPid, ctime (&t)) ;
        lprintf (r -> pApp,  "[%d]Use App: %s\n", r -> pApp -> pThread -> nPid, r -> pApp -> Config.sAppName) ; 
        }



#ifdef APACHE
    if (r -> pApacheReq && (r -> Config.bDebug & dbgHeadersIn))
        {
        int i;
        const apr_array_header_t *hdrs_arr;
        apr_table_entry_t  *hdrs;

        hdrs_arr = apr_table_elts (r -> pApacheReq->headers_in);
        hdrs = (apr_table_entry_t *)hdrs_arr->elts;

        lprintf (r -> pApp,   "[%d]HDR:  %d\n", r -> pThread -> nPid, hdrs_arr->nelts) ; 
        for (i = 0; i < hdrs_arr->nelts; ++i)
	    if (hdrs[i].key)
                lprintf (r -> pApp,   "[%d]HDR:  %s=%s\n", r -> pThread -> nPid, hdrs[i].key, hdrs[i].val) ; 
        }
#endif
    if (r -> Config.bDebug & dbgEnv)
        {
        SV *   psv ;
        HE *   pEntry ;
        char * pKey ;
        I32    l ;
        int  savewarn = dowarn ;
        dowarn = 0 ; /* no warnings here */
        
        hv_iterinit (r -> pThread -> pEnvHash) ;
        while ((pEntry = hv_iternext (r -> pThread -> pEnvHash)))
            {
            pKey = hv_iterkey (pEntry, &l) ;
            psv  = hv_iterval (r -> pThread -> pEnvHash, pEntry) ;

                lprintf (r -> pApp,   "[%d]ENV:  %s=%s\n", r -> pThread -> nPid, pKey, SvPV (psv, na)) ; 
            }
        dowarn = savewarn ;
        }

    }



/*---------------------------------------------------------------------------
* embperl_SetupRequest
*/
/*!
*
* \_en									   
* setup data for (http-)request object
* \endif                                                                       
*
* \_de									   
* Initialisiert das Requestobjekt
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */


int    embperl_SetupRequest (/*in*/ pTHX_
                             /*in*/ SV *             pApacheReqSV,
                             /*in*/ tApp *           pApp,
                             /*in*/ tApacheDirConfig *  pApacheCfg,
                             /*in*/ SV *             pPerlParam,
                             /*out*/tReq * *         ppReq)
                     
                     
    {
    tReq *          r ;
    tThreadData *   pThread ;
    SV *            pReqSV ;
    SV *            pReqRV ;
    SV * pSV ;
    SV * pRV ;
    tReqConfig *    pConfig ;
    tReqParam  *    pParam ;
    char *          pCookieName ;
    HV *            pParamHV = NULL ;
    dSP ;

#ifdef APACHE
    request_rec * pApacheReq  ;
#endif
    tMemPool * pPool = ep_make_sub_pool (pApp -> pPool) ;

    tainted = 0 ;

    if (pPerlParam && SvROK(pPerlParam))
        pParamHV = (HV *)SvRV(pPerlParam) ;

    epxs_Embperl__Req_create_obj(r,pReqSV,pReqRV,ep_palloc(pPool,sizeof(*r))) ;
    epxs_Embperl__Req__Config_create_obj(pConfig,pSV,pRV,&r->Config) ;
    epxs_Embperl__Req__Param_create_obj(pParam,pSV,pRV,&r->Param) ;
#ifdef PERL_IMPLICIT_CONTEXT
    r -> pPerlTHX = aTHX ;
#endif
    r -> pPool         = pPool ;
    pConfig -> pPool   = pPool ;
    pParam  -> pPool   = pPool ;

    r -> pApp = pApp ;
    pThread = r -> pThread = pApp -> pThread  ;
    r -> pPrevReq = pThread -> pCurrReq  ;
    pThread -> pCurrReq = r ;
    pApp ->    pCurrReq = r ;
    sv_setsv(pThread -> pReqRV, r -> _perlsv) ;   
    
    r -> startclock      = clock () ;
    r -> stsv_count      = sv_count ;

#ifdef PERL_IMPLICIT_CONTEXT
    r -> pPerlTHX = aTHX ;
#endif


    
#ifdef APACHE
    if (SvROK (pApacheReqSV))
        pApacheReq = r -> pApacheReq = (request_rec *)SvIV((SV*)SvRV(pApacheReqSV));
    else
        pApacheReq = r -> pApacheReq = NULL ;
    r -> pApacheReqSV = SvREFCNT_inc(pApacheReqSV) ;
    if (pApacheReq)
        {
        embperl_GetApacheReqConfig (pApp, pPool, pApacheCfg, &r -> Config) ;
        embperl_GetApacheReqParam  (pApp, pPool, pApacheReq, &r -> Param) ;
        }
    else
#endif
        {
        bool   bUseEnv = 0 ;
        bool   bUseRedirectEnv = 0 ;
        if (pParamHV)
            {
            bUseEnv         = (bool)GetHashValueInt (aTHX_ pParamHV, "use_env", 0) ;
            bUseRedirectEnv = (bool)GetHashValueInt (aTHX_ pParamHV, "use_redirect_env", 0) ;
            }
        embperl_GetCGIReqConfig (pApp, pPool, &r -> Config, bUseEnv, bUseRedirectEnv, 1) ;
        embperl_GetCGIReqParam  (pApp, pPool, &r -> Param) ;
        }
    
    if (pParamHV)
        {
        char * fn = GetHashValueStrDup(aTHX_ pPool, pParamHV, "inputfile", NULL) ;
        Embperl__Req__Config_new_init(aTHX_ &r -> Config, (SV *)pParamHV, 0) ;
        Embperl__Req__Param_new_init(aTHX_ &r -> Param, (SV *)pParamHV, 0) ;
        if (fn)
            r -> Param.sFilename = fn ;
        
        }

    tainted = 0 ;


    /*if (r -> Config.bDebug)
	lprintf (r -> pApp,  "[%d]ep_acquire_mutex(RequestCountMutex)\n", r -> pThread -> nPid) ; */
    ep_acquire_mutex(RequestCountMutex) ;
    r -> nRequestCount   = nRequestCount++ ;
    ep_release_mutex(RequestCountMutex) ;
    /*if (r -> Config.bDebug)
	lprintf (r -> pApp,  "[%d]ep_release_mutex(RequestCountMutex)\n", r -> pThread -> nPid) ; */
    r -> nRequestTime    = time(NULL) ;

    r -> pErrArray  = newAV () ;
    r -> pDomTreeAV = newAV () ; 
    r -> pCleanupAV = newAV () ; 
    r -> pCleanupPackagesHV = newHV () ; 
    r -> pMessages = newAV () ;    
    r -> pDefaultMessages = newAV () ;    

    pCookieName = r -> pApp -> Config.sCookieName ;
    if (pCookieName)
	{ /* remove session id  */
        char * pVal = GetHashValueStr (aTHX_ r -> Param.pCookies, pCookieName, NULL) ;
        if (pVal)
            r -> sSessionUserID = ep_pstrdup (r -> pPool, pVal) ;
        }

    if (r -> pApp -> Config.sCookieExpires)
        {
        char buf[256] ; 

        if (!embperl_CalcExpires(r -> pApp -> Config.sCookieExpires, buf, 0)) 
            LogErrorParam (r -> pApp, rcTimeFormatErr, "EMBPERL_COOKIE_EXPIRES", r -> pApp -> Config.sCookieExpires) ; 
        else
            r -> sCookieExpires = ep_pstrdup (r -> pPool, buf) ;    
        }    

    if (r -> pApp -> pUserHash)
        r -> nSessionMgnt = 1 ;

    r -> nLogFileStartPos = GetLogFilePos (pApp) ;

    hv_clear (pThread -> pHeaderHash) ;

    embperl_LogStartReq (r) ;

    embperl_SetupFormData (r) ;

    if (r -> sSessionUserID && pApp -> pUserObj)
        {
        tainted = 0 ;
        SPAGAIN;
        PUSHMARK(sp);
	XPUSHs(pApp -> pUserObj); 
	XPUSHs(sv_2mortal(newSVpv(r -> sSessionUserID, 0))); 
	PUTBACK;                        
	perl_call_method ("setid", 0) ;
        }

    if (r -> sSessionStateID && pApp -> pStateObj)
        {
        tainted = 0 ;
        SPAGAIN;
        PUSHMARK(sp);
	XPUSHs(pApp -> pStateObj); 
	XPUSHs(sv_2mortal(newSVpv(r -> sSessionStateID, 0))); 
	PUTBACK;                        
	perl_call_method ("setid", 0) ;
        }

    
    r -> sInitialCWD = ep_palloc(pPool, PATH_MAX * 2) ;
    getcwd (r -> sInitialCWD, PATH_MAX * 2 - 1) ;

    *ppReq = r ;

    if (pApp -> Config.sAppHandlerClass)
        {
        tainted = 0 ;
        SPAGAIN ;
        PUSHMARK(sp);
	XPUSHs(pApp -> _perlsv); 
	XPUSHs(r -> _perlsv); 
	PUTBACK;                        
	perl_call_method ("init", G_EVAL) ;
        tainted = 0 ;

        if (SvTRUE (ERRSV))
	    {
            STRLEN l ;
            POPs ; /* cleanup stack */
            LogErrorParam (pApp, rcEvalErr, SvPV (ERRSV, l), " while calling APP_HANDLER_CLASS -> init") ;
            sv_setpv(ERRSV,"");
            return rcEvalErr ;
            }
        }

    tainted = 0 ;
    
    return ok ;
    }
    
/*---------------------------------------------------------------------------
* embperl_CleanupOutput
*/
/*!
*
* \_en									   
* cleanup data for component output object
* \endif                                                                       
*
* \_de									   
* R?umt das Component-Ausgabe Objekt auf
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



int    embperl_CleanupOutput   (/*in*/ tReq *                r,
                                /*in*/ tComponent *           c)
                     
                     
    {
    epTHX_
    tComponentOutput * pOutput = c -> pOutput ;

    if (!pOutput || (c -> pPrev && c -> pPrev -> pOutput == pOutput))
        { /* this component uses the main output object */
        return ok ;
        }

    CloseOutput (r, pOutput) ;

    if (SvREFCNT(SvRV(pOutput -> _perlsv)) != 1)
        {
        char buf[20] ;
        sprintf (buf, "%d", (int)SvREFCNT(SvRV(pOutput -> _perlsv)) - 1) ;
        LogErrorParam (r -> pApp, rcRefcntNotOne, buf, "request.component.output") ;
        }            
    sv_unmagic(SvRV(pOutput -> _perlsv), '~') ;
    SvREFCNT_dec (pOutput -> _perlsv) ;
    ep_destroy_pool (pOutput -> pPool) ;

    return ok ;
    }

    
/*---------------------------------------------------------------------------
* embperl_CleanupComponent
*/
/*!
*
* \_en									   
* cleanup component object
* \endif                                                                       
*
* \_de									   
* Component-Objekt aufr?umen
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



int    embperl_CleanupComponent  (/*in*/ tComponent *          c)
                     
                     
    {
    tReq *  r = c -> pReq ;
    epTHX_
    SV * pHV ;
    MAGIC * mg;

    if (c -> Param.sISA && c -> sCurrPackage)
        {
        STRLEN  l ;
        SV * pName = newSVpvf ("%s::ISA", c -> sImportPackage) ;
        AV * pCallerISA = perl_get_av (SvPV(pName, l), TRUE) ;
        int i ;
        int n = av_len(pCallerISA) + 1;
        SV ** ppSV ;
        newSVpvf2(pName) ;

        SvREFCNT_dec (pName) ;
        
        for (i = 0; i < n; i++)
            {
            if ((ppSV = av_fetch(pCallerISA, i, 0)) && *ppSV && strcmp (SvPV(*ppSV, l), c -> sCurrPackage) == 0)
                break ;
            }

        if (n == i)
            av_push(pCallerISA, newSVpv (c -> sCurrPackage, 0)) ;
        }
        
    embperl_CleanupOutput (r, c) ;

    if (SvREFCNT(SvRV(c -> Config._perlsv)) != 1)
        {
        char buf[20] ;
        sprintf (buf, "%d", (int)SvREFCNT(SvRV(c -> Config._perlsv)) - 1) ;
        LogErrorParam (r -> pApp, rcRefcntNotOne, buf, "request.component.config") ;
        }            
    if (SvREFCNT(SvRV(c -> Param._perlsv)) != 1)
        {
        char buf[20] ;
        sprintf (buf, "%d", (int)SvREFCNT(SvRV(c -> Param._perlsv)) - 1) ;
        LogErrorParam (r -> pApp, rcRefcntNotOne, buf, "request.component.param") ;
        }            
    if (SvREFCNT(c -> _perlsv) != 1)
        {
        char buf[20] ;
        sprintf (buf, "%d", (int)SvREFCNT(SvRV(c -> _perlsv)) - 1) ;
        LogErrorParam (r -> pApp, rcRefcntNotOne, buf, "request.component") ;
        }            


    Embperl__Component__Config_destroy(aTHX_ &c -> Config) ;
    Embperl__Component__Param_destroy(aTHX_ &c -> Param) ;
    Embperl__Component_destroy(aTHX_ c) ;

    pHV = SvRV (c -> _perlsv) ;
    if ((mg = mg_find (pHV, '~')))
        *((tComponent **)(mg -> mg_ptr)) = &NullRequest.Component ;
    pHV = SvRV (c -> Config._perlsv) ;
    if ((mg = mg_find (pHV, '~')))
        *((tComponentConfig **)(mg -> mg_ptr)) = &NullRequest.Component.Config ;
    pHV = SvRV (c -> Param._perlsv) ;
    if ((mg = mg_find (pHV, '~')))
        *((tComponentParam **)(mg -> mg_ptr)) = &NullRequest.Component.Param ;

    SvREFCNT_dec (c -> Config._perlsv) ;
    SvREFCNT_dec (c -> Param._perlsv) ;
    SvREFCNT_dec (c -> _perlsv) ;


    if (c == &r -> Component && c -> pPrev)
        { /* we have a previous component, so let restore it */
        tComponent * pPrev = c -> pPrev;

        memcpy (c, pPrev, sizeof (*c)) ;
        
	/* adjust pointer in perl magic */
        pHV = SvRV (c -> _perlsv) ;
        if ((mg = mg_find (pHV, '~')))
            *((tComponent **)(mg -> mg_ptr)) = c ;
        pHV = SvRV (c -> Config._perlsv) ;
        if ((mg = mg_find (pHV, '~')))
            *((tComponentConfig **)(mg -> mg_ptr)) = &c -> Config ;
        pHV = SvRV (c -> Param._perlsv) ;
        if ((mg = mg_find (pHV, '~')))
            *((tComponentParam **)(mg -> mg_ptr)) = &c -> Param ;
        }
    else
        {
        c -> _perlsv = NULL ;
        }
    
    return ok ;
    }


/*---------------------------------------------------------------------------
* embperl_CleanupRequest
*/
/*!
*
* \_en									   
* cleanup request
* \endif                                                                       
*
* \_de									   
* Das Requestobjekt aufr?umen
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

int    embperl_CleanupRequest (/*in*/ tReq *  r) 

    {
    epTHX_
    int     i ;
    HE *    pEntry ;
    I32     l ;
    tApp *  pApp = r -> pApp ;
    SV *    pHV ;
    MAGIC * mg;
    dSP ;

    
    hv_iterinit (r -> pCleanupPackagesHV) ;
    while ((pEntry = hv_iternext (r -> pCleanupPackagesHV)))
        {
	char * sPackage = hv_iterkey (pEntry, &l) ;
        ClearSymtab (r, sPackage, r -> Config.bDebug & dbgShowCleanup) ;
        }
    tainted = 0 ;

    sv_setsv(r -> pThread -> pReqRV, &sv_undef) ;   

    while (r -> Component._perlsv)
        embperl_CleanupComponent(&r -> Component) ;
    
    if (r -> nSessionMgnt)
        {
        SPAGAIN ;
        PUSHMARK(sp);
        XPUSHs(pApp -> pAppObj); 
        PUTBACK;                        
        perl_call_method ("cleanup", G_DISCARD) ;
        SPAGAIN ;
        PUSHMARK(sp);
        XPUSHs(pApp -> pUserObj); 
        PUTBACK;                        
        perl_call_method ("cleanup", G_DISCARD) ;
        SPAGAIN ;
        PUSHMARK(sp);
        XPUSHs(pApp -> pStateObj); 
        PUTBACK;                        
        perl_call_method ("cleanup", G_DISCARD) ;
        SPAGAIN ;
        }
    
    hv_clear (r -> pThread -> pHeaderHash) ;
    hv_clear (r -> pThread -> pInputHash) ;
    av_clear (r -> pThread -> pFormArray) ;
    hv_clear (r -> pThread -> pFormHash) ;
    hv_clear (r -> pThread -> pFormSplitHash) ;
    /*
    for (i = 0 ; i <= av_len (r -> pDomTreeAV); i++)
	{
	SV ** ppSV = av_fetch (r -> pDomTreeAV, i, 0) ;   
        SV * pSV = * ppSV ;
        lprintf (r -> pApp, "r -> pDomTreeAV DomTree #%d type = %d cnt=%d n=%d\n", i, SvTYPE(pSV), SvREFCNT(pSV), SvIVX(pSV)) ;
	}
    */
    av_clear (r -> pDomTreeAV) ;
    SvREFCNT_dec (r -> pDomTreeAV) ;
    for (i = 0 ; i <= av_len (r -> pCleanupAV); i++)
	{
	SV ** ppSV = av_fetch (r -> pCleanupAV, i, 0) ;   
        SV * pSV = * ppSV ;
	/*
        if (SvROK(pSV))
            lprintf (r -> pApp, "r -> pCleanupAV DomTree #%d type = %d cnt=%d n=%d\n", i, SvTYPE(SvRV(pSV)), SvREFCNT(SvRV(pSV)), SvIVX(SvRV(pSV))) ;
	*/
        if (SvROK(pSV))
            sv_setsv (SvRV(pSV), &sv_undef) ;
	}
    av_clear (r -> pCleanupAV) ;

    Cache_CleanupRequest (r) ;

    if (SvREFCNT(SvRV(r -> Config._perlsv)) != 1)
        {
        char buf[20] ;
        sprintf (buf, "%d", (int)SvREFCNT(SvRV(r -> Config._perlsv)) - 1) ;
        LogErrorParam (r -> pApp, rcRefcntNotOne, buf, "request.config") ;
        }            
    if (SvREFCNT(SvRV(r -> Param._perlsv)) != 1)
        {
        char buf[20] ;
        sprintf (buf, "%d", (int)SvREFCNT(SvRV(r -> Param._perlsv)) - 1) ;
        LogErrorParam (r -> pApp, rcRefcntNotOne, buf, "request.param") ;
        }            
    /*
    if (SvREFCNT(SvRV(r -> _perlsv)) != 1)
        {
        char buf[20] ;
        sprintf (buf, "%d", SvREFCNT(SvRV(r -> _perlsv)) - 1) ;
        LogErrorParam (r -> pApp, rcRefcntNotOne, buf, "request") ;
        }            
        */

    /* cleanup errarray manualy, to avoid segv incase error in destroy */
    SvREFCNT_dec (r -> pErrArray) ;
    r -> pErrArray = NULL ;

    
    Embperl__Req__Config_destroy(aTHX_ &r -> Config) ;
    Embperl__Req__Param_destroy(aTHX_ &r -> Param) ;
    Embperl__Req_destroy(aTHX_ r) ;

    pHV = SvRV (r -> _perlsv) ;
    if ((mg = mg_find (pHV, '~')))
        *((tReq **)(mg -> mg_ptr)) = &NullRequest ;
    pHV = SvRV (r -> Config._perlsv) ;
    if ((mg = mg_find (pHV, '~')))
        *((tReqConfig **)(mg -> mg_ptr)) = &NullRequest.Config ;
    pHV = SvRV (r -> Param._perlsv) ;
    if ((mg = mg_find (pHV, '~')))
        *((tReqParam **)(mg -> mg_ptr)) = &NullRequest.Param ;
    
   
    SvREFCNT_dec (r -> Config._perlsv) ;
    SvREFCNT_dec (r -> Param._perlsv) ;
    SvREFCNT_dec (r -> _perlsv) ;
    
    ep_destroy_pool (r -> pPool) ;
    sv_setpv(ERRSV,"");

    if (r -> Config.bDebug)
	DomStats (r -> pApp) ;

    r -> pThread -> pCurrReq = r -> pPrevReq ;
    r -> pApp ->    pCurrReq = r -> pPrevReq ;

    if (r -> pPrevReq)
        sv_setsv(r -> pThread -> pReqRV, r -> pPrevReq -> _perlsv) ;   

    
    return ok ;
    }





/*---------------------------------------------------------------------------
* embperl_SetupOutput
*/
/*!
*
* \_en									   
* setup data for component output object
* \endif                                                                       
*
* \_de									   
* Initialisiert das Component-Ausgabe Objekt
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



int    embperl_SetupOutput     (/*in*/ tReq *                r,
                                /*in*/tComponent *           c)
                     
                     
    {
    epTHX_
    int          rc ;
    SV *         pSV ;
    SV *         pRV ;
    tComponentOutput * pOutput ;
    tMemPool * pPool  ;

    if (!c -> Param.pOutput && !c -> Param.sOutputfile && c -> pPrev && !r -> Component.pImportStash)
        { /* this component uses the main output object */
        c -> pOutput = c -> pPrev -> pOutput ;
        return ok ;
        }

    pPool = ep_make_sub_pool (r -> pPool) ;

    tainted = 0 ;
    epxs_Embperl__Component__Output_create_obj(pOutput,pSV,pRV,ep_palloc(pPool,sizeof(tComponentOutput))) ;
    tainted = 0 ;
    pOutput -> pPool         = pPool ;
    c -> pOutput = pOutput ;

    if (r -> Component.pImportStash)
	pOutput -> bDisableOutput = 1 ;
    else if (c -> Param.pOutput)
        {
        if ((rc = OpenOutput (r, "")) != ok)
            return rc ;
        }
    else
        {
        if ((rc = OpenOutput (r, embperl_File2Abs(r, pOutput -> pPool, c -> Param.sOutputfile))) != ok)
            return rc ;
        }

    return ok ;
    }


/*---------------------------------------------------------------------------
* embperl_SetupComponent
*/
/*!
*
* \_en									   
* setup data for component object
* \endif                                                                       
*
* \_de									   
* Initialisiert das Component-Objekt
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */



int    embperl_SetupComponent  (/*in*/ tReq *                 r,
                                /*in*/ SV *                   pPerlParam,
                                /*out*/tComponent * *         ppComponent)
                     
                     
    {
    int          rc ;
    SV *         pComponentSV ;
    SV *         pComponentRV ;
    SV *         pSV ;
    SV *         pRV ;
    tComponent * c ;
    tComponentParam * pParam ;
    tComponentConfig * pConfig ;
    epTHX_
    tComponent * pPrev = NULL ;
    char * p ;
    HV *         pParamHV = NULL ;

    if (r -> Component._perlsv)
        { /* we have already a component, so let safe it first */
        SV * pHV ;
        MAGIC * mg ;

        pPrev = ep_palloc(r->pPool,sizeof(*pPrev)) ;

        memcpy (pPrev, &r -> Component, sizeof (*pPrev)) ;
        
	/* adjust pointer in perl magic */
        pHV = SvRV (pPrev -> _perlsv) ;
        if ((mg = mg_find (pHV, '~')))
            *((tComponent **)(mg -> mg_ptr)) = pPrev ;
        pHV = SvRV (pPrev -> Config._perlsv) ;
        if ((mg = mg_find (pHV, '~')))
            *((tComponentConfig **)(mg -> mg_ptr)) = &pPrev -> Config ;
        pHV = SvRV (pPrev -> Param._perlsv) ;
        if ((mg = mg_find (pHV, '~')))
            *((tComponentParam **)(mg -> mg_ptr)) = &pPrev -> Param ;
        }

    if (pPerlParam && SvROK(pPerlParam))
        pParamHV = (HV *)SvRV(pPerlParam) ;
   
    epxs_Embperl__Component_create_obj(c,pComponentSV, pComponentRV,&r->Component) ;
    epxs_Embperl__Component__Param_create_obj(pParam,pSV, pRV,&r->Component.Param) ;
    epxs_Embperl__Component__Config_create_obj(pConfig,pSV, pRV,&r->Component.Config) ;
    
    r -> Component.pPrev = pPrev ;

    c -> pPool         = r -> pPool ;
    pParam -> pPool    = r -> pPool ;
    pConfig -> pPool   = r -> pPool ;

    c -> Param.nImport = -1 ;
    c -> Param.nFirstLine = 1 ;

    c -> pReq = r ;
#ifdef APACHE
    if (r -> pApacheReq)
        {
        embperl_GetApacheComponentConfig (r, r -> pPool, r -> pApacheConfig, &c -> Config) ;
        }
    else
#endif
        {
        bool   bUseEnv = 0 ;
        bool   bUseRedirectEnv = 0 ;
        if (pParamHV)
            {
            bUseEnv         = (bool)GetHashValueInt (aTHX_ pParamHV, "use_env", 0) ;
            bUseRedirectEnv = (bool)GetHashValueInt (aTHX_ pParamHV, "use_redirect_env", 0) ;
            }
        embperl_GetCGIComponentConfig (r, r -> pPool, &c -> Config, bUseEnv, bUseRedirectEnv, 1) ;
        }
    
    if (pPrev)
        c -> Config.bOptions &= ~optReturnError ;
    
    if (pParamHV)
        {
        Embperl__Component__Config_new_init (aTHX_ &c -> Config, (SV *)pParamHV, 0) ;
        Embperl__Component__Param_new_init  (aTHX_ &c -> Param, (SV *)pParamHV, 0) ;
        }

    c -> sCWD = pPrev?pPrev -> sCWD:r -> sInitialCWD ;
    if (c -> sCWD == NULL)
        c -> sCWD = "" ;

    NewEscMode (r, NULL) ;
    c -> bEscModeSet = 0 ;

    if (c -> Param.nImport < 0 && (c -> Param.sObject || c -> Param.sISA))
        c -> Param.nImport = 0 ;

    if (c -> Param.nImport >= 0)
	{
        char code[40] ;
        SV * pSVImport ;
        STRLEN l ;

        sprintf (code, "caller(%d)", c -> Param.nImport>0?c -> Param.nImport:1) ; 
        /* there is no c api to the caller function, eval it... */
        pSVImport = perl_eval_pv(code, 0) ;
        if (!SvOK(pSVImport))
            {
            if (c -> Param.nImport == 0)
                c -> sImportPackage = "main" ;
            else
	        {
	        LogError (r, rcImportStashErr) ;
                c -> sImportPackage = NULL ;
	        }
            }
        else
            c -> sImportPackage = ep_pstrdup(r -> pPool, SvPV (pSVImport, l)) ;

        if (c -> sImportPackage)
            {
            if ((c -> pImportStash = gv_stashpv (c -> sImportPackage, 0)) == NULL)
	        {
	        strncpy (r -> errdat1, c -> sImportPackage, sizeof (r -> errdat1) - 1);
	        LogError (r, rcImportStashErr) ;
	        }
            SvREFCNT_inc(c -> pImportStash) ;
            }
	}

    c -> nSourceline = pParam -> nFirstLine ;
    if (!pParam -> sInputfile) 
        {
        if (pParam -> sISA)
            pParam -> sInputfile = pParam -> sISA ;
        else if (pParam -> sObject)
            pParam -> sInputfile = pParam -> sObject ;
        else
            {
            if (pPrev)
                pParam -> sInputfile = pPrev -> sSourcefile ;
            if (!pParam -> sInputfile)
                pParam -> sInputfile = r -> Param.sFilename ;
            }
        }
    else if ((p = strchr(pParam -> sInputfile, '#')))
        {
        pParam -> sSub = p + 1 ;
        if (p == pParam -> sInputfile && c -> pPrev)
            pParam -> sInputfile = c -> pPrev -> sSourcefile ;
        else
            *p = '\0' ;
        }
    if (!pParam -> sInputfile || !*pParam -> sInputfile || strcmp(pParam -> sInputfile, "*") == 0) 
        pParam -> sInputfile = r -> Param.sFilename ;
    else if (strcmp(pParam -> sInputfile, "../*") == 0) 
        {
#ifdef WIN32
        char * p = strrchr(r -> Param.sFilename, '\\') ;
        if (!p)
            p = strrchr(r -> Param.sFilename, '/') ;                
#else
        char * p = strrchr(r -> Param.sFilename, '/') ;
#endif
        if (!p)
            p = r -> Param.sFilename ;
        else
            p++ ;
        
        pParam -> sInputfile = ep_pstrcat(r -> pPool, "../", p, NULL) ;
        }

    *ppComponent = c ;

    if (!pParam -> sInputfile)
        rc = rcMissingInput ;
    else
        rc = embperl_SetupOutput (r, c) ;
    if (rc != ok)
        LogError (r, rc) ;
    return rc ;
    }






/*---------------------------------------------------------------------------
* embperl_InitRequest
*/
/*!
*
* \_en									   
* Initialize the Thread and Application object and if available return the
* Apache configuration data
* \endif                                                                       
*
* \_de									   
* Initialisiert das Thread und Application Objekt und leifert, soweit vorhanden,
* die Apache Konfiguration
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */




int     embperl_InitAppForRequest (/*in*/ pTHX_
                             /*in*/ SV *             pApacheReqSV,
                             /*in*/ SV *             pPerlParam,
                             /*out*/tThreadData * *  ppThread,
                             /*out*/tApp * *         ppApp,
                             /*out*/tApacheDirConfig * * ppApacheCfg)


    {
    int              rc ;
    tThreadData *    pThread ;
    tApp  *          pApp ;
    tApacheDirConfig * pApacheCfg = NULL ;

    
    /* get our thread object */
    if ((rc = embperl_SetupThread (aTHX_ &pThread)) != ok)
        {
        LogError (NULL, rc) ;
        return rc ;
        }

#ifdef APACHE
    if (pApacheReqSV && SvROK (pApacheReqSV))
        {
        request_rec * ap_r = (request_rec *)SvIV((SV*)SvRV(pApacheReqSV));
        
        embperl_GetApacheConfig (pThread, ap_r, ap_r -> server, &pApacheCfg) ;
        
        }
#endif

    /* get the application object */
    if ((rc = embperl_SetupApp (aTHX_ pThread, pApacheCfg, pPerlParam, &pApp)) != ok)
        {
        LogError (NULL, rc) ;
        return rc ;
        }


    *ppThread    = pThread ;
    *ppApp       = pApp ;
    *ppApacheCfg = pApacheCfg ;

    return ok ;
    }


/*---------------------------------------------------------------------------
* embperl_InitRequest
*/
/*!
*
* \_en									   
* Initialize all necessary data structures to start a request like thread,
* application and request object
* \endif                                                                       
*
* \_de									   
* Initialisiert alle n?tigen Datenstrukturen um den Request zu starten, wie
* Thread-, Applikcation und Request-Objekt.
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */




int     embperl_InitRequest (/*in*/ pTHX_
                             /*in*/ SV *             pApacheReqSV,
                             /*in*/ SV *             pPerlParam,
                             /*out*/tReq * *         ppReq)


    {
    int              rc ;
    tThreadData *    pThread ;
    tApp  *          pApp ;
    tReq  *          r ;
    tApacheDirConfig * pApacheCfg = NULL ;

    
    /* get our thread & Application object */

    if ((rc = embperl_InitAppForRequest (aTHX_
                                         pApacheReqSV,
                                         pPerlParam,
                                         &pThread,
                                         &pApp,
                                         &pApacheCfg)) != ok)
        {
        LogError (NULL, rc) ;
        return rc ;
        }


    /* and setup the request object */
    if ((rc = embperl_SetupRequest (aTHX_ pApacheReqSV, pApp, pApacheCfg, pPerlParam, &r)) != ok)
        {
        LogErrorParam (pApp, rc, NULL, NULL) ;
        return rc ;
        }

    r -> pApacheConfig = pApacheCfg ;
   
    *ppReq = r ;

    if (r -> Config.pAllow || r -> Config.pUriMatch)
        {
        SV * args[1] ;
        SV * pRet ;
        STRLEN l ;

        if (r -> Param.sUri && *r -> Param.sUri)
            args[0] = newSVpv (r -> Param.sUri, 0) ;
        else if (r -> Param.sFilename && *r -> Param.sFilename)
            args[0] = newSVpv (r -> Param.sFilename, 0) ;
        else if (pPerlParam  && SvROK(pPerlParam))
            args[0] = (SV *)GetHashValueSVinc (r, (HV *)SvRV(pPerlParam), "inputfile", &sv_undef) ;
        else
            {
            LogError (r, rcCannotCheckUri) ;
            return rcCannotCheckUri ;
            }

        if (r -> Config.pAllow)
            {
            CallStoredCV (r, "ALLOW", r -> Config.pAllow, 1, args, 0, &pRet) ;
            if (pRet && !SvTRUE(pRet))
                {
                strncpy (r -> errdat1, SvPV(args[0], l), sizeof(r -> errdat1) - 1) ;
                SvREFCNT_dec(args[0]) ;
                if (pRet)
                    SvREFCNT_dec(pRet) ;
                LogError (r, rcForbidden) ;
                return rcForbidden ;
                }
            if (pRet)
                SvREFCNT_dec(pRet) ;
            }

        if (r -> Config.pUriMatch)
            {
            CallStoredCV (r, "URIMATCH", r -> Config.pUriMatch, 1, args, 0, &pRet) ;
            if (pRet && !SvTRUE(pRet))
                {
                strncpy (r -> errdat1, SvPV(args[0], l), sizeof(r -> errdat1) - 1) ;
                SvREFCNT_dec(args[0]) ;
                if (pRet)
                    SvREFCNT_dec(pRet) ;
                return rcDecline ;
                }
            if (pRet)
                SvREFCNT_dec(pRet) ;
            }
        SvREFCNT_dec(args[0]) ;
        }    

    return ok ;
    }




int     embperl_InitRequestComponent (/*in*/ pTHX_
                             /*in*/ SV *             pApacheReqSV,
                             /*in*/ SV *             pPerlParam,
                             /*out*/tReq * *         ppReq)

    {
    int rc ;
    tComponent * pComponent ;
    
    if ((rc = embperl_InitRequest (aTHX_ pApacheReqSV, pPerlParam, ppReq)) != ok)
        return rc ;

    return embperl_SetupComponent  (*ppReq, pPerlParam, &pComponent) ;
    }

