
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
#   $Id: embperl.h 1578075 2014-03-16 14:01:14Z richter $
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
    rcDummy,
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
    rcCryptoErr,
    rcUnknownProvider,
    rcXalanError,
    rcLibXSLTError,
    rcMissingParam,
    rcNotCodeRef,
    rcUnknownRecipe,
    rcTypeMismatch,
    rcChdirError,
    rcUnknownSyntax,
    rcCannotCheckUri,
    rcSetupSessionErr,
    rcRefcntNotOne,
    rcApacheErr,
    rcTooDeepNested,
    rcUnknownOption,
    rcTimeFormatErr,
    rcSubCallNotRequest,
    rcTokenNotFound,  
    rcNotScalarRef,
    rcForbidden = 403,
    rcNotFound  = 404,
    rcDecline   = -1
    } ;


/*
    Debug Flags
*/

enum dbg
    {
    dbgNone	    = 0,
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
    optEnableChdir             = 0x1000000,
    optFormDataNoUtf8          = 0x2000000,
    optShowBacktrace           = 0x8000000,
    optChdirToSource           = 0x10000000
    } ;

/* --- output escaping --- */

enum tEscMode
    {
    escNone     = 0,
    escHtml     = 1,
    escUrl      = 2,
    escEscape   = 4,
    escXML      = 8,

    escStd      = 7,
    
    escHtmlUtf8 = 128
    } ;

/* --- output mode --- */

enum tOutputMode
    {
    omodeHtml   = 0,
    omodeXml    = 1,
    } ;

/* --- output esc charset --- */

enum tOutputEscChareset
    {
    ocharsetUtf8  = 0,
    ocharsetLatin1  = 1,
    ocharsetLatin2  = 2,
    } ;

/* --- input escaping --- */

enum tInputEscMode
    {
    iescNone        = 0,
    iescHtml        = 1,
    iescUrl         = 2,
    iescRemoveTags  = 4,
    } ;


/* --- session handling --- */

enum tSessionMode
    {
    smodeNone       = 0,
    smodeUDatCookie = 1,
    smodeUDatParam  = 2,
    smodeUDatUrl    = 4,

    smodeSDatParam  = 0x20
    } ;

#define smodeStd smodeUDatCookie 

/* --- misc --- */

#if !defined (pid_t) && defined (WIN32)
#define pid_t int
#endif

extern pid_t nPid ;

#ifdef WIN32
#define PATH_SEPARATOR_CHAR '\\' 
#define PATH_SEPARATOR_STR  "\\"
#else
#define PATH_SEPARATOR_CHAR '/' 
#define PATH_SEPARATOR_STR  "/"
#endif 

