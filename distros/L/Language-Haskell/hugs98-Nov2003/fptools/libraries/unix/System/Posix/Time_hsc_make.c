#include "template-hsc.h"
#line 22 "Time.hsc"
#include "HsUnix.h"

int main (int argc, char *argv [])
{
#if __GLASGOW_HASKELL__ && __GLASGOW_HASKELL__ < 409
    printf ("{-# OPTIONS -optc-D__GLASGOW_HASKELL__=%d #-}\n", 603);
#endif
    printf ("{-# OPTIONS %s #-}\n", "-#include \"HsUnix.h\"");
    hsc_line (1, "Time.hsc");
    fputs ("{-# OPTIONS -fffi #-}\n"
           "", stdout);
    hsc_line (2, "Time.hsc");
    fputs ("-----------------------------------------------------------------------------\n"
           "-- |\n"
           "-- Module      :  System.Posix.Time\n"
           "-- Copyright   :  (c) The University of Glasgow 2002\n"
           "-- License     :  BSD-style (see the file libraries/base/LICENSE)\n"
           "-- \n"
           "-- Maintainer  :  libraries@haskell.org\n"
           "-- Stability   :  provisional\n"
           "-- Portability :  non-portable (requires POSIX)\n"
           "--\n"
           "-- POSIX Time support\n"
           "--\n"
           "-----------------------------------------------------------------------------\n"
           "\n"
           "module System.Posix.Time (\n"
           "\tepochTime,\n"
           "\t-- ToDo: lots more from sys/time.h\n"
           "\t-- how much already supported by System.Time\?\n"
           "  ) where\n"
           "\n"
           "", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (23, "Time.hsc");
    fputs ("\n"
           "import System.Posix.Types\n"
           "import Foreign\n"
           "import Foreign.C\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- epochTime\n"
           "\n"
           "epochTime :: IO EpochTime\n"
           "epochTime = throwErrnoIfMinus1 \"epochTime\" (c_time nullPtr)\n"
           "\n"
           "foreign import ccall unsafe \"time\"\n"
           "  c_time :: Ptr CTime -> IO CTime\n"
           "", stdout);
    return 0;
}
