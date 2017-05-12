#include "template-hsc.h"
#line 20 "Process.hsc"
#ifdef __GLASGOW_HASKELL__
#line 22 "Process.hsc"
#endif 
#line 62 "Process.hsc"
#include "HsUnix.h"
#line 80 "Process.hsc"
#ifdef __HUGS__
#line 82 "Process.hsc"
#endif 
#line 218 "Process.hsc"
#ifdef __GLASGOW_HASKELL__
#line 234 "Process.hsc"
#endif /* __GLASGOW_HASKELL__ */

int main (int argc, char *argv [])
{
#if __GLASGOW_HASKELL__ && __GLASGOW_HASKELL__ < 409
    printf ("{-# OPTIONS -optc-D__GLASGOW_HASKELL__=%d #-}\n", 603);
#endif
#line 20 "Process.hsc"
#ifdef __GLASGOW_HASKELL__
#line 22 "Process.hsc"
#endif 
    printf ("{-# OPTIONS %s #-}\n", "-#include \"HsUnix.h\"");
#line 80 "Process.hsc"
#ifdef __HUGS__
#line 82 "Process.hsc"
#endif 
#line 218 "Process.hsc"
#ifdef __GLASGOW_HASKELL__
#line 234 "Process.hsc"
#endif /* __GLASGOW_HASKELL__ */
    hsc_line (1, "Process.hsc");
    fputs ("{-# OPTIONS -fffi #-}\n"
           "", stdout);
    hsc_line (2, "Process.hsc");
    fputs ("-----------------------------------------------------------------------------\n"
           "-- |\n"
           "-- Module      :  System.Posix.Process\n"
           "-- Copyright   :  (c) The University of Glasgow 2002\n"
           "-- License     :  BSD-style (see the file libraries/base/LICENSE)\n"
           "-- \n"
           "-- Maintainer  :  libraries@haskell.org\n"
           "-- Stability   :  provisional\n"
           "-- Portability :  non-portable (requires POSIX)\n"
           "--\n"
           "-- POSIX process support\n"
           "--\n"
           "-----------------------------------------------------------------------------\n"
           "\n"
           "module System.Posix.Process (\n"
           "    -- * Processes\n"
           "\n"
           "    -- ** Forking and executing\n"
           "", stdout);
#line 20 "Process.hsc"
#ifdef __GLASGOW_HASKELL__
    fputs ("\n"
           "", stdout);
    hsc_line (21, "Process.hsc");
    fputs ("    forkProcess,\n"
           "", stdout);
#line 22 "Process.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (23, "Process.hsc");
    fputs ("    executeFile,\n"
           "    \n"
           "    -- ** Exiting\n"
           "    exitImmediately,\n"
           "\n"
           "    -- ** Process environment\n"
           "    getProcessID,\n"
           "    getParentProcessID,\n"
           "    getProcessGroupID,\n"
           "\n"
           "    -- ** Process groups\n"
           "    createProcessGroup,\n"
           "    joinProcessGroup,\n"
           "    setProcessGroupID,\n"
           "\n"
           "    -- ** Sessions\n"
           "    createSession,\n"
           "\n"
           "    -- ** Process times\n"
           "    ProcessTimes(..),\n"
           "    getProcessTimes,\n"
           "\n"
           "    -- ** Scheduling priority\n"
           "    nice,\n"
           "    getProcessPriority,\n"
           "    getProcessGroupPriority,\n"
           "    getUserPriority,\n"
           "    setProcessPriority,\n"
           "    setProcessGroupPriority,\n"
           "    setUserPriority,\n"
           "\n"
           "    -- ** Process status\n"
           "    ProcessStatus(..),\n"
           "    getProcessStatus,\n"
           "    getAnyProcessStatus,\n"
           "    getGroupProcessStatus,\n"
           "\n"
           " ) where\n"
           "\n"
           "", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (63, "Process.hsc");
    fputs ("\n"
           "import Foreign.C.Error\n"
           "import Foreign.C.String ( CString, withCString )\n"
           "import Foreign.C.Types ( CInt, CClock )\n"
           "import Foreign.Marshal.Alloc ( alloca, allocaBytes )\n"
           "import Foreign.Marshal.Array ( withArray0 )\n"
           "import Foreign.Marshal.Utils ( withMany )\n"
           "import Foreign.Ptr ( Ptr, nullPtr )\n"
           "import Foreign.StablePtr ( StablePtr, newStablePtr, freeStablePtr )\n"
           "import Foreign.Storable ( Storable(..) )\n"
           "import System.IO\n"
           "import System.IO.Error\n"
           "import System.Exit\n"
           "import System.Posix.Types\n"
           "import System.Posix.Signals\n"
           "import Control.Monad\n"
           "\n"
           "", stdout);
#line 80 "Process.hsc"
#ifdef __HUGS__
    fputs ("\n"
           "", stdout);
    hsc_line (81, "Process.hsc");
    fputs ("{-# CBITS HsUnix.c execvpe.c #-}\n"
           "", stdout);
#line 82 "Process.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (83, "Process.hsc");
    fputs ("\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Process environment\n"
           "\n"
           "getProcessID :: IO ProcessID\n"
           "getProcessID = c_getpid\n"
           "\n"
           "foreign import ccall unsafe \"getpid\"\n"
           "   c_getpid :: IO CPid\n"
           "\n"
           "getParentProcessID :: IO ProcessID\n"
           "getParentProcessID = c_getppid\n"
           "\n"
           "foreign import ccall unsafe \"getppid\"\n"
           "  c_getppid :: IO CPid\n"
           "\n"
           "getProcessGroupID :: IO ProcessGroupID\n"
           "getProcessGroupID = c_getpgrp\n"
           "\n"
           "foreign import ccall unsafe \"getpgrp\"\n"
           "  c_getpgrp :: IO CPid\n"
           "\n"
           "createProcessGroup :: ProcessID -> IO ProcessGroupID\n"
           "createProcessGroup pid = do\n"
           "  throwErrnoIfMinus1_ \"createProcessGroup\" (c_setpgid pid 0)\n"
           "  return pid\n"
           "\n"
           "joinProcessGroup :: ProcessGroupID -> IO ()\n"
           "joinProcessGroup pgid =\n"
           "  throwErrnoIfMinus1_ \"joinProcessGroup\" (c_setpgid 0 pgid)\n"
           "\n"
           "setProcessGroupID :: ProcessID -> ProcessGroupID -> IO ()\n"
           "setProcessGroupID pid pgid =\n"
           "  throwErrnoIfMinus1_ \"setProcessGroupID\" (c_setpgid pid pgid)\n"
           "\n"
           "foreign import ccall unsafe \"setpgid\"\n"
           "  c_setpgid :: CPid -> CPid -> IO CInt\n"
           "\n"
           "createSession :: IO ProcessGroupID\n"
           "createSession = throwErrnoIfMinus1 \"createSession\" c_setsid\n"
           "\n"
           "foreign import ccall unsafe \"setsid\"\n"
           "  c_setsid :: IO CPid\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Process times\n"
           "\n"
           "-- All times in clock ticks (see getClockTick)\n"
           "\n"
           "data ProcessTimes\n"
           "  = ProcessTimes { elapsedTime     :: ClockTick\n"
           "  \t\t , userTime        :: ClockTick\n"
           "\t\t , systemTime      :: ClockTick\n"
           "\t\t , childUserTime   :: ClockTick\n"
           "\t\t , childSystemTime :: ClockTick\n"
           "\t\t }\n"
           "\n"
           "getProcessTimes :: IO ProcessTimes\n"
           "getProcessTimes = do\n"
           "   allocaBytes (", stdout);
#line 142 "Process.hsc"
    hsc_const (sizeof(struct tms));
    fputs (") $ \\p_tms -> do\n"
           "", stdout);
    hsc_line (143, "Process.hsc");
    fputs ("     elapsed <- throwErrnoIfMinus1 \"getProcessTimes\" (c_times p_tms)\n"
           "     ut  <- (", stdout);
#line 144 "Process.hsc"
    hsc_peek (struct tms, tms_utime);
    fputs (")  p_tms\n"
           "", stdout);
    hsc_line (145, "Process.hsc");
    fputs ("     st  <- (", stdout);
#line 145 "Process.hsc"
    hsc_peek (struct tms, tms_stime);
    fputs (")  p_tms\n"
           "", stdout);
    hsc_line (146, "Process.hsc");
    fputs ("     cut <- (", stdout);
#line 146 "Process.hsc"
    hsc_peek (struct tms, tms_cutime);
    fputs (") p_tms\n"
           "", stdout);
    hsc_line (147, "Process.hsc");
    fputs ("     cst <- (", stdout);
#line 147 "Process.hsc"
    hsc_peek (struct tms, tms_cstime);
    fputs (") p_tms\n"
           "", stdout);
    hsc_line (148, "Process.hsc");
    fputs ("     return (ProcessTimes{ elapsedTime     = elapsed,\n"
           "\t \t\t   userTime        = ut,\n"
           "\t \t\t   systemTime      = st,\n"
           "\t \t\t   childUserTime   = cut,\n"
           "\t \t\t   childSystemTime = cst\n"
           "\t\t\t  })\n"
           "\n"
           "type CTms = ()\n"
           "\n"
           "foreign import ccall unsafe \"times\"\n"
           "  c_times :: Ptr CTms -> IO CClock\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Process scheduling priority\n"
           "\n"
           "nice :: Int -> IO ()\n"
           "nice prio = do\n"
           "  resetErrno\n"
           "  res <- c_nice (fromIntegral prio)\n"
           "  when (res == -1) $ do\n"
           "    err <- getErrno\n"
           "    when (err /= eOK) (throwErrno \"nice\")\n"
           "\n"
           "foreign import ccall unsafe \"nice\"\n"
           "  c_nice :: CInt -> IO CInt\n"
           "\n"
           "getProcessPriority      :: ProcessID      -> IO Int\n"
           "getProcessGroupPriority :: ProcessGroupID -> IO Int\n"
           "getUserPriority         :: UserID         -> IO Int\n"
           "\n"
           "getProcessPriority pid = do\n"
           "  r <- throwErrnoIfMinus1 \"getProcessPriority\" $\n"
           "         c_getpriority (", stdout);
#line 180 "Process.hsc"
    hsc_const (PRIO_PROCESS);
    fputs (") (fromIntegral pid)\n"
           "", stdout);
    hsc_line (181, "Process.hsc");
    fputs ("  return (fromIntegral r)\n"
           "\n"
           "getProcessGroupPriority pid = do\n"
           "  r <- throwErrnoIfMinus1 \"getProcessPriority\" $\n"
           "         c_getpriority (", stdout);
#line 185 "Process.hsc"
    hsc_const (PRIO_PGRP);
    fputs (") (fromIntegral pid)\n"
           "", stdout);
    hsc_line (186, "Process.hsc");
    fputs ("  return (fromIntegral r)\n"
           "\n"
           "getUserPriority uid = do\n"
           "  r <- throwErrnoIfMinus1 \"getUserPriority\" $\n"
           "         c_getpriority (", stdout);
#line 190 "Process.hsc"
    hsc_const (PRIO_USER);
    fputs (") (fromIntegral uid)\n"
           "", stdout);
    hsc_line (191, "Process.hsc");
    fputs ("  return (fromIntegral r)\n"
           "\n"
           "foreign import ccall unsafe \"getpriority\"\n"
           "  c_getpriority :: CInt -> CInt -> IO CInt\n"
           "\n"
           "setProcessPriority      :: ProcessID      -> Int -> IO ()\n"
           "setProcessGroupPriority :: ProcessGroupID -> Int -> IO ()\n"
           "setUserPriority         :: UserID         -> Int -> IO ()\n"
           "\n"
           "setProcessPriority pid val = \n"
           "  throwErrnoIfMinus1_ \"setProcessPriority\" $\n"
           "    c_setpriority (", stdout);
#line 202 "Process.hsc"
    hsc_const (PRIO_PROCESS);
    fputs (") (fromIntegral pid) (fromIntegral val)\n"
           "", stdout);
    hsc_line (203, "Process.hsc");
    fputs ("\n"
           "setProcessGroupPriority pid val =\n"
           "  throwErrnoIfMinus1_ \"setProcessPriority\" $\n"
           "    c_setpriority (", stdout);
#line 206 "Process.hsc"
    hsc_const (PRIO_PGRP);
    fputs (") (fromIntegral pid) (fromIntegral val)\n"
           "", stdout);
    hsc_line (207, "Process.hsc");
    fputs ("\n"
           "setUserPriority uid val =\n"
           "  throwErrnoIfMinus1_ \"setUserPriority\" $\n"
           "    c_setpriority (", stdout);
#line 210 "Process.hsc"
    hsc_const (PRIO_USER);
    fputs (") (fromIntegral uid) (fromIntegral val)\n"
           "", stdout);
    hsc_line (211, "Process.hsc");
    fputs ("\n"
           "foreign import ccall unsafe \"setpriority\"\n"
           "  c_setpriority :: CInt -> CInt -> CInt -> IO CInt\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Forking, execution\n"
           "\n"
           "", stdout);
#line 218 "Process.hsc"
#ifdef __GLASGOW_HASKELL__
    fputs ("\n"
           "", stdout);
    hsc_line (219, "Process.hsc");
    fputs ("{- | \'forkProcess\' corresponds to the POSIX @fork@ system call.\n"
           "The \'IO\' action passed as an argument is executed in the child process; no other\n"
           "threads will be copied to the child process.\n"
           "On success, \'forkProcess\' returns the child\'s \'ProcessID\' to the parent process;\n"
           "in case of an error, an exception is thrown.\n"
           "-}\n"
           "\n"
           "forkProcess :: IO () -> IO ProcessID\n"
           "forkProcess action = do\n"
           "  stable <- newStablePtr action\n"
           "  pid <- throwErrnoIfMinus1 \"forkProcess\" (forkProcessPrim stable)\n"
           "  freeStablePtr stable\n"
           "  return $ fromIntegral pid\n"
           "\n"
           "foreign import ccall \"forkProcess\" forkProcessPrim :: StablePtr (IO ()) -> IO CPid\n"
           "", stdout);
#line 234 "Process.hsc"
#endif /* __GLASGOW_HASKELL__ */
    fputs ("\n"
           "", stdout);
    hsc_line (235, "Process.hsc");
    fputs ("\n"
           "executeFile :: FilePath\t\t\t    -- Command\n"
           "            -> Bool\t\t\t    -- Search PATH\?\n"
           "            -> [String]\t\t\t    -- Arguments\n"
           "            -> Maybe [(String, String)]\t    -- Environment\n"
           "            -> IO ()\n"
           "executeFile path search args Nothing = do\n"
           "  withCString path $ \\s ->\n"
           "    withMany withCString (path:args) $ \\cstrs ->\n"
           "      withArray0 nullPtr cstrs $ \\arr -> do\n"
           "\tpPrPr_disableITimers\n"
           "\tif search \n"
           "\t   then throwErrnoIfMinus1_ \"executeFile\" (c_execvp s arr)\n"
           "\t   else throwErrnoIfMinus1_ \"executeFile\" (c_execv s arr)\n"
           "\n"
           "executeFile path search args (Just env) = do\n"
           "  withCString path $ \\s ->\n"
           "    withMany withCString (path:args) $ \\cstrs ->\n"
           "      withArray0 nullPtr cstrs $ \\arg_arr ->\n"
           "    let env\' = map (\\ (name, val) -> name ++ (\'=\' : val)) env in\n"
           "    withMany withCString env\' $ \\cenv ->\n"
           "      withArray0 nullPtr cenv $ \\env_arr -> do\n"
           "\tpPrPr_disableITimers\n"
           "\tif search \n"
           "\t   then throwErrnoIfMinus1_ \"executeFile\" (c_execvpe s arg_arr env_arr)\n"
           "\t   else throwErrnoIfMinus1_ \"executeFile\" (c_execve s arg_arr env_arr)\n"
           "\n"
           "-- this function disables the itimer, which would otherwise cause confusing\n"
           "-- signals to be sent to the new process.\n"
           "foreign import ccall unsafe \"pPrPr_disableITimers\"\n"
           "  pPrPr_disableITimers :: IO ()\n"
           "\n"
           "foreign import ccall unsafe \"execvp\"\n"
           "  c_execvp :: CString -> Ptr CString -> IO CInt\n"
           "\n"
           "foreign import ccall unsafe \"execv\"\n"
           "  c_execv :: CString -> Ptr CString -> IO CInt\n"
           "\n"
           "foreign import ccall unsafe \"execvpe\"\n"
           "  c_execvpe :: CString -> Ptr CString -> Ptr CString -> IO CInt\n"
           "\n"
           "foreign import ccall unsafe \"execve\"\n"
           "  c_execve :: CString -> Ptr CString -> Ptr CString -> IO CInt\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Waiting for process termination\n"
           "\n"
           "data ProcessStatus = Exited ExitCode\n"
           "                   | Terminated Signal\n"
           "                   | Stopped Signal\n"
           "\t\t   deriving (Eq, Ord, Show)\n"
           "\n"
           "getProcessStatus :: Bool -> Bool -> ProcessID -> IO (Maybe ProcessStatus)\n"
           "getProcessStatus block stopped pid =\n"
           "  alloca $ \\wstatp -> do\n"
           "    pid <- throwErrnoIfMinus1Retry \"getProcessStatus\"\n"
           "\t\t(c_waitpid pid wstatp (waitOptions block stopped))\n"
           "    case pid of\n"
           "      0  -> return Nothing\n"
           "      _  -> do ps <- decipherWaitStatus wstatp\n"
           "\t       return (Just ps)\n"
           "\n"
           "foreign import ccall unsafe \"waitpid\"\n"
           "  c_waitpid :: CPid -> Ptr CInt -> CInt -> IO CPid\n"
           "\n"
           "getGroupProcessStatus :: Bool\n"
           "                      -> Bool\n"
           "                      -> ProcessGroupID\n"
           "                      -> IO (Maybe (ProcessID, ProcessStatus))\n"
           "getGroupProcessStatus block stopped pgid =\n"
           "  alloca $ \\wstatp -> do\n"
           "    pid <- throwErrnoIfMinus1Retry \"getGroupProcessStatus\"\n"
           "\t\t(c_waitpid (-pgid) wstatp (waitOptions block stopped))\n"
           "    case pid of\n"
           "      0  -> return Nothing\n"
           "      _  -> do ps <- decipherWaitStatus wstatp\n"
           "\t       return (Just (pid, ps))\n"
           "\n"
           "getAnyProcessStatus :: Bool -> Bool -> IO (Maybe (ProcessID, ProcessStatus))\n"
           "getAnyProcessStatus block stopped = getGroupProcessStatus block stopped 1\n"
           "\n"
           "waitOptions :: Bool -> Bool -> CInt\n"
           "--             block   stopped\n"
           "waitOptions False False = (", stdout);
#line 318 "Process.hsc"
    hsc_const (WNOHANG);
    fputs (")\n"
           "", stdout);
    hsc_line (319, "Process.hsc");
    fputs ("waitOptions False True  = (", stdout);
#line 319 "Process.hsc"
    hsc_const ((WNOHANG|WUNTRACED));
    fputs (")\n"
           "", stdout);
    hsc_line (320, "Process.hsc");
    fputs ("waitOptions True  False = 0\n"
           "waitOptions True  True  = (", stdout);
#line 321 "Process.hsc"
    hsc_const (WUNTRACED);
    fputs (")\n"
           "", stdout);
    hsc_line (322, "Process.hsc");
    fputs ("\n"
           "-- Turn a (ptr to a) wait status into a ProcessStatus\n"
           "\n"
           "decipherWaitStatus :: Ptr CInt -> IO ProcessStatus\n"
           "decipherWaitStatus wstatp = do\n"
           "  wstat <- peek wstatp\n"
           "  if c_WIFEXITED wstat /= 0\n"
           "      then do\n"
           "        let exitstatus = c_WEXITSTATUS wstat\n"
           "        if exitstatus == 0\n"
           "\t   then return (Exited ExitSuccess)\n"
           "\t   else return (Exited (ExitFailure (fromIntegral exitstatus)))\n"
           "      else do\n"
           "        if c_WIFSIGNALED wstat /= 0\n"
           "\t   then do\n"
           "\t\tlet termsig = c_WTERMSIG wstat\n"
           "\t\treturn (Terminated (fromIntegral termsig))\n"
           "\t   else do\n"
           "\t\tif c_WIFSTOPPED wstat /= 0\n"
           "\t\t   then do\n"
           "\t\t\tlet stopsig = c_WSTOPSIG wstat\n"
           "\t\t\treturn (Stopped (fromIntegral stopsig))\n"
           "\t\t   else do\n"
           "\t\t\tioError (mkIOError illegalOperationErrorType\n"
           "\t\t\t\t   \"waitStatus\" Nothing Nothing)\n"
           "\n"
           "foreign import ccall unsafe \"__hsunix_wifexited\"\n"
           "  c_WIFEXITED :: CInt -> CInt \n"
           "\n"
           "foreign import ccall unsafe \"__hsunix_wexitstatus\"\n"
           "  c_WEXITSTATUS :: CInt -> CInt\n"
           "\n"
           "foreign import ccall unsafe \"__hsunix_wifsignaled\"\n"
           "  c_WIFSIGNALED :: CInt -> CInt\n"
           "\n"
           "foreign import ccall unsafe \"__hsunix_wtermsig\"\n"
           "  c_WTERMSIG :: CInt -> CInt \n"
           "\n"
           "foreign import ccall unsafe \"__hsunix_wifstopped\"\n"
           "  c_WIFSTOPPED :: CInt -> CInt\n"
           "\n"
           "foreign import ccall unsafe \"__hsunix_wstopsig\"\n"
           "  c_WSTOPSIG :: CInt -> CInt\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Exiting\n"
           "\n"
           "exitImmediately :: ExitCode -> IO ()\n"
           "exitImmediately exitcode = c_exit (exitcode2Int exitcode)\n"
           "  where\n"
           "    exitcode2Int ExitSuccess = 0\n"
           "    exitcode2Int (ExitFailure n) = fromIntegral n\n"
           "\n"
           "foreign import ccall unsafe \"exit\"\n"
           "  c_exit :: CInt -> IO ()\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "", stdout);
    return 0;
}
