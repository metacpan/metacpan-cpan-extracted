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
#   $Id: epmain.c 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################*/


#include "ep.h"
#include "epmacro.h"




/*---------------------------------------------------------------------------
* DoLogError
*/
/*!
*
* \_en									   
* Logs the occurence of an error to the embperl logfile and the httpd error log
*                                                                          
* @param    r       the request object (maybe NULL)
* @param    a       the application object (maybe NULL)
* @param    rc      the error code
* @param    errdat1 addtional information
* @param    errdat2 addtional information
* \endif                                                                       
*
* \_de									   
* logged das auftreten eines Fehler in das Embperl Logfile und den httpd
* error log
*                                                                          
* @param    r       das Requestobjekt (kann NULL sein)
* @param    a       das Applikationobjekt (kann NULL sein)
* @param    rc      Fehlercode
* @param    errdat1 Zusätzliche Informationen
* @param    errdat2 Zusätzliche Informationen
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

static char * DoLogError (/*i/o*/ struct tReq * r,
                        /*i/o*/ struct tApp * a,
			/*in*/ int   rc,
                        /*in*/ const char * errdat1,
                        /*in*/ const char * errdat2) 

    {
    const char * msg ;
    char * sText ;
    SV *   pSV ;
    SV *   pSVLine = NULL ;
    STRLEN l ;
    pid_t  nPid ;

#ifdef PERL_IMPLICIT_CONTEXT
    pTHX ;
    if (r)
        aTHX = r -> pPerlTHX ;
    else if (a)
        aTHX = a -> pPerlTHX ;
    else
        aTHX = PERL_GET_THX ;
#endif


    if (r)
        {            
        r -> errdat1 [sizeof (r -> errdat1) - 1] = '\0' ;
        r -> errdat2 [sizeof (r -> errdat2) - 1] = '\0' ;

        GetLineNo (r) ;

        errdat1 = r -> errdat1 ;
        errdat2 = r -> errdat2 ;

        if (rc != rcPerlWarn)
            r -> bError = 1 ;
        nPid = r -> pThread -> nPid ;
        a = r -> pApp ;
        }
    else if (a)
        {
        nPid = a -> pThread -> nPid ;
        }
    else
        nPid = getpid() ;

    
    if (!errdat1)
        errdat1 = "" ;
    if (!errdat2)
        errdat2 = "" ;
    
    switch (rc)
        {
        case ok:                        msg ="[%d]ERR:  %d: %s ok%s%s" ; break ;
        case rcStackOverflow:           msg ="[%d]ERR:  %d: %s Stack Overflow%s%s" ; break ;
        case rcArgStackOverflow:        msg ="[%d]ERR:  %d: %s Argumnet Stack Overflow (%s)%s" ; break ;
        case rcStackUnderflow:          msg ="[%d]ERR:  %d: %s Stack Underflow%s%s" ; break ;
        case rcEndifWithoutIf:          msg ="[%d]ERR:  %d: %s endif without if%s%s" ; break ;
        case rcElseWithoutIf:           msg ="[%d]ERR:  %d: %s else without if%s%s" ; break ;
        case rcEndwhileWithoutWhile:    msg ="[%d]ERR:  %d: %s endwhile without while%s%s" ; break ;
        case rcEndtableWithoutTable:    msg ="[%d]ERR:  %d: %s blockend <%s> does not match blockstart <%s>" ; break ;
        case rcTablerowOutsideOfTable:  msg ="[%d]ERR:  %d: %s <tr> outside of table%s%s" ; break ;
        case rcCmdNotFound:             msg ="[%d]ERR:  %d: %s Unknown Command %s%s" ; break ;
        case rcOutOfMemory:             msg ="[%d]ERR:  %d: %s Out of memory %s %s" ; break ;
        case rcPerlVarError:            msg ="[%d]ERR:  %d: %s Perl variable error %s%s" ; break ;
        case rcHashError:               msg ="[%d]ERR:  %d: %s Perl hash error, %%%s does not exist%s" ; break ;
        case rcArrayError:              msg ="[%d]ERR:  %d: %s Perl array error , @%s does not exist%s" ; break ;
        case rcFileOpenErr:             msg ="[%d]ERR:  %d: %s File %s open error: %s" ; break ;    
        case rcLogFileOpenErr:          msg ="[%d]ERR:  %d: %s Logfile %s open error: %s" ; break ;    
        case rcMissingRight:            msg ="[%d]ERR:  %d: %s Missing right %s%s" ; break ;
        case rcNoRetFifo:               msg ="[%d]ERR:  %d: %s No Return Fifo%s%s" ; break ;
        case rcMagicError:              msg ="[%d]ERR:  %d: %s Perl Magic Error%s%s" ; break ;
        case rcWriteErr:                msg ="[%d]ERR:  %d: %s File write Error%s%s" ; break ;
        case rcUnknownNameSpace:        msg ="[%d]ERR:  %d: %s Namespace %s unknown%s" ; break ;
        case rcInputNotSupported:       msg ="[%d]ERR:  %d: %s Input not supported in mod_perl mode%s%s" ; break ;
        case rcCannotUsedRecursive:     msg ="[%d]ERR:  %d: %s Cannot be called recursivly in mod_perl mode%s%s" ; break ;
        case rcEndtableWithoutTablerow: msg ="[%d]ERR:  %d: %s </tr> without <tr>%s%s" ; break ;
        case rcEndtextareaWithoutTextarea: msg ="[%d]ERR:  %d: %s </textarea> without <textarea>%s%s" ; break ;
        case rcEvalErr:                 msg ="[%d]ERR:  %d: %s Error in Perl code: %s%s" ; break ;
	case rcNotCompiledForModPerl:   msg ="[%d]ERR:  %d: %s Embperl is not compiled for mod_perl. Rerun Makefile.PL and give the correct Apache source tree location %s%s" ; break ;
        case rcExecCGIMissing:          msg ="[%d]ERR:  %d: %s Forbidden %s: Options ExecCGI not set in your Apache configs%s" ; break ;
        case rcIsDir:                   msg ="[%d]ERR:  %d: %s Forbidden %s is a directory%s" ; break ;
        case rcXNotSet:                 msg ="[%d]ERR:  %d: %s Forbidden %s X Bit not set%s" ; break ;
        case rcNotFound:                msg ="[%d]ERR:  %d: %s Not found '%s', searched: %s" ; break ;
        case rcTokenNotFound:           msg ="[%d]ERR:  %d: %s Token not found '%s', %s" ; break ;
        case rcUnknownVarType:          msg ="[%d]ERR:  %d: %s Type for Variable %s is unknown %s" ; break ;
        case rcPerlWarn:                msg ="[%d]ERR:  %d: %s Warning in Perl code: %s%s" ; break ;
        case rcVirtLogNotSet:           msg ="[%d]ERR:  %d: %s EMBPERL_VIRTLOG must be set, when dbgLogLink is set %s%s" ; break ;
        case rcMissingInput:            msg ="[%d]ERR:  %d: %s Sourcedata/-file missing %s%s" ; break ;
        case rcUntilWithoutDo:          msg ="[%d]ERR:  %d: %s until without do%s%s" ; break ;
        case rcEndforeachWithoutForeach:msg ="[%d]ERR:  %d: %s endforeach without foreach%s%s" ; break ;
        case rcMissingArgs:             msg ="[%d]ERR:  %d: %s Too few arguments%s%s" ; break ;
        case rcNotAnArray:              msg ="[%d]ERR:  %d: %s Second Argument must be array/list%s%s" ; break ;
        case rcCallInputFuncFailed:     msg ="[%d]ERR:  %d: %s Call to Input Function failed: %s%s" ; break ;
        case rcCallOutputFuncFailed:    msg ="[%d]ERR:  %d: %s Call to Output Function failed: %s%s" ; break ;
        case rcSubNotFound:             msg ="[%d]ERR:  %d: %s Call to unknown Embperl macro %s%s" ; break ;
        case rcImportStashErr:          msg ="[%d]ERR:  %d: %s Package %s for import unknown%s" ; break ;
        case rcCGIError:                msg ="[%d]ERR:  %d: %s Setup of CGI.pm failed: %s%s" ; break ;
        case rcUnclosedHtml:            msg ="[%d]ERR:  %d: %s Unclosed HTML tag <%s> at end of file %s" ; break ;
        case rcUnclosedCmd:             msg ="[%d]ERR:  %d: %s Unclosed command [$ %s $] at end of file %s" ; break ;
	case rcNotAllowed:              msg ="[%d]ERR:  %d: %s Forbidden %s: Does not match EMBPERL_ALLOW %s" ; break ;
        case rcNotHashRef:              msg ="[%d]ERR:  %d: %s %s need hashref in '%s'" ; break ; 
	case rcTagMismatch:		msg ="[%d]ERR:  %d: %s Endtag '%s' doesn't match starttag '%s'" ; break ; 
	case rcCleanupErr:		msg ="[%d]ERR:  %d: %s Error in cleanup %s%s" ; break ; 
	case rcCryptoWrongHeader:	msg ="[%d]ERR:  %d: %s Decrypt-error: Not encrypted (%s)%s" ; break ; 
	case rcCryptoWrongSyntax:	msg ="[%d]ERR:  %d: %s Decrypt-error: Wrong syntax (%s)%s" ; break ; 
	case rcCryptoNotSupported:	msg ="[%d]ERR:  %d: %s Decrypt-error: Not supported (%s)%s" ; break ; 
	case rcCryptoBufferOverflow:	msg ="[%d]ERR:  %d: %s Decrypt-error: Buffer overflow (%s)%s" ; break ; 
	case rcCryptoErr:		msg ="[%d]ERR:  %d: %s Decrypt-error: OpenSSL error (%s)%s" ; break ; 
	case rcUnknownProvider:	        msg ="[%d]ERR:  %d: %s Unknown Provider %s %s" ; break ; 
	case rcXalanError:	        msg ="[%d]ERR:  %d: %s Xalan Error: %s: %s" ; break ; 
	case rcLibXSLTError:	        msg ="[%d]ERR:  %d: %s LibXSLT Error: %s: %s" ; break ; 
        case rcMissingParam:		msg ="[%d]ERR:  %d: %s Missing Parameter %s %s" ; break ; 
        case rcNotCodeRef:		msg ="[%d]ERR:  %d: %s %s need coderef in '%s'" ; break ; 
        case rcUnknownRecipe:		msg ="[%d]ERR:  %d: %s Unknown recipe '%s'" ; break ; 
        case rcTypeMismatch:		msg ="[%d]ERR:  %d: %s Unsupported Outputformat %s of %s" ; break ; 
        case rcChdirError:		msg ="[%d]ERR:  %d: %s Cannot change to directory %s %s" ; break ; 
        case rcUnknownSyntax:		msg ="[%d]ERR:  %d: %s Unknown syntax '%s'" ; break ; 
        case rcForbidden:		msg ="[%d]ERR:  %d: %s Access Forbidden for '%s'" ; break ; 
        case rcDecline:		        msg ="[%d]ERR:  %d: %s Decline for '%s'" ; break ; 
        case rcCannotCheckUri:          msg ="[%d]ERR:  %d: %s Cannot check URI against ALLOW and/or URIMATCH because URI is unknown" ; break ; 
        case rcSetupSessionErr:         msg ="[%d]ERR:  %d: %s Embperl Session handling DISABLED because of the following error: %s\nSet EMBPERL_SESSION_HANDLER_CLASS to 'no' to avoid this message. %s" ; break ; 
        case rcRefcntNotOne:            msg ="[%d]ERR:  %d: %s There is still %s reference(s) to the %s object, while there shouldn't be any." ; break ; 
        case rcApacheErr:               msg ="[%d]ERR:  %d: %s Apache returns Error: %s %s" ; break ; 
        case rcTooDeepNested:           msg ="[%d]ERR:  %d: %s Source data is too deep nested %s %s" ; break ; 
        case rcUnknownOption:           msg ="[%d]ERR:  %d: %s Unknown option '%s' in configuration directive '%s'" ; break ; 
        case rcTimeFormatErr:           msg ="[%d]ERR:  %d: %s Format error in %s = %s" ; break ;
        case rcSubCallNotRequest:       msg ="[%d]ERR:  %d: %s A Embperl sub is called and no Embperl request is running  %s %s" ; break ;
        case rcNotScalarRef:            msg ="[%d]ERR:  %d: %s %s need scalar in '%s'" ; break ; 

	default:                        msg ="[%d]ERR:  %d: %s Error (no description) %s %s" ; break ; 
        }

    if (r && ((rc != rcPerlWarn && rc != rcEvalErr) || r -> errdat1[0] == '\0'))
        {
        char * p = NULL ;
        char buf[20] = "" ;
        char * f ;
        tComponent * c = &r -> Component ;
        if (!(f = c -> sSourcefile))
            {
            c = r -> Component.pPrev ;
            if (c && !(f = c -> sSourcefile))
                f = "", p = "" ;
            }
        if (f)
            {
            if (!p)
                p = strrchr (f, '/') ;
            if (p)
                p++ ;
            else
                {
                p = strrchr (f, '\\') ;
                if (!p)
                    p = f ;
                else
                    p++ ;
                }
            }
        else
            if (!p)
                p = "" ;
        if (c && c -> nSourceline)
            sprintf (buf, "(%d)", c -> nSourceline) ;
        pSVLine = newSVpvf ("%s%s:", p, buf) ;
	newSVpvf2(pSVLine) ;
        }

   
    
    pSV = newSVpvf (msg, nPid , rc, pSVLine?SvPV(pSVLine, l):"", errdat1, errdat2) ;
    newSVpvf2(pSV) ;

    if (r && r -> Component.Config.bOptions & optShowBacktrace)
        {
        tComponent * c = &r -> Component ;
        while (c)
            {
            sv_catpvf(pSV, "\n    * %s", (!c -> sSourcefile)?"<no filename available>":c -> sSourcefile) ;
            c = c -> pPrev ;
            }
        }


    if (pSVLine)
        SvREFCNT_dec(pSVLine) ;

    sText = SvPV (pSV, l) ;    
    
    if (a)
        lprintf (a,  "%s\n", sText) ;

#ifdef APACHE
    if (r && r -> pApacheReq)
        {
#ifdef APLOG_ERR
        if (rc != rcPerlWarn)
            ap_log_error (APLOG_MARK, APLOG_ERR | APLOG_NOERRNO, APLOG_STATUSCODE r -> pApacheReq -> server, "%s", sText) ;
        else
            ap_log_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, APLOG_STATUSCODE r -> pApacheReq -> server, "%s", sText) ;
#else
        log_error (sText, r -> pApacheReq -> server) ;
#endif
        }
    else
