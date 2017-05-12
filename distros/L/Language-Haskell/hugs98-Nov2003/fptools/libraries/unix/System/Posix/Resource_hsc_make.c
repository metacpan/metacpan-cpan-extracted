#include "template-hsc.h"
#line 23 "Resource.hsc"
#include "HsUnix.h"
#line 39 "Resource.hsc"
#ifdef RLIMIT_AS
#line 41 "Resource.hsc"
#endif 
#line 90 "Resource.hsc"
#ifdef RLIMIT_AS
#line 92 "Resource.hsc"
#endif 
#line 96 "Resource.hsc"
#ifdef RLIM_SAVED_MAX
#line 99 "Resource.hsc"
#endif 
#line 104 "Resource.hsc"
#ifdef RLIM_SAVED_MAX
#line 107 "Resource.hsc"
#endif 

int main (int argc, char *argv [])
{
#if __GLASGOW_HASKELL__ && __GLASGOW_HASKELL__ < 409
    printf ("{-# OPTIONS -optc-D__GLASGOW_HASKELL__=%d #-}\n", 603);
#endif
    printf ("{-# OPTIONS %s #-}\n", "-#include \"HsUnix.h\"");
#line 39 "Resource.hsc"
#ifdef RLIMIT_AS
#line 41 "Resource.hsc"
#endif 
#line 90 "Resource.hsc"
#ifdef RLIMIT_AS
#line 92 "Resource.hsc"
#endif 
#line 96 "Resource.hsc"
#ifdef RLIM_SAVED_MAX
#line 99 "Resource.hsc"
#endif 
#line 104 "Resource.hsc"
#ifdef RLIM_SAVED_MAX
#line 107 "Resource.hsc"
#endif 
    hsc_line (1, "Resource.hsc");
    fputs ("{-# OPTIONS -fffi #-}\n"
           "", stdout);
    hsc_line (2, "Resource.hsc");
    fputs ("-----------------------------------------------------------------------------\n"
           "-- |\n"
           "-- Module      :  System.Posix.Resource\n"
           "-- Copyright   :  (c) The University of Glasgow 2003\n"
           "-- License     :  BSD-style (see the file libraries/base/LICENSE)\n"
           "-- \n"
           "-- Maintainer  :  libraries@haskell.org\n"
           "-- Stability   :  provisional\n"
           "-- Portability :  non-portable (requires POSIX)\n"
           "--\n"
           "-- POSIX resource support\n"
           "--\n"
           "-----------------------------------------------------------------------------\n"
           "\n"
           "module System.Posix.Resource (\n"
           "    -- * Resource Limits\n"
           "    ResourceLimit(..), ResourceLimits(..), Resource(..),\n"
           "    getResourceLimit,\n"
           "    setResourceLimit,\n"
           "  ) where\n"
           "\n"
           "", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (24, "Resource.hsc");
    fputs ("\n"
           "import System.Posix.Types\n"
           "import Foreign\n"
           "import Foreign.C\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Resource limits\n"
           "\n"
           "data Resource\n"
           "  = ResourceCoreFileSize\n"
           "  | ResourceCPUTime\n"
           "  | ResourceDataSize\n"
           "  | ResourceFileSize\n"
           "  | ResourceOpenFiles\n"
           "  | ResourceStackSize\n"
           "", stdout);
#line 39 "Resource.hsc"
#ifdef RLIMIT_AS
    fputs ("\n"
           "", stdout);
    hsc_line (40, "Resource.hsc");
    fputs ("  | ResourceTotalMemory\n"
           "", stdout);
#line 41 "Resource.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (42, "Resource.hsc");
    fputs ("  deriving Eq\n"
           "\n"
           "data ResourceLimits\n"
           "  = ResourceLimits { softLimit, hardLimit :: ResourceLimit }\n"
           "  deriving Eq\n"
           "\n"
           "data ResourceLimit\n"
           "  = ResourceLimitInfinity\n"
           "  | ResourceLimitUnknown\n"
           "  | ResourceLimit Integer\n"
           "  deriving Eq\n"
           "\n"
           "type RLimit = ()\n"
           "\n"
           "foreign import ccall unsafe \"getrlimit\"\n"
           "  c_getrlimit :: CInt -> Ptr RLimit -> IO CInt\n"
           "\n"
           "foreign import ccall unsafe \"setrlimit\"\n"
           "  c_setrlimit :: CInt -> Ptr RLimit -> IO CInt\n"
           "\n"
           "getResourceLimit :: Resource -> IO ResourceLimits\n"
           "getResourceLimit res = do\n"
           "  allocaBytes (", stdout);
#line 64 "Resource.hsc"
    hsc_const (sizeof(struct rlimit));
    fputs (") $ \\p_rlimit -> do\n"
           "", stdout);
    hsc_line (65, "Resource.hsc");
    fputs ("    throwErrnoIfMinus1 \"getResourceLimit\" $\n"
           "      c_getrlimit (packResource res) p_rlimit\n"
           "    soft <- (", stdout);
#line 67 "Resource.hsc"
    hsc_peek (struct rlimit, rlim_cur);
    fputs (") p_rlimit\n"
           "", stdout);
    hsc_line (68, "Resource.hsc");
    fputs ("    hard <- (", stdout);
#line 68 "Resource.hsc"
    hsc_peek (struct rlimit, rlim_max);
    fputs (") p_rlimit\n"
           "", stdout);
    hsc_line (69, "Resource.hsc");
    fputs ("    return (ResourceLimits { \n"
           "\t\tsoftLimit = unpackRLimit soft,\n"
           "\t\thardLimit = unpackRLimit hard\n"
           "\t   })\n"
           "\n"
           "setResourceLimit :: Resource -> ResourceLimits -> IO ()\n"
           "setResourceLimit res ResourceLimits{softLimit=soft,hardLimit=hard} = do\n"
           "  allocaBytes (", stdout);
#line 76 "Resource.hsc"
    hsc_const (sizeof(struct rlimit));
    fputs (") $ \\p_rlimit -> do\n"
           "", stdout);
    hsc_line (77, "Resource.hsc");
    fputs ("    (", stdout);
#line 77 "Resource.hsc"
    hsc_poke (struct rlimit, rlim_cur);
    fputs (") p_rlimit (packRLimit soft True)\n"
           "", stdout);
    hsc_line (78, "Resource.hsc");
    fputs ("    (", stdout);
#line 78 "Resource.hsc"
    hsc_poke (struct rlimit, rlim_max);
    fputs (") p_rlimit (packRLimit hard False)\n"
           "", stdout);
    hsc_line (79, "Resource.hsc");
    fputs ("    throwErrnoIfMinus1 \"setResourceLimit\" $\n"
           "\tc_setrlimit (packResource res) p_rlimit\n"
           "    return ()\n"
           "\n"
           "packResource :: Resource -> CInt\n"
           "packResource ResourceCoreFileSize  = (", stdout);
#line 84 "Resource.hsc"
    hsc_const (RLIMIT_CORE);
    fputs (")\n"
           "", stdout);
    hsc_line (85, "Resource.hsc");
    fputs ("packResource ResourceCPUTime       = (", stdout);
#line 85 "Resource.hsc"
    hsc_const (RLIMIT_CPU);
    fputs (")\n"
           "", stdout);
    hsc_line (86, "Resource.hsc");
    fputs ("packResource ResourceDataSize      = (", stdout);
#line 86 "Resource.hsc"
    hsc_const (RLIMIT_DATA);
    fputs (")\n"
           "", stdout);
    hsc_line (87, "Resource.hsc");
    fputs ("packResource ResourceFileSize      = (", stdout);
#line 87 "Resource.hsc"
    hsc_const (RLIMIT_FSIZE);
    fputs (")\n"
           "", stdout);
    hsc_line (88, "Resource.hsc");
    fputs ("packResource ResourceOpenFiles     = (", stdout);
#line 88 "Resource.hsc"
    hsc_const (RLIMIT_NOFILE);
    fputs (")\n"
           "", stdout);
    hsc_line (89, "Resource.hsc");
    fputs ("packResource ResourceStackSize     = (", stdout);
#line 89 "Resource.hsc"
    hsc_const (RLIMIT_STACK);
    fputs (")\n"
           "", stdout);
    hsc_line (90, "Resource.hsc");
    fputs ("", stdout);
#line 90 "Resource.hsc"
#ifdef RLIMIT_AS
    fputs ("\n"
           "", stdout);
    hsc_line (91, "Resource.hsc");
    fputs ("packResource ResourceTotalMemory   = (", stdout);
#line 91 "Resource.hsc"
    hsc_const (RLIMIT_AS);
    fputs (")\n"
           "", stdout);
    hsc_line (92, "Resource.hsc");
    fputs ("", stdout);
#line 92 "Resource.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (93, "Resource.hsc");
    fputs ("\n"
           "unpackRLimit :: CRLim -> ResourceLimit\n"
           "unpackRLimit (", stdout);
#line 95 "Resource.hsc"
    hsc_const (RLIM_INFINITY);
    fputs (")  = ResourceLimitInfinity\n"
           "", stdout);
    hsc_line (96, "Resource.hsc");
    fputs ("", stdout);
#line 96 "Resource.hsc"
#ifdef RLIM_SAVED_MAX
    fputs ("\n"
           "", stdout);
    hsc_line (97, "Resource.hsc");
    fputs ("unpackRLimit (", stdout);
#line 97 "Resource.hsc"
    hsc_const (RLIM_SAVED_MAX);
    fputs (") = ResourceLimitUnknown\n"
           "", stdout);
    hsc_line (98, "Resource.hsc");
    fputs ("unpackRLimit (", stdout);
#line 98 "Resource.hsc"
    hsc_const (RLIM_SAVED_CUR);
    fputs (") = ResourceLimitUnknown\n"
           "", stdout);
    hsc_line (99, "Resource.hsc");
    fputs ("", stdout);
#line 99 "Resource.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (100, "Resource.hsc");
    fputs ("unpackRLimit other = ResourceLimit (fromIntegral other)\n"
           "\n"
           "packRLimit :: ResourceLimit -> Bool -> CRLim\n"
           "packRLimit ResourceLimitInfinity _     = (", stdout);
#line 103 "Resource.hsc"
    hsc_const (RLIM_INFINITY);
    fputs (")\n"
           "", stdout);
    hsc_line (104, "Resource.hsc");
    fputs ("", stdout);
#line 104 "Resource.hsc"
#ifdef RLIM_SAVED_MAX
    fputs ("\n"
           "", stdout);
    hsc_line (105, "Resource.hsc");
    fputs ("packRLimit ResourceLimitUnknown  True  = (", stdout);
#line 105 "Resource.hsc"
    hsc_const (RLIM_SAVED_CUR);
    fputs (")\n"
           "", stdout);
    hsc_line (106, "Resource.hsc");
    fputs ("packRLimit ResourceLimitUnknown  False = (", stdout);
#line 106 "Resource.hsc"
    hsc_const (RLIM_SAVED_MAX);
    fputs (")\n"
           "", stdout);
    hsc_line (107, "Resource.hsc");
    fputs ("", stdout);
#line 107 "Resource.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (108, "Resource.hsc");
    fputs ("packRLimit (ResourceLimit other) _     = fromIntegral other\n"
           "\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Test code\n"
           "\n"
           "{-\n"
           "import System.Posix\n"
           "import Control.Monad\n"
           "\n"
           "main = do\n"
           " zipWithM_ (\\r n -> setResourceLimit r ResourceLimits{\n"
           "\t\t\t\t\thardLimit = ResourceLimit n,\n"
           "\t\t\t\t\tsoftLimit = ResourceLimit n })\n"
           "\tallResources [1..]\t\n"
           " showAll\n"
           " mapM_ (\\r -> setResourceLimit r ResourceLimits{\n"
           "\t\t\t\t\thardLimit = ResourceLimit 1,\n"
           "\t\t\t\t\tsoftLimit = ResourceLimitInfinity })\n"
           "\tallResources\n"
           "   -- should fail\n"
           "\n"
           "\n"
           "showAll = \n"
           "  mapM_ (\\r -> getResourceLimit r >>= (putStrLn . showRLims)) allResources\n"
           "\n"
           "allResources =\n"
           "    [ResourceCoreFileSize, ResourceCPUTime, ResourceDataSize,\n"
           "\tResourceFileSize, ResourceOpenFiles, ResourceStackSize\n"
           "#ifdef RLIMIT_AS\n"
           "\t, ResourceTotalMemory \n"
           "#endif\n"
           "\t]\n"
           "\n"
           "showRLims ResourceLimits{hardLimit=h,softLimit=s}\n"
           "  = \"hard: \" ++ showRLim h ++ \", soft: \" ++ showRLim s\n"
           " \n"
           "showRLim ResourceLimitInfinity = \"infinity\"\n"
           "showRLim ResourceLimitUnknown  = \"unknown\"\n"
           "showRLim (ResourceLimit other)  = show other\n"
           "-}\n"
           "", stdout);
    return 0;
}
