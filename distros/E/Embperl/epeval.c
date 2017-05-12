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
#   $Id: epeval.c 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################*/


#include "ep.h"
#include "epmacro.h"


/*---------------------------------------------------------------------------
* EvalDirect
*/
/*!
*
* \_en									   
* Compile and execute Perl code 
*                                                                          
* @param   pArg             Perl code to eval as SV. Can be either
*                           a string (PV) or code (CV)
* @param   numArgs          Number of arguments
* @param   pArgs            Arguments
* \endif                                                                       
*
* \_de									   
* Compiliert Perlcode und f?hrt ihn dann direkt aus.
*                                                                          
* @param   pArg             Perlcode der compiliert werden soll als SV. 
*                           Kann entweder eine Zeichenkette (SV) oder
*                           Code (CV) sein
* @param   numArgs          Anzahl der Argumente
* @param   pArgs            Argumente
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

int EvalDirect (/*i/o*/ register req *  r,
		/*in*/  SV *            pArg, 
                /*in*/  int		numArgs,
                /*in*/  SV **		pArgs)
    {
    epTHX_ /* dTHXsem */ 
    dSP;
    SV *  pSVErr  ;
    int   num ;
    int   n ;

    tainted = 0 ;

    PUSHMARK(sp);
    for (num = 0; num < numArgs; num++)
	XPUSHs(pArgs [num]) ;            /* push pointer to argument */
    PUTBACK;

#if PERL_VERSION >= 14
    n = perl_eval_sv(pArg, G_SCALAR);
#else
    n = perl_eval_sv(pArg, G_SCALAR | G_KEEPERR);
#endif

    SPAGAIN;
    if (n > 0)
        pSVErr = POPs;
    PUTBACK;

    //delap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "eval direct %s  serial=%d", SvPVX(pArg), pSVErr->sv_debug_serial) ;

    tainted = 0 ;
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
         
	/* LogError (r, rcEvalErr) ; */

        if (SvROK (pSVErr))
            {
            if (r -> pErrSV)
                SvREFCNT_dec(r -> pErrSV) ;
            r -> pErrSV = newRV (SvRV(pSVErr)) ;
            }
        
        sv_setpv(pSVErr,"");
        return rcEvalErr ;
        }

    return ok ;
    }


/*---------------------------------------------------------------------------
* EvalConfig
*/
/*!
*
* \_en									   
* Returns a CV for the given config expresseion. Can be either
* a CV, a name of a Perl sub or a string which starts with "sub "
* in which case it is compiled.
*                                                                          
* @param   pSV              Config code
* @param   numArgs          Number of arguments
* @param   pArgs            Arguments
* @param   sContext         give some context information for the error message
* @param   ppCV             Returns the CV
* \endif                                                                       
*
* \_de									   
* Liefert f?r einen gegeben Konfigurationsausdruck ein CV zur?ck.
* Der Ausdruck kann entweder schon ein CV sein, der Name einer
* Perlfunktion oder eine Zeichenkette die mit "sub " anf?ngt sein,
* in welchem Fall der Code kompiliert wird.
*                                                                          
* @param   pSV              Konfigurationsausdruck
* @param   numArgs          Anzahl der Argumente
* @param   pArgs            Argumente
* @param   sContext         Gibt Information ?ber das Umfeld f?r die Fehlermeldung
* @param   ppCV             Liefert die CV zur?ck
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

int EvalConfig (/*i/o*/ tApp *          a,
		/*in*/  SV *            pSV, 
                /*in*/  int		numArgs,
                /*in*/  SV **		pArgs,
		/*in*/  const char *    sContext, 
		/*out*/ CV **           pCV)
    {
    char * s = "Needs CodeRef" ;
    #ifdef PERL_IMPLICIT_CONTEXT
    pTHX = a?a -> pPerlTHX:PERL_GET_THX;
    #endif
    dSP;

    EPENTRY (EvalConfig) ;

    tainted = 0 ;

    *pCV = NULL ;
    if (SvPOK (pSV))
	{
	STRLEN l ;
	s = SvPV (pSV, l) ;
	if (strncmp (s, "sub ", 4) == 0)
	    {
	    SV * pSVErr ;
	    SV * pRV = NULL ;
            int  n ;

            n = perl_eval_sv (pSV, G_EVAL | G_SCALAR) ;
            tainted = 0 ;

            SPAGAIN;
            if (n > 0)
                pRV = POPs;
            PUTBACK;
    
            tainted = 0 ;
	    if (n > 0 && SvROK (pRV))
		{
		*pCV = (CV *)SvRV (pRV) ;
		SvREFCNT_inc (*pCV) ;
		}

	    pSVErr = ERRSV ;
	    if (SvTRUE (pSVErr))
		{
		STRLEN l ;
		char * p = SvPV (pSVErr, l) ;
        
		LogErrorParam (a, rcEvalErr, p, sContext) ;

		sv_setpv(pSVErr,"");
		*pCV = NULL ;
		return rcEvalErr ;
		}
	    }
	else
	    {
	    *pCV = perl_get_cv (s, 0) ;
	    SvREFCNT_inc (*pCV) ;
	    }
	}
    else 
	{
	if (SvROK (pSV))
	    {
	    *pCV = (CV *)SvRV (pSV) ;
	    }
	}
    //del ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "eval config %s  serial=%d", s, ((SV *)(*pCV))->sv_debug_serial) ;

    if (!*pCV || SvTYPE (*pCV) != SVt_PVCV)
	{
	*pCV = NULL ;
        LogErrorParam (a, rcEvalErr, s, sContext) ;
	return rcEvalErr ;
	}
#ifdef DMALLOC
        AddDMallocMagic (*pCV, s?s:"EvalConfig", __FILE__, __LINE__) ;
#endif

    return ok ;
    }