#endif
        {
#ifdef WIN32
        PerlIO_printf (PerlIO_stderr(), "%s\n", sText) ;
        PerlIO_flush (PerlIO_stderr()) ;
#else
#undef fprintf
#undef fflush
        fprintf (stderr, "%s\n", sText) ;
        fflush (stderr) ; 
#endif
        }
    
    if (r)
        {            
        if (rc == rcPerlWarn)
            strncpy (r -> lastwarn, r -> errdat1, sizeof (r -> lastwarn) - 1) ;

        if (r -> pErrArray)
            {
            av_push (r -> pErrArray, r -> pErrSV?SvREFCNT_inc(r -> pErrSV):pSV) ;
            }
        else
	    SvREFCNT_dec (pSV) ;

        r -> errdat1[0] = '\0' ;
        r -> errdat2[0] = '\0' ;
        }
    else
        SvREFCNT_dec (pSV) ;

    return sText ;
    }

/*---------------------------------------------------------------------------
* LogErrorParam
*/
/*!
*
* \_en									   
* Logs the occurence of an error to the embperl logfile and the httpd error log
*                                                                          
* @param    a       the application object
* @param    rc      the error code
* @param    errdat1 addtional information
* @param    errdat2 addtional information
* \endif                                                                       
*
* \_de									   
* logged das auftreten eines Fehler in das Embperl Logfile und den httpd
* error log
*                                                                          
* @param    a       das Applikationobjekt
* @param    rc      Fehlercode
* @param    errdat1 Zusätzliche Informationen
* @param    errdat2 Zusätzliche Informationen
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */


