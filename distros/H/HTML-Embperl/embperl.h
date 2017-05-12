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
#   $Id: embperl.h,v 1.29 2001/11/02 10:03:48 richter Exp $
#
###################################################################################*/



/*
    Errors and Return Codes
*/

enum tRc
    {
    ok = 0,
    rcStackOverflow,
    rcStackUnderflow,
    rcEndifWithoutIf,
    rcElseWithoutIf,
    rcEndwhileWithoutWhile,
    rcEndtableWithoutTable,
    rcCmdNotFound,
    rcOutOfMemory,
    rcPerlVarError,
    rcHashError,
    rcArrayError,
    rcFileOpenErr,    
    rcMissingRight,
    rcNoRetFifo,
    rcMagicError,
    rcWriteErr,
    rcUnknownNameSpace,
    rcInputNotSupported,
    rcCannotUsedRecursive,
    rcEndtableWithoutTablerow,
    rcTablerowOutsideOfTable, 
    rcEndtextareaWithoutTextarea,
    rcArgStackOverflow,
    rcEvalErr,
    rcNotCompiledForModPerl,
    rcLogFileOpenErr,
    rcExecCGIMissing,
    rcIsDir,
    rcXNotSet,
    rcNotFound,
    rcUnknownVarType,
    rcPerlWarn,
    rcVirtLogNotSet,
    rcMissingInput,
    rcExit,
    rcUntilWithoutDo, 
    rcEndforeachWithoutForeach, 
    rcMissingArgs,
    rcNotAnArray,
    rcCallInputFuncFailed,
    rcCallOutputFuncFailed,
    rcSubNotFound,
    rcImportStashErr,
    rcCGIError,
    rcUnclosedHtml,
    rcUnclosedCmd,
    rcNotAllowed,
    rcNotHashRef,
    rcTagMismatch,
    rcCleanupErr,
    rcCryptoWrongHeader,
    rcCryptoWrongSyntax,
    rcCryptoNotSupported,
    rcCryptoBufferOverflow,
    rcCryptoErr
    } ;


/*
    Debug Flags
*/

enum dbg
    {
    dbgStd          = 1,
    dbgMem          = 2,
    dbgEval         = 4,
    dbgCmd          = 8,
    dbgEnv          = 16,
    dbgForm         = 32,
    dbgTab          = 64,
    dbgInput        = 128,
    dbgFlushOutput  = 256,
    dbgFlushLog     = 512,
    dbgAllCmds      = 1024,
    dbgSource       = 2048,
    dbgFunc         = 4096,
    dbgLogLink      = 8192,
    dbgDefEval      = 16384,
    dbgOutput           = 0x08000,
    dbgDOM              = 0x10000,
    dbgRun              = 0x20000,
    dbgHeadersIn        = 0x40000,
    dbgShowCleanup      = 0x80000,
    dbgProfile          = 0x100000,
    dbgSession          = 0x200000,
    dbgImport		= 0x400000,
    dbgBuildToken       = 0x800000,
    dbgParse            = 0x1000000,
    dbgObjectSearch     = 0x2000000,
    dbgCache            = 0x4000000,
    dbgCompile          = 0x8000000,
    dbgXML              = 0x10000000,
    dbgXSLT             = 0x20000000,
    dbgCheckpoint       = 0x40000000,
    
    dbgAll  = -1
    } ;

/*
    Option Flags
*/

enum opt
    {
    optDisableVarCleanup       = 1,
    optDisableEmbperlErrorPage = 2,
    optSafeNamespace           = 4,
    optOpcodeMask              = 8,
    optRawInput                = 16,
    optSendHttpHeader          = 32,
    optEarlyHttpHeader         = 64,
    optDisableChdir            = 128,
    optDisableFormData         = 256,
    optDisableHtmlScan         = 512,
    optDisableInputScan        = 1024,
    optDisableTableScan        = 2048,
    optDisableMetaScan         = 4096,
    optAllFormData             = 8192,
    optRedirectStdout          = 16384,
    optUndefToEmptyValue       = 32768,
    optNoHiddenEmptyValue      = 65536,
    optAllowZeroFilesize       = 0x20000, 
    optReturnError             = 0x40000, 
    optKeepSrcInMemory         = 0x80000,
    optKeepSpaces	       = 0x100000,
    optOpenLogEarly            = 0x200000,
    optNoUncloseWarn	       = 0x400000,
    optDisableSelectScan       = 0x800000,
    optAddUserSessionToLinks   = 0x1000000,
    optAddStateSessionToLinks  = 0x2000000,
    optNoSessionCookies        = 0x4000000,
    optShowBacktrace           = 0x8000000
    } ;

/*
    I/O modes
*/

enum epIO
    {
    epIOCGI      = 1,
    epIOProcess  = 2,
    epIOMod_Perl = 3,
    epIOPerl     = 4
    } ;
    
/*
    Table modes
*/

#define epTabRow        0x0f   /* Row Mask */
#define epTabRowDef     0x01   /* Last row where last defined expression */
#define epTabRowUndef   0x02   /* Last row where first undefined expression */
#define epTabRowMax     0x03   /* maxrow determinates number of rows */

#define epTabCol        0xf0   /* Column Mask */
#define epTabColDef     0x10   /* Last column where last defined expression */
#define epTabColUndef   0x20   /* Last column where first undefined expression */
#define epTabColMax     0x30   /* maxcol determinates number of columns */





/*
    Escape modes
*/


enum tEscMode
    {
    escNone = 0,
    escHtml = 1,
    escUrl  = 2,
    escStd  = 3,
    escEscape  = 4
    } ;


#if !defined (pid_t) && defined (WIN32)
#define pid_t int
#endif

extern pid_t nPid ;