/*---------------------------------------------------------------------------
* EvalRegEx
*/
/*!
*
* \_en									   
* Returns a CV for the given regular expression.
*                                                                          
* @param   sRegex           regular expression as string
* @param   sContext         give some context information for the error message
* @param   ppCV             Returns the CV
* \endif                                                                       
*
* \_de									   
* Liefert f?r eine gegebenen Regul?ren Ausdruck ein CV zur?ck.
*                                                                          
* @param   sRegex           Regul?rer Ausdruck als Zeichenkette
* @param   sContext         Gibt Information ?ber das Umfeld f?r die Fehlermeldung
* @param   ppCV             Liefert die CV zur?ck
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

int EvalRegEx  (/*i/o*/ tApp *          a,
		/*in*/  char *          sRegex, 
		/*in*/  const char *    sContext, 
		/*out*/ CV **           ppCV)
    {
    epaTHX_
    SV * pSV ;
    char * p ;
    STRLEN l ;
    SV * pRV = NULL ;
    SV * pSVErr ;
    char c ;
    int  n ;
    dSP ;

    if (sRegex[0] == '!')
        {
        c = '!' ;
        while (isspace(*sRegex))
            sRegex++ ;
        }
    else
        c = '=' ;
    
    tainted = 0 ;
    pSV = newSVpvf ("package Embperl::Regex ; sub { $_[0] %c~ m{%s} }", c, sRegex) ;
    newSVpvf2(pSV) ;

    /* perl_eval_pv seems to be broken in 5.005_03!! */
    /* p = SvPV(pSV, l) ; */
    /* pRV = perl_eval_pv (p, 0) ; */

    n = perl_eval_sv (pSV, G_EVAL | G_SCALAR) ;
    SvREFCNT_dec(pSV);
    tainted = 0 ;

    SPAGAIN;
    if (n > 0)
        pRV = POPs;
    PUTBACK;
    
    pSVErr = ERRSV ;
    if (SvTRUE (pSVErr))
	{
	p = SvPV (pSVErr, l) ;

	LogErrorParam (a, rcEvalErr, p, sContext) ;

	sv_setpv(pSVErr,"");
	*ppCV = NULL ;
	return rcEvalErr ;
	}

    if (n > 0 && SvROK (pRV))
	{
	*ppCV = (CV *)SvRV (pRV) ;
	SvREFCNT_inc (*ppCV) ;
#ifdef DMALLOC
        AddDMallocMagic (*ppCV, sRegex?sRegex:"EvalRegEx", __FILE__, __LINE__) ;
#endif
//del ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE NULL, "eval regex %s  serial=%d", sRegex, ((SV *)(*ppCV))->sv_debug_serial) ;
	}
    else
      	*ppCV = NULL ;

    

    return ok ;
    }


    
    

/* -------------------------------------------------------------------------------
*
* Eval PERL Statements into a sub 
* 
* in  sArg   Statement to eval
* out pRet   pointer to SV contains an CV to the evaled code
*
------------------------------------------------------------------------------- */

static int EvalAll (/*i/o*/ register req * r,
		    /*in*/  const char *  sArg,
                    /*in*/  int           flags,
                    /*in*/  const char *  sName,
		    /*out*/ SV **         pRet)             
    {
    epTHX_ /* dTHXsem */
    static char sFormat []       = "package %s ; %s sub %s { \n#line %d \"%s\"\n%s\n} %s%s" ;
    static char sFormatStrict [] = "package %s ; %s use strict ; sub %s {\n#line %d \"%s\"\n%s\n} %s%s" ; 
    static char sFormatArray []       = "package %s ; %s sub %s { \n#line %d \"%s\"\n[%s]\n} %s%s" ;
    static char sFormatStrictArray [] = "package %s ; %s use strict ; sub %s {\n#line %d \"%s\"\n[%s]\n} %s%s" ; 
    SV *   pSVCmd ;
    SV *   pSVErr ;
    int    n ;
    char * sRef = "" ;
    char * use_utf8 = "" ;

    dSP;
    
    EPENTRY (EvalAll) ;

    GetLineNo (r) ;

    if (r -> Component.Config.bDebug & dbgDefEval)
        lprintf (r -> pApp,  "[%d]DEF:  Line %d: %s\n", r -> pThread -> nPid, r -> Component.nSourceline, sArg?sArg:"<unknown>") ;

    tainted = 0 ;

    if (!sName)
        sName = "" ;
    
    if (*sName)
	sRef = "; \\&" ;
    
    if (strcmp (r -> Component.Config.sInputCharset, "utf8") == 0)
        use_utf8 = "use utf8;" ;
    
    if (r -> Component.bStrict)
        if ((flags & G_ARRAY) != G_SCALAR)
            pSVCmd = newSVpvf(sFormatStrictArray, r -> Component.sEvalPackage, use_utf8, sName, r -> Component.nSourceline, r -> Component.sSourcefile, sArg, sRef, sName) ;
        else
            pSVCmd = newSVpvf(sFormatStrict, r -> Component.sEvalPackage, use_utf8, sName, r -> Component.nSourceline, r -> Component.sSourcefile, sArg, sRef, sName) ;
    else
        if ((flags & G_ARRAY) != G_SCALAR)
            pSVCmd = newSVpvf(sFormatArray, r -> Component.sEvalPackage, use_utf8, sName, r -> Component.nSourceline, r -> Component.sSourcefile, sArg, sRef, sName) ;
        else
            pSVCmd = newSVpvf(sFormat, r -> Component.sEvalPackage, use_utf8, sName, r -> Component.nSourceline, r -> Component.sSourcefile, sArg, sRef, sName) ;
    newSVpvf2(pSVCmd) ;

    PUSHMARK(sp);
#if PERL_VERSION >= 14
    n = perl_eval_sv(pSVCmd, G_SCALAR);
#else
    n = perl_eval_sv(pSVCmd, G_SCALAR | G_KEEPERR);
#endif
    SvREFCNT_dec(pSVCmd);
    tainted = 0 ;

    SPAGAIN;
    if (n > 0)
        *pRet = POPs;
    else
	*pRet = NULL ;
    PUTBACK;

    if (r -> Component.Config.bDebug & dbgMem)
        lprintf (r -> pApp,  "[%d]SVs:  %d\n", r -> pThread -> nPid, sv_count) ;
    
    pSVErr = ERRSV ;
    if (SvTRUE (pSVErr) || (n == 0 && (flags & G_DISCARD) == 0))
        {
        STRLEN l ;
        char * p = SvPV (pSVErr, l) ;
        if (l > sizeof (r -> errdat1) - 1)
            l = sizeof (r -> errdat1) - 1 ;
        strncpy (r -> errdat1, p, l) ;
        if (l > 0 && r -> errdat1[l-1] == '\n')
            l-- ;
        r -> errdat1[l] = '\0' ;
         
        /*if (pRet && *pRet)
	     SvREFCNT_dec (*pRet) ;
	*/
	*pRet = newSVpv (r -> errdat1, 0) ;
         
        /* LogError (r, rcEvalErr) ; */
	sv_setpv(pSVErr, "");

	return rcEvalErr ;
        }

    return ok ;
    }



