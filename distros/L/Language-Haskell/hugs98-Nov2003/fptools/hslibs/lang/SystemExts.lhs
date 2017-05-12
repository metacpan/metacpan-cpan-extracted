% -----------------------------------------------------------------------------
% $Id: SystemExts.lhs,v 1.8 2002/08/28 13:59:19 simonmar Exp $
%
% (c) The GHC Team, 2001
%

Systemy extensions.

\begin{code}
{-# OPTIONS -#include "HsLang.h" #-}
module SystemExts
	( rawSystem,     -- :: String -> IO ExitCode

	, withArgs       -- :: [String] -> IO a -> IO a
	, withProgName   -- :: String -> IO a -> IO a
	
	, getEnvironment -- :: IO [(String, String)]
	
	) where

import Foreign.C
import Foreign

import System.Cmd
import System.Environment
import Foreign.Ptr
import Control.Monad

import GHC.IOBase
\end{code}

Get at the environment block -- also provided by Posix.

\begin{code}
getEnvironment :: IO [(String, String)]
getEnvironment = do
   pBlock <- getEnvBlock
   if pBlock == nullPtr then return []
    else do
      stuff <- peekArray0 nullPtr pBlock >>= mapM peekCString
      return (map divvy stuff)
  where
   divvy str = 
      case break (=='=') str of
        (xs,[])        -> (xs,[]) -- don't barf (like Posix.getEnvironment)
	(name,_:value) -> (name,value)

foreign import ccall unsafe "getEnvBlock" getEnvBlock :: IO (Ptr CString)
\end{code}