char * LogErrorParam   (/*i/o*/ struct tApp * a,
			/*in*/ int   rc,
                        /*in*/ const char * errdat1,
                        /*in*/ const char * errdat2) 
    {
    return DoLogError (NULL, a, rc, errdat1, errdat2) ;
    }


/*---------------------------------------------------------------------------
* LogError
*/
/*!
*
* \_en									   
* Logs the occurence of an error to the embperl logfile and the httpd error log
* Addtional information, like stack backtrace, is taken from the request object
*                                                                          
* @param    r       the request object
* @param    rc      the error code
* \endif                                                                       
*
* \_de									   
* Logged das auftreten eines Fehler in das Embperl Logfile und den httpd
* error log. Zusätzlich Informationen, wie z.B. ein Stackbacktrace, werden
* dem Requestobjket entnommen
*                                                                          
* @param    a       das Requestobjekt
* @param    rc      Fehlercode
* \endif                                                                       
*                                                                          
* ------------------------------------------------------------------------ */

char * LogError (/*i/o*/ register req * r,
			/*in*/ int   rc)
                        
                        
    {
    return DoLogError (r, NULL, rc, NULL, NULL) ;
    }


#if defined (_MDEBUG) && defined (WIN32)

static int EmbperlCRTDebugOutput( int reportType, char *userMessage, int *retVal )
    {   
    lprintf (CurrReq, "[%d]CRTDBG: %s\n", pCurrReq -> nPid, userMessage) ;  

    return TRUE ;
    }

#endif

/* */
/* Magic */
/* */

void NewEscMode (/*i/o*/ register req * r,
			           SV * pSV)

    {
    if (r -> Component.Config.nEscMode & escXML && !r -> Component.bEscInUrl)
	r -> Component.pNextEscape = Char2XML ;
    else if (r -> Component.Config.nEscMode & escHtml && !r -> Component.bEscInUrl)
	{
    	struct tCharTrans * pChar2Html  ;

    	if (r -> Config.nOutputEscCharset == ocharsetLatin1)
	    	pChar2Html = Char2Html ;
	else if (r -> Config.nOutputEscCharset == ocharsetLatin2)
	    	pChar2Html = Char2HtmlLatin2 ;
	else
	    	pChar2Html = Char2HtmlMin ;
	
	r -> Component.pNextEscape = pChar2Html ;
	}
    else if (r -> Component.Config.nEscMode & escUrl)
        r -> Component.pNextEscape = Char2Url ;
    else 
        r -> Component.pNextEscape = NULL ;

    if (r -> Component.bEscModeSet < 1)
	{
        r -> Component.pCurrEscape = r -> Component.pNextEscape ;
        r -> Component.nCurrEscMode = r -> Component.Config.nEscMode ;
	}

    if (r -> Component.bEscModeSet < 0 && pSV && SvOK (pSV))
        r -> Component.bEscModeSet = 1 ;
    }


#ifdef UNUSED


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Localise op_mask then opmask_add()                                           */
/*                                                                              */
/* Just copied from Opcode.xs                                                   */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static void
opmask_addlocal(pTHX_
                SV *   opset,
                char * op_mask_buf) 
    {
    char *orig_op_mask = op_mask;
    int i,j;
    char *bitmask;
    STRLEN len;
    int myopcode  = 0;
    int opset_len = (maxo + 7) / 8 ;

    SAVEPPTR(op_mask);
    op_mask = &op_mask_buf[0];
    if (orig_op_mask)
	Copy(orig_op_mask, op_mask, maxo, char);
    else
	Zero(op_mask, maxo, char);


    /* OPCODES ALREADY MASKED ARE NEVER UNMASKED. See opmask_addlocal()	*/

    bitmask = SvPV(opset, len);
    for (i=0; i < opset_len; i++)
        {
	U16 bits = bitmask[i];
	if (!bits)
            {	/* optimise for sparse masks */
	    myopcode += 8;
	    continue;
	    }
	for (j=0; j < 8 && myopcode < maxo; )
	    op_mask[myopcode++] |= bits & (1 << j++);
        }
    }