/* -------------------------------------------------------------------------------
*
* Call an already evaled PERL Statement
* 
* in  sArg   Statement to eval (only used for logging)
* in  pSub   CV which should be called
* out pRet   pointer to SV contains the eval return
*
------------------------------------------------------------------------------- */


int CallCV  (/*i/o*/ register req * r,
		    /*in*/  const char *  sArg,
                    /*in*/  CV *          pSub,
                    /*in*/  int           flags,
                    /*out*/ SV **         pRet)             
    {
    epTHX_ /* dTHXsem */ 
    int   num ;         
#ifdef TABUSED
    int   nCountUsed = r -> TableStack.State.nCountUsed ;
    int   nRowUsed   = r -> TableStack.State.nRowUsed ;
    int   nColUsed   = r -> TableStack.State.nColUsed ;
#endif
    SV *  pSVErr ;
    dSP;                            /* initialize stack pointer      */


    if (r -> Component.pImportStash)
	{ /* do not execute any code on import */
	*pRet = NULL ;
	return ok ;
	}
    

    EPENTRY (CallCV) ;

    if (r -> Component.Config.bDebug & dbgEval)
        lprintf (r -> pApp,  "[%d]EVAL< %s\n", r -> pThread -> nPid, sArg?sArg:"<unknown>") ;

    tainted = 0 ;

    ENTER ;
    SAVETMPS ;
    PUSHMARK(sp);                   /* remember the stack pointer    */

    num = perl_call_sv ((SV *)pSub, flags | G_EVAL | G_NOARGS) ; /* call the function             */
    tainted = 0 ;

    SPAGAIN;                        /* refresh stack pointer         */
    
    if (r -> Component.Config.bDebug & dbgMem)
        lprintf (r -> pApp,  "[%d]SVs:  %d\n", r -> pThread -> nPid, sv_count) ;
    /* pop the return value from stack */
    if (num == 1)   
        {
        *pRet = POPs ;
        if (SvTYPE (*pRet) == SVt_PVMG)
            { /* variable is magicaly -> fetch value now */
            SV * pSV = newSVsv (*pRet) ;
            *pRet = pSV ;
            }
        else        
            SvREFCNT_inc (*pRet) ;

        if (r -> Component.Config.bDebug & dbgEval)
            {
            if (SvOK (*pRet))
                lprintf (r -> pApp,  "[%d]EVAL> %s\n", r -> pThread -> nPid, SvPV (*pRet, na)) ;
            else
                lprintf (r -> pApp,  "[%d]EVAL> <undefined>\n", r -> pThread -> nPid) ;
            }                
            
#ifdef TABUSED
        if ((nCountUsed != r -> TableStack.State.nCountUsed ||
             nColUsed != r -> TableStack.State.nColUsed ||
             nRowUsed != r -> TableStack.State.nRowUsed) &&
              !SvOK (*pRet))
            {
            r -> TableStack.State.nResult = 0 ;
            SvREFCNT_dec (*pRet) ;
            *pRet = newSVpv("", 0) ;
            } 

        if ((r -> Component.Config.bDebug & dbgTab) &&
            (r -> TableStack.State.nCountUsed ||
             r -> TableStack.State.nColUsed ||
             r -> TableStack.State.nRowUsed))
            lprintf (r -> pApp,  "[%d]TAB:  nResult = %d\n", r -> pThread -> nPid, r -> TableStack.State.nResult) ;
#ifdef DMALLOC
        AddDMallocMagic (*pRet, sArg?sArg:"CallCV", __FILE__, __LINE__) ;
#endif
#endif
        }
     else if (num == 0)
        {
        *pRet = NULL ;
        if (r -> Component.Config.bDebug & dbgEval)
            lprintf (r -> pApp,  "[%d]EVAL> <NULL>\n", r -> pThread -> nPid) ;
        }
     else
        {
        *pRet = &sv_undef ;
        if (r -> Component.Config.bDebug & dbgEval)
            lprintf (r -> pApp,  "[%d]EVAL> returns %d args instead of one\n", r -> pThread -> nPid, num) ;
        }

     /*if (SvREFCNT(*pRet) != 2)
            lprintf (r -> pApp,  "[%d]EVAL refcnt != 2 !!= %d !!!!!\n", r -> pThread -> nPid, SvREFCNT(*pRet)) ;*/

     PUTBACK;
     FREETMPS ;
     LEAVE ;

     if (r -> bExit || r -> Component.bExit)
	 {
	 if (*pRet)
	     SvREFCNT_dec (*pRet) ;
	 *pRet = NULL ;
         if (r -> Component.Config.bDebug & dbgEval)
            lprintf (r -> pApp,  "[%d]EVAL> exit passed through\n", r -> pThread -> nPid) ;
	 return rcExit ;
	 }
     
     pSVErr = ERRSV ;
     if (SvTRUE (pSVErr))
        {
        STRLEN l ;
        char * p ;

        p = SvPV (pSVErr, l) ;
        if (p && l > 14 && strncmp(p, ">embperl_exit<", 14) == 0)
            {
 	    /* On an Apache::exit call, the function croaks with error having 'U' magic.
 	     * When we get this return, we'll just give up and quit this file completely,
 	     * without error. */
             
	    /*struct magic * m = SvMAGIC (pSVErr) ;*/

            tDomTree * pDomTree = DomTree_self (r -> Component.xCurrDomTree) ;
            tIndex n = ArrayGetSize (r -> pApp, pDomTree -> pCheckpoints) ;
            if (n > 2)
                DomTree_checkpoint (r, n-1)  ;

            if (r -> Component.Config.bDebug & dbgEval)
                lprintf (r -> pApp,  "[%d]EVAL> exit called\n", r -> pThread -> nPid) ;
            
	    sv_setpv(pSVErr,"");

	    r -> Component.Config.bOptions |= optNoUncloseWarn ;
	    r -> bExit = 1 ;

            return rcExit ;
            }

        if (l > sizeof (r -> errdat1) - 1)
            l = sizeof (r -> errdat1) - 1 ;
        strncpy (r -> errdat1, p, l) ;
        if (l > 0 && r -> errdat1[l-1] == '\n')
             l-- ;
        r -> errdat1[l] = '\0' ;

        if (SvROK (pSVErr))
            {
            if (r -> pErrSV)
                SvREFCNT_dec(r -> pErrSV) ;
            r -> pErrSV = newRV (SvRV(pSVErr)) ;
            }
        
         
	LogError (r, rcEvalErr) ;

	sv_setpv(pSVErr,"");

	return rcEvalErr ;
        }

     
    return ok ;
    }

