#include "template-hsc.h"
#line 59 "Files.hsc"
#if HAVE_LCHOWN
#line 61 "Files.hsc"
#endif 
#line 73 "Files.hsc"
#include "HsUnix.h"
#line 389 "Files.hsc"
#if HAVE_LCHOWN
#line 397 "Files.hsc"
#endif 
#line 470 "Files.hsc"
#ifdef _PC_SYNC_IO
#line 472 "Files.hsc"
#else 
#line 474 "Files.hsc"
#endif 
#line 476 "Files.hsc"
#ifdef _PC_ASYNC_IO
#line 478 "Files.hsc"
#else 
#line 480 "Files.hsc"
#endif 
#line 482 "Files.hsc"
#ifdef _PC_PRIO_IO
#line 484 "Files.hsc"
#else 
#line 486 "Files.hsc"
#endif 
#line 488 "Files.hsc"
#if _PC_FILESIZEBITS
#line 490 "Files.hsc"
#else 
#line 492 "Files.hsc"
#endif 
#line 494 "Files.hsc"
#if _PC_SYMLINK_MAX
#line 496 "Files.hsc"
#else 
#line 498 "Files.hsc"
#endif 

int main (int argc, char *argv [])
{
#if __GLASGOW_HASKELL__ && __GLASGOW_HASKELL__ < 409
    printf ("{-# OPTIONS -optc-D__GLASGOW_HASKELL__=%d #-}\n", 603);
#endif
#line 59 "Files.hsc"
#if HAVE_LCHOWN
#line 61 "Files.hsc"
#endif 
    printf ("{-# OPTIONS %s #-}\n", "-#include \"HsUnix.h\"");
#line 389 "Files.hsc"
#if HAVE_LCHOWN
#line 397 "Files.hsc"
#endif 
#line 470 "Files.hsc"
#ifdef _PC_SYNC_IO
#line 472 "Files.hsc"
#else 
#line 474 "Files.hsc"
#endif 
#line 476 "Files.hsc"
#ifdef _PC_ASYNC_IO
#line 478 "Files.hsc"
#else 
#line 480 "Files.hsc"
#endif 
#line 482 "Files.hsc"
#ifdef _PC_PRIO_IO
#line 484 "Files.hsc"
#else 
#line 486 "Files.hsc"
#endif 
#line 488 "Files.hsc"
#if _PC_FILESIZEBITS
#line 490 "Files.hsc"
#else 
#line 492 "Files.hsc"
#endif 
#line 494 "Files.hsc"
#if _PC_SYMLINK_MAX
#line 496 "Files.hsc"
#else 
#line 498 "Files.hsc"
#endif 
    hsc_line (1, "Files.hsc");
    fputs ("{-# OPTIONS -fffi #-}\n"
           "", stdout);
    hsc_line (2, "Files.hsc");
    fputs ("-----------------------------------------------------------------------------\n"
           "-- |\n"
           "-- Module      :  System.Posix.Files\n"
           "-- Copyright   :  (c) The University of Glasgow 2002\n"
           "-- License     :  BSD-style (see the file libraries/base/LICENSE)\n"
           "-- \n"
           "-- Maintainer  :  libraries@haskell.org\n"
           "-- Stability   :  provisional\n"
           "-- Portability :  non-portable (requires POSIX)\n"
           "--\n"
           "-- POSIX file support\n"
           "--\n"
           "-----------------------------------------------------------------------------\n"
           "\n"
           "module System.Posix.Files (\n"
           "    -- * File modes\n"
           "    -- FileMode exported by System.Posix.Types\n"
           "    unionFileModes, intersectFileModes,\n"
           "    nullFileMode,\n"
           "    ownerReadMode, ownerWriteMode, ownerExecuteMode, ownerModes,\n"
           "    groupReadMode, groupWriteMode, groupExecuteMode, groupModes,\n"
           "    otherReadMode, otherWriteMode, otherExecuteMode, otherModes,\n"
           "    setUserIDMode, setGroupIDMode,\n"
           "    stdFileMode,   accessModes,\n"
           "\n"
           "    -- ** Setting file modes\n"
           "    setFileMode, setFdMode, setFileCreationMask,\n"
           "\n"
           "    -- ** Checking file existence and permissions\n"
           "    fileAccess, fileExist,\n"
           "\n"
           "    -- * File status\n"
           "    FileStatus,\n"
           "    -- ** Obtaining file status\n"
           "    getFileStatus, getFdStatus, getSymbolicLinkStatus,\n"
           "    -- ** Querying file status\n"
           "    deviceID, fileID, fileMode, linkCount, fileOwner, fileGroup,\n"
           "    specialDeviceID, fileSize, accessTime, modificationTime,\n"
           "    statusChangeTime,\n"
           "    isBlockDevice, isCharacterDevice, isNamedPipe, isRegularFile,\n"
           "    isDirectory, isSymbolicLink, isSocket,\n"
           "\n"
           "    -- * Creation\n"
           "    createNamedPipe, \n"
           "    createDevice,\n"
           "\n"
           "    -- * Hard links\n"
           "    createLink, removeLink,\n"
           "\n"
           "    -- * Symbolic links\n"
           "    createSymbolicLink, readSymbolicLink,\n"
           "\n"
           "    -- * Renaming files\n"
           "    rename,\n"
           "\n"
           "    -- * Changing file ownership\n"
           "    setOwnerAndGroup,  setFdOwnerAndGroup,\n"
           "", stdout);
#line 59 "Files.hsc"
#if HAVE_LCHOWN
    fputs ("\n"
           "", stdout);
    hsc_line (60, "Files.hsc");
    fputs ("    setSymbolicLinkOwnerAndGroup,\n"
           "", stdout);
#line 61 "Files.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (62, "Files.hsc");
    fputs ("\n"
           "    -- * Changing file timestamps\n"
           "    setFileTimes, touchFile,\n"
           "\n"
           "    -- * Setting file sizes\n"
           "    setFileSize, setFdSize,\n"
           "\n"
           "    -- * Find system-specific limits for a file\n"
           "    PathVar(..), getPathVar, getFdPathVar,\n"
           "  ) where\n"
           "\n"
           "", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (74, "Files.hsc");
    fputs ("\n"
           "import System.Posix.Types\n"
           "import System.IO.Unsafe\n"
           "import Data.Bits\n"
           "import System.Posix.Internals\n"
           "import Foreign\n"
           "import Foreign.C\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- POSIX file modes\n"
           "\n"
           "-- The abstract type \'FileMode\', constants and operators for\n"
           "-- manipulating the file modes defined by POSIX.\n"
           "\n"
           "nullFileMode :: FileMode\n"
           "nullFileMode = 0\n"
           "\n"
           "ownerReadMode :: FileMode\n"
           "ownerReadMode = (", stdout);
#line 92 "Files.hsc"
    hsc_const (S_IRUSR);
    fputs (")\n"
           "", stdout);
    hsc_line (93, "Files.hsc");
    fputs ("\n"
           "ownerWriteMode :: FileMode\n"
           "ownerWriteMode = (", stdout);
#line 95 "Files.hsc"
    hsc_const (S_IWUSR);
    fputs (")\n"
           "", stdout);
    hsc_line (96, "Files.hsc");
    fputs ("\n"
           "ownerExecuteMode :: FileMode\n"
           "ownerExecuteMode = (", stdout);
#line 98 "Files.hsc"
    hsc_const (S_IXUSR);
    fputs (")\n"
           "", stdout);
    hsc_line (99, "Files.hsc");
    fputs ("\n"
           "groupReadMode :: FileMode\n"
           "groupReadMode = (", stdout);
#line 101 "Files.hsc"
    hsc_const (S_IRGRP);
    fputs (")\n"
           "", stdout);
    hsc_line (102, "Files.hsc");
    fputs ("\n"
           "groupWriteMode :: FileMode\n"
           "groupWriteMode = (", stdout);
#line 104 "Files.hsc"
    hsc_const (S_IWGRP);
    fputs (")\n"
           "", stdout);
    hsc_line (105, "Files.hsc");
    fputs ("\n"
           "groupExecuteMode :: FileMode\n"
           "groupExecuteMode = (", stdout);
#line 107 "Files.hsc"
    hsc_const (S_IXGRP);
    fputs (")\n"
           "", stdout);
    hsc_line (108, "Files.hsc");
    fputs ("\n"
           "otherReadMode :: FileMode\n"
           "otherReadMode = (", stdout);
#line 110 "Files.hsc"
    hsc_const (S_IROTH);
    fputs (")\n"
           "", stdout);
    hsc_line (111, "Files.hsc");
    fputs ("\n"
           "otherWriteMode :: FileMode\n"
           "otherWriteMode = (", stdout);
#line 113 "Files.hsc"
    hsc_const (S_IWOTH);
    fputs (")\n"
           "", stdout);
    hsc_line (114, "Files.hsc");
    fputs ("\n"
           "otherExecuteMode :: FileMode\n"
           "otherExecuteMode = (", stdout);
#line 116 "Files.hsc"
    hsc_const (S_IXOTH);
    fputs (")\n"
           "", stdout);
    hsc_line (117, "Files.hsc");
    fputs ("\n"
           "setUserIDMode :: FileMode\n"
           "setUserIDMode = (", stdout);
#line 119 "Files.hsc"
    hsc_const (S_ISUID);
    fputs (")\n"
           "", stdout);
    hsc_line (120, "Files.hsc");
    fputs ("\n"
           "setGroupIDMode :: FileMode\n"
           "setGroupIDMode = (", stdout);
#line 122 "Files.hsc"
    hsc_const (S_ISGID);
    fputs (")\n"
           "", stdout);
    hsc_line (123, "Files.hsc");
    fputs ("\n"
           "stdFileMode :: FileMode\n"
           "stdFileMode = ownerReadMode  .|. ownerWriteMode .|. \n"
           "\t      groupReadMode  .|. groupWriteMode .|. \n"
           "\t      otherReadMode  .|. otherWriteMode\n"
           "\n"
           "ownerModes :: FileMode\n"
           "ownerModes = (", stdout);
#line 130 "Files.hsc"
    hsc_const (S_IRWXU);
    fputs (")\n"
           "", stdout);
    hsc_line (131, "Files.hsc");
    fputs ("\n"
           "groupModes :: FileMode\n"
           "groupModes = (", stdout);
#line 133 "Files.hsc"
    hsc_const (S_IRWXG);
    fputs (")\n"
           "", stdout);
    hsc_line (134, "Files.hsc");
    fputs ("\n"
           "otherModes :: FileMode\n"
           "otherModes = (", stdout);
#line 136 "Files.hsc"
    hsc_const (S_IRWXO);
    fputs (")\n"
           "", stdout);
    hsc_line (137, "Files.hsc");
    fputs ("\n"
           "accessModes :: FileMode\n"
           "accessModes = ownerModes .|. groupModes .|. otherModes\n"
           "\n"
           "unionFileModes :: FileMode -> FileMode -> FileMode\n"
           "unionFileModes m1 m2 = m1 .|. m2\n"
           "\n"
           "intersectFileModes :: FileMode -> FileMode -> FileMode\n"
           "intersectFileModes m1 m2 = m1 .&. m2\n"
           "\n"
           "-- Not exported:\n"
           "fileTypeModes :: FileMode\n"
           "fileTypeModes = (", stdout);
#line 149 "Files.hsc"
    hsc_const (S_IFMT);
    fputs (")\n"
           "", stdout);
    hsc_line (150, "Files.hsc");
    fputs ("\n"
           "blockSpecialMode :: FileMode\n"
           "blockSpecialMode = (", stdout);
#line 152 "Files.hsc"
    hsc_const (S_IFBLK);
    fputs (")\n"
           "", stdout);
    hsc_line (153, "Files.hsc");
    fputs ("\n"
           "characterSpecialMode :: FileMode\n"
           "characterSpecialMode = (", stdout);
#line 155 "Files.hsc"
    hsc_const (S_IFCHR);
    fputs (")\n"
           "", stdout);
    hsc_line (156, "Files.hsc");
    fputs ("\n"
           "namedPipeMode :: FileMode\n"
           "namedPipeMode = (", stdout);
#line 158 "Files.hsc"
    hsc_const (S_IFIFO);
    fputs (")\n"
           "", stdout);
    hsc_line (159, "Files.hsc");
    fputs ("\n"
           "regularFileMode :: FileMode\n"
           "regularFileMode = (", stdout);
#line 161 "Files.hsc"
    hsc_const (S_IFREG);
    fputs (")\n"
           "", stdout);
    hsc_line (162, "Files.hsc");
    fputs ("\n"
           "directoryMode :: FileMode\n"
           "directoryMode = (", stdout);
#line 164 "Files.hsc"
    hsc_const (S_IFDIR);
    fputs (")\n"
           "", stdout);
    hsc_line (165, "Files.hsc");
    fputs ("\n"
           "symbolicLinkMode :: FileMode\n"
           "symbolicLinkMode = (", stdout);
#line 167 "Files.hsc"
    hsc_const (S_IFLNK);
    fputs (")\n"
           "", stdout);
    hsc_line (168, "Files.hsc");
    fputs ("\n"
           "socketMode :: FileMode\n"
           "socketMode = (", stdout);
#line 170 "Files.hsc"
    hsc_const (S_IFSOCK);
    fputs (")\n"
           "", stdout);
    hsc_line (171, "Files.hsc");
    fputs ("\n"
           "setFileMode :: FilePath -> FileMode -> IO ()\n"
           "setFileMode name m =\n"
           "  withCString name $ \\s -> do\n"
           "    throwErrnoIfMinus1_ \"setFileMode\" (c_chmod s m)\n"
           "\n"
           "setFdMode :: Fd -> FileMode -> IO ()\n"
           "setFdMode fd m =\n"
           "  throwErrnoIfMinus1_ \"setFdMode\" (c_fchmod fd m)\n"
           "\n"
           "foreign import ccall unsafe \"fchmod\" \n"
           "  c_fchmod :: Fd -> CMode -> IO CInt\n"
           "\n"
           "setFileCreationMask :: FileMode -> IO FileMode\n"
           "setFileCreationMask mask = c_umask mask\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- access()\n"
           "\n"
           "fileAccess :: FilePath -> Bool -> Bool -> Bool -> IO Bool\n"
           "fileAccess name read write exec = access name flags\n"
           "  where\n"
           "   flags   = read_f .|. write_f .|. exec_f\n"
           "   read_f  = if read  then (", stdout);
#line 194 "Files.hsc"
    hsc_const (R_OK);
    fputs (") else 0\n"
           "", stdout);
    hsc_line (195, "Files.hsc");
    fputs ("   write_f = if write then (", stdout);
#line 195 "Files.hsc"
    hsc_const (W_OK);
    fputs (") else 0\n"
           "", stdout);
    hsc_line (196, "Files.hsc");
    fputs ("   exec_f  = if exec  then (", stdout);
#line 196 "Files.hsc"
    hsc_const (X_OK);
    fputs (") else 0\n"
           "", stdout);
    hsc_line (197, "Files.hsc");
    fputs ("\n"
           "fileExist :: FilePath -> IO Bool\n"
           "fileExist name = \n"
           "  withCString name $ \\s -> do\n"
           "    r <- c_access s (", stdout);
#line 201 "Files.hsc"
    hsc_const (F_OK);
    fputs (")\n"
           "", stdout);
    hsc_line (202, "Files.hsc");
    fputs ("    if (r == 0)\n"
           "\tthen return True\n"
           "\telse do err <- getErrno\n"
           "\t        if (err == eNOENT)\n"
           "\t\t   then return False\n"
           "\t\t   else throwErrno \"fileExist\"\n"
           "\n"
           "access :: FilePath -> CMode -> IO Bool\n"
           "access name flags = \n"
           "  withCString name $ \\s -> do\n"
           "    r <- c_access s flags\n"
           "    if (r == 0)\n"
           "\tthen return True\n"
           "\telse do err <- getErrno\n"
           "\t        if (err == eACCES)\n"
           "\t\t   then return False\n"
           "\t\t   else throwErrno \"fileAccess\"\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- stat() support\n"
           "\n"
           "newtype FileStatus = FileStatus (ForeignPtr CStat)\n"
           "\n"
           "deviceID         :: FileStatus -> DeviceID\n"
           "fileID           :: FileStatus -> FileID\n"
           "fileMode         :: FileStatus -> FileMode\n"
           "linkCount        :: FileStatus -> LinkCount\n"
           "fileOwner        :: FileStatus -> UserID\n"
           "fileGroup        :: FileStatus -> GroupID\n"
           "specialDeviceID  :: FileStatus -> DeviceID\n"
           "fileSize         :: FileStatus -> FileOffset\n"
           "accessTime       :: FileStatus -> EpochTime\n"
           "modificationTime :: FileStatus -> EpochTime\n"
           "statusChangeTime :: FileStatus -> EpochTime\n"
           "\n"
           "deviceID (FileStatus stat) = \n"
           "  unsafePerformIO $ withForeignPtr stat $ (", stdout);
#line 238 "Files.hsc"
    hsc_peek (struct stat, st_dev);
    fputs (")\n"
           "", stdout);
    hsc_line (239, "Files.hsc");
    fputs ("fileID (FileStatus stat) = \n"
           "  unsafePerformIO $ withForeignPtr stat $ (", stdout);
#line 240 "Files.hsc"
    hsc_peek (struct stat, st_ino);
    fputs (")\n"
           "", stdout);
    hsc_line (241, "Files.hsc");
    fputs ("fileMode (FileStatus stat) =\n"
           "  unsafePerformIO $ withForeignPtr stat $ (", stdout);
#line 242 "Files.hsc"
    hsc_peek (struct stat, st_mode);
    fputs (")\n"
           "", stdout);
    hsc_line (243, "Files.hsc");
    fputs ("linkCount (FileStatus stat) =\n"
           "  unsafePerformIO $ withForeignPtr stat $ (", stdout);
#line 244 "Files.hsc"
    hsc_peek (struct stat, st_nlink);
    fputs (")\n"
           "", stdout);
    hsc_line (245, "Files.hsc");
    fputs ("fileOwner (FileStatus stat) =\n"
           "  unsafePerformIO $ withForeignPtr stat $ (", stdout);
#line 246 "Files.hsc"
    hsc_peek (struct stat, st_uid);
    fputs (")\n"
           "", stdout);
    hsc_line (247, "Files.hsc");
    fputs ("fileGroup (FileStatus stat) =\n"
           "  unsafePerformIO $ withForeignPtr stat $ (", stdout);
#line 248 "Files.hsc"
    hsc_peek (struct stat, st_gid);
    fputs (")\n"
           "", stdout);
    hsc_line (249, "Files.hsc");
    fputs ("specialDeviceID (FileStatus stat) =\n"
           "  unsafePerformIO $ withForeignPtr stat $ (", stdout);
#line 250 "Files.hsc"
    hsc_peek (struct stat, st_rdev);
    fputs (")\n"
           "", stdout);
    hsc_line (251, "Files.hsc");
    fputs ("fileSize (FileStatus stat) =\n"
           "  unsafePerformIO $ withForeignPtr stat $ (", stdout);
#line 252 "Files.hsc"
    hsc_peek (struct stat, st_size);
    fputs (")\n"
           "", stdout);
    hsc_line (253, "Files.hsc");
    fputs ("accessTime (FileStatus stat) =\n"
           "  unsafePerformIO $ withForeignPtr stat $ (", stdout);
#line 254 "Files.hsc"
    hsc_peek (struct stat, st_atime);
    fputs (")\n"
           "", stdout);
    hsc_line (255, "Files.hsc");
    fputs ("modificationTime (FileStatus stat) =\n"
           "  unsafePerformIO $ withForeignPtr stat $ (", stdout);
#line 256 "Files.hsc"
    hsc_peek (struct stat, st_mtime);
    fputs (")\n"
           "", stdout);
    hsc_line (257, "Files.hsc");
    fputs ("statusChangeTime (FileStatus stat) =\n"
           "  unsafePerformIO $ withForeignPtr stat $ (", stdout);
#line 258 "Files.hsc"
    hsc_peek (struct stat, st_ctime);
    fputs (")\n"
           "", stdout);
    hsc_line (259, "Files.hsc");
    fputs ("\n"
           "isBlockDevice     :: FileStatus -> Bool\n"
           "isCharacterDevice :: FileStatus -> Bool\n"
           "isNamedPipe       :: FileStatus -> Bool\n"
           "isRegularFile     :: FileStatus -> Bool\n"
           "isDirectory       :: FileStatus -> Bool\n"
           "isSymbolicLink    :: FileStatus -> Bool\n"
           "isSocket          :: FileStatus -> Bool\n"
           "\n"
           "isBlockDevice stat = \n"
           "  (fileMode stat `intersectFileModes` fileTypeModes) == blockSpecialMode\n"
           "isCharacterDevice stat = \n"
           "  (fileMode stat `intersectFileModes` fileTypeModes) == characterSpecialMode\n"
           "isNamedPipe stat = \n"
           "  (fileMode stat `intersectFileModes` fileTypeModes) == namedPipeMode\n"
           "isRegularFile stat = \n"
           "  (fileMode stat `intersectFileModes` fileTypeModes) == regularFileMode\n"
           "isDirectory stat = \n"
           "  (fileMode stat `intersectFileModes` fileTypeModes) == directoryMode\n"
           "isSymbolicLink stat = \n"
           "  (fileMode stat `intersectFileModes` fileTypeModes) == symbolicLinkMode\n"
           "isSocket stat = \n"
           "  (fileMode stat `intersectFileModes` fileTypeModes) == socketMode\n"
           "\n"
           "getFileStatus :: FilePath -> IO FileStatus\n"
           "getFileStatus path = do\n"
           "  fp <- mallocForeignPtrBytes (", stdout);
#line 285 "Files.hsc"
    hsc_const (sizeof(struct stat));
    fputs (") \n"
           "", stdout);
    hsc_line (286, "Files.hsc");
    fputs ("  withForeignPtr fp $ \\p ->\n"
           "    withCString path $ \\s -> \n"
           "      throwErrnoIfMinus1_ \"getFileStatus\" (c_stat s p)\n"
           "  return (FileStatus fp)\n"
           "\n"
           "getFdStatus :: Fd -> IO FileStatus\n"
           "getFdStatus (Fd fd) = do\n"
           "  fp <- mallocForeignPtrBytes (", stdout);
#line 293 "Files.hsc"
    hsc_const (sizeof(struct stat));
    fputs (") \n"
           "", stdout);
    hsc_line (294, "Files.hsc");
    fputs ("  withForeignPtr fp $ \\p ->\n"
           "    throwErrnoIfMinus1_ \"getFdStatus\" (c_fstat fd p)\n"
           "  return (FileStatus fp)\n"
           "\n"
           "getSymbolicLinkStatus :: FilePath -> IO FileStatus\n"
           "getSymbolicLinkStatus path = do\n"
           "  fp <- mallocForeignPtrBytes (", stdout);
#line 300 "Files.hsc"
    hsc_const (sizeof(struct stat));
    fputs (") \n"
           "", stdout);
    hsc_line (301, "Files.hsc");
    fputs ("  withForeignPtr fp $ \\p ->\n"
           "    withCString path $ \\s -> \n"
           "      throwErrnoIfMinus1_ \"getSymbolicLinkStatus\" (c_lstat s p)\n"
           "  return (FileStatus fp)\n"
           "\n"
           "foreign import ccall unsafe \"lstat\" \n"
           "  c_lstat :: CString -> Ptr CStat -> IO CInt\n"
           "\n"
           "createNamedPipe :: FilePath -> FileMode -> IO ()\n"
           "createNamedPipe name mode = do\n"
           "  withCString name $ \\s -> \n"
           "    throwErrnoIfMinus1_ \"createNamedPipe\" (c_mkfifo s mode)\n"
           "\n"
           "createDevice :: FilePath -> FileMode -> DeviceID -> IO ()\n"
           "createDevice path mode dev =\n"
           "  withCString path $ \\s ->\n"
           "    throwErrnoIfMinus1_ \"createDevice\" (c_mknod s mode dev)\n"
           "\n"
           "foreign import ccall unsafe \"mknod\" \n"
           "  c_mknod :: CString -> CMode -> CDev -> IO CInt\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Hard links\n"
           "\n"
           "createLink :: FilePath -> FilePath -> IO ()\n"
           "createLink name1 name2 =\n"
           "  withCString name1 $ \\s1 ->\n"
           "  withCString name2 $ \\s2 ->\n"
           "  throwErrnoIfMinus1_ \"createLink\" (c_link s1 s2)\n"
           "\n"
           "removeLink :: FilePath -> IO ()\n"
           "removeLink name =\n"
           "  withCString name $ \\s ->\n"
           "  throwErrnoIfMinus1_ \"removeLink\" (c_unlink s)\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Symbolic Links\n"
           "\n"
           "createSymbolicLink :: FilePath -> FilePath -> IO ()\n"
           "createSymbolicLink file1 file2 =\n"
           "  withCString file1 $ \\s1 ->\n"
           "  withCString file2 $ \\s2 ->\n"
           "  throwErrnoIfMinus1_ \"createSymbolicLink\" (c_symlink s1 s2)\n"
           "\n"
           "foreign import ccall unsafe \"symlink\"\n"
           "  c_symlink :: CString -> CString -> IO CInt\n"
           "\n"
           "-- ToDo: should really use SYMLINK_MAX, but not everyone supports it yet,\n"
           "-- and it seems that the intention is that SYMLINK_MAX is no larger than\n"
           "-- PATH_MAX.\n"
           "readSymbolicLink :: FilePath -> IO FilePath\n"
           "readSymbolicLink file =\n"
           "  allocaArray0 (", stdout);
#line 353 "Files.hsc"
    hsc_const (PATH_MAX);
    fputs (") $ \\buf -> do\n"
           "", stdout);
    hsc_line (354, "Files.hsc");
    fputs ("    withCString file $ \\s -> do\n"
           "      len <- throwErrnoIfMinus1 \"readSymbolicLink\" $ \n"
           "\tc_readlink s buf (", stdout);
#line 356 "Files.hsc"
    hsc_const (PATH_MAX);
    fputs (")\n"
           "", stdout);
    hsc_line (357, "Files.hsc");
    fputs ("      peekCStringLen (buf,fromIntegral len)\n"
           "\n"
           "foreign import ccall unsafe \"readlink\"\n"
           "  c_readlink :: CString -> CString -> CInt -> IO CInt\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Renaming files\n"
           "\n"
           "rename :: FilePath -> FilePath -> IO ()\n"
           "rename name1 name2 =\n"
           "  withCString name1 $ \\s1 ->\n"
           "  withCString name2 $ \\s2 ->\n"
           "  throwErrnoIfMinus1_ \"rename\" (c_rename s1 s2)\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- chmod()\n"
           "\n"
           "setOwnerAndGroup :: FilePath -> UserID -> GroupID -> IO ()\n"
           "setOwnerAndGroup name uid gid = do\n"
           "  withCString name $ \\s ->\n"
           "    throwErrnoIfMinus1_ \"setOwnerAndGroup\" (c_chown s uid gid)\n"
           "\n"
           "foreign import ccall unsafe \"chown\"\n"
           "  c_chown :: CString -> CUid -> CGid -> IO CInt\n"
           "\n"
           "setFdOwnerAndGroup :: Fd -> UserID -> GroupID -> IO ()\n"
           "setFdOwnerAndGroup (Fd fd) uid gid = \n"
           "  throwErrnoIfMinus1_ \"setFdOwnerAndGroup\" (c_fchown fd uid gid)\n"
           "\n"
           "foreign import ccall unsafe \"fchown\"\n"
           "  c_fchown :: CInt -> CUid -> CGid -> IO CInt\n"
           "\n"
           "", stdout);
#line 389 "Files.hsc"
#if HAVE_LCHOWN
    fputs ("\n"
           "", stdout);
    hsc_line (390, "Files.hsc");
    fputs ("setSymbolicLinkOwnerAndGroup :: FilePath -> UserID -> GroupID -> IO ()\n"
           "setSymbolicLinkOwnerAndGroup name uid gid = do\n"
           "  withCString name $ \\s ->\n"
           "    throwErrnoIfMinus1_ \"setSymbolicLinkOwnerAndGroup\" (c_lchown s uid gid)\n"
           "\n"
           "foreign import ccall unsafe \"lchown\"\n"
           "  c_lchown :: CString -> CUid -> CGid -> IO CInt\n"
           "", stdout);
#line 397 "Files.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (398, "Files.hsc");
    fputs ("\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- utime()\n"
           "\n"
           "setFileTimes :: FilePath -> EpochTime -> EpochTime -> IO ()\n"
           "setFileTimes name atime mtime = do\n"
           "  withCString name $ \\s ->\n"
           "   allocaBytes (", stdout);
#line 405 "Files.hsc"
    hsc_const (sizeof(struct utimbuf));
    fputs (") $ \\p -> do\n"
           "", stdout);
    hsc_line (406, "Files.hsc");
    fputs ("     (", stdout);
#line 406 "Files.hsc"
    hsc_poke (struct utimbuf, actime);
    fputs (")  p atime\n"
           "", stdout);
    hsc_line (407, "Files.hsc");
    fputs ("     (", stdout);
#line 407 "Files.hsc"
    hsc_poke (struct utimbuf, modtime);
    fputs (") p mtime\n"
           "", stdout);
    hsc_line (408, "Files.hsc");
    fputs ("     throwErrnoIfMinus1_ \"setFileTimes\" (c_utime s p)\n"
           "\n"
           "touchFile :: FilePath -> IO ()\n"
           "touchFile name = do\n"
           "  withCString name $ \\s ->\n"
           "   throwErrnoIfMinus1_ \"touchFile\" (c_utime s nullPtr)\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- Setting file sizes\n"
           "\n"
           "setFileSize :: FilePath -> FileOffset -> IO ()\n"
           "setFileSize file off = \n"
           "  withCString file $ \\s ->\n"
           "    throwErrnoIfMinus1_ \"setFileSize\" (c_truncate s off)\n"
           "\n"
           "foreign import ccall unsafe \"truncate\"\n"
           "  c_truncate :: CString -> COff -> IO CInt\n"
           "\n"
           "setFdSize :: Fd -> FileOffset -> IO ()\n"
           "setFdSize fd off =\n"
           "  throwErrnoIfMinus1_ \"setFdSize\" (c_ftruncate fd off)\n"
           "\n"
           "foreign import ccall unsafe \"ftruncate\"\n"
           "  c_ftruncate :: Fd -> COff -> IO CInt\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- pathconf()/fpathconf() support\n"
           "\n"
           "data PathVar\n"
           "  = FileSizeBits\t\t  {- _PC_FILESIZEBITS     -}\n"
           "  | LinkLimit                     {- _PC_LINK_MAX         -}\n"
           "  | InputLineLimit                {- _PC_MAX_CANON        -}\n"
           "  | InputQueueLimit               {- _PC_MAX_INPUT        -}\n"
           "  | FileNameLimit                 {- _PC_NAME_MAX         -}\n"
           "  | PathNameLimit                 {- _PC_PATH_MAX         -}\n"
           "  | PipeBufferLimit               {- _PC_PIPE_BUF         -}\n"
           "\t\t\t\t  -- These are described as optional in POSIX:\n"
           "  \t\t\t\t  {- _PC_ALLOC_SIZE_MIN     -}\n"
           "  \t\t\t\t  {- _PC_REC_INCR_XFER_SIZE -}\n"
           "  \t\t\t\t  {- _PC_REC_MAX_XFER_SIZE  -}\n"
           "  \t\t\t\t  {- _PC_REC_MIN_XFER_SIZE  -}\n"
           " \t\t\t\t  {- _PC_REC_XFER_ALIGN     -}\n"
           "  | SymbolicLinkLimit\t\t  {- _PC_SYMLINK_MAX      -}\n"
           "  | SetOwnerAndGroupIsRestricted  {- _PC_CHOWN_RESTRICTED -}\n"
           "  | FileNamesAreNotTruncated      {- _PC_NO_TRUNC         -}\n"
           "  | VDisableChar\t\t  {- _PC_VDISABLE         -}\n"
           "  | AsyncIOAvailable\t\t  {- _PC_ASYNC_IO         -}\n"
           "  | PrioIOAvailable\t\t  {- _PC_PRIO_IO          -}\n"
           "  | SyncIOAvailable\t\t  {- _PC_SYNC_IO          -}\n"
           "\n"
           "pathVarConst :: PathVar -> CInt\n"
           "pathVarConst v = case v of\n"
           "\tLinkLimit     \t\t\t-> (", stdout);
#line 460 "Files.hsc"
    hsc_const (_PC_LINK_MAX);
    fputs (")\n"
           "", stdout);
    hsc_line (461, "Files.hsc");
    fputs ("\tInputLineLimit\t\t\t-> (", stdout);
#line 461 "Files.hsc"
    hsc_const (_PC_MAX_CANON);
    fputs (")\n"
           "", stdout);
    hsc_line (462, "Files.hsc");
    fputs ("\tInputQueueLimit\t\t\t-> (", stdout);
#line 462 "Files.hsc"
    hsc_const (_PC_MAX_INPUT);
    fputs (")\n"
           "", stdout);
    hsc_line (463, "Files.hsc");
    fputs ("\tFileNameLimit\t\t\t-> (", stdout);
#line 463 "Files.hsc"
    hsc_const (_PC_NAME_MAX);
    fputs (")\n"
           "", stdout);
    hsc_line (464, "Files.hsc");
    fputs ("\tPathNameLimit\t\t\t-> (", stdout);
#line 464 "Files.hsc"
    hsc_const (_PC_PATH_MAX);
    fputs (")\n"
           "", stdout);
    hsc_line (465, "Files.hsc");
    fputs ("\tPipeBufferLimit\t\t\t-> (", stdout);
#line 465 "Files.hsc"
    hsc_const (_PC_PIPE_BUF);
    fputs (")\n"
           "", stdout);
    hsc_line (466, "Files.hsc");
    fputs ("\tSetOwnerAndGroupIsRestricted\t-> (", stdout);
#line 466 "Files.hsc"
    hsc_const (_PC_CHOWN_RESTRICTED);
    fputs (")\n"
           "", stdout);
    hsc_line (467, "Files.hsc");
    fputs ("\tFileNamesAreNotTruncated\t-> (", stdout);
#line 467 "Files.hsc"
    hsc_const (_PC_NO_TRUNC);
    fputs (")\n"
           "", stdout);
    hsc_line (468, "Files.hsc");
    fputs ("\tVDisableChar\t\t\t-> (", stdout);
#line 468 "Files.hsc"
    hsc_const (_PC_VDISABLE);
    fputs (")\n"
           "", stdout);
    hsc_line (469, "Files.hsc");
    fputs ("\n"
           "", stdout);
#line 470 "Files.hsc"
#ifdef _PC_SYNC_IO
    fputs ("\n"
           "", stdout);
    hsc_line (471, "Files.hsc");
    fputs ("\tSyncIOAvailable\t\t-> (", stdout);
#line 471 "Files.hsc"
    hsc_const (_PC_SYNC_IO);
    fputs (")\n"
           "", stdout);
    hsc_line (472, "Files.hsc");
    fputs ("", stdout);
#line 472 "Files.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (473, "Files.hsc");
    fputs ("\tSyncIOAvailable\t\t-> error \"_PC_SYNC_IO not available\"\n"
           "", stdout);
#line 474 "Files.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (475, "Files.hsc");
    fputs ("\n"
           "", stdout);
#line 476 "Files.hsc"
#ifdef _PC_ASYNC_IO
    fputs ("\n"
           "", stdout);
    hsc_line (477, "Files.hsc");
    fputs ("\tAsyncIOAvailable\t-> (", stdout);
#line 477 "Files.hsc"
    hsc_const (_PC_ASYNC_IO);
    fputs (")\n"
           "", stdout);
    hsc_line (478, "Files.hsc");
    fputs ("", stdout);
#line 478 "Files.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (479, "Files.hsc");
    fputs ("\tAsyncIOAvailable\t-> error \"_PC_ASYNC_IO not available\"\n"
           "", stdout);
#line 480 "Files.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (481, "Files.hsc");
    fputs ("\n"
           "", stdout);
#line 482 "Files.hsc"
#ifdef _PC_PRIO_IO
    fputs ("\n"
           "", stdout);
    hsc_line (483, "Files.hsc");
    fputs ("\tPrioIOAvailable\t\t-> (", stdout);
#line 483 "Files.hsc"
    hsc_const (_PC_PRIO_IO);
    fputs (")\n"
           "", stdout);
    hsc_line (484, "Files.hsc");
    fputs ("", stdout);
#line 484 "Files.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (485, "Files.hsc");
    fputs ("\tPrioIOAvailable\t\t-> error \"_PC_PRIO_IO not available\"\n"
           "", stdout);
#line 486 "Files.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (487, "Files.hsc");
    fputs ("\n"
           "", stdout);
#line 488 "Files.hsc"
#if _PC_FILESIZEBITS
    fputs ("\n"
           "", stdout);
    hsc_line (489, "Files.hsc");
    fputs ("\tFileSizeBits\t\t-> (", stdout);
#line 489 "Files.hsc"
    hsc_const (_PC_FILESIZEBITS);
    fputs (")\n"
           "", stdout);
    hsc_line (490, "Files.hsc");
    fputs ("", stdout);
#line 490 "Files.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (491, "Files.hsc");
    fputs ("\tFileSizeBits\t\t-> error \"_PC_FILESIZEBITS not available\"\n"
           "", stdout);
#line 492 "Files.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (493, "Files.hsc");
    fputs ("\n"
           "", stdout);
#line 494 "Files.hsc"
#if _PC_SYMLINK_MAX
    fputs ("\n"
           "", stdout);
    hsc_line (495, "Files.hsc");
    fputs ("\tSymbolicLinkLimit\t-> (", stdout);
#line 495 "Files.hsc"
    hsc_const (_PC_SYMLINK_MAX);
    fputs (")\n"
           "", stdout);
    hsc_line (496, "Files.hsc");
    fputs ("", stdout);
#line 496 "Files.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (497, "Files.hsc");
    fputs ("\tSymbolicLinkLimit\t-> error \"_PC_SYMLINK_MAX not available\"\n"
           "", stdout);
#line 498 "Files.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (499, "Files.hsc");
    fputs ("\n"
           "getPathVar :: FilePath -> PathVar -> IO Limit\n"
           "getPathVar name v = do\n"
           "  withCString name $ \\ nameP -> \n"
           "    throwErrnoIfMinus1 \"getPathVar\" $ \n"
           "      c_pathconf nameP (pathVarConst v)\n"
           "\n"
           "foreign import ccall unsafe \"pathconf\" \n"
           "  c_pathconf :: CString -> CInt -> IO CLong\n"
           "\n"
           "getFdPathVar :: Fd -> PathVar -> IO Limit\n"
           "getFdPathVar fd v =\n"
           "    throwErrnoIfMinus1 \"getFdPathVar\" $ \n"
           "      c_fpathconf fd (pathVarConst v)\n"
           "\n"
           "foreign import ccall unsafe \"fpathconf\" \n"
           "  c_fpathconf :: Fd -> CInt -> IO CLong\n"
           "", stdout);
    return 0;
}
