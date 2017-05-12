#include "template-hsc.h"
#line 69 "IO.hsc"
#ifdef __GLASGOW_HASKELL__
#line 73 "IO.hsc"
#endif 
#line 75 "IO.hsc"
#ifdef __HUGS__
#line 78 "IO.hsc"
#endif 
#line 80 "IO.hsc"
#include "HsUnix.h"
#line 176 "IO.hsc"
#ifdef __GLASGOW_HASKELL__
#line 192 "IO.hsc"
#endif 
#line 194 "IO.hsc"
#ifdef __HUGS__
#line 204 "IO.hsc"
#endif 

int main (int argc, char *argv [])
{
#if __GLASGOW_HASKELL__ && __GLASGOW_HASKELL__ < 409
    printf ("{-# OPTIONS -optc-D__GLASGOW_HASKELL__=%d #-}\n", 603);
#endif
#line 69 "IO.hsc"
#ifdef __GLASGOW_HASKELL__
#line 73 "IO.hsc"
#endif 
#line 75 "IO.hsc"
#ifdef __HUGS__
#line 78 "IO.hsc"
#endif 
    printf ("{-# OPTIONS %s #-}\n", "-#include \"HsUnix.h\"");
#line 176 "IO.hsc"
#ifdef __GLASGOW_HASKELL__
#line 192 "IO.hsc"
#endif 
#line 194 "IO.hsc"
#ifdef __HUGS__
#line 204 "IO.hsc"
#endif 
    hsc_line (1, "IO.hsc");
    fputs ("{-# OPTIONS -fffi #-}\n"
           "", stdout);
    hsc_line (2, "IO.hsc");
    fputs ("-----------------------------------------------------------------------------\n"
           "-- |\n"
           "-- Module      :  System.Posix.IO\n"
           "-- Copyright   :  (c) The University of Glasgow 2002\n"
           "-- License     :  BSD-style (see the file libraries/base/LICENSE)\n"
           "-- \n"
           "-- Maintainer  :  libraries@haskell.org\n"
           "-- Stability   :  provisional\n"
           "-- Portability :  non-portable (requires POSIX)\n"
           "--\n"
           "-- POSIX IO support\n"
           "--\n"
           "-----------------------------------------------------------------------------\n"
           "\n"
           "module System.Posix.IO (\n"
           "    -- * Input \\/ Output\n"
           "\n"
           "    -- ** Standard file descriptors\n"
           "    stdInput, stdOutput, stdError,\n"
           "\n"
           "    -- ** Opening and closing files\n"
           "    OpenMode(..),\n"
           "    OpenFileFlags(..), defaultFileFlags,\n"
           "    openFd, createFile,\n"
           "    closeFd,\n"
           "\n"
           "    -- ** Reading\\/writing data\n"
           "    -- |Programmers using the \'fdRead\' and \'fdWrite\' API should be aware that\n"
           "    -- EAGAIN exceptions may occur for non-blocking IO!\n"
           "\n"
           "    fdRead, fdWrite,\n"
           "\n"
           "    -- ** Seeking\n"
           "    fdSeek,\n"
           "\n"
           "    -- ** File options\n"
           "    FdOption(..),\n"
           "    queryFdOption,\n"
           "    setFdOption,\n"
           "\n"
           "    -- ** Locking\n"
           "    FileLock,\n"
           "    LockRequest(..),\n"
           "    getLock,  setLock,\n"
           "    waitToSetLock,\n"
           "\n"
           "    -- ** Pipes\n"
           "    createPipe,\n"
           "\n"
           "    -- ** Duplicating file descriptors\n"
           "    dup, dupTo,\n"
           "\n"
           "    -- ** Converting file descriptors to\\/from Handles\n"
           "    handleToFd,\n"
           "    fdToHandle,  \n"
           "\n"
           "  ) where\n"
           "\n"
           "import System.IO\n"
           "import System.IO.Error\n"
           "import System.Posix.Types\n"
           "import System.Posix.Internals\n"
           "\n"
           "import Foreign\n"
           "import Foreign.C\n"
           "import Data.Bits\n"
           "\n"
           "", stdout);
#line 69 "IO.hsc"
#ifdef __GLASGOW_HASKELL__
    fputs ("\n"
           "", stdout);
    hsc_line (70, "IO.hsc");
    fputs ("import GHC.IOBase\n"
           "import GHC.Handle hiding (fdToHandle, openFd)\n"
           "import qualified GHC.Handle\n"
           "", stdout);
#line 73 "IO.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (74, "IO.hsc");
    fputs ("\n"
           "", stdout);
#line 75 "IO.hsc"
#ifdef __HUGS__
    fputs ("\n"
           "", stdout);
    hsc_line (76, "IO.hsc");
    fputs ("import Hugs.Prelude (IOException(..), IOErrorType(..))\n"
           "import qualified Hugs.IO (handleToFd, openFd)\n"
           "", stdout);
#line 78 "IO.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (79, "IO.hsc");
    fputs ("\n"
           "", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (81, "IO.hsc");
    fputs ("\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Pipes\n"
           "-- |The \'createPipe\' function creates a pair of connected file descriptors. The first\n"
           "-- component is the fd to read from, the second is the write end.\n"
           "-- Although pipes may be bidirectional, this behaviour is not portable and\n"
           "-- programmers should use two separate pipes for this purpose.\n"
           "\n"
           "createPipe :: IO (Fd, Fd)\n"
           "createPipe =\n"
           "  allocaArray 2 $ \\p_fd -> do\n"
           "    throwErrnoIfMinus1_ \"createPipe\" (c_pipe p_fd)\n"
           "    rfd <- peekElemOff p_fd 0\n"
           "    wfd <- peekElemOff p_fd 1\n"
           "    return (Fd rfd, Fd wfd)\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Duplicating file descriptors\n"
           "\n"
           "dup :: Fd -> IO Fd\n"
           "dup (Fd fd) = do r <- throwErrnoIfMinus1 \"dup\" (c_dup fd); return (Fd r)\n"
           "\n"
           "dupTo :: Fd -> Fd -> IO Fd\n"
           "dupTo (Fd fd1) (Fd fd2) = do\n"
           "  r <- throwErrnoIfMinus1 \"dupTo\" (c_dup2 fd1 fd2)\n"
           "  return (Fd r)\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Opening and closing files\n"
           "\n"
           "stdInput, stdOutput, stdError :: Fd\n"
           "stdInput   = Fd (", stdout);
#line 112 "IO.hsc"
    hsc_const (STDIN_FILENO);
    fputs (")\n"
           "", stdout);
    hsc_line (113, "IO.hsc");
    fputs ("stdOutput  = Fd (", stdout);
#line 113 "IO.hsc"
    hsc_const (STDOUT_FILENO);
    fputs (")\n"
           "", stdout);
    hsc_line (114, "IO.hsc");
    fputs ("stdError   = Fd (", stdout);
#line 114 "IO.hsc"
    hsc_const (STDERR_FILENO);
    fputs (")\n"
           "", stdout);
    hsc_line (115, "IO.hsc");
    fputs ("\n"
           "data OpenMode = ReadOnly | WriteOnly | ReadWrite\n"
           "\n"
           "data OpenFileFlags =\n"
           " OpenFileFlags {\n"
           "    append    :: Bool,\n"
           "    exclusive :: Bool,\n"
           "    noctty    :: Bool,\n"
           "    nonBlock  :: Bool,\n"
           "    trunc     :: Bool\n"
           " }\n"
           "\n"
           "defaultFileFlags :: OpenFileFlags\n"
           "defaultFileFlags =\n"
           " OpenFileFlags {\n"
           "    append    = False,\n"
           "    exclusive = False,\n"
           "    noctty    = False,\n"
           "    nonBlock  = False,\n"
           "    trunc     = False\n"
           "  }\n"
           "\n"
           "openFd :: FilePath\n"
           "       -> OpenMode\n"
           "       -> Maybe FileMode -- Just x => O_CREAT, Nothing => must exist\n"
           "       -> OpenFileFlags\n"
           "       -> IO Fd\n"
           "openFd name how maybe_mode (OpenFileFlags append exclusive noctty\n"
           "\t\t\t\tnonBlock truncate) = do\n"
           "   withCString name $ \\s -> do\n"
           "    fd <- throwErrnoIfMinus1 \"openFd\" (c_open s all_flags mode_w)\n"
           "    return (Fd fd)\n"
           "  where\n"
           "    all_flags  = creat .|. flags .|. open_mode\n"
           "\n"
           "    flags =\n"
           "       (if append    then (", stdout);
#line 151 "IO.hsc"
    hsc_const (O_APPEND);
    fputs (")   else 0) .|.\n"
           "", stdout);
    hsc_line (152, "IO.hsc");
    fputs ("       (if exclusive then (", stdout);
#line 152 "IO.hsc"
    hsc_const (O_EXCL);
    fputs (")     else 0) .|.\n"
           "", stdout);
    hsc_line (153, "IO.hsc");
    fputs ("       (if noctty    then (", stdout);
#line 153 "IO.hsc"
    hsc_const (O_NOCTTY);
    fputs (")   else 0) .|.\n"
           "", stdout);
    hsc_line (154, "IO.hsc");
    fputs ("       (if nonBlock  then (", stdout);
#line 154 "IO.hsc"
    hsc_const (O_NONBLOCK);
    fputs (") else 0) .|.\n"
           "", stdout);
    hsc_line (155, "IO.hsc");
    fputs ("       (if truncate  then (", stdout);
#line 155 "IO.hsc"
    hsc_const (O_TRUNC);
    fputs (")    else 0)\n"
           "", stdout);
    hsc_line (156, "IO.hsc");
    fputs ("\n"
           "    (creat, mode_w) = case maybe_mode of \n"
           "\t\t\tNothing -> (0,0)\n"
           "\t\t\tJust x  -> ((", stdout);
#line 159 "IO.hsc"
    hsc_const (O_CREAT);
    fputs ("), x)\n"
           "", stdout);
    hsc_line (160, "IO.hsc");
    fputs ("\n"
           "    open_mode = case how of\n"
           "\t\t   ReadOnly  -> (", stdout);
#line 162 "IO.hsc"
    hsc_const (O_RDONLY);
    fputs (")\n"
           "", stdout);
    hsc_line (163, "IO.hsc");
    fputs ("\t\t   WriteOnly -> (", stdout);
#line 163 "IO.hsc"
    hsc_const (O_WRONLY);
    fputs (")\n"
           "", stdout);
    hsc_line (164, "IO.hsc");
    fputs ("\t\t   ReadWrite -> (", stdout);
#line 164 "IO.hsc"
    hsc_const (O_RDWR);
    fputs (")\n"
           "", stdout);
    hsc_line (165, "IO.hsc");
    fputs ("\n"
           "createFile :: FilePath -> FileMode -> IO Fd\n"
           "createFile name mode\n"
           "  = openFd name WriteOnly (Just mode) defaultFileFlags{ trunc=True } \n"
           "\n"
           "closeFd :: Fd -> IO ()\n"
           "closeFd (Fd fd) = throwErrnoIfMinus1_ \"closeFd\" (c_close fd)\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Converting file descriptors to/from Handles\n"
           "\n"
           "", stdout);
#line 176 "IO.hsc"
#ifdef __GLASGOW_HASKELL__
    fputs ("\n"
           "", stdout);
    hsc_line (177, "IO.hsc");
    fputs ("handleToFd :: Handle -> IO Fd\n"
           "handleToFd h = withHandle \"handleToFd\" h $ \\ h_ -> do\n"
           "  -- converting a Handle into an Fd effectively means\n"
           "  -- letting go of the Handle; it is put into a closed\n"
           "  -- state as a result. \n"
           "  let fd = haFD h_\n"
           "  flushWriteBufferOnly h_\n"
           "  unlockFile (fromIntegral fd)\n"
           "    -- setting the Handle\'s fd to (-1) as well as its \'type\'\n"
           "    -- to closed, is enough to disable the finalizer that\n"
           "    -- eventually is run on the Handle.\n"
           "  return (h_{haFD= (-1),haType=ClosedHandle}, Fd (fromIntegral fd))\n"
           "\n"
           "fdToHandle :: Fd -> IO Handle\n"
           "fdToHandle fd = GHC.Handle.fdToHandle (fromIntegral fd)\n"
           "", stdout);
#line 192 "IO.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (193, "IO.hsc");
    fputs ("\n"
           "", stdout);
#line 194 "IO.hsc"
#ifdef __HUGS__
    fputs ("\n"
           "", stdout);
    hsc_line (195, "IO.hsc");
    fputs ("handleToFd :: Handle -> IO Fd\n"
           "handleToFd h = do\n"
           "  fd <- Hugs.IO.handleToFd h\n"
           "  return (fromIntegral fd)\n"
           "\n"
           "fdToHandle :: Fd -> IO Handle\n"
           "fdToHandle fd = do\n"
           "  mode <- fdGetMode (fromIntegral fd)\n"
           "  Hugs.IO.openFd (fromIntegral fd) False mode True\n"
           "", stdout);
#line 204 "IO.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (205, "IO.hsc");
    fputs ("\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Fd options\n"
           "\n"
           "data FdOption = AppendOnWrite\n"
           "\t      | CloseOnExec\n"
           "\t      | NonBlockingRead\n"
           "\t      | SynchronousWrites\n"
           "\n"
           "fdOption2Int :: FdOption -> CInt\n"
           "fdOption2Int CloseOnExec       = (", stdout);
#line 215 "IO.hsc"
    hsc_const (FD_CLOEXEC);
    fputs (")\n"
           "", stdout);
    hsc_line (216, "IO.hsc");
    fputs ("fdOption2Int AppendOnWrite     = (", stdout);
#line 216 "IO.hsc"
    hsc_const (O_APPEND);
    fputs (")\n"
           "", stdout);
    hsc_line (217, "IO.hsc");
    fputs ("fdOption2Int NonBlockingRead   = (", stdout);
#line 217 "IO.hsc"
    hsc_const (O_NONBLOCK);
    fputs (")\n"
           "", stdout);
    hsc_line (218, "IO.hsc");
    fputs ("fdOption2Int SynchronousWrites = (", stdout);
#line 218 "IO.hsc"
    hsc_const (O_SYNC);
    fputs (")\n"
           "", stdout);
    hsc_line (219, "IO.hsc");
    fputs ("\n"
           "queryFdOption :: Fd -> FdOption -> IO Bool\n"
           "queryFdOption (Fd fd) opt = do\n"
           "  r <- throwErrnoIfMinus1 \"queryFdOption\" (c_fcntl_read fd flag)\n"
           "  return (testBit r (fromIntegral (fdOption2Int opt)))\n"
           " where\n"
           "  flag    = case opt of\n"
           "\t      CloseOnExec       -> (", stdout);
#line 226 "IO.hsc"
    hsc_const (F_GETFD);
    fputs (")\n"
           "", stdout);
    hsc_line (227, "IO.hsc");
    fputs ("\t      other\t\t-> (", stdout);
#line 227 "IO.hsc"
    hsc_const (F_GETFL);
    fputs (")\n"
           "", stdout);
    hsc_line (228, "IO.hsc");
    fputs ("\n"
           "setFdOption :: Fd -> FdOption -> Bool -> IO ()\n"
           "setFdOption (Fd fd) opt val = do\n"
           "  r <- throwErrnoIfMinus1 \"setFdOption\" (c_fcntl_read fd getflag)\n"
           "  let r\' | val       = r .|. opt_val\n"
           "\t | otherwise = r .&. (complement opt_val)\n"
           "  throwErrnoIfMinus1_ \"setFdOption\" (c_fcntl_write fd setflag r\')\n"
           " where\n"
           "  (getflag,setflag)= case opt of\n"
           "\t      CloseOnExec       -> ((", stdout);
#line 237 "IO.hsc"
    hsc_const (F_GETFD);
    fputs ("),(", stdout);
#line 237 "IO.hsc"
    hsc_const (F_SETFD);
    fputs (")) \n"
           "", stdout);
    hsc_line (238, "IO.hsc");
    fputs ("\t      other\t\t-> ((", stdout);
#line 238 "IO.hsc"
    hsc_const (F_GETFL);
    fputs ("),(", stdout);
#line 238 "IO.hsc"
    hsc_const (F_SETFL);
    fputs ("))\n"
           "", stdout);
    hsc_line (239, "IO.hsc");
    fputs ("  opt_val = fdOption2Int opt\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Seeking \n"
           "\n"
           "mode2Int :: SeekMode -> CInt\n"
           "mode2Int AbsoluteSeek = (", stdout);
#line 245 "IO.hsc"
    hsc_const (SEEK_SET);
    fputs (")\n"
           "", stdout);
    hsc_line (246, "IO.hsc");
    fputs ("mode2Int RelativeSeek = (", stdout);
#line 246 "IO.hsc"
    hsc_const (SEEK_CUR);
    fputs (")\n"
           "", stdout);
    hsc_line (247, "IO.hsc");
    fputs ("mode2Int SeekFromEnd  = (", stdout);
#line 247 "IO.hsc"
    hsc_const (SEEK_END);
    fputs (")\n"
           "", stdout);
    hsc_line (248, "IO.hsc");
    fputs ("\n"
           "fdSeek :: Fd -> SeekMode -> FileOffset -> IO FileOffset\n"
           "fdSeek (Fd fd) mode off =\n"
           "  throwErrnoIfMinus1 \"fdSeek\" (c_lseek fd off (mode2Int mode))\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Locking\n"
           "\n"
           "data LockRequest = ReadLock\n"
           "                 | WriteLock\n"
           "                 | Unlock\n"
           "\n"
           "type FileLock = (LockRequest, SeekMode, FileOffset, FileOffset)\n"
           "\n"
           "getLock :: Fd -> FileLock -> IO (Maybe (ProcessID, FileLock))\n"
           "getLock (Fd fd) lock =\n"
           "  allocaLock lock $ \\p_flock -> do\n"
           "    throwErrnoIfMinus1_ \"getLock\" (c_fcntl_lock fd (", stdout);
#line 265 "IO.hsc"
    hsc_const (F_GETLK);
    fputs (") p_flock)\n"
           "", stdout);
    hsc_line (266, "IO.hsc");
    fputs ("    result <- bytes2ProcessIDAndLock p_flock\n"
           "    return (maybeResult result)\n"
           "  where\n"
           "    maybeResult (_, (Unlock, _, _, _)) = Nothing\n"
           "    maybeResult x = Just x\n"
           "\n"
           "allocaLock :: FileLock -> (Ptr CFLock -> IO a) -> IO a\n"
           "allocaLock (lockreq, mode, start, len) io = \n"
           "  allocaBytes (", stdout);
#line 274 "IO.hsc"
    hsc_const (sizeof(struct flock));
    fputs (") $ \\p -> do\n"
           "", stdout);
    hsc_line (275, "IO.hsc");
    fputs ("    (", stdout);
#line 275 "IO.hsc"
    hsc_poke (struct flock, l_type);
    fputs (")   p (lockReq2Int lockreq :: CShort)\n"
           "", stdout);
    hsc_line (276, "IO.hsc");
    fputs ("    (", stdout);
#line 276 "IO.hsc"
    hsc_poke (struct flock, l_whence);
    fputs (") p (fromIntegral (mode2Int mode) :: CShort)\n"
           "", stdout);
    hsc_line (277, "IO.hsc");
    fputs ("    (", stdout);
#line 277 "IO.hsc"
    hsc_poke (struct flock, l_start);
    fputs (")  p start\n"
           "", stdout);
    hsc_line (278, "IO.hsc");
    fputs ("    (", stdout);
#line 278 "IO.hsc"
    hsc_poke (struct flock, l_len);
    fputs (")    p len\n"
           "", stdout);
    hsc_line (279, "IO.hsc");
    fputs ("    io p\n"
           "\n"
           "lockReq2Int :: LockRequest -> CShort\n"
           "lockReq2Int ReadLock  = (", stdout);
#line 282 "IO.hsc"
    hsc_const (F_RDLCK);
    fputs (")\n"
           "", stdout);
    hsc_line (283, "IO.hsc");
    fputs ("lockReq2Int WriteLock = (", stdout);
#line 283 "IO.hsc"
    hsc_const (F_WRLCK);
    fputs (")\n"
           "", stdout);
    hsc_line (284, "IO.hsc");
    fputs ("lockReq2Int Unlock    = (", stdout);
#line 284 "IO.hsc"
    hsc_const (F_UNLCK);
    fputs (")\n"
           "", stdout);
    hsc_line (285, "IO.hsc");
    fputs ("\n"
           "bytes2ProcessIDAndLock :: Ptr CFLock -> IO (ProcessID, FileLock)\n"
           "bytes2ProcessIDAndLock p = do\n"
           "  req   <- (", stdout);
#line 288 "IO.hsc"
    hsc_peek (struct flock, l_type);
    fputs (")   p\n"
           "", stdout);
    hsc_line (289, "IO.hsc");
    fputs ("  mode  <- (", stdout);
#line 289 "IO.hsc"
    hsc_peek (struct flock, l_whence);
    fputs (") p\n"
           "", stdout);
    hsc_line (290, "IO.hsc");
    fputs ("  start <- (", stdout);
#line 290 "IO.hsc"
    hsc_peek (struct flock, l_start);
    fputs (")  p\n"
           "", stdout);
    hsc_line (291, "IO.hsc");
    fputs ("  len   <- (", stdout);
#line 291 "IO.hsc"
    hsc_peek (struct flock, l_len);
    fputs (")    p\n"
           "", stdout);
    hsc_line (292, "IO.hsc");
    fputs ("  pid   <- (", stdout);
#line 292 "IO.hsc"
    hsc_peek (struct flock, l_pid);
    fputs (")    p\n"
           "", stdout);
    hsc_line (293, "IO.hsc");
    fputs ("  return (pid, (int2req req, int2mode mode, start, len))\n"
           " where\n"
           "  int2req :: CShort -> LockRequest\n"
           "  int2req (", stdout);
#line 296 "IO.hsc"
    hsc_const (F_RDLCK);
    fputs (") = ReadLock\n"
           "", stdout);
    hsc_line (297, "IO.hsc");
    fputs ("  int2req (", stdout);
#line 297 "IO.hsc"
    hsc_const (F_WRLCK);
    fputs (") = WriteLock\n"
           "", stdout);
    hsc_line (298, "IO.hsc");
    fputs ("  int2req (", stdout);
#line 298 "IO.hsc"
    hsc_const (F_UNLCK);
    fputs (") = Unlock\n"
           "", stdout);
    hsc_line (299, "IO.hsc");
    fputs ("  int2req _ = error $ \"int2req: bad argument\"\n"
           "\n"
           "  int2mode :: CShort -> SeekMode\n"
           "  int2mode (", stdout);
#line 302 "IO.hsc"
    hsc_const (SEEK_SET);
    fputs (") = AbsoluteSeek\n"
           "", stdout);
    hsc_line (303, "IO.hsc");
    fputs ("  int2mode (", stdout);
#line 303 "IO.hsc"
    hsc_const (SEEK_CUR);
    fputs (") = RelativeSeek\n"
           "", stdout);
    hsc_line (304, "IO.hsc");
    fputs ("  int2mode (", stdout);
#line 304 "IO.hsc"
    hsc_const (SEEK_END);
    fputs (") = SeekFromEnd\n"
           "", stdout);
    hsc_line (305, "IO.hsc");
    fputs ("  int2mode _ = error $ \"int2mode: bad argument\"\n"
           "\n"
           "setLock :: Fd -> FileLock -> IO ()\n"
           "setLock (Fd fd) lock = do\n"
           "  allocaLock lock $ \\p_flock ->\n"
           "    throwErrnoIfMinus1_ \"setLock\" (c_fcntl_lock fd (", stdout);
#line 310 "IO.hsc"
    hsc_const (F_SETLK);
    fputs (") p_flock)\n"
           "", stdout);
    hsc_line (311, "IO.hsc");
    fputs ("\n"
           "waitToSetLock :: Fd -> FileLock -> IO ()\n"
           "waitToSetLock (Fd fd) lock = do\n"
           "  allocaLock lock $ \\p_flock ->\n"
           "    throwErrnoIfMinus1_ \"waitToSetLock\" \n"
           "\t(c_fcntl_lock fd (", stdout);
#line 316 "IO.hsc"
    hsc_const (F_SETLKW);
    fputs (") p_flock)\n"
           "", stdout);
    hsc_line (317, "IO.hsc");
    fputs ("\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- fd{Read,Write}\n"
           "\n"
           "fdRead :: Fd -> ByteCount -> IO (String, ByteCount)\n"
           "fdRead _fd 0 = return (\"\", 0)\n"
           "fdRead (Fd fd) nbytes = do\n"
           "    allocaBytes (fromIntegral nbytes) $ \\ bytes -> do\n"
           "    rc    <-  throwErrnoIfMinus1Retry \"fdRead\" (c_read fd bytes nbytes)\n"
           "    case fromIntegral rc of\n"
           "      0 -> ioError (IOError Nothing EOF \"fdRead\" \"EOF\" Nothing)\n"
           "      n -> do\n"
           "       s <- peekCStringLen (bytes, fromIntegral n)\n"
           "       return (s, n)\n"
           "\n"
           "fdWrite :: Fd -> String -> IO ByteCount\n"
           "fdWrite (Fd fd) str = withCStringLen str $ \\ (strPtr,len) -> do\n"
           "    rc <- throwErrnoIfMinus1Retry \"fdWrite\" (c_write fd strPtr (fromIntegral len))\n"
           "    return (fromIntegral rc)\n"
           "", stdout);
    return 0;
}