/* -------------------------------------------------------------------------------
*
* Eval PERL Statements and setup the correct return value/error message
* 
* in  sArg   Statement to eval
* out ppSV   pointer to an SV with should be set to CV of the evaled code
*
------------------------------------------------------------------------------- */


int EvalOnly           (/*i/o*/ register req * r,
			/*in*/  const char *  sArg,
                        /*in*/  SV **         ppSV,
                        /*in*/  int           flags,
  		        /*in*/  const char *  sName)



    {
    int     rc ;
    SV *   pSub ;
    epTHX_    
    
    EPENTRY (EvalOnly) ;

    r -> lastwarn[0] = '\0' ;
    
    rc = EvalAll (r, sArg, flags, sName, &pSub) ;

    if (rc == ok && (flags & G_DISCARD))
	{
	if (pSub)
	    SvREFCNT_dec (pSub) ;
	return ok ;
	}

    if (ppSV && *ppSV)
	 SvREFCNT_dec (*ppSV) ;

    if (rc == ok && pSub != NULL && SvROK (pSub))
        {
        /*sv_setsv (*ppSV, pSub) ;*/
        *ppSV = SvRV(pSub) ;
        SvREFCNT_inc (*ppSV) ;  
        }
    else
        {
        if (pSub != NULL && SvTYPE (pSub) == SVt_PV)
            {
	    *ppSV = pSub ; /* save error message */
	    pSub = NULL ;
	    }
        else if (r -> lastwarn[0] != '\0')
	    {
    	    *ppSV = newSVpv (r -> lastwarn, 0) ;
	    }
        else
	    {
    	    *ppSV = newSVpv ("Compile Error", 0) ;
	    }
        
        if (pSub)
	     SvREFCNT_dec (pSub) ;

	r -> bError = 1 ;
        return rc ;
        }

    return ok ;
    }

#if 0
/* -------------------------------------------------------------------------------
*
* Eval PERL Statements and execute the evaled code
* 
* in  sArg   Statement to eval
* out ppSV   pointer to an SV with should be set to CV of the evaled code
* out pRet   pointer to SV contains the eval return
*
------------------------------------------------------------------------------- */


static int EvalAndCall (/*i/o*/ register req * r,
			/*in*/  const char *  sArg,
                        /*in*/  SV **         ppSV,
                        /*in*/  int           flags,
                        /*out*/ SV **         pRet)             


    {
    int     rc ;
    epTHX_    
    
    
    EPENTRY (EvalAndCall) ;

    if ((rc = EvalOnly (r, sArg, ppSV, flags, "")) != ok)
	{
	*pRet = NULL ;
	return rc ;
	}


    if (*ppSV && SvTYPE (*ppSV) == SVt_PVCV)
        { /* Call the compiled eval */
        return CallCV (r, sArg, (CV *)*ppSV, flags, pRet) ;
        }
    
    *pRet = NULL ;
    r -> bError = 1 ;
    
    if (ppSV && *ppSV)
	 SvREFCNT_dec (*ppSV) ;

    if (r -> lastwarn[0] != '\0')
    	{
 	*ppSV = newSVpv (r -> lastwarn, 0) ;
	}
    else
	{
    	*ppSV = newSVpv ("Compile Error", 0) ;
	}

    return rcEvalErr ;
    }

#endif


/* -------------------------------------------------------------------------------
*
* Call an already evaled PERL Statement
* 
* in  sArg   Statement to eval (only used for logging)
* in  pSub   CV which should be called
* in  numArgs number of arguments
* in  pArgs   args for subroutine
* out pRet   pointer to SV contains the eval return
*
------------------------------------------------------------------------------- */


