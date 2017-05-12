/*###################################################################################
#
#   Embperl - Copyright (c) 1997-1999 Gerald Richter / ECOS
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#   For use with Apache httpd and mod_perl, see also Apache copyright.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
###################################################################################*/

#define ADDINTMG(name)    \
    if (rc == 0)    \
        rc = AddMagic (r, s##name##Name, &EMBPERL_mvtTab##name) ;

#define OPTPREFIX "HTML::Embperl::"

#define ADDOPTMG(name)    \
    if (rc == 0)    \
        rc = AddMagic (r, OPTPREFIX#name, &EMBPERL_mvtTab##name) ;


#define INTMG(name,var,used,sub) \
    \
int EMBPERL_mgGet##name (pTHX_ SV * pSV, MAGIC * mg) \
\
    { \
\
    sv_setiv (pSV, var) ; \
    if (pCurrReq -> bReqRunning) \
	used++ ; \
    if ((pCurrReq -> bDebug & dbgTab) && pCurrReq -> bReqRunning) \
        lprintf (pCurrReq, "[%d]TAB:  get %s = %d, Used = %d\n", pCurrReq -> nPid, #name, var, used) ; \
    return 0 ; \
    } \
\
    int EMBPERL_mgSet##name (pTHX_ SV * pSV, MAGIC * mg) \
\
    { \
\
    var = SvIV (pSV) ; \
    if ((pCurrReq -> bDebug & dbgTab) && pCurrReq -> bReqRunning) \
        lprintf (pCurrReq, "[%d]TAB:  set %s = %d, Used = %d\n", pCurrReq -> nPid, #name, var, used) ; \
    sub ; \
    return 0 ; \
    } \
    \
    MGVTBL EMBPERL_mvtTab##name = { EMBPERL_mgGet##name, EMBPERL_mgSet##name, NULL, NULL, NULL } ;

#define INTMGshort(name,var) \
    \
int EMBPERL_mgGet##name (pTHX_ SV * pSV, MAGIC * mg) \
\
    { \
    sv_setiv (pSV, var) ; \
    return 0 ; \
    } \
\
    int EMBPERL_mgSet##name (pTHX_ SV * pSV, MAGIC * mg) \
\
    { \
    var = SvIV (pSV) ; \
    return 0 ; \
    } \
    \
    MGVTBL EMBPERL_mvtTab##name = { EMBPERL_mgGet##name, EMBPERL_mgSet##name, NULL, NULL, NULL } ;



#define INTMGcall(name,var,sub) \
    \
void EMBPERL_mgGet##name (pTHX_ SV * pSV, MAGIC * mg) \
\
    { \
    sv_setiv (pSV, var) ; \
    sub ; \
    } \
\
    void EMBPERL_mgSet##name (pTHX_ SV * pSV, MAGIC * mg) \
\
    { \
    var = SvIV (pSV) ; \
    sub ; \
    } \
    \
    MGVTBL EMBPERL_mvtTab##name = { EMBPERL_mgGet##name, EMBPERL_mgSet##name, NULL, NULL, NULL } ;


#define OPTMGRD(name,var) \
    \
int EMBPERL_mgGet##name (pTHX_ SV * pSV, MAGIC * mg) \
\
    { \
\
    sv_setiv (pSV, (var & name)?1:0) ; \
    return 0 ; \
    } \
\
int EMBPERL_mgSet##name (pTHX_ SV * pSV, MAGIC * mg) \
\
    { \
    return 0 ; \
    } \
    \
    MGVTBL EMBPERL_mvtTab##name = { EMBPERL_mgGet##name, EMBPERL_mgSet##name, NULL, NULL, NULL } ;


#define OPTMG(name,var) \
    \
int EMBPERL_mgGet##name (pTHX_ SV * pSV, MAGIC * mg) \
\
    { \
\
    sv_setiv (pSV, (var & name)?1:0) ; \
    return 0 ; \
    } \
\
int EMBPERL_mgSet##name (pTHX_ SV * pSV, MAGIC * mg) \
\
    { \
\
    if (SvIV (pSV)) \
        var |= name ; \
    else \
        var &= ~name ; \
    return 0 ; \
    } \
    \
    MGVTBL EMBPERL_mvtTab##name = { EMBPERL_mgGet##name, EMBPERL_mgSet##name, NULL, NULL, NULL } ;




#ifdef EPDEBUGALL
#define EPENTRY(func) if (r -> bDebug & dbgFunc) { lprintf (r, "[%d]DBG:  %dms %s\n", r -> nPid, clock () * 1000 / CLOCKS_PER_SEC, #func) ; FlushLog (r) ; }
#define EPENTRY1N(func,arg1) if (r -> bDebug & dbgFunc) { lprintf (r, "[%d]DBG:  %dms %s %d\n", r -> nPid, clock () * 1000 / CLOCKS_PER_SEC, #func, arg1) ; FlushLog (r) ; }
#define EPENTRY1S(func,arg1) if (r -> bDebug & dbgFunc) { lprintf (r, "[%d]DBG:  %dms %s %s\n", r -> nPid, clock () * 1000 / CLOCKS_PER_SEC, #func, arg1) ; FlushLog (r) ; }
#else
#define EPENTRY(func)
#define EPENTRY1N(func,arg1)
#define EPENTRY1S(func,arg1)
#endif



#define AssignSVPtr(ppDst,pSrc) { if (*ppDst) SvREFCNT_dec (*ppDst) ; *ppDst = pSrc ; }

