#include "template-hsc.h"
#line 25 "CPUTime.hsc"
#ifdef __HUGS__
#line 27 "CPUTime.hsc"
#endif 
#line 29 "CPUTime.hsc"
#ifdef __GLASGOW_HASKELL__
#line 33 "CPUTime.hsc"
#include "HsBase.h"
#line 34 "CPUTime.hsc"
#endif 
#line 36 "CPUTime.hsc"
#ifdef __GLASGOW_HASKELL__
#line 45 "CPUTime.hsc"
#if !defined(mingw32_TARGET_OS) && !defined(cygwin32_TARGET_OS)
#line 53 "CPUTime.hsc"
#if defined(HAVE_GETRUSAGE) && ! irix_TARGET_OS && ! solaris2_TARGET_OS
#line 70 "CPUTime.hsc"
#else 
#line 71 "CPUTime.hsc"
#if defined(HAVE_TIMES)
#line 81 "CPUTime.hsc"
#else 
#line 86 "CPUTime.hsc"
#endif 
#line 87 "CPUTime.hsc"
#endif 
#line 89 "CPUTime.hsc"
#else /* win32 */
#line 121 "CPUTime.hsc"
#endif /* not _WIN32 */
#line 122 "CPUTime.hsc"
#endif /* __GLASGOW_HASKELL__ */
#line 131 "CPUTime.hsc"
#ifdef __GLASGOW_HASKELL__
#line 134 "CPUTime.hsc"
#if defined(CLK_TCK)
#line 136 "CPUTime.hsc"
#else 
#line 139 "CPUTime.hsc"
#endif 
#line 140 "CPUTime.hsc"
#endif /* __GLASGOW_HASKELL__ */