int CallStoredCV  (/*i/o*/ register req * r,
		    /*in*/  const char *  sArg,
                    /*in*/  CV *          pSub,
                    /*in*/  int           numArgs,
                    /*in*/  SV **         pArgs,
                    /*in*/  int           flags,
                    /*out*/ SV **         pRet)             
    {
    epTHX_ /* dTHXsem */
    int   num ;         
    SV *  pSVErr ;

    dSP;                            /* initialize stack pointer      */

    EPENTRY (CallCV) ;

    if (r -> Component.Config.bDebug & dbgEval)
        lprintf (r -> pApp,  "[%d]EVAL< %s\n", r -> pThread -> nPid, sArg?sArg:"<unknown>") ;

    tainted = 0 ;

    ENTER ;
    SAVETMPS ;
    PUSHMARK(sp);                   /* remember the stack pointer    */
    for (num = 0; num < numArgs; num++)
	XPUSHs(pArgs [num]) ;            /* push pointer to argument */
    PUTBACK;

    num = perl_call_sv ((SV *)pSub, flags | G_EVAL | (numArgs?0:G_NOARGS)) ; /* call the function             */
    tainted = 0 ;
    
    SPAGAIN;                        /* refresh stack pointer         */
    
    if (r -> Component.Config.bDebug & dbgMem)
        lprintf (r -> pApp,  "[%d]SVs:  %d\n", r -> pThread -> nPid, sv_count) ;
    /* pop the return value from stack */
    if (num == 1)   
        {
        *pRet = POPs ;
        if (SvTYPE (*pRet) == SVt_PVMG)
            { /* variable is magicaly -> fetch value now */
            SV * pSV = newSVsv (*pRet) ;
            *pRet = pSV ;
            }
        else        
            SvREFCNT_inc (*pRet) ;

        if (r -> Component.Config.bDebug & dbgEval)
            {
            if (SvOK (*pRet))
                lprintf (r -> pApp,  "[%d]EVAL> %s\n", r -> pThread -> nPid, SvPV (*pRet, na)) ;
            else
                lprintf (r -> pApp,  "[%d]EVAL> <undefined>\n", r -> pThread -> nPid) ;
            }                
#ifdef DMALLOC
        AddDMallocMagic (*pRet, sArg?sArg:"CallStoredCV", __FILE__, __LINE__) ;
#endif
        }
     else if (num == 0)
        {
        *pRet = NULL ;
        if (r -> Component.Config.bDebug & dbgEval)
            lprintf (r -> pApp,  "[%d]EVAL> <NULL>\n", r -> pThread -> nPid) ;
        }
     else
        {
        *pRet = &sv_undef ;
        if (r -> Component.Config.bDebug & dbgEval)
            lprintf (r -> pApp,  "[%d]EVAL> returns %d args instead of one\n", r -> pThread -> nPid, num) ;
        }

     PUTBACK;
     FREETMPS ;
     LEAVE ;

    /*
     if (r -> bExit || r -> Component.bExit)
	 {
	 if (*pRet)
	     SvREFCNT_dec (*pRet) ;
	 *pRet = NULL ;
         if (r -> Component.Config.bDebug & dbgEval)
            lprintf (r -> pApp,  "[%d]EVAL> exit passed through\n", r -> pThread -> nPid) ;
	 return rcExit ;
	 }
     */

     pSVErr = ERRSV ;
     if (SvTRUE (pSVErr))
        {
        STRLEN l ;
        char * p ;

        p = SvPV (pSVErr, l) ;
        if (p && l > 14 && strncmp(p, ">embperl_exit<", 14) == 0)
            {
 	    /* On an Apache::exit call, the function croaks with error having 'U' magic.
 	     * When we get this return, we'll just give up and quit this file completely,
 	     * without error. */
             
	    /*struct magic * m = SvMAGIC (pSVErr) ;*/
            tDomTree * pDomTree = DomTree_self (r -> Component.xCurrDomTree) ;
            tIndex n = ArrayGetSize (r -> pApp, pDomTree -> pCheckpoints) ;
            if (n > 2)
                DomTree_checkpoint (r, n-1) ;

            p = SvPV(ERRSV, l) ;
            if (l > 0 && strncmp (p, ">embperl_exit< request ", 23) == 0)
                r -> bExit = 1 ;
            
            if (r -> Component.Config.bDebug & dbgEval)
                lprintf (r -> pApp,  "[%d]EVAL> %s exit called (%s)\n", r -> pThread -> nPid, r -> bExit?"request":"component", p?p:"") ;
            
	    sv_setpv(pSVErr,"");

	    r -> Component.Config.bOptions |= optNoUncloseWarn ;
	    r -> Component.bExit = 1 ;

            return rcExit ;
            }

        if (l > sizeof (r -> errdat1) - 1)
            l = sizeof (r -> errdat1) - 1 ;
        strncpy (r -> errdat1, p, l) ;
        if (l > 0 && r -> errdat1[l-1] == '\n')
             l-- ;
        r -> errdat1[l] = '\0' ;

        if (SvROK (pSVErr))
            {
            if (r -> pErrSV)
                SvREFCNT_dec(r -> pErrSV) ;
            r -> pErrSV = newRV (SvRV(pSVErr)) ;
            }
        
         
	LogError (r, rcEvalErr) ;

	sv_setpv(pSVErr,"");

	return rcEvalErr ;
        }

     
    return ok ;
    }

#if 0
#ifdef EP2

/* -------------------------------------------------------------------------------
*
* Eval PERL Statements check if it's already compiled
* 
* in  sArg      Statement to eval
* in  nFilepos  position von eval in file (is used to build an unique key)
* out pRet      pointer to SV contains the eval return
*
------------------------------------------------------------------------------- */

