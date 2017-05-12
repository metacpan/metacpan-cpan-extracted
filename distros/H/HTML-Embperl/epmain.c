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
#   $Id: epmain.c,v 1.118.2.1 2003/01/22 08:23:35 richter Exp $
#
###################################################################################*/


#include "ep.h"
#include "epmacro.h"


/* Version */

static char sVersion [] = VERSION ;


static int  bInitDone = 0 ; /* c part is already initialized */

static char sEnvHashName   [] = "ENV" ;
static char sFormHashName  [] = "HTML::Embperl::fdat" ;
static char sUserHashName  [] = "HTML::Embperl::udat" ;
static char sStateHashName [] = "HTML::Embperl::sdat" ;
static char sModHashName  []  = "HTML::Embperl::mdat" ;
static char sFormSplitHashName [] = "HTML::Embperl::fsplitdat" ;
static char sFormArrayName [] = "HTML::Embperl::ffld" ;
static char sInputHashName [] = "HTML::Embperl::idat" ;
static char sHeaderHashName  [] = "HTML::Embperl::http_headers_out" ;
static char sTabCountName  [] = "HTML::Embperl::cnt" ;
static char sTabRowName    [] = "HTML::Embperl::row" ;
static char sTabColName    [] = "HTML::Embperl::col" ;
static char sTabMaxRowName [] = "HTML::Embperl::maxrow" ;
static char sTabMaxColName [] = "HTML::Embperl::maxcol" ;
static char sTabModeName   [] = "HTML::Embperl::tabmode" ;
static char sEscModeName   [] = "HTML::Embperl::escmode" ;
#ifdef EP2
static char sCurrNodeName   [] = "HTML::Embperl::_ep_node" ;
static char sTokenHashName [] = "HTML::Embperl::Syntax::Default" ;
#endif

static char sDefaultPackageName [] = "HTML::Embperl::DOC::_%d" ;

static char sUIDName [] = "_ID" ;
static char sSetCookie [] = "Set-Cookie" ;
static char sCookieNameDefault [] = "EMBPERL_UID" ;


static int      nPackNo = 1 ;       /* Number for createing unique package names */
static tReq *   pReqFree = NULL ;   /* Chain of unused req structures */
tReq     InitialReq ;               /* Initial request - holds default values */
tReq * pCurrReq ;                   /* Set before every eval (NOT thread safe!!) */ 

static HV * pCacheHash ;            /* Hash which holds all cached data
				       (key=> filename or 
					      filename + packagename, 
				       value=>cache hash for file) */

#if PERL_VERSION >= 8
SV   ep_sv_undef ; /* we need our own undef value, because when
                      storing a PL_sv_undef with Perl 5.8.0 in a hash
                      Perl takes it as a placeholder and pretents it
                      isn't there :-( */
#endif


/* */
/* print error */
/* */

char * LogError (/*i/o*/ register req * r,
			/*in*/ int   rc)

    {
    const char * msg ;
    char * sText ;
    SV *   pSV ;
    SV *   pSVLine = NULL ;
    SV **  ppSV ;
    STRLEN l ;
    int    n ;

    
    EPENTRY (LogError) ;
    
    r -> errdat1 [sizeof (r -> errdat1) - 1] = '\0' ;
    r -> errdat2 [sizeof (r -> errdat2) - 1] = '\0' ;

    GetLineNo (r) ;
    
    if (rc != rcPerlWarn)
        r -> bError = 1 ;
    
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
        case rcOutOfMemory:             msg ="[%d]ERR:  %d: %s Out of memory%s%s" ; break ;
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
        case rcNotFound:                msg ="[%d]ERR:  %d: %s Not found %s%s" ; break ;
        case rcUnknownVarType:          msg ="[%d]ERR:  %d: %s Type for Variable %s is unknown %s" ; break ;
        case rcPerlWarn:                msg ="[%d]ERR:  %d: %s Warning in Perl code: %s%s" ; break ;
        case rcVirtLogNotSet:           msg ="[%d]ERR:  %d: %s EMBPERL_VIRTLOG must be set, when dbgLogLink is set %s%s" ; break ;
        case rcMissingInput:            msg ="[%d]ERR:  %d: %s Sourcedata missing %s%s" ; break ;
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
        case rcNotHashRef:              msg ="[%d]ERR:  %d: %s %s need hashref in %s" ; break ; 
	case rcTagMismatch:		msg ="[%d]ERR:  %d: %s Endtag '%s' doesn't match starttag '%s'" ; break ; 
	case rcCleanupErr:		msg ="[%d]ERR:  %d: %s Error in cleanup %s%s" ; break ; 
	case rcCryptoWrongHeader:	msg ="[%d]ERR:  %d: %s Decrypt-error: Not encrypted (%s)%s" ; break ; 
	case rcCryptoWrongSyntax:	msg ="[%d]ERR:  %d: %s Decrypt-error: Wrong syntax (%s)%s" ; break ; 
	case rcCryptoNotSupported:	msg ="[%d]ERR:  %d: %s Decrypt-error: Not supported (%s)%s" ; break ; 
	case rcCryptoBufferOverflow:	msg ="[%d]ERR:  %d: %s Decrypt-error: Buffer overflow (%s)%s" ; break ; 
	case rcCryptoErr:		msg ="[%d]ERR:  %d: %s Decrypt-error: OpenSSL error (%s)%s" ; break ; 
	
	default:                        msg ="[%d]ERR:  %d: %s Error %s%s" ; break ; 
        }

    if ((rc != rcPerlWarn && rc != rcEvalErr) || r -> errdat1[0] == '\0')
        {
        char * p = NULL ;
        char buf[20] = "" ;
        if (!r -> Buf.pFile || !r -> Buf.pFile -> sSourcefile)
            p = "" ;
        if (!p)
            p = strrchr (r -> Buf.pFile -> sSourcefile, '/') ;
        if (p)
            p++ ;
        else
            {
            p = strrchr (r -> Buf.pFile -> sSourcefile, '\\') ;
            if (!p)
                p = r -> Buf.pFile -> sSourcefile ;
            else
                p++ ;
            }
        if (r -> Buf.nSourceline)
            sprintf (buf, "(%d)", r -> Buf.nSourceline) ;
        pSVLine = newSVpvf ("%s%s:", p, buf) ;
        }

   
    
    pSV = newSVpvf (msg, r -> nPid , rc, pSVLine?SvPV(pSVLine, l):"", r -> errdat1, r -> errdat2) ;

    if (r -> bOptions & optShowBacktrace)
        {
        req * l = r ;
        while (l && l != &InitialReq)
            {
            sv_catpvf(pSV, "\n    * %s", (!l -> Buf.pFile || !l -> Buf.pFile -> sSourcefile)?"<no filename available>":l -> Buf.pFile -> sSourcefile) ;
            l = l -> pLastReq ;
            }
        }


    if (pSVLine)
        SvREFCNT_dec(pSVLine) ;

    sText = SvPV (pSV, l) ;    
    
    lprintf (r, "%s\n", sText) ;

#ifdef APACHE
    if (r -> pApacheReq)
#ifdef APLOG_ERR
        if (rc != rcPerlWarn)
            aplog_error (APLOG_MARK, APLOG_ERR | APLOG_NOERRNO, r -> pApacheReq -> server, "%s", sText) ;
        else
            aplog_error (APLOG_MARK, APLOG_WARNING | APLOG_NOERRNO, r -> pApacheReq -> server, "%s", sText) ;
#else
        log_error (sText, r -> pApacheReq -> server) ;
#endif
    else
#endif
        {
#ifdef WIN32
        if (r -> nIOType != epIOCGI)
#endif
            {
            /*fprintf (stderr, "%s\n", sText) ;*/
            PerlIO_printf (PerlIO_stderr(), "%s\n", sText) ;
            fflush (stderr) ;
            }
        }
    
    if (rc == rcPerlWarn)
        strncpy (r -> lastwarn, r -> errdat1, sizeof (r -> lastwarn) - 1) ;

    if (r -> pErrArray)
        {
        /*lprintf (r, "DIS: in LogError AvFILL (pErrArray) = %d, nMarker = %d,  nLastErrFill= %d , bLastErrState = %d, bError = %d\n" , AvFILL (r -> pErrArray), r -> nMarker, r -> nLastErrFill, r -> bLastErrState, r -> bError) ;*/
        av_push (r -> pErrArray, pSV) ;
    
        av_store (r -> pErrFill, r -> nMarker, newSViv (AvFILL(r -> pErrArray))) ;
        av_store (r -> pErrState, r -> nMarker, newSViv (r -> bError)) ;
        n = r -> nMarker ;
        while (n-- > 0)
            {
            ppSV = av_fetch (r -> pErrFill, n, 0) ;
            if (ppSV && SvOK (*ppSV))
                break ;
            av_store (r -> pErrFill, n, newSViv (r -> nLastErrFill)) ;
            av_store (r -> pErrState, n, newSViv (r -> bLastErrState)) ;
            /*lprintf (r, "DIS: in LogError n=%d\n", n) ;*/
            }
        
        r -> nLastErrFill  = AvFILL(r -> pErrArray) ;
        r -> bLastErrState = r -> bError ;
        }

    r -> errdat1[0] = '\0' ;
    r -> errdat2[0] = '\0' ;

    return sText ;
    }


/* */
/* begin for error rollback */
/* */

void CommitError (/*i/o*/ register req * r)
    
    {
    int f = AvFILL(r -> pErrArray)  ;
    int n ;
    SV ** ppSV ;

    if (f == -1)
        return ; /* no errors -> nothing to do */

    /* lprintf (r, "DIS: Commit AvFILL (pErrArray) = %d, nMarker = %d,  nLastErrFill= %d , bLastErrState = %d\n" , AvFILL (r -> pErrArray), r -> nMarker, r -> nLastErrFill, r -> bLastErrState) ; */

    av_store (r -> pErrFill, r -> nMarker, newSViv (f)) ;
    av_store (r -> pErrState, r -> nMarker, newSViv (r -> bError)) ;
    n = r -> nMarker ;
    while (n-- > 0)
        {
        ppSV = av_fetch (r -> pErrFill, n, 0) ;
        if (ppSV && SvOK (*ppSV))
            break ;
        av_store (r -> pErrFill, n, newSViv (r -> nLastErrFill)) ;
        av_store (r -> pErrState, n, newSViv (r -> bLastErrState)) ;
        /* lprintf (r, "DIS: in LogError n=%d\n", n) ;*/
        }
    }

    
    
/* */
/* rollback error */
/* */

void RollbackError (/*i/o*/ register req * r)

    {
    SV *  pFill ;
    SV *  pState ;
    SV ** ppSV ;
    I32   f = AvFILL (r -> pErrFill) ;
    int   n ;
    int   i ;

    if (f < r -> nMarker)
        return ;
    
    /*lprintf (r, "DIS: AvFILL (pErrFill) = %d, nMarker = %d\n" , f, r -> nMarker) ;*/
    
    for (i = f; i > r -> nMarker; i--)
        {
        pFill  = av_pop(r -> pErrFill) ;
        pState = av_pop(r -> pErrState) ;
        SvREFCNT_dec (pFill) ;
        SvREFCNT_dec (pState) ;
        }
    ppSV   = av_fetch(r -> pErrFill, r -> nMarker, 0) ;
    if (ppSV)
        n = SvIV (*ppSV) ;
    else
        {
        n = 0 ;
        /*lprintf (r, "DIS: in Roolback set n=%d\n", n) ;*/
        }


    ppSV = av_fetch(r -> pErrState, r -> nMarker, 0) ;
    if (ppSV)
        r -> bError = SvIV (*ppSV) ;
    else
        r -> bError = 1 ;
    f = AvFILL (r -> pErrArray) ;
    /*lprintf (r, "DIS: AvFILL (pErrArray) = %d, n = %d\n" , f, n) ;*/
    if (f > n)
        lprintf (r, "[%d]ERR:  Discard the last %d errormessages, because they occured after the end of a table\n", r -> nPid, f - n) ;
    for (i = f; i > n; i--)
        {
        SvREFCNT_dec (av_pop(r -> pErrArray)) ;
        }

    r -> nLastErrFill  = AvFILL(r -> pErrArray) ;
    r -> bLastErrState = r -> bError ;

    /*lprintf (r, "DIS: in RollbackError AvFILL (pErrArray) = %d, nMarker = %d,  nLastErrFill= %d , bLastErrState = %d, bError = %d\n" , AvFILL (r -> pErrArray), r -> nMarker, r -> nLastErrFill, r -> bLastErrState, r -> bError) ;*/
    
    }


    
/* */
/* Magic */
/* */

void NewEscMode (/*i/o*/ register req * r,
			           SV * pSV)

    {
    if (r -> nEscMode & escHtml && !r -> bEscInUrl)
	r -> pNextEscape = Char2Html ;
    else if (r -> nEscMode & escUrl)
        r -> pNextEscape = Char2Url ;
    else 
        r -> pNextEscape = NULL ;

    if (r -> bEscModeSet < 1)
	{
        r -> pCurrEscape = r -> pNextEscape ;
        r -> nCurrEscMode = r -> nEscMode ;
	}

    if (r -> bEscModeSet < 0 && pSV && SvOK (pSV))
        r -> bEscModeSet = 1 ;
    }



static int notused ;

INTMG (TabCount, pCurrReq -> TableStack.State.nCount, pCurrReq -> TableStack.State.nCountUsed, ;) 
INTMG (TabRow, pCurrReq -> TableStack.State.nRow, pCurrReq -> TableStack.State.nRowUsed, ;) 
INTMG (TabCol, pCurrReq -> TableStack.State.nCol, pCurrReq -> TableStack.State.nColUsed, ;) 
INTMG (TabMaxRow, pCurrReq -> nTabMaxRow, notused,  ;) 
INTMG (TabMaxCol, pCurrReq -> nTabMaxCol, notused, ;) 
INTMG (TabMode, pCurrReq -> nTabMode, notused, ;) 
INTMG (EscMode, pCurrReq -> nEscMode, notused, NewEscMode (pCurrReq, pSV)) 
#ifdef EP2
INTMGshort (CurrNode, pCurrReq -> xCurrNode) 
#endif

