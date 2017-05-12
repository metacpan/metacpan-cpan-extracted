#include "template-hsc.h"
#line 43 "User.hsc"
#include "HsUnix.h"
#line 45 "User.hsc"
#ifdef solaris_TARGET_OS
#line 47 "User.hsc"
#define _POSIX_PTHREAD_SEMANTICS
#line 48 "User.hsc"
#endif 
#line 134 "User.hsc"
#ifdef HAVE_GETGRGID_R
#line 147 "User.hsc"
#else 
#line 149 "User.hsc"
#endif 
#line 153 "User.hsc"
#ifdef HAVE_GETGRNAM_R
#line 166 "User.hsc"
#else 
#line 168 "User.hsc"
#endif 
#line 170 "User.hsc"
#if defined(HAVE_GETGRGID_R) || defined(HAVE_GETGRNAM_R)
#line 172 "User.hsc"
#if defined(HAVE_SYSCONF) && defined(HAVE_SC_GETGR_R_SIZE_MAX)
#line 175 "User.hsc"
#else 
#line 177 "User.hsc"
#endif 
#line 178 "User.hsc"
#endif 
#line 201 "User.hsc"
#ifdef HAVE_GETPWUID_R
#line 213 "User.hsc"
#else 
#line 215 "User.hsc"
#endif 
#line 218 "User.hsc"
#if HAVE_GETPWNAM_R
#line 231 "User.hsc"
#else 
#line 233 "User.hsc"
#endif 
#line 235 "User.hsc"
#if defined(HAVE_GETPWUID_R) || defined(HAVE_GETPWNAM_R)
#line 237 "User.hsc"
#if defined(HAVE_SYSCONF) && defined(HAVE_SC_GETPW_R_SIZE_MAX)
#line 240 "User.hsc"
#else 
#line 242 "User.hsc"
#endif 
#line 243 "User.hsc"
#endif 
#line 245 "User.hsc"
#ifdef HAVE_SYSCONF
#line 248 "User.hsc"
#endif 