int EvalStore (/*i/o*/ register req * r,
	      /*in*/  const char *  sArg,
	      /*in*/  int           nFilepos,
	      /*out*/ SV **         pRet)             


    {
    int     rc ;
    SV **   ppSV ;
    epTHX_    
    
    
    EPENTRY (Eval) ;

    *pRet = NULL ;

    /*if (r -> Component.Config.bDebug & dbgCacheDisable)
        return EvalAllNoCache (r, sArg, pRet) ;
    */
    /* Already compiled ? */

    ppSV = hv_fetch(r -> Buf.pFile -> pCacheHash, (char *)&nFilepos, sizeof (nFilepos), 1) ;  
    if (ppSV == NULL)
        {
        strcpy (r -> errdat1, "CacheHash in EvalStore") ;
        return rcHashError ;
        }

    if (*ppSV != NULL && SvTYPE (*ppSV) == SVt_PV)
        {
        strncpy (r -> errdat1, SvPV(*ppSV, na), sizeof (r -> errdat1) - 1) ; 
        LogError (r, rcEvalErr) ;
        return rcEvalErr ;
        }

    lprintf (r -> pApp,  "CV ppSV=%s type=%d\n", *ppSV?"ok":"NULL", *ppSV?SvTYPE (*ppSV):0) ;               
    if (*ppSV == NULL || SvTYPE (*ppSV) != SVt_PVCV)
	{
	if ((rc = EvalOnly (r, sArg, ppSV, G_SCALAR, "")) != ok)
	    {
	    *pRet = NULL ;
	    return rc ;
	    }
        *pRet = *ppSV  ;
	return ok ;
	}

    *pRet = *ppSV  ;
    r -> numCacheHits++ ;
    return ok ;
    }



#endif /* EP2 */

/* -------------------------------------------------------------------------------
*
* Eval PERL Statements and execute the evaled code, check if it's already compiled
* 
* in  sArg      Statement to eval
* in  nFilepos  position von eval in file (is used to build an unique key)
* out pRet      pointer to SV contains the eval return
*
------------------------------------------------------------------------------- */

int Eval (/*i/o*/ register req * r,
			/*in*/  const char *  sArg,
          /*in*/  int           nFilepos,
          /*out*/ SV **         pRet)             


    {
    SV **   ppSV ;
    epTHX_    
    
    
    EPENTRY (Eval) ;

    *pRet = NULL ;

    /*if (r -> Component.Config.bDebug & dbgCacheDisable)
        return EvalAllNoCache (r, sArg, pRet) ;
    */
    /* Already compiled ? */

    ppSV = hv_fetch(r -> Buf.pFile -> pCacheHash, (char *)&nFilepos, sizeof (nFilepos), 1) ;  
    if (ppSV == NULL)
        {
        strcpy (r -> errdat1, "CacheHash in Eval") ;
        return rcHashError ;
        }

    if (*ppSV != NULL && SvTYPE (*ppSV) == SVt_PV)
        {
        strncpy (r -> errdat1, SvPV(*ppSV, na), sizeof (r -> errdat1) - 1) ; 
        LogError (r, rcEvalErr) ;
        return rcEvalErr ;
        }

    if (*ppSV == NULL || SvTYPE (*ppSV) != SVt_PVCV)
        return EvalAndCall (r, sArg, ppSV, G_SCALAR, pRet) ;

    r -> numCacheHits++ ;
    return CallCV (r, sArg, (CV *)*ppSV, G_SCALAR, pRet) ;
    }


/* -------------------------------------------------------------------------------
*
* Eval PERL Statements and execute the evaled code, check if it's already compiled
* strip off all <HTML> Tags before 
* 
* in  sArg      Statement to eval
* in  nFilepos  position von eval in file (is used to build an unique key)
* out pRet      pointer to SV contains the eval return value
*
------------------------------------------------------------------------------- */


int EvalTransFlags (/*i/o*/ register req * r,
			/*in*/  char *   sArg,
                    /*in*/  int      nFilepos,
                    /*in*/  int      flags,
                    /*out*/ SV **    pRet)             


    {
    SV **   ppSV ;
    epTHX_    
    
    EPENTRY (EvalTrans) ;


    *pRet = NULL ;

    /*
    if (r -> Component.Config.bDebug & dbgCacheDisable)
        {
        /  * strip off all <HTML> Tags *  /
        TransHtml (r, sArg, 0) ;
        
        return EvalAllNoCache (r, sArg, pRet) ;
        }
    */
    /* Already compiled ? */

    ppSV = hv_fetch(r -> Buf.pFile -> pCacheHash, (char *)&nFilepos, sizeof (nFilepos), 1) ;  
    if (ppSV == NULL)
        {
        strcpy (r -> errdat1, "CacheHash in EvalTransFlags") ;
        return rcHashError ;
        }

    if (*ppSV != NULL && SvTYPE (*ppSV) == SVt_PV)
        {
        strncpy (r -> errdat1, SvPV(*ppSV, na), sizeof (r -> errdat1) - 1) ; 
        LogError (r, rcEvalErr) ;
        return rcEvalErr ;
        }

    if (*ppSV == NULL || SvTYPE (*ppSV) != SVt_PVCV)
        {
        /* strip off all <HTML> Tags */
        TransHtml (r, sArg, 0) ;

        return EvalAndCall (r, sArg, ppSV, flags, pRet) ;
        }

    r -> numCacheHits++ ;
    
    return CallCV (r, sArg, (CV *)*ppSV, flags, pRet) ;
    }


int EvalTrans (/*i/o*/ register req * r,
			/*in*/  char *   sArg,
                    /*in*/  int      nFilepos,
                    /*out*/ SV **    pRet)             
    
    {
    return EvalTransFlags (r, sArg, nFilepos, G_SCALAR, pRet) ;
    }
    
    
