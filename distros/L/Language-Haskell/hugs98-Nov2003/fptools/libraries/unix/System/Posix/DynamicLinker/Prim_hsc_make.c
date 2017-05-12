#include "template-hsc.h"
#line 35 "Prim.hsc"
#include "HsUnix.h"
#line 56 "Prim.hsc"
#ifdef HAVE_RTLDNEXT
#line 61 "Prim.hsc"
#else /* HAVE_RTLDNEXT */
#line 63 "Prim.hsc"
#endif /* HAVE_RTLDNEXT */
#line 67 "Prim.hsc"
#ifdef HAVE_RTLDLOCAL
#line 69 "Prim.hsc"
#else /* HAVE_RTLDLOCAL */
#line 71 "Prim.hsc"
#endif /* HAVE_RTLDLOCAL */
#line 91 "Prim.hsc"
#ifdef HAVE_RTLDNOW
#line 93 "Prim.hsc"
#else /* HAVE_RTLDNOW */
#line 95 "Prim.hsc"
#endif /* HAVE_RTLDNOW */
#line 97 "Prim.hsc"
#ifdef HAVE_RTLDGLOBAL
#line 99 "Prim.hsc"
#else /* HAVE_RTLDGLOBAL */
#line 101 "Prim.hsc"
#endif 
#line 103 "Prim.hsc"
#ifdef HAVE_RTLDLOCAL
#line 105 "Prim.hsc"
#else /* HAVE_RTLDLOCAL */
#line 107 "Prim.hsc"
#endif /* HAVE_RTLDLOCAL */
#line 116 "Prim.hsc"
#ifdef HAVE_RTLDNEXT
#line 118 "Prim.hsc"
#else 
#line 120 "Prim.hsc"
#endif 

