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
#   $Id: epcmd.c 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################*/


#include "ep.h"
#include "epmacro.h"



/* ---------------------------------------------------------------------------- */
/* Commandtable...                                                              */
/* ---------------------------------------------------------------------------- */


static int CmdIf (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int CmdElse (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int CmdElsif (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int CmdEndif (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;

static int CmdWhile (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int CmdEndwhile (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int CmdDo (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int CmdUntil (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int CmdForeach (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int CmdEndforeach (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;

static int CmdHidden (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int CmdVar (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int CmdSub (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int CmdEndsub (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;

static int HtmlTable (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int HtmlTableHead (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int HtmlSelect (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int HtmlEndselect (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int HtmlOption (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int HtmlEndtable (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int HtmlRow (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int HtmlEndrow (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int HtmlInput (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int HtmlTextarea (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int HtmlEndtextarea (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int HtmlBody (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int HtmlA (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int HtmlIMG (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int HtmlASRC (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int HtmlForm (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int HtmlEndform (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;
static int HtmlMeta (/*i/o*/ register req * r,
			/*in*/ const char *   sArg) ;

    

struct tCmd CmdTab [] =
    {
        /* cmdname    function        push pop  type         scan save no          disable            bHtml  */
        { "/dir",     HtmlEndtable,     0, 1, cmdTable,         0, 0, cnDir    , optDisableTableScan, 1 } ,
        { "/dl",      HtmlEndtable,     0, 1, cmdTable,         0, 0, cnDl     , optDisableTableScan, 1 } ,
        { "/form",    HtmlEndform,      0, 0, cmdNorm,          0, 0, cnNop    , 0                  , 1 } ,
        { "/menu",    HtmlEndtable,     0, 1, cmdTable,         0, 0, cnMenu   , optDisableTableScan, 1 } ,
        { "/ol",      HtmlEndtable,     0, 1, cmdTable,         0, 0, cnOl     , optDisableTableScan, 1 } ,
        { "/select",  HtmlEndselect,    0, 1, cmdTable,         0, 0, cnSelect , optDisableSelectScan, 1 } ,
        { "/table",   HtmlEndtable,     0, 1, cmdTable,         0, 0, cnTable  , optDisableTableScan, 1 } ,
        { "/textarea", HtmlEndtextarea, 0, 1, cmdTextarea,      0, 0, cnNop    , optDisableInputScan, 1 } ,
        { "/tr",      HtmlEndrow,       0, 1, cmdTablerow,      0, 0, cnTr     , optDisableTableScan, 1 } ,
        { "/ul",      HtmlEndtable,     0, 1, cmdTable,         0, 0, cnUl     , optDisableTableScan, 1 } ,
        { "a",        HtmlA,            0, 0, cmdNorm,          0, 0, cnNop    , 0                  , 1 } ,
        { "body",     HtmlBody,         0, 0, cmdNorm,          1, 0, cnNop    , 0                  , 1 } ,
        { "dir",      HtmlTable,        1, 0, cmdTable,         1, 0, cnDir    , optDisableTableScan, 1 } ,
        { "dl",       HtmlTable,        1, 0, cmdTable,         1, 0, cnDl     , optDisableTableScan, 1 } ,
        { "do",       CmdDo,            1, 0, cmdDo,            0, 0, cnNop    , 0                  , 0 } ,
        { "else",     CmdElse,          0, 0, cmdIf,            0, 0, cnNop    , 0                  , 0 } ,
        { "elsif",    CmdElsif,         0, 0, cmdIf,            0, 0, cnNop    , 0                  , 0 } ,
        { "embed",    HtmlASRC,          0, 0, cmdNorm,          0, 0, cnNop    , 0                  , 1 } ,
        { "endforeach", CmdEndforeach,  0, 1, cmdForeach,       0, 0, cnNop    , 0                  , 0 } ,
        { "endif",    CmdEndif,         0, 1, (enum tCmdType)(cmdIf | cmdEndif), 0, 0, cnNop    , 0,  0 } ,
        { "endsub",   CmdEndsub,        0, 1, cmdSub,           0, 0, cnNop    , 0                  , 0 } ,
        { "endwhile", CmdEndwhile,      0, 1, cmdWhile,         0, 0, cnNop    , 0                  , 0 } ,
        { "foreach",  CmdForeach,       1, 0, cmdForeach,       0, 1, cnNop    , 0                  , 0 } ,
        { "form",     HtmlForm,         0, 0, cmdNorm,          0, 0, cnNop    , 0                  , 1 } ,
        { "frame",    HtmlASRC,          0, 0, cmdNorm,          0, 0, cnNop    , 0                  , 1 } ,
        { "hidden",   CmdHidden,        0, 0, cmdNorm,          0, 0, cnNop    , 0                  , 0 } ,
        { "if",       CmdIf,            1, 0, (enum tCmdType)(cmdIf | cmdEndif), 0, 0, cnNop    , 0,  0 } ,
        { "iframe",   HtmlASRC,          0, 0, cmdNorm,          0, 0, cnNop    , 0                  , 1 } ,
        { "img",      HtmlIMG,          0, 0, cmdNorm,          0, 0, cnNop    , 0                  , 1 } ,
        { "input",    HtmlInput,        0, 0, cmdNorm,          1, 0, cnNop    , optDisableInputScan, 1 } ,
        { "layer",    HtmlASRC,          0, 0, cmdNorm,          0, 0, cnNop    , 0                  , 1 } ,
        { "menu",     HtmlTable,        1, 0, cmdTable,         1, 0, cnMenu   , optDisableTableScan, 1 } ,
        { "meta",     HtmlMeta,         0, 0, cmdNorm,          1, 0, cnNop    , optDisableMetaScan , 1 } ,
        { "ol",       HtmlTable,        1, 0, cmdTable,         1, 0, cnOl     , optDisableTableScan, 1 } ,
        { "option",   HtmlOption,       0, 0, cmdNorm,          1, 0, cnNop    , optDisableInputScan, 1 } ,
        { "select",   HtmlSelect,       1, 0, cmdTable,         1, 0, cnSelect , optDisableSelectScan, 1 } ,
        { "sub",      CmdSub,           1, 0, cmdSub,           0, 0, cnNop    , 0                  , 0 } ,
        { "table",    HtmlTable,        1, 0, cmdTable,         1, 0, cnTable  , optDisableTableScan, 1 } ,
        { "textarea", HtmlTextarea,     1, 0, cmdTextarea,      1, 1, cnNop    , optDisableInputScan, 1 } ,
        { "th",       HtmlTableHead,    0, 0, cmdNorm,          1, 0, cnNop    , optDisableTableScan, 1 } ,
        { "tr",       HtmlRow,          1, 0, cmdTablerow,      1, 0, cnTr     , optDisableTableScan, 1 } ,
        { "ul",       HtmlTable,        1, 0, cmdTable,         1, 0, cnUl     , optDisableTableScan, 1 } ,
        { "until",    CmdUntil,         0, 1, cmdDo,            0, 0, cnNop    , 0                  , 0 } ,
        { "var",      CmdVar,           0, 0, cmdNorm,          0, 0, cnNop    , 0                  , 0 } ,
        { "while",    CmdWhile,         1, 0, cmdWhile,         0, 1, cnNop    , 0                  , 0 } ,
    
    } ;



/* */
/* compare commands */
/* */

static int CmpCmd (/*in*/ const void *  p1,
                   /*in*/ const void *  p2)

    {
    return strcmp (*((const char * *)p1), *((const char * *)p2)) ;
    }



/* */
/* Search Command in Commandtable */
/* */

int SearchCmd (/*i/o*/ register req * r,
			/*in*/  const char *    sCmdName,
                         /*in*/  int             nCmdLen,
                         /*in*/  const char *    sArg,
                         /*in*/  int             bIgnore,
                         /*out*/ struct tCmd * * ppCmd)

    {
    struct tCmd *  pCmd ;
    char           sCmdLwr [64] ;
    char *         p ;
    int            i ;


    EPENTRY (SearchCmd) ;

    i = sizeof (sCmdLwr) - 1 ;
    p = sCmdLwr ;
    while (nCmdLen-- > 0 && --i > 0)
        if ((*p++ = tolower (*sCmdName++)) == '\0')
            break ;

    *p = '\0' ;
    
    p = sCmdLwr ;
    pCmd = (struct tCmd *)bsearch (&p, CmdTab, sizeof (CmdTab) / sizeof (struct tCmd), sizeof (struct tCmd), CmpCmd) ;
    if (pCmd && (pCmd -> bDisableOption & r -> Component.Config.bOptions))
        pCmd = NULL ; /* command is disabled */

    if (pCmd && ((pCmd -> bHtml == 0) ^ (bIgnore == 0)))
        pCmd = NULL ; /* command is not of right type (html <-> meta cmd) */

	
    if (r -> Component.Config.bDebug & dbgAllCmds)
        if (sArg && *sArg != '\0')
            lprintf (r -> pApp,  "[%d]CMD%c:  Cmd = '%s' Arg = '%s'\n", r -> pThread -> nPid, (pCmd == NULL)?'-':'+', sCmdLwr, sArg) ;
        else
            lprintf (r -> pApp,  "[%d]CMD%c:  Cmd = '%s'\n", r -> pThread -> nPid, (pCmd == NULL)?'-':'+', sCmdLwr) ;

    if (pCmd == NULL && bIgnore)
        return rcCmdNotFound ;

    if ((r -> Component.Config.bDebug & dbgCmd) && (r -> Component.Config.bDebug & dbgAllCmds) == 0)
        if (sArg && *sArg != '\0')
            lprintf (r -> pApp,  "[%d]CMD:  Cmd = '%s' Arg = '%s'\n", r -> pThread -> nPid, sCmdLwr, sArg) ;
        else
            lprintf (r -> pApp,  "[%d]CMD:  Cmd = '%s'\n", r -> pThread -> nPid, sCmdLwr) ;
    
    if (pCmd == NULL)
        {
        strncpy (r -> errdat1, sCmdLwr, sizeof (r -> errdat1) - 1) ;
        return rcCmdNotFound ;
        }

    
    *ppCmd = pCmd ;
    
    return ok ;
    }



/* */
/* Process a Command */
/* */



static int ProcessAllCmds (/*i/o*/ register req *   r,
			   /*in*/  struct tCmd *    pCmd,
                           /*in*/  const char *     sArg,
                           /*in*/  tStackPointer    *pSP)

    {                        
    int                     rc ;
    struct tStackEntry *    pStack ;
    struct tStackEntry *    pState = &pSP -> State ;

    EPENTRY (ProcessAllCmds) ;
    
    if (pCmd -> bPush)
        {
        if (pSP -> pStackFree)
            {
            pStack = pSP -> pStackFree ;
            pSP -> pStackFree = pSP -> pStackFree -> pNext ;
            }
        else
            {
            pStack = _malloc (r, sizeof (struct tStackEntry)) ;
            }
        memcpy (pStack, pState, sizeof (*pStack)) ;
        
        pStack -> pNext = pSP -> pStack ;
        pSP -> pStack   = pStack ;
        
        pState -> nCmdType  = pCmd -> nCmdType ;
        pState -> pStart    = r -> Component.pCurrPos ;
        pState -> nBlockNo  = r -> Buf.nBlockNo ;
        if (pCmd -> bSaveArg)
            pState -> sArg      = _ep_strdup (r, sArg) ;
        else
            pState -> sArg = NULL ;
        
        pState -> pSV       = NULL ;
        pState -> pSV2      = NULL ;
        pState -> pBuf      = NULL ;
        pState -> pNext     = NULL ;
        pState -> pCmd      = pCmd ;
        }

    r -> pCurrCmd = pCmd ;

    rc = (*pCmd -> pProc)(r, sArg) ;
    if (rc == rcEvalErr)
        rc = ok ;

    if (pCmd -> bPop && pState -> pStart == NULL && rc != rcExit)
        {
        pStack = pSP -> pStack ; 

        if (pStack == NULL)
            return rcStackUnderflow ;
        else
            {
            if (pState -> sArg)
                _free (r, pState -> sArg) ;
            if (pState -> pSV)
                SvREFCNT_dec (pState -> pSV) ;
            if (pState -> pSV2)
                SvREFCNT_dec (pState -> pSV2) ;

            memcpy (pState, pStack, sizeof (*pState)) ;
            
            pSP -> pStack = pStack -> pNext ;
            pStack -> pNext = pSP -> pStackFree ;
            pSP -> pStackFree = pStack ;
            }
        }
    
    return rc ;
    }




int ProcessCmd (/*i/o*/ register req *  r,
		/*in*/ struct tCmd *    pCmd,
                /*in*/ const char *     sArg)

    {                        
    EPENTRY (ProcessCmd) ;
    
    
    if ((pCmd -> nCmdType & r -> CmdStack.State.bProcessCmds) == 0)
        return ok ; /* ignore it */

    if (pCmd -> bHtml)
        return ProcessAllCmds (r, pCmd, sArg, &r -> HtmlStack) ;

    return ProcessAllCmds (r, pCmd, sArg, &r -> CmdStack) ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* if command ...                                                               */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

static int CmdIf (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)
    {
    int rc = ok ;

    EPENTRY (CmdIf) ;
    
    if (r -> CmdStack.State.bProcessCmds == cmdAll)
        {
        rc = EvalBool (r, (char *)sArg, (sArg - r -> Component.pBuf), &r -> CmdStack.State.nResult) ;
    
        if (r -> CmdStack.State.nResult && rc == ok) 
            {
            r -> CmdStack.State.bProcessCmds = cmdAll ;
            }
        else
            {
            r -> CmdStack.State.bProcessCmds = cmdIf ;
            }
        }
    else
        r -> CmdStack.State.nResult = -1 ;

    return rc ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* elsif command ...                                                            */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

static int CmdElsif (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)
    {
    int rc = ok ;


    EPENTRY (CmdElsif) ;
    
    if ((r -> CmdStack.State.nCmdType & cmdIf) == 0)
        return rcElseWithoutIf ;
    
        
    if (r -> CmdStack.State.nResult == -1)
        return ok ;

    if (r -> CmdStack.State.nResult == 0)
        {    
        rc = EvalBool (r, (char *)sArg, (sArg - r -> Component.pBuf), &r -> CmdStack.State.nResult) ;
    
        if (r -> CmdStack.State.nResult && rc == ok) 
            r -> CmdStack.State.bProcessCmds = cmdAll ;
        else
            r -> CmdStack.State.bProcessCmds = cmdIf ;
        }
    else
        {
        r -> CmdStack.State.bProcessCmds = cmdEndif ;
        r -> CmdStack.State.nResult      = 0 ;
        }

    return rc ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* else command ...                                                             */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

static int CmdElse (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)
    {

    EPENTRY (CmdElse) ;
    
    
    if ((r -> CmdStack.State.nCmdType & cmdIf) == 0)
        return rcElseWithoutIf ;

    if (r -> CmdStack.State.nResult == -1)
        return ok ;


    
    if (r -> CmdStack.State.nResult)
        {
        r -> CmdStack.State.bProcessCmds = cmdIf ;
        r -> CmdStack.State.nResult      = 0 ;
        }
    else
        {
        r -> CmdStack.State.bProcessCmds = cmdAll ;
        r -> CmdStack.State.nResult      = 1 ;
        }

    return ok ;
    }
                        

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* endif command ...                                                            */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

static int CmdEndif (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)
    {
    EPENTRY (CmdEndif) ;

    
    
    r -> CmdStack.State.pStart    = NULL ;

    if ((r -> CmdStack.State.nCmdType & cmdIf) == 0)
        return rcEndifWithoutIf ;

    return ok ;
    }
                        


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* while command ...                                                            */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

static int CmdWhile (/*i/o*/ register req * r,
 		     /*in*/ const char *   sArg)
    {
    int rc ;
    
    EPENTRY (CmdWhile) ;

    if (r -> CmdStack.State.bProcessCmds == cmdWhile)
        return ok ;

    rc = EvalBool (r, (char *)sArg, (r -> CmdStack.State.pStart - r -> Component.pBuf), &r -> CmdStack.State.nResult) ;
    
    if (r -> CmdStack.State.nResult && rc == ok) 
        r -> CmdStack.State.bProcessCmds = cmdAll ;
    else
        r -> CmdStack.State.bProcessCmds = cmdWhile ;

    return rc ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* endwhile command ...                                                         */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

static int CmdEndwhile (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)
    {
    int rc = ok ;

    EPENTRY (CmdEndwhile) ;


    if (r -> CmdStack.State.nCmdType != cmdWhile)
        return rcEndwhileWithoutWhile ;

    
    if (r -> CmdStack.State.nResult)
        {
        rc = EvalBool (r, r -> CmdStack.State.sArg, (r -> CmdStack.State.pStart - r -> Component.pBuf), &r -> CmdStack.State.nResult) ;
    
        if (r -> CmdStack.State.nResult && rc == ok) 
            {
            r -> Component.pCurrPos = r -> CmdStack.State.pStart ;        
            r -> Buf.nBlockNo = r -> CmdStack.State.nBlockNo ;        
            return rc ;
            }
        }

    r -> CmdStack.State.pStart    = NULL ;

    return rc ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* do command ...                                                            */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

static int CmdDo       (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)
    {
    EPENTRY (CmdDo) ;

    return ok ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* until command ...                                                            */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

static int CmdUntil (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)
    {
    int rc = ok ;

    EPENTRY (CmdUntil) ;


    if (r -> CmdStack.State.nCmdType != cmdDo)
        return rcUntilWithoutDo ;

    
    rc = EvalBool (r, (char *)sArg, (r -> CmdStack.State.pStart - r -> Component.pBuf), &r -> CmdStack.State.nResult) ;

    if (!r -> CmdStack.State.nResult && rc == ok && !r -> Component.pImportStash)
        {
        r -> Component.pCurrPos = r -> CmdStack.State.pStart ;        
        r -> Buf.nBlockNo = r -> CmdStack.State.nBlockNo ;        
        return rc ;
        }

    r -> CmdStack.State.pStart    = NULL ;

    return rc ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* foreach command ...                                                          */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

static int CmdForeach (/*i/o*/ register req * r,
		       /*in*/ const char *   sArg)
    {
    int rc ;
    char *  sArgs ;
    char *  sVarName ;
    char    sVar[512] ;
    SV * *  ppSV ;
    SV *    pRV ;
    int     nMax ;
    int	    n ;
    int	    c ;

    EPENTRY (CmdForeach) ;

    if (r -> CmdStack.State.bProcessCmds == cmdForeach)
        return ok ;

    sArgs = r -> CmdStack.State.sArg ;
    while (isspace (*sArgs))
	sArgs++ ;
    if (*sArgs != '\0')
        {            
        
	n = strcspn (sArgs, ", \t\n(") ;
        sVarName = sArgs + n ;
	if (*sVarName != '\0')
            {
            if (*sArgs == '$')
                sArgs++ ;
        
	    c = *sVarName ;
	    *sVarName = '\0' ;

            if (!strstr (sArgs, "::"))
                {            
                strncpy (sVar, r -> Component.sEvalPackage, sizeof (sVar) - 5) ;
                sVar[r -> Component.nEvalPackage] = ':' ;
                sVar[r -> Component.nEvalPackage+1] = ':' ;
                sVar[sizeof(sVar) - 1] = '\0' ;
                nMax = sizeof(sVar) - r -> Component.nEvalPackage - 3 ;
                strncpy (sVar + r -> Component.nEvalPackage + 2, sArgs, nMax) ;
                if ((r -> CmdStack.State.pSV = perl_get_sv (sVar, TRUE)) == NULL)
                    return rcPerlVarError ;
                }
            else
                if ((r -> CmdStack.State.pSV = perl_get_sv (sArgs, TRUE)) == NULL)
                    return rcPerlVarError ;
 
	    *sVarName = c ;
            
            SvREFCNT_inc (r -> CmdStack.State.pSV) ;

            if (*sVarName != '(')
		sVarName++ ;
	    
                
	    if ((rc = EvalTransFlags (r, sVarName, (r -> CmdStack.State.pStart - r -> Component.pBuf), G_ARRAY, &pRV)) != ok)
                return rc ;

	    if (r -> Component.pImportStash)
		return ok ;
          
	    if (pRV == NULL)
                return rcMissingArgs ;

            if (!SvROK (pRV))
                {
                SvREFCNT_dec (pRV) ;
                return rcNotAnArray ;
                }

            r -> CmdStack.State.pSV2 = SvRV (pRV) ;
            SvREFCNT_inc (r -> CmdStack.State.pSV2) ;
            SvREFCNT_dec (pRV) ;

            if (SvTYPE (r -> CmdStack.State.pSV2) != SVt_PVAV)
                return rcNotAnArray ;
            }
        }

    
    if (r -> CmdStack.State.pSV == NULL || r -> CmdStack.State.pSV2 == NULL)
        return rcMissingArgs ;


    r -> CmdStack.State.nResult = 0 ; /* array index */

    ppSV = av_fetch ((AV *)r -> CmdStack.State.pSV2, r -> CmdStack.State.nResult, 0) ;

    if (ppSV != NULL && *ppSV != NULL)
        {
        r -> CmdStack.State.bProcessCmds = cmdAll ;
        sv_setsv (r -> CmdStack.State.pSV, *ppSV) ;
        r -> CmdStack.State.nResult++ ;
        }
    else
        r -> CmdStack.State.bProcessCmds = cmdForeach ;

    return ok ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* endforeach command ...                                                       */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

static int CmdEndforeach (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)
    {
    SV ** ppSV ;        

    EPENTRY (CmdEndforeach) ;


    if (r -> CmdStack.State.nCmdType != cmdForeach)
        return rcEndforeachWithoutForeach ;

    if (r -> CmdStack.State.pSV == NULL)
        {
        r -> CmdStack.State.pStart    = NULL ;
        return ok ;
        }

    ppSV = av_fetch ((AV *)r -> CmdStack.State.pSV2, r -> CmdStack.State.nResult, 0) ;

    if (ppSV != NULL && *ppSV != NULL)
        {
        sv_setsv (r -> CmdStack.State.pSV, *ppSV) ;
        r -> CmdStack.State.nResult++ ;
        r -> Component.pCurrPos = r -> CmdStack.State.pStart ;        
        r -> Buf.nBlockNo = r -> CmdStack.State.nBlockNo ;        
        }
    else
        r -> CmdStack.State.pStart    = NULL ;

    return ok ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* hidden command ...                                                           */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

static int CmdHidden (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)

    {
    char *  pKey ;
    SV *    psv ;
    SV * *  ppsv ;
    HV *    pAddHash = r -> pThread -> pFormHash ;
    HV *    pSubHash = r -> pThread -> pInputHash ;
    AV *    pSort    = NULL ;
    HE *    pEntry ;
    I32     l ;
    char *  sArgs ;
    char *  sVarName ;
    char    sVar[512] ;
    int     nMax ;
    STRLEN  nKey ;

    EPENTRY (CmdHidden) ;

    
    sArgs = _ep_strdup (r, sArg) ;
    if (sArgs && *sArgs != '\0')
        {            
        strncpy (sVar, r -> Component.sEvalPackage, sizeof (sVar) - 5) ;
        sVar[r -> Component.nEvalPackage] = ':' ;
        sVar[r -> Component.nEvalPackage+1] = ':' ;
        sVar[sizeof(sVar) - 1] = '\0' ;
        nMax = sizeof(sVar) - r -> Component.nEvalPackage - 3 ;
        
        if ((sVarName = strtok (sArgs, ", \t\n")))
            {
            if (*sVarName == '%')
                sVarName++ ;
        
            strncpy (sVar + r -> Component.nEvalPackage + 2, sVarName, nMax) ;
            
            if ((pAddHash = perl_get_hv ((char *)sVar, FALSE)) == NULL)
                {
                strncpy (r -> errdat1, sVar, sizeof (r -> errdat1) - 1) ;
                _free (r, sArgs) ;
                return rcHashError ;
                }

            if ((sVarName = strtok (NULL, ", \t\n")))
                {
                if (*sVarName == '%')
                    sVarName++ ;
        
                strncpy (sVar + r -> Component.nEvalPackage + 2, sVarName, nMax) ;
        
                if ((pSubHash = perl_get_hv ((char *)sVar, FALSE)) == NULL)
                    {
                    strncpy (r -> errdat1, sVar, sizeof (r -> errdat1) - 1) ;
                    _free (r, sArgs) ;
                    return rcHashError ;
                    }

                if ((sVarName = strtok (NULL, ", \t\n")))
                    {
                    if (*sVarName == '@')
                        sVarName++ ;
        
                    strncpy (sVar + r -> Component.nEvalPackage + 2, sVarName, nMax) ;
        
                    if ((pSort = perl_get_av ((char *)sVar, FALSE)) == NULL)
                        {
                        strncpy (r -> errdat1, sVar, sizeof (r -> errdat1) - 1) ;
                        _free (r, sArgs) ;
                        return rcArrayError ;
                        }
                    }
                }
            }
        }
    else
        pSort = r -> pThread -> pFormArray ;


    oputc (r, '\n') ;
    if (pSort)
        {
        int n = AvFILL (pSort) + 1 ;
        int i ;

        for (i = 0; i < n; i++)
            {
            ppsv = av_fetch (pSort, i, 0) ;
            if (ppsv && (pKey = SvPV(*ppsv, nKey)) && !hv_exists (pSubHash, pKey, nKey))
                {
                ppsv = hv_fetch (pAddHash, pKey, nKey, 0) ;
                
               if (ppsv && (!(r -> Component.Config.bOptions & optNoHiddenEmptyValue) || *SvPV (*ppsv, na)))
                    {
                    oputs (r, "<input type=\"hidden\" name=\"") ;
                    oputs (r, pKey) ;
                    oputs (r, "\" value=\"") ;
                    OutputToHtml (r, SvPV (*ppsv, na)) ;
                    oputs (r, "\">\n") ;
                    }
                }
            }
        }
    else
        {
        hv_iterinit (pAddHash) ;
        while ((pEntry = hv_iternext (pAddHash)))
            {
            pKey = hv_iterkey (pEntry, &l) ;
            if (!hv_exists (pSubHash, pKey, strlen (pKey)))
                {
                psv = hv_iterval (pAddHash, pEntry) ;

                if (!(r -> Component.Config.bOptions & optNoHiddenEmptyValue) || *SvPV (psv, na)) 
		    {
                    oputs (r, "<input type=\"hidden\" name=\"") ;
                    oputs (r, pKey) ;
                    oputs (r, "\" value=\"") ;
                    OutputToHtml (r, SvPV (psv, na)) ;
                    oputs (r, "\">\n") ;
                    }
                }
            }
        }

    if (sArgs)
        _free (r, sArgs) ;

    return ok ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* var command ...                                                              */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

static int CmdVar (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)

    {
    int    rc ;
    SV **  ppSV ;
    int    nFilepos = (sArg - r -> Component.pBuf) ;
    SV *   pSV ;

    dTHR ;

    EPENTRY (CmdVar) ;
    
    r -> Component.bStrict = HINT_STRICT_REFS | HINT_STRICT_SUBS | HINT_STRICT_VARS ;
    
    /* Already compiled ? */
    
    ppSV = hv_fetch(r -> Buf.pFile -> pCacheHash, (char *)&nFilepos, sizeof (nFilepos), 1) ;  
    if (ppSV == NULL)
        {
        strcpy (r -> errdat1, "CacheHash") ;
        return rcHashError ;
        }
            
    if (SvTRUE(*ppSV))
        return ok ;
    
    sv_setiv (*ppSV, 1) ;

    tainted = 0 ;

    pSV = newSVpvf("package %s ; \n#line %d %s\n use vars qw(%s); map { $%s::CLEANUP{substr ($_, 1)} = 1 } qw(%s) ;\n",
	           r -> Component.sEvalPackage, r -> Component.nSourceline, r -> Component.sSourcefile, sArg,
		   r -> Component.sEvalPackage, sArg) ;
    newSVpvf2(pSV) ;

    rc = EvalDirect (r, pSV, 0, NULL) ;
    SvREFCNT_dec(pSV);

    return rc ;
    }



/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* sub command ...                                                              */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

static int CmdSub    (/*i/o*/ register req * r,
		      /*in*/ const char *   sArg)
    {
    int	nSubPos = r -> Component.pCurrPos - r -> Component.pBuf ;
    int    nFilepos = (sArg - r -> Component.pBuf) ;
    char sSubCode [128] ;

    EPENTRY (CmdSub) ;


    /* remember the start of the sub */
    SetSubTextPos (r, sArg, nSubPos) ;
    
    /* skip everything until endsub */
    r -> CmdStack.State.bProcessCmds = cmdSub ;

    /* compile perl sub */
    /* sprintf (sSubCode, "unshift @_, HTML::Embperl::CurrReq (0) ; HTML::Embperl::ProcessSub (%d, %d, %d)", (int)r -> Buf.pFile, nSubPos, r -> Buf.nBlockNo) ; */
    sprintf (sSubCode, " HTML::Embperl::ProcessSub (%ld, %d, %d)", (IV)r -> Buf.pFile, nSubPos, r -> Buf.nBlockNo) ;

    while (isspace(*sArg))
	sArg++ ;

    return EvalSub (r, sSubCode, nFilepos, sArg) ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* endsub command ...                                                           */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

static int CmdEndsub   (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)
    {
    EPENTRY (CmdEndsub) ;


    if (r -> CmdStack.State.nCmdType != cmdSub)
        return rcExit ;

    r -> CmdStack.State.bProcessCmds = cmdAll ;
    r -> CmdStack.State.pStart       = NULL ;

    return ok ;
    }



/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* meta tag ...                                                                 */
/*                                                                              */
/*  set http headers on meta http-equiv                                         */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static int HtmlMeta (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)
    
    {
    char *  pType ;
    char *  pContent ;
    int     tlen ;
    int     clen ;
    
    
    EPENTRY (HtmlMeta) ;

    
    pType = (char *)GetHtmlArg (sArg, "HTTP-EQUIV", &tlen) ;
    if (tlen == 0)
        return ok ; /* no http-equiv */

    pContent = (char *)GetHtmlArg (sArg, "CONTENT", &clen) ;
    if (clen == 0)
        return ok ; /* missing content for http-equiv */
    
    /*tsav = pType[tlen] ;
    pType[tlen] = '\0' ;
    csav = pContent[clen] ;
    pContent[clen] = '\0' ;*/
    
    hv_store (r -> pThread -> pHeaderHash, pType, tlen, newSVpv (pContent, clen), 0) ;

    /*pType[tlen] = tsav ;
    pContent[clen] = csav ;*/

    return ok ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* body tag ...                                                                 */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static int HtmlBody (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)
    {
    EPENTRY (HtmlBody) ;

    if ((r -> Component.Config.bDebug & dbgLogLink) == 0)
        return ok ;

    oputs (r, r -> Buf.pCurrTag) ;
    if (*sArg != '\0')
        {
        oputc (r, ' ') ;
        oputs (r, sArg) ;
        }
    oputc (r, '>') ;
    
    r -> Component.pCurrPos = NULL ;
    	
    if (r -> Component.Config.bDebug & dbgLogLink)
	{
        char pid [30] ;
        char fp [30] ;
        
        if (!r -> pConf -> sVirtLogURI)
            {
            LogError (r, rcVirtLogNotSet) ;
            return ok ;
            }
        
        sprintf (pid, "%d", r -> pThread -> nPid) ;
        sprintf (fp, "%ld", r -> nLogFileStartPos) ;
        
        oputs (r, "<A HREF=\"") ;
        oputs (r, r -> pConf -> sVirtLogURI) ;    
        oputs (r, "?") ;    
        oputs (r, fp) ;    
        oputs (r, "&") ;    
        oputs (r, pid) ;    
        oputs (r, "\">Logfile</A> / ") ;

        oputs (r, "<A HREF=\"") ;
        oputs (r, r -> pConf -> sVirtLogURI) ;    
        oputs (r, "?") ;    
        oputs (r, fp) ;    
        oputs (r, "&") ;    
        oputs (r, pid) ;    
        oputs (r, "&SRC:") ;    
        oputs (r, "\">Source only</A> / ") ;

        oputs (r, "<A HREF=\"") ;
        oputs (r, r -> pConf -> sVirtLogURI) ;    
        oputs (r, "?") ;    
        oputs (r, fp) ;    
        oputs (r, "&") ;    
        oputs (r, pid) ;    
        oputs (r, "&EVAL") ;    
        oputs (r, "\">Eval only</A>\n") ;
	}

    return ok ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* URLEscape ...                                                                */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static int URLEscape   (/*i/o*/ register req * r,
			/*in*/  const char *   sArg,
			/*in*/  const char *   sAttrName,
			/*in*/  int            bAppendSessionID)
    {
    int    rc ;
    char * pArgBuf  = NULL ;
    char * pFreeBuf = NULL ;
    char * pAttr ;
    int          alen ;

    
    EPENTRY (URLEscape) ;

    oputs (r, r -> Buf.pCurrTag) ;
    oputc (r, ' ') ;

    if (*sArg != '\0')
    	{
	pAttr = (char *)GetHtmlArg (sArg, sAttrName, &alen) ;

	if (alen > 0)
	    {
	    char c = *pAttr ;
	
	    /* check part before ATTR */

	    *pAttr = '\0' ;

	    if ((rc = ScanCmdEvalsInString (r, (char *)sArg, &pArgBuf, nInitialScanOutputSize, &pFreeBuf)) != ok)
		{
		*pAttr = c ;
		if (pFreeBuf)
		    _free (r, pFreeBuf) ;
            
		return rc ;
		}
	    
	    oputs (r, pArgBuf) ;
	    *pAttr = c ;

	    if (pFreeBuf)
		_free (r, pFreeBuf) ;
	    pFreeBuf = NULL ;

	    /* check ATTR part which should be URL escaped */

	    c = pAttr[alen] ;
	    pAttr[alen] = '\0' ;
		
	    if (r -> Component.Config.nEscMode & escUrl)
		r -> Component.pCurrEscape = Char2Url ;
	    r -> Component.bEscInUrl = TRUE ;

	    if ((rc = ScanCmdEvalsInString (r, (char *)pAttr, &pArgBuf, nInitialScanOutputSize, &pFreeBuf)) != ok)
		{
		pAttr[alen] = c ;
		r -> Component.bEscInUrl = FALSE ;
		NewEscMode (r, NULL) ;
		if (pFreeBuf)
		    _free (r, pFreeBuf) ;
            
		return rc ;
		}
	    oputs (r, pArgBuf) ;

	    
	    if (bAppendSessionID && r -> sSessionID)
                {
                if (strchr(pArgBuf, '?'))
                    {
                    oputc(r, '&') ;
                    }
                else
                    {
                    oputc(r, '?') ;
                    }
                oputs (r, r -> sSessionID) ;
                }
            
            
            r -> Component.bEscInUrl = FALSE ;
	    NewEscMode (r, NULL) ;
	    if (pFreeBuf)
		_free (r, pFreeBuf) ;
	    pFreeBuf = NULL ;
 	    pAttr[alen] = c ;

	    /* check part after ATTR */

	    if ((rc = ScanCmdEvalsInString (r, (char *)pAttr + alen, &pArgBuf, nInitialScanOutputSize, &pFreeBuf)) != ok)
		{
		if (pFreeBuf)
		    _free (r, pFreeBuf) ;
            
		return rc ;
		}
	    oputs (r, pArgBuf) ;
	    if (pFreeBuf)
		_free (r, pFreeBuf) ;
	    pFreeBuf = NULL ;

	    }
	else
	    {
	    if ((rc = ScanCmdEvalsInString (r, (char *)sArg, &pArgBuf, nInitialScanOutputSize, &pFreeBuf)) != ok)
		{
		if (pFreeBuf)
		    _free (r, pFreeBuf) ;
            
		return rc ;
		}
	    oputs (r, pArgBuf) ;
	    if (pFreeBuf)
		_free (r, pFreeBuf) ;
	    pFreeBuf = NULL ;
	    }

	}
    else
        {
        oputs (r, sArg) ;
        }

    oputc (r, '>') ;
    
    r -> Component.pCurrPos = NULL ;
    	
    return ok ;
    }

    
/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* A tag ...                                                                    */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static int HtmlA (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)
    {
    EPENTRY (HtmlA) ;

    return URLEscape (r, sArg, "HREF", 1) ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* IMG tag ...                                                                    */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static int HtmlIMG     (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)
    {
    EPENTRY (HtmlIMG) ;

    return URLEscape (r, sArg, "SRC", 0) ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* tag with SRC attribute...                                                    */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static int HtmlASRC     (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)
    {
    EPENTRY (HtmlASRC) ;

    return URLEscape (r, sArg, "SRC", 1) ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Form tag ...                                                                 */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static int HtmlForm    (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)
    {
    EPENTRY (HtmlForm) ;

    return URLEscape (r, sArg, "ACTION", 0) ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* /Form tag ...                                                                 */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static int HtmlEndform (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)
    {
    char * sid = r -> sSessionID ;

    EPENTRY (HtmlFormEnd) ;


    if (sid)
        {
	char * val = strchr (sid, '=') ;
	if (val)
	    {
	    oputs(r, "<input type=\"hidden\" name=\"") ;
	    owrite(r, sid, val - sid) ;
	    val++ ;
	    oputs(r, "\" value=\"") ;
	    oputs (r, val) ;
	    oputs(r, "\">") ;
	    }
        }


    return ok ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* table tag ...                                                                */
/* and various list tags ... (dir, menu, ol, ul)                                */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

static int HtmlTable (/*i/o*/ register req * r,
		      /*in*/  const char *   sArg)
    {
    tTableStackEntry *  pStack ;
    
    EPENTRY (HtmlTable) ;

    oputs (r, r -> Buf.pCurrTag) ;
    if (*sArg != '\0')
        {
        oputc (r, ' ') ;
        oputs (r, sArg) ;
        }
    oputc (r, '>') ;
    
    pStack = r -> TableStack.pStackFree ;
    if (pStack)
        r -> TableStack.pStackFree = pStack -> pNext ;
    else
        pStack = _malloc (r, sizeof (struct tTableStackEntry)) ;

    memcpy (pStack, &r -> TableStack.State, sizeof (*pStack)) ;

    pStack -> pNext        = r -> TableStack.pStack ;
    r -> TableStack.pStack = pStack ;

    memset (&r -> TableStack.State, 0, sizeof (r -> TableStack.State)) ;
    r -> TableStack.State.nResult   = 1 ;
    r -> TableStack.State.nTabMode  = r -> nTabMode ;
    r -> TableStack.State.nMaxRow   = r -> nTabMaxRow ;
    r -> TableStack.State.nMaxCol   = r -> nTabMaxCol ;
    
    if ((r -> TableStack.State.nTabMode & epTabRow) == epTabRowDef)
        r -> HtmlStack.State.pBuf = oBegin (r) ;

    r -> Component.pCurrPos = NULL ;
    	
    return ok ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* table tag ... (and end of list)                                              */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static int HtmlEndtable (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)
    {
    tTableStackEntry *  pStack ;
    
    EPENTRY (HtmlEndtable) ;

    if (r -> HtmlStack.State.nCmdType != cmdTable || r -> HtmlStack.State.pCmd -> nCmdNo != r -> pCurrCmd -> nCmdNo)
        {
        strncpy (r -> errdat1, r -> Buf.pCurrTag + 1, sizeof (r -> errdat1) - 1) ; 
        if (r -> HtmlStack.State.pCmd)
            strcpy (r -> errdat2, r -> HtmlStack.State.pCmd -> sCmdName) ; 
        else
            strcpy (r -> errdat2, "NO TAG") ; 
        
        return rcEndtableWithoutTable ;
        }

    if (r -> Component.Config.bDebug & dbgTab)
        lprintf (r -> pApp,  "[%d]TAB:  r -> nTabMode=%d nResult=%d nRow=%d Used=%d nCol=%d Used=%d nCnt=%d Used=%d \n",
               r -> pThread -> nPid, r -> TableStack.State.nTabMode, r -> TableStack.State.nResult, r -> TableStack.State.nRow, r -> TableStack.State.nRowUsed, r -> TableStack.State.nCol, r -> TableStack.State.nColUsed, r -> TableStack.State.nCount, r -> TableStack.State.nCountUsed) ;

    if ((r -> TableStack.State.nTabMode & epTabRow) == epTabRowDef)
        if (r -> TableStack.State.nResult || r -> TableStack.State.nCol > 0)
            oCommit (r, r -> HtmlStack.State.pBuf) ;
        else
            oRollback (r, r -> HtmlStack.State.pBuf) ;

    r -> TableStack.State.nRow++ ;
    if (((r -> TableStack.State.nTabMode & epTabRow) == epTabRowMax ||
         ((r -> TableStack.State.nResult || r -> TableStack.State.nCol > 0) && (r -> TableStack.State.nRowUsed || r -> TableStack.State.nCountUsed) )) &&
          r -> TableStack.State.nRow < r -> TableStack.State.nMaxRow)
        {
        r -> Component.pCurrPos = r -> HtmlStack.State.pStart ;        
        r -> Buf.nBlockNo = r -> HtmlStack.State.nBlockNo ;        
        if ((r -> TableStack.State.nTabMode & epTabRow) == epTabRowDef)
            r -> HtmlStack.State.pBuf = oBegin (r) ;

	r -> TableStack.State.nResult    = 1 ;
        
	return ok ;
        }

    r -> HtmlStack.State.pStart    = NULL ;

    pStack = r -> TableStack.pStack ;
    if (pStack == NULL)
        return rcStackUnderflow ;
    else
        {
        memcpy (&r -> TableStack.State, pStack, sizeof (r -> TableStack.State)) ;
        
        r -> TableStack.pStack = pStack -> pNext ;
        pStack -> pNext = r -> TableStack.pStackFree ;
        r -> TableStack.pStackFree = pStack ;
        }

    return ok ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* tr tag ...                                                                   */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

static int HtmlRow (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)
    {
    EPENTRY (HtmlRow) ;

            
    if (r -> TableStack.pStack == NULL)
        return rcTablerowOutsideOfTable ;
    
    oputs (r, r -> Buf.pCurrTag) ;
    if (*sArg != '\0')
        {
        oputc (r, ' ') ;
        oputs (r, sArg) ;
        }
    oputc (r, '>') ;

    /* r -> TableStack.State.nResult    = 1 ; */
    r -> TableStack.State.nCol       = 0 ; 
    r -> TableStack.State.nColUsed   = 0 ; 
    r -> TableStack.State.bHead      = r -> TableStack.State.bRowHead = 0 ;

    if ((r -> TableStack.State.nTabMode & epTabCol) == epTabColDef)
        r -> HtmlStack.State.pBuf = oBegin (r) ;
    
    r -> Component.pCurrPos = NULL ;
    
    return ok ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* /tr tag ...                                                                  */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

static int HtmlEndrow  (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)
    {
    EPENTRY (HtmlEndrow) ;

    
    if (r -> HtmlStack.State.nCmdType != cmdTablerow)
        return rcEndtableWithoutTablerow ;

    if (r -> Component.Config.bDebug & dbgTab)
        lprintf (r -> pApp,  "[%d]TAB:  r -> nTabMode=%d nResult=%d nRow=%d Used=%d nCol=%d Used=%d nCnt=%d Used=%d \n",
               r -> pThread -> nPid, r -> TableStack.State.nTabMode, r -> TableStack.State.nResult, r -> TableStack.State.nRow, r -> TableStack.State.nRowUsed, r -> TableStack.State.nCol, r -> TableStack.State.nColUsed, r -> TableStack.State.nCount, r -> TableStack.State.nCountUsed) ;

    
    if ((r -> TableStack.State.nTabMode & epTabCol) == epTabColDef)
        if (r -> TableStack.State.nResult || (!r -> TableStack.State.nColUsed && !r -> TableStack.State.nCountUsed && !r -> TableStack.State.nRowUsed))
            oCommit (r, r -> HtmlStack.State.pBuf) ;
	else
            oRollback (r, r -> HtmlStack.State.pBuf), r -> TableStack.State.nCol-- ;

    if (r -> TableStack.State.bRowHead)    
        {
        if (r -> HtmlStack.pStack == NULL)
            return rcTablerowOutsideOfTable ;
        r -> HtmlStack.pStack -> pStart   = r -> Component.pCurrPos ;
        r -> HtmlStack.pStack -> nBlockNo = r -> Buf.nBlockNo ; 
        }
    

    r -> TableStack.State.nCount++ ;
    r -> TableStack.State.nCol++ ;
    if (((r -> TableStack.State.nTabMode & epTabCol) == epTabColMax ||
         (r -> TableStack.State.nResult && (r -> TableStack.State.nColUsed || r -> TableStack.State.nCountUsed)))
        && r -> TableStack.State.nCol < r -> TableStack.State.nMaxCol)
        {
        r -> Component.pCurrPos = r -> HtmlStack.State.pStart ;        
        r -> Buf.nBlockNo = r -> HtmlStack.State.nBlockNo ;        
        if ((r -> TableStack.State.nTabMode & epTabCol) == epTabColDef)
            r -> HtmlStack.State.pBuf = oBegin (r) ;
    
        }
    else
	{
        r -> HtmlStack.State.pStart    = NULL ;

	if (r -> TableStack.State.bHead || r -> TableStack.State.nCol > 0)    
	    {
	    r -> TableStack.State.nResult    = 1 ; 
	    }
	}
    return ok ;
    }
                        
/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* table head tag ...                                                           */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

static int HtmlTableHead (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)
    {
    EPENTRY (HtmlTableHead) ;

    if (r -> TableStack.State.nCol == 0)
        r -> TableStack.State.bHead = r -> TableStack.State.bRowHead = 1 ;
    else
        r -> TableStack.State.bRowHead = 0 ;

    return ok ;
    }

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* Split values in from %fdat                                                   */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


SV * SplitFdat     (/*i/o*/ register req * r,
                           /*in*/  SV ** ppSVfdat,
                           /*out*/ SV ** ppSVerg,
                           /*in*/  char * pName,
                           /*in*/  STRLEN nlen)

    {
    STRLEN dlen ;
    char * pData ;
    char * s ;
    char * p ;
    
    if (ppSVerg && *ppSVerg && SvTYPE (*ppSVerg))
        {
        return *ppSVerg ;
        }

    pData = SvPV (*ppSVfdat, dlen) ;
    s = pData ;

    if ((p = strchr (s, r -> pConf -> cMultFieldSep)))
        { /* Multiple values -> put them into a hash */
        HV * pHV = newHV () ;
        int l ;

        while (p)
            {
            hv_store (pHV, s, p - s, &sv_undef, 0) ;
            s = p + 1 ;
            p = strchr (s, r -> pConf -> cMultFieldSep) ;
            }

        l = dlen - (s - pData) ;
        if (l > 0)
            hv_store (pHV, s, l, &sv_undef, 0) ;
        hv_store (r -> pThread -> pFormSplitHash, (char *)pName, nlen, (SV *)pHV, 0) ;
        if (r -> Component.Config.bDebug & dbgInput)
            lprintf (r -> pApp,  "[%d]INPU: <mult values>\n", r -> pThread -> nPid) ; 
        return (SV *)pHV;
        }
    else
        {
        SvREFCNT_inc (*ppSVfdat) ;
        hv_store (r -> pThread -> pFormSplitHash, (char *)pName, nlen, *ppSVfdat, 0) ;
        if (r -> Component.Config.bDebug & dbgInput)
            lprintf (r -> pApp,  "[%d]INPU: value = %s\n", r -> pThread -> nPid, SvPV(*ppSVfdat, na)) ; 
        return *ppSVfdat ;
        }
    }    

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* select tag ...                                                               */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

static int HtmlSelect (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)
    {
    const char * pName ;
    int          nlen ;
    SV * *       ppSV ;

    
    EPENTRY (HtmlSelect) ;

    pName = GetHtmlArg (sArg, "NAME", &nlen) ;
    if (nlen == 0)
        {
        if (r -> Component.Config.bDebug & dbgInput)
            lprintf (r -> pApp,  "[%d]INPU: Select has no name\n", r -> pThread -> nPid) ; 
        }
    else
        {
        r -> HtmlStack.State.sArg   = _ep_strndup (r, pName, nlen) ;

        ppSV = hv_fetch(r -> pThread -> pFormHash, (char *)pName, nlen, 0) ;  
        if (ppSV == NULL)
            {
            if (r -> Component.Config.bDebug & dbgInput)
                lprintf (r -> pApp,  "[%d]INPU: Select %s: no data available in form data\n", r -> pThread -> nPid, r -> HtmlStack.State.sArg) ; 
            }
        else
            {
            SV * * ppSVerg = hv_fetch(r -> pThread -> pFormSplitHash, (char *)pName, nlen, 0) ;  

            r -> HtmlStack.State.pSV = SplitFdat (r, ppSV, ppSVerg, (char *)pName, nlen) ;
            SvREFCNT_inc (r -> HtmlStack.State.pSV) ;
            if (r -> Component.Config.bDebug & dbgInput)
                lprintf (r -> pApp,  "[%d]INPU: Select %s = %s\n", r -> pThread -> nPid, r -> HtmlStack.State.sArg, SvPV(r -> HtmlStack.State.pSV, na)) ; 
           }    
        }


    return HtmlTable (r, sArg) ;
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* option tag ...                                                               */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static int HtmlOption (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)
    {
    const char *  pVal ;
    const char *  pSelected ;
    STRLEN        vlen ;
    int           slen ;
    char *        pName ;
    char *        pData ;
    STRLEN        dlen ;
    int           bSel ;
    SV *	  pSV ;


    EPENTRY (HtmlOption) ;

    pName = r -> HtmlStack.State.sArg?r -> HtmlStack.State.sArg:"" ;

    if (r -> HtmlStack.State.pSV == NULL)
        {
        /*if (bDebug & dbgInput)
            lprintf (r -> pApp,  "[%d]INPU: <Select>/<Option> no data available\n", r -> pThread -> nPid) ; */
        
        return ok ; /* no name or no data for select */
        }

    pVal = GetHtmlArg (sArg, "VALUE", &slen) ;
    vlen = slen ; /* first use an int to avoid problems on 64Bit Systems! */
    if (vlen == 0)    
        {
        if (r -> Component.Config.bDebug & dbgInput)
            lprintf (r -> pApp,  "[%d]INPU: <Option> for Select %s has no value\n", r -> pThread -> nPid, pName) ; 
        
        return ok ; /* has no value */
        }

    pSV = newSVpv ((char *)pVal, vlen) ;
    TransHtmlSV (r, pSV) ;
    pVal = SvPV (pSV, vlen) ;

 
    pSelected = GetHtmlArg (sArg, "SELECTED", &slen) ;
    bSel = 0 ;

    
    if (SvTYPE (r -> HtmlStack.State.pSV) == SVt_PVHV)
        { /* -> Hash -> check if key exists */
        if (hv_exists ((HV *)r -> HtmlStack.State.pSV, (char *)pVal, vlen))
            bSel = 1 ;
        }
    else
        {
        pData = SvPV (r -> HtmlStack.State.pSV, dlen) ;
        if (dlen == vlen && strncmp (pVal, pData, dlen) == 0)
            bSel = 1 ;
        }
            
    if (r -> Component.Config.bDebug & dbgInput)
        lprintf (r -> pApp,  "[%d]INPU: <Option> %s is now%s selected\n", r -> pThread -> nPid, pName, (bSel?"":" not")) ; 

    if (bSel)
        { /* -> selected */
        if (hv_store (r -> pThread -> pInputHash, pName, strlen (pName), pSV, 0) == NULL)
            {
            strcpy (r -> errdat1, "InputHash in HtmlOption") ;
            return rcHashError ;
            }

        if (pSelected)
            return ok ;
        else
            {
            oputs (r, r -> Buf.pCurrTag) ;
            if (*sArg != '\0')
                {
                oputc (r, ' ') ;
                oputs (r, sArg) ;
                }
            oputs (r, " selected>") ;
            r -> Component.pCurrPos = NULL ; /* nothing more left of html tag */
            return ok ;
            }
        }
    else
        {
        SvREFCNT_dec (pSV) ;
	if (pSelected == NULL)
            return ok ;
        else
            {
            oputs (r, r -> Buf.pCurrTag) ;
            oputc (r, ' ') ;
            owrite (r, sArg, pSelected - sArg) ;
            oputs (r, pSelected + 8) ;
            oputc (r, '>') ;
            r -> Component.pCurrPos = NULL ; /* nothing more left of html tag */
            return ok ;
            }
        }
    }


/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* /select tag ...                                                               */
/*                                                                              */
/* ---------------------------------------------------------------------------- */

static int HtmlEndselect (/*i/o*/ register req * r,
		 	  /*in*/ const char *   sArg)
    {
    if (r -> Component.Config.bOptions & optAllFormData)
	{
	char *        pName ;
	int           l ;
	EPENTRY (HtmlEndselect) ;

	pName = r -> HtmlStack.State.sArg?r -> HtmlStack.State.sArg:"" ;
	l     = strlen (pName) ;
        
	if (!hv_exists (r -> pThread -> pInputHash, pName, l))
	    if (hv_store (r -> pThread -> pInputHash, pName, l, &sv_undef, 0) == NULL)
                {
                strcpy (r -> errdat1, "InputHash in HtmlEndselect") ;
                return rcHashError ;
                }
	}

    return HtmlEndtable (r, sArg) ;
    }

                        

/* ---------------------------------------------------------------------------- */
/*                                                                              */
/* input tag ...                                                                */
/*                                                                              */
/* ---------------------------------------------------------------------------- */


static int HtmlInput (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)
    {
    const char *  pName ;
    const char *  pVal ;
    const char *  pData ;
    const char *  pType ;
    const char *  pCheck ;
    int           nlen ;
    int           vlen ;
    STRLEN        dlen ;
    int           tlen ;
    int           clen ;
    SV *          pSV ;
    SV **         ppSV ;
    char          sName [256] ;
    int           bCheck ;
    int           bEqual = 0 ;

    EPENTRY (HtmlInput) ;

    pName = GetHtmlArg (sArg, "NAME", &nlen) ;
    if (nlen == 0)
        {
        if (r -> Component.Config.bDebug & dbgInput)
            lprintf (r -> pApp,  "[%d]INPU: has no name\n", r -> pThread -> nPid) ; 
        return ok ; /* no Name */
        }

    if (nlen >= sizeof (sName))
        nlen = sizeof (sName) - 1 ;
    strncpy (sName, pName, nlen) ;
    sName [nlen] = '\0' ;        

    pType = GetHtmlArg (sArg, "TYPE", &tlen) ;
    if (tlen > 0 && (strnicmp (pType, "RADIO", 5) == 0 || strnicmp (pType, "CHECKBOX", 8) == 0))
        bCheck = 1 ;
    else    
        bCheck = 0 ;
    
    
    
    pVal = GetHtmlArg (sArg, "VALUE", &vlen) ;
    /*if ((pVal && vlen != 0) && bCheck == 0)    */
    if (pVal && bCheck == 0)    
        {
        pSV = newSVpv ((char *)pVal, vlen) ;
        TransHtmlSV (r, pSV) ;

        if (r -> Component.Config.bDebug & dbgInput)
            lprintf (r -> pApp,  "[%d]INPU: %s already has a value = %s\n", r -> pThread -> nPid, sName, SvPV (pSV, na)) ; 
        
        if (hv_store (r -> pThread -> pInputHash, sName, strlen (sName), pSV, 0) == NULL)
            {
            strcpy (r -> errdat1, "InputHash in HtmlInput") ;
            return rcHashError ;
            }
        
        return ok ; /* has already a value */
        }


    ppSV = hv_fetch(r -> pThread -> pFormHash, (char *)pName, nlen, 0) ;  
    if (ppSV == NULL)
        {
        if (r -> Component.Config.bOptions & optUndefToEmptyValue)
            {
            pData = "" ;
            dlen = 0 ;
            }
        else
            {
            if (r -> Component.Config.bDebug & dbgInput)
                lprintf (r -> pApp,  "[%d]INPU: %s: no data available in form data\n", r -> pThread -> nPid, sName) ; 

            if (vlen != 0)    
                {
                pSV = newSVpv ((char *)pVal, vlen) ;

                if (hv_store (r -> pThread -> pInputHash, sName, strlen (sName), pSV, 0) == NULL)
                    {
                    strcpy (r -> errdat1, "InputHash in HtmlInput") ;
                    return rcHashError ;
                    }
                }

            return ok ; /* no data available */
            }
        }
    else
        pData = SvPV (*ppSV, dlen) ;
    

    if (bCheck)
        { /* check box */
        bEqual = 0 ;
        
        if (vlen > 0 && ppSV)
            {
            SV * pSV ;
            SV * pSVVal ;
            char * pTVal ;
	    STRLEN vtlen ;
	    
	    SV * * ppSVerg = hv_fetch(r -> pThread -> pFormSplitHash, (char *)pName, nlen, 0) ;  
            pSV = SplitFdat (r, ppSV, ppSVerg, (char *)pName, nlen) ;
    
	    pSVVal = newSVpv ((char *)pVal, vlen) ;
	    TransHtmlSV (r, pSVVal) ;
	    pTVal = SvPV (pSVVal, vtlen) ;

            if (SvTYPE (pSV) == SVt_PVHV)
                { /* -> Hash -> check if key exists */
                if (hv_exists ((HV *)pSV, (char *)pTVal, vtlen))
                    bEqual = 1 ;
                }
            else
                {
                pData = SvPV (pSV, dlen) ;
                if (dlen == vtlen && strncmp (pTVal, pData, dlen) == 0)
                    bEqual = 1 ;
                }
            SvREFCNT_dec (pSVVal) ;
	    }
       
        pCheck = GetHtmlArg (sArg, "checked", &clen) ;
        if (pCheck)
            {
            if (!bEqual)
                { /* Remove "checked" */
                oputs (r, "<input ") ;
                
                owrite (r, sArg, pCheck - sArg) ;
    
                oputs (r, pCheck + 7) ; /* write rest of html tag */
                oputc (r, '>') ;

                r -> Component.pCurrPos = NULL ; /* nothing more left of html tag */
                }
            }
        else
            {
            if (bEqual)
                { /* Insert "checked" */
                oputs (r, "<input ") ;
                oputs (r, sArg) ;
                oputs (r, " checked>") ;
    
                r -> Component.pCurrPos = NULL ; /* nothing more left of html tag */
                }
            }
        }
    else 
        { /* text field */
        if (pVal)
            {
            oputs (r, "<input ") ;

            owrite (r, sArg, pVal - sArg) ;

            oputs (r, " value=\"") ;
            OutputToHtml (r, pData) ;
            oputs (r, "\" ") ;

            while (*pVal && !isspace(*pVal))
                pVal++ ;
        
            oputs (r, pVal) ; /* write rest of html tag */
            oputc (r, '>') ;

            r -> Component.pCurrPos = NULL ; /* nothing more left of html tag */
            }
        else
            {
            oputs (r, "<input ") ;
            oputs (r, sArg) ;
            oputs (r, " value=\"") ;
            OutputToHtml (r, pData) ;
            oputs (r, "\">") ;
    
            r -> Component.pCurrPos = NULL ; /* nothing more left of html tag */
            }
        }

    if (r -> Component.Config.bDebug & dbgInput)
        {
        lprintf (r -> pApp,  "[%d]INPU: %s=%s %s\n", r -> pThread -> nPid, sName, pData, bCheck?(bEqual?"CHECKED":"NOT CHECKED"):"") ; 
        }
    
    pSV = newSVpv ((char *)pData, dlen) ;
    if (hv_store (r -> pThread -> pInputHash, sName, strlen (sName), pSV, 0) == NULL)
        {
        strcpy (r -> errdat1, "InputHash in HtmlInput") ;
        return rcHashError ;
        }

    return ok ;
    }

/* ---------------------------------------------------------------------------- */
/* textarea tag ... */
/* */
/* ---------------------------------------------------------------------------- */


static int HtmlTextarea (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)
    {
    EPENTRY (HtmlTextarea) ;

    return ok ;
    }

    
/* ---------------------------------------------------------------------------- */
/* /textarea tag ... */
/* */
/* ---------------------------------------------------------------------------- */


static int HtmlEndtextarea (/*i/o*/ register req * r,
			/*in*/ const char *   sArg)
    {
    const char *  pName ;
    const char *  pVal ;
    const char *  pEnd ;
    const char *  pData ;
    int           nlen ;
    int           vlen ;
    STRLEN        dlen ;
    SV *          pSV ;
    SV **         ppSV ;
    char          sName [256] ;


    EPENTRY (HtmlEndtextarea) ;
    
    
    pVal = r -> HtmlStack.State.pStart ;

    r -> HtmlStack.State.pStart = NULL ;

    if (r -> HtmlStack.State.nCmdType != cmdTextarea)
        return rcEndtextareaWithoutTextarea ;


    pName = GetHtmlArg (r -> HtmlStack.State.sArg, "NAME", &nlen) ;
    if (nlen == 0)
        {
        if (r -> Component.Config.bDebug & dbgInput)
            lprintf (r -> pApp,  "[%d]TEXT: has no name\n", r -> pThread -> nPid) ; 
        return ok ; /* no Name */
        }

    if (nlen >= sizeof (sName))
        nlen = sizeof (sName) - 1 ;
    strncpy (sName, pName, nlen) ;
    sName [nlen] = '\0' ;        


    pEnd = r -> Buf.pCurrTag - 1 ;
    while (pVal <= pEnd && isspace (*pVal))
        pVal++ ;

    while (pVal <= pEnd && isspace (*pEnd))
        pEnd-- ;

    vlen = pEnd - pVal + 1 ;

    if (vlen != 0)    
        {
        pSV = newSVpv ((char *)pVal, vlen) ;
        TransHtmlSV (r, pSV) ;

        if (r -> Component.Config.bDebug & dbgInput)
            lprintf (r -> pApp,  "[%d]TEXT: %s already has a value = %s\n", r -> pThread -> nPid, sName, SvPV (pSV, na)) ; 
        
        if (hv_store (r -> pThread -> pInputHash, sName, strlen (sName), pSV, 0) == NULL)
            {
            strcpy (r -> errdat1, "InputHash in HtmlEndtextarea") ;
            return rcHashError ;
            }
        
        return ok ; /* has already a value */
        }


    ppSV = hv_fetch(r -> pThread -> pFormHash, (char *)pName, nlen, 0) ;  
    if (ppSV == NULL)
        {
        if (r -> Component.Config.bDebug & dbgInput)
            lprintf (r -> pApp,  "[%d]TEXT: %s: no data available in form data\n", r -> pThread -> nPid, sName) ; 
        return ok ; /* no data available */
        }

    pData = SvPV (*ppSV, dlen) ;
    
    if (pVal)
        {
        OutputToHtml (r, pData) ;
        }

    if (r -> Component.Config.bDebug & dbgInput)
        {
        lprintf (r -> pApp,  "[%d]TEXT: %s=%s\n", r -> pThread -> nPid, sName, pData) ; 
        }
    
    pSV = newSVpv ((char *)pData, dlen) ;
    if (hv_store (r -> pThread -> pInputHash, sName, strlen (sName), pSV, 0) == NULL)
        {
        strcpy (r -> errdat1, "InputHash in HtmlEndtextarea") ;
        return rcHashError ;
        }

    return ok ;
    }