int main (int argc, char *argv [])
{
#if __GLASGOW_HASKELL__ && __GLASGOW_HASKELL__ < 409
    printf ("{-# OPTIONS -optc-D__GLASGOW_HASKELL__=%d #-}\n", 603);
#endif
#line 25 "CPUTime.hsc"
#ifdef __HUGS__
#line 27 "CPUTime.hsc"
#endif 
#line 29 "CPUTime.hsc"
#ifdef __GLASGOW_HASKELL__
    printf ("{-# OPTIONS %s #-}\n", "-#include \"HsBase.h\"");
#line 34 "CPUTime.hsc"
#endif 
#line 36 "CPUTime.hsc"
#ifdef __GLASGOW_HASKELL__
#line 45 "CPUTime.hsc"
#if !defined(mingw32_TARGET_OS) && !defined(cygwin32_TARGET_OS)
#line 53 "CPUTime.hsc"
#if defined(HAVE_GETRUSAGE) && ! irix_TARGET_OS && ! solaris2_TARGET_OS
#line 70 "CPUTime.hsc"
#else 
#line 71 "CPUTime.hsc"
#if defined(HAVE_TIMES)
#line 81 "CPUTime.hsc"
#else 
#line 86 "CPUTime.hsc"
#endif 
#line 87 "CPUTime.hsc"
#endif 
#line 89 "CPUTime.hsc"
#else /* win32 */
#line 121 "CPUTime.hsc"
#endif /* not _WIN32 */
#line 122 "CPUTime.hsc"
#endif /* __GLASGOW_HASKELL__ */
#line 131 "CPUTime.hsc"
#ifdef __GLASGOW_HASKELL__
#line 134 "CPUTime.hsc"
#if defined(CLK_TCK)
#line 136 "CPUTime.hsc"
#else 
#line 139 "CPUTime.hsc"
#endif 
#line 140 "CPUTime.hsc"
#endif /* __GLASGOW_HASKELL__ */
    hsc_line (1, "CPUTime.hsc");
    fputs ("-----------------------------------------------------------------------------\n"
           "", stdout);
    hsc_line (2, "CPUTime.hsc");
    fputs ("-- |\n"
           "-- Module      :  System.CPUTime\n"
           "-- Copyright   :  (c) The University of Glasgow 2001\n"
           "-- License     :  BSD-style (see the file libraries/core/LICENSE)\n"
           "-- \n"
           "-- Maintainer  :  libraries@haskell.org\n"
           "-- Stability   :  provisional\n"
           "-- Portability :  portable\n"
           "--\n"
           "-- The standard CPUTime library.\n"
           "--\n"
           "-----------------------------------------------------------------------------\n"
           "\n"
           "module System.CPUTime \n"
           "\t(\n"
           "         getCPUTime,       -- :: IO Integer\n"
           "\t cpuTimePrecision  -- :: Integer\n"
           "        ) where\n"
           "\n"
           "import Prelude\n"
           "\n"
           "import Data.Ratio\n"
           "\n"
           "", stdout);
#line 25 "CPUTime.hsc"
#ifdef __HUGS__
    fputs ("\n"
           "", stdout);
    hsc_line (26, "CPUTime.hsc");
    fputs ("import Hugs.Time ( getCPUTime, clockTicks )\n"
           "", stdout);
#line 27 "CPUTime.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (28, "CPUTime.hsc");
    fputs ("\n"
           "", stdout);
#line 29 "CPUTime.hsc"
#ifdef __GLASGOW_HASKELL__
    fputs ("\n"
           "", stdout);
    hsc_line (30, "CPUTime.hsc");
    fputs ("import Foreign\n"
           "import Foreign.C\n"
           "\n"
           "", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (34, "CPUTime.hsc");
    fputs ("", stdout);
#line 34 "CPUTime.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (35, "CPUTime.hsc");
    fputs ("\n"
           "", stdout);
#line 36 "CPUTime.hsc"
#ifdef __GLASGOW_HASKELL__
    fputs ("\n"
           "", stdout);
    hsc_line (37, "CPUTime.hsc");
    fputs ("-- -----------------------------------------------------------------------------\n"
           "-- |Computation \'getCPUTime\' returns the number of picoseconds CPU time\n"
           "-- used by the current program.  The precision of this result is\n"
           "-- implementation-dependent.\n"
           "\n"
           "getCPUTime :: IO Integer\n"
           "getCPUTime = do\n"
           "\n"
           "", stdout);
#line 45 "CPUTime.hsc"
#if !defined(mingw32_TARGET_OS) && !defined(cygwin32_TARGET_OS)
    fputs ("\n"
           "", stdout);
    hsc_line (46, "CPUTime.hsc");
    fputs ("-- getrusage() is right royal pain to deal with when targetting multiple\n"
           "-- versions of Solaris, since some versions supply it in libc (2.3 and 2.5),\n"
           "-- while 2.4 has got it in libucb (I wouldn\'t be too surprised if it was back\n"
           "-- again in libucb in 2.6..)\n"
           "--\n"
           "-- Avoid the problem by resorting to times() instead.\n"
           "--\n"
           "", stdout);
#line 53 "CPUTime.hsc"
#if defined(HAVE_GETRUSAGE) && ! irix_TARGET_OS && ! solaris2_TARGET_OS
    fputs ("\n"
           "", stdout);
    hsc_line (54, "CPUTime.hsc");
    fputs ("    allocaBytes (", stdout);
#line 54 "CPUTime.hsc"
    hsc_const (sizeof(struct rusage));
    fputs (") $ \\ p_rusage -> do\n"
           "", stdout);
    hsc_line (55, "CPUTime.hsc");
    fputs ("    getrusage (", stdout);
#line 55 "CPUTime.hsc"
    hsc_const (RUSAGE_SELF);
    fputs (") p_rusage\n"
           "", stdout);
    hsc_line (56, "CPUTime.hsc");
    fputs ("\n"
           "    let ru_utime = (", stdout);
#line 57 "CPUTime.hsc"
    hsc_ptr (struct rusage, ru_utime);
    fputs (") p_rusage\n"
           "", stdout);
    hsc_line (58, "CPUTime.hsc");
    fputs ("    let ru_stime = (", stdout);
#line 58 "CPUTime.hsc"
    hsc_ptr (struct rusage, ru_stime);
    fputs (") p_rusage\n"
           "", stdout);
    hsc_line (59, "CPUTime.hsc");
    fputs ("    u_sec  <- (", stdout);
#line 59 "CPUTime.hsc"
    hsc_peek (struct timeval,tv_sec);
    fputs (")  ru_utime :: IO CTime\n"
           "", stdout);
    hsc_line (60, "CPUTime.hsc");
    fputs ("    u_usec <- (", stdout);
#line 60 "CPUTime.hsc"
    hsc_peek (struct timeval,tv_usec);
    fputs (") ru_utime :: IO CTime\n"
           "", stdout);
    hsc_line (61, "CPUTime.hsc");
    fputs ("    s_sec  <- (", stdout);
#line 61 "CPUTime.hsc"
    hsc_peek (struct timeval,tv_sec);
    fputs (")  ru_stime :: IO CTime\n"
           "", stdout);
    hsc_line (62, "CPUTime.hsc");
    fputs ("    s_usec <- (", stdout);
#line 62 "CPUTime.hsc"
    hsc_peek (struct timeval,tv_usec);
    fputs (") ru_stime :: IO CTime\n"
           "", stdout);
    hsc_line (63, "CPUTime.hsc");
    fputs ("\n"
           "    return ((fromIntegral u_sec * 1000000 + fromIntegral u_usec + \n"
           "             fromIntegral s_sec * 1000000 + fromIntegral s_usec) \n"
           "\t\t* 1000000)\n"
           "\n"
           "type CRUsage = ()\n"
           "foreign import ccall unsafe getrusage :: CInt -> Ptr CRUsage -> IO CInt\n"
           "", stdout);
#line 70 "CPUTime.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (71, "CPUTime.hsc");
    fputs ("", stdout);
#line 71 "CPUTime.hsc"
#if defined(HAVE_TIMES)
    fputs ("\n"
           "", stdout);
    hsc_line (72, "CPUTime.hsc");
    fputs ("    allocaBytes (", stdout);
#line 72 "CPUTime.hsc"
    hsc_const (sizeof(struct tms));
    fputs (") $ \\ p_tms -> do\n"
           "", stdout);
    hsc_line (73, "CPUTime.hsc");
    fputs ("    times p_tms\n"
           "    u_ticks  <- (", stdout);
#line 74 "CPUTime.hsc"
    hsc_peek (struct tms,tms_utime);
    fputs (") p_tms :: IO CClock\n"
           "", stdout);
    hsc_line (75, "CPUTime.hsc");
    fputs ("    s_ticks  <- (", stdout);
#line 75 "CPUTime.hsc"
    hsc_peek (struct tms,tms_stime);
    fputs (") p_tms :: IO CClock\n"
           "", stdout);
    hsc_line (76, "CPUTime.hsc");
    fputs ("    return (( (fromIntegral u_ticks + fromIntegral s_ticks) * 1000000000000) \n"
           "\t\t\t`div` fromIntegral clockTicks)\n"
           "\n"
           "type CTms = ()\n"
           "foreign import ccall unsafe times :: Ptr CTms -> IO CClock\n"
           "", stdout);
#line 81 "CPUTime.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (82, "CPUTime.hsc");
    fputs ("    ioException (IOError Nothing UnsupportedOperation \n"
           "\t\t\t \"getCPUTime\"\n"
           "\t\t         \"can\'t get CPU time\"\n"
           "\t\t\t Nothing)\n"
           "", stdout);
#line 86 "CPUTime.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (87, "CPUTime.hsc");
    fputs ("", stdout);
#line 87 "CPUTime.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (88, "CPUTime.hsc");
    fputs ("\n"
           "", stdout);
#line 89 "CPUTime.hsc"
#else /* win32 */
    fputs ("\n"
           "", stdout);
    hsc_line (90, "CPUTime.hsc");
    fputs ("     -- NOTE: GetProcessTimes() is only supported on NT-based OSes.\n"
           "     -- The counts reported by GetProcessTimes() are in 100-ns (10^-7) units.\n"
           "    allocaBytes (", stdout);
#line 92 "CPUTime.hsc"
    hsc_const (sizeof(FILETIME));
    fputs (") $ \\ p_creationTime -> do\n"
           "", stdout);
    hsc_line (93, "CPUTime.hsc");
    fputs ("    allocaBytes (", stdout);
#line 93 "CPUTime.hsc"
    hsc_const (sizeof(FILETIME));
    fputs (") $ \\ p_exitTime -> do\n"
           "", stdout);
    hsc_line (94, "CPUTime.hsc");
    fputs ("    allocaBytes (", stdout);
#line 94 "CPUTime.hsc"
    hsc_const (sizeof(FILETIME));
    fputs (") $ \\ p_kernelTime -> do\n"
           "", stdout);
    hsc_line (95, "CPUTime.hsc");
    fputs ("    allocaBytes (", stdout);
#line 95 "CPUTime.hsc"
    hsc_const (sizeof(FILETIME));
    fputs (") $ \\ p_userTime -> do\n"
           "", stdout);
    hsc_line (96, "CPUTime.hsc");
    fputs ("    pid <- getCurrentProcess\n"
           "    ok <- getProcessTimes pid p_creationTime p_exitTime p_kernelTime p_userTime\n"
           "    if toBool ok then do\n"
           "      ut <- ft2psecs p_userTime\n"
           "      kt <- ft2psecs p_kernelTime\n"
           "      return (ut + kt)\n"
           "     else return 0\n"
           "  where \n"
           "\tft2psecs :: Ptr FILETIME -> IO Integer\n"
           "        ft2psecs ft = do\n"
           "          high <- (", stdout);
#line 106 "CPUTime.hsc"
    hsc_peek (FILETIME,dwHighDateTime);
    fputs (") ft :: IO CLong\n"
           "", stdout);
    hsc_line (107, "CPUTime.hsc");
    fputs ("          low <- (", stdout);
#line 107 "CPUTime.hsc"
    hsc_peek (FILETIME,dwLowDateTime);
    fputs (") ft :: IO CLong\n"
           "", stdout);
    hsc_line (108, "CPUTime.hsc");
    fputs ("\t    -- Convert 100-ns units to picosecs (10^-12) \n"
           "\t    -- => multiply by 10^5.\n"
           "          return (((fromIntegral high) * (2^32) + (fromIntegral low)) * 100000)\n"
           "\n"
           "    -- ToDo: pin down elapsed times to just the OS thread(s) that\n"
           "    -- are evaluating/managing Haskell code.\n"
           "\n"
           "type FILETIME = ()\n"
           "type HANDLE = ()\n"
           "-- need proper Haskell names (initial lower-case character)\n"
           "foreign import ccall unsafe \"GetCurrentProcess\" getCurrentProcess :: IO (Ptr HANDLE)\n"
           "foreign import ccall unsafe \"GetProcessTimes\" getProcessTimes :: Ptr HANDLE -> Ptr FILETIME -> Ptr FILETIME -> Ptr FILETIME -> Ptr FILETIME -> IO CInt\n"
           "\n"
           "", stdout);
#line 121 "CPUTime.hsc"
#endif /* not _WIN32 */
    fputs ("\n"
           "", stdout);
    hsc_line (122, "CPUTime.hsc");
    fputs ("", stdout);
#line 122 "CPUTime.hsc"
#endif /* __GLASGOW_HASKELL__ */
    fputs ("\n"
           "", stdout);
    hsc_line (123, "CPUTime.hsc");
    fputs ("\n"
           "-- |The \'cpuTimePrecision\' constant is the smallest measurable difference\n"
           "-- in CPU time that the implementation can record, and is given as an\n"
           "-- integral number of picoseconds.\n"
           "\n"
           "cpuTimePrecision :: Integer\n"
           "cpuTimePrecision = round ((1000000000000::Integer) % fromIntegral (clockTicks))\n"
           "\n"
           "", stdout);
#line 131 "CPUTime.hsc"
#ifdef __GLASGOW_HASKELL__
    fputs ("\n"
           "", stdout);
    hsc_line (132, "CPUTime.hsc");
    fputs ("clockTicks :: Int\n"
           "clockTicks =\n"
           "", stdout);
#line 134 "CPUTime.hsc"
#if defined(CLK_TCK)
    fputs ("\n"
           "", stdout);
    hsc_line (135, "CPUTime.hsc");
    fputs ("    (", stdout);
#line 135 "CPUTime.hsc"
    hsc_const (CLK_TCK);
    fputs (")\n"
           "", stdout);
    hsc_line (136, "CPUTime.hsc");
    fputs ("", stdout);
#line 136 "CPUTime.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (137, "CPUTime.hsc");
    fputs ("    unsafePerformIO (sysconf (", stdout);
#line 137 "CPUTime.hsc"
    hsc_const (_SC_CLK_TCK);
    fputs (") >>= return . fromIntegral)\n"
           "", stdout);
    hsc_line (138, "CPUTime.hsc");
    fputs ("foreign import ccall unsafe sysconf :: CInt -> IO CLong\n"
           "", stdout);
#line 139 "CPUTime.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (140, "CPUTime.hsc");
    fputs ("", stdout);
#line 140 "CPUTime.hsc"
#endif /* __GLASGOW_HASKELL__ */
    fputs ("\n"
           "", stdout);
    hsc_line (141, "CPUTime.hsc");
    fputs ("", stdout);
    return 0;
}