/* -------------------------------------------------------------------------------
*
* Eval PERL Statements and execute the evaled code, check if it's already compiled
* if yes do not call the code a second time
* strip off all <HTML> Tags before 
* 
* in  sArg      Statement to eval
* in  nFilepos  position von eval in file (is used to build an unique key)
* out pRet      pointer to SV contains the eval return value
*
------------------------------------------------------------------------------- */


int EvalTransOnFirstCall (/*i/o*/ register req * r,
			/*in*/  char *   sArg,
                          /*in*/  int      nFilepos,
                          /*out*/ SV **    pRet)             


    {
    SV **   ppSV ;
    epTHX_    
    
    EPENTRY (EvalTrans) ;


    *pRet = NULL ;

    /* Already compiled ? */

    ppSV = hv_fetch(r -> Buf.pFile -> pCacheHash, (char *)&nFilepos, sizeof (nFilepos), 1) ;  
    if (ppSV == NULL)
        {
        strcpy (r -> errdat1, "CacheHash in EvalTransOnFirstCall") ;
        return rcHashError ;
        }

    if (*ppSV != NULL && SvTYPE (*ppSV) == SVt_PV)
        {
        strncpy (r -> errdat1, SvPV(*ppSV, na), sizeof (r -> errdat1) - 1) ; 
        LogError (r, rcEvalErr) ;
        return rcEvalErr ;
        }

    if (*ppSV == NULL || SvTYPE (*ppSV) != SVt_PVCV)
        {
        int	rc ;
	HV *  pImportStash = r -> Component.pImportStash ;
	r -> Component.pImportStash = NULL ; /* temporarely disable import */

	/* strip off all <HTML> Tags */
        TransHtml (r, sArg, 0) ;

	rc = EvalAndCall (r, sArg, ppSV, G_SCALAR, pRet) ;

       	r -> Component.pImportStash = pImportStash ; 

	return rc ;	    
	}

    r -> numCacheHits++ ;
    
    return ok ; /* Do not call this a second time */
    }


/* -------------------------------------------------------------------------------
*
* Eval PERL Statements into a sub, check if it's already compiled
* 
* in  sArg      Statement to eval wrap into a sub
* in  nFilepos  position von eval in file (is used to build an unique key)
* in  sName     sub name
*
------------------------------------------------------------------------------- */

int EvalSub (/*i/o*/ register req * r,
	    /*in*/  const char *  sArg,
	    /*in*/  int           nFilepos,
	    /*in*/  const char *  sName)


    {
    int     rc ;
    SV **   ppSV ;
    epTHX_    
    
    
    EPENTRY (EvalSub) ;



    /* Already compiled ? */

    ppSV = hv_fetch(r -> Buf.pFile -> pCacheHash, (char *)&nFilepos, sizeof (nFilepos), 1) ;  
    if (ppSV == NULL)
        {
        strcpy (r -> errdat1, "CacheHash in EvalSub") ;
        return rcHashError ;
        }

    if (*ppSV != NULL && SvTYPE (*ppSV) == SVt_PV)
        {
        strncpy (r -> errdat1, SvPV(*ppSV, na), sizeof (r -> errdat1) - 1) ; 
        LogError (r, rcEvalErr) ;
        return rcEvalErr ;
        }

    if (*ppSV == NULL || SvTYPE (*ppSV) != SVt_PVCV)
        {
	char endc ;
	int  len = strlen (sName) ;
	
	while (len > 0 && isspace(sName[len-1]))
	    len-- ;
	endc = sName[len] ;
	((char *)sName)[len] = '\0' ;
	
	if ((rc =  EvalOnly (r, sArg, ppSV, 0, sName)) != ok)
	    {
	    ((char *)sName)[len] = endc ;
	    return rc ;
	    }

        if (r -> Component.pImportStash && *ppSV && SvTYPE (*ppSV) == SVt_PVCV)
	    {
	    hv_store (r -> Component.pExportHash, (char *)sName, len, newRV_inc(*ppSV), 0) ;
	    
	    if (r -> Component.Config.bDebug & dbgImport)
		lprintf (r -> pApp,  "[%d]IMP:  %s -> %s (%x)\n", r -> pThread -> nPid, sName, HvNAME (r -> Component.pImportStash), *ppSV) ;

	    /* 
	    gvp = (GV**)hv_fetch(r -> Component.pImportStash, (char *)sName, len, 1);
	    
	    if (!gvp || *gvp == (GV*)&PL_sv_undef)
		{
		((char *)sName)[len] = endc ;
		return rcHashError ;
		}

	    gv = *gvp;
	    if (SvTYPE(gv) != SVt_PVGV) 
		gv_init(gv, r -> Component.pImportStash, (char *)sName, len, 0);
	    
	    lprintf (r -> pApp,  "sv_any=%x\n", gv -> sv_any) ;
	    
	    SvREFCNT_dec (GvCV (gv)) ;  
	    GvCV_set (gv,(CV *)*ppSV) ; 
	    SvREFCNT_inc (*ppSV) ;  
	    */
	    }

	((char *)sName)[len] = endc ;
	return ok ;
	}

    r -> numCacheHits++ ;
    return ok ;
    }


/* -------------------------------------------------------------------------------
*
* Eval PERL Statements and execute the evaled code, check if it's already compiled
* 
* in  sArg      Statement to eval
* in  nFilepos  position von eval in file (is used to build an unique key)
* out pNum      pointer to int, contains the eval return value
*
------------------------------------------------------------------------------- */



int EvalNum (/*i/o*/ register req * r,
			/*in*/  char *        sArg,
             /*in*/  int           nFilepos,
             /*out*/ int *         pNum)             
    {
    SV * pRet ;
    int  n ;
    epTHX_    

    EPENTRY (EvalNum) ;


    n = Eval (r, sArg, nFilepos, &pRet) ;
    
    if (pRet)
        {
        *pNum = SvIV (pRet) ;
        SvREFCNT_dec (pRet) ;
        }
    else
        *pNum = 0 ;

    return ok ;
    }
    