#endif


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Create Session cookie                                                        */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static char * CreateSessionCookie (/*i/o*/ register req * r,
				 /*in*/  SV * pSessionObj,
				 /*in*/  char type,
                                 /*in*/  int  bReturnCookie)
    
    {
    SV *    pSVID = NULL ;
    SV *    pSVUID = NULL ;
    char *  pUID = NULL ;
    char *  pInitialUID = NULL ;
    STRLEN  ulen = 0 ;
    STRLEN  ilen = 0 ;
    IV	    bModified = 0 ;
    char *  pCookie = NULL ;
    STRLEN  ldummy ;
    tAppConfig * pCfg = &r -> pApp -> Config ;
    epTHX ;

    if (r -> nSessionMgnt)
	{			
	dSP;                            /* initialize stack pointer      */
	int n ;

	PUSHMARK(sp);                   /* remember the stack pointer    */
	XPUSHs(pSessionObj) ;            /* push pointer to obeject */
	XPUSHs(sv_2mortal(newSViv(bReturnCookie?0:1))) ;       /* init session if not for cookie */
	PUTBACK;
	n = perl_call_method ("getids", G_ARRAY) ; /* call the function             */
	SPAGAIN;
	if (n > 2)
	    {
	    int  savewarn = dowarn ;
	    dowarn = 0 ; /* no warnings here */
	    bModified = POPi ;
	    pSVUID = POPs;
	    pUID = SvPV (pSVUID, ulen) ;
	    pSVID = POPs;
	    pInitialUID = SvPV (pSVID, ilen) ;
	    dowarn = savewarn ;
	    }
	PUTBACK;
	
	if (r -> Config.bDebug & dbgSession)  
	    lprintf (r -> pApp,  "[%d]SES:  Received Cookie ID: %s  New Cookie ID: %s  %s data is%s modified\n", r -> pThread -> nPid, pInitialUID, pUID, type == 's'?"State":"User", bModified?"":" NOT") ; 

	if (ilen > 0 && (ulen == 0 || (!bModified && strcmp ("!DELETE", pInitialUID) == 0)))
	    { /* delete cookie */
            if (bReturnCookie)
                {                    
                pCookie = ep_pstrcat (r -> pPool, pCfg -> sCookieName, type == 's'?"s=":"=", "; expires=Thu, 1-Jan-1970 00:00:01 GMT", NULL) ;
                if (pCfg -> sCookieDomain)
                    pCookie = ep_pstrcat (r -> pPool, pCookie, "; domain=", pCfg -> sCookieDomain, NULL) ;
                if (pCfg -> sCookiePath)
                    pCookie = ep_pstrcat (r -> pPool, pCookie, "; path=", pCfg -> sCookiePath, NULL) ;
                if (pCfg -> bCookieSecure)
                    pCookie = ep_pstrcat (r -> pPool, pCookie, "; secure", NULL) ;
                }

	    if (r -> Config.bDebug & dbgSession)  
		lprintf (r -> pApp,  "[%d]SES:  Delete Cookie -> %s\n", r -> pThread -> nPid, pCookie) ;
	    }
	else if (ulen > 0 && 
		    ((bModified && (ilen == 0 || strcmp (pInitialUID, pUID) !=0)) ||
		     (r -> nSessionMgnt & 4) || !bReturnCookie))
	    {
            if (bReturnCookie)
                {                    
                pCookie = ep_pstrcat (r -> pPool, pCfg -> sCookieName, type == 's'?"s=":"=", pUID, NULL) ;
                if (pCfg -> sCookieDomain)
                    pCookie = ep_pstrcat (r -> pPool, pCookie, "; domain=", pCfg -> sCookieDomain, NULL) ;
                if (pCfg -> sCookiePath)
                    pCookie = ep_pstrcat (r -> pPool, pCookie, "; path=", pCfg -> sCookiePath, NULL) ;
                if (r -> sCookieExpires)
                    pCookie = ep_pstrcat (r -> pPool, pCookie, "; expires=", r -> sCookieExpires, NULL) ;
                if (pCfg -> bCookieSecure)
                    pCookie = ep_pstrcat (r -> pPool, pCookie, "; secure", NULL) ;

	        if (r -> Config.bDebug & dbgSession)  
		    lprintf (r -> pApp,  "[%d]SES:  Send Cookie -> %s\n", r -> pThread -> nPid, pCookie) ; 
                }
            else
                {
                pCookie = ep_pstrdup (r -> pPool, SvPV(pSVUID, ldummy)) ;
	        if (r -> Config.bDebug & dbgSession)  
		    lprintf (r -> pApp,  "[%d]SES:  Add ID to URL type=%c id=%s\n", r -> pThread -> nPid, type, pCookie) ; 
                }
	    }
	}
    return pCookie ;
    }
    

#ifdef UNUSED
                     
/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Setup Safe Namespace                                                         */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static void SetupSafeNamespace (/*i/o*/ register req * r)

    {                 
    GV *    gv;

    dTHR ;
    epTHX ;

	/* The following is borrowed from Opcode.xs */

    if (r -> Component.Config.bOptions & optOpcodeMask)
        opmask_addlocal(aTHX_ r -> Component.Config.pOpcodeMask, r -> Component.op_mask_buf);

        
    if (r -> Component.Config.bOptions & optSafeNamespace)
        {
        save_aptr(&endav);
        endav = (AV*)sv_2mortal((SV*)newAV()); /* ignore END blocks for now	*/

        save_hptr(&defstash);		/* save current default stack	*/
        /* the assignment to global defstash changes our sense of 'main'	*/
        defstash = gv_stashpv(r -> Component.sCurrPackage, GV_ADDWARN); /* should exist already	*/

        if (r -> Component.Config.bDebug)
            lprintf (r -> pApp,  "[%d]REQ:  switch to safe namespace %s\n", r -> pThread -> nPid, r -> Component.sCurrPackage) ;


        /* defstash must itself contain a main:: so we'll add that now	*/
        /* take care with the ref counts (was cause of long standing bug)	*/
        /* XXX I'm still not sure if this is right, GV_ADDWARN should warn!	*/
        gv = gv_fetchpv("main::", GV_ADDWARN, SVt_PVHV);
        sv_free((SV*)GvHV(gv));
        GvHV(gv) = (HV*)SvREFCNT_inc(defstash);
        }
    }

#endif

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Reset Request                                                                */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static int ResetRequest (/*i/o*/ register req * r,
			/*in*/ char *  sInputfile)

    {
    epTHX ;    

    if (r -> Component.Config.bDebug)
        {
        clock_t cl = clock () ;
        time_t t ;
        struct tm * tm ;
        
        time (&t) ;        
        tm =localtime (&t) ;
        
        lprintf (r -> pApp,  "[%d]PERF: input = %s\n", r -> pThread -> nPid, sInputfile?sInputfile:"???") ;
#ifdef CLOCKS_PER_SEC
        lprintf (r -> pApp,  "[%d]PERF: Time: %d ms ", r -> pThread -> nPid, ((cl - r -> startclock) * 1000 / CLOCKS_PER_SEC)) ;
#else
        lprintf (r -> pApp,  "[%d]PERF: ", r -> pThread -> nPid) ;
#endif        
        lprintf (r -> pApp,  "\n") ;    
        lprintf (r -> pApp,  "[%d]%sRequest finished. %s. Entry-SVs: %d  Exit-SVs: %d \n", r -> pThread -> nPid,
	    (r -> Component.pPrev?"Sub-":""), asctime(tm), r -> stsv_count, sv_count) ;
#ifdef DMALLOC
        dmalloc_message ( "[%d]%sRequest finished. Entry-SVs: %d Exit-SVs: %d \n", r -> pThread -> nPid,
	    (r -> Component.pPrev?"Sub-":""), r -> stsv_count, sv_count) ;
#endif        
        }

    
    r -> Component.pCurrPos = NULL ;


    FlushLog (r -> pApp) ;

    r -> Component.nSourceline = 1 ;
    r -> Component.pSourcelinePos = NULL ;    
    r -> Component.pLineNoCurrPos = NULL ;    

    r -> Component.bReqRunning = 0 ;

    /*
    av_clear (r -> pErrFill) ;
    av_clear (r -> pErrState) ;
    */

    return ok ;
    }

    
