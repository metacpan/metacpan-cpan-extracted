#include "template-hsc.h"
#line 23 "BSD.hsc"
#include "HsNet.h"
#line 36 "BSD.hsc"
#if !defined(cygwin32_TARGET_OS) && !defined(mingw32_TARGET_OS) && !defined(_WIN32)
#line 41 "BSD.hsc"
#endif 
#line 50 "BSD.hsc"
#if !defined(cygwin32_TARGET_OS) && !defined(mingw32_TARGET_OS) && !defined(_WIN32)
#line 55 "BSD.hsc"
#endif 
#line 65 "BSD.hsc"
#if !defined(cygwin32_TARGET_OS) && !defined(mingw32_TARGET_OS) && !defined(_WIN32)
#line 70 "BSD.hsc"
#endif 
#line 80 "BSD.hsc"
#if !defined(cygwin32_TARGET_OS) && !defined(mingw32_TARGET_OS) && !defined(_WIN32)
#line 87 "BSD.hsc"
#endif 
#line 89 "BSD.hsc"
#ifdef HAVE_SYMLINK
#line 92 "BSD.hsc"
#endif 
#line 93 "BSD.hsc"
#ifdef HAVE_READLINK
#line 95 "BSD.hsc"
#endif 
#line 99 "BSD.hsc"
#ifdef __HUGS__
#line 101 "BSD.hsc"
#endif 
#line 112 "BSD.hsc"
#ifdef __GLASGOW_HASKELL__
#line 114 "BSD.hsc"
#endif 
#line 161 "BSD.hsc"
#if defined(HAVE_WINSOCK_H) && !defined(cygwin32_TARGET_OS)
#line 163 "BSD.hsc"
#else 
#line 167 "BSD.hsc"
#endif 
#line 202 "BSD.hsc"
#if !defined(cygwin32_TARGET_OS) && !defined(mingw32_TARGET_OS) && !defined(_WIN32)
#line 225 "BSD.hsc"
#endif 
#line 255 "BSD.hsc"
#if defined(HAVE_WINSOCK_H) && !defined(cygwin32_TARGET_OS)
#line 261 "BSD.hsc"
#else 
#line 263 "BSD.hsc"
#endif 
#line 298 "BSD.hsc"
#if !defined(cygwin32_TARGET_OS) && !defined(mingw32_TARGET_OS) && !defined(_WIN32)
#line 321 "BSD.hsc"
#endif 
#line 385 "BSD.hsc"
#if !defined(cygwin32_TARGET_OS) && !defined(mingw32_TARGET_OS) && !defined(_WIN32)
#line 408 "BSD.hsc"
#endif 
#line 451 "BSD.hsc"
#if !defined(cygwin32_TARGET_OS) && !defined(mingw32_TARGET_OS) && !defined(_WIN32)
#line 493 "BSD.hsc"
#endif 
#line 529 "BSD.hsc"
#ifdef HAVE_SYMLINK
#line 539 "BSD.hsc"
#endif 
#line 541 "BSD.hsc"
#ifdef HAVE_READLINK
#line 553 "BSD.hsc"
#endif 
#line 560 "BSD.hsc"
#if !defined(mingw32_TARGET_OS) && !defined(_WIN32)
#line 562 "BSD.hsc"
#else 
#line 568 "BSD.hsc"
#endif 

