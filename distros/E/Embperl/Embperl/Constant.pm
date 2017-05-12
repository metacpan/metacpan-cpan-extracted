
###################################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2014 Gerald Richter
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: Constant.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################


package Embperl::Constant ;



use constant dbgAll                 => -1 ;
use constant dbgAllCmds             => 1024 ;
use constant dbgCmd                 => 8 ;
use constant dbgDefEval             => 16384 ;
use constant dbgEnv                 => 16 ;
use constant dbgEval                => 4 ;
use constant dbgFlushLog            => 512 ;
use constant dbgFlushOutput         => 256 ;
use constant dbgForm                => 32 ;
use constant dbgFunc                => 4096 ;
use constant dbgHeadersIn           => 262144 ;
use constant dbgImport              => 0x400000 ;
use constant dbgInput               => 128 ;
use constant dbgLogLink             => 8192 ;
use constant dbgMem                 => 2 ;
use constant dbgProfile             => 0x100000 ;
use constant dbgShowCleanup         => 524288 ;
use constant dbgSource              => 2048 ;
use constant dbgStd                 => 1 ;
use constant dbgSession             => 0x200000 ;
use constant dbgTab                 => 64 ;
use constant dbgParse               => 0x1000000 ; 
use constant dbgObjectSearch        => 0x2000000 ;
use constant dbgDOM                 => 0x10000 ;
use constant dbgOutput              => 0x08000 ;
use constant dbgRun                 => 0x20000 ;
use constant dbgCache               => 0x4000000 ;
use constant dbgCompile             => 0x8000000 ;
use constant dbgXML                 => 0x10000000 ;
use constant dbgXSLT                => 0x20000000 ;
use constant dbgCheckpoint          => 0x40000000 ;

use constant epIOCGI                => 1 ;
use constant epIOMod_Perl           => 3 ;
use constant epIOPerl               => 4 ;
use constant epIOProcess            => 2 ;

use constant escHtml                => 1 ;
use constant escNone                => 0 ;
use constant escStd                 => 3 ;
use constant escUrl                 => 2 ;
use constant escEscape              => 4 ;
use constant escXML                 => 8 ;


use constant optDisableChdir            => 128 ;
use constant optDisableEmbperlErrorPage => 2 ;
use constant optReturnError	        => 0x40000 ;
use constant optDisableFormData         => 256 ;
use constant optDisableHtmlScan         => 512 ;
use constant optDisableInputScan        => 1024 ;
use constant optDisableMetaScan         => 4096 ;
use constant optDisableTableScan        => 2048 ;
use constant optDisableSelectScan       => 0x800000 ;
use constant optDisableVarCleanup       => 1 ;
use constant optEarlyHttpHeader         => 64 ;
use constant optOpcodeMask              => 8 ;
use constant optRawInput                => 16 ;
use constant optSafeNamespace           => 4 ;
use constant optSendHttpHeader          => 32 ;
use constant optAllFormData             => 8192 ;
use constant optRedirectStdout          => 16384 ;
use constant optUndefToEmptyValue       => 32768 ;
use constant optNoHiddenEmptyValue      => 0x10000 ;
use constant optAllowZeroFilesize       => 0x20000 ;
use constant optKeepSrcInMemory         => 0x80000 ;
use constant optKeepSpaces	        => 0x100000 ;
use constant optOpenLogEarly            => 0x200000 ;
use constant optNoUncloseWarn	        => 0x400000 ;
use constant optShowBacktrace           => 0x8000000 ;


use constant ok                     => 0 ;
use constant rcArgStackOverflow => 23 ;
use constant rcArrayError => 11 ;
use constant rcCannotUsedRecursive => 19 ;
use constant rcCleanupErr => 50 ;
use constant rcCmdNotFound => 7 ;
use constant rcElseWithoutIf => 4 ;
use constant rcEndifWithoutIf => 3 ;
use constant rcEndtableWithoutTable => 6 ;
use constant rcEndtableWithoutTablerow => 20 ;
use constant rcEndtextareaWithoutTextarea => 22 ;
use constant rcEndwhileWithoutWhile => 5 ;
use constant rcEvalErr => 24 ;
use constant rcExecCGIMissing => 27 ;
use constant rcFileOpenErr => 12 ;
use constant rcHashError => 10 ;
use constant rcInputNotSupported => 18 ;
use constant rcIsDir => 28 ;
use constant rcLogFileOpenErr => 26 ;
use constant rcMagicError => 15 ;
use constant rcMissingRight => 13 ;
use constant rcNoRetFifo => 14 ;
use constant rcNotCompiledForModPerl => 25 ;
use constant rcNotFound => 404 ;
use constant rcOutOfMemory => 8 ;
use constant rcPerlVarError => 9 ;
use constant rcPerlWarn => 32 ;
use constant rcStackOverflow => 1 ;
use constant rcStackUnderflow => 2 ;
use constant rcUnknownNameSpace => 17 ;
use constant rcUnknownVarType => 31 ;
use constant rcVirtLogNotSet => 33 ;
use constant rcWriteErr => 16 ;
use constant rcXNotSet => 29 ;
use constant rcCallInputFuncFailed => 40 ;
use constant rcCallOutputFuncFailed => 41 ;
use constant rcSubNotFound => 42 ;
use constant rcImportStashErr => 43 ;
use constant rcCGIError => 44 ;
use constant rcUnclosedHtml => 45 ;
use constant rcUnclosedCmd => 46 ;
use constant rcNotAllowed => 47 ;
use constant rcForbidden => 401 ;

1; 