/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Start the output stream                                                      */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

    
static int StartOutput (/*i/o*/ register req * r)

    {
    int  bOutToMem = r -> Component.Param.pOutput && SvROK (r -> Component.Param.pOutput) ;
    epTHX_

#ifdef APACHE
    if (r -> pApacheReq && r -> pApacheReq -> main)
    	r -> Config.bOptions |= optEarlyHttpHeader ; /* do not direct output to memory on internal redirect */
#endif
    if (bOutToMem)
    	r -> Config.bOptions &= ~optEarlyHttpHeader ;

    if (r -> Component.pPrev || r -> Component.pImportStash)
    	r -> Config.bOptions &= ~optSendHttpHeader ;


    if (r -> Config.bOptions & optEarlyHttpHeader)
        {
#ifdef APACHE
        if (r -> pApacheReq == NULL)
            {
#endif
            if (r -> Config.bOptions & optSendHttpHeader)
                oputs (r, "Content-type: text/html\n\n") ;

#ifdef APACHE
            }
        else
            {
#ifndef APACHE2
            if (r -> pApacheReq -> main == NULL && (r -> Config.bOptions & optSendHttpHeader))
            	send_http_header (r -> pApacheReq) ;
#endif
#ifndef WIN32
	    /* shouldn't be necessary for newer mod_perl versions !? */
	    /* mod_perl_sent_header(r -> pApacheReq, 1) ; */
#endif
            if (r -> pApacheReq -> header_only)
            	return ok ;
            }
#endif
        }
    else
        {
        /*
	if (r -> nIOType == epIOCGI && (r -> Config.bOptions & optSendHttpHeader))
            oputs (r, "Content-type: text/html\n\n") ;
        */
	
        oBegin (r) ;
        }


    if ((r -> Config.nSessionMode & smodeSDatParam) && !r -> Component.pPrev)
	{
	char * pCookie = CreateSessionCookie (r, r -> pApp -> pStateObj, 's', 0) ; 
        /* lprintf (r -> pApp,  "opt %x optadd %x options %x cookie %s\n", optAddStateSessionToLinks, r -> Component.Config.bOptions & optAddStateSessionToLinks, r -> Component.Config.bOptions, SvPV(pCookie, l)) ; */
	if (pCookie)
            r -> sSessionID = ep_pstrcat  (r -> pPool, r -> pApp -> Config.sCookieName, "=", pCookie, NULL) ;
        }
    
    if ((r -> Config.nSessionMode & smodeUDatParam) && !r -> Component.pPrev)
        {
	char * pCookie = CreateSessionCookie (r, r -> pApp -> pUserObj, 'u', 0) ; 
        if (pCookie)
            {
            if (r -> sSessionID)
                r -> sSessionID = ep_pstrcat  (r -> pPool, r -> sSessionID, ":", pCookie, NULL) ;
            else
		r -> sSessionID = ep_pstrcat  (r -> pPool, r -> pApp -> Config.sCookieName, "=:", pCookie, NULL) ;
            }
        }

    
    
    return ok ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* GenerateErrorPage                                                            */
/*                                                                              */
/* ---------------------------------------------------------------------------- */



static int GenerateErrorPage (/*i/o*/ register req * r,
               		      /*in*/  int    rc)
                     

    {
    epTHX_    

    dSP;                            /* initialize stack pointer      */
    
    if (r -> pApp -> Config.sMailErrorsTo)
        {
        /* --- check if error should be mailed --- */
	tApp * a = r -> pApp ;
        time_t nTime = time(NULL) ;

        if (a -> nErrorsLastTime < nTime - a -> Config.nMailErrorsResetTime)
            a -> nErrorsCount = 0 ;
        else if (a -> nErrorsLastSendTime < nTime - a -> Config.nMailErrorsResendTime)
            a -> nErrorsCount = 0 ;
        a -> nErrorsLastTime = nTime ;
        if (a -> Config.nMailErrorsLimit == 0 || a -> nErrorsCount < a -> Config.nMailErrorsLimit)
            {
            a -> nErrorsCount++ ;
            a -> nErrorsLastSendTime = nTime ;

            PUSHMARK(sp);    
            XPUSHs(r -> pApp -> _perlsv) ;   
            XPUSHs(r -> _perlsv) ;   
            PUTBACK;
            perl_call_method ("mail_errors", G_DISCARD) ; 
            SPAGAIN ;
            }
        }
    
    if (r -> Component.Config.bOptions & optReturnError)
	{
	oRollbackOutput (r, NULL) ;
	if (r -> Component.Param.pOutput && SvROK (r -> Component.Param.pOutput))
	    {
	    sv_setsv (SvRV (r -> Component.Param.pOutput), &sv_undef) ;
	    }
    	r -> bExit = 1 ;
	return ok ; /* No further output or header, this should be handle by the server */
	}    
    else if (r -> Component.pOutput && !(r -> Component.Config.bOptions & optDisableEmbperlErrorPage))
	{
        oRollbackOutput (r, NULL) ; /* forget everything outputed so far */
	oBegin (r) ;

        SPAGAIN ;
	PUSHMARK(sp);   
        XPUSHs(r -> pApp -> _perlsv) ;   
	XPUSHs(r -> _perlsv) ;     
	PUTBACK;
	perl_call_method ("send_error_page", G_DISCARD) ; 
        SPAGAIN ;
#ifdef APACHE
	if (r -> pApacheReq)
	    {
	    if (rc >= 400)
	        r -> pApacheReq -> status = rc ;
            else
                r -> pApacheReq -> status = 500 ;
	    }
#endif
        
	SetHashValueInt (r, r -> pThread -> pHeaderHash, "Content-Length", GetContentLength (r) ) ;
        }
    r -> bError = 1 ;

    return ok ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* SendHttpHeader                                                               */
/*                                                                              */
/* ---------------------------------------------------------------------------- */



int embperl_SendHttpHeader (/*i/o*/ register req * r)

    {                    
    epTHX_
    char * pCookie = NULL ;

    if (r -> Config.nSessionMode & smodeUDatCookie)
        pCookie = CreateSessionCookie (r, r -> pApp -> pUserObj, 'u', 1) ;
	
#ifdef APACHE
    if (r -> pApacheReq)
	{
	SV *   pHeader ;
	char * p ;
	HE *   pEntry ;
	char * pKey ;
	I32    l ;
        STRLEN ldummy ;

 	I32	i;
 	I32	len;
 	AV	*arr;
 	SV	**svp;

	/* loc = 0  =>  no location header found
	 * loc = 1  =>  location header found
	 * loc = 2  =>  location header + value found
         * loc = 3  =>  location header + value + status found
	 */
 	I32	loc;
        I32 loc_status = 301;


	hv_iterinit (r -> pThread -> pHeaderHash) ;
	while ((pEntry = hv_iternext (r -> pThread -> pHeaderHash)))
	    {
	    pKey     = hv_iterkey (pEntry, &l) ;
	    pHeader  = hv_iterval (r -> pThread -> pHeaderHash, pEntry) ;
 	    loc = 0;
	    if (pHeader && pKey)
		{			    

		if (stricmp (pKey, "location") == 0)
		    loc = 1;
 		if (stricmp (pKey, "content-type") == 0)  
 		    {
 		    p = NULL;
 		    if ( SvROK(pHeader) && SvTYPE(SvRV(pHeader)) == SVt_PVAV ) 
 			{
 			arr = (AV *)SvRV(pHeader);
 			if (av_len(arr) >= 0) 
 			    {
 			    svp = av_fetch(arr, 0, 0);
			    p = SvPV(*svp, ldummy);
			    }
 			} 
 		    else 
 		 	{
 			p = SvPV(pHeader, ldummy);
 			}
 		    if (p) 
			r->pApacheReq->content_type = apr_pstrdup(r->pApacheReq->pool, p);
		    } 
  		else if (SvROK(pHeader)  && SvTYPE(SvRV(pHeader)) == SVt_PVAV ) 
 		    {
 		    arr = (AV *)SvRV(pHeader);
 		    len = av_len(arr);
 		    for (i = 0; i <= len; i++) 
 			{
 			svp = av_fetch(arr, i, 0);
                        if (loc == 2)
                             {
                             loc = 3;
                             loc_status = SvIV(*svp);
                             break;
                             }

 			p = SvPV(*svp, ldummy);
 			apr_table_add( r->pApacheReq->headers_out, apr_pstrdup(r->pApacheReq->pool, pKey),
 				   apr_pstrdup(r->pApacheReq->pool, p ) );
 			if (loc == 1) 
			    loc = 2;
			}
 		    } 
 		else 
 		    {
 		    p = SvPV(pHeader, ldummy);
		    apr_table_set(r -> pApacheReq->headers_out, apr_pstrdup(r -> pApacheReq->pool, pKey), apr_pstrdup(r -> pApacheReq->pool, p)) ;
		    if (loc == 1) loc = 2;
		    }

		if (loc >= 2) r->pApacheReq->status = loc_status;
		}
	    }


	if (pCookie)
	    apr_table_add(r -> pApacheReq->headers_out, "Set-Cookie", pCookie) ;
#if 0
	if (r -> Component.Config.bEP1Compat)  /*  Embperl 2 currently cannot calc Content Length */
	    set_content_length (r -> pApacheReq, GetContentLength (r) + (r -> Component.pCurrEscape?2:0)) ;
#endif
#ifndef APACHE2
	    send_http_header (r -> pApacheReq) ;
#endif

        if (r -> Component.Config.bDebug & dbgHeadersIn)
            {
            int i;
            const apr_array_header_t *hdrs_arr;
            apr_table_entry_t  *hdrs;

            hdrs_arr = apr_table_elts (r -> pApacheReq->headers_out);
	    hdrs = (apr_table_entry_t *)hdrs_arr->elts;

            lprintf (r -> pApp,   "[%d]HDR:  %d\n", r -> pThread -> nPid, hdrs_arr->nelts) ; 
	    for (i = 0; i < hdrs_arr->nelts; ++i)
		if (hdrs[i].key)
                    lprintf (r -> pApp,   "[%d]HDR:  %s=%s\n", r -> pThread -> nPid, hdrs[i].key, hdrs[i].val) ; 
            }
        }
    else
#endif
	{ 
	/*char txt[100] ;*/
	int  save = r -> Component.pOutput -> nMarker ;
	SV *   pHeader ;
	char * p ;
	HE *   pEntry ;
	char * pKey ;
	I32    l ;
	char * pContentType = "text/html";
        STRLEN ldummy ;
        /* loc = 0  =>  no location header found
        * loc = 1  =>  location header found
        */
        I32 loc;


	r -> Component.pOutput -> nMarker = 0 ; /* output directly */

	hv_iterinit (r -> pThread -> pHeaderHash) ;
	while ((pEntry = hv_iternext (r -> pThread -> pHeaderHash)))
	    {
	    pKey     = hv_iterkey (pEntry, &l) ;
	    pHeader  = hv_iterval (r -> pThread -> pHeaderHash, pEntry) ;
            loc = 0;

	    if (pHeader && pKey)
		{			    
 		if (stricmp (pKey, "location") == 0)
                    loc = 1;

                if (SvROK(pHeader)  && SvTYPE(SvRV(pHeader)) == SVt_PVAV ) 
 		    {
 		    AV * arr = (AV *)SvRV(pHeader);
 		    I32 len = av_len(arr);
		    int i ;

 		    for (i = 0; i <= len; i++) 
 			{
 			SV ** svp = av_fetch(arr, i, 0);
 			p = SvPV(*svp, ldummy);
			oputs (r, pKey) ;
			oputs (r, ": ") ;
			oputs (r, p) ;
			oputs (r, "\n") ;
			if (r -> Component.Config.bDebug & dbgHeadersIn)
                	    lprintf (r -> pApp,   "[%d]HDR:  %s: %s\n", r -> pThread -> nPid, pKey, p) ; 
			if (loc == 1) 
                            break;
                        }
 		    } 
		else
		    {				    
		    p = SvPV (pHeader, na) ;
		    if (stricmp (pKey, "content-type") == 0)
			pContentType = p ;
		    else
			{
			oputs (r, pKey) ;
			oputs (r, ": ") ;
			oputs (r, p) ;
			oputs (r, "\n") ;
			}
		    if (r -> Component.Config.bDebug & dbgHeadersIn)
                	lprintf (r -> pApp,   "[%d]HDR:  %s: %s\n", r -> pThread -> nPid, pKey, p) ; 
		    }
		}
	    }
	
	oputs (r, "Content-Type: ") ;
	oputs (r, pContentType) ;
	oputs (r, "\n") ;
	if (pCookie)
	    {
	    oputs (r, "Set-Cookie") ;
	    oputs (r, ": ") ;
	    oputs (r, pCookie) ;
	    oputs (r, "\n") ;
	    }

	oputs (r, "\n") ;

	r -> Component.pOutput -> nMarker = save ;
	}

    return ok ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* End the output stream to memory                                              */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static int OutputToMem (/*i/o*/ register req * r)

    {
    epTHX_
    SV * pOut ;
    char * pData ;
    STRLEN    l ;
            	
    if (!SvROK (r -> Component.Param.pOutput))
        {
        strcpy (r -> errdat1, "OutputToMem") ;
        strcpy (r -> errdat2, "parameter output") ;
        
        return rcNotScalarRef ;
        }
    
    pOut = SvRV (r -> Component.Param.pOutput) ;
    if (!r -> bError && r -> Component.pOutputSV && !r -> Component.pImportStash)
	{
	sv_setsv (pOut, r -> Component.pOutputSV) ;
	}
    else
	{
	if (!r -> bError && !r -> Component.pImportStash)
	    {
	    tDomTree * pDomTree = DomTree_self (r -> Component.xCurrDomTree) ;
	    Node_toString (r, pDomTree, pDomTree -> xDocument, 0) ;
	    }

	l = GetContentLength (r) + 1 ;
    
	sv_setpv (pOut, "") ;
	SvGROW (pOut, l) ;
	pData = SvPVX (pOut) ;
	oCommitToMem (r, NULL, pData) ;
	SvCUR_set (pOut, l - 1) ;
	}
    
    return ok ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* End the output stream to file                                                */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static int OutputToFile (/*i/o*/ register req * r)

    {
    epTHX_
    oCommit (r, NULL) ;
    if (!r -> bError && !r -> Component.pImportStash) 
	{
	if (r -> Component.pOutputSV)
	    {
	    STRLEN l ;
	    char * p = SvPV (r -> Component.pOutputSV, l) ;
	    owrite (r, p, l) ;
	    }
	else
	    {
	    tDomTree * pDomTree = DomTree_self (r -> Component.xCurrDomTree) ;
	    Node_toString (r, pDomTree, pDomTree -> xDocument, 0) ;
	    }
	}
    return ok ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Append tree to upper tree                                                    */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static int AppendToUpperTree (/*i/o*/ register req * r)

    {
    epTHX_
    tDomTree * pDomTree = DomTree_self (r -> Component.xCurrDomTree) ;
    tComponent * lc = r -> Component.pPrev ;
    if (lc -> xCurrNode)
	{
	if (r -> Component.pOutputSV)
	    {
	    STRLEN len ;
	    char * p = SvPV (r -> Component.pOutputSV, len) ;
	    lc -> xCurrNode = Node_insertAfter_CDATA (r -> pApp, p, len, 0, DomTree_self (lc -> xCurrDomTree), lc -> xCurrNode, lc -> nCurrRepeatLevel) ;
	    }
	else if (pDomTree -> xDocument)
	    {
	    lc -> xCurrNode = Node_insertAfter (r -> pApp, pDomTree, pDomTree -> xDocument, 0, DomTree_self (lc -> xCurrDomTree), lc -> xCurrNode, lc -> nCurrRepeatLevel) ;
	    }
	}
    return ok ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* End the output stream                                                        */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static int EndOutput (/*i/o*/ register req * r,
		      /*in*/ int    rc,
                      /*in*/ SV *   pOutData) 
                      

    {
    epTHX_

    
    r -> Component.bEscModeSet = 0 ;

    if (rc != ok ||  r -> bError)
        { /* --- generate error page if necessary --- */
        GenerateErrorPage (r, rc) ;
        if (r -> bExit)
            return ok ;
        }

    if (!(r -> Config.bOptions & optEarlyHttpHeader) && 
        (r -> Config.bOptions & optSendHttpHeader) && !r -> Component.Param.pOutput)
        embperl_SendHttpHeader (r) ;

    if (r -> Component.Param.pOutput)
        return OutputToMem (r) ;
    
    rc = OutputToFile (r) ;
#ifdef APACHE
    if (r -> pApacheReq)
        ap_finalize_request_protocol (r -> pApacheReq) ;
#endif
    oflush (r) ;
    
    return rc ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* export symbols into caller package                                           */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

    
static int export (/*in*/ tReq * r)
    
    {
    epTHX_
    SV * sCaller = sv_2mortal(newSVpv (HvNAME (r -> Component.pImportStash), 0)) ;
    dSP ;
    
    PUSHMARK(sp);
    XPUSHs(r -> _perlsv); 
    XPUSHs(sCaller) ; 
    PUTBACK;                        
    perl_call_method ("export", G_SCALAR | G_EVAL) ;
    SPAGAIN ;
    if (SvTRUE (ERRSV))
	{
        STRLEN l ;
        strncpy (r -> errdat1, SvPV (ERRSV, l), sizeof (r -> errdat1) - 1) ;
	LogError (r, rcEvalErr) ; 
        POPs ;
        sv_setpv(ERRSV,"");
        }
    tainted = 0 ;

    return ok ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Process the file                                                             */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

    

static int ProcessFile (/*i/o*/ register req * r,
			/*in*/ int     nFileSize)

    {
    epTHX_    
    int rc ;
    SV * pParam ;
    SV * pParamRV = NULL ;
    SV * pRecipe = r -> Component.Config.pRecipe ;
    STRLEN l ;
    int num ;

    dSP ;
    tainted = 0 ;

    if (!pRecipe || !SvOK(pRecipe))
        pRecipe = sv_2mortal(newSVpv("Embperl", 7)) ;

    if (SvPOK(pRecipe))            
        {
        PUSHMARK(sp);
	XPUSHs(r -> pApp -> _perlsv); 
	XPUSHs(r -> _perlsv); 
	XPUSHs(pRecipe);                
	PUTBACK;                        
	num = perl_call_method ("get_recipe", G_SCALAR | G_EVAL) ;
	tainted = 0 ;
	SPAGAIN;                        
	if (num == 1)
	    pParamRV = POPs ;
	PUTBACK;
        if (SvTRUE (ERRSV))
	    {
            STRLEN l ;
            strncpy (r -> errdat1, SvPV (ERRSV, l), sizeof (r -> errdat1) - 1) ;
	    LogError (r, rcEvalErr) ; 
	    sv_setpv(ERRSV,"");
            num = 0 ;
            }
	if (num != 1 || !SvROK (pParamRV) || !(pParam = SvRV(pParamRV)) || 
            (SvTYPE((SV *)pParam) != SVt_PVHV && SvTYPE(pParam) != SVt_PVAV))
	    {
	    strncpy (r -> errdat1, SvPV(pRecipe, l), sizeof (r -> errdat1) - 1) ;
	    return rcUnknownRecipe ;
	    }
	}
    else if (SvROK(pRecipe))
        pParam = SvRV(pRecipe) ;
    else
        pParam = pRecipe ;

    if ((rc = Cache_New (r, pParam, -1, 1, &r -> Component.pOutputCache)) != ok)
        return rc ;


    if (strncmp (r -> Component.pOutputCache -> pProvider -> sOutputType, "text/", 5) == 0)
	{
	if ((rc = Cache_GetContentSV (r, r -> Component.pOutputCache, &r -> Component.pOutputSV, FALSE)) != ok)
	    return rc ;
	}
    else if (strcmp (r -> Component.pOutputCache -> pProvider -> sOutputType, "X-Embperl/DomTree") == 0)
	{
	if ((rc = Cache_GetContentIndex (r, r -> Component.pOutputCache, &r -> Component.xCurrDomTree, FALSE)) != ok)
	    return rc ;
	}
    else
	{
	sprintf (r -> errdat1, "'%s' (accpetable are 'text/*', 'X-Embperl/DomTree')", r -> Component.pOutputCache -> pProvider -> sOutputType) ;
	strncpy (r -> errdat2, r -> Component.pOutputCache -> sKey, sizeof (r -> errdat2) - 1) ;
	return rcTypeMismatch ;
	}

    return ok ;
    }


    
/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Request handler                                                              */
/*                                                                              */
/* ---------------------------------------------------------------------------- */



int embperl_RunRequest (/*i/o*/ register req * r)

    {
    int     rc = ok ;
    tComponent * c = &r -> Component ;
    char *  sInputfile = c -> sSourcefile ;
    

    dTHR ;
    epTHX ;    

    EPENTRY (ExecuteReq) ;

    if (!r -> Component.pExportHash)
	r -> Component.pExportHash = newHV () ;
    
    ENTER;
    SAVETMPS ;
	
    /* SetupSafeNamespace (r) ; */


    if (c -> Param.pErrArray)
        {
        SvREFCNT_inc(c -> Param.pErrArray) ;
        SvREFCNT_dec(r -> pErrArray) ;
        r -> pErrArray = c -> Param.pErrArray ;
        }
    
    /* --- open output and send http header if EarlyHttpHeaders --- */
    if (rc == ok)
        rc = StartOutput (r) ;

    
    /* --- ok so far? if not exit ---- */
#ifdef APACHE
    if (rc != ok || (r -> pApacheReq && r -> pApacheReq -> header_only && (r -> Config.bOptions & optEarlyHttpHeader)))
#else
    if (rc != ok)
#endif
        {
        if (rc != ok)
            LogError (r, rc);
#ifdef APACHE
        r -> pApacheReq = NULL ;
#endif
        r -> Component.bReqRunning = 0 ;
        FREETMPS ;
        LEAVE;
        return rc ;
        }

    r -> Component.bReqRunning     = 1 ;

    if (!r -> bError)
        {
        if ((rc = ProcessFile (r, 0 /*r -> Buf.pFile -> nFilesize*/)) != ok)
            {
            if (rc == rcExit)
                rc = ok ;
            else
                LogError (r, rc) ;
            }

        if (r -> Component.Param.nImport > 0)
            export (r) ;
        }

    /* --- Restore Operatormask and Package, destroy temp perl sv's --- */
    FREETMPS ;
    LEAVE;
    r -> Component.bReqRunning = 0 ;

    /* --- send http header and data to the browser if not already done --- */
    if ((rc = EndOutput (r, rc, r -> Component.Param.pOutput)) != ok)
        LogError (r, rc) ;

#ifdef EP2
    if (r -> Component.pOutputCache)
        Cache_ReleaseContent (r, r -> Component.pOutputCache) ;
#endif    
    
    /* --- reset variables and log end of request --- */
    if ((rc = ResetRequest (r, sInputfile)) != ok)
        LogError (r, rc) ;

#if defined (_MDEBUG) && defined (WIN32)
    _ASSERTE( _CrtCheckMemory( ) );
#endif

    if ((c -> Config.bOptions & optReturnError) && r -> bError)
        {        
#ifdef APACHE
        if (r -> pApacheReq && r -> pApacheReqSV)
            {
            dSP ;
            PUSHMARK(sp);
	    XPUSHs(r -> pApacheReqSV); 
	    XPUSHs(sv_2mortal(newSVpv("EMBPERL_ERRORS", 14))); 
	    XPUSHs(sv_2mortal(newRV((SV*)r -> pErrArray))); 
	    PUTBACK;                        
	    perl_call_method ("pnotes", G_DISCARD) ;
            }
#endif
#ifdef APACHE
        /* This must be the very very very last !!!!! */
        r -> pApacheReq = NULL ;
#endif
        return 500 ;
        }
#ifdef APACHE
    /* This must be the very very very last !!!!! */
    r -> pApacheReq = NULL ;
#endif

    return ok ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Run Request                                                                  */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


int     embperl_ExecuteRequest  (/*in*/ pTHX_
                                 /*in*/ SV *             pApacheReqSV,
                                 /*in*/ SV *             pPerlParam)


    {
    int rc ;
    tReq * r = NULL ;

#ifdef DMALLOC
    time_t t = time(NULL) ;
    static unsigned long nMemCheckpoint ;
    static unsigned long nMemCheckpoint2 ;
    dmalloc_message ("[%d]REQ: Start Request at %s\n", getpid(), ctime (&t)) ; 
#endif        

#if defined (_MDEBUG) && defined (WIN32)
    _CrtMemCheckpoint(&r -> MemCheckpoint);    
#endif    
#ifdef DMALLOC
    nMemCheckpoint2 = nMemCheckpoint  ;   
    nMemCheckpoint = dmalloc_mark () ;   
#endif    

    ENTER;
    SAVETMPS ;
	
    rc = embperl_InitRequestComponent (aTHX_ pApacheReqSV, pPerlParam, &r) ;

#ifdef DMALLOC
    r -> MemCheckpoint = nMemCheckpoint;   
#endif    

    if (rc == ok)
        rc = embperl_RunRequest (r) ;

#ifdef DMALLOC
    dmalloc_message ( "[%d]%sRequest will be freed. Entry-SVs: %d: %%d\n", r -> pThread -> nPid,
	    (r -> Component.pPrev?"Sub-":""), r -> stsv_count) ;
#endif

    if (r)
        embperl_CleanupRequest (r) ;

    FREETMPS ;
    LEAVE;

#if defined (_MDEBUG) && defined (WIN32)
    _CrtMemDumpAllObjectsSince(&r -> MemCheckpoint);    
#endif    
#ifdef DMALLOC
			    /* unsigned long mark, int not_freed_b, int freed_b, int details_b */
    dmalloc_log_changed (nMemCheckpoint, 1, 0, 1) ;
    dmalloc_message ( "[%d]Request freed. Exit-SVs: %d -OBJs: %d\n", getpid(),
	    sv_count, sv_objcount) ;
    if (nMemCheckpoint2)
        {
        dmalloc_message ( "***TO PREVIOUS REQUEST***\n") ;
        dmalloc_log_changed (nMemCheckpoint2, 1, 0, 1) ;
        }
#endif    

    return rc ;
    }
    

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Run Component                                                                */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

int     embperl_RunComponent    (/*in*/ tComponent *     c)


    {
    tReq * r = c -> pReq ;
    epTHX_
    int rc ;

    ENTER;
    SAVETMPS ;
    
    c -> bReqRunning     = 1 ;

    if ((c -> Config.bOptions & optReturnError) )
        save_int(&r -> bError) ;

    if (c -> Param.pErrArray)
        {
        save_int(&r -> bError) ;
        save_aptr(&r -> pErrArray) ;
        r -> pErrArray = c -> Param.pErrArray ;
        }

    if ((c -> Config.bOptions & optEarlyHttpHeader) == 0)
        oBegin (r) ;

    if ((rc = ProcessFile (r, 0 /*r -> Buf.pFile -> nFilesize*/)) != ok)
        {
        if (rc == rcExit)
            rc = ok ;
        else
            LogError (r, rc) ;
        }

    if (rc == ok && (c -> Config.bOptions & optReturnError) && r -> bError)
        rc = 500 ;
    

    if (!r -> bError)
        {
        if (c -> Param.nImport > 0)
            export (r) ;
        else if (c -> pOutput && !c -> pOutput -> bDisableOutput) 
            {
            if (c -> Param.pOutput)
                OutputToMem (r) ;
            else if (r -> Component.pPrev && c -> pOutput == r -> Component.pPrev -> pOutput)
                AppendToUpperTree (r) ;
            else
                OutputToFile (r) ;
            }
        }

    /* --- Restore Operatormask and Package, destroy temp perl sv's --- */
    FREETMPS ;
    LEAVE;
    c -> bReqRunning = 0 ;

    return rc ;
    }
    
/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Execute Component                                                            */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


int     embperl_ExecuteComponent(/*in*/ tReq *           r,
                                 /*in*/ SV *             pPerlParam)


    {
    epTHX_
    int rc ;
    tComponent * pComponent ;

    rc = embperl_SetupComponent  (r, pPerlParam, &pComponent) ;
    if (rc == ok)
        {
        rc = embperl_RunComponent (pComponent) ;
        
        embperl_CleanupComponent  (pComponent) ;
        }

    return rc ;
    }
    