/* -------------------------------------------------------------------------------
*
* EvalBool PERL Statements and execute the evaled code, check if it's already compiled
* 
* in  sArg      Statement to eval
* in  nFilepos  position von eval in file (is used to build an unique key)
* out pTrue     return 1 if evaled expression is true
*
------------------------------------------------------------------------------- */



int EvalBool (/*i/o*/ register req * r,
	      /*in*/  char *        sArg,
              /*in*/  int           nFilepos,
              /*out*/ int *         pTrue)             
    {
    SV * pRet ;
    int  rc ;
    epTHX_    

    EPENTRY (EvalNum) ;


    rc = Eval (r, sArg, nFilepos, &pRet) ;
    
    if (pRet)
        {
        *pTrue = SvTRUE (pRet) ;
        SvREFCNT_dec (pRet) ;
        }
    else
        *pTrue = 0 ;

    return rc ;
    }
    

/* -------------------------------------------------------------------------------
*
* EvalMain Scan file for [* ... *] and convert it to a perl program
* 
*
------------------------------------------------------------------------------- */


int EvalMain (/*i/o*/ register req *  r)

    {
    int     rc ;
    long    nFilepos = -1 ;
    char *  sProg = "" ;
    SV **   ppSV ;
    SV *    pRet ;
    int     flags = G_SCALAR ;
    epTHX_    

    /* Already compiled ? */

    ppSV = hv_fetch(r -> Buf.pFile -> pCacheHash, (char *)&nFilepos, sizeof (nFilepos), 1) ;  
    if (ppSV == NULL)
        {
        strcpy (r -> errdat1, "CacheHash in EvalMain") ;
        return rcHashError ;
        }

    if (*ppSV != NULL && SvTYPE (*ppSV) == SVt_PV)
        {
        strncpy (r -> errdat1, SvPV(*ppSV, na), sizeof (r -> errdat1) - 1) ; 
        LogError (r, rcEvalErr) ;
        return rcEvalErr ;
        }

    if (*ppSV == NULL || SvTYPE (*ppSV) != SVt_PVCV)
	{ /* Not already compiled -> build a perl frame program */
	char * pStart = r -> Component.pBuf ;
	char * pEnd   = r -> Component.pEndPos ;
	char * pOpenBracket  = r -> pConf -> pOpenBracket ;
	char * pCloseBracket = r -> pConf -> pCloseBracket ;
	int  lenOpenBracket  = strlen (pOpenBracket) ;
	int  lenCloseBracket = strlen (pCloseBracket) ;
	char * pOpen  ;
	char * pClose ;
	char   buf [256] ;
        int    nBlockNo = 1 ;

        
	if (r -> sSubName && *(r -> sSubName))
	    {
	    int nPos = GetSubTextPos (r, r -> sSubName) ;
	    
	    if (!nPos || pStart + nPos > pEnd || nPos < 0)
		{
		strncpy (r -> errdat1, r -> sSubName, sizeof (r -> errdat1) - 1) ; 
		return rcSubNotFound ;
		}
	    pStart += nPos ; 
	    }
	pOpen = pStart - 1 ;
	
	do 
            pOpen  = strstr (pOpen + 1, pOpenBracket) ;
        while (pOpen && pOpen > pStart && pOpen[-1] == '[') ;
        
        
        if (!pOpen)
            { /* no top level perl blocks -> call ProcessBlock directly */
            ProcessBlock (r, pStart - r -> Component.pBuf, r -> Component.pEndPos - r -> Component.pBuf, 1) ;
            return ok ;
            }


	OutputToMemBuf (r, NULL, r -> Component.pEndPos - r -> Component.pBuf) ;

	while (pStart)
	    {
	    pClose = NULL ;
	    if (pOpen)
                {
		if ((pClose = strstr (pOpen + lenOpenBracket, pCloseBracket)) == NULL)
                    {
                    strncpy (r -> errdat1, pCloseBracket, sizeof (r -> errdat1) - 1) ; 
                    return rcMissingRight ;
                    }
                *pOpen = '\0' ;
                }
            else
		pOpen = pEnd ;


            sprintf (buf, "\n$___b=$_[0] -> ProcessBlock (%d,%d,%d);\ngoto \"b$___b\";\nb%d:;\n", pStart - r -> Component.pBuf, pOpen - pStart, nBlockNo, nBlockNo) ;
            oputs  (r, buf) ;
            nBlockNo++ ;
	    if (pClose)
		{
		owrite (r, pOpen + lenOpenBracket, pClose - (pOpen + lenOpenBracket)) ;
		pStart = pClose + lenCloseBracket ;
                /* skip trailing whitespaces */
                while (isspace(*pStart))
                    pStart++ ;
                pOpen  = pStart - 1 ;
                do 
                    pOpen  = strstr (pOpen + 1, pOpenBracket) ;
                while (pOpen && pOpen > pStart && pOpen[-1] == '[') ;
                }
	    else
                {
                pStart = NULL ;
                }
            }

        oputs  (r, "\nb0:\n\0") ;

	sProg = OutputToStd (r) ;
	if (sProg == NULL)
	    return rcOutOfMemory ;

        /* strip off all <HTML> Tags */
	TransHtml (r, sProg, 0) ;

        if ((rc = EvalAndCall (r, sProg, ppSV, flags, &pRet)) != ok)
            return rc ;
        return ok ; /* SvIV (pRet) ;*/
        }

    r -> numCacheHits++ ;
    
    if ((rc = CallCV (r, sProg, (CV *)*ppSV, flags, &pRet)) != ok)
        return rc ;
    return ok ; /* SvIV (pRet) ;*/
    }
#endif

