


MODULE = Embperl      PACKAGE = Embperl     PREFIX = embperl_

PROTOTYPES: ENABLE



# /* ---- Helper ----- */


#if defined (__GNUC__) && defined (__i386__)

void
embperl_dbgbreak()
CODE:
    __asm__ ("int   $0x03\n") ;

#endif



double
Clock()
CODE:
#ifdef CLOCKS_PER_SEC
        RETVAL = clock () * 1000 / CLOCKS_PER_SEC / 1000.0 ;
#else
        RETVAL = clock () ;
#endif        
OUTPUT:
    RETVAL



void
embperl_logerror(code, sText, pApacheReqSV=NULL)
    int    code
    char * sText
    SV * pApacheReqSV
PREINIT:
    tReq * r = CurrReq ;
    int  bRestore = 0 ;
#ifdef APACHE
    SV * pSaveApacheReqSV = NULL ;
    request_rec * pSaveApacheReq = NULL ;
#endif
CODE:
#ifdef APACHE
    if (pApacheReqSV && r -> pApacheReq == NULL)
        {
        bRestore = 1 ;
        pSaveApacheReqSV = r -> pApacheReqSV ;
        pSaveApacheReq = r -> pApacheReq ;
        if (SvROK (pApacheReqSV))
            r -> pApacheReq = (request_rec *)SvIV((SV*)SvRV(pApacheReqSV));
        else
            r -> pApacheReq = NULL ;
        r -> pApacheReqSV = pApacheReqSV ;
        }
#endif
    if (r)
         {
         strncpy (r->errdat1, sText, sizeof (r->errdat1) - 1) ;
         LogError (r,code) ;
         }
    else
        LogErrorParam(NULL, code, sText, NULL) ;
#ifdef APACHE
    if (bRestore)
        {
        r -> pApacheReqSV  = pSaveApacheReqSV  ;
        r -> pApacheReq = pSaveApacheReq   ;
        }
#endif



void
embperl_log(sText)
    char * sText
INIT:
    tReq * r = CurrReq ;
CODE:
    if (r)
        lwrite (r->pApp,sText, strlen (sText)) ;
    else
        PerlIO_puts(PerlIO_stderr(), sText) ;


void
embperl_output(sText)
    SV * sText
INIT:
    STRLEN l ;
    tReq * r = CurrReq ;
CODE:
	{
        char * p = SvPV (sText, l) ;
        r -> Component.bSubNotEmpty = 1 ;
        r -> Component.xCurrNode = Node_insertAfter_CDATA (r->pApp, p, l, (SvUTF8(sText)?nflgEscUTF8:0) + ((r -> Component.nCurrEscMode & 3)== 3?1 + (r -> Component.nCurrEscMode & 4):r -> Component.nCurrEscMode), DomTree_self (r -> Component.xCurrDomTree), r -> Component.xCurrNode, r -> Component.nCurrRepeatLevel) ; 
        r -> Component.bEscModeSet = 0 ;
        }


int
embperl_getlineno()
INIT:
    tReq * r = CurrReq ;
CODE:
    RETVAL = GetLineNo (r) ;
OUTPUT:
    RETVAL


void
embperl_flushlog()
CODE:
    FlushLog (CurrApp) ;


char *
embperl_Sourcefile()
INIT:
    tReq * r = CurrReq ;
CODE:
    RETVAL = r?r -> Component.sSourcefile:"" ;
OUTPUT:
    RETVAL




void
embperl_exit(...)
CODE:
    /* from mod_perl's perl_util.c */
    /* does not work with Perl >= 5.18
    struct ufuncs umg;

    umg.uf_val = errgv_empty_set;
    umg.uf_set = errgv_empty_set;
    umg.uf_index = (IV)0;

    sv_magic(ERRSV, Nullsv, 'U', (char*) &umg, sizeof(umg));
    */

    ENTER;
    SAVESPTR(diehook);
    diehook = Nullsv; 
    if (items > 0)
        croak(">embperl_exit< request %d", SvIV(ST(0)));
    else
        croak(">embperl_exit< component");
    LEAVE; /* we don't get this far, but croak() will rewind */

    /* sv_unmagic(ERRSV, 'U'); */



void 
embperl_ClearSymtab(sPackage,bDebug)
    char * sPackage
    int	    bDebug
CODE:
    ClearSymtab (CurrReq, sPackage, bDebug) ;


################################################################################

MODULE = Embperl      PACKAGE = Embperl::Req     PREFIX = embperl_


void
embperl_logerror(r,code, sText,pApacheReqSV=NULL)
    tReq * r
    int    code
    char * sText
    SV * pApacheReqSV
PREINIT:
    int  bRestore = 0 ;
#ifdef APACHE
    SV * pSaveApacheReqSV = NULL ;
    request_rec * pSaveApacheReq = NULL ;
#endif
CODE:
#ifdef APACHE
    if (pApacheReqSV && r -> pApacheReq == NULL)
        {
        bRestore = 1 ;
        pSaveApacheReqSV = r -> pApacheReqSV ;
        pSaveApacheReq = r -> pApacheReq ;
        if (SvROK (pApacheReqSV))
            r -> pApacheReq = (request_rec *)SvIV((SV*)SvRV(pApacheReqSV));
        else
            r -> pApacheReq = NULL ;
        r -> pApacheReqSV = pApacheReqSV ;
        }
#endif
    if (r)
         {
         strncpy (r->errdat1, sText, sizeof (r->errdat1) - 1) ;
         LogError (r,code) ;
         }
    else
        LogErrorParam(NULL, code, sText, NULL) ;
#ifdef APACHE
    if (bRestore)
        {
        r -> pApacheReqSV  = pSaveApacheReqSV  ;
        r -> pApacheReq = pSaveApacheReq   ;
        }
#endif


void
embperl_output(r,sText)
    tReq * r
    char * sText
CODE:
    r -> Component.bSubNotEmpty = 1 ;
    OutputToHtml (r,sText) ;


void
embperl_log(r,sText)
    tReq * r
    char * sText
CODE:
    lwrite (r->pApp, sText, strlen (sText)) ;

void
embperl_flushlog(r)
    tReq * r
CODE:
    FlushLog (r->pApp) ;



int
embperl_getlineno(r)
    tReq * r
CODE:
    RETVAL = GetLineNo (r) ;
OUTPUT:
    RETVAL


void
log_svs(r,sText)
    tReq * r
    char * sText
CODE:
    lprintf (r->pApp,"[%d]MEM:  %s: SVs: %d\n", r->pThread->nPid, sText, sv_count) ;

SV *
embperl_Escape(r, str, mode)
    tReq * r
    char *   str = NO_INIT 
    int      mode
PREINIT:
    STRLEN len ;
CODE:
    str = SvPV(ST(1),len) ;
    RETVAL = Escape(r, str, len, mode, NULL, 0) ;
OUTPUT:
    RETVAL

 



INCLUDE: Cmd.xs

INCLUDE: DOM.xs

INCLUDE: Syntax.xs



# Reset Module, so we get the correct boot function

MODULE = Embperl      PACKAGE = Embperl     PREFIX = embperl_





