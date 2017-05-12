#include "template-hsc.h"
#line 15 "Signals.hsc"
#include "config.h"
#line 18 "Signals.hsc"
#ifndef mingw32_TARGET_OS
#line 44 "Signals.hsc"
#if HAVE_SIGPOLL
#line 46 "Signals.hsc"
#endif 
#line 60 "Signals.hsc"
#ifdef __GLASGOW_HASKELL__
#line 64 "Signals.hsc"
#endif 
#line 80 "Signals.hsc"
#ifdef __GLASGOW_HASKELL__
#line 83 "Signals.hsc"
#endif 
#line 91 "Signals.hsc"
#endif 
#line 94 "Signals.hsc"
#ifdef __GLASGOW_HASKELL__
#line 95 "Signals.hsc"
#include "Signals.h"
#line 96 "Signals.hsc"
#else 
#line 97 "Signals.hsc"
#include "HsBase.h"
#line 98 "Signals.hsc"
#endif 
#line 106 "Signals.hsc"
#ifndef mingw32_TARGET_OS
#line 117 "Signals.hsc"
#ifdef __HUGS__
#line 138 "Signals.hsc"
#if HAVE_SIGPOLL
#line 140 "Signals.hsc"
#endif 
#line 148 "Signals.hsc"
#else 
#line 169 "Signals.hsc"
#if HAVE_SIGPOLL
#line 171 "Signals.hsc"
#endif 
#line 179 "Signals.hsc"
#endif /* __HUGS__ */
#line 193 "Signals.hsc"
#ifndef cygwin32_TARGET_OS
#line 196 "Signals.hsc"
#endif 
#line 243 "Signals.hsc"
#if HAVE_SIGPOLL
#line 246 "Signals.hsc"
#endif 
#line 292 "Signals.hsc"
#ifdef __GLASGOW_HASKELL__
#line 304 "Signals.hsc"
#ifdef __PARALLEL_HASKELL__
#line 307 "Signals.hsc"
#else 
#line 347 "Signals.hsc"
#endif /* !__PARALLEL_HASKELL__ */
#line 348 "Signals.hsc"
#endif /* __GLASGOW_HASKELL__ */
#line 361 "Signals.hsc"
#ifdef __GLASGOW_HASKELL__
#line 382 "Signals.hsc"
#endif /* __GLASGOW_HASKELL__ */
#line 454 "Signals.hsc"
#ifndef cygwin32_TARGET_OS
#line 468 "Signals.hsc"
#endif 
#line 470 "Signals.hsc"
#ifdef __HUGS__
#line 479 "Signals.hsc"
#else 
#line 488 "Signals.hsc"
#endif /* __HUGS__ */
#line 493 "Signals.hsc"
#ifdef __HUGS__
#line 497 "Signals.hsc"
#else 
#line 501 "Signals.hsc"
#endif /* __HUGS__ */
#line 503 "Signals.hsc"
#endif /* mingw32_TARGET_OS */

