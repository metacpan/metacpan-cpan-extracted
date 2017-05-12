#include "template-hsc.h"
#line 28 "Temp.hsc"
#include "HsUnix.h"
#line 40 "Temp.hsc"
#if defined(__GLASGOW_HASKELL__) || defined(__HUGS__)
#line 46 "Temp.hsc"
#else 
#line 62 "Temp.hsc"
#endif 

int main (int argc, char *argv [])
{
#if __GLASGOW_HASKELL__ && __GLASGOW_HASKELL__ < 409
    printf ("{-# OPTIONS -optc-D__GLASGOW_HASKELL__=%d #-}\n", 603);
#endif
    printf ("{-# OPTIONS %s #-}\n", "-#include \"HsUnix.h\"");
#line 40 "Temp.hsc"
#if defined(__GLASGOW_HASKELL__) || defined(__HUGS__)
#line 46 "Temp.hsc"
#else 
#line 62 "Temp.hsc"
#endif 
    hsc_line (1, "Temp.hsc");
    fputs ("{-# OPTIONS -fffi #-}\n"
           "", stdout);
    hsc_line (2, "Temp.hsc");
    fputs ("-----------------------------------------------------------------------------\n"
           "-- |\n"
           "-- Module      :  System.Posix.Temp\n"
           "-- Copyright   :  (c) Volker Stolz <vs@foldr.org>\n"
           "-- License     :  BSD-style (see the file libraries/base/LICENSE)\n"
           "-- \n"
           "-- Maintainer  :  vs@foldr.org\n"
           "-- Stability   :  provisional\n"
           "-- Portability :  non-portable (requires POSIX)\n"
           "--\n"
           "-- POSIX environment support\n"
           "--\n"
           "-----------------------------------------------------------------------------\n"
           "\n"
           "module System.Posix.Temp (\n"
           "\n"
           "\tmkstemp\n"
           "\n"
           "{- Not ported (yet\?):\n"
           "\ttmpfile: can we handle FILE*\?\n"
           "\ttmpnam: ISO C, should go in base\?\n"
           "\ttempname: dito\n"
           "-}\n"
           "\n"
           ") where\n"
           "\n"
           "", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (29, "Temp.hsc");
    fputs ("\n"
           "import System.IO\n"
           "import System.Posix.IO\n"
           "import System.Posix.Types\n"
           "import Foreign.C\n"
           "\n"
           "-- |\'mkstemp\' - make a unique filename and open it for\n"
           "-- reading\\/writing (only safe on GHC & Hugs)\n"
           "\n"
           "mkstemp :: String -> IO (String, Handle)\n"
           "mkstemp template = do\n"
           "", stdout);
#line 40 "Temp.hsc"
#if defined(__GLASGOW_HASKELL__) || defined(__HUGS__)
    fputs ("\n"
           "", stdout);
    hsc_line (41, "Temp.hsc");
    fputs ("  withCString template $ \\ ptr -> do\n"
           "    fd <- throwErrnoIfMinus1 \"mkstemp\" (c_mkstemp ptr)\n"
           "    name <- peekCString ptr\n"
           "    h <- fdToHandle fd\n"
           "    return (name, h)\n"
           "", stdout);
#line 46 "Temp.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (47, "Temp.hsc");
    fputs ("  name <- mktemp template\n"
           "  h <- openFile name ReadWriteMode\n"
           "  return (name, h)\n"
           "\n"
           "-- |\'mktemp\' - make a unique file name\n"
           "-- This function should be considered deprecated\n"
           "\n"
           "mktemp :: String -> IO String\n"
           "mktemp template = do\n"
           "  withCString template $ \\ ptr -> do\n"
           "    ptr <- throwErrnoIfNull \"mktemp\" (c_mktemp ptr)\n"
           "    peekCString ptr\n"
           "\n"
           "foreign import ccall unsafe \"mktemp\"\n"
           "  c_mktemp :: CString -> IO CString\n"
           "", stdout);
#line 62 "Temp.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (63, "Temp.hsc");
    fputs ("\n"
           "foreign import ccall unsafe \"mkstemp\"\n"
           "  c_mkstemp :: CString -> IO Fd\n"
           "\n"
           "", stdout);
    return 0;
}