int main (int argc, char *argv [])
{
#if __GLASGOW_HASKELL__ && __GLASGOW_HASKELL__ < 409
    printf ("{-# OPTIONS -optc-D__GLASGOW_HASKELL__=%d #-}\n", 603);
#endif
    printf ("{-# OPTIONS %s #-}\n", "-#include \"HsNet.h\"");
#line 36 "BSD.hsc"
#if !defined(cygwin32_TARGET_OS) && !defined(mingw32_TARGET_OS) && !defined(_WIN32)
#line 41 "BSD.hsc"
#endif 
#line 50 "BSD.hsc"
#if !defined(cygwin32_TARGET_OS) && !defined(mingw32_TARGET_OS) && !defined(_WIN32)
#line 55 "BSD.hsc"
#endif 
#line 65 "BSD.hsc"
#if !defined(cygwin32_TARGET_OS) && !defined(mingw32_TARGET_OS) && !defined(_WIN32)
#line 70 "BSD.hsc"
#endif 
#line 80 "BSD.hsc"
#if !defined(cygwin32_TARGET_OS) && !defined(mingw32_TARGET_OS) && !defined(_WIN32)
#line 87 "BSD.hsc"
#endif 
#line 89 "BSD.hsc"
#ifdef HAVE_SYMLINK
#line 92 "BSD.hsc"
#endif 
#line 93 "BSD.hsc"
#ifdef HAVE_READLINK
#line 95 "BSD.hsc"
#endif 
#line 99 "BSD.hsc"
#ifdef __HUGS__
#line 101 "BSD.hsc"
#endif 
#line 112 "BSD.hsc"
#ifdef __GLASGOW_HASKELL__
#line 114 "BSD.hsc"
#endif 
#line 161 "BSD.hsc"
#if defined(HAVE_WINSOCK_H) && !defined(cygwin32_TARGET_OS)
#line 163 "BSD.hsc"
#else 
#line 167 "BSD.hsc"
#endif 
#line 202 "BSD.hsc"
#if !defined(cygwin32_TARGET_OS) && !defined(mingw32_TARGET_OS) && !defined(_WIN32)
#line 225 "BSD.hsc"
#endif 
#line 255 "BSD.hsc"
#if defined(HAVE_WINSOCK_H) && !defined(cygwin32_TARGET_OS)
#line 261 "BSD.hsc"
#else 
#line 263 "BSD.hsc"
#endif 
#line 298 "BSD.hsc"
#if !defined(cygwin32_TARGET_OS) && !defined(mingw32_TARGET_OS) && !defined(_WIN32)
#line 321 "BSD.hsc"
#endif 
#line 385 "BSD.hsc"
#if !defined(cygwin32_TARGET_OS) && !defined(mingw32_TARGET_OS) && !defined(_WIN32)
#line 408 "BSD.hsc"
#endif 
#line 451 "BSD.hsc"
#if !defined(cygwin32_TARGET_OS) && !defined(mingw32_TARGET_OS) && !defined(_WIN32)
#line 493 "BSD.hsc"
#endif 
#line 529 "BSD.hsc"
#ifdef HAVE_SYMLINK
#line 539 "BSD.hsc"
#endif 
#line 541 "BSD.hsc"
#ifdef HAVE_READLINK
#line 553 "BSD.hsc"
#endif 
#line 560 "BSD.hsc"
#if !defined(mingw32_TARGET_OS) && !defined(_WIN32)
#line 562 "BSD.hsc"
#else 
#line 568 "BSD.hsc"
#endif 
    hsc_line (1, "BSD.hsc");
    fputs ("{-# OPTIONS -fglasgow-exts #-}\n"
           "", stdout);
    hsc_line (2, "BSD.hsc");
    fputs ("-----------------------------------------------------------------------------\n"
           "-- |\n"
           "-- Module      :  Network.BSD\n"
           "-- Copyright   :  (c) The University of Glasgow 2001\n"
           "-- License     :  BSD-style (see the file libraries/net/LICENSE)\n"
           "-- \n"
           "-- Maintainer  :  libraries@haskell.org\n"
           "-- Stability   :  experimental\n"
           "-- Portability :  non-portable\n"
           "--\n"
           "-- The \"Network.BSD\" module defines Haskell bindings to functionality\n"
           "-- provided by BSD Unix derivatives. Currently this covers\n"
           "-- network programming functionality and symbolic links.\n"
           "-- (OK, so the latter is pretty much supported by most Unixes\n"
           "-- today, but it was BSD that introduced them.)  \n"
           "--\n"
           "-- The symlink stuff is really in the wrong place, at some point it will move\n"
           "-- to a generic Unix library somewhere else in the module tree.\n"
           "--\n"
           "-----------------------------------------------------------------------------\n"
           "\n"
           "", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (24, "BSD.hsc");
    fputs ("\n"
           "module Network.BSD (\n"
           "       \n"
           "    -- * Host names\n"
           "    HostName,\n"
           "    getHostName,\t    -- :: IO HostName\n"
           "\n"
           "    HostEntry(..),\n"
           "    getHostByName,\t    -- :: HostName -> IO HostEntry\n"
           "    getHostByAddr,\t    -- :: HostAddress -> Family -> IO HostEntry\n"
           "    hostAddress,\t    -- :: HostEntry -> HostAddress\n"
           "\n"
           "", stdout);
#line 36 "BSD.hsc"
#if !defined(cygwin32_TARGET_OS) && !defined(mingw32_TARGET_OS) && !defined(_WIN32)
    fputs ("\n"
           "", stdout);
    hsc_line (37, "BSD.hsc");
    fputs ("    setHostEntry,\t    -- :: Bool -> IO ()\n"
           "    getHostEntry,\t    -- :: IO HostEntry\n"
           "    endHostEntry,\t    -- :: IO ()\n"
           "    getHostEntries,\t    -- :: Bool -> IO [HostEntry]\n"
           "", stdout);
#line 41 "BSD.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (42, "BSD.hsc");
    fputs ("\n"
           "    -- * Service names\n"
           "    ServiceEntry(..),\n"
           "    ServiceName,\n"
           "    getServiceByName,\t    -- :: ServiceName -> ProtocolName -> IO ServiceEntry\n"
           "    getServiceByPort,       -- :: PortNumber  -> ProtocolName -> IO ServiceEntry\n"
           "    getServicePortNumber,   -- :: ServiceName -> IO PortNumber\n"
           "\n"
           "", stdout);
#line 50 "BSD.hsc"
#if !defined(cygwin32_TARGET_OS) && !defined(mingw32_TARGET_OS) && !defined(_WIN32)
    fputs ("\n"
           "", stdout);
    hsc_line (51, "BSD.hsc");
    fputs ("    getServiceEntry,\t    -- :: IO ServiceEntry\n"
           "    setServiceEntry,\t    -- :: Bool -> IO ()\n"
           "    endServiceEntry,\t    -- :: IO ()\n"
           "    getServiceEntries,\t    -- :: Bool -> IO [ServiceEntry]\n"
           "", stdout);
#line 55 "BSD.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (56, "BSD.hsc");
    fputs ("\n"
           "    -- * Protocol names\n"
           "    ProtocolName,\n"
           "    ProtocolNumber,\n"
           "    ProtocolEntry(..),\n"
           "    getProtocolByName,\t    -- :: ProtocolName   -> IO ProtocolEntry\n"
           "    getProtocolByNumber,    -- :: ProtocolNumber -> IO ProtcolEntry\n"
           "    getProtocolNumber,\t    -- :: ProtocolName   -> ProtocolNumber\n"
           "\n"
           "", stdout);
#line 65 "BSD.hsc"
#if !defined(cygwin32_TARGET_OS) && !defined(mingw32_TARGET_OS) && !defined(_WIN32)
    fputs ("\n"
           "", stdout);
    hsc_line (66, "BSD.hsc");
    fputs ("    setProtocolEntry,\t    -- :: Bool -> IO ()\n"
           "    getProtocolEntry,\t    -- :: IO ProtocolEntry\n"
           "    endProtocolEntry,\t    -- :: IO ()\n"
           "    getProtocolEntries,\t    -- :: Bool -> IO [ProtocolEntry]\n"
           "", stdout);
#line 70 "BSD.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (71, "BSD.hsc");
    fputs ("\n"
           "    -- * Port numbers\n"
           "    PortNumber,\n"
           "\n"
           "    -- * Network names\n"
           "    NetworkName,\n"
           "    NetworkAddr,\n"
           "    NetworkEntry(..)\n"
           "\n"
           "", stdout);
#line 80 "BSD.hsc"
#if !defined(cygwin32_TARGET_OS) && !defined(mingw32_TARGET_OS) && !defined(_WIN32)
    fputs ("\n"
           "", stdout);
    hsc_line (81, "BSD.hsc");
    fputs ("    , getNetworkByName\t    -- :: NetworkName -> IO NetworkEntry\n"
           "    , getNetworkByAddr      -- :: NetworkAddr -> Family -> IO NetworkEntry\n"
           "    , setNetworkEntry\t    -- :: Bool -> IO ()\n"
           "    , getNetworkEntry\t    -- :: IO NetworkEntry\n"
           "    , endNetworkEntry\t    -- :: IO ()\n"
           "    , getNetworkEntries     -- :: Bool -> IO [NetworkEntry]\n"
           "", stdout);
#line 87 "BSD.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (88, "BSD.hsc");
    fputs ("\n"
           "", stdout);
#line 89 "BSD.hsc"
#ifdef HAVE_SYMLINK
    fputs ("\n"
           "", stdout);
    hsc_line (90, "BSD.hsc");
    fputs ("    -- * Symbolic links\n"
           "    , symlink\t\t    -- :: String -> String -> IO ()\n"
           "", stdout);
#line 92 "BSD.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (93, "BSD.hsc");
    fputs ("", stdout);
#line 93 "BSD.hsc"
#ifdef HAVE_READLINK
    fputs ("\n"
           "", stdout);
    hsc_line (94, "BSD.hsc");
    fputs ("    , readlink\t\t    -- :: String -> IO String\n"
           "", stdout);
#line 95 "BSD.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (96, "BSD.hsc");
    fputs ("\n"
           "    ) where\n"
           "\n"
           "", stdout);
#line 99 "BSD.hsc"
#ifdef __HUGS__
    fputs ("\n"
           "", stdout);
    hsc_line (100, "BSD.hsc");
    fputs ("import Hugs.Prelude\n"
           "", stdout);
#line 101 "BSD.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (102, "BSD.hsc");
    fputs ("import Network.Socket\n"
           "\n"
           "import Foreign.C.Error ( throwErrnoIfMinus1, throwErrnoIfMinus1_ )\n"
           "import Foreign.C.String ( CString, peekCString, peekCStringLen, withCString )\n"
           "import Foreign.C.Types ( CInt, CULong, CChar, CSize, CShort )\n"
           "import Foreign.Ptr ( Ptr, nullPtr )\n"
           "import Foreign.Storable ( Storable(..) )\n"
           "import Foreign.Marshal.Array ( allocaArray0, peekArray0 )\n"
           "import Foreign.Marshal.Utils ( with, fromBool )\n"
           "\n"
           "", stdout);
#line 112 "BSD.hsc"
#ifdef __GLASGOW_HASKELL__
    fputs ("\n"
           "", stdout);
    hsc_line (113, "BSD.hsc");
    fputs ("import GHC.IOBase\n"
           "", stdout);
#line 114 "BSD.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (115, "BSD.hsc");
    fputs ("\n"
           "import Control.Monad ( liftM )\n"
           "\n"
           "-- ---------------------------------------------------------------------------\n"
           "-- Basic Types\n"
           "\n"
           "type HostName     = String\n"
           "type ProtocolName = String\n"
           "type ServiceName  = String\n"
           "\n"
           "-- ---------------------------------------------------------------------------\n"
           "-- Service Database Access\n"
           "\n"
           "-- Calling getServiceByName for a given service and protocol returns\n"
           "-- the systems service entry.  This should be used to find the port\n"
           "-- numbers for standard protocols such as SMTP and FTP.  The remaining\n"
           "-- three functions should be used for browsing the service database\n"
           "-- sequentially.\n"
           "\n"
           "-- Calling setServiceEntry with True indicates that the service\n"
           "-- database should be left open between calls to getServiceEntry.  To\n"
           "-- close the database a call to endServiceEntry is required.  This\n"
           "-- database file is usually stored in the file /etc/services.\n"
           "\n"
           "data ServiceEntry  = \n"
           "  ServiceEntry  {\n"
           "     serviceName     :: ServiceName,\t-- Official Name\n"
           "     serviceAliases  :: [ServiceName],\t-- aliases\n"
           "     servicePort     :: PortNumber,\t-- Port Number  ( network byte order )\n"
           "     serviceProtocol :: ProtocolName\t-- Protocol\n"
           "  } deriving (Show)\n"
           "\n"
           "instance Storable ServiceEntry where\n"
           "   sizeOf    _ = ", stdout);
#line 148 "BSD.hsc"
    hsc_const (sizeof(struct servent));
    fputs ("\n"
           "", stdout);
    hsc_line (149, "BSD.hsc");
    fputs ("   alignment _ = alignment (undefined :: CInt) -- \?\?\?\n"
           "\n"
           "   peek p = do\n"
           "\ts_name    <- (", stdout);
#line 152 "BSD.hsc"
    hsc_peek (struct servent, s_name);
    fputs (") p >>= peekCString\n"
           "", stdout);
    hsc_line (153, "BSD.hsc");
    fputs ("\ts_aliases <- (", stdout);
#line 153 "BSD.hsc"
    hsc_peek (struct servent, s_aliases);
    fputs (") p\n"
           "", stdout);
    hsc_line (154, "BSD.hsc");
    fputs ("\t\t\t   >>= peekArray0 nullPtr\n"
           "\t\t\t   >>= mapM peekCString\n"
           "\ts_port    <- (", stdout);
#line 156 "BSD.hsc"
    hsc_peek (struct servent, s_port);
    fputs (") p\n"
           "", stdout);
    hsc_line (157, "BSD.hsc");
    fputs ("\ts_proto   <- (", stdout);
#line 157 "BSD.hsc"
    hsc_peek (struct servent, s_proto);
    fputs (") p >>= peekCString\n"
           "", stdout);
    hsc_line (158, "BSD.hsc");
    fputs ("\treturn (ServiceEntry {\n"
           "\t\t\tserviceName     = s_name,\n"
           "\t\t\tserviceAliases  = s_aliases,\n"
           "", stdout);
#line 161 "BSD.hsc"
#if defined(HAVE_WINSOCK_H) && !defined(cygwin32_TARGET_OS)
    fputs ("\n"
           "", stdout);
    hsc_line (162, "BSD.hsc");
    fputs ("\t\t\tservicePort     = PortNum (fromIntegral (s_port :: CShort)),\n"
           "", stdout);
#line 163 "BSD.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (164, "BSD.hsc");
    fputs ("\t\t\t   -- s_port is already in network byte order, but it\n"
           "\t\t\t   -- might be the wrong size.\n"
           "\t\t\tservicePort     = PortNum (fromIntegral (s_port :: CInt)),\n"
           "", stdout);
#line 167 "BSD.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (168, "BSD.hsc");
    fputs ("\t\t\tserviceProtocol = s_proto\n"
           "\t\t})\n"
           "\n"
           "   poke p = error \"Storable.poke(BSD.ServiceEntry) not implemented\"\n"
           "\n"
           "\n"
           "getServiceByName :: ServiceName \t-- Service Name\n"
           "\t\t -> ProtocolName \t-- Protocol Name\n"
           "\t\t -> IO ServiceEntry\t-- Service Entry\n"
           "getServiceByName name proto = do\n"
           " withCString name  $ \\ cstr_name  -> do\n"
           " withCString proto $ \\ cstr_proto -> do\n"
           " throwNoSuchThingIfNull \"getServiceByName\" \"no such service entry\"\n"
           "   $ (trySysCall (c_getservbyname cstr_name cstr_proto))\n"
           " >>= peek\n"
           "\n"
           "foreign import ccall unsafe \"getservbyname\" \n"
           "  c_getservbyname :: CString -> CString -> IO (Ptr ServiceEntry)\n"
           "\n"
           "getServiceByPort :: PortNumber -> ProtocolName -> IO ServiceEntry\n"
           "getServiceByPort (PortNum port) proto = do\n"
           " withCString proto $ \\ cstr_proto -> do\n"
           " throwNoSuchThingIfNull \"getServiceByPort\" \"no such service entry\"\n"
           "   $ (trySysCall (c_getservbyport (fromIntegral port) cstr_proto))\n"
           " >>= peek\n"
           "\n"
           "foreign import ccall unsafe \"getservbyport\" \n"
           "  c_getservbyport :: CInt -> CString -> IO (Ptr ServiceEntry)\n"
           "\n"
           "getServicePortNumber :: ServiceName -> IO PortNumber\n"
           "getServicePortNumber name = do\n"
           "    (ServiceEntry _ _ port _) <- getServiceByName name \"tcp\"\n"
           "    return port\n"
           "\n"
           "", stdout);
#line 202 "BSD.hsc"
#if !defined(cygwin32_TARGET_OS) && !defined(mingw32_TARGET_OS) && !defined(_WIN32)
    fputs ("\n"
           "", stdout);
    hsc_line (203, "BSD.hsc");
    fputs ("getServiceEntry\t:: IO ServiceEntry\n"
           "getServiceEntry = do\n"
           " throwNoSuchThingIfNull \"getServiceEntry\" \"no such service entry\"\n"
           "   $ trySysCall c_getservent\n"
           " >>= peek\n"
           "\n"
           "foreign import ccall unsafe \"getservent\" c_getservent :: IO (Ptr ServiceEntry)\n"
           "\n"
           "setServiceEntry\t:: Bool -> IO ()\n"
           "setServiceEntry flg = trySysCall $ c_setservent (fromBool flg)\n"
           "\n"
           "foreign import ccall unsafe  \"setservent\" c_setservent :: CInt -> IO ()\n"
           "\n"
           "endServiceEntry\t:: IO ()\n"
           "endServiceEntry = trySysCall $ c_endservent\n"
           "\n"
           "foreign import ccall unsafe  \"endservent\" c_endservent :: IO ()\n"
           "\n"
           "getServiceEntries :: Bool -> IO [ServiceEntry]\n"
           "getServiceEntries stayOpen = do\n"
           "  setServiceEntry stayOpen\n"
           "  getEntries (getServiceEntry) (endServiceEntry)\n"
           "", stdout);
#line 225 "BSD.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (226, "BSD.hsc");
    fputs ("\n"
           "-- ---------------------------------------------------------------------------\n"
           "-- Protocol Entries\n"
           "\n"
           "-- The following relate directly to the corresponding UNIX C\n"
           "-- calls for returning the protocol entries. The protocol entry is\n"
           "-- represented by the Haskell type ProtocolEntry.\n"
           "\n"
           "-- As for setServiceEntry above, calling setProtocolEntry.\n"
           "-- determines whether or not the protocol database file, usually\n"
           "-- @/etc/protocols@, is to be kept open between calls of\n"
           "-- getProtocolEntry. Similarly, \n"
           "\n"
           "data ProtocolEntry = \n"
           "  ProtocolEntry  {\n"
           "     protoName    :: ProtocolName,\t-- Official Name\n"
           "     protoAliases :: [ProtocolName],\t-- aliases\n"
           "     protoNumber  :: ProtocolNumber\t-- Protocol Number\n"
           "  } deriving (Read, Show)\n"
           "\n"
           "instance Storable ProtocolEntry where\n"
           "   sizeOf    _ = ", stdout);
#line 247 "BSD.hsc"
    hsc_const (sizeof(struct protoent));
    fputs ("\n"
           "", stdout);
    hsc_line (248, "BSD.hsc");
    fputs ("   alignment _ = alignment (undefined :: CInt) -- \?\?\?\n"
           "\n"
           "   peek p = do\n"
           "\tp_name    <- (", stdout);
#line 251 "BSD.hsc"
    hsc_peek (struct protoent, p_name);
    fputs (") p >>= peekCString\n"
           "", stdout);
    hsc_line (252, "BSD.hsc");
    fputs ("\tp_aliases <- (", stdout);
#line 252 "BSD.hsc"
    hsc_peek (struct protoent, p_aliases);
    fputs (") p\n"
           "", stdout);
    hsc_line (253, "BSD.hsc");
    fputs ("\t\t\t   >>= peekArray0 nullPtr\n"
           "\t\t\t   >>= mapM peekCString\n"
           "", stdout);
#line 255 "BSD.hsc"
#if defined(HAVE_WINSOCK_H) && !defined(cygwin32_TARGET_OS)
    fputs ("\n"
           "", stdout);
    hsc_line (256, "BSD.hsc");
    fputs ("         -- With WinSock, the protocol number is only a short;\n"
           "\t -- hoist it in as such, but represent it on the Haskell side\n"
           "\t -- as a CInt.\n"
           "\tp_proto_short  <- (", stdout);
#line 259 "BSD.hsc"
    hsc_peek (struct protoent, p_proto);
    fputs (") p \n"
           "", stdout);
    hsc_line (260, "BSD.hsc");
    fputs ("\tlet p_proto = fromIntegral (p_proto_short :: CShort)\n"
           "", stdout);
#line 261 "BSD.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (262, "BSD.hsc");
    fputs ("\tp_proto        <- (", stdout);
#line 262 "BSD.hsc"
    hsc_peek (struct protoent, p_proto);
    fputs (") p \n"
           "", stdout);
    hsc_line (263, "BSD.hsc");
    fputs ("", stdout);
#line 263 "BSD.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (264, "BSD.hsc");
    fputs ("\treturn (ProtocolEntry { \n"
           "\t\t\tprotoName    = p_name,\n"
           "\t\t\tprotoAliases = p_aliases,\n"
           "\t\t\tprotoNumber  = p_proto\n"
           "\t\t})\n"
           "\n"
           "   poke p = error \"Storable.poke(BSD.ProtocolEntry) not implemented\"\n"
           "\n"
           "getProtocolByName :: ProtocolName -> IO ProtocolEntry\n"
           "getProtocolByName name = do\n"
           " withCString name $ \\ name_cstr -> do\n"
           " throwNoSuchThingIfNull \"getServiceEntry\" \"no such service entry\"\n"
           "   $ (trySysCall.c_getprotobyname) name_cstr\n"
           " >>= peek\n"
           "\n"
           "foreign import  ccall unsafe  \"getprotobyname\" \n"
           "   c_getprotobyname :: CString -> IO (Ptr ProtocolEntry)\n"
           "\n"
           "\n"
           "getProtocolByNumber :: ProtocolNumber -> IO ProtocolEntry\n"
           "getProtocolByNumber num = do\n"
           " throwNoSuchThingIfNull \"getServiceEntry\" \"no such service entry\"\n"
           "   $ (trySysCall.c_getprotobynumber) (fromIntegral num)\n"
           " >>= peek\n"
           "\n"
           "foreign import ccall unsafe  \"getprotobynumber\"\n"
           "   c_getprotobynumber :: CInt -> IO (Ptr ProtocolEntry)\n"
           "\n"
           "\n"
           "getProtocolNumber :: ProtocolName -> IO ProtocolNumber\n"
           "getProtocolNumber proto = do\n"
           " (ProtocolEntry _ _ num) <- getProtocolByName proto\n"
           " return num\n"
           "\n"
           "", stdout);
#line 298 "BSD.hsc"
#if !defined(cygwin32_TARGET_OS) && !defined(mingw32_TARGET_OS) && !defined(_WIN32)
    fputs ("\n"
           "", stdout);
    hsc_line (299, "BSD.hsc");
    fputs ("getProtocolEntry :: IO ProtocolEntry\t-- Next Protocol Entry from DB\n"
           "getProtocolEntry = do\n"
           " ent <- throwNoSuchThingIfNull \"getProtocolEntry\" \"no such protocol entry\"\n"
           "   \t\t$ trySysCall c_getprotoent\n"
           " peek ent\n"
           "\n"
           "foreign import ccall unsafe  \"getprotoent\" c_getprotoent :: IO (Ptr ProtocolEntry)\n"
           "\n"
           "setProtocolEntry :: Bool -> IO ()\t-- Keep DB Open \?\n"
           "setProtocolEntry flg = trySysCall $ c_setprotoent (fromBool flg)\n"
           "\n"
           "foreign import ccall unsafe \"setprotoent\" c_setprotoent :: CInt -> IO ()\n"
           "\n"
           "endProtocolEntry :: IO ()\n"
           "endProtocolEntry = trySysCall $ c_endprotoent\n"
           "\n"
           "foreign import ccall unsafe \"endprotoent\" c_endprotoent :: IO ()\n"
           "\n"
           "getProtocolEntries :: Bool -> IO [ProtocolEntry]\n"
           "getProtocolEntries stayOpen = do\n"
           "  setProtocolEntry stayOpen\n"
           "  getEntries (getProtocolEntry) (endProtocolEntry)\n"
           "", stdout);
#line 321 "BSD.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (322, "BSD.hsc");
    fputs ("\n"
           "-- ---------------------------------------------------------------------------\n"
           "-- Host lookups\n"
           "\n"
           "data HostEntry = \n"
           "  HostEntry  {\n"
           "     hostName      :: HostName,  \t-- Official Name\n"
           "     hostAliases   :: [HostName],\t-- aliases\n"
           "     hostFamily    :: Family,\t        -- Host Type (currently AF_INET)\n"
           "     hostAddresses :: [HostAddress]\t-- Set of Network Addresses  (in network byte order)\n"
           "  } deriving (Read, Show)\n"
           "\n"
           "instance Storable HostEntry where\n"
           "   sizeOf    _ = ", stdout);
#line 335 "BSD.hsc"
    hsc_const (sizeof(struct hostent));
    fputs ("\n"
           "", stdout);
    hsc_line (336, "BSD.hsc");
    fputs ("   alignment _ = alignment (undefined :: CInt) -- \?\?\?\n"
           "\n"
           "   peek p = do\n"
           "\th_name       <- (", stdout);
#line 339 "BSD.hsc"
    hsc_peek (struct hostent, h_name);
    fputs (") p >>= peekCString\n"
           "", stdout);
    hsc_line (340, "BSD.hsc");
    fputs ("\th_aliases    <- (", stdout);
#line 340 "BSD.hsc"
    hsc_peek (struct hostent, h_aliases);
    fputs (") p\n"
           "", stdout);
    hsc_line (341, "BSD.hsc");
    fputs ("\t\t\t\t>>= peekArray0 nullPtr\n"
           "\t\t\t\t>>= mapM peekCString\n"
           "\th_addrtype   <- (", stdout);
#line 343 "BSD.hsc"
    hsc_peek (struct hostent, h_addrtype);
    fputs (") p\n"
           "", stdout);
    hsc_line (344, "BSD.hsc");
    fputs ("\t-- h_length       <- (#peek struct hostent, h_length) p\n"
           "\th_addr_list  <- (", stdout);
#line 345 "BSD.hsc"
    hsc_peek (struct hostent, h_addr_list);
    fputs (") p\n"
           "", stdout);
    hsc_line (346, "BSD.hsc");
    fputs ("\t\t\t\t>>= peekArray0 nullPtr\n"
           "\t\t\t\t>>= mapM peek\n"
           "\treturn (HostEntry {\n"
           "\t\t\thostName       = h_name,\n"
           "\t\t\thostAliases    = h_aliases,\n"
           "\t\t\thostFamily     = unpackFamily h_addrtype,\n"
           "\t\t\thostAddresses  = h_addr_list\n"
           "\t\t})\n"
           "\n"
           "   poke p = error \"Storable.poke(BSD.ServiceEntry) not implemented\"\n"
           "\n"
           "\n"
           "-- convenience function:\n"
           "hostAddress :: HostEntry -> HostAddress\n"
           "hostAddress (HostEntry nm _ _ ls) =\n"
           " case ls of\n"
           "   []    -> error (\"BSD.hostAddress: empty network address list for \" ++ nm)\n"
           "   (x:_) -> x\n"
           "\n"
           "getHostByName :: HostName -> IO HostEntry\n"
           "getHostByName name = do\n"
           "  withCString name $ \\ name_cstr -> do\n"
           "   ent <- throwNoSuchThingIfNull \"getHostByName\" \"no such host entry\"\n"
           "    \t\t$ trySysCall $ c_gethostbyname name_cstr\n"
           "   peek ent\n"
           "\n"
           "foreign import ccall unsafe \"gethostbyname\" \n"
           "   c_gethostbyname :: CString -> IO (Ptr HostEntry)\n"
           "\n"
           "getHostByAddr :: Family -> HostAddress -> IO HostEntry\n"
           "getHostByAddr family addr = do\n"
           " with addr $ \\ ptr_addr -> do\n"
           " throwNoSuchThingIfNull \t\"getHostByAddr\" \"no such host entry\"\n"
           "   $ trySysCall $ c_gethostbyaddr ptr_addr (fromIntegral (sizeOf addr)) (packFamily family)\n"
           " >>= peek\n"
           "\n"
           "foreign import ccall unsafe \"gethostbyaddr\"\n"
           "   c_gethostbyaddr :: Ptr HostAddress -> CInt -> CInt -> IO (Ptr HostEntry)\n"
           "\n"
           "", stdout);
#line 385 "BSD.hsc"
#if !defined(cygwin32_TARGET_OS) && !defined(mingw32_TARGET_OS) && !defined(_WIN32)
    fputs ("\n"
           "", stdout);
    hsc_line (386, "BSD.hsc");
    fputs ("getHostEntry :: IO HostEntry\n"
           "getHostEntry = do\n"
           " throwNoSuchThingIfNull \t\"getHostEntry\" \"unable to retrieve host entry\"\n"
           "   $ trySysCall $ c_gethostent\n"
           " >>= peek\n"
           "\n"
           "foreign import ccall unsafe \"gethostent\" c_gethostent :: IO (Ptr HostEntry)\n"
           "\n"
           "setHostEntry :: Bool -> IO ()\n"
           "setHostEntry flg = trySysCall $ c_sethostent (fromBool flg)\n"
           "\n"
           "foreign import ccall unsafe \"sethostent\" c_sethostent :: CInt -> IO ()\n"
           "\n"
           "endHostEntry :: IO ()\n"
           "endHostEntry = c_endhostent\n"
           "\n"
           "foreign import ccall unsafe \"endhostent\" c_endhostent :: IO ()\n"
           "\n"
           "getHostEntries :: Bool -> IO [HostEntry]\n"
           "getHostEntries stayOpen = do\n"
           "  setHostEntry stayOpen\n"
           "  getEntries (getHostEntry) (endHostEntry)\n"
           "", stdout);
#line 408 "BSD.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (409, "BSD.hsc");
    fputs ("\n"
           "-- ---------------------------------------------------------------------------\n"
           "-- Accessing network information\n"
           "\n"
           "-- Same set of access functions as for accessing host,protocol and\n"
           "-- service system info, this time for the types of networks supported.\n"
           "\n"
           "-- network addresses are represented in host byte order.\n"
           "type NetworkAddr = CULong\n"
           "\n"
           "type NetworkName = String\n"
           "\n"
           "data NetworkEntry =\n"
           "  NetworkEntry {\n"
           "     networkName\t:: NetworkName,   -- official name\n"
           "     networkAliases\t:: [NetworkName], -- aliases\n"
           "     networkFamily\t:: Family,\t   -- type\n"
           "     networkAddress\t:: NetworkAddr\n"
           "   } deriving (Read, Show)\n"
           "\n"
           "instance Storable NetworkEntry where\n"
           "   sizeOf    _ = ", stdout);
#line 430 "BSD.hsc"
    hsc_const (sizeof(struct hostent));
    fputs ("\n"
           "", stdout);
    hsc_line (431, "BSD.hsc");
    fputs ("   alignment _ = alignment (undefined :: CInt) -- \?\?\?\n"
           "\n"
           "   peek p = do\n"
           "\tn_name         <- (", stdout);
#line 434 "BSD.hsc"
    hsc_peek (struct netent, n_name);
    fputs (") p >>= peekCString\n"
           "", stdout);
    hsc_line (435, "BSD.hsc");
    fputs ("\tn_aliases      <- (", stdout);
#line 435 "BSD.hsc"
    hsc_peek (struct netent, n_aliases);
    fputs (") p\n"
           "", stdout);
    hsc_line (436, "BSD.hsc");
    fputs ("\t\t\t \t>>= peekArray0 nullPtr\n"
           "\t\t\t   \t>>= mapM peekCString\n"
           "\tn_addrtype     <- (", stdout);
#line 438 "BSD.hsc"
    hsc_peek (struct netent, n_addrtype);
    fputs (") p\n"
           "", stdout);
    hsc_line (439, "BSD.hsc");
    fputs ("\tn_net          <- (", stdout);
#line 439 "BSD.hsc"
    hsc_peek (struct netent, n_net);
    fputs (") p\n"
           "", stdout);
    hsc_line (440, "BSD.hsc");
    fputs ("\treturn (NetworkEntry {\n"
           "\t\t\tnetworkName      = n_name,\n"
           "\t\t\tnetworkAliases   = n_aliases,\n"
           "\t\t\tnetworkFamily    = unpackFamily (fromIntegral \n"
           "\t\t\t\t\t    (n_addrtype :: CInt)),\n"
           "\t\t\tnetworkAddress   = n_net\n"
           "\t\t})\n"
           "\n"
           "   poke p = error \"Storable.poke(BSD.NetEntry) not implemented\"\n"
           "\n"
           "\n"
           "", stdout);
#line 451 "BSD.hsc"
#if !defined(cygwin32_TARGET_OS) && !defined(mingw32_TARGET_OS) && !defined(_WIN32)
    fputs ("\n"
           "", stdout);
    hsc_line (452, "BSD.hsc");
    fputs ("getNetworkByName :: NetworkName -> IO NetworkEntry\n"
           "getNetworkByName name = do\n"
           " withCString name $ \\ name_cstr -> do\n"
           "  throwNoSuchThingIfNull \"getNetworkByName\" \"no such network entry\"\n"
           "    $ trySysCall $ c_getnetbyname name_cstr\n"
           "  >>= peek\n"
           "\n"
           "foreign import ccall unsafe \"getnetbyname\" \n"
           "   c_getnetbyname  :: CString -> IO (Ptr NetworkEntry)\n"
           "\n"
           "getNetworkByAddr :: NetworkAddr -> Family -> IO NetworkEntry\n"
           "getNetworkByAddr addr family = do\n"
           " throwNoSuchThingIfNull \"getNetworkByAddr\" \"no such network entry\"\n"
           "   $ trySysCall $ c_getnetbyaddr addr (packFamily family)\n"
           " >>= peek\n"
           "\n"
           "foreign import ccall unsafe \"getnetbyaddr\" \n"
           "   c_getnetbyaddr  :: NetworkAddr -> CInt -> IO (Ptr NetworkEntry)\n"
           "\n"
           "getNetworkEntry :: IO NetworkEntry\n"
           "getNetworkEntry = do\n"
           " throwNoSuchThingIfNull \"getNetworkEntry\" \"no more network entries\"\n"
           "          $ trySysCall $ c_getnetent\n"
           " >>= peek\n"
           "\n"
           "foreign import ccall unsafe \"getnetent\" c_getnetent :: IO (Ptr NetworkEntry)\n"
           "\n"
           "setNetworkEntry :: Bool -> IO ()\n"
           "setNetworkEntry flg = trySysCall $ c_setnetent (fromBool flg)\n"
           "\n"
           "foreign import ccall unsafe \"setnetent\" c_setnetent :: CInt -> IO ()\n"
           "\n"
           "endNetworkEntry :: IO ()\n"
           "endNetworkEntry = trySysCall $ c_endnetent\n"
           "\n"
           "foreign import ccall unsafe \"endnetent\" c_endnetent :: IO ()\n"
           "\n"
           "getNetworkEntries :: Bool -> IO [NetworkEntry]\n"
           "getNetworkEntries stayOpen = do\n"
           "  setNetworkEntry stayOpen\n"
           "  getEntries (getNetworkEntry) (endNetworkEntry)\n"
           "", stdout);
#line 493 "BSD.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (494, "BSD.hsc");
    fputs ("\n"
           "-- ---------------------------------------------------------------------------\n"
           "-- Miscellaneous Functions\n"
           "\n"
           "-- Calling getHostName returns the standard host name for the current\n"
           "-- processor, as set at boot time.\n"
           "\n"
           "getHostName :: IO HostName\n"
           "getHostName = do\n"
           "  let size = 256\n"
           "  allocaArray0 size $ \\ cstr -> do\n"
           "    throwSocketErrorIfMinus1_ \"getHostName\" $ c_gethostname cstr (fromIntegral size)\n"
           "    peekCString cstr\n"
           "\n"
           "foreign import ccall unsafe \"gethostname\" \n"
           "   c_gethostname :: CString -> CSize -> IO CInt\n"
           "\n"
           "-- Helper function used by the exported functions that provides a\n"
           "-- Haskellised view of the enumerator functions:\n"
           "\n"
           "getEntries :: IO a  -- read\n"
           "           -> IO () -- at end\n"
           "\t   -> IO [a]\n"
           "getEntries getOne atEnd = loop\n"
           "  where\n"
           "    loop = do\n"
           "      vv <- catch (liftM Just getOne) ((const.return) Nothing)\n"
           "      case vv of\n"
           "        Nothing -> return []\n"
           "        Just v  -> loop >>= \\ vs -> atEnd >> return (v:vs)\n"
           "\n"
           "\n"
           "-- ---------------------------------------------------------------------------\n"
           "-- Symbolic links\n"
           "\n"
           "", stdout);
#line 529 "BSD.hsc"
#ifdef HAVE_SYMLINK
    fputs ("\n"
           "", stdout);
    hsc_line (530, "BSD.hsc");
    fputs ("{-# DEPRECATED symlink \"use System.Posix.createSymbolicLink\" #-}\n"
           "symlink :: String -> String -> IO ()\n"
           "symlink actual_path sym_path = do\n"
           "   withCString actual_path $ \\ actual_path_cstr -> do\n"
           "   withCString sym_path $ \\ sym_path_cstr -> do\n"
           "   throwErrnoIfMinus1_ \"symlink\" $ c_symlink actual_path_cstr sym_path_cstr\n"
           "\n"
           "foreign import ccall unsafe \"symlink\" \n"
           "   c_symlink :: CString -> CString -> IO CInt\n"
           "", stdout);
#line 539 "BSD.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (540, "BSD.hsc");
    fputs ("\n"
           "", stdout);
#line 541 "BSD.hsc"
#ifdef HAVE_READLINK
    fputs ("\n"
           "", stdout);
    hsc_line (542, "BSD.hsc");
    fputs ("{-# DEPRECATED readlink \"use System.Posix.readSymbolicLink\" #-}\n"
           "readlink :: String -> IO String\n"
           "readlink sym = do\n"
           "   withCString sym $ \\ sym_cstr -> do\n"
           "   allocaArray0 (", stdout);
#line 546 "BSD.hsc"
    hsc_const (PATH_MAX);
    fputs (") $ \\ buf -> do\n"
           "", stdout);
    hsc_line (547, "BSD.hsc");
    fputs ("   rc <- throwErrnoIfMinus1 \"readlink\" $ \n"
           "\t    c_readlink sym_cstr buf (", stdout);
#line 548 "BSD.hsc"
    hsc_const (PATH_MAX);
    fputs (")\n"
           "", stdout);
    hsc_line (549, "BSD.hsc");
    fputs ("   peekCStringLen (buf, fromIntegral rc)\n"
           "\n"
           "foreign import ccall unsafe \"readlink\"\n"
           "   c_readlink :: CString -> Ptr CChar -> CSize -> IO CInt\n"
           "", stdout);
#line 553 "BSD.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (554, "BSD.hsc");
    fputs ("\n"
           "-- ---------------------------------------------------------------------------\n"
           "-- Winsock only:\n"
           "--   The BSD API networking calls made locally return NULL upon failure.\n"
           "--   That failure may very well be due to WinSock not being initialised,\n"
           "--   so if NULL is seen try init\'ing and repeat the call.\n"
           "", stdout);
#line 560 "BSD.hsc"
#if !defined(mingw32_TARGET_OS) && !defined(_WIN32)
    fputs ("\n"
           "", stdout);
    hsc_line (561, "BSD.hsc");
    fputs ("trySysCall act = act\n"
           "", stdout);
#line 562 "BSD.hsc"
#else 
    fputs ("\n"
           "", stdout);
    hsc_line (563, "BSD.hsc");
    fputs ("trySysCall act = do\n"
           "  ptr <- act\n"
           "  if (ptr == nullPtr)\n"
           "   then withSocketsDo act\n"
           "   else return ptr\n"
           "", stdout);
#line 568 "BSD.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (569, "BSD.hsc");
    fputs ("\n"
           "throwNoSuchThingIfNull :: String -> String -> IO (Ptr a) -> IO (Ptr a)\n"
           "throwNoSuchThingIfNull loc desc act = do\n"
           "  ptr <- act\n"
           "  if (ptr == nullPtr)\n"
           "   then ioError (IOError Nothing NoSuchThing\n"
           "\tloc desc Nothing)\n"
           "   else return ptr\n"
           "", stdout);
    return 0;
}
