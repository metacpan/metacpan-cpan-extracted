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
#   $Id: epeval.c,v 1.30 2001/11/02 10:03:48 richter Exp $
#
###################################################################################*/


#include "ep.h"
#include "epmacro.h"


/* -------------------------------------------------------------------------------
*
* Eval PERL Statements 
* 
* in  sArg   Statement to eval
* out pRet   pointer to SV contains an CV to the evaled code
*
------------------------------------------------------------------------------- */

int EvalDirect (/*i/o*/ register req *  r,
		/*in*/  SV *            pArg, 
                /*in*/  int		numArgs,
                /*in*/  SV **		pArgs)
    {
    dTHXsem 
    dSP;
    SV *  pSVErr  ;
    int   num ;         

    EPENTRY (EvalDirect) ;

    tainted = 0 ;
    pCurrReq = r ;

    PUSHMARK(sp);
    for (num = 0; num < numArgs; num++)
	XPUSHs(pArgs [num]) ;            /* push pointer to argument */
    PUTBACK;

    perl_eval_sv(pArg, G_SCALAR | G_KEEPERR);


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
        return rcEvalErr ;
        }

    return ok ;
    }


/* -------------------------------------------------------------------------------
*
* Eval Config Statements 
* 
* in  pSV    pointer to string or CV
* out pCV    pointer to SV contains an CV to the evaled code
*
------------------------------------------------------------------------------- */