int main (int argc, char *argv [])
{
#if __GLASGOW_HASKELL__ && __GLASGOW_HASKELL__ < 409
    printf ("{-# OPTIONS -optc-D__GLASGOW_HASKELL__=%d #-}\n", 603);
#endif
    printf ("{-# OPTIONS %s #-}\n", "-#include \"config.h\"");
#line 18 "Signals.hsc"
#ifndef mingw32_TARGET_OS
#line 44 "Signals.hsc"
#if HAVE_SIGPOLL
#line 46 "Signals.hsc"
#endif 
#line 60 "Signals.hsc"
#ifdef __GLASGOW_HASKELL__
#line 64 "Signals.hsc"
#endif 
#line 80 "Signals.hsc"
#ifdef __GLASGOW_HASKELL__
#line 83 "Signals.hsc"
#endif 
#line 91 "Signals.hsc"
#endif 
#line 94 "Signals.hsc"
#ifdef __GLASGOW_HASKELL__
    printf ("{-# OPTIONS %s #-}\n", "-#include \"Signals.h\"");
#line 96 "Signals.hsc"
#else 
    printf ("{-# OPTIONS %s #-}\n", "-#include \"HsBase.h\"");
#line 98 "Signals.hsc"
#endif 
#line 106 "Signals.hsc"
#ifndef mingw32_TARGET_OS
#line 117 "Signals.hsc"
#ifdef __HUGS__
#line 138 "Signals.hsc"
#if HAVE_SIGPOLL
#line 140 "Signals.hsc"
#endif 
#line 148 "Signals.hsc"
#else 
#line 169 "Signals.hsc"
#if HAVE_SIGPOLL
#line 171 "Signals.hsc"
#endif 
#line 179 "Signals.hsc"
#endif /* __HUGS__ */
#line 193 "Signals.hsc"
#ifndef cygwin32_TARGET_OS
#line 196 "Signals.hsc"
#endif 
#line 243 "Signals.hsc"
#if HAVE_SIGPOLL
#line 246 "Signals.hsc"
#endif 
#line 292 "Signals.hsc"
#ifdef __GLASGOW_HASKELL__
#line 304 "Signals.hsc"
#ifdef __PARALLEL_HASKELL__
#line 307 "Signals.hsc"
#else 
#line 347 "Signals.hsc"
#endif /* !__PARALLEL_HASKELL__ */
#line 348 "Signals.hsc"
#endif /* __GLASGOW_HASKELL__ */
#line 361 "Signals.hsc"
#ifdef __GLASGOW_HASKELL__
#line 382 "Signals.hsc"
#endif /* __GLASGOW_HASKELL__ */
#line 454 "Signals.hsc"
#ifndef cygwin32_TARGET_OS
#line 468 "Signals.hsc"
#endif 
#line 470 "Signals.hsc"
#ifdef __HUGS__
#line 479 "Signals.hsc"
#else 
#line 488 "Signals.hsc"
#endif /* __HUGS__ */
#line 493 "Signals.hsc"
#ifdef __HUGS__
#line 497 "Signals.hsc"
#else 
#line 501 "Signals.hsc"
#endif /* __HUGS__ */
#line 503 "Signals.hsc"
#endif /* mingw32_TARGET_OS */
    hsc_line (1, "Signals.hsc");
    fputs ("-----------------------------------------------------------------------------\n"
           "", stdout);
    hsc_line (2, "Signals.hsc");
    fputs ("-- |\n"
           "-- Module      :  System.Posix.Signals\n"
           "-- Copyright   :  (c) The University of Glasgow 2002\n"
           "-- License     :  BSD-style (see the file libraries/base/LICENSE)\n"
           "-- \n"
           "-- Maintainer  :  libraries@haskell.org\n"
           "-- Stability   :  provisional\n"
           "-- Portability :  non-portable (requires POSIX)\n"
           "--\n"
           "-- POSIX signal support\n"
           "--\n"
           "-----------------------------------------------------------------------------\n"
           "\n"
           "", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (16, "Signals.hsc");
    fputs ("\n"
           "module System.Posix.Signals (\n"
           "", stdout);
#line 18 "Signals.hsc"
#ifndef mingw32_TARGET_OS
    fputs ("\n"
           "", stdout);
    hsc_line (19, "Signals.hsc");
    fputs ("  -- * The Signal type\n"
           "  Signal,\n"
           "\n"
           "  -- * Specific signals\n"
           "  nullSignal,\n"
           "  internalAbort, sigABRT,\n"
           "  realTimeAlarm, sigALRM,\n"
           "  busError, sigBUS,\n"
           "  processStatusChanged, sigCHLD,\n"
           "  continueProcess, sigCONT,\n"
           "  floatingPointException, sigFPE,\n"
           "  lostConnection, sigHUP,\n"
           "  illegalInstruction, sigILL,\n"
           "  keyboardSignal, sigINT,\n"
           "  killProcess, sigKILL,\n"
           "  openEndedPipe, sigPIPE,\n"
           "  keyboardTermination, sigQUIT,\n"
           "  segmentationViolation, sigSEGV,\n"
           "  softwareStop, sigSTOP,\n"
           "  softwareTermination, sigTERM,\n"
           "  keyboardStop, sigTSTP,\n"
           "  backgroundRead, sigTTIN,\n"
           "  backgroundWrite, sigTTOU,\n"
           "  userDefinedSignal1, sigUSR1,\n"
           "  userDefinedSignal2, sigUSR2,\n"
           "", stdout);
#line 44 "Signals.hsc"
#if HAVE_SIGPOLL
    fputs ("\n"
           "", stdout);
    hsc_line (45, "Signals.hsc");
    fputs ("  pollableEvent, sigPOLL,\n"
           "", stdout);
#line 46 "Signals.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (47, "Signals.hsc");
    fputs ("  profilingTimerExpired, sigPROF,\n"
           "  badSystemCall, sigSYS,\n"
           "  breakpointTrap, sigTRAP,\n"
           "  urgentDataAvailable, sigURG,\n"
           "  virtualTimerExpired, sigVTALRM,\n"
           "  cpuTimeLimitExceeded, sigXCPU,\n"
           "  fileSizeLimitExceeded, sigXFSZ,\n"
           "\n"
           "  -- * Sending signals\n"
           "  raiseSignal,\n"
           "  signalProcess,\n"
           "  signalProcessGroup,\n"
           "\n"
           "", stdout);
#line 60 "Signals.hsc"
#ifdef __GLASGOW_HASKELL__
    fputs ("\n"
           "", stdout);
    hsc_line (61, "Signals.hsc");
    fputs ("  -- * Handling signals\n"
           "  Handler(..),\n"
           "  installHandler,\n"
           "", stdout);
#line 64 "Signals.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (65, "Signals.hsc");
    fputs ("\n"
           "  -- * Signal sets\n"
           "  SignalSet,\n"
           "  emptySignalSet, fullSignalSet, \n"
           "  addSignal, deleteSignal, inSignalSet,\n"
           "\n"
           "  -- * The process signal mask\n"
           "  getSignalMask, setSignalMask, blockSignals, unblockSignals,\n"
           "\n"
           "  -- * The alarm timer\n"
           "  scheduleAlarm,\n"
           "\n"
           "  -- * Waiting for signals\n"
           "  getPendingSignals, awaitSignal,\n"
           "\n"
           "", stdout);
#line 80 "Signals.hsc"
#ifdef __GLASGOW_HASKELL__
    fputs ("\n"
           "", stdout);
    hsc_line (81, "Signals.hsc");
    fputs ("  -- * The @NOCLDSTOP@ flag\n"
           "  setStoppedChildFlag, queryStoppedChildFlag,\n"
           "", stdout);
#line 83 "Signals.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (84, "Signals.hsc");
    fputs ("\n"
           "  -- MISSING FUNCTIONALITY:\n"
           "  -- sigaction(), (inc. the sigaction structure + flags etc.)\n"
           "  -- the siginfo structure\n"
           "  -- sigaltstack()\n"
           "  -- sighold, sigignore, sigpause, sigrelse, sigset\n"
           "  -- siginterrupt\n"
           "", stdout);
#line 91 "Signals.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (92, "Signals.hsc");
    fputs ("  ) where\n"
           "\n"
           "", stdout);
#line 94 "Signals.hsc"
#ifdef __GLASGOW_HASKELL__
    fputs ("\n"
           "", stdout);
    hsc_line (95, "Signals.hsc");
    fputs ("", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (96, "Signals.hsc");
    fputs ("", stdout);
#line 96 "Signals.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (97, "Signals.hsc");
    fputs ("", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (98, "Signals.hsc");
    fputs ("", stdout);
#line 98 "Signals.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (99, "Signals.hsc");
    fputs ("\n"
           "import Foreign\n"
           "import Foreign.C\n"
           "import System.IO.Unsafe\n"
           "import System.Posix.Types\n"
           "import System.Posix.Internals\n"
           "\n"
           "", stdout);
#line 106 "Signals.hsc"
#ifndef mingw32_TARGET_OS
    fputs ("\n"
           "", stdout);
    hsc_line (107, "Signals.hsc");
    fputs ("-- WHOLE FILE...\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Specific signals\n"
           "\n"
           "type Signal = CInt\n"
           "\n"
           "nullSignal :: Signal\n"
           "nullSignal = 0\n"
           "\n"
           "", stdout);
#line 117 "Signals.hsc"
#ifdef __HUGS__
    fputs ("\n"
           "", stdout);
    hsc_line (118, "Signals.hsc");
    fputs ("sigABRT   = (", stdout);
#line 118 "Signals.hsc"
    hsc_const (SIGABRT);
    fputs (")   :: CInt\n"
           "", stdout);
    hsc_line (119, "Signals.hsc");
    fputs ("sigALRM   = (", stdout);
#line 119 "Signals.hsc"
    hsc_const (SIGALRM);
    fputs (")   :: CInt\n"
           "", stdout);
    hsc_line (120, "Signals.hsc");
    fputs ("sigBUS    = (", stdout);
#line 120 "Signals.hsc"
    hsc_const (SIGBUS);
    fputs (")    :: CInt\n"
           "", stdout);
    hsc_line (121, "Signals.hsc");
    fputs ("sigCHLD   = (", stdout);
#line 121 "Signals.hsc"
    hsc_const (SIGCHLD);
    fputs (")   :: CInt\n"
           "", stdout);
    hsc_line (122, "Signals.hsc");
    fputs ("sigCONT   = (", stdout);
#line 122 "Signals.hsc"
    hsc_const (SIGCONT);
    fputs (")   :: CInt\n"
           "", stdout);
    hsc_line (123, "Signals.hsc");
    fputs ("sigFPE    = (", stdout);
#line 123 "Signals.hsc"
    hsc_const (SIGFPE);
    fputs (")    :: CInt\n"
           "", stdout);
    hsc_line (124, "Signals.hsc");
    fputs ("sigHUP    = (", stdout);
#line 124 "Signals.hsc"
    hsc_const (SIGHUP);
    fputs (")    :: CInt\n"
           "", stdout);
    hsc_line (125, "Signals.hsc");
    fputs ("sigILL    = (", stdout);
#line 125 "Signals.hsc"
    hsc_const (SIGILL);
    fputs (")    :: CInt\n"
           "", stdout);
    hsc_line (126, "Signals.hsc");
    fputs ("sigINT    = (", stdout);
#line 126 "Signals.hsc"
    hsc_const (SIGINT);
    fputs (")    :: CInt\n"
           "", stdout);
    hsc_line (127, "Signals.hsc");
    fputs ("sigKILL   = (", stdout);
#line 127 "Signals.hsc"
    hsc_const (SIGKILL);
    fputs (")   :: CInt\n"
           "", stdout);
    hsc_line (128, "Signals.hsc");
    fputs ("sigPIPE   = (", stdout);
#line 128 "Signals.hsc"
    hsc_const (SIGPIPE);
    fputs (")   :: CInt\n"
           "", stdout);
    hsc_line (129, "Signals.hsc");
    fputs ("sigQUIT   = (", stdout);
#line 129 "Signals.hsc"
    hsc_const (SIGQUIT);
    fputs (")   :: CInt\n"
           "", stdout);
    hsc_line (130, "Signals.hsc");
    fputs ("sigSEGV   = (", stdout);
#line 130 "Signals.hsc"
    hsc_const (SIGSEGV);
    fputs (")   :: CInt\n"
           "", stdout);
    hsc_line (131, "Signals.hsc");
    fputs ("sigSTOP   = (", stdout);
#line 131 "Signals.hsc"
    hsc_const (SIGSTOP);
    fputs (")   :: CInt\n"
           "", stdout);
    hsc_line (132, "Signals.hsc");
    fputs ("sigTERM   = (", stdout);
#line 132 "Signals.hsc"
    hsc_const (SIGTERM);
    fputs (")   :: CInt\n"
           "", stdout);
    hsc_line (133, "Signals.hsc");
    fputs ("sigTSTP   = (", stdout);
#line 133 "Signals.hsc"
    hsc_const (SIGTSTP);
    fputs (")   :: CInt\n"
           "", stdout);
    hsc_line (134, "Signals.hsc");
    fputs ("sigTTIN   = (", stdout);
#line 134 "Signals.hsc"
    hsc_const (SIGTTIN);
    fputs (")   :: CInt\n"
           "", stdout);
    hsc_line (135, "Signals.hsc");
    fputs ("sigTTOU   = (", stdout);
#line 135 "Signals.hsc"
    hsc_const (SIGTTOU);
    fputs (")   :: CInt\n"
           "", stdout);
    hsc_line (136, "Signals.hsc");
    fputs ("sigUSR1   = (", stdout);
#line 136 "Signals.hsc"
    hsc_const (SIGUSR1);
    fputs (")   :: CInt\n"
           "", stdout);
    hsc_line (137, "Signals.hsc");
    fputs ("sigUSR2   = (", stdout);
#line 137 "Signals.hsc"
    hsc_const (SIGUSR2);
    fputs (")   :: CInt\n"
           "", stdout);
    hsc_line (138, "Signals.hsc");
    fputs ("", stdout);
#line 138 "Signals.hsc"
#if HAVE_SIGPOLL
    fputs ("\n"
           "", stdout);
    hsc_line (139, "Signals.hsc");
    fputs ("sigPOLL   = (", stdout);
#line 139 "Signals.hsc"
    hsc_const (SIGPOLL);
    fputs (")   :: CInt\n"
           "", stdout);
    hsc_line (140, "Signals.hsc");
    fputs ("", stdout);
#line 140 "Signals.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (141, "Signals.hsc");
    fputs ("sigPROF   = (", stdout);
#line 141 "Signals.hsc"
    hsc_const (SIGPROF);
    fputs (")   :: CInt\n"
           "", stdout);
    hsc_line (142, "Signals.hsc");
    fputs ("sigSYS    = (", stdout);
#line 142 "Signals.hsc"
    hsc_const (SIGSYS);
    fputs (")    :: CInt\n"
           "", stdout);
    hsc_line (143, "Signals.hsc");
    fputs ("sigTRAP   = (", stdout);
#line 143 "Signals.hsc"
    hsc_const (SIGTRAP);
    fputs (")   :: CInt\n"
           "", stdout);
    hsc_line (144, "Signals.hsc");
    fputs ("sigURG    = (", stdout);
#line 144 "Signals.hsc"
    hsc_const (SIGURG);
    fputs (")    :: CInt\n"
           "", stdout);
    hsc_line (145, "Signals.hsc");
    fputs ("sigVTALRM = (", stdout);
#line 145 "Signals.hsc"
    hsc_const (SIGVTALRM);
    fputs (") :: CInt\n"
           "", stdout);
    hsc_line (146, "Signals.hsc");
    fputs ("sigXCPU   = (", stdout);
#line 146 "Signals.hsc"
    hsc_const (SIGXCPU);
    fputs (")   :: CInt\n"
           "", stdout);
    hsc_line (147, "Signals.hsc");
    fputs ("sigXFSZ   = (", stdout);
#line 147 "Signals.hsc"
    hsc_const (SIGXFSZ);
    fputs (")   :: CInt\n"
           "", stdout);
    hsc_line (148, "Signals.hsc");
    fputs ("", stdout);
#line 148 "Signals.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (149, "Signals.hsc");
    fputs ("foreign import ccall unsafe \"__hsposix_SIGABRT\"   sigABRT   :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIGALRM\"   sigALRM   :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIGBUS\"    sigBUS    :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIGCHLD\"   sigCHLD   :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIGCONT\"   sigCONT   :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIGFPE\"    sigFPE    :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIGHUP\"    sigHUP    :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIGILL\"    sigILL    :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIGINT\"    sigINT    :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIGKILL\"   sigKILL   :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIGPIPE\"   sigPIPE   :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIGQUIT\"   sigQUIT   :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIGSEGV\"   sigSEGV   :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIGSTOP\"   sigSTOP   :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIGTERM\"   sigTERM   :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIGTSTP\"   sigTSTP   :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIGTTIN\"   sigTTIN   :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIGTTOU\"   sigTTOU   :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIGUSR1\"   sigUSR1   :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIGUSR2\"   sigUSR2   :: CInt\n"
           "", stdout);
#line 169 "Signals.hsc"
#if HAVE_SIGPOLL
    fputs ("\n"
           "", stdout);
    hsc_line (170, "Signals.hsc");
    fputs ("foreign import ccall unsafe \"__hsposix_SIGPOLL\"   sigPOLL   :: CInt\n"
           "", stdout);
#line 171 "Signals.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (172, "Signals.hsc");
    fputs ("foreign import ccall unsafe \"__hsposix_SIGPROF\"   sigPROF   :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIGSYS\"    sigSYS    :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIGTRAP\"   sigTRAP   :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIGURG\"    sigURG    :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIGVTALRM\" sigVTALRM :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIGXCPU\"   sigXCPU   :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIGXFSZ\"   sigXFSZ   :: CInt\n"
           "", stdout);
#line 179 "Signals.hsc"
#endif /* __HUGS__ */
    fputs ("\n"
           "", stdout);
    hsc_line (180, "Signals.hsc");
    fputs ("\n"
           "internalAbort ::Signal\n"
           "internalAbort = sigABRT\n"
           "\n"
           "realTimeAlarm :: Signal\n"
           "realTimeAlarm = sigALRM\n"
           "\n"
           "busError :: Signal\n"
           "busError = sigBUS\n"
           "\n"
           "processStatusChanged :: Signal\n"
           "processStatusChanged = sigCHLD\n"
           "\n"
           "", stdout);
#line 193 "Signals.hsc"
#ifndef cygwin32_TARGET_OS
    fputs ("\n"
           "", stdout);
    hsc_line (194, "Signals.hsc");
    fputs ("continueProcess :: Signal\n"
           "continueProcess = sigCONT\n"
           "", stdout);
#line 196 "Signals.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (197, "Signals.hsc");
    fputs ("\n"
           "floatingPointException :: Signal\n"
           "floatingPointException = sigFPE\n"
           "\n"
           "lostConnection :: Signal\n"
           "lostConnection = sigHUP\n"
           "\n"
           "illegalInstruction :: Signal\n"
           "illegalInstruction = sigILL\n"
           "\n"
           "keyboardSignal :: Signal\n"
           "keyboardSignal = sigINT\n"
           "\n"
           "killProcess :: Signal\n"
           "killProcess = sigKILL\n"
           "\n"
           "openEndedPipe :: Signal\n"
           "openEndedPipe = sigPIPE\n"
           "\n"
           "keyboardTermination :: Signal\n"
           "keyboardTermination = sigQUIT\n"
           "\n"
           "segmentationViolation :: Signal\n"
           "segmentationViolation = sigSEGV\n"
           "\n"
           "softwareStop :: Signal\n"
           "softwareStop = sigSTOP\n"
           "\n"
           "softwareTermination :: Signal\n"
           "softwareTermination = sigTERM\n"
           "\n"
           "keyboardStop :: Signal\n"
           "keyboardStop = sigTSTP\n"
           "\n"
           "backgroundRead :: Signal\n"
           "backgroundRead = sigTTIN\n"
           "\n"
           "backgroundWrite :: Signal\n"
           "backgroundWrite = sigTTOU\n"
           "\n"
           "userDefinedSignal1 :: Signal\n"
           "userDefinedSignal1 = sigUSR1\n"
           "\n"
           "userDefinedSignal2 :: Signal\n"
           "userDefinedSignal2 = sigUSR2\n"
           "\n"
           "", stdout);
#line 243 "Signals.hsc"
#if HAVE_SIGPOLL
    fputs ("\n"
           "", stdout);
    hsc_line (244, "Signals.hsc");
    fputs ("pollableEvent :: Signal\n"
           "pollableEvent = sigPOLL\n"
           "", stdout);
#line 246 "Signals.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (247, "Signals.hsc");
    fputs ("\n"
           "profilingTimerExpired :: Signal\n"
           "profilingTimerExpired = sigPROF\n"
           "\n"
           "badSystemCall :: Signal\n"
           "badSystemCall = sigSYS\n"
           "\n"
           "breakpointTrap :: Signal\n"
           "breakpointTrap = sigTRAP\n"
           "\n"
           "urgentDataAvailable :: Signal\n"
           "urgentDataAvailable = sigURG\n"
           "\n"
           "virtualTimerExpired :: Signal\n"
           "virtualTimerExpired = sigVTALRM\n"
           "\n"
           "cpuTimeLimitExceeded :: Signal\n"
           "cpuTimeLimitExceeded = sigXCPU\n"
           "\n"
           "fileSizeLimitExceeded :: Signal\n"
           "fileSizeLimitExceeded = sigXFSZ\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Signal-related functions\n"
           "\n"
           "signalProcess :: Signal -> ProcessID -> IO ()\n"
           "signalProcess sig pid \n"
           " = throwErrnoIfMinus1_ \"signalProcess\" (c_kill (fromIntegral pid) sig)\n"
           "\n"
           "foreign import ccall unsafe \"kill\"\n"
           "  c_kill :: CPid -> CInt -> IO CInt\n"
           "\n"
           "signalProcessGroup :: Signal -> ProcessGroupID -> IO ()\n"
           "signalProcessGroup sig pgid \n"
           "  = throwErrnoIfMinus1_ \"signalProcessGroup\" (c_killpg (fromIntegral pgid) sig)\n"
           "\n"
           "foreign import ccall unsafe \"killpg\"\n"
           "  c_killpg :: CPid -> CInt -> IO CInt\n"
           "\n"
           "raiseSignal :: Signal -> IO ()\n"
           "raiseSignal sig = throwErrnoIfMinus1_ \"raiseSignal\" (c_raise sig)\n"
           "\n"
           "foreign import ccall unsafe \"raise\"\n"
           "  c_raise :: CInt -> IO CInt\n"
           "\n"
           "", stdout);
#line 292 "Signals.hsc"
#ifdef __GLASGOW_HASKELL__
    fputs ("\n"
           "", stdout);
    hsc_line (293, "Signals.hsc");
    fputs ("data Handler = Default\n"
           "             | Ignore\n"
           "\t     -- not yet: | Hold \n"
           "             | Catch (IO ())\n"
           "             | CatchOnce (IO ())\n"
           "\n"
           "installHandler :: Signal\n"
           "               -> Handler\n"
           "               -> Maybe SignalSet\t-- other signals to block\n"
           "               -> IO Handler\t\t-- old handler\n"
           "\n"
           "", stdout);
#line 304 "Signals.hsc"
#ifdef __PARALLEL_HASKELL__
    fputs ("\n"
           "", stdout);
    hsc_line (305, "Signals.hsc");
    fputs ("installHandler = \n"
           "  error \"installHandler: not available for Parallel Haskell\"\n"
           "", stdout);
#line 307 "Signals.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (308, "Signals.hsc");
    fputs ("\n"
           "installHandler int handler maybe_mask = do\n"
           "    case maybe_mask of\n"
           "\tNothing -> install\' nullPtr\n"
           "        Just (SignalSet x) -> withForeignPtr x $ install\' \n"
           "  where \n"
           "    install\' mask = \n"
           "      alloca $ \\p_sp -> do\n"
           "\n"
           "      rc <- case handler of\n"
           "      \t      Default -> stg_sig_install int (", stdout);
#line 318 "Signals.hsc"
    hsc_const (STG_SIG_DFL);
    fputs (") p_sp mask\n"
           "", stdout);
    hsc_line (319, "Signals.hsc");
    fputs ("      \t      Ignore  -> stg_sig_install int (", stdout);
#line 319 "Signals.hsc"
    hsc_const (STG_SIG_IGN);
    fputs (") p_sp mask\n"
           "", stdout);
    hsc_line (320, "Signals.hsc");
    fputs ("      \t      Catch m -> install\'\' m p_sp mask int (", stdout);
#line 320 "Signals.hsc"
    hsc_const (STG_SIG_HAN);
    fputs (")\n"
           "", stdout);
    hsc_line (321, "Signals.hsc");
    fputs ("      \t      CatchOnce m -> install\'\' m p_sp mask int (", stdout);
#line 321 "Signals.hsc"
    hsc_const (STG_SIG_RST);
    fputs (")\n"
           "", stdout);
    hsc_line (322, "Signals.hsc");
    fputs ("\n"
           "      case rc of\n"
           "\t(", stdout);
#line 324 "Signals.hsc"
    hsc_const (STG_SIG_DFL);
    fputs (") -> return Default\n"
           "", stdout);
    hsc_line (325, "Signals.hsc");
    fputs ("\t(", stdout);
#line 325 "Signals.hsc"
    hsc_const (STG_SIG_IGN);
    fputs (") -> return Ignore\n"
           "", stdout);
    hsc_line (326, "Signals.hsc");
    fputs ("\t(", stdout);
#line 326 "Signals.hsc"
    hsc_const (STG_SIG_ERR);
    fputs (") -> throwErrno \"installHandler\"\n"
           "", stdout);
    hsc_line (327, "Signals.hsc");
    fputs ("\t(", stdout);
#line 327 "Signals.hsc"
    hsc_const (STG_SIG_HAN);
    fputs (") -> do\n"
           "", stdout);
    hsc_line (328, "Signals.hsc");
    fputs ("        \tm <- peekHandler p_sp\n"
           "\t\treturn (Catch m)\n"
           "\t(", stdout);
#line 330 "Signals.hsc"
    hsc_const (STG_SIG_RST);
    fputs (") -> do\n"
           "", stdout);
    hsc_line (331, "Signals.hsc");
    fputs ("        \tm <- peekHandler p_sp\n"
           "\t\treturn (CatchOnce m)\n"
           "\n"
           "    install\'\' m p_sp mask int reset = do\n"
           "      sptr <- newStablePtr m\n"
           "      poke p_sp sptr\n"
           "      stg_sig_install int reset p_sp mask\n"
           "\n"
           "    peekHandler p_sp = do\n"
           "      osptr <- peek p_sp\n"
           "      deRefStablePtr osptr\n"
           "\n"
           "foreign import ccall unsafe\n"
           "  stg_sig_install :: CInt -> CInt -> Ptr (StablePtr (IO ())) -> Ptr CSigset\n"
           "\t -> IO CInt\n"
           "\n"
           "", stdout);
#line 347 "Signals.hsc"
#endif /* !__PARALLEL_HASKELL__ */
    fputs ("\n"
           "", stdout);
    hsc_line (348, "Signals.hsc");
    fputs ("", stdout);
#line 348 "Signals.hsc"
#endif /* __GLASGOW_HASKELL__ */
    fputs ("\n"
           "", stdout);
    hsc_line (349, "Signals.hsc");
    fputs ("\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Alarms\n"
           "\n"
           "scheduleAlarm :: Int -> IO Int\n"
           "scheduleAlarm secs = do\n"
           "   r <- c_alarm (fromIntegral secs)\n"
           "   return (fromIntegral r)\n"
           "\n"
           "foreign import ccall unsafe \"alarm\"\n"
           "  c_alarm :: CUInt -> IO CUInt\n"
           "\n"
           "", stdout);
#line 361 "Signals.hsc"
#ifdef __GLASGOW_HASKELL__
    fputs ("\n"
           "", stdout);
    hsc_line (362, "Signals.hsc");
    fputs ("-- -----------------------------------------------------------------------------\n"
           "-- The NOCLDSTOP flag\n"
           "\n"
           "foreign import ccall \"&nocldstop\" nocldstop :: Ptr Int\n"
           "\n"
           "-- | Tells the system whether or not to set the @SA_NOCLDSTOP@ flag when\n"
           "-- installing new signal handlers.\n"
           "setStoppedChildFlag :: Bool -> IO Bool\n"
           "setStoppedChildFlag b = do\n"
           "    rc <- peek nocldstop\n"
           "    poke nocldstop x\n"
           "    return (rc == (0::Int))\n"
           "  where\n"
           "    x = case b of {True -> 0; False -> 1}\n"
           "\n"
           "-- | Queries the current state of the stopped child flag.\n"
           "queryStoppedChildFlag :: IO Bool\n"
           "queryStoppedChildFlag = do\n"
           "    rc <- peek nocldstop\n"
           "    return (rc == (0::Int))\n"
           "", stdout);
#line 382 "Signals.hsc"
#endif /* __GLASGOW_HASKELL__ */
    fputs ("\n"
           "", stdout);
    hsc_line (383, "Signals.hsc");
    fputs ("\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Manipulating signal sets\n"
           "\n"
           "newtype SignalSet = SignalSet (ForeignPtr CSigset)\n"
           "\n"
           "emptySignalSet :: SignalSet\n"
           "emptySignalSet = unsafePerformIO $ do\n"
           "  fp <- mallocForeignPtrBytes sizeof_sigset_t\n"
           "  throwErrnoIfMinus1_ \"emptySignalSet\" (withForeignPtr fp $ c_sigemptyset)\n"
           "  return (SignalSet fp)\n"
           "\n"
           "fullSignalSet :: SignalSet\n"
           "fullSignalSet = unsafePerformIO $ do\n"
           "  fp <- mallocForeignPtrBytes sizeof_sigset_t\n"
           "  throwErrnoIfMinus1_ \"fullSignalSet\" (withForeignPtr fp $ c_sigfillset)\n"
           "  return (SignalSet fp)\n"
           "\n"
           "infixr `addSignal`, `deleteSignal`\n"
           "addSignal :: Signal -> SignalSet -> SignalSet\n"
           "addSignal sig (SignalSet fp1) = unsafePerformIO $ do\n"
           "  fp2 <- mallocForeignPtrBytes sizeof_sigset_t\n"
           "  withForeignPtr fp1 $ \\p1 ->\n"
           "    withForeignPtr fp2 $ \\p2 -> do\n"
           "      copyBytes p2 p1 sizeof_sigset_t\n"
           "      throwErrnoIfMinus1_ \"addSignal\" (c_sigaddset p2 sig)\n"
           "  return (SignalSet fp2)\n"
           "\n"
           "deleteSignal :: Signal -> SignalSet -> SignalSet\n"
           "deleteSignal sig (SignalSet fp1) = unsafePerformIO $ do\n"
           "  fp2 <- mallocForeignPtrBytes sizeof_sigset_t\n"
           "  withForeignPtr fp1 $ \\p1 ->\n"
           "    withForeignPtr fp2 $ \\p2 -> do\n"
           "      copyBytes p2 p1 sizeof_sigset_t\n"
           "      throwErrnoIfMinus1_ \"deleteSignal\" (c_sigdelset p2 sig)\n"
           "  return (SignalSet fp2)\n"
           "\n"
           "inSignalSet :: Signal -> SignalSet -> Bool\n"
           "inSignalSet sig (SignalSet fp) = unsafePerformIO $\n"
           "  withForeignPtr fp $ \\p -> do\n"
           "    r <- throwErrnoIfMinus1 \"inSignalSet\" (c_sigismember p sig)\n"
           "    return (r /= 0)\n"
           "\n"
           "getSignalMask :: IO SignalSet\n"
           "getSignalMask = do\n"
           "  fp <- mallocForeignPtrBytes sizeof_sigset_t\n"
           "  withForeignPtr fp $ \\p ->\n"
           "    throwErrnoIfMinus1_ \"getSignalMask\" (c_sigprocmask 0 nullPtr p)\n"
           "  return (SignalSet fp)\n"
           "   \n"
           "sigProcMask :: String -> CInt -> SignalSet -> IO ()\n"
           "sigProcMask fn how (SignalSet set) =\n"
           "  withForeignPtr set $ \\p_set ->\n"
           "    throwErrnoIfMinus1_ fn (c_sigprocmask how p_set nullPtr)\n"
           "  \n"
           "setSignalMask :: SignalSet -> IO ()\n"
           "setSignalMask set = sigProcMask \"setSignalMask\" c_SIG_SETMASK set\n"
           "\n"
           "blockSignals :: SignalSet -> IO ()\n"
           "blockSignals set = sigProcMask \"blockSignals\" c_SIG_BLOCK set\n"
           "\n"
           "unblockSignals :: SignalSet -> IO ()\n"
           "unblockSignals set = sigProcMask \"unblockSignals\" c_SIG_UNBLOCK set\n"
           "\n"
           "getPendingSignals :: IO SignalSet\n"
           "getPendingSignals = do\n"
           "  fp <- mallocForeignPtrBytes sizeof_sigset_t\n"
           "  withForeignPtr fp $ \\p -> \n"
           "   throwErrnoIfMinus1_ \"getPendingSignals\" (c_sigpending p)\n"
           "  return (SignalSet fp)\n"
           "\n"
           "", stdout);
#line 454 "Signals.hsc"
#ifndef cygwin32_TARGET_OS
    fputs ("\n"
           "", stdout);
    hsc_line (455, "Signals.hsc");
    fputs ("awaitSignal :: Maybe SignalSet -> IO ()\n"
           "awaitSignal maybe_sigset = do\n"
           "  fp <- case maybe_sigset of\n"
           "    \t  Nothing -> do SignalSet fp <- getSignalMask; return fp\n"
           "    \t  Just (SignalSet fp) -> return fp\n"
           "  withForeignPtr fp $ \\p -> do\n"
           "  c_sigsuspend p\n"
           "  return ()\n"
           "  -- ignore the return value; according to the docs it can only ever be\n"
           "  -- (-1) with errno set to EINTR.\n"
           " \n"
           "foreign import ccall unsafe \"sigsuspend\"\n"
           "  c_sigsuspend :: Ptr CSigset -> IO CInt\n"
           "", stdout);
#line 468 "Signals.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (469, "Signals.hsc");
    fputs ("\n"
           "", stdout);
#line 470 "Signals.hsc"
#ifdef __HUGS__
    fputs ("\n"
           "", stdout);
    hsc_line (471, "Signals.hsc");
    fputs ("foreign import ccall unsafe \"sigdelset\"\n"
           "  c_sigdelset   :: Ptr CSigset -> CInt -> IO CInt\n"
           "\n"
           "foreign import ccall unsafe \"sigfillset\"\n"
           "  c_sigfillset  :: Ptr CSigset -> IO CInt\n"
           "\n"
           "foreign import ccall unsafe \"sigismember\"\n"
           "  c_sigismember :: Ptr CSigset -> CInt -> IO CInt\n"
           "", stdout);
#line 479 "Signals.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (480, "Signals.hsc");
    fputs ("foreign import ccall unsafe \"__hscore_sigdelset\"\n"
           "  c_sigdelset   :: Ptr CSigset -> CInt -> IO CInt\n"
           "\n"
           "foreign import ccall unsafe \"__hscore_sigfillset\"\n"
           "  c_sigfillset  :: Ptr CSigset -> IO CInt\n"
           "\n"
           "foreign import ccall unsafe \"__hscore_sigismember\"\n"
           "  c_sigismember :: Ptr CSigset -> CInt -> IO CInt\n"
           "", stdout);
#line 488 "Signals.hsc"
#endif /* __HUGS__ */
    fputs ("\n"
           "", stdout);
    hsc_line (489, "Signals.hsc");
    fputs ("\n"
           "foreign import ccall unsafe \"sigpending\"\n"
           "  c_sigpending :: Ptr CSigset -> IO CInt\n"
           "\n"
           "", stdout);
#line 493 "Signals.hsc"
#ifdef __HUGS__
    fputs ("\n"
           "", stdout);
    hsc_line (494, "Signals.hsc");
    fputs ("c_SIG_BLOCK   = (", stdout);
#line 494 "Signals.hsc"
    hsc_const (SIG_BLOCK);
    fputs (")   :: CInt\n"
           "", stdout);
    hsc_line (495, "Signals.hsc");
    fputs ("c_SIG_SETMASK = (", stdout);
#line 495 "Signals.hsc"
    hsc_const (SIG_SETMASK);
    fputs (") :: CInt\n"
           "", stdout);
    hsc_line (496, "Signals.hsc");
    fputs ("c_SIG_UNBLOCK = (", stdout);
#line 496 "Signals.hsc"
    hsc_const (SIG_UNBLOCK);
    fputs (") :: CInt\n"
           "", stdout);
    hsc_line (497, "Signals.hsc");
    fputs ("", stdout);
#line 497 "Signals.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (498, "Signals.hsc");
    fputs ("foreign import ccall unsafe \"__hsposix_SIG_BLOCK\"   c_SIG_BLOCK   :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIG_SETMASK\" c_SIG_SETMASK :: CInt\n"
           "foreign import ccall unsafe \"__hsposix_SIG_UNBLOCK\" c_SIG_UNBLOCK :: CInt\n"
           "", stdout);
#line 501 "Signals.hsc"
#endif /* __HUGS__ */
    fputs ("\n"
           "", stdout);
    hsc_line (502, "Signals.hsc");
    fputs ("\n"
           "", stdout);
#line 503 "Signals.hsc"
#endif /* mingw32_TARGET_OS */
    fputs ("\n"
           "", stdout);
    hsc_line (504, "Signals.hsc");
    fputs ("\n"
           "", stdout);
    return 0;
}