int main (int argc, char *argv [])
{
#if __GLASGOW_HASKELL__ && __GLASGOW_HASKELL__ < 409
    printf ("{-# OPTIONS -optc-D__GLASGOW_HASKELL__=%d #-}\n", 603);
#endif
    printf ("{-# OPTIONS %s #-}\n", "-#include \"HsUnix.h\"");
#line 56 "Prim.hsc"
#ifdef HAVE_RTLDNEXT
#line 61 "Prim.hsc"
#else /* HAVE_RTLDNEXT */
#line 63 "Prim.hsc"
#endif /* HAVE_RTLDNEXT */
#line 67 "Prim.hsc"
#ifdef HAVE_RTLDLOCAL
#line 69 "Prim.hsc"
#else /* HAVE_RTLDLOCAL */
#line 71 "Prim.hsc"
#endif /* HAVE_RTLDLOCAL */
#line 91 "Prim.hsc"
#ifdef HAVE_RTLDNOW
#line 93 "Prim.hsc"
#else /* HAVE_RTLDNOW */
#line 95 "Prim.hsc"
#endif /* HAVE_RTLDNOW */
#line 97 "Prim.hsc"
#ifdef HAVE_RTLDGLOBAL
#line 99 "Prim.hsc"
#else /* HAVE_RTLDGLOBAL */
#line 101 "Prim.hsc"
#endif 
#line 103 "Prim.hsc"
#ifdef HAVE_RTLDLOCAL
#line 105 "Prim.hsc"
#else /* HAVE_RTLDLOCAL */
#line 107 "Prim.hsc"
#endif /* HAVE_RTLDLOCAL */
#line 116 "Prim.hsc"
#ifdef HAVE_RTLDNEXT
#line 118 "Prim.hsc"
#else 
#line 120 "Prim.hsc"
#endif 
    hsc_line (1, "Prim.hsc");
    fputs ("{-# OPTIONS -fffi #-}\n"
           "", stdout);
    hsc_line (2, "Prim.hsc");
    fputs ("-----------------------------------------------------------------------------\n"
           "-- |\n"
           "-- Module      :  System.Posix.DynamicLinker.Prim\n"
           "-- Copyright   :  (c) Volker Stolz <vs@foldr.org> 2003\n"
           "-- License     :  BSD-style (see the file libraries/base/LICENSE)\n"
           "-- \n"
           "-- Maintainer  :  vs@foldr.org\n"
           "-- Stability   :  provisional\n"
           "-- Portability :  non-portable (requires POSIX)\n"
           "--\n"
           "-- DLOpen and friend\n"
           "--  Derived from GModule.chs by M.Weber & M.Chakravarty which is part of c2hs\n"
           "--  I left the API more or less the same, mostly the flags are different.\n"
           "--\n"
           "-----------------------------------------------------------------------------\n"
           "\n"
           "module System.Posix.DynamicLinker.Prim (\n"
           "  -- * low level API\n"
           "  c_dlopen,\n"
           "  c_dlsym,\n"
           "  c_dlerror,\n"
           "  c_dlclose,\n"
           "  -- dlAddr, -- XXX NYI\n"
           "  haveRtldNext,\n"
           "  haveRtldLocal,\n"
           "  packRTLDFlags,\n"
           "  RTLDFlags(..),\n"
           "  packDL,\n"
           "  DL(..)\n"
           " )\n"
           "\n"
           "where\n"
           "\n"
           "", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (36, "Prim.hsc");
    fputs ("\n"
           "import Data.Bits\t( (.|.) )\n"
           "import Foreign.Ptr\t( Ptr, FunPtr, nullPtr )\n"
           "import Foreign.C.Types\t( CInt )\n"
           "import Foreign.C.String\t( CString )\n"
           "\n"
           "-- RTLD_NEXT madness\n"
           "-- On some host (e.g. SuSe Linux 7.2) RTLD_NEXT is not visible\n"
           "-- without setting _GNU_SOURCE. Since we don\'t want to set this\n"
           "-- flag, here\'s a different solution: You can use the Haskell\n"
           "-- function \'haveRtldNext\' to check wether the flag is available\n"
           "-- to you. Ideally, this will be optimized by the compiler so\n"
           "-- that it should be as efficient as an #ifdef.\n"
           "--    If you fail to test the flag and use it although it is\n"
           "-- undefined, \'packOneModuleFlag\' will bomb.\n"
           "--    The same applies to RTLD_LOCAL which isn\'t available on\n"
           "-- cygwin.\n"
           "\n"
           "haveRtldNext :: Bool\n"
           "\n"
           "", stdout);
#line 56 "Prim.hsc"
#ifdef HAVE_RTLDNEXT
    fputs ("\n"
           "", stdout);
    hsc_line (57, "Prim.hsc");
    fputs ("haveRtldNext = True\n"
           "\n"
           "foreign import ccall unsafe \"__hsunix_rtldNext\" rtldNext :: Ptr a\n"
           "\n"
           "", stdout);
#line 61 "Prim.hsc"
#else /* HAVE_RTLDNEXT */
    fputs ("\n"
           "", stdout);
    hsc_line (62, "Prim.hsc");
    fputs ("haveRtldNext = False\n"
           "", stdout);
#line 63 "Prim.hsc"
#endif /* HAVE_RTLDNEXT */
    fputs ("\n"
           "", stdout);
    hsc_line (64, "Prim.hsc");
    fputs ("\n"
           "haveRtldLocal :: Bool\n"
           "\n"
           "", stdout);
#line 67 "Prim.hsc"
#ifdef HAVE_RTLDLOCAL
    fputs ("\n"
           "", stdout);
    hsc_line (68, "Prim.hsc");
    fputs ("haveRtldLocal = True\n"
           "", stdout);
#line 69 "Prim.hsc"
#else /* HAVE_RTLDLOCAL */
    fputs ("\n"
           "", stdout);
    hsc_line (70, "Prim.hsc");
    fputs ("haveRtldLocal = False\n"
           "", stdout);
#line 71 "Prim.hsc"
#endif /* HAVE_RTLDLOCAL */
    fputs ("\n"
           "", stdout);
    hsc_line (72, "Prim.hsc");
    fputs ("\n"
           "data RTLDFlags \n"
           "  = RTLD_LAZY\n"
           "  | RTLD_NOW\n"
           "  | RTLD_GLOBAL \n"
           "  | RTLD_LOCAL\n"
           "    deriving (Show, Read)\n"
           "\n"
           "foreign import ccall unsafe \"dlopen\" c_dlopen :: CString -> CInt -> IO (Ptr ())\n"
           "foreign import ccall unsafe \"dlsym\"  c_dlsym  :: Ptr () -> CString -> IO (FunPtr a)\n"
           "foreign import ccall unsafe \"dlerror\" c_dlerror :: IO CString\n"
           "foreign import ccall unsafe \"dlclose\" c_dlclose :: (Ptr ()) -> IO CInt\n"
           "\n"
           "packRTLDFlags :: [RTLDFlags] -> CInt\n"
           "packRTLDFlags flags = foldl (\\ s f -> (packRTLDFlag f) .|. s) 0 flags\n"
           "\n"
           "packRTLDFlag :: RTLDFlags -> CInt\n"
           "packRTLDFlag RTLD_LAZY = ", stdout);
#line 89 "Prim.hsc"
    hsc_const (RTLD_LAZY);
    fputs ("\n"
           "", stdout);
    hsc_line (90, "Prim.hsc");
    fputs ("\n"
           "", stdout);
#line 91 "Prim.hsc"
#ifdef HAVE_RTLDNOW
    fputs ("\n"
           "", stdout);
    hsc_line (92, "Prim.hsc");
    fputs ("packRTLDFlag RTLD_NOW = ", stdout);
#line 92 "Prim.hsc"
    hsc_const (RTLD_NOW);
    fputs ("\n"
           "", stdout);
    hsc_line (93, "Prim.hsc");
    fputs ("", stdout);
#line 93 "Prim.hsc"
#else /* HAVE_RTLDNOW */
    fputs ("\n"
           "", stdout);
    hsc_line (94, "Prim.hsc");
    fputs ("packRTLDFlag RTLD_NOW =  error \"RTLD_NOW not available\"\n"
           "", stdout);
#line 95 "Prim.hsc"
#endif /* HAVE_RTLDNOW */
    fputs ("\n"
           "", stdout);
    hsc_line (96, "Prim.hsc");
    fputs ("\n"
           "", stdout);
#line 97 "Prim.hsc"
#ifdef HAVE_RTLDGLOBAL
    fputs ("\n"
           "", stdout);
    hsc_line (98, "Prim.hsc");
    fputs ("packRTLDFlag RTLD_GLOBAL = ", stdout);
#line 98 "Prim.hsc"
    hsc_const (RTLD_GLOBAL);
    fputs ("\n"
           "", stdout);
    hsc_line (99, "Prim.hsc");
    fputs ("", stdout);
#line 99 "Prim.hsc"
#else /* HAVE_RTLDGLOBAL */
    fputs ("\n"
           "", stdout);
    hsc_line (100, "Prim.hsc");
    fputs ("packRTLDFlag RTLD_GLOBAL = error \"RTLD_GLOBAL not available\"\n"
           "", stdout);
#line 101 "Prim.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (102, "Prim.hsc");
    fputs ("\n"
           "", stdout);
#line 103 "Prim.hsc"
#ifdef HAVE_RTLDLOCAL
    fputs ("\n"
           "", stdout);
    hsc_line (104, "Prim.hsc");
    fputs ("packRTLDFlag RTLD_LOCAL = ", stdout);
#line 104 "Prim.hsc"
    hsc_const (RTLD_LOCAL);
    fputs ("\n"
           "", stdout);
    hsc_line (105, "Prim.hsc");
    fputs ("", stdout);
#line 105 "Prim.hsc"
#else /* HAVE_RTLDLOCAL */
    fputs ("\n"
           "", stdout);
    hsc_line (106, "Prim.hsc");
    fputs ("packRTLDFlag RTLD_LOCAL = error \"RTLD_LOCAL not available\"\n"
           "", stdout);
#line 107 "Prim.hsc"
#endif /* HAVE_RTLDLOCAL */
    fputs ("\n"
           "", stdout);
    hsc_line (108, "Prim.hsc");
    fputs ("\n"
           "-- |Flags for \'dlsym\'. Notice that @Next@ might not be available on\n"
           "-- your particular platform!\n"
           "\n"
           "data DL = Null | Next | Default | DLHandle (Ptr ()) deriving (Show)\n"
           "\n"
           "packDL :: DL -> Ptr ()\n"
           "packDL Null = nullPtr\n"
           "", stdout);
#line 116 "Prim.hsc"
#ifdef HAVE_RTLDNEXT
    fputs ("\n"
           "", stdout);
    hsc_line (117, "Prim.hsc");
    fputs ("packDL Next = rtldNext\n"
           "", stdout);
#line 118 "Prim.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (119, "Prim.hsc");
    fputs ("packDL Next = error \"RTLD_NEXT not available\"\n"
           "", stdout);
#line 120 "Prim.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (121, "Prim.hsc");
    fputs ("packDL Default = nullPtr\n"
           "packDL (DLHandle h) = h\n"
           "", stdout);
    return 0;
}
