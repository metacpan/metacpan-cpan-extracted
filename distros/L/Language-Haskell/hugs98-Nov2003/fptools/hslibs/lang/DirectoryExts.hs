{-# OPTIONS -#include "cbits/HsLang.h" #-}
#include "config.h"
--
-- Extensions to H98's Directory.
--
module DirectoryExts 
	( copyFile	-- :: FilePath -> FilePath -> IO ()
	) where

import Foreign.C.String
import Foreign.C.Error	( throwErrnoIfMinus1 )

{-
  Copying a file in a platform indep. manner, and fast. 
  
  It is trivial to write a naive file-copying action in std. Haskell,
  but it is awfully slow and is not as robust as you could wish for,
  hence the provision for 'copyFile' here, which uses OS-provided
  facilities for copying bits over in a safe & timely manner.
-}
copyFile src dest = 
   withCString src  $ \ p_src  -> 
   withCString dest $ \ p_dest -> do
#ifndef mingw32_TARGET_OS
      stat <- throwErrnoIfMinus1 "DirectoryExts.copyFile" (primCopyFile p_src p_dest)
      case stat of
        0 -> return ()
          -- errno won't have much interesting to say, so just emit generic exception.

	n -> ioError (userError ("DirectoryExts.copyFile: unable to copy " ++
			         show src ++ " to " ++ show dest ++
				 ". (error code: " ++ show n ++ ")"))
#else
       -- errno'ery is UNIX-specific, 
       -- use GetLastError()/FormatMessage() under Win32.
      rc   <- primCopyFile p_src p_dest
      if rc /= 0 then return ()
       else do
         p_errStr <- getLastErrorString
	 errStr   <- peekCString p_errStr
	 localFree p_errStr
	 let errStr' = filter (/='\r') errStr
	 ioError (userError ("DirectoryExts.copyFile: unable to copy " ++ show src ++
	 		     " to " ++ show dest ++ ".\nReason: " ++ errStr'))

foreign import ccall "primGetLastErrorString" getLastErrorString :: IO CString
foreign import ccall "primLocalFree" localFree :: CString -> IO ()
#endif

foreign import ccall "primCopyFile" primCopyFile :: CString -> CString -> IO Int
