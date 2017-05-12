#include "template-hsc.h"
#line 49 "Unistd.hsc"
#include "HsUnix.h"
#line 101 "Unistd.hsc"
#ifdef USLEEP_RETURNS_VOID
#line 103 "Unistd.hsc"
#else 
#line 105 "Unistd.hsc"
#endif 
#line 107 "Unistd.hsc"
#ifdef USLEEP_RETURNS_VOID
#line 110 "Unistd.hsc"
#else 
#line 113 "Unistd.hsc"
#endif 

int main (int argc, char *argv [])
{
#if __GLASGOW_HASKELL__ && __GLASGOW_HASKELL__ < 409
    printf ("{-# OPTIONS -optc-D__GLASGOW_HASKELL__=%d #-}\n", 603);
#endif
    printf ("{-# OPTIONS %s #-}\n", "-#include \"HsUnix.h\"");
#line 101 "Unistd.hsc"
#ifdef USLEEP_RETURNS_VOID
#line 103 "Unistd.hsc"
#else 
#line 105 "Unistd.hsc"
#endif 
#line 107 "Unistd.hsc"
#ifdef USLEEP_RETURNS_VOID
#line 110 "Unistd.hsc"
#else 
#line 113 "Unistd.hsc"
#endif 
    hsc_line (1, "Unistd.hsc");
    fputs ("{-# OPTIONS -fffi #-}\n"
           "", stdout);
    hsc_line (2, "Unistd.hsc");
    fputs ("-----------------------------------------------------------------------------\n"
           "-- |\n"
           "-- Module      :  System.Posix.Unistd\n"
           "-- Copyright   :  (c) The University of Glasgow 2002\n"
           "-- License     :  BSD-style (see the file libraries/base/LICENSE)\n"
           "-- \n"
           "-- Maintainer  :  libraries@haskell.org\n"
           "-- Stability   :  provisional\n"
           "-- Portability :  non-portable (requires POSIX)\n"
           "--\n"
           "-- POSIX miscellaneous stuff, mostly from unistd.h\n"
           "--\n"
           "-----------------------------------------------------------------------------\n"
           "\n"
           "module System.Posix.Unistd (\n"
           "    -- * System environment\n"
           "    SystemID(..),\n"
           "    getSystemID,\n"
           "\n"
           "    SysVar(..),\n"
           "    getSysVar,\n"
           "\n"
           "    -- * Sleeping\n"
           "    sleep, usleep,\n"
           "\n"
           "  {-\n"
           "    ToDo from unistd.h:\n"
           "      confstr, \n"
           "      lots of sysconf variables\n"
           "\n"
           "    -- use Network.BSD\n"
           "    gethostid, gethostname\n"
           "\n"
           "    -- should be in System.Posix.Files\?\n"
           "    pathconf, fpathconf,\n"
           "\n"
           "    -- System.Posix.Signals\n"
           "    ualarm,\n"
           "\n"
           "    -- System.Posix.IO\n"
           "    read, write,\n"
           "\n"
           "    -- should be in System.Posix.User\?\n"
           "    getEffectiveUserName,\n"
           "-}\n"
           "  ) where\n"
           "\n"
           "", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (50, "Unistd.hsc");
    fputs ("\n"
           "import Foreign.C.Error ( throwErrnoIfMinus1, throwErrnoIfMinus1_ )\n"
           "import Foreign.C.String ( peekCString )\n"
           "import Foreign.C.Types ( CInt, CUInt, CLong )\n"
           "import Foreign.Marshal.Alloc ( allocaBytes )\n"
           "import Foreign.Ptr ( Ptr, plusPtr )\n"
           "import System.Posix.Types\n"
           "import System.Posix.Internals\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- System environment (uname())\n"
           "\n"
           "data SystemID =\n"
           "  SystemID { systemName :: String\n"
           "  \t   , nodeName   :: String\n"
           "\t   , release    :: String\n"
           "\t   , version    :: String\n"
           "\t   , machine    :: String\n"
           "\t   }\n"
           "\n"
           "getSystemID :: IO SystemID\n"
           "getSystemID = do\n"
           "  allocaBytes (", stdout);
#line 72 "Unistd.hsc"
    hsc_const (sizeof(struct utsname));
    fputs (") $ \\p_sid -> do\n"
           "", stdout);
    hsc_line (73, "Unistd.hsc");
    fputs ("    throwErrnoIfMinus1_ \"getSystemID\" (c_uname p_sid)\n"
           "    sysN <- peekCString ((", stdout);
#line 74 "Unistd.hsc"
    hsc_ptr (struct utsname, sysname);
    fputs (") p_sid)\n"
           "", stdout);
    hsc_line (75, "Unistd.hsc");
    fputs ("    node <- peekCString ((", stdout);
#line 75 "Unistd.hsc"
    hsc_ptr (struct utsname, nodename);
    fputs (") p_sid)\n"
           "", stdout);
    hsc_line (76, "Unistd.hsc");
    fputs ("    rel  <- peekCString ((", stdout);
#line 76 "Unistd.hsc"
    hsc_ptr (struct utsname, release);
    fputs (") p_sid)\n"
           "", stdout);
    hsc_line (77, "Unistd.hsc");
    fputs ("    ver  <- peekCString ((", stdout);
#line 77 "Unistd.hsc"
    hsc_ptr (struct utsname, version);
    fputs (") p_sid)\n"
           "", stdout);
    hsc_line (78, "Unistd.hsc");
    fputs ("    mach <- peekCString ((", stdout);
#line 78 "Unistd.hsc"
    hsc_ptr (struct utsname, machine);
    fputs (") p_sid)\n"
           "", stdout);
    hsc_line (79, "Unistd.hsc");
    fputs ("    return (SystemID { systemName = sysN,\n"
           "\t\t       nodeName   = node,\n"
           "\t\t       release    = rel,\n"
           "\t\t       version    = ver,\n"
           "\t\t       machine    = mach\n"
           "\t\t     })\n"
           "\n"
           "foreign import ccall unsafe \"uname\"\n"
           "   c_uname :: Ptr CUtsname -> IO CInt\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- sleeping\n"
           "\n"
           "sleep :: Int -> IO Int\n"
           "sleep 0 = return 0\n"
           "sleep secs = do r <- c_sleep (fromIntegral secs); return (fromIntegral r)\n"
           "\n"
           "foreign import ccall unsafe \"sleep\"\n"
           "  c_sleep :: CUInt -> IO CUInt\n"
           "\n"
           "usleep :: Int -> IO ()\n"
           "usleep 0 = return ()\n"
           "", stdout);
#line 101 "Unistd.hsc"
#ifdef USLEEP_RETURNS_VOID
    fputs ("\n"
           "", stdout);
    hsc_line (102, "Unistd.hsc");
    fputs ("usleep usecs = c_usleep (fromIntegral usecs)\n"
           "", stdout);
#line 103 "Unistd.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (104, "Unistd.hsc");
    fputs ("usleep usecs = throwErrnoIfMinus1_ \"usleep\" (c_usleep (fromIntegral usecs))\n"
           "", stdout);
#line 105 "Unistd.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (106, "Unistd.hsc");
    fputs ("\n"
           "", stdout);
#line 107 "Unistd.hsc"
#ifdef USLEEP_RETURNS_VOID
    fputs ("\n"
           "", stdout);
    hsc_line (108, "Unistd.hsc");
    fputs ("foreign import ccall unsafe \"usleep\"\n"
           "  c_usleep :: CUInt -> IO ()\n"
           "", stdout);
#line 110 "Unistd.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (111, "Unistd.hsc");
    fputs ("foreign import ccall unsafe \"usleep\"\n"
           "  c_usleep :: CUInt -> IO CInt\n"
           "", stdout);
#line 113 "Unistd.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (114, "Unistd.hsc");
    fputs ("\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- System variables\n"
           "\n"
           "data SysVar = ArgumentLimit\n"
           "            | ChildLimit\n"
           "            | ClockTick\n"
           "            | GroupLimit\n"
           "            | OpenFileLimit\n"
           "            | PosixVersion\n"
           "            | HasSavedIDs\n"
           "            | HasJobControl\n"
           "\t-- ToDo: lots more\n"
           "\n"
           "getSysVar :: SysVar -> IO Integer\n"
           "getSysVar v =\n"
           "    case v of\n"
           "      ArgumentLimit -> sysconf (", stdout);
#line 131 "Unistd.hsc"
    hsc_const (_SC_ARG_MAX);
    fputs (")\n"
           "", stdout);
    hsc_line (132, "Unistd.hsc");
    fputs ("      ChildLimit    -> sysconf (", stdout);
#line 132 "Unistd.hsc"
    hsc_const (_SC_CHILD_MAX);
    fputs (")\n"
           "", stdout);
    hsc_line (133, "Unistd.hsc");
    fputs ("      ClockTick\t    -> sysconf (", stdout);
#line 133 "Unistd.hsc"
    hsc_const (_SC_CLK_TCK);
    fputs (")\n"
           "", stdout);
    hsc_line (134, "Unistd.hsc");
    fputs ("      GroupLimit    -> sysconf (", stdout);
#line 134 "Unistd.hsc"
    hsc_const (_SC_NGROUPS_MAX);
    fputs (")\n"
           "", stdout);
    hsc_line (135, "Unistd.hsc");
    fputs ("      OpenFileLimit -> sysconf (", stdout);
#line 135 "Unistd.hsc"
    hsc_const (_SC_OPEN_MAX);
    fputs (")\n"
           "", stdout);
    hsc_line (136, "Unistd.hsc");
    fputs ("      PosixVersion  -> sysconf (", stdout);
#line 136 "Unistd.hsc"
    hsc_const (_SC_VERSION);
    fputs (")\n"
           "", stdout);
    hsc_line (137, "Unistd.hsc");
    fputs ("      HasSavedIDs   -> sysconf (", stdout);
#line 137 "Unistd.hsc"
    hsc_const (_SC_SAVED_IDS);
    fputs (")\n"
           "", stdout);
    hsc_line (138, "Unistd.hsc");
    fputs ("      HasJobControl -> sysconf (", stdout);
#line 138 "Unistd.hsc"
    hsc_const (_SC_JOB_CONTROL);
    fputs (")\n"
           "", stdout);
    hsc_line (139, "Unistd.hsc");
    fputs ("\n"
           "sysconf :: CInt -> IO Integer\n"
           "sysconf n = do \n"
           "  r <- throwErrnoIfMinus1 \"getSysVar\" (c_sysconf n)\n"
           "  return (fromIntegral r)\n"
           "\n"
           "foreign import ccall unsafe \"sysconf\"\n"
           "  c_sysconf :: CInt -> IO CLong\n"
           "", stdout);
    return 0;
}