int main (int argc, char *argv [])
{
#if __GLASGOW_HASKELL__ && __GLASGOW_HASKELL__ < 409
    printf ("{-# OPTIONS -optc-D__GLASGOW_HASKELL__=%d #-}\n", 603);
#endif
    printf ("{-# OPTIONS %s #-}\n", "-#include \"HsUnix.h\"");
#line 45 "User.hsc"
#ifdef solaris_TARGET_OS
    printf ("{-# OPTIONS %s #-}\n", "-optc-D_POSIX_PTHREAD_SEMANTICS");
#line 48 "User.hsc"
#endif 
#line 134 "User.hsc"
#ifdef HAVE_GETGRGID_R
#line 147 "User.hsc"
#else 
#line 149 "User.hsc"
#endif 
#line 153 "User.hsc"
#ifdef HAVE_GETGRNAM_R
#line 166 "User.hsc"
#else 
#line 168 "User.hsc"
#endif 
#line 170 "User.hsc"
#if defined(HAVE_GETGRGID_R) || defined(HAVE_GETGRNAM_R)
#line 172 "User.hsc"
#if defined(HAVE_SYSCONF) && defined(HAVE_SC_GETGR_R_SIZE_MAX)
#line 175 "User.hsc"
#else 
#line 177 "User.hsc"
#endif 
#line 178 "User.hsc"
#endif 
#line 201 "User.hsc"
#ifdef HAVE_GETPWUID_R
#line 213 "User.hsc"
#else 
#line 215 "User.hsc"
#endif 
#line 218 "User.hsc"
#if HAVE_GETPWNAM_R
#line 231 "User.hsc"
#else 
#line 233 "User.hsc"
#endif 
#line 235 "User.hsc"
#if defined(HAVE_GETPWUID_R) || defined(HAVE_GETPWNAM_R)
#line 237 "User.hsc"
#if defined(HAVE_SYSCONF) && defined(HAVE_SC_GETPW_R_SIZE_MAX)
#line 240 "User.hsc"
#else 
#line 242 "User.hsc"
#endif 
#line 243 "User.hsc"
#endif 
#line 245 "User.hsc"
#ifdef HAVE_SYSCONF
#line 248 "User.hsc"
#endif 
    hsc_line (1, "User.hsc");
    fputs ("{-# OPTIONS -fffi #-}\n"
           "", stdout);
    hsc_line (2, "User.hsc");
    fputs ("-----------------------------------------------------------------------------\n"
           "-- |\n"
           "-- Module      :  System.Posix.User\n"
           "-- Copyright   :  (c) The University of Glasgow 2002\n"
           "-- License     :  BSD-style (see the file libraries/base/LICENSE)\n"
           "-- \n"
           "-- Maintainer  :  libraries@haskell.org\n"
           "-- Stability   :  provisional\n"
           "-- Portability :  non-portable (requires POSIX)\n"
           "--\n"
           "-- POSIX user\\/group support\n"
           "--\n"
           "-----------------------------------------------------------------------------\n"
           "\n"
           "module System.Posix.User (\n"
           "    -- * User environment\n"
           "    -- ** Querying the user environment\n"
           "    getRealUserID,\n"
           "    getRealGroupID,\n"
           "    getEffectiveUserID,\n"
           "    getEffectiveGroupID,\n"
           "    getGroups,\n"
           "    getLoginName,\n"
           "    getEffectiveUserName,\n"
           "\n"
           "    -- *** The group database\n"
           "    GroupEntry(..),\n"
           "    getGroupEntryForID,\n"
           "    getGroupEntryForName,\n"
           "\n"
           "    -- *** The user database\n"
           "    UserEntry(..),\n"
           "    getUserEntryForID,\n"
           "    getUserEntryForName,\n"
           "\n"
           "    -- ** Modifying the user environment\n"
           "    setUserID,\n"
           "    setGroupID,\n"
           "\n"
           "  ) where\n"
           "\n"
           "", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (44, "User.hsc");
    fputs ("\n"
           "", stdout);
#line 45 "User.hsc"
#ifdef solaris_TARGET_OS
    fputs ("\n"
           "", stdout);
    hsc_line (46, "User.hsc");
    fputs ("-- Solaris needs this in order to get the POSIX versions of getgrnam_r etc.\n"
           "", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (48, "User.hsc");
    fputs ("", stdout);
#line 48 "User.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (49, "User.hsc");
    fputs ("\n"
           "import System.Posix.Types\n"
           "import Foreign\n"
           "import Foreign.C\n"
           "import System.Posix.Internals\t( CGroup, CPasswd )\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- user environemnt\n"
           "\n"
           "getRealUserID :: IO UserID\n"
           "getRealUserID = c_getuid\n"
           "\n"
           "foreign import ccall unsafe \"getuid\"\n"
           "  c_getuid :: IO CUid\n"
           "\n"
           "getRealGroupID :: IO GroupID\n"
           "getRealGroupID = c_getgid\n"
           "\n"
           "foreign import ccall unsafe \"getgid\"\n"
           "  c_getgid :: IO CGid\n"
           "\n"
           "getEffectiveUserID :: IO UserID\n"
           "getEffectiveUserID = c_geteuid\n"
           "\n"
           "foreign import ccall unsafe \"geteuid\"\n"
           "  c_geteuid :: IO CUid\n"
           "\n"
           "getEffectiveGroupID :: IO GroupID\n"
           "getEffectiveGroupID = c_getegid\n"
           "\n"
           "foreign import ccall unsafe \"getegid\"\n"
           "  c_getegid :: IO CGid\n"
           "\n"
           "getGroups :: IO [GroupID]\n"
           "getGroups = do\n"
           "    ngroups <- c_getgroups 0 nullPtr\n"
           "    allocaArray (fromIntegral ngroups) $ \\arr -> do\n"
           "       throwErrnoIfMinus1_ \"getGroups\" (c_getgroups ngroups arr)\n"
           "       groups <- peekArray (fromIntegral ngroups) arr\n"
           "       return groups\n"
           "\n"
           "foreign import ccall unsafe \"getgroups\"\n"
           "  c_getgroups :: CInt -> Ptr CGid -> IO CInt\n"
           "\n"
           "-- ToDo: use getlogin_r\n"
           "getLoginName :: IO String\n"
           "getLoginName =  do\n"
           "    str <- throwErrnoIfNull \"getLoginName\" c_getlogin\n"
           "    peekCString str\n"
           "\n"
           "foreign import ccall unsafe \"getlogin\"\n"
           "  c_getlogin :: IO CString\n"
           "\n"
           "setUserID :: UserID -> IO ()\n"
           "setUserID uid = throwErrnoIfMinus1_ \"setUserID\" (c_setuid uid)\n"
           "\n"
           "foreign import ccall unsafe \"setuid\"\n"
           "  c_setuid :: CUid -> IO CInt\n"
           "\n"
           "setGroupID :: GroupID -> IO ()\n"
           "setGroupID gid = throwErrnoIfMinus1_ \"setGroupID\" (c_setgid gid)\n"
           "\n"
           "foreign import ccall unsafe \"setgid\"\n"
           "  c_setgid :: CGid -> IO CInt\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- User names\n"
           "\n"
           "getEffectiveUserName :: IO String\n"
           "getEffectiveUserName = do\n"
           "    euid <- getEffectiveUserID\n"
           "    pw <- getUserEntryForID euid\n"
           "    return (userName pw)\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- The group database (grp.h)\n"
           "\n"
           "data GroupEntry =\n"
           " GroupEntry {\n"
           "  groupName    :: String,\n"
           "  groupID      :: GroupID,\n"
           "  groupMembers :: [String]\n"
           " }\n"
           "\n"
           "getGroupEntryForID :: GroupID -> IO GroupEntry\n"
           "", stdout);
#line 134 "User.hsc"
#ifdef HAVE_GETGRGID_R
    fputs ("\n"
           "", stdout);
    hsc_line (135, "User.hsc");
    fputs ("getGroupEntryForID gid = do\n"
           "  allocaBytes (", stdout);
#line 136 "User.hsc"
    hsc_const (sizeof(struct group));
    fputs (") $ \\pgr ->\n"
           "", stdout);
    hsc_line (137, "User.hsc");
    fputs ("    allocaBytes grBufSize $ \\pbuf ->\n"
           "      alloca $ \\ ppgr -> do\n"
           "        throwErrorIfNonZero_ \"getGroupEntryForID\" $\n"
           "\t     c_getgrgid_r gid pgr pbuf (fromIntegral grBufSize) ppgr\n"
           "\tunpackGroupEntry pgr\n"
           "\n"
           "\n"
           "foreign import ccall unsafe \"getgrgid_r\"\n"
           "  c_getgrgid_r :: CGid -> Ptr CGroup -> CString\n"
           "\t\t -> CSize -> Ptr (Ptr CGroup) -> IO CInt\n"
           "", stdout);
#line 147 "User.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (148, "User.hsc");
    fputs ("getGroupEntryForID = error \"System.Posix.User.getGroupEntryForID: not supported\"\n"
           "", stdout);
#line 149 "User.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (150, "User.hsc");
    fputs ("\n"
           "\n"
           "getGroupEntryForName :: String -> IO GroupEntry\n"
           "", stdout);
#line 153 "User.hsc"
#ifdef HAVE_GETGRNAM_R
    fputs ("\n"
           "", stdout);
    hsc_line (154, "User.hsc");
    fputs ("getGroupEntryForName name = do\n"
           "  allocaBytes (", stdout);
#line 155 "User.hsc"
    hsc_const (sizeof(struct group));
    fputs (") $ \\pgr ->\n"
           "", stdout);
    hsc_line (156, "User.hsc");
    fputs ("    allocaBytes grBufSize $ \\pbuf ->\n"
           "      alloca $ \\ ppgr -> \n"
           "\twithCString name $ \\ pstr -> do\n"
           "          throwErrorIfNonZero_ \"getGroupEntryForName\" $\n"
           "\t     c_getgrnam_r pstr pgr pbuf (fromIntegral grBufSize) ppgr\n"
           "\t  unpackGroupEntry pgr\n"
           "\n"
           "foreign import ccall unsafe \"getgrnam_r\"\n"
           "  c_getgrnam_r :: CString -> Ptr CGroup -> CString\n"
           "\t\t -> CSize -> Ptr (Ptr CGroup) -> IO CInt\n"
           "", stdout);
#line 166 "User.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (167, "User.hsc");
    fputs ("getGroupEntryForName = error \"System.Posix.User.getGroupEntryForName: not supported\"\n"
           "", stdout);
#line 168 "User.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (169, "User.hsc");
    fputs ("\n"
           "", stdout);
#line 170 "User.hsc"
#if defined(HAVE_GETGRGID_R) || defined(HAVE_GETGRNAM_R)
    fputs ("\n"
           "", stdout);
    hsc_line (171, "User.hsc");
    fputs ("grBufSize :: Int\n"
           "", stdout);
#line 172 "User.hsc"
#if defined(HAVE_SYSCONF) && defined(HAVE_SC_GETGR_R_SIZE_MAX)
    fputs ("\n"
           "", stdout);
    hsc_line (173, "User.hsc");
    fputs ("grBufSize = fromIntegral $ unsafePerformIO $\n"
           "\t\tc_sysconf (", stdout);
#line 174 "User.hsc"
    hsc_const (_SC_GETGR_R_SIZE_MAX);
    fputs (")\n"
           "", stdout);
    hsc_line (175, "User.hsc");
    fputs ("", stdout);
#line 175 "User.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (176, "User.hsc");
    fputs ("grBufSize = 1024\t-- just assume some value\n"
           "", stdout);
#line 177 "User.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (178, "User.hsc");
    fputs ("", stdout);
#line 178 "User.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (179, "User.hsc");
    fputs ("\n"
           "unpackGroupEntry :: Ptr CGroup -> IO GroupEntry\n"
           "unpackGroupEntry ptr = do\n"
           "   name    <- (", stdout);
#line 182 "User.hsc"
    hsc_peek (struct group, gr_name);
    fputs (") ptr >>= peekCString\n"
           "", stdout);
    hsc_line (183, "User.hsc");
    fputs ("   gid     <- (", stdout);
#line 183 "User.hsc"
    hsc_peek (struct group, gr_gid);
    fputs (") ptr\n"
           "", stdout);
    hsc_line (184, "User.hsc");
    fputs ("   mem     <- (", stdout);
#line 184 "User.hsc"
    hsc_peek (struct group, gr_mem);
    fputs (") ptr\n"
           "", stdout);
    hsc_line (185, "User.hsc");
    fputs ("   members <- peekArray0 nullPtr mem >>= mapM peekCString\n"
           "   return (GroupEntry name gid members)\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- The user database (pwd.h)\n"
           "\n"
           "data UserEntry =\n"
           " UserEntry {\n"
           "   userName      :: String,\n"
           "   userID        :: UserID,\n"
           "   userGroupID   :: GroupID,\n"
           "   homeDirectory :: String,\n"
           "   userShell     :: String\n"
           " }\n"
           "\n"
           "getUserEntryForID :: UserID -> IO UserEntry\n"
           "", stdout);
#line 201 "User.hsc"
#ifdef HAVE_GETPWUID_R
    fputs ("\n"
           "", stdout);
    hsc_line (202, "User.hsc");
    fputs ("getUserEntryForID uid = do\n"
           "  allocaBytes (", stdout);
#line 203 "User.hsc"
    hsc_const (sizeof(struct passwd));
    fputs (") $ \\ppw ->\n"
           "", stdout);
    hsc_line (204, "User.hsc");
    fputs ("    allocaBytes pwBufSize $ \\pbuf ->\n"
           "      alloca $ \\ pppw -> do\n"
           "        throwErrorIfNonZero_ \"getUserEntryForID\" $\n"
           "\t     c_getpwuid_r uid ppw pbuf (fromIntegral pwBufSize) pppw\n"
           "\tunpackUserEntry ppw\n"
           "\n"
           "foreign import ccall unsafe \"getpwuid_r\"\n"
           "  c_getpwuid_r :: CUid -> Ptr CPasswd -> \n"
           "\t\t\tCString -> CSize -> Ptr (Ptr CPasswd) -> IO CInt\n"
           "", stdout);
#line 213 "User.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (214, "User.hsc");
    fputs ("getUserEntryForID = error \"System.Posix.User.getUserEntryForID: not supported\"\n"
           "", stdout);
#line 215 "User.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (216, "User.hsc");
    fputs ("\n"
           "getUserEntryForName :: String -> IO UserEntry\n"
           "", stdout);
#line 218 "User.hsc"
#if HAVE_GETPWNAM_R
    fputs ("\n"
           "", stdout);
    hsc_line (219, "User.hsc");
    fputs ("getUserEntryForName name = do\n"
           "  allocaBytes (", stdout);
#line 220 "User.hsc"
    hsc_const (sizeof(struct passwd));
    fputs (") $ \\ppw ->\n"
           "", stdout);
    hsc_line (221, "User.hsc");
    fputs ("    allocaBytes pwBufSize $ \\pbuf ->\n"
           "      alloca $ \\ pppw -> \n"
           "\twithCString name $ \\ pstr -> do\n"
           "          throwErrorIfNonZero_ \"getUserEntryForName\" $\n"
           "\t       c_getpwnam_r pstr ppw pbuf (fromIntegral pwBufSize) pppw\n"
           "\t  unpackUserEntry ppw\n"
           "\n"
           "foreign import ccall unsafe \"getpwnam_r\"\n"
           "  c_getpwnam_r :: CString -> Ptr CPasswd -> \n"
           "\t\t\tCString -> CSize -> Ptr (Ptr CPasswd) -> IO CInt\n"
           "", stdout);
#line 231 "User.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (232, "User.hsc");
    fputs ("getUserEntryForName = error \"System.Posix.User.getUserEntryForName: not supported\"\n"
           "", stdout);
#line 233 "User.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (234, "User.hsc");
    fputs ("\n"
           "", stdout);
#line 235 "User.hsc"
#if defined(HAVE_GETPWUID_R) || defined(HAVE_GETPWNAM_R)
    fputs ("\n"
           "", stdout);
    hsc_line (236, "User.hsc");
    fputs ("pwBufSize :: Int\n"
           "", stdout);
#line 237 "User.hsc"
#if defined(HAVE_SYSCONF) && defined(HAVE_SC_GETPW_R_SIZE_MAX)
    fputs ("\n"
           "", stdout);
    hsc_line (238, "User.hsc");
    fputs ("pwBufSize = fromIntegral $ unsafePerformIO $\n"
           "\t\tc_sysconf (", stdout);
#line 239 "User.hsc"
    hsc_const (_SC_GETPW_R_SIZE_MAX);
    fputs (")\n"
           "", stdout);
    hsc_line (240, "User.hsc");
    fputs ("", stdout);
#line 240 "User.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (241, "User.hsc");
    fputs ("pwBufSize = 1024\n"
           "", stdout);
#line 242 "User.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (243, "User.hsc");
    fputs ("", stdout);
#line 243 "User.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (244, "User.hsc");
    fputs ("\n"
           "", stdout);
#line 245 "User.hsc"
#ifdef HAVE_SYSCONF
    fputs ("\n"
           "", stdout);
    hsc_line (246, "User.hsc");
    fputs ("foreign import ccall unsafe \"sysconf\"\n"
           "  c_sysconf :: CInt -> IO CLong\n"
           "", stdout);
#line 248 "User.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (249, "User.hsc");
    fputs ("\n"
           "unpackUserEntry :: Ptr CPasswd -> IO UserEntry\n"
           "unpackUserEntry ptr = do\n"
           "   name   <- (", stdout);
#line 252 "User.hsc"
    hsc_peek (struct passwd, pw_name);
    fputs (")  ptr >>= peekCString\n"
           "", stdout);
    hsc_line (253, "User.hsc");
    fputs ("   uid    <- (", stdout);
#line 253 "User.hsc"
    hsc_peek (struct passwd, pw_uid);
    fputs (")   ptr\n"
           "", stdout);
    hsc_line (254, "User.hsc");
    fputs ("   gid    <- (", stdout);
#line 254 "User.hsc"
    hsc_peek (struct passwd, pw_gid);
    fputs (")   ptr\n"
           "", stdout);
    hsc_line (255, "User.hsc");
    fputs ("   dir    <- (", stdout);
#line 255 "User.hsc"
    hsc_peek (struct passwd, pw_dir);
    fputs (")   ptr >>= peekCString\n"
           "", stdout);
    hsc_line (256, "User.hsc");
    fputs ("   shell  <- (", stdout);
#line 256 "User.hsc"
    hsc_peek (struct passwd, pw_shell);
    fputs (") ptr >>= peekCString\n"
           "", stdout);
    hsc_line (257, "User.hsc");
    fputs ("   return (UserEntry name uid gid dir shell)\n"
           "\n"
           "-- Used when calling re-entrant system calls that signal their \'errno\' \n"
           "-- directly through the return value.\n"
           "throwErrorIfNonZero_ :: String -> IO CInt -> IO ()\n"
           "throwErrorIfNonZero_ loc act = do\n"
           "    rc <- act\n"
           "    if (rc == 0) \n"
           "     then return ()\n"
           "     else ioError (errnoToIOError loc (Errno (fromIntegral rc)) Nothing Nothing)\n"
           "\n"
           "", stdout);
    return 0;
}