OPTMGRD (optDisableVarCleanup      , pCurrReq -> bOptions) 
OPTMG   (optDisableEmbperlErrorPage, pCurrReq -> bOptions) 
OPTMG   (optReturnError            , pCurrReq -> bOptions) 
OPTMGRD (optSafeNamespace          , pCurrReq -> bOptions) 
OPTMGRD (optOpcodeMask             , pCurrReq -> bOptions) 
OPTMG   (optRawInput               , pCurrReq -> bOptions) 
OPTMG   (optSendHttpHeader         , pCurrReq -> bOptions) 
OPTMGRD (optDisableChdir           , pCurrReq -> bOptions) 
OPTMG   (optDisableHtmlScan        , pCurrReq -> bOptions) 
OPTMGRD (optEarlyHttpHeader        , pCurrReq -> bOptions) 
OPTMGRD (optDisableFormData        , pCurrReq -> bOptions) 
OPTMG   (optDisableInputScan       , pCurrReq -> bOptions) 
OPTMG   (optDisableTableScan       , pCurrReq -> bOptions) 
OPTMG   (optDisableMetaScan        , pCurrReq -> bOptions) 
OPTMGRD (optAllFormData            , pCurrReq -> bOptions) 
OPTMGRD (optRedirectStdout         , pCurrReq -> bOptions) 
OPTMG   (optUndefToEmptyValue      , pCurrReq -> bOptions) 
OPTMG   (optNoHiddenEmptyValue     , pCurrReq -> bOptions) 
OPTMGRD (optAllowZeroFilesize      , pCurrReq -> bOptions) 
OPTMGRD (optKeepSrcInMemory        , pCurrReq -> bOptions) 
OPTMG   (optKeepSpaces             , pCurrReq -> bOptions) 
OPTMG   (optOpenLogEarly           , pCurrReq -> bOptions) 
OPTMG   (optNoUncloseWarn          , pCurrReq -> bOptions) 


OPTMG   (dbgStd          , pCurrReq -> bDebug) 
OPTMG   (dbgMem          , pCurrReq -> bDebug) 
OPTMG   (dbgEval         , pCurrReq -> bDebug) 
OPTMG   (dbgCmd          , pCurrReq -> bDebug) 
OPTMG   (dbgEnv          , pCurrReq -> bDebug) 
OPTMG   (dbgForm         , pCurrReq -> bDebug) 
OPTMG   (dbgTab          , pCurrReq -> bDebug) 
OPTMG   (dbgInput        , pCurrReq -> bDebug) 
OPTMG   (dbgFlushOutput  , pCurrReq -> bDebug) 
OPTMG   (dbgFlushLog     , pCurrReq -> bDebug) 
OPTMG   (dbgAllCmds      , pCurrReq -> bDebug) 
OPTMG   (dbgSource       , pCurrReq -> bDebug) 
OPTMG   (dbgFunc         , pCurrReq -> bDebug) 
OPTMG   (dbgLogLink      , pCurrReq -> bDebug) 
OPTMG   (dbgDefEval      , pCurrReq -> bDebug) 
OPTMG   (dbgHeadersIn    , pCurrReq -> bDebug) 
OPTMG   (dbgShowCleanup  , pCurrReq -> bDebug) 
OPTMG   (dbgProfile      , pCurrReq -> bDebug) 
OPTMG   (dbgSession      , pCurrReq -> bDebug) 
OPTMG   (dbgImport       , pCurrReq -> bDebug) 

/* ---------------------------------------------------------------------------- */
/* read form input from http server... */
/* */

static int GetFormData (/*i/o*/ register req * r,
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

    EPENTRY (GetFormData) ;

    hv_clear (r -> pFormHash) ;
    hv_clear (r -> pFormSplitHash) ;
    
#ifdef HASHTEST
	pHash = perl_get_hv (sFormHashName, FALSE) ;
	if (pHash != r -> pFormHash)
	    {
	    strcpy (r -> errdat1, sFormHashName) ;
	    strcpy (r -> errdat2, " !!C-Adress differs from Perl-Adress!! in GetFormData" ) ;
	    LogError (r, rcHashError) ;
	    }
#endif

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
            case '=':
                nKey = p - pKey ;
                *p++ = r -> pConf -> cMultFieldSep ;
                nVal = 0 ;
                pVal = p ;
                pQueryString++ ;
                nLen-- ;
                break ;
            case ';':
            case '&':
                pQueryString++ ;
                nLen-- ;
            case '\0':
                nVal = p - pVal ;
                *p++ = '\0' ;
            
                if (nKey > 0 && (nVal > 0 || (r -> bOptions & optAllFormData)))
                    {
                    char * sid = r -> pConf -> sCookieName ;

		    if (sid)
			{ /* remove session id  */
			if (strncmp (pKey, sid, nKey) != 0)
			    sid = NULL ;
			}

		    if (sid == NULL)
			{ /* field is not the session id */
			if (pVal > pKey)
			    pVal[-1] = '\0' ;
                    
			if ((ppSV = hv_fetch (r -> pFormHash, pKey, nKey, 0)))
			    { /* Field exists already -> append separator and field value */
			    sv_catpvn (*ppSV, &r ->  pConf -> cMultFieldSep, 1) ;
			    sv_catpvn (*ppSV, pVal, nVal) ;
			    }
			else
			    { /* New Field -> store it */
			    pSVV = newSVpv (pVal, nVal) ;
			    if (hv_store (r -> pFormHash, pKey, nKey, pSVV, 0) == NULL)
				{
				_free (r, pMem) ;
				return rcHashError ;
				}

			    pSVK = newSVpv (pKey, nKey) ;

			    av_push (r -> pFormArray, pSVK) ;
			    }

                
			if (r -> bDebug & dbgForm)
			    lprintf (r, "[%d]FORM: %s=%s\n", r -> nPid, pKey, pVal) ; 
			}
                    }
                pKey = pVal = p ;
                nKey = nVal = 0 ;
                
                if (*pQueryString == '\0')
                    {
                    _free (r, pMem) ;
                    return ok ;
                    }
                
                
                break ;
            default:
                *p++ = *pQueryString++ ;
                nLen-- ;
                break ;
            }
        }

    }

#ifdef comment

/* ---------------------------------------------------------------------------- */
/* read input from cgi process... */
/* */


static int GetInputData_CGIProcess (/*i/o*/ register req * r)

    {
    char *  p ;
    int     rc = ok ;
    int  state = 0 ;
    int  len   = 0 ;
    char sLine [1024] ;
    SV * pSVE ;
    int  savewarn = dowarn ;
    dowarn = 0 ; /* no warnings here */
    
    EPENTRY (GetInputData_CGIProcess) ;

    hv_clear (r -> pEnvHash) ;


    if (r -> bDebug)
        lprintf (r, "\n[%d]Waiting for Request... SVs: %d OBJs: %d\n", r -> nPid, sv_count, sv_objcount) ;

    if ((rc = OpenInput (r, sCmdFifo)) != ok)
        {
        dowarn = savewarn ;
        return rc ;
        }


    if (r -> bDebug)
        lprintf (r, "[%d]Processing Request...\n", r -> nPid) ;
    
    while (igets (sLine, sizeof (sLine)))
        {
        len = strlen (sLine) ; 
        while (len >= 0 && isspace (sLine [--len]))
            ;
        sLine [len + 1] = '\0' ;
        

        if (strcmp (sLine, "----") == 0)
            { state = 1 ; if (r -> bDebug) lprintf (r, "[%d]Environment...\n", r -> nPid) ;}
        else if (strcmp (sLine, "****") == 0)
            { state = 2 ;  if (r -> bDebug) lprintf (r,  "[%d]Formdata...\n", r -> nPid) ;}
        else if (state == 1)
            {
            p = strchr (sLine, '=') ;
            *p = '\0' ;
            p++ ;

            pSVE = newSVpv (p, strlen (p)) ;

            if (hv_store (r -> pEnvHash, sLine, strlen (sLine), pSVE, 0) == NULL)
                {
                dowarn = savewarn ;
                return rcHashError ;
                }
            if (r -> bDebug & dbgEnv)
                lprintf (r,  "[%d]ENV:  %s=%s\n", r -> nPid, sLine, p) ;
            }
        else if (state == 2)
            {
            len = atoi (sLine) ;
            if ((p = _malloc (len + 1)) == NULL)
                {
                dowarn = savewarn ;
                return rcOutOfMemory ;
                }
            iread (p, len) ;
            p[len] = '\0' ;
            rc = GetFormData (p, len) ;
            _free (p) ;
            break ;
            }
        else
            { if (r -> bDebug) lprintf (r, "[%d]Unknown Input: %s\n", r -> nPid, sLine) ;}

        }
        
    CloseInput () ;
    
    dowarn = savewarn ;
    return rc ;
    }
                        
#endif

/* ---------------------------------------------------------------------------- */
/* get form data when running as cgi script... */
/* */