int EvalConfig (/*i/o*/ register req *  r,
		/*in*/  SV *            pSV, 
                /*in*/  int		numArgs,
                /*in*/  SV **		pArgs,
		/*out*/ CV **           pCV)
    {
    dTHXsem 
    dSP;
    SV *  pSVErr  ;
    int   num ;         
    char * s = "Needs CodeRef" ;

    EPENTRY (EvalDirect) ;

    tainted = 0 ;
    pCurrReq = r ;

    *pCV = NULL ;
    if (SvPOK (pSV))
	{
	STRLEN l ;
	s = SvPV (pSV, l) ;
	if (strncmp (s, "sub ", 4) == 0)
	    {
	    SV * pSVErr ;
	    SV * pRV ;

	    pRV = perl_eval_pv (s, 0) ;
	    if (SvROK (pRV))
		{
		*pCV = (CV *)SvRV (pRV) ;
		SvREFCNT_inc (*pCV) ;
		}

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

    if (!*pCV || SvTYPE (*pCV) != SVt_PVCV)
	{
	*pCV = NULL ;
	strcpy (r -> errdat1 ,"Config: ") ;
	strncpy (r -> errdat2, s, sizeof (r -> errdat2) - 1) ;
	return rcEvalErr ;
	}

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
    dTHXsem 
    static char sFormat []       = "package %s ; sub %s { \n#line %d \"%s\"\n%s\n} %s%s" ;
    static char sFormatStrict [] = "package %s ; use strict ; sub %s {\n#line %d \"%s\"\n%s\n} %s%s" ; 
    static char sFormatArray []       = "package %s ; sub %s { \n#line %d \"%s\"\n[%s]\n} %s%s" ;
    static char sFormatStrictArray [] = "package %s ; use strict ; sub %s {\n#line %d \"%s\"\n[%s]\n} %s%s" ; 
    SV *   pSVCmd ;
    SV *   pSVErr ;
    int    n ;
    char * sRef = "" ;

    dSP;
    
    EPENTRY (EvalAll) ;

    GetLineNo (r) ;

    if (r -> bDebug & dbgDefEval)
        lprintf (r, "[%d]DEF:  Line %d: %s\n", r -> nPid, r -> Buf.nSourceline, sArg?sArg:"<unknown>") ;

    tainted = 0 ;
    pCurrReq = r ;

    if (*sName)
	sRef = "; \\&" ;
    
    if (r -> bStrict)
        if (flags & G_ARRAY)
            pSVCmd = newSVpvf(sFormatStrictArray, r -> Buf.sEvalPackage, sName, r -> Buf.nSourceline, r -> Buf.pFile -> sSourcefile, sArg, sRef, sName) ;
        else
            pSVCmd = newSVpvf(sFormatStrict, r -> Buf.sEvalPackage, sName, r -> Buf.nSourceline, r -> Buf.pFile -> sSourcefile, sArg, sRef, sName) ;
    else
        if (flags & G_ARRAY)
            pSVCmd = newSVpvf(sFormatArray, r -> Buf.sEvalPackage, sName, r -> Buf.nSourceline, r -> Buf.pFile -> sSourcefile, sArg, sRef, sName) ;
        else
            pSVCmd = newSVpvf(sFormat, r -> Buf.sEvalPackage, sName, r -> Buf.nSourceline, r -> Buf.pFile -> sSourcefile, sArg, sRef, sName) ;

    PUSHMARK(sp);
    n = perl_eval_sv(pSVCmd, G_SCALAR | G_KEEPERR);
    SvREFCNT_dec(pSVCmd);

    SPAGAIN;
    if (n > 0)
        *pRet = POPs;
    else
	*pRet = NULL ;
    PUTBACK;

    if (r -> bDebug & dbgMem)
        lprintf (r, "[%d]SVs:  %d\n", r -> nPid, sv_count) ;
    
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
         
        if (pRet && *pRet)
	     SvREFCNT_dec (*pRet) ;
	
	*pRet = newSVpv (r -> errdat1, 0) ;
         
        LogError (r, rcEvalErr) ;
	sv_setpv(pSVErr, "");
        return rcEvalErr ;
        }

    return ok ;
    }


/* -------------------------------------------------------------------------------
*
* Eval PERL Statements without any caching of p-code
* 
* in  sArg   Statement to eval
* out pRet   pointer to SV contains the eval return
*
------------------------------------------------------------------------------- */

#define EVAL_SUB

static int EvalAllNoCache (/*i/o*/ register req * r,
			/*in*/  const char *  sArg,
                           /*out*/ SV **         pRet)             
    {
    dTHXsem 
    int   num ;         
    int   nCountUsed = r -> TableStack.State.nCountUsed ;
    int   nRowUsed   = r -> TableStack.State.nRowUsed ;
    int   nColUsed   = r -> TableStack.State.nColUsed ;
#ifndef EVAL_SUB    
    SV *  pSVArg ;
#endif
    SV *  pSVErr ;
    dSP;                            /* initialize stack pointer      */

    EPENTRY (EvalAll) ;

    if (r -> bDebug & dbgEval)
        lprintf (r, "[%d]EVAL< %s\n", r -> nPid, sArg?sArg:"<unknown>") ;

    tainted = 0 ;
    pCurrReq = r ;

#ifdef EVAL_SUB    

    ENTER;                          /* everything created after here */
    SAVETMPS;                       /* ...is a temporary variable.   */
    PUSHMARK(sp);                   /* remember the stack pointer    */
    XPUSHs(sv_2mortal(newSVpv((char *)sArg, strlen (sArg)))); /* push the base onto the stack  */
    PUTBACK;                        /* make local stack pointer global */
    num = perl_call_pv ("_eval_", G_SCALAR /*| G_EVAL*/) ; /* call the function             */
#else
    
    pSVArg = sv_2mortal(newSVpv((char *)sArg, strlen (sArg))) ;

    /*num = perl_eval_sv (pSVArg, G_SCALAR) ; / * call the function             */ */
    num = perl_eval_sv (pSVArg, G_DISCARD) ; /* call the function             */
    num = 0 ;
#endif    
    SPAGAIN;                        /* refresh stack pointer         */
    
    if (r -> bDebug & dbgMem)
        lprintf (r, "[%d]SVs:  %d\n", r -> nPid, sv_count) ;
    /* pop the return value from stack */
    if (num == 1)   
        {
        *pRet = POPs ;
        SvREFCNT_inc (*pRet) ;

        if (r -> bDebug & dbgEval)
            if (SvOK (*pRet))
                lprintf (r, "[%d]EVAL> %s\n", r -> nPid, SvPV (*pRet, na)) ;
            else
                lprintf (r, "[%d]EVAL> <undefined>\n", r -> nPid) ;
        
        if ((nCountUsed != r -> TableStack.State.nCountUsed ||
             nColUsed != r -> TableStack.State.nColUsed ||
             nRowUsed != r -> TableStack.State.nRowUsed) &&
              !SvOK (*pRet))
            {
            r -> TableStack.State.nResult = 0 ;
            SvREFCNT_dec (*pRet) ;
            *pRet = newSVpv("", 0) ;
            } 

        if ((r -> bDebug & dbgTab) &&
            (r -> TableStack.State.nCountUsed ||
             r -> TableStack.State.nColUsed ||
             r -> TableStack.State.nRowUsed))
            lprintf (r, "[%d]TAB:  nResult = %d\n", r -> nPid, r -> TableStack.State.nResult) ;
        }
    else
        {
        *pRet = NULL ;
        if (r -> bDebug & dbgEval)
            lprintf (r, "[%d]EVAL> <NULL>\n", r -> nPid) ;
        }

	PUTBACK;

    pSVErr = ERRSV ;
    if (SvTRUE (pSVErr))
        {
        strncpy (r -> errdat1, SvPV (pSVErr, na), sizeof (r -> errdat1) - 1) ;
        LogError (r, rcEvalErr) ;
	num = rcEvalErr ;
        }
    else
        num = ok ;



#ifdef EVAL_SUB    
    FREETMPS;                       /* free that return value        */
    LEAVE;                       /* ...and the XPUSHed "mortal" args.*/
#endif
    
    return num ;
    }

/* -------------------------------------------------------------------------------
*
* Watch if there are any variables changed
* 
------------------------------------------------------------------------------- */


static int Watch (/*i/o*/ register req * r)

    {
    dSP;                            /* initialize stack pointer      */

    EPENTRY (Watch) ;

    PUSHMARK(sp);                   /* remember the stack pointer    */

    perl_call_pv ("HTML::Embperl::watch", G_DISCARD | G_NOARGS) ; /* call the function             */
    
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
    dTHXsem 
    int   num ;         
    int   nCountUsed = r -> TableStack.State.nCountUsed ;
    int   nRowUsed   = r -> TableStack.State.nRowUsed ;
    int   nColUsed   = r -> TableStack.State.nColUsed ;
    SV *  pSVErr ;
    dSP;                            /* initialize stack pointer      */


    if (r -> pImportStash)
	{ /* do not execute any code on import */
	*pRet = NULL ;
	return ok ;
	}
    

    EPENTRY (CallCV) ;

    if (r -> bDebug & dbgEval)
        lprintf (r, "[%d]EVAL< %s\n", r -> nPid, sArg?sArg:"<unknown>") ;

    tainted = 0 ;
    pCurrReq = r ;

    ENTER ;
    SAVETMPS ;
    PUSHMARK(sp);                   /* remember the stack pointer    */

    num = perl_call_sv ((SV *)pSub, flags | G_EVAL | G_NOARGS) ; /* call the function             */
    
    SPAGAIN;                        /* refresh stack pointer         */
    
    if (r -> bDebug & dbgMem)
        lprintf (r, "[%d]SVs:  %d\n", r -> nPid, sv_count) ;
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

        if (r -> bDebug & dbgEval)
            {
            if (SvOK (*pRet))
                lprintf (r, "[%d]EVAL> %s\n", r -> nPid, SvPV (*pRet, na)) ;
            else
                lprintf (r, "[%d]EVAL> <undefined>\n", r -> nPid) ;
            }                
            
        if ((nCountUsed != r -> TableStack.State.nCountUsed ||
             nColUsed != r -> TableStack.State.nColUsed ||
             nRowUsed != r -> TableStack.State.nRowUsed) &&
              !SvOK (*pRet))
            {
            r -> TableStack.State.nResult = 0 ;
            SvREFCNT_dec (*pRet) ;
            *pRet = newSVpv("", 0) ;
            } 

        if ((r -> bDebug & dbgTab) &&
            (r -> TableStack.State.nCountUsed ||
             r -> TableStack.State.nColUsed ||
             r -> TableStack.State.nRowUsed))
            lprintf (r, "[%d]TAB:  nResult = %d\n", r -> nPid, r -> TableStack.State.nResult) ;

        }
     else if (num == 0)
        {
        *pRet = NULL ;
        if (r -> bDebug & dbgEval)
            lprintf (r, "[%d]EVAL> <NULL>\n", r -> nPid) ;
        }
     else
        {
        *pRet = &sv_undef ;
        if (r -> bDebug & dbgEval)
            lprintf (r, "[%d]EVAL> returns %d args instead of one\n", r -> nPid, num) ;
        }

     /*if (SvREFCNT(*pRet) != 2)
            lprintf (r, "[%d]EVAL refcnt != 2 !!= %d !!!!!\n", r -> nPid, SvREFCNT(*pRet)) ;*/

     PUTBACK;
     FREETMPS ;
     LEAVE ;

     if (r -> bExit)
	 {
	 if (*pRet)
	     SvREFCNT_dec (*pRet) ;
	 *pRet = NULL ;
	 return rcExit ;
	 }
     
     pSVErr = ERRSV ;
     if (SvTRUE (pSVErr))
        {
        STRLEN l ;
        char * p ;

        if (SvMAGICAL (pSVErr) && mg_find (pSVErr, 'U'))
            {
 	    /* On an Apache::exit call, the function croaks with error having 'U' magic.
 	     * When we get this return, we'll just give up and quit this file completely,
 	     * without error. */
             
	    /*struct magic * m = SvMAGIC (pSVErr) ;*/

	    sv_unmagic(pSVErr,'U');
	    sv_setpv(pSVErr,"");

	    r -> bOptions |= optNoUncloseWarn ;
	    r -> bExit = 1 ;

            return rcExit ;
            }

        p = SvPV (pSVErr, l) ;
        if (l > sizeof (r -> errdat1) - 1)
            l = sizeof (r -> errdat1) - 1 ;
        strncpy (r -> errdat1, p, l) ;
        if (l > 0 && r -> errdat1[l-1] == '\n')
             l-- ;
        r -> errdat1[l] = '\0' ;
         
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

    if (rc == ok && pSub != NULL && SvTYPE (pSub) == SVt_RV)
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

#ifdef EP2

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
    dTHXsem
    int   num ;         
    SV *  pSVErr ;

    dSP;                            /* initialize stack pointer      */

    EPENTRY (CallCV) ;

    if (r -> bDebug & dbgEval)
        lprintf (r, "[%d]EVAL< %s\n", r -> nPid, sArg?sArg:"<unknown>") ;

    tainted = 0 ;
    pCurrReq = r ;

    ENTER ;
    SAVETMPS ;
    PUSHMARK(sp);                   /* remember the stack pointer    */
    for (num = 0; num < numArgs; num++)
	XPUSHs(pArgs [num]) ;            /* push pointer to argument */
    PUTBACK;

    num = perl_call_sv ((SV *)pSub, flags | G_EVAL | (numArgs?0:G_NOARGS)) ; /* call the function             */
    
    SPAGAIN;                        /* refresh stack pointer         */
    
    if (r -> bDebug & dbgMem)
        lprintf (r, "[%d]SVs:  %d\n", r -> nPid, sv_count) ;
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

        if (r -> bDebug & dbgEval)
            {
            if (SvOK (*pRet))
                lprintf (r, "[%d]EVAL> %s\n", r -> nPid, SvPV (*pRet, na)) ;
            else
                lprintf (r, "[%d]EVAL> <undefined>\n", r -> nPid) ;
            }                
        }
     else if (num == 0)
        {
        *pRet = NULL ;
        if (r -> bDebug & dbgEval)
            lprintf (r, "[%d]EVAL> <NULL>\n", r -> nPid) ;
        }
     else
        {
        *pRet = &sv_undef ;
        if (r -> bDebug & dbgEval)
            lprintf (r, "[%d]EVAL> returns %d args instead of one\n", r -> nPid, num) ;
        }

     PUTBACK;
     FREETMPS ;
     LEAVE ;

     if (r -> bExit)
	 {
	 if (*pRet)
	     SvREFCNT_dec (*pRet) ;
	 *pRet = NULL ;
	 return rcExit ;
	 }
     
     pSVErr = ERRSV ;
     if (SvTRUE (pSVErr))
        {
        STRLEN l ;
        char * p ;

        if (SvMAGICAL (pSVErr) && mg_find (pSVErr, 'U'))
            {
 	    /* On an Apache::exit call, the function croaks with error having 'U' magic.
 	     * When we get this return, we'll just give up and quit this file completely,
 	     * without error. */
             
	    /*struct magic * m = SvMAGIC (pSVErr) ;*/

	    sv_unmagic(pSVErr,'U');
	    sv_setpv(pSVErr,"");

	    r -> bOptions |= optNoUncloseWarn ;
	    r -> bExit = 1 ;

            return rcExit ;
            }

        p = SvPV (pSVErr, l) ;
        if (l > sizeof (r -> errdat1) - 1)
            l = sizeof (r -> errdat1) - 1 ;
        strncpy (r -> errdat1, p, l) ;
        if (l > 0 && r -> errdat1[l-1] == '\n')
             l-- ;
        r -> errdat1[l] = '\0' ;
         
	LogError (r, rcEvalErr) ;

	sv_setpv(pSVErr,"");

	return rcEvalErr ;
        }

     
    return ok ;
    }


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
    
    
    EPENTRY (Eval) ;

    r -> numEvals++ ;
    *pRet = NULL ;

    /*if (r -> bDebug & dbgCacheDisable)
        return EvalAllNoCache (r, sArg, pRet) ;
    */
    /* Already compiled ? */

    ppSV = hv_fetch(r -> Buf.pFile -> pCacheHash, (char *)&nFilepos, sizeof (nFilepos), 1) ;  
    if (ppSV == NULL)
        return rcHashError ;

    if (*ppSV != NULL && SvTYPE (*ppSV) == SVt_PV)
        {
        strncpy (r -> errdat1, SvPV(*ppSV, na), sizeof (r -> errdat1) - 1) ; 
        LogError (r, rcEvalErr) ;
        return rcEvalErr ;
        }

    lprintf (r, "CV ppSV=%s type=%d\n", *ppSV?"ok":"NULL", *ppSV?SvTYPE (*ppSV):0) ;               
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
    
    
    EPENTRY (Eval) ;

    r -> numEvals++ ;
    *pRet = NULL ;

    /*if (r -> bDebug & dbgCacheDisable)
        return EvalAllNoCache (r, sArg, pRet) ;
    */
    /* Already compiled ? */

    ppSV = hv_fetch(r -> Buf.pFile -> pCacheHash, (char *)&nFilepos, sizeof (nFilepos), 1) ;  
    if (ppSV == NULL)
        return rcHashError ;

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
    
    EPENTRY (EvalTrans) ;


    r -> numEvals++ ;
    *pRet = NULL ;

    /*
    if (r -> bDebug & dbgCacheDisable)
        {
        /  * strip off all <HTML> Tags *  /
        TransHtml (r, sArg, 0) ;
        
        return EvalAllNoCache (r, sArg, pRet) ;
        }
    */
    /* Already compiled ? */

    ppSV = hv_fetch(r -> Buf.pFile -> pCacheHash, (char *)&nFilepos, sizeof (nFilepos), 1) ;  
    if (ppSV == NULL)
        return rcHashError ;

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
    
    EPENTRY (EvalTrans) ;


    r -> numEvals++ ;
    *pRet = NULL ;

    /* Already compiled ? */

    ppSV = hv_fetch(r -> Buf.pFile -> pCacheHash, (char *)&nFilepos, sizeof (nFilepos), 1) ;  
    if (ppSV == NULL)
        return rcHashError ;

    if (*ppSV != NULL && SvTYPE (*ppSV) == SVt_PV)
        {
        strncpy (r -> errdat1, SvPV(*ppSV, na), sizeof (r -> errdat1) - 1) ; 
        LogError (r, rcEvalErr) ;
        return rcEvalErr ;
        }

    if (*ppSV == NULL || SvTYPE (*ppSV) != SVt_PVCV)
        {
        int	rc ;
	HV *  pImportStash = r -> pImportStash ;
	r -> pImportStash = NULL ; /* temporarely disable import */

	/* strip off all <HTML> Tags */
        TransHtml (r, sArg, 0) ;

	rc = EvalAndCall (r, sArg, ppSV, G_SCALAR, pRet) ;

       	r -> pImportStash = pImportStash ; 

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
    
    
    EPENTRY (EvalSub) ;

    r -> numEvals++ ;


    /* Already compiled ? */

    ppSV = hv_fetch(r -> Buf.pFile -> pCacheHash, (char *)&nFilepos, sizeof (nFilepos), 1) ;  
    if (ppSV == NULL)
        return rcHashError ;

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

        if (r -> pImportStash && *ppSV && SvTYPE (*ppSV) == SVt_PVCV)
	    {
	    hv_store (r -> Buf.pFile -> pExportHash, (char *)sName, len, newRV_inc(*ppSV), 0) ;
	    
	    if (r -> bDebug & dbgImport)
		lprintf (r, "[%d]IMP:  %s -> %s (%x)\n", r -> nPid, sName, HvNAME (r -> pImportStash), *ppSV) ;

	    /* 
	    gvp = (GV**)hv_fetch(r -> pImportStash, (char *)sName, len, 1);
	    
	    if (!gvp || *gvp == (GV*)&PL_sv_undef)
		{
		((char *)sName)[len] = endc ;
		return rcHashError ;
		}

	    gv = *gvp;
	    if (SvTYPE(gv) != SVt_PVGV) 
		gv_init(gv, r -> pImportStash, (char *)sName, len, 0);
	    
	    lprintf (r, "sv_any=%x\n", gv -> sv_any) ;
	    
	    SvREFCNT_dec (GvCV (gv)) ;  
	    GvCV (gv) = (CV *)*ppSV ; 
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

    /* Already compiled ? */

    ppSV = hv_fetch(r -> Buf.pFile -> pCacheHash, (char *)&nFilepos, sizeof (nFilepos), 1) ;  
    if (ppSV == NULL)
        return rcHashError ;

    if (*ppSV != NULL && SvTYPE (*ppSV) == SVt_PV)
        {
        strncpy (r -> errdat1, SvPV(*ppSV, na), sizeof (r -> errdat1) - 1) ; 
        LogError (r, rcEvalErr) ;
        return rcEvalErr ;
        }

    if (*ppSV == NULL || SvTYPE (*ppSV) != SVt_PVCV)
	{ /* Not already compiled -> build a perl frame program */
	char * pStart = r -> Buf.pBuf ;
	char * pEnd   = r -> Buf.pEndPos ;
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
            ProcessBlock (r, pStart - r -> Buf.pBuf, r -> Buf.pEndPos - r -> Buf.pBuf, 1) ;
            return ok ;
            }


	OutputToMemBuf (r, NULL, r -> Buf.pEndPos - r -> Buf.pBuf) ;

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


            sprintf (buf, "\n$___b=$_[0] -> ProcessBlock (%d,%d,%d);\ngoto \"b$___b\";\nb%d:;\n", pStart - r -> Buf.pBuf, pOpen - pStart, nBlockNo, nBlockNo) ;
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
