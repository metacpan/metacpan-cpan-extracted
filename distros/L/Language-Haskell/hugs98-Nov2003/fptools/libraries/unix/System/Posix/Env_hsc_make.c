#include "template-hsc.h"
#line 26 "Env.hsc"
#include "HsUnix.h"
#line 80 "Env.hsc"
#ifdef HAVE_UNSETENV
#line 86 "Env.hsc"
#else 
#line 88 "Env.hsc"
#endif 
#line 108 "Env.hsc"
#ifdef HAVE_SETENV
#line 117 "Env.hsc"
#else 
#line 124 "Env.hsc"
#endif 

int main (int argc, char *argv [])
{
#if __GLASGOW_HASKELL__ && __GLASGOW_HASKELL__ < 409
    printf ("{-# OPTIONS -optc-D__GLASGOW_HASKELL__=%d #-}\n", 603);
#endif
    printf ("{-# OPTIONS %s #-}\n", "-#include \"HsUnix.h\"");
#line 80 "Env.hsc"
#ifdef HAVE_UNSETENV
#line 86 "Env.hsc"
#else 
#line 88 "Env.hsc"
#endif 
#line 108 "Env.hsc"
#ifdef HAVE_SETENV
#line 117 "Env.hsc"
#else 
#line 124 "Env.hsc"
#endif 
    hsc_line (1, "Env.hsc");
    fputs ("{-# OPTIONS -fffi #-}\n"
           "", stdout);
    hsc_line (2, "Env.hsc");
    fputs ("-----------------------------------------------------------------------------\n"
           "-- |\n"
           "-- Module      :  System.Posix.Env\n"
           "-- Copyright   :  (c) The University of Glasgow 2002\n"
           "-- License     :  BSD-style (see the file libraries/base/LICENSE)\n"
           "-- \n"
           "-- Maintainer  :  libraries@haskell.org\n"
           "-- Stability   :  provisional\n"
           "-- Portability :  non-portable (requires POSIX)\n"
           "--\n"
           "-- POSIX environment support\n"
           "--\n"
           "-----------------------------------------------------------------------------\n"
           "\n"
           "module System.Posix.Env (\n"
           "\tgetEnv\n"
           "\t, getEnvDefault\n"
           "\t, getEnvironmentPrim\n"
           "\t, getEnvironment\n"
           "\t, putEnv\n"
           "\t, setEnv\n"
           "\t, unsetEnv\n"
           ") where\n"
           "\n"
           "", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (27, "Env.hsc");
    fputs ("\n"
           "import Foreign.C.Error\t( throwErrnoIfMinus1_ )\n"
           "import Foreign.C.Types\t( CInt )\n"
           "import Foreign.C.String\n"
           "import Foreign.Marshal.Array\n"
           "import Foreign.Ptr\n"
           "import Foreign.Storable\n"
           "import Control.Monad\t( liftM )\n"
           "import Data.Maybe\t( fromMaybe )\n"
           "\n"
           "-- |\'getEnv\' looks up a variable in the environment.\n"
           "\n"
           "getEnv :: String -> IO (Maybe String)\n"
           "getEnv name = do\n"
           "  litstring <- withCString name c_getenv\n"
           "  if litstring /= nullPtr\n"
           "     then liftM Just $ peekCString litstring\n"
           "     else return Nothing\n"
           "\n"
           "-- |\'getEnvDefault\' is a wrapper around \'getEnvVar\' where the\n"
           "-- programmer can specify a fallback if the variable is not found\n"
           "-- in the environment.\n"
           "\n"
           "getEnvDefault :: String -> String -> IO String\n"
           "getEnvDefault name fallback = liftM (fromMaybe fallback) (getEnv name)\n"
           "\n"
           "foreign import ccall unsafe \"getenv\"\n"
           "   c_getenv :: CString -> IO CString\n"
           "\n"
           "getEnvironmentPrim :: IO [String]\n"
           "getEnvironmentPrim = do\n"
           "  c_environ <- peek c_environ_p\n"
           "  arr <- peekArray0 nullPtr c_environ\n"
           "  mapM peekCString arr\n"
           "\n"
           "foreign import ccall unsafe \"&environ\"\n"
           "   c_environ_p :: Ptr (Ptr CString)\n"
           "\n"
           "-- |\'getEnvironment\' retrieves the entire environment as a\n"
           "-- list of @(key,value)@ pairs.\n"
           "\n"
           "getEnvironment :: IO [(String,String)]\n"
           "getEnvironment = do\n"
           "  env <- getEnvironmentPrim\n"
           "  return $ map (dropEq.(break ((==) \'=\'))) env\n"
           " where\n"
           "   dropEq (x,\'=\':ys) = (x,ys)\n"
           "   dropEq (x,_)      = error $ \"getEnvironment: insane variable \" ++ x\n"
           "\n"
           "-- |The \'unsetenv\' function deletes all instances of the variable name\n"
           "-- from the environment.\n"
           "\n"
           "unsetEnv :: String -> IO ()\n"
           "", stdout);
#line 80 "Env.hsc"
#ifdef HAVE_UNSETENV
    fputs ("\n"
           "", stdout);
    hsc_line (81, "Env.hsc");
    fputs ("\n"
           "unsetEnv name = withCString name c_unsetenv\n"
           "\n"
           "foreign import ccall unsafe \"unsetenv\"\n"
           "   c_unsetenv :: CString -> IO ()\n"
           "", stdout);
#line 86 "Env.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (87, "Env.hsc");
    fputs ("unsetEnv name = putEnv (name ++ \"=\")\n"
           "", stdout);
#line 88 "Env.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (89, "Env.hsc");
    fputs ("\n"
           "-- |\'putEnv\' function takes an argument of the form @name=value@\n"
           "-- and is equivalent to @setEnv(key,value,True{-overwrite-})@.\n"
           "\n"
           "putEnv :: String -> IO ()\n"
           "putEnv keyvalue = withCString keyvalue $ \\s ->\n"
           "  throwErrnoIfMinus1_ \"putenv\" (c_putenv s)\n"
           "\n"
           "foreign import ccall unsafe \"putenv\"\n"
           "   c_putenv :: CString -> IO CInt\n"
           "\n"
           "{- |The \'setenv\' function inserts or resets the environment variable name in\n"
           "     the current environment list.  If the variable @name@ does not exist in the\n"
           "     list, it is inserted with the given value.  If the variable does exist,\n"
           "     the argument @overwrite@ is tested; if @overwrite@ is @False@, the variable is\n"
           "     not reset, otherwise it is reset to the given value.\n"
           "-}\n"
           "\n"
           "setEnv :: String -> String -> Bool {-overwrite-} -> IO ()\n"
           "", stdout);
#line 108 "Env.hsc"
#ifdef HAVE_SETENV
    fputs ("\n"
           "", stdout);
    hsc_line (109, "Env.hsc");
    fputs ("setEnv key value ovrwrt = do\n"
           "  withCString key $ \\ keyP ->\n"
           "    withCString value $ \\ valueP ->\n"
           "      throwErrnoIfMinus1_ \"putenv\" $\n"
           "\tc_setenv keyP valueP (fromIntegral (fromEnum ovrwrt))\n"
           "\n"
           "foreign import ccall unsafe \"setenv\"\n"
           "   c_setenv :: CString -> CString -> CInt -> IO CInt\n"
           "", stdout);
#line 117 "Env.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (118, "Env.hsc");
    fputs ("setEnv key value True = putEnv (key++\"=\"++value)\n"
           "setEnv key value False = do\n"
           "  res <- getEnv key\n"
           "  case res of\n"
           "    Just _  -> return ()\n"
           "    Nothing -> putEnv (key++\"=\"++value)\n"
           "", stdout);
#line 124 "Env.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (125, "Env.hsc");
    fputs ("", stdout);
    return 0;
}