static int GetInputData_CGIScript (/*i/o*/ register req * r)

    {
    char *  p = NULL ;
    char *  f ;
    int     rc = ok ;
    STRLEN  len   = 0 ;
    char    sLen [20] ;
    

    EPENTRY (GetInputData_CGIScript) ;

#ifdef APACHE
    if (r -> pApacheReq && (r -> bDebug & dbgHeadersIn))
        {
        int i;
        array_header *hdrs_arr;
        table_entry  *hdrs;

        hdrs_arr = table_elts (r -> pApacheReq->headers_in);
        hdrs = (table_entry *)hdrs_arr->elts;

        lprintf (r,  "[%d]HDR:  %d\n", r -> nPid, hdrs_arr->nelts) ; 
        for (i = 0; i < hdrs_arr->nelts; ++i)
	    if (hdrs[i].key)
                lprintf (r,  "[%d]HDR:  %s=%s\n", r -> nPid, hdrs[i].key, hdrs[i].val) ; 
        }
#endif

    if (r -> bDebug & dbgEnv)
        {
        SV *   psv ;
        HE *   pEntry ;
        char * pKey ;
        I32    l ;
        int  savewarn = dowarn ;
        dowarn = 0 ; /* no warnings here */
        
        hv_iterinit (r -> pEnvHash) ;
        while ((pEntry = hv_iternext (r -> pEnvHash)))
            {
            pKey = hv_iterkey (pEntry, &l) ;
            psv  = hv_iterval (r -> pEnvHash, pEntry) ;

                lprintf (r,  "[%d]ENV:  %s=%s\n", r -> nPid, pKey, SvPV (psv, na)) ; 
            }
        dowarn = savewarn ;
        }

#ifdef APACHE
    if (r -> pApacheReq)
        {
        const char * sLength = table_get(r -> pApacheReq->headers_in, "Content-Length") ;
	len = sLength?atoi (sLength):0 ;
	}
    else
#endif
	{
	sLen [0] = '\0' ;
	GetHashValue (r -> pEnvHash, "CONTENT_LENGTH", sizeof (sLen) - 1, sLen) ;
	len = atoi (sLen) ;
	}

    if (len == 0)
        {
        SV * * ppSV = hv_fetch(r -> pEnvHash, "QUERY_STRING", sizeof ("QUERY_STRING") - 1, 0) ;  
        if (ppSV != NULL)
            {
            p = SvPV (*ppSV ,len) ;
            }
        else
            len = 0 ;
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
        
    if (r -> bDebug)
        lprintf (r,  "[%d]Formdata... length = %d\n", r -> nPid, len) ;    

    rc = GetFormData (r, p, len) ;
    
#ifdef EP2
    if (!f && len > 0)
	{
        if ((f = _malloc (r, len + 1)) == NULL)
            return rcOutOfMemory ;

	memcpy (f, p, len) ;
        p[len] = '\0' ;
	}
    if (len > 0)
	{
	r -> sQueryInfo = f ;
	f[len] = '\0' ;
	}
#else
    if (f)
        _free (r, f) ;
#endif        
    
    return rc ;
    }


/* ---------------------------------------------------------------------------- */
/* scan commands and evals ([x ... x] sequenz) ... */
/* */
/* p points to '[' */
/* */


    
static int ScanCmdEvals (/*i/o*/ register req * r,
			/*in*/ char *   p)
    
    
    { 
    int     rc ;
    char *  c ;
    char *  a ;
    char    nType ;
    SV *    pRet ;
    struct tCmd * pCmd ;
    char *  pAfterWS ;
    int     nFilepos = p - r -> Buf.pBuf ;
    SV **   ppSV ;
    AV *    pAV ;
    HV *    pHV ;
    STRLEN  l ;
    I32     li ;

    EPENTRY (ScanCmdEvals) ;
    
    p++ ;

    r -> Buf.pCurrPos = p ;

    if ((nType = *p++) == '\0')
        return ok ;

    r -> Buf.pCurrPos = p ;

    if (nType != '+' && nType != '-' && nType != '$' && nType != '!' && nType != '#')
        { /* escape (for [[ -> [) */
        if (r -> CmdStack.State.bProcessCmds == cmdAll)
            {
            if (nType != '[') 
                oputc (r, '[') ;
            oputc (r, nType) ;
            }
        return ok ;
        }

    /* end known ? */

    ppSV = hv_fetch(r -> Buf.pFile -> pCacheHash, (char *)&nFilepos, sizeof (nFilepos), 1) ;  
    if (ppSV == NULL)
        return rcHashError ;

    if (*ppSV != NULL && SvTYPE (*ppSV) == SVt_IV)
        {
	p = p + SvIV(*ppSV) ;
        }
    else
	{
	do
	    { /* search end  */
	    p++ ;
    
	    if ((p = strchr (p, ']')) == NULL)
		break ;
	    }   
	while (p[-1] != nType) ;
	if (p == NULL)
	    { /* end not found */
	    sprintf (r -> errdat1, "%c]", nType) ; 
	    return rcMissingRight ;
	    }
        SvREFCNT_dec (*ppSV) ;  
        *ppSV = newSViv (p - r -> Buf.pCurrPos) ;
        /*SvREFCNT_inc (*ppSV) ;  */
	}
	
    p [-1] = '\0' ;
    p++ ;

    pAfterWS = p;

    if ((r -> bOptions & optKeepSpaces) == 0)
	{	    
	/* skip trailing whitespaces */
	while (isspace(*pAfterWS))
	    pAfterWS++ ;

	if (nType == '+' && pAfterWS > p)
	    pAfterWS-- ;
	}

    switch (nType)
        {
        case '+':
            if (r -> CmdStack.State.bProcessCmds == cmdAll)
                {
                r -> bEscModeSet = -1 ;
                r -> pNextEscape = r -> pCurrEscape ;
                rc = EvalTrans (r, r -> Buf.pCurrPos, (r -> Buf.pCurrPos - r -> Buf.pBuf), &pRet) ;
                if (rc != ok && rc != rcEvalErr)
                    return rc ;

                if (pRet)
                    {
		    if (r -> bEscInUrl && SvTYPE(pRet) == SVt_RV && (pAV = (AV *)SvRV(pRet)))
			{			    
			if (SvTYPE(pAV) == SVt_PVAV)
			    { /* Array reference inside URL */
			    SV ** ppSV ;
			    int i ;
			    int f = AvFILL(pAV)  ;
			    for (i = 0; i <= f; i++)
				{
				ppSV = av_fetch (pAV, i, 0) ;
				if (ppSV && *ppSV)
				    {
				    OutputToHtml (r, SvPV (*ppSV, l)) ;
				    }
				if ((i & 1) == 0)
				    oputc (r, '=' ) ;
				else if (i < f)
				    oputs (r, "&amp;") ;
				}
			    }
			else if (SvTYPE(pAV) == SVt_PVHV)
			    { /* Hash reference inside URL */
			    int         i = 0 ;
			    HE *	    pEntry ;
			    char *	    pKey ;
			    SV * 	    pSVValue ;
			    pHV = (HV *)pAV ;

			    hv_iterinit (pHV) ;
			    while (pEntry = hv_iternext (pHV))
				{
				if (i++ > 0)
				    oputs (r, "&amp;") ;
				pKey     = hv_iterkey (pEntry, &li) ;
				OutputToHtml (r, pKey) ;
				oputc (r, '=' ) ;

				pSVValue = hv_iterval (pHV , pEntry) ;
				if (pSVValue)
				    OutputToHtml (r, SvPV (pSVValue, l)) ;
				}
			    }
			}
		    else
			{
			if (r -> pCurrEscape == NULL)
			    {
			    char * p = SvPV (pRet, l) ;
			    owrite (r, p, l) ;
			    }
			else
			    OutputToHtml (r, SvPV (pRet, l)) ;
			}
		    SvREFCNT_dec (pRet) ;
		    }
		r -> pCurrEscape = r -> pNextEscape ;
                r -> bEscModeSet = 0 ;
                }

            p [-2] = nType ;
            r -> Buf.pCurrPos = pAfterWS ;

        
            break ;
        case '-':
            if (r -> CmdStack.State.bProcessCmds == cmdAll)
                {
                rc = EvalTrans (r, r -> Buf.pCurrPos, (r -> Buf.pCurrPos - r -> Buf.pBuf), &pRet) ;
                if (rc != ok && rc != rcEvalErr)
                    return rc ;
                if (pRet)
                    SvREFCNT_dec (pRet) ;
                }

            p [-2] = nType ;
            r -> Buf.pCurrPos = pAfterWS ;

            break ;
        case '!':
            if (r -> CmdStack.State.bProcessCmds == cmdAll)
                {
                rc = EvalTransOnFirstCall (r, r -> Buf.pCurrPos, (r -> Buf.pCurrPos - r -> Buf.pBuf), &pRet) ;
                if (rc != ok && rc != rcEvalErr)
                    return rc ;
                if (pRet)
                    SvREFCNT_dec (pRet) ;
                }

            p [-2] = nType ;
            r -> Buf.pCurrPos = pAfterWS ;

            break ;
        case '#':
            /* just skip comments */
            p [-2] = nType ;
            r -> Buf.pCurrPos = pAfterWS ;

            break ;
        case '$':
            TransHtml (r, r -> Buf.pCurrPos, 0) ;

            /* skip spaces before command */
            while (*r -> Buf.pCurrPos != '\0' && isspace (*r -> Buf.pCurrPos))
                    r -> Buf.pCurrPos++ ;

            /* c holds the start of the command */
            a = c = r -> Buf.pCurrPos ;
            while (*a != '\0' && isalpha (*a))
                a++ ;

            /* a points to first char after command */

            r -> Buf.pCurrPos = p ;

            if ((rc = SearchCmd (r, c, a-c, a, FALSE, &pCmd)) != ok)
                return rc ;
        
        
            if ((rc = ProcessCmd (r, pCmd, a)) != ok)
		{
		p [-2] = nType ;
                return rc ;
		}

            p [-2] = nType ;
            if (r -> Buf.pCurrPos == p)
                r -> Buf.pCurrPos = pAfterWS ;

            break ;
        }

    return ok ;
    }

    
/* ---------------------------------------------------------------------------- */
/* process commands and evals in a string ... */
/* */
/* pIn   points to the string to process */
/* pOut  pointer to a pointer to a buffer for the output, maybe point to pIn at */
/*       exit if nothing to do or the buffer is filled with processed output */
/* nSize size of outputbuffer */
/* */


    
int ScanCmdEvalsInString (/*i/o*/ register req * r,
			  /*in*/  char *   pIn,
                          /*out*/ char * * pOut,
                          /*in*/  size_t   nSize,
                          /*out*/ char * * pFree)
    
    
    { 
    int    rc ;
    char * pSaveCurrPos  ;
    char * pSaveCurrStart ;
    char * pSaveEndPos ;
    char * pSaveLineNo ;
    char * p = strchr (pIn, '[');    


    EPENTRY (ScanCmdEvalsInString) ;

    *pFree = NULL ;
    if (p == NULL)
        {
        /* lprintf (r, "SCEV nothing sArg = %s\n", pIn) ; */
        *pOut = pIn ; /* Nothing to do */
        return ok ;
        }
    /* lprintf (r, "SCEV sArg = %s, p = %s\n", pIn, p) ; */

    /* save global vars */
    pSaveCurrPos   = r -> Buf.pCurrPos ;
    pSaveCurrStart = r -> Buf.pCurrStart ;
    pSaveEndPos    = r -> Buf.pEndPos ;
    pSaveLineNo    = r -> Buf.pLineNoCurrPos ;
    if (r -> Buf.pLineNoCurrPos == NULL)
        r -> Buf.pLineNoCurrPos = r -> Buf.pCurrPos ; /* save it for line no calculation */
    

    r -> Buf.pCurrPos = pIn ;
    r -> Buf.pEndPos  = pIn + strlen (pIn) ;

    *pOut = _malloc (r, nSize) ;
    if (*pOut == NULL)
        return rcOutOfMemory ;

    OutputToMemBuf (r, *pOut, nSize) ;

    rc = ok ;
    while (r -> Buf.pCurrPos < r -> Buf.pEndPos && rc == ok)
        {
        /* */
        /* execute [x ... x] and replace them if nessecary */
        /* */
        if (p == NULL || *p == '\0')
            { /* output the rest of html */
            owrite (r, r -> Buf.pCurrPos, r -> Buf.pEndPos - r -> Buf.pCurrPos) ;
            break ;
            }
        
        if (r -> CmdStack.State.bProcessCmds == cmdAll)
            {
            /* output until next cmd */
            owrite (r, r -> Buf.pCurrPos, p - r -> Buf.pCurrPos) ;
            }
        
        if (r -> bDebug & dbgSource)
            {
            char * s = p ;
            char * n ;

            while (*s && isspace (*s))
                s++ ;
            
            if (*s)
                {
                n = strchr (s, '\n') ;
#ifdef CLOCKS_PER_SEC
                if (r -> bDebug & dbgProfile)
                    if (n)
                        lprintf (r, "[%d]SRC: Time: %d ms  %*.*s\n", r -> nPid, ((clock () - r -> startclock) * 1000 / CLOCKS_PER_SEC), n-s, n-s, s) ;
                    else
                        lprintf (r, "[%d]SRC: Time: %d ms  %70.70s\n", r -> nPid, ((clock () - r -> startclock) * 1000 / CLOCKS_PER_SEC), s) ;
                else
#endif
                    if (n)
                        lprintf (r, "[%d]SRC: %*.*s\n", r -> nPid, n-s, n-s, s) ;
                    else
                        lprintf (r, "[%d]SRC: %70.70s\n", r -> nPid, s) ;

                }
            }        

        
        r -> Buf.pCurrStart = p ;
        rc = ScanCmdEvals (r, p) ;

        p = strchr (r -> Buf.pCurrPos, '[') ;
        }
    
    *pFree = *pOut = OutputToStd (r) ;

    r -> Buf.pCurrPos   = pSaveCurrPos ;
    r -> Buf.pCurrStart = pSaveCurrStart ;
    r -> Buf.pEndPos    = pSaveEndPos ;
    r -> Buf.pLineNoCurrPos = pSaveLineNo ;
    
    return rc ;
    }
            
/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* scan html tag ...                                                            */
/*                                                                              */
/* p points to '<'                                                              */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

static int ScanHtmlTag (/*i/o*/ register req * r,
			/*in*/ char *   p)

    { 
    int  rc ;
    char ec ;
    char ea = 0 ;
    char * pec ;
    char * pea ;
    char * pCmd ;
    char * pArg ;
    char * pArgBuf  = NULL ;
    char * pFreeBuf = NULL ;
    struct tCmd * pCmdInfo ;



    EPENTRY (ScanHtmlTag) ;
    
    
    r -> Buf.pCurrTag = p ;     /* save start of html tag */

    /* skip space */
    p++ ;
    while (*p != '\0' && isspace (*p))
            p++ ;
    
    pCmd = p ;               /* start of tag name */
    while (*p != '\0' && !isspace (*p) && *p != '>')
        p++ ;

    ec = *p ;              /* save first char after tag name */
    pec = p ;
    *p++ = '\0' ;          /* set end of tag name to \0 */

    if ((rc = SearchCmd (r, pCmd, pec - pCmd, "", TRUE, &pCmdInfo)) != ok)
        {
        *pec = ec ;
        oputc (r, *r -> Buf.pCurrTag) ;
        r -> Buf.pCurrPos = r -> Buf.pCurrTag + 1 ;  
        if (rc == rcCmdNotFound)
            return ok ;    /* ignore this html tag */
        return rc ;
        }


    /* look if there are any arguments */    
    
    pArg = p ;             /* start of arguments */
    if (ec == '>')
        { /* No Arguments */
        pArg = p - 1 ;
        pea = NULL ;
        }
    else
        {
        /* get end of tag, skip everything inside [+/- ... -/+] */

        char nType = '\0';
        while ((*p != '>' || nType) && *p != '\0')
            {
            if (nType == '\0' && *p == '[' && (p[1] == '+' || p[1] == '-' || p[1] == '$' || p[1] == '!' || p[1] == '#'))
                nType = *++p ;
            else if (nType && *p == nType && p[1] == ']')
                {
                nType = '\0';
                p++ ;
                }

            p++;
            }

        if (*p == '>')
            {
            ea = *p ;
            pea = p ;
            *p = '\0' ;            /* set end of tag arguments to \0 */
            p++ ;
            }
        else
            {
            p = pArg + strlen (pArg) ;
            pea = NULL ;
            }
        }

    r -> Buf.pCurrPos = p ;    /* r -> Buf.pCurrPos = first char after whole tag */

    
    if (*pArg != '\0' && pCmdInfo -> bScanArg)
    	{
        if ((rc = ScanCmdEvalsInString (r, (char *)pArg, &pArgBuf, nInitialScanOutputSize, &pFreeBuf)) != ok)
            {
            if (pFreeBuf)
                _free (r, pFreeBuf) ;
            return rc ;
            }
    	}
    else
    	pArgBuf = pArg ;
    
    
    /* see if knwon html tag and execute */

    if ((rc = ProcessCmd (r, pCmdInfo, pArgBuf)) != ok)
        {
        if (rc == rcCmdNotFound)
            {
              /* only write html tag start char and */
            /*p = pCurrPos = pCurrTag + 1 ;   */    /* check if more to exceute within html tag */
            }
        else
            {
            if (pFreeBuf)
                _free (r, pFreeBuf) ;
            
            *pec = ec ;              /* restore first char after tag name */
            if (pea)
                *pea = ea ;              /* restore first char after tag arguments */

            return rc ;
            }
        }


    if (p == r -> Buf.pCurrPos && r -> Buf.pCurrPos) /* if CurrPos didn't change write out html tag as it is */
        {
        if (pArg == pArgBuf)
            { /* write unmodified tag */    
            *pec = ec ;              /* restore first char after tag name */
            if (pea)
                *pea = ea ;              /* restore first char after tag arguments */

            oputc (r, *r -> Buf.pCurrTag) ;
            r -> Buf.pCurrPos = r -> Buf.pCurrTag + 1 ;
            }
        else
            { /* write tag with interpreted args */
            oputs (r, r -> Buf.pCurrTag) ;
            oputc (r, ' ') ;
            oputs (r, pArgBuf) ;
            oputc (r, '>') ;
            *pec = ec ;              /* restore first char after tag name */
            if (pea)
                *pea = ea ;              /* restore first char after tag arguments */

            }
        }
    else
        {
        *pec = ec ;              /* restore first char after tag name */
        if (pea)
            *pea = ea ;              /* restore first char after tag arguments */
        }

    if (r -> Buf.pCurrPos == NULL)
        r -> Buf.pCurrPos = p ; /* html tag is written by command handler */

    if (pFreeBuf)
        _free (r, pFreeBuf) ;

    r -> Buf.pCurrTag = NULL ;

    return ok ;    
    }

    
/* ---------------------------------------------------------------------------- */
/* add magic to integer var */
/* */
/* in  sVarName = Name of varibale */
/* in  pVirtTab = pointer to virtual table */
/* */
/* ---------------------------------------------------------------------------- */

static int AddMagic (/*i/o*/ register req * r,
			/*in*/ char *     sVarName,
                     /*in*/ MGVTBL *   pVirtTab) 

    {
    SV * pSV ;
    struct magic * pMagic ;

    EPENTRY (AddMagic) ;

    
    pSV = perl_get_sv (sVarName, TRUE) ;
    sv_magic (pSV, NULL, 0, sVarName, strlen (sVarName)) ;
    sv_setiv (pSV, 0) ;
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

int Init        (/*in*/ int           _nIOType,
                 /*in*/ const char *  sLogFile, 
                 /*in*/ int           nDebugDefault)

    {
    int     rc ;
#ifdef EP2
    HV *   pTokenHash ;
#endif

    req * r = &InitialReq ;
    
    pCurrReq = r ;

    r -> nIOType = _nIOType ;

#if PERL_VERSION >= 8
#if PERL_SUBVERSION >= 50 || PERL_VERSION >= 6
    memcpy (&ep_sv_undef, &PL_sv_undef, sizeof(PL_sv_undef)) ;
#else
    memcpy (&ep_sv_undef, &sv_undef, sizeof(sv_undef)) ;
#endif
#endif

#ifdef APACHE
    r -> pApacheReq = NULL ;
    if (_nIOType == epIOMod_Perl)
	{
	embperl_ApacheAddModule () ;
	}
#endif
    r -> bReqRunning = 0 ;
    
    r -> bDebug = nDebugDefault ;
    
    r -> nPid = getpid () ;

    r -> Buf.nSourceline = 1 ;
    r -> Buf.pSourcelinePos = NULL ;    
    r -> Buf.pLineNoCurrPos = NULL ;    

    r -> nEscMode = escStd ;
    r -> nCurrEscMode = escStd ;

    if ((rc = OpenLog (r, sLogFile, ((r -> bDebug & dbgFunc) || (r -> bOptions & optOpenLogEarly))?1:0)) != ok)
        { 
        r -> bDebug = 0 ; /* Turn debbuging off, only errors will go to stderr */
        LogError (r, rc) ;
        }

    EPENTRY (iembperl_init) ;

    if (r -> bDebug)
        {
        char * p ;

        switch (r -> nIOType)
            {
        #ifdef APACHE
            case epIOMod_Perl: p = "mod_perl"; break ;
        #else
            case epIOMod_Perl: p = "mod_perl UNSUPPORTED"; break ;
        #endif
            case epIOPerl:     p = "Offline"; break ;
            case epIOCGI:      p = "CGI-Script"; break ;
            case epIOProcess:  p = "Demon"; break ;
            default: p = "unknown" ; break ;
            }
        
        /* lprintf (r, "[%d]INIT: Embperl %s starting... mode = %s (%d)\n", nPid, sVersion, p, nIOType) ; */
        }


#ifndef APACHE
    if (r -> nIOType == epIOMod_Perl)
        {
        LogError (r, rcNotCompiledForModPerl) ;
        return 1 ;
        }
#endif

    if (bInitDone)
        return ok ; /* the rest was alreay done */

    /*
    if ((pSubArgsAV = perl_get_av ("_", FALSE)) == NULL)
        {
        LogError (r, rcPerlVarError) ;
        return 1 ;
        }
    */

    if ((r -> pFormHash = perl_get_hv (sFormHashName, TRUE)) == NULL)
        {
        LogError (r, rcHashError) ;
        return 1 ;
        }

    if ((r -> pUserHash = perl_get_hv (sUserHashName, TRUE)) == NULL)
        {
        LogError (r, rcHashError) ;
        return 1 ;
        }

    if ((r -> pStateHash = perl_get_hv (sStateHashName, TRUE)) == NULL)
        {
        LogError (r, rcHashError) ;
        return 1 ;
        }

    if ((r -> pModHash = perl_get_hv (sModHashName, TRUE)) == NULL)
        {
        LogError (r, rcHashError) ;
        return 1 ;
        }


    if ((r -> pFormSplitHash = perl_get_hv (sFormSplitHashName, TRUE)) == NULL)
        {
        LogError (r, rcHashError) ;
        return 1 ;
        }

    if ((r -> pFormArray = perl_get_av (sFormArrayName, TRUE)) == NULL)
        {
        LogError (r, rcArrayError) ;
        return 1 ;
        }

    /*
    if ((r -> pErrArray = perl_get_av (sErrArrayName, TRUE)) == NULL)
        {
        LogError (r, rcArrayError) ;
        return 1 ;
        }

    if ((r -> pErrFill = perl_get_av (sErrFillName, TRUE)) == NULL)
        {
        LogError (r, rcArrayError) ;
        return 1 ;
        }

    if ((r -> pErrState = perl_get_av (sErrStateName, TRUE)) == NULL)
        {
        LogError (r, rcArrayError) ;
        return 1 ;
        }

    */
    if ((r -> pHeaderHash = perl_get_hv (sHeaderHashName, TRUE)) == NULL)
        {
        LogError (r, rcHashError) ;
        return 1 ;
        }

    if ((r -> pInputHash = perl_get_hv (sInputHashName, TRUE)) == NULL)
        {
        LogError (r,  rcHashError) ;
        return 1 ;
        }

    if ((r -> pEnvHash = perl_get_hv (sEnvHashName, TRUE)) == NULL)
        {
        LogError (r,  rcHashError) ;
        return 1 ;
        }

    if (!(pCacheHash = newHV ()))
        {
        LogError (r,  rcHashError) ;
        return 1 ;
        }

    if (!(r -> pErrFill = newAV ()))
        {
        LogError (r, rcArrayError) ;
        return 1 ;
        }
    
    if (!(r -> pErrState = newAV ()))
        {
        LogError (r, rcArrayError) ;
        return 1 ;
        }
    
    if (!(r -> pErrArray = newAV ()))
        {
        LogError (r, rcArrayError) ;
        return 1 ;
        }
    
#ifdef EP2
    if (!(r -> pDomTreeAV = newAV ()))
        {
        LogError (r, rcArrayError) ;
        return 1 ;
        }

    if (!(r -> pCleanupAV = newAV ()))
        {
        LogError (r, rcArrayError) ;
        return 1 ;
        }

#endif    
    
    rc = 0 ;

    ADDINTMG (TabCount) 
    ADDINTMG (TabRow) 
    ADDINTMG (TabCol) 
    ADDINTMG (TabMaxRow) 
    ADDINTMG (TabMaxCol) 
    ADDINTMG (TabMode) 
    ADDINTMG (EscMode) 
#ifdef EP2
    ADDINTMG (CurrNode) 
#endif    
    
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
   
#ifdef EP2
    DomInit () ;
#endif    
    
    bInitDone = 1 ;

    return rc ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* clean up embperl module                                                      */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

int Term ()

    {
    req * r = pCurrReq ;

    EPENTRY (iembperl_term) ;
    
    if (!bInitDone)
        return ok ; 

    CloseLog (r) ;
    CloseOutput (r) ;
    
    return ok ;
    }



int ResetHandler (/*in*/ SV * pApacheReqSV)
    {
#ifdef APACHE
    request_rec * pReq = (request_rec *)SvIV((SV*)SvRV(pApacheReqSV));
    pReq -> handler = NULL ;
#endif

    return ok ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Localise op_mask then opmask_add()                                           */
/*                                                                              */
/* Just copied from Opcode.xs                                                   */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static void
opmask_addlocal(SV *   opset,
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

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Setup Configuration specficy data                                            */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


tConf * SetupConfData   (/*in*/ HV *   pReqInfo,
                         /*in*/ SV *   pOpcodeMask)

    {
#ifdef EP2
    SV * *   ppSV ;
    SV *     pSV ;
    SV * *   ppCV ;
    int	     rc ;
#endif
    tConf *  pConf = malloc (sizeof (tConf)) ;
    
    if (!pConf)
        return NULL ;

    pConf -> bDebug =	    GetHashValueInt (pReqInfo, "debug", pCurrReq -> pConf?pCurrReq -> pConf -> bDebug:pCurrReq -> bDebug) ;	    /* Debugging options */
    pConf -> bOptions =	    GetHashValueInt (pReqInfo, "options",  pCurrReq -> pConf?pCurrReq -> pConf -> bOptions:pCurrReq -> bOptions) ;  /* Options */
    pConf -> nEscMode =	    GetHashValueInt (pReqInfo, "escmode",  pCurrReq -> pConf?pCurrReq -> pConf -> nEscMode:escStd) ;  /* EscMode */
    pConf -> sPackage =	    sstrdup (GetHashValueStr (pReqInfo, "package", NULL)) ;         /* Packagename */
    pConf -> sLogFilename = sstrdup (GetHashValueStr (pReqInfo, "log",  NULL)) ;            /* name of logfile */
    pConf -> sVirtLogURI  = sstrdup (GetHashValueStr (pReqInfo, "virtlog",  pCurrReq -> pConf?pCurrReq -> pConf -> sVirtLogURI:NULL)) ;        /* name of logfile */
    pConf -> pOpcodeMask  = pOpcodeMask ;                                                   /* Opcode mask (if any) */
    pConf -> sCookieName  = sstrdup (GetHashValueStr (pReqInfo, "cookie_name",  sCookieNameDefault))  ;   /* Name to use for cookie */
    pConf -> sCookieExpires = sstrdup (GetHashValueStr (pReqInfo, "cookie_expires",  ""))  ; /* cookie expiration time */
    pConf -> sCookieDomain = sstrdup (GetHashValueStr (pReqInfo, "cookie_domain",  "")) ; ; /* domain patter for which the cookie should be returned */
    pConf -> sCookiePath   = sstrdup (GetHashValueStr (pReqInfo, "cookie_path",  "")) ; ;   /* path to which cookie should be returned */
    pConf -> cMultFieldSep = '\t' ;
    pConf -> pOpenBracket  = "[*" ;
    pConf -> pCloseBracket = "*]" ;
    pConf -> sPath         = sstrdup (GetHashValueStr (pReqInfo, "path",  pCurrReq -> pConf?pCurrReq -> pConf -> sPath:NULL)) ;        /* file search path */
    pConf -> sReqFilename  = sstrdup (GetHashValueStr (pReqInfo, "reqfilename",  pCurrReq -> pConf?pCurrReq -> pConf -> sReqFilename:NULL)) ;        /* filename of original request */
    pConf -> pReqParameter = pReqInfo ;

#ifdef EP2
    pConf -> sRecipe =	    sstrdup (GetHashValueStr (pReqInfo, "recipe", "Embperl")) ;         /* Recipe name */
    pConf -> bEP1Compat	    = GetHashValueInt (pReqInfo, "ep1compat",  pCurrReq -> pConf?pCurrReq -> pConf -> bEP1Compat:pCurrReq -> bEP1Compat) ;  /* EP1Compat */

    pConf -> sCacheKey	    = sstrdup (GetHashValueStr (pReqInfo, "cache_key",  pCurrReq -> pConf?pCurrReq -> pConf -> sCacheKey:NULL)) ; ;
    pConf -> bCacheKeyOptions = GetHashValueInt (pReqInfo, "cache_key_options",  pCurrReq -> pConf?pCurrReq -> pConf -> bCacheKeyOptions:ckoptDefault) ;  

    ppCV			    =     hv_fetch(pReqInfo, "expires_func", sizeof ("expires_func") - 1, 0) ;  
    if (ppCV && *ppCV && SvOK (*ppCV))
	{
	if ((rc = EvalConfig (pCurrReq, *ppCV, 0, NULL, &pConf -> pExpiresCV)) != ok)
	    LogError (pCurrReq, rc) ;
	}
    else
	pConf -> pExpiresCV     =  pCurrReq -> pConf?pCurrReq -> pConf -> pExpiresCV:NULL ;
    

    ppCV			    =     hv_fetch(pReqInfo, "cache_key_func", sizeof ("cache_key_func") - 1, 0) ;  
    if (ppCV && *ppCV && SvOK (*ppCV))
	{
	if ((rc = EvalConfig (pCurrReq, *ppCV, 0, NULL, &pConf -> pCacheKeyCV)) != ok)
	    LogError (pCurrReq, rc) ;
	}
    else
	pConf -> pCacheKeyCV     =  pCurrReq -> pConf?pCurrReq -> pConf -> pCacheKeyCV:NULL ;
    
    pConf -> nExpiresIn	    = GetHashValueInt (pReqInfo, "expires_in",  pCurrReq -> pConf?pCurrReq -> pConf -> nExpiresIn:0) ;  
#endif


    return pConf ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Free Configuration specficy data                                             */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


void FreeConfData       (/*in*/ tConf *   pConf)

    {
    if (!pConf)
        return ;

    if (pConf -> sPackage)
        free (pConf -> sPackage) ;
    
    if (pConf -> sLogFilename)
        free (pConf -> sLogFilename) ;

    if (pConf -> sVirtLogURI)
        free (pConf -> sVirtLogURI) ;

    if (pConf -> sCookieName)
	free (pConf -> sCookieName) ;

    if (pConf -> sCookieExpires)
	free (pConf -> sCookieExpires) ;

    if (pConf -> sCookieDomain)
	free (pConf -> sCookieDomain) ;

    if (pConf -> sCookiePath)
	free (pConf -> sCookiePath) ;

    if (pConf -> sPath)
	free (pConf -> sPath) ;

    if (pConf -> sReqFilename)
	free (pConf -> sReqFilename) ;

#ifdef EP2
    if (pConf -> sCacheKey)
	free (pConf -> sCacheKey) ;
 
    if (pConf -> pCacheKeyCV)
	SvREFCNT_dec (pConf -> pCacheKeyCV) ;

    if (pConf -> pExpiresCV)
	SvREFCNT_dec (pConf -> pExpiresCV) ;
#endif

    free (pConf) ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Setup File specficy data                                                     */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


tFile * SetupFileData   (/*i/o*/ register req * r,
                         /*in*/  char *  sSourcefile,
                         /*in*/  double  mtime,
                         /*in*/  long    nFilesize,
                         /*in*/  int     nFirstLine,
                         /*in*/  tConf * pConf)

    {
    SV * *      ppSV ;
    tFile *     f ;
    char	txt [sizeof (sDefaultPackageName) + 50] ;
    char *	cache_key;
    int		cache_key_len;
    char olddir[PATH_MAX] = "" ;
    char *      pNew ;

    EPENTRY (SetupFileData) ;

    /* Have we seen this sourcefile/package already ? */
    cache_key_len = strlen( sSourcefile ) ;
    if ( pConf->sPackage )
	cache_key_len += strlen( pConf->sPackage );
    
    /* is it a relativ filename? -> append path */
    if (!(sSourcefile[0] == '/' || 
          sSourcefile[0] == '\\' || 
          (isalpha(sSourcefile[0]) && sSourcefile[1] == ':' && 
	          (sSourcefile[2] == '\\' || sSourcefile[2] == '/')) ||
	    (r -> pInData && SvROK(r -> pInData))))
        getcwd (olddir, sizeof (olddir) - 1) ;

    if ( olddir[0] )
	cache_key_len += strlen( olddir );
        
    cache_key = _malloc( r, cache_key_len + 3 );
    strcpy( cache_key, sSourcefile );
    if ( pConf->sPackage )
	strcat( cache_key, pConf->sPackage );

    if ( olddir[0] )
	strcat( cache_key, olddir );


#ifdef EP2
    if ( pConf->bEP1Compat && !pConf->sPackage )
	{
	strcat( cache_key, "-1" ); /* make sure Embperl 1.x compatible files get another namespace */
	cache_key_len += 2 ;
	}
#endif

    ppSV = hv_fetch(pCacheHash, cache_key, cache_key_len, 0);  
    
    if (ppSV && *ppSV)
        {
        f = (tFile *)SvIV((SV*)SvRV(*ppSV)) ;
        
        if (mtime == 0 || f -> mtime != mtime)
            {
            hv_clear (f -> pCacheHash) ;

#ifdef EP2	
	    UndefSub (r, EPMAINSUB, f -> sCurrPackage) ;
#endif
            if (r -> bDebug)
                lprintf (r, "[%d]MEM: Reload %s in %s\n", r -> nPid,  sSourcefile, f -> sCurrPackage) ;

            f -> mtime       = mtime ;	 /* last modification time of file */
            f -> nFilesize   = nFilesize ;	 /* size of File */
	    f -> bKeep       = (r -> bOptions & optKeepSrcInMemory) != 0 ;
	    f -> nFirstLine  = nFirstLine ;
	    if (f -> pExportHash)
		{
		SvREFCNT_dec (f -> pExportHash) ;
		f -> pExportHash = NULL ;
		}
	    if (f -> pBufSV)
		{
		SvREFCNT_dec (f -> pBufSV) ;
		f -> pBufSV = NULL ;
		}
	    }
        pNew = "Found" ;
        }
    else
        { /* create new file structure */
        if ((f = malloc (sizeof (*f))) == NULL)
	    {
	    _free(r,cache_key);
            return NULL ;
	    }

        f -> sSourcefile = sstrdup (sSourcefile) ; /* Name of sourcefile */
        f -> mtime       = mtime ;	 /* last modification time of file */
        f -> nFilesize   = nFilesize ;	 /* size of File */
	f -> pBufSV      = NULL ;
	f -> pNext2Free  = NULL ;
	f -> bKeep       = (r -> bOptions & optKeepSrcInMemory) != 0;
	f -> pExportHash = NULL ;
	f -> nFirstLine  = nFirstLine ;

        f -> pCacheHash  = newHV () ;    /* Hash containing CVs to precompiled subs */

        if (pConf -> sPackage)
            f -> sCurrPackage = strdup (pConf -> sPackage) ; /* Package of file  */
        else
            {
            sprintf (txt, sDefaultPackageName, nPackNo++ ) ;
            f -> sCurrPackage = strdup (txt) ; /* Package of file  */
            }
        f -> nCurrPackage = strlen (f -> sCurrPackage); /* Package of file (length) */

        hv_store(pCacheHash, cache_key, cache_key_len, newRV_noinc (newSViv ((IV)f)), 0) ;  
    
        if (r -> bDebug)
            lprintf (r, "[%d]MEM: Load %s in %s\n", r -> nPid,  sSourcefile, f -> sCurrPackage) ;
        pNew = "New" ;
        }
    if (r -> bDebug)
        lprintf (r, "[%d]CACHE: %s File for '%s' (%x) in '%s' hash cache-key '%s'\n", r -> nPid,  pNew, f -> sSourcefile, f, f -> sCurrPackage, cache_key) ;
    
    _free(r,cache_key);

    return f ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Get file data from filename; preset if not present                           */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


tFile * GetFileData     (/*in*/  char *  sSourcefile,
                         /*in*/  char *  sPackage,
			 /*in*/  double  mtime,
			 /*in*/  int     bEP1Compat)
                        
    {
    SV * *      ppSV ;
    tFile *     f ;
    char	txt [sizeof (sDefaultPackageName) + 50] ;
    char *	cache_key;
    int		cache_key_len;
    char olddir[PATH_MAX] = "" ;
    char *      pNew ;
    
    EPENTRY (GetFileData) ;

    /* Have we seen this sourcefile/package already ? */
    cache_key_len = strlen( sSourcefile ) ;
    if ( sPackage && *sPackage)
	cache_key_len += strlen( sPackage );
    
    /* is it a relativ filename? -> append path */
    if (!(sSourcefile[0] == '/' || 
        sSourcefile[0] == '\\' || 
        (isalpha(sSourcefile[0]) && sSourcefile[1] == ':' && 
            (sSourcefile[2] == '\\' || sSourcefile[2] == '/'))))
        getcwd (olddir, sizeof (olddir) - 1) ;

    if ( olddir[0] )
	cache_key_len += strlen( olddir );
        
    cache_key = malloc(cache_key_len + 3 );
    strcpy( cache_key, sSourcefile );
    if ( sPackage && *sPackage)
	strcat( cache_key, sPackage );

    if ( olddir[0] )
	strcat( cache_key, olddir );


#ifdef EP2
    if ( bEP1Compat )
	{
	strcat( cache_key, "-1" ); /* make sure Embperl 1.x compatible files get another namespace */
	cache_key_len += 2 ;
	}
#endif

    ppSV = hv_fetch(pCacheHash, cache_key, cache_key_len, 0);  
    
    if (ppSV && *ppSV)
        {
        f = (tFile *)SvIV((SV*)SvRV(*ppSV)) ;
        
        if (mtime == 0 || f -> mtime != mtime)
            {
            hv_clear (f -> pCacheHash) ;
#ifdef EP2	
	    UndefSub (pCurrReq, f -> sCurrPackage, EPMAINSUB) ;
#endif
        
            f -> mtime       = -1 ;	 /* reset last modification time of file */
	    if (f -> pExportHash)
		{
		SvREFCNT_dec (f -> pExportHash) ;
		f -> pExportHash = NULL ;
		}
	    }
        pNew = "Found " ;
        }
    else
        { /* create new file structure */
        if ((f = malloc (sizeof (*f))) == NULL)
	    {
	    free(cache_key);
            return NULL ;
	    }

        f -> sSourcefile = sstrdup (sSourcefile) ; /* Name of sourcefile */
        f -> mtime       = -1 ;	 /* last modification time of file */
        f -> nFilesize   = 0 ;	 /* size of File */
	f -> pBufSV      = NULL ;
	f -> pNext2Free  = NULL ;
	f -> bKeep       = 0 ;
	f -> pExportHash = NULL ;
	f -> nFirstLine  = 0 ;

        f -> pCacheHash  = newHV () ;    /* Hash containing CVs to precompiled subs */

	if ( sPackage && *sPackage)
            f -> sCurrPackage = strdup (sPackage) ; /* Package of file  */
        else
            {
            sprintf (txt, sDefaultPackageName, nPackNo++ ) ;
            f -> sCurrPackage = strdup (txt) ; /* Package of file  */
            }
        f -> nCurrPackage = strlen (f -> sCurrPackage); /* Package of file (length) */

        hv_store(pCacheHash, cache_key, cache_key_len, newRV_noinc (newSViv ((IV)f)), 0) ;  
    
        pNew = "New " ;
        }

    if (pCurrReq -> bDebug)
        lprintf (pCurrReq, "[%d]CACHE: %s File for %s (%x) in %s hash cache-key %s\n", pCurrReq -> nPid,  pNew, f -> sSourcefile, f, f -> sCurrPackage, cache_key) ;
    
    free(cache_key);

    return f ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Free File buffer								*/
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static void FreeFileBuf     (/*i/o*/ register req * r,
			     /*i/o*/ tFile * f)


    {
    if (!f -> bKeep && f -> pBufSV)
	{
	SvREFCNT_dec (f -> pBufSV) ;
	f -> pBufSV = NULL ;
        if (r -> bDebug)
            lprintf (r, "[%d]MEM: Free buffer for %s in %s\n", r -> nPid,  f -> sSourcefile, f -> sCurrPackage) ;
	}
    else if (r -> bDebug && !f -> pBufSV)
        lprintf (r, "[%d]MEM: Warning! buffer for %s in %s is NULL\n", r -> nPid,  f -> sSourcefile, f -> sCurrPackage) ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Create Session cookie                                                        */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static SV * CreateSessionCookie (/*i/o*/ register req * r,
				 /*in*/  HV * pSessionHash,
				 /*in*/  char type,
                                 /*in*/  int  bReturnCookie)
    
    {
    SV **   ppSVID ;
    SV *    pSVID = NULL ;
    SV *    pSVUID = NULL ;
    MAGIC * pMG ;
    char *  pUID = NULL ;
    char *  pInitialUID = NULL ;
    STRLEN  ulen = 0 ;
    STRLEN  ilen = 0 ;
    IV	    bModified ;
    SV *    pCookie = NULL ;
    STRLEN  ldummy ;

    if (r -> nSessionMgnt)
	{			
	SV * pUserHashObj = NULL ;
	if ((pMG = mg_find((SV *)pSessionHash,'P')))
	    {
	    dSP;                            /* initialize stack pointer      */
	    int n ;
	    pUserHashObj = pMG -> mg_obj ;

	    PUSHMARK(sp);                   /* remember the stack pointer    */
	    XPUSHs(pUserHashObj) ;            /* push pointer to obeject */
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
	    }
	
	if (r -> bDebug & dbgSession)  
	    lprintf (r, "[%d]SES:  Received Cookie ID: %s  New Cookie ID: %s  %s data is%s modified\n", r -> nPid, pInitialUID, pUID, type == 's'?"State":"User", bModified?"":" NOT") ; 

	if (ilen > 0 && (ulen == 0 || (!bModified && strcmp ("!DELETE", pInitialUID) == 0)))
	    { /* delete cookie */
            if (bReturnCookie)
                {                    
                pCookie = newSVpvf ("%s%s=; expires=Thu, 1-Jan-1970 00:00:01 GMT%s%s%s%s",  r -> pConf -> sCookieName, type == 's'?"s":"",
			    r -> pConf -> sCookieDomain[0]?"; domain=":""  , r -> pConf -> sCookieDomain, 
			    r -> pConf -> sCookiePath[0]?"; path=":""      , r -> pConf -> sCookiePath) ;
                }

	    if (r -> bDebug & dbgSession)  
		lprintf (r, "[%d]SES:  Delete Cookie -> %s\n", r -> nPid, SvPV(pCookie, ldummy)) ;
	    }
	else if (ulen > 0 && 
		    ((bModified && (ilen == 0 || strcmp (pInitialUID, pUID) !=0)) ||
		     (r -> nSessionMgnt & 4) || !bReturnCookie))
	    {
            if (bReturnCookie)
                {                    
	        pCookie = newSVpvf ("%s%s=%s%s%s%s%s%s%s",  r -> pConf -> sCookieName, type == 's'?"s":"", pUID,
			    r -> pConf -> sCookieDomain[0]?"; domain=":""  , r -> pConf -> sCookieDomain, 
			    r -> pConf -> sCookiePath[0]?"; path=":""      , r -> pConf -> sCookiePath, 
			    r -> pConf -> sCookieExpires[0]?"; expires=":"", r -> pConf -> sCookieExpires) ;
	        if (r -> bDebug & dbgSession)  
		    lprintf (r, "[%d]SES:  Send Cookie -> %s\n", r -> nPid, SvPV(pCookie, ldummy)) ; 
                }
            else
                {
                pCookie = pSVUID ;
                }
	    }
	}
    return pCookie ;
    }
    

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Setup Request                                                                */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


tReq * SetupRequest (/*in*/ SV *    pApacheReqSV,
                     /*in*/ char *  sSourcefile,
                     /*in*/ double  mtime,
                     /*in*/ long    nFilesize,
                     /*in*/ int     nFirstLine,
                     /*in*/ char *  sOutputfile,
                     /*in*/ tConf * pConf,
                     /*in*/ int     nIOType,
                     /*in*/ SV *    pIn,
                     /*in*/ SV *    pOut,
		     /*in*/ char *  sSubName,
		     /*in*/ char *  sImport,
		     /*in*/ int	    nSessionMgnt,
                     /*in*/ tTokenTable * pTokenTable)

    {
    int     rc ;
    tReq *  r = pCurrReq ;
    char *  sMode ;
    tFile * pFile ;
    HV * pReqHV  ;
#ifdef EP2
    SV * * ppSV ;
    STRLEN len ;
#endif

    dTHR ;

	
    tainted         = 0 ;

    if (pConf -> bDebug)
	if ((rc = OpenLog (pCurrReq, NULL, 2)) != ok)
	    { 
	    LogError (pCurrReq, rc) ;
	    }

    EPENTRY (SetupRequest) ;

    if (pReqFree)
        {
        r = pReqFree ;
        pReqFree = pReqFree -> pNext ;
        memcpy (r, pCurrReq, (char *)&r -> zeroend - (char *)r) ;
        r -> pNext = NULL ;
        }
    else
        {
        if ((r = malloc (sizeof (tReq))) == NULL)
            return NULL ;
        
        memcpy (r, pCurrReq, sizeof (*r)) ;
        }
    
#ifdef EP2
    r -> nPhase  = phInit ;
#endif
    r -> bSubReq = !(pCurrReq == &InitialReq) ;

    r -> pLastReq = pCurrReq ;
    pCurrReq = r ;
    
#ifdef APACHE
    if (SvROK (pApacheReqSV))
        r -> pApacheReq = (request_rec *)SvIV((SV*)SvRV(pApacheReqSV));
    else
        r -> pApacheReq = NULL ;
    r -> pApacheReqSV = pApacheReqSV ;
#endif


    if (!r -> pLastReq -> pReqSV)
	pReqHV = newHV () ;
    else
	{
	pReqHV = (HV *)SvRV (r -> pLastReq -> pReqSV) ;
	SvREFCNT_inc (pReqHV) ;
	}

    sv_unmagic ((SV *)pReqHV, '~') ;
    sv_magic ((SV *)pReqHV, NULL, '~', (char *)&r, sizeof (r)) ;
    r -> pReqSV = newRV_noinc ((SV *)pReqHV) ;
    if (!r -> pLastReq -> pReqSV)
	sv_bless (r -> pReqSV, gv_stashpv ("HTML::Embperl::Req", 0)) ;

    r -> startclock      = clock () ;
    r -> stsv_count      = sv_count ;
    r -> stsv_objcount   = sv_objcount ;
    r -> lstsv_count     = sv_count ;
    r -> lstsv_objcount  = sv_objcount ;

    r -> nPid            = getpid () ; /* reget pid, because it could be chaned when loaded with PerlModule */
    r -> bDebug          = pConf -> bDebug ;
#ifdef EP2
    r -> bEP1Compat      = pConf -> bEP1Compat ;
    ppSV = hv_fetch(r -> pEnvHash, "PATH_INFO", sizeof ("PATH_INFO") - 1, 0) ;  
    if (ppSV)
        r -> sPathInfo = SvPV (*ppSV ,len) ;
    r -> pTokenTable = pTokenTable ;    
#else
    r -> pTokenTable = (void *)pTokenTable ;    
#endif
    if (rc != ok)
        r -> bDebug = 0 ; /* Turn debbuging off, only errors will go to stderr if logfile not open */
    r -> bOptions        = pConf -> bOptions ;
    /*r -> nIOType         = InitialReq.nIOType ;*/

    r -> sSubName        = sSubName ;
    r -> nSessionMgnt    = nSessionMgnt ;    
    r -> pConf           = pConf ;
    r -> nInsideSub	 = 0 ;
    r -> bExit  	 = 0 ;
    
    r -> pOutData        = pOut ;
    r -> pInData         = pIn ;

    r -> pFiles2Free	 = NULL ;
    if (r -> bSubReq && sSourcefile[0] == '?' && sSubName && sSubName[0] != '\0')
	{
	pFile = r -> pLastReq -> Buf.pFile ;
	}
    else
	{
	if ((pFile = SetupFileData (r, sSourcefile, mtime, nFilesize, nFirstLine, pConf)) == NULL)
            return NULL ;
	}

    if (r -> bSubReq && sOutputfile[0] == 1 && r -> pLastReq && !SvROK (pOut))
        {
        r -> sOutputfile      = r -> pLastReq -> sOutputfile ;
        r -> bAppendToMainReq = TRUE ;
        }
    else
        {
        if (sOutputfile[0] == 1)
            r -> sOutputfile      = "" ;
        else
            r -> sOutputfile      = sOutputfile ;
        r -> bAppendToMainReq = FALSE ;
        }
    
    r -> bReqRunning     = 0 ;

    r -> Buf.pFile = pFile ;

    r -> pOutData        = pOut ;
    r -> pInData         = pIn ;

    
    r -> CmdStack.State.nCmdType      = cmdNorm ;
    r -> CmdStack.State.bProcessCmds  = cmdAll ;
    r -> HtmlStack.State.nCmdType      = cmdNorm ;
    r -> HtmlStack.State.bProcessCmds  = cmdAll ;
    r -> nTabMode        = epTabRowDef | epTabColDef ;
    r -> nTabMaxRow      = 100 ;
    r -> nTabMaxCol      = 10 ;


    r -> nEscMode = pConf -> nEscMode ;
    NewEscMode (r, NULL) ;
    r -> bEscModeSet = 0 ;


    if (r -> bOptions & optSafeNamespace)
	{
        r -> Buf.sEvalPackage = "main" ;
        r -> Buf.nEvalPackage = sizeof ("main") - 1 ;
        }
    else
	{
        r -> Buf.sEvalPackage = r -> Buf.pFile -> sCurrPackage ;
        r -> Buf.nEvalPackage = r -> Buf.pFile -> nCurrPackage ;
        }
    
    if (sImport && *sImport)
	{

        if ((r -> pImportStash = gv_stashpv (sImport, 0)) == NULL)
	    {
	    strncpy (r -> errdat1, sImport, sizeof (r -> errdat1) - 1);
	    LogError (r, rcImportStashErr) ;
	    }
	r -> bOptions |= optDisableHtmlScan ;
	}
    else
	r -> pImportStash = NULL ;

    r -> Buf.nSourceline = r -> Buf.pFile -> nFirstLine ;
    r -> Buf.pSourcelinePos = NULL ;    
    r -> Buf.pLineNoCurrPos = NULL ;    

    r -> bStrict       = FALSE ;

    r -> errdat1 [0]  = '\0' ; /* Additional error information */
    r -> errdat2 [0]  = '\0' ;
    r -> lastwarn [0] = '\0' ; /* last warning */
    
    if (!r -> bSubReq)
        {
        r -> bError = FALSE ;
        av_clear (r -> pErrFill) ;
        av_clear (r -> pErrState) ;
        av_clear (r -> pErrArray) ;
        hv_clear (r -> pHeaderHash) ;
        r -> nLastErrFill  = AvFILL(r -> pErrArray) ;
        r -> bLastErrState = r -> bError ;
        r -> nLogFileStartPos = GetLogFilePos (r) ;
        }


    if (r -> bDebug)
        {
        time_t t ;
        struct tm * tm ;
        time (&t) ;        
        tm =localtime (&t) ;
        if (!r -> bSubReq)
	    lprintf (r, "[%d]REQ:  Embperl %s starting... %s\n", r -> nPid,  sVersion, asctime(tm)) ;
        r -> numEvals = 0  ;
        r -> numCacheHits = 0 ;
        }
    
    if (r -> bDebug)
        {
        switch (r -> nIOType)
            {
            case epIOMod_Perl: sMode = "mod_perl"; break ;
            case epIOPerl:     sMode = "Offline"; break ;
            case epIOCGI:      sMode = "CGI-Script"; break ;
            case epIOProcess:  sMode = "Demon"; break ;
            default: sMode = "unknown" ; break ;
            }
        
        lprintf (r, "[%d]REQ:  %s  %s  ", r -> nPid, (r -> bOptions & optSafeNamespace)?"SafeNamespace":"No Safe Eval", (r -> bOptions & optOpcodeMask)?"OpcodeMask":"All Opcode allowed") ;
#ifdef EP2
	lprintf (r, " mode = %s (%d) %s recipe = %s\n", sMode, r -> nIOType, r -> bEP1Compat?"EP 1.x":"EP 2.x", r -> pConf -> sRecipe) ;
#else
        lprintf (r, " mode = %s (%d)\n", sMode, r -> nIOType) ;
#endif
	lprintf (r, "[%d]REQ:  Package = %s\n", r -> nPid, r -> Buf.pFile -> sCurrPackage) ;
        }

    return r ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Free Request                                                                 */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


void FreeRequest (/*i/o*/ register req * r)

    {
    FreeConfData (r -> pConf) ;
    r -> pConf = NULL ;

    if (!r -> bAppendToMainReq && r -> ofd)
        CloseOutput (r) ; /* just to be sure */
    
    if (r -> bSubReq)
        {
        tReq * l = r -> pLastReq ;

        l -> bError      = r -> bError ;
        l -> nLastErrFill= r -> nLastErrFill ;
        l -> bLastErrState= r -> bLastErrState ;
        }
    else
        {
        tFile * pFile ;
        tFile * pNext ;
	int     i ;

#ifdef HASHTEST
	pHash = perl_get_hv (sFormHashName, FALSE) ;
	if (pHash != r -> pFormHash)
	    {
	    strcpy (r -> errdat1, sFormHashName) ;
	    strcpy (r -> errdat2, " !!C-Adress differs from Perl-Adress!! in FreeRequest") ;
	    LogError (r, rcHashError) ;
	    }
#endif

        hv_clear (r -> pHeaderHash) ;
        av_clear (r -> pFormArray) ;
        hv_clear (r -> pFormHash) ;
        hv_clear (r -> pInputHash) ;
        hv_clear (r -> pFormSplitHash) ;
#ifdef EP2 
        av_clear (r -> pDomTreeAV) ;
	for (i = 0 ; i < AvFILL (r -> pCleanupAV); i++)
	    {
	    sv_setsv (SvRV(*av_fetch (r -> pCleanupAV, i, 0)), &sv_undef) ;
	    }
        av_clear (r -> pCleanupAV) ;

#endif
	if ((pFile = r -> pFiles2Free))
	    {
	    do
		{
		FreeFileBuf (r, pFile) ;
		pNext = pFile -> pNext2Free ;
		pFile -> pNext2Free = NULL ;
		}
	    while (pFile != pNext && (pFile = pNext)) ;
	    }
#ifdef APACHE
	r -> pApacheReq   = NULL ;
	r -> pApacheReqSV = &sv_undef ;
#endif
	}

    SvREFCNT_dec (r -> pReqSV) ;

    pCurrReq = r -> pLastReq ;
    if (pCurrReq && pCurrReq -> pReqSV)
	{
	SV * pReqHV = SvRV (pCurrReq -> pReqSV) ;
	sv_unmagic (pReqHV, '~') ;
	sv_magic (pReqHV, NULL, '~', (char *)&pCurrReq, sizeof (pCurrReq)) ;
	}

    if (r -> sSessionID)
	_free (r, r -> sSessionID) ;
    r -> pNext = pReqFree ;
    pReqFree = r ;
    }


                     
/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Setup Safe Namespace                                                         */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static void SetupSafeNamespace (/*i/o*/ register req * r)

    {                 
    GV *    gv;

    dTHR ;

	/* The following is borrowed from Opcode.xs */

    if (r -> bOptions & optOpcodeMask)
        opmask_addlocal(r -> pConf -> pOpcodeMask, r -> op_mask_buf);

        
    if (r -> bOptions & optSafeNamespace)
        {
        save_aptr(&endav);
        endav = (AV*)sv_2mortal((SV*)newAV()); /* ignore END blocks for now	*/

        save_hptr(&defstash);		/* save current default stack	*/
        /* the assignment to global defstash changes our sense of 'main'	*/
        defstash = gv_stashpv(r -> Buf.pFile -> sCurrPackage, GV_ADDWARN); /* should exist already	*/

        if (r -> bDebug)
            lprintf (r, "[%d]REQ:  switch to safe namespace %s\n", r -> nPid, r -> Buf.pFile -> sCurrPackage) ;


        /* defstash must itself contain a main:: so we'll add that now	*/
        /* take care with the ref counts (was cause of long standing bug)	*/
        /* XXX I'm still not sure if this is right, GV_ADDWARN should warn!	*/
        gv = gv_fetchpv("main::", GV_ADDWARN, SVt_PVHV);
        sv_free((SV*)GvHV(gv));
        GvHV(gv) = (HV*)SvREFCNT_inc(defstash);
        }
    }

    
/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Start the output stream                                                      */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

    
static int StartOutput (/*i/o*/ register req * r)

    {
    int rc ;
    SV * pOutData  = r -> pOutData ;
    int  bOutToMem = SvROK (pOutData) ;
    

    if (r -> pImportStash)
	{ /* import does not generate any output */
	r -> bDisableOutput = 1 ;
	}
    else if (!bOutToMem)
        {
        if (!r -> bAppendToMainReq)
            {
            if ((rc = OpenOutput (r, r -> sOutputfile)) != ok)
                return rc ;
            }
        else
            OutputToStd (r) ;
        }
    else
        { /* only reset output buffers */
        r -> ofd = NULL ;
        OpenOutput (r, NULL) ;
        }


#ifdef APACHE
    if (r -> pApacheReq && r -> pApacheReq -> main)
    	r -> bOptions |= optEarlyHttpHeader ; /* do not direct output to memory on internal redirect */
#endif
    if (bOutToMem)
    	r -> bOptions &= ~optEarlyHttpHeader ;

    if (r -> bSubReq || r -> pImportStash)
    	r -> bOptions &= ~optSendHttpHeader ;


    if (r -> bOptions & optEarlyHttpHeader)
        {
#ifdef APACHE
        if (r -> pApacheReq == NULL)
            {
#endif
            if (r -> nIOType != epIOPerl && (r -> bOptions & optSendHttpHeader))
                oputs (r, "Content-type: text/html\n\n") ;

#ifdef APACHE
            }
        else
            {
            if (r -> pApacheReq -> main == NULL && (r -> bOptions & optSendHttpHeader))
            	send_http_header (r -> pApacheReq) ;
#ifndef WIN32
	    /* shouldn't be neccessary for newer mod_perl versions !? */
	    /* mod_perl_sent_header(r -> pApacheReq, 1) ; */
#endif
            if (r -> pApacheReq -> header_only)
            	{
	        if (!r -> bAppendToMainReq)
                    CloseOutput (r) ;
            	return ok ;
    	        }
            }
#endif
        }
    else
        {
        /*
	if (r -> nIOType == epIOCGI && (r -> bOptions & optSendHttpHeader))
            oputs (r, "Content-type: text/html\n\n") ;
        */
	
        oBegin (r) ;
        }


    if ((r -> bOptions & optAddStateSessionToLinks) && !r -> bSubReq)
	{
	SV * pCookie = CreateSessionCookie (r, r -> pStateHash, 's', 0) ; 
        STRLEN l ;
        lprintf (r, "opt %x optadd %x options %x cookie %s\n", optAddStateSessionToLinks, r -> bOptions & optAddStateSessionToLinks, r -> bOptions, SvPV(pCookie, l)) ;
	if (pCookie)
            {
            r -> sSessionID = _memstrcat  (r, r -> pConf -> sCookieName, "=", SvPV (pCookie, l), NULL) ;
            }
        }
    
    if ((r -> bOptions & optAddUserSessionToLinks) && !r -> bSubReq)
        {
	SV * pCookie = CreateSessionCookie (r, r -> pUserHash, 'u', 0) ; 
        if (pCookie)
            {
            STRLEN l ;
            if (r -> sSessionID)
                r -> sSessionID = _memstrcat (r, r -> sSessionID, ":", SvPV (pCookie, l), NULL) ;
            else
		r -> sSessionID = _memstrcat  (r, r -> pConf -> sCookieName, "=:", SvPV (pCookie, l), NULL) ;
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
    SV * pOut = NULL ;
    int  bOutToMem = SvROK (pOutData) ;
    SV * pCookie = NULL ;
    SV * pCookie2 = NULL ;
    int  bError = 0 ;
    STRLEN ldummy ;

#ifdef EP2
    /* ### tmp ### */
    int bXSLT = 0 ;

    if (strcmp (r ->  pConf -> sRecipe + strlen (r ->  pConf -> sRecipe) - 4 , "XSLT") == 0)
        {
        bXSLT = 1 ;
        }
#endif
    
    r -> bEscModeSet = 0 ;

    if (rc != ok ||  r -> bError)
        { /* --- generate error page if necessary --- */
	dSP;                            /* initialize stack pointer      */
        
	/* --- check if error should be mailed --- */
	PUSHMARK(sp);                   /* remember the stack pointer    */
        XPUSHs(r -> pReqSV) ;            /* push pointer to obeject */
        PUTBACK;
        perl_call_method ("MailErrorsTo", G_DISCARD) ; /* call the function             */

        
	if (r -> bOptions & optReturnError)
	    {
    	    r -> bError = 1 ;
	    oRollbackOutput (r, NULL) ;
	    if (bOutToMem)
		{
		pOut = SvRV (pOutData) ;
		sv_setsv (pOut, &sv_undef) ;
		}
	    return ok ; /* No further output or header, this should be handle by the server */
	    }    
        else if (!(r -> bOptions & optDisableEmbperlErrorPage))
	    {
	    if (!r -> bAppendToMainReq)
		{

		oRollbackOutput (r, NULL) ; /* forget everything outputed so far */
		oBegin (r) ;

		PUSHMARK(sp);                   /* remember the stack pointer    */
		XPUSHs(r -> pReqSV) ;            /* push pointer to obeject */
		PUTBACK;
		perl_call_method ("SendErrorDoc", G_DISCARD) ; /* call the function             */
#ifdef APACHE
		if (r -> pApacheReq)
		    r -> pApacheReq -> status = 500 ;
#endif
		}
	    bError = 1 ;
	    }
	if (!r -> bAppendToMainReq)
   	    r -> bError = 0 ; /* error already handled */
	}
    

    if (!(r -> bOptions & optEarlyHttpHeader) && (r -> bOptions & optSendHttpHeader) && !bOutToMem)
        {  /* --- send http headers if not alreay done --- */
        if (!r -> bAppendToMainReq)
            {                    
            if (!(r -> bOptions & optNoSessionCookies))
                pCookie = CreateSessionCookie (r, r -> pUserHash, 'u', 1) ;
	    /* pCookie2 = CreateSessionCookie (r, r -> pStateHash, 's') ; */
		
#ifdef APACHE
	    if (r -> pApacheReq)
		{
		SV *   pHeader ;
		char * p ;
		HE *   pEntry ;
		char * pKey ;
		I32    l ;

 
 		I32	i;
 		I32	len;
 		AV	*arr;
 		SV	**svp;

		/* loc = 0  =>  no location header found
		 * loc = 1  =>  location header found
		 * loc = 2  =>  location header + value found
		 */
 		I32	loc;
        
		hv_iterinit (r -> pHeaderHash) ;
		while ((pEntry = hv_iternext (r -> pHeaderHash)))
		    {
		    pKey     = hv_iterkey (pEntry, &l) ;
		    pHeader  = hv_iterval (r -> pHeaderHash, pEntry) ;
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
				r->pApacheReq->content_type = pstrdup(r->pApacheReq->pool, p);
			    } 
  			else if (SvROK(pHeader)  && SvTYPE(SvRV(pHeader)) == SVt_PVAV ) 
 			    {
 			    arr = (AV *)SvRV(pHeader);
 			    len = av_len(arr);
 			    for (i = 0; i <= len; i++) 
 				{
 				svp = av_fetch(arr, i, 0);
 				p = SvPV(*svp, ldummy);
 				table_add( r->pApacheReq->headers_out, pstrdup(r->pApacheReq->pool, pKey),
 					   pstrdup(r->pApacheReq->pool, p ) );
 				if (loc == 1) 
				    {
				    loc = 2;
				    break;
 				    }
				}
 			    } 
 			else 
 			    {
 			    p = SvPV(pHeader, ldummy);
			    table_set(r -> pApacheReq->headers_out, pstrdup(r -> pApacheReq->pool, pKey), pstrdup(r -> pApacheReq->pool, p)) ;
			    if (loc == 1) loc = 2;
			    }

			if (loc == 2) r->pApacheReq->status = 301;
			}
		    }


		if (pCookie)
		    {
		    table_add(r -> pApacheReq->headers_out, sSetCookie, pstrdup(r -> pApacheReq->pool, SvPV(pCookie, ldummy))) ;
		    SvREFCNT_dec (pCookie) ;
		    }
		if (pCookie2)
		    {
		    table_add(r -> pApacheReq->headers_out, sSetCookie, pstrdup(r -> pApacheReq->pool, SvPV(pCookie2, ldummy))) ;
		    SvREFCNT_dec (pCookie2) ;
		    }
#ifdef EP2
	        if (r -> bEP1Compat)  /*  Embperl 2 currently cannot calc Content Length */
#endif
		set_content_length (r -> pApacheReq, GetContentLength (r) + (r -> pCurrEscape?2:0)) ;
		send_http_header (r -> pApacheReq) ;
#ifndef WIN32
		/* shouldn't be neccessary for newer mod_perl versions !? */
                /* mod_perl_sent_header(r -> pApacheReq, 1) ; */
#endif
                if (r -> bDebug & dbgHeadersIn)
        	    {
        	    int i;
        	    array_header *hdrs_arr;
        	    table_entry  *hdrs;

        	    hdrs_arr = table_elts (r -> pApacheReq->headers_out);
	            hdrs = (table_entry *)hdrs_arr->elts;

        	    lprintf (r,  "[%d]HDR:  %d\n", r -> nPid, hdrs_arr->nelts) ; 
	            for (i = 0; i < hdrs_arr->nelts; ++i)
		        if (hdrs[i].key)
                	    lprintf (r,  "[%d]HDR:  %s=%s\n", r -> nPid, hdrs[i].key, hdrs[i].val) ; 
        	    }
                }
	    else
#endif
		{ 
		if (r -> nIOType == epIOCGI)
		    {            
		    char txt[100] ;
		    int  save = r -> nMarker ;
		    SV *   pHeader ;
		    char * p ;
		    HE *   pEntry ;
		    char * pKey ;
		    I32    l ;
		    char * pContentType = "text/html";

		    r -> nMarker = 0 ; /* output directly */
        
		    hv_iterinit (r -> pHeaderHash) ;
		    while ((pEntry = hv_iternext (r -> pHeaderHash)))
			{
			pKey     = hv_iterkey (pEntry, &l) ;
			pHeader  = hv_iterval (r -> pHeaderHash, pEntry) ;

			if (pHeader && pKey)
			    {			    
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
				    if (r -> bDebug & dbgHeadersIn)
                			lprintf (r,  "[%d]HDR:  %s: %s\n", r -> nPid, pKey, p) ; 
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
				if (r -> bDebug & dbgHeadersIn)
                		    lprintf (r,  "[%d]HDR:  %s: %s\n", r -> nPid, pKey, p) ; 
				}
			    }
			}
		    
		    oputs (r, "Content-Type: ") ;
		    oputs (r, pContentType) ;
		    oputs (r, "\n") ;
		    sprintf (txt, "Content-Length: %d\n", GetContentLength (r) + (r -> pCurrEscape?2:0)) ;
		    oputs (r, txt) ;
		    if (pCookie)
			{
			oputs (r, sSetCookie) ;
			oputs (r, ": ") ;
			oputs (r, SvPV(pCookie, na)) ;
			oputs (r, "\n") ;
			SvREFCNT_dec (pCookie) ;
			}
		    if (pCookie2)
			{
			oputs (r, sSetCookie) ;
			oputs (r, ": ") ;
			oputs (r, SvPV(pCookie2, na)) ;
			oputs (r, "\n") ;
			SvREFCNT_dec (pCookie2) ;
			}

		    oputs (r, "\n") ;

		    r -> nMarker = save ;
		    }
		}
	    }
	}

    /* --- output the content if not alreay done --- */

    if (bOutToMem)
        pOut = SvRV (pOutData) ;


#ifdef APACHE
    if ((r -> pApacheReq == NULL || !r -> pApacheReq -> header_only) && 
	(!(r -> bOptions & optEarlyHttpHeader) || r -> bAppendToMainReq))
#else
    if (!(r -> bOptions & optEarlyHttpHeader) || r -> bAppendToMainReq)
#endif
        {
#ifdef EP2
	if (r -> bEP1Compat && r -> pCurrEscape)
#else
	if (r -> pCurrEscape)
#endif		
	    oputs (r, "\r\n") ;
#ifdef EP2

        if (bXSLT && !bError && !r -> bEP1Compat)
            {
            char * pData ;
            int    l ;

	    tDomTree * pDomTree = DomTree_self (r -> xCurrDomTree) ;
	    Node_toString (r, pDomTree, pDomTree -> xDocument, 0) ;

            pOut = newSVpv ("", 0) ;
	    oputs (r, "\r\n") ;
            l = GetContentLength (r) + 1 ;
            
            SvGROW (pOut, l) ;
            pData = SvPVX (pOut) ;
            oCommitToMem (r, NULL, pData) ;
            oRollbackOutput (r, NULL) ;
            SvCUR_set (pOut, l - 1) ;

            if (r -> bAppendToMainReq)
                oBegin (r) ;

            
            if (strstr (r -> pConf -> sRecipe, "LibXSLT"))
                {
#ifdef LIBXSLT
                if (r -> bDebug & dbgXSLT)
                    lprintf (r, "[%d]XSLT: call libxslt\n", r -> nPid) ;

                if ((rc = embperl_LibXSLT_Text2Text   (r, r -> pConf -> pReqParameter, pOut)) != ok)
                    return rc ;
#else
                strcpy (r -> errdat1, "libxslt not supported") ;
                return 9999 ;
#endif
                }
            else if (strstr (r -> pConf -> sRecipe, "Xalan"))
                {
#ifdef XALAN
                if (r -> bDebug & dbgXSLT)
                    lprintf (r, "[%d]XSLT: call xalan\n", r -> nPid) ;

                if ((rc = embperl_Xalan_Text2Text   (r, r -> pConf -> pReqParameter, pOut)) != ok)
                    return rc ;
#else
                strcpy (r -> errdat1, "xalan not supported") ;
                return 9999 ;
#endif
                }
            }
#endif

        if (bOutToMem)
            {
            char * pData ;
            int    l ;
#ifdef EP2
            		
	    if (!bError && !r -> bEP1Compat)
		{
		tDomTree * pDomTree = DomTree_self (r -> xCurrDomTree) ;
		Node_toString (r, pDomTree, pDomTree -> xDocument, 0) ;
		}

	    if (!r -> bEP1Compat)
		oputs (r, "\r\n") ;
#endif		
            l = GetContentLength (r) + 1 ;
            
            sv_setpv (pOut, "") ;
            SvGROW (pOut, l) ;
            pData = SvPVX (pOut) ;
            oCommitToMem (r, NULL, pData) ;
            SvCUR_set (pOut, l - 1) ;
            }
        else
            {
            if (r -> bAppendToMainReq)
                {
                tReq * l = r -> pLastReq ;


#ifdef EP2
		if (r -> bEP1Compat)
		    {
#endif
		    l -> pFirstBuf   = r -> pFirstBuf  ;
		    l -> pLastBuf    = r -> pLastBuf   ;
		    l -> pFreeBuf    = r -> pFreeBuf   ;
		    l -> pLastFreeBuf= r -> pLastFreeBuf ;
		    l -> nSessionMgnt= r -> nSessionMgnt ;
#ifdef EP2
		    }
		else
		    {
		    if (!bError && !r -> pImportStash)
			{
			tDomTree * pDomTree = DomTree_self (r -> xCurrDomTree) ;
                        if (bXSLT)
                            {
                            int len = GetContentLength (r) + 1 ;
                            char * pData = _malloc (r, len) ;
                            oCommitToMem (r, NULL, pData) ;
                            oRollbackOutput (r, NULL) ;
                            l -> xCurrNode =  Node_appendChild (DomTree_self (l -> xCurrDomTree),
								l -> xCurrNode, 
								l -> nCurrRepeatLevel, 
			                                            ntypCDATA,
                                                                    0,
                                                                    pData, len - 1, 0, 0, "XSLT Result") ;
                            }
                        else
                            l -> xCurrNode = Node_insertAfter (pDomTree, pDomTree -> xDocument, 0, DomTree_self (l -> xCurrDomTree), l -> xCurrNode, l -> nCurrRepeatLevel) ;
			}
		    }
#endif
		}
            else
		{
                oCommit (r, NULL) ;
#ifdef EP2
		if (!bError && !r -> bEP1Compat && !r -> pImportStash && !bXSLT)
		    {
		    tDomTree * pDomTree = DomTree_self (r -> xCurrDomTree) ;
		    Node_toString (r, pDomTree, pDomTree -> xDocument, 0) ;
		    oputs (r, "\r\n") ;
		    }
#endif
		}
	    }
        }
    else
        {
        oRollbackOutput (r, NULL) ;
        if (bOutToMem)
            sv_setsv (pOut, &sv_undef) ;
#ifdef EP2
	else if (!r -> bEP1Compat)
	    {
	    tDomTree * pDomTree = DomTree_self (r -> xCurrDomTree) ;
	    Node_toString (r, pDomTree, pDomTree -> xDocument, 0) ;
	    }
#endif
        }    

    if (!r -> bAppendToMainReq)
        CloseOutput (r) ;

    return ok ;
    }
    
/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Reset Request                                                                */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static int ResetRequest (/*i/o*/ register req * r,
			/*in*/ char *  sInputfile)

    {

    if (r -> bDebug)
        {
        clock_t cl = clock () ;
        time_t t ;
        struct tm * tm ;
        
        time (&t) ;        
        tm =localtime (&t) ;
        
        lprintf (r, "[%d]PERF: input = %s\n", r -> nPid, sInputfile) ;
#ifdef CLOCKS_PER_SEC
        lprintf (r, "[%d]PERF: Time: %d ms ", r -> nPid, ((cl - r -> startclock) * 1000 / CLOCKS_PER_SEC)) ;
#else
        lprintf (r, "[%d]PERF: ", r -> nPid) ;
#endif        
        lprintf (r, "Evals: %d ", r -> numEvals) ;
        if (r -> numEvals == 0)
            lprintf (r, "No Evals to cache") ;
        else
            lprintf (r, "Cache Hits: %d (%d%%)", r -> numCacheHits, r -> numCacheHits * 100 / r -> numEvals) ;

        lprintf (r, "\n") ;    
        lprintf (r, "[%d]%sRequest finished. %s. Entry-SVs: %d -OBJs: %d Exit-SVs: %d -OBJs: %d\n", r -> nPid,
	    (r -> bSubReq?"Sub-":""), asctime(tm), r -> stsv_count, r -> stsv_objcount, sv_count, sv_objcount) ;
        }

    r -> Buf.pCurrPos = NULL ;


    FlushLog (r) ;

    r -> Buf.nSourceline = 1 ;
    r -> Buf.pSourcelinePos = NULL ;    
    r -> Buf.pLineNoCurrPos = NULL ;    

    r -> bReqRunning = 0 ;

    av_clear (r -> pErrFill) ;
    av_clear (r -> pErrState) ;

#ifdef APACHE
    /* This must be the very very very last !!!!! */
    r -> pApacheReq = NULL ;
#endif
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
    int rc ;
    
    r -> Buf.pSourcelinePos = r -> Buf.pCurrPos = r -> Buf.pBuf ;
    r -> Buf.pEndPos  = r -> Buf.pBuf + nFileSize ;

#ifdef EP2
    if (!r -> bEP1Compat)
	{
	tConf * pConf = r -> pConf ;
	
	tProcessor p2 = {2, "Embperl", embperl_CompileProcessor, NULL, embperl_PreExecuteProcessor, embperl_ExecuteProcessor, "", 
	                   NULL, 0, 0, NULL,  NULL } ; 
	tProcessor p1 = {1, "Parser",  embperl_ParseProcessor,   NULL, NULL,                        NULL,                     "", NULL, 0, 0, NULL, NULL } ; 
	
	/* do this here to make stupid compiler happy (sun cc) */
	p2.pCacheKeyCV		= pConf -> pCacheKeyCV ;
	p2.bCacheKeyOptions	= pConf -> bCacheKeyOptions ;
	p2.nOutputExpiresIn	= pConf -> nExpiresIn ; 
	p2.pOutputExpiresCV	= pConf -> pExpiresCV ; 
	p1.pNext		= &p2 ;
	
	if (p2.pCacheKeyCV)
	    SvREFCNT_inc (p2.pCacheKeyCV) ;

	if (p2.pOutputExpiresCV)
	    SvREFCNT_inc (p2.pOutputExpiresCV) ;

	rc = embperl_CompileDocument (r, &p1) ;

	if (p2.pCacheKeyCV)
	    SvREFCNT_dec (p2.pCacheKeyCV) ;

	if (p2.pOutputExpiresCV)
	    SvREFCNT_dec (p2.pOutputExpiresCV) ;

	}
    else
        {
        clock_t cl1 = clock () ;
        clock_t cl2  ;

	rc = EvalMain (r) ; 
	
	cl2 = clock () ;
#ifdef CLOCKS_PER_SEC
        if (r -> bDebug)
	    {
	    lprintf (r, "[%d]PERF: Run Start Time: %d ms \n", r -> nPid, ((cl1 - r -> startclock) * 1000 / CLOCKS_PER_SEC)) ;
	    lprintf (r, "[%d]PERF: Run End Time:   %d ms \n", r -> nPid, ((cl2 - r -> startclock) * 1000 / CLOCKS_PER_SEC)) ;
	    lprintf (r, "[%d]PERF: Run Time:       %d ms \n", r -> nPid, ((cl2 - cl1) * 1000 / CLOCKS_PER_SEC)) ;
	    }
#endif    
        }
#else /* EP2 */
    rc = EvalMain (r) ; 
#endif /* EP2 */
    if ((r -> bOptions & optNoUncloseWarn) == 0)
	{
	if (!r -> bSubReq && r -> CmdStack.pStack)
	    {
	    if (r -> CmdStack.State.pCmd)
		strncpy (r -> errdat1, r -> CmdStack.State.pCmd -> sCmdName, sizeof (r -> errdat1) - 1) ;
	    LogError (r, rcUnclosedCmd) ;
	    }

	if (!r -> bSubReq && r -> HtmlStack.pStack)
	    {
	    if (r -> HtmlStack.State.pCmd)
		strncpy (r -> errdat1, r -> HtmlStack.State.pCmd -> sCmdName, sizeof (r -> errdat1) - 1) ;
	    LogError (r, rcUnclosedHtml) ;
	    }
	}

    return rc ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Process a block of the file  						*/
/*                                                                              */
/* ---------------------------------------------------------------------------- */

    

int ProcessBlock	(/*i/o*/ register req * r,
			 /*in*/  int	 nBlockStart,
			 /*in*/  int	 nBlockSize,
                         /*in*/  int     nBlockNo)

    {
    int     rc ;
    char *  p ;
    int     n ;


    r -> Buf.pCurrPos = r -> Buf.pBuf + nBlockStart ;
    r -> Buf.pEndPos  = r -> Buf.pCurrPos + nBlockSize ;
    r -> Buf.nBlockNo = nBlockNo ;


    if (r -> pTokenTable && strcmp ((char *)r -> pTokenTable, "Text") == 0)
	{ /* --- emulate Embperl 2  syntax => 'Text' --- */	    
	owrite (r, r -> Buf.pCurrPos, r -> Buf.pEndPos - r -> Buf.pCurrPos) ;
	return r -> Buf.nBlockNo ;
	}

    rc = ok ;
    p = r -> Buf.pCurrPos ;
    while (p && *p && p < r -> Buf.pEndPos && rc == ok)
        {
        if ((r -> bDebug & dbgMem) && (sv_count != r -> lstsv_count || sv_objcount != r -> lstsv_objcount))
            {
            lprintf (r, "[%d]SVs:  Entry-SVs: %d -OBJs: %d Curr-SVs: %d -OBJs: %d\n", r -> nPid, r -> stsv_count, r -> stsv_objcount, sv_count, sv_objcount) ;
            r -> lstsv_count = sv_count ;
            r -> lstsv_objcount = sv_objcount ;
            }
        
        /* */
        /* execute [x ... x] and special html tags and replace them if nessecary */
        /* */

        if (r -> CmdStack.State.bProcessCmds == cmdAll && !(r -> bOptions & optDisableHtmlScan))
            {
            n = strcspn (p, "[<") ;
            p += n ;
            }
        else
            p = strchr (p, '[') ;
            
            
        if (p == NULL)
            { /* output the rest of html */
            owrite (r, r -> Buf.pCurrPos, r -> Buf.pEndPos - r -> Buf.pCurrPos) ;
            break ;
            }
        
        if (r -> CmdStack.State.bProcessCmds == cmdAll)
            /* output until next cmd */
            owrite (r, r -> Buf.pCurrPos, p - r -> Buf.pCurrPos) ;
        
        if (*p == '\0')
            break ;

        if (r -> bDebug & dbgSource)
            {
            char * s = p ;
            char * n ;

            while (*s && isspace (*s))
                s++ ;
            
            if (*s)
                {
                GetLineNo (r) ;    
                n = strchr (s, '\n') ;
    
#ifdef CLOCKS_PER_SEC
                if (r -> bDebug & dbgProfile)
                    if (n)
                        lprintf (r, "[%d]SRC: Line %d: Time %d ms  %*.*s\n", r -> nPid, r -> Buf.nSourceline, ((clock () - r -> startclock) * 1000 / CLOCKS_PER_SEC), n-s, n-s, s) ;
                    else
                        lprintf (r, "[%d]SRC: Line %d: Time %d ms  %60.60s\n", r -> nPid, r -> Buf.nSourceline, ((clock () - r -> startclock) * 1000 / CLOCKS_PER_SEC), s) ;
                else
#endif
                    if (n)
                        lprintf (r, "[%d]SRC: Line %d: %*.*s\n", r -> nPid, r -> Buf.nSourceline, n-s, n-s, s) ;
                    else
                        lprintf (r, "[%d]SRC: Line %d: %60.60s\n", r -> nPid, r -> Buf.nSourceline, s) ;

                }
            }        

        
        r -> Buf.pCurrStart = p ;
        if (*p == '<')
            { /* HTML Tag */
            rc = ScanHtmlTag (r, p) ;
            }
         else
            { /* [x ... x] sequenz */
            if (p[1] == '*')
                break ;
            
            rc = ScanCmdEvals (r, p) ;
            }
        p = r -> Buf.pCurrPos ;
        }

    if (rc != ok)
        {
        if (rc != rcExit)
            LogError (r, rc) ;
        return 0 ;
        }
    
    return r -> Buf.nBlockNo ;
    }


	    
	    
	    
/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Read input file into memory  						*/
/*                                                                              */
/* ---------------------------------------------------------------------------- */

int ReadInputFile	(/*i/o*/ register req * r)

    {
    int	    rc = ok ;
    SV *    pBufSV = NULL ;
    req *   pMain = r ;

#ifdef EP2
    if (!r -> bEP1Compat)
    	{
    	SV * * ppSV ;
    	
    	ppSV = hv_fetch (r -> Buf.pFile -> pCacheHash, "P-1----", 7, 0) ;
    	if (ppSV && *ppSV)
    	    {
	    r -> Buf.pBuf		    = NULL ;
	    r -> Buf.pFile -> nFilesize     = 1 ;
	    return ok ;  /* source already parsed */
	    }
	}
#endif

    if ((pBufSV = r -> Buf.pFile -> pBufSV) == NULL || !SvPOK (pBufSV))
	{
	if (SvROK(r -> pInData))
	    { /* --- get input from memory --- */
	    STRLEN n ;
	    r -> Buf.pBuf = SvPV (pBufSV = SvRV(r -> pInData), n) ;
	    r -> Buf.pFile -> nFilesize = n ; 
	    }

	else
	    {
	    /* --- read input file --- */
    	    rc = ReadHTML (r, r -> Buf.pFile -> sSourcefile, &r -> Buf.pFile -> nFilesize, &pBufSV) ;
	    if (rc == ok)
		r -> Buf.pBuf = SvPVX (pBufSV) ;
	    }
	
	if (rc == ok)
	    {
	    SvREFCNT_inc (pBufSV) ;
	    r -> Buf.pFile -> pBufSV = pBufSV ;
	    r -> Buf.pEndPos  = r -> Buf.pBuf + r -> Buf.pFile -> nFilesize ;
	    
	    if (r -> Buf.pFile -> pNext2Free == NULL)
		{
		/* --- add to list for freeing --- */
	    
		while (pMain && pMain -> pLastReq != &InitialReq)
		    pMain = pMain -> pLastReq ;

		if ((r -> Buf.pFile -> pNext2Free = pMain -> pFiles2Free) == NULL)
		    r -> Buf.pFile -> pNext2Free  = r -> Buf.pFile ; /* last one points to itself !! */
		pMain -> pFiles2Free = r -> Buf.pFile ;
		}
	    
	    /* SetupDebugger (r) ; */
	    }
	}
    else
	{
	r -> Buf.pBuf		    = SvPVX (pBufSV) ;
	r -> Buf.pFile -> nFilesize = SvCUR (pBufSV) ;
	}

    return rc ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Process a block of the file  						*/
/*                                                                              */
/* ---------------------------------------------------------------------------- */

    

int ProcessSub		(/*i/o*/ register req * r,
			 /*in*/  tFile * pFile,
			 /*in*/  int	 nBlockStart,
                         /*in*/  int     nBlockNo)

    {
    int	    rc ;
    tSrcBuf Buf ;
    char *  sEvalPackage = r -> Buf.sEvalPackage ; 
    STRLEN  nEvalPackage = r -> Buf.nEvalPackage ;  
    SV *    pInData      = r -> pInData  ;  


    /*av_unshift (GvAV (PL_defgv), 1) ;
    av_store   (GvAV (PL_defgv), 0, r -> pReqSV) ; */
    
    memcpy (&Buf, &r -> Buf, sizeof (Buf)) ;

    
    if (pFile != r -> Buf.pFile)
	{ /* get other file */
	r -> Buf.pFile = pFile ;
	r -> pInData = &sv_undef ;

	if ((rc = ReadInputFile (r)) != ok)
	    {
	    LogError (r, rc) ;
	    return rc ;
	    }

	r -> Buf.pSourcelinePos =  r -> Buf.pBuf ;
	r -> Buf.nSourceline = r -> Buf.pFile -> nFirstLine ;
	r -> Buf.pLineNoCurrPos = NULL ;    
	r -> Buf.sEvalPackage   = r -> Buf.pFile -> sCurrPackage ; 
	r -> Buf.nEvalPackage   = r -> Buf.pFile -> nCurrPackage ; 
	}

    r -> nInsideSub++ ;
    rc = ProcessBlock (r, nBlockStart, r -> Buf.pFile -> nFilesize - nBlockStart, nBlockNo) ;
    r -> nInsideSub-- ;

    memcpy (&r -> Buf, &Buf, sizeof (Buf)) ;
    r -> Buf.sEvalPackage = sEvalPackage ; 
    r -> Buf.nEvalPackage = nEvalPackage ; 
    r -> pInData          = pInData ;  

    if (rc != ok)
	LogError (r, rc) ;

    return rc ;
    }


    
/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Request handler                                                              */
/*                                                                              */
/* ---------------------------------------------------------------------------- */



int ExecuteReq (/*i/o*/ register req * r,
                /*in*/  SV *           pReqSV) 

    {
    int     rc = ok ;
    char    olddir[PATH_MAX];
    char *  sInputfile = r -> Buf.pFile -> sSourcefile ;
#ifdef WIN32
    int		olddrive ;
#endif

    dTHR ;

    EPENTRY (ExecuteReq) ;

    
    /* r -> pReqSV = pReqSV ;  ep2?? */

    if (!r -> Buf.pFile -> pExportHash)
	r -> Buf.pFile -> pExportHash = newHV () ;
    
    ENTER;
    SAVETMPS ;
	
    SetupSafeNamespace (r) ;

    /* --- read form data from browser if not already read by perl part --- */
    if (rc == ok && !(r -> bOptions & optDisableFormData) && 
	            av_len (r -> pFormArray) == -1 && !r -> bSubReq && 
		    r -> pImportStash == NULL) 
        rc = GetInputData_CGIScript (r) ;
    
    /* --- open output and send http header if EarlyHttpHeaders --- */
    if (rc == ok)
        rc = StartOutput (r) ;

    /* --- read input file or get input file from memory --- */
#ifdef xxxEP2
    if (rc == ok && r -> bEP1Compat)
#else
    if (rc == ok)
#endif
	rc = ReadInputFile (r) ;

    if (rc == ok && r -> Buf.pBuf == NULL && r -> Buf.pFile -> nFilesize == 0)
        rc = rcMissingInput ;
    
    /* --- ok so far? if not exit ---- */
#ifdef APACHE
    if (rc != ok || (r -> pApacheReq && r -> pApacheReq -> header_only && (r -> bOptions & optEarlyHttpHeader)))
#else
    if (rc != ok)
#endif
        {
        if (rc != ok)
            LogError (r, rc);
#ifdef APACHE
        r -> pApacheReq = NULL ;
#endif
        r -> bReqRunning = 0 ;
        FREETMPS ;
        LEAVE;
        return rc ;
        }

    /* --- change working directory --- */
    
    if ((r -> bOptions & optDisableChdir) == 0 && sInputfile != NULL && sInputfile != '\0' && !SvROK(r -> pInData))
	{
	char dir[PATH_MAX];
#ifdef WIN32
	char drive[_MAX_DRIVE];
	char fname[_MAX_FNAME];
	char ext[_MAX_EXT];
	char * c = sInputfile ;
	char * p ;

	while (*c)
	    { /* convert / to \ */
 	    if (*c == '/')
		*c = '\\' ;
	    c++ ;
	    }

	olddrive = _getdrive () ;
	getcwd (olddir, sizeof (olddir) - 1) ;

	
	if (sInputfile[1] == ':')
	    {
	    drive[0] = toupper (sInputfile[0]) ;
	    c = sInputfile + 2 ;
	    }
	else
	    {
	    drive[0] = olddrive + 64 ;
	    c = sInputfile ;
	    }

	dir[0] = drive[0] ;
	dir[1] = ':' ;
	p = strrchr (sInputfile, '\\') ;
	if (p && p - c < PATH_MAX - 4)
	    {
	    memcpy (dir+2, c, p - c) ;
	    dir[2 + (p - c)] = '\0' ; 
	    }
	else
	    {
	    dir[2] = '.' ;
	    dir[3] = '\0' ;
	    }

	if (_chdrive (toupper(drive[0]) - 'A' + 1) < 0)
	   lprintf (r, "Cannot change to drive %c\n", drive[0] ) ;
	if (chdir (dir) < 0)
	   lprintf (r, "Cannot change directory to %s on drive %c for file %s\n", dir, drive[0], sInputfile ) ;
	/*
	if (r -> bDebug)
	    {
	    char    ndir[PATH_MAX];
	    int	    ndrive ;
	    
	    ndrive = _getdrive () ;
	    getcwd (ndir, sizeof (ndir) - 1) ;

	    lprintf (r, "Change directory to %s on drive %c (is %d:%s, was %d:%s)\n", dir, drive[0], ndrive, ndir, olddrive, olddir) ;
	    }
	*/
#else
        Dirname (sInputfile, dir, sizeof (dir) - 1) ;
	getcwd (olddir, sizeof (olddir) - 1) ;
	if (chdir (dir) < 0)
	   lprintf (r, "Cannot change directory to %s\n", dir ) ;
#endif
	}
    else
	r -> bOptions |= optDisableChdir ;

    r -> bReqRunning     = 1 ;

    if ((rc = ProcessFile (r, r -> Buf.pFile -> nFilesize)) != ok)
        if (rc == rcExit)
            rc = ok ;
        else
            LogError (r, rc) ;


    /* --- Restore Operatormask and Package, destroy temp perl sv's --- */
    FREETMPS ;
    LEAVE;
    r -> bReqRunning = 0 ;

    /* --- send http header and data to the browser if not already done --- */
    if ((rc = EndOutput (r, rc, r -> pOutData)) != ok)
        LogError (r, rc) ;

    /* --- restore working directory --- */
    if ((r -> bOptions & optDisableChdir) == 0)
	{
#ifdef WIN32
   	_chdrive (olddrive) ;
#endif
	chdir (olddir) ;
	}

    /* --- reset variables and log end of request --- */
    if ((rc = ResetRequest (r, sInputfile)) != ok)
        LogError (r, rc) ;

    return ok ;
    }
