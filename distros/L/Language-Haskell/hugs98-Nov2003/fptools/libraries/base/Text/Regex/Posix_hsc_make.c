#include "template-hsc.h"
#line 16 "Posix.hsc"
#include "config.h"
#line 22 "Posix.hsc"
#if !defined(__HUGS__) || defined(HAVE_REGEX_H)
#line 39 "Posix.hsc"
#endif 
#line 42 "Posix.hsc"
#if !defined(__HUGS__) || defined(HAVE_REGEX_H)
#line 43 "Posix.hsc"
#include <sys/types.h>
#line 44 "Posix.hsc"
#include "regex.h"
#line 45 "Posix.hsc"
#endif 
#line 57 "Posix.hsc"
#if !defined(__HUGS__) || defined(HAVE_REGEX_H)
#line 178 "Posix.hsc"
#endif /* HAVE_REGEX_H */

int main (int argc, char *argv [])
{
#if __GLASGOW_HASKELL__ && __GLASGOW_HASKELL__ < 409
    printf ("{-# OPTIONS -optc-D__GLASGOW_HASKELL__=%d #-}\n", 603);
#endif
    printf ("{-# OPTIONS %s #-}\n", "-#include \"config.h\"");
#line 22 "Posix.hsc"
#if !defined(__HUGS__) || defined(HAVE_REGEX_H)
#line 39 "Posix.hsc"
#endif 
#line 42 "Posix.hsc"
#if !defined(__HUGS__) || defined(HAVE_REGEX_H)
    printf ("{-# OPTIONS %s #-}\n", "-#include <sys/types.h>");
    printf ("{-# OPTIONS %s #-}\n", "-#include \"regex.h\"");
#line 45 "Posix.hsc"
#endif 
#line 57 "Posix.hsc"
#if !defined(__HUGS__) || defined(HAVE_REGEX_H)
#line 178 "Posix.hsc"
#endif /* HAVE_REGEX_H */
    hsc_line (1, "Posix.hsc");
    fputs ("-----------------------------------------------------------------------------\n"
           "", stdout);
    hsc_line (2, "Posix.hsc");
    fputs ("-- |\n"
           "-- Module      :  Text.Regex.Posix\n"
           "-- Copyright   :  (c) The University of Glasgow 2002\n"
           "-- License     :  BSD-style (see the file libraries/base/LICENSE)\n"
           "-- \n"
           "-- Maintainer  :  libraries@haskell.org\n"
           "-- Stability   :  experimental\n"
           "-- Portability :  non-portable (needs POSIX regexps)\n"
           "--\n"
           "-- Interface to the POSIX regular expression library.\n"
           "--\n"
           "-----------------------------------------------------------------------------\n"
           "\n"
           "-- ToDo: should have an interface using PackedStrings.\n"
           "", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (17, "Posix.hsc");
    fputs ("\n"
           "module Text.Regex.Posix (\n"
           "\t-- * The @Regex@ type\n"
           "\tRegex,\t \t-- abstract\n"
           "\n"
           "", stdout);
#line 22 "Posix.hsc"
#if !defined(__HUGS__) || defined(HAVE_REGEX_H)
    fputs ("\n"
           "", stdout);
    hsc_line (23, "Posix.hsc");
    fputs ("\t-- * Compiling a regular expression\n"
           "\tregcomp, \t-- :: String -> Int -> IO Regex\n"
           "\n"
           "\t-- ** Flags for regcomp\n"
           "\tregExtended,\t-- (flag to regcomp) use extended regex syntax\n"
           "\tregIgnoreCase,\t-- (flag to regcomp) ignore case when matching\n"
           "\tregNewline,\t-- (flag to regcomp) \'.\' doesn\'t match newline\n"
           "\n"
           "\t-- * Matching a regular expression\n"
           "\tregexec, \t-- :: Regex\t\t     -- pattern\n"
           "\t         \t-- -> String\t\t     -- string to match\n"
           "\t         \t-- -> IO (Maybe (String,     -- everything before match\n"
           "\t         \t-- \t \t String,     -- matched portion\n"
           "\t         \t--\t\t String,     -- everything after match\n"
           "\t         \t-- \t \t [String]))  -- subexpression matches\n"
           "\n"
           "", stdout);
#line 39 "Posix.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (40, "Posix.hsc");
    fputs ("  ) where\n"
           "\n"
           "", stdout);
#line 42 "Posix.hsc"
#if !defined(__HUGS__) || defined(HAVE_REGEX_H)
    fputs ("\n"
           "", stdout);
    hsc_line (43, "Posix.hsc");
    fputs ("", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (44, "Posix.hsc");
    fputs ("", stdout);
    fputs ("\n"
           "", stdout);
    hsc_line (45, "Posix.hsc");
    fputs ("", stdout);
#line 45 "Posix.hsc"
#endif 
    fputs ("\n"
           "", stdout);
    hsc_line (46, "Posix.hsc");
    fputs ("\n"
           "import Prelude\n"
           "\n"
           "import Foreign\n"
           "import Foreign.C\n"
           "\n"
           "type CRegex    = ()\n"
           "\n"
           "-- | A compiled regular expression\n"
           "newtype Regex = Regex (ForeignPtr CRegex)\n"
           "\n"
           "", stdout);
#line 57 "Posix.hsc"
#if !defined(__HUGS__) || defined(HAVE_REGEX_H)
    fputs ("\n"
           "", stdout);
    hsc_line (58, "Posix.hsc");
    fputs ("-- to the end\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- regcomp\n"
           "\n"
           "-- | Compiles a regular expression\n"
           "regcomp\n"
           "  :: String  \t-- ^ The regular expression to compile\n"
           "  -> Int    \t-- ^ Flags (summed together)\n"
           "  -> IO Regex  \t-- ^ Returns: the compiled regular expression\n"
           "regcomp pattern flags = do\n"
           "  regex_fptr <- mallocForeignPtrBytes (", stdout);
#line 68 "Posix.hsc"
    hsc_const (sizeof(regex_t));
    fputs (")\n"
           "", stdout);
    hsc_line (69, "Posix.hsc");
    fputs ("  r <- withCString pattern $ \\cstr ->\n"
           "    \t withForeignPtr regex_fptr $ \\p ->\n"
           "           c_regcomp p cstr (fromIntegral flags)\n"
           "  if (r == 0)\n"
           "     then do addForeignPtrFinalizer ptr_regfree regex_fptr\n"
           "\t     return (Regex regex_fptr)\n"
           "     else error \"Text.Regex.Posix.regcomp: error in pattern\" -- ToDo\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- regexec\n"
           "\n"
           "-- | Matches a regular expression against a string\n"
           "regexec :: Regex\t\t\t-- ^ Compiled regular expression\n"
           "\t-> String\t\t\t-- ^ String to match against\n"
           "\t-> IO (Maybe (String, String, String, [String]))\n"
           "\t \t-- ^ Returns: \'Nothing\' if the regex did not match the\n"
           "\t\t-- string, or:\n"
           "\t\t--\n"
           "\t\t-- @\n"
           "\t\t--   \'Just\' (everything before match,\n"
           "\t\t--         matched portion,\n"
           "\t\t--         everything after match,\n"
           "\t\t--         subexpression matches)\n"
           "\t\t-- @\n"
           "\n"
           "regexec (Regex regex_fptr) str = do\n"
           "  withCString str $ \\cstr -> do\n"
           "    withForeignPtr regex_fptr $ \\regex_ptr -> do\n"
           "      nsub <- (", stdout);
#line 97 "Posix.hsc"
    hsc_peek (regex_t, re_nsub);
    fputs (") regex_ptr\n"
           "", stdout);
    hsc_line (98, "Posix.hsc");
    fputs ("      let nsub_int = fromIntegral (nsub :: CSize)\n"
           "      allocaBytes ((1 + nsub_int) * (", stdout);
#line 99 "Posix.hsc"
    hsc_const (sizeof(regmatch_t));
    fputs (")) $ \\p_match -> do\n"
           "", stdout);
    hsc_line (100, "Posix.hsc");
    fputs ("\t\t-- add one because index zero covers the whole match\n"
           "        r <- c_regexec regex_ptr cstr (1 + nsub) p_match 0{-no flags for now-}\n"
           "\n"
           "        if (r /= 0) then return Nothing else do \n"
           "\n"
           "        (before,match,after) <- matched_parts str p_match\n"
           "\n"
           "        sub_strs <- \n"
           "\t  mapM (unpack str) $ take nsub_int $ tail $\n"
           "\t     iterate (`plusPtr` (", stdout);
#line 109 "Posix.hsc"
    hsc_const (sizeof(regmatch_t));
    fputs (")) p_match\n"
           "", stdout);
    hsc_line (110, "Posix.hsc");
    fputs ("\n"
           "        return (Just (before, match, after, sub_strs))\n"
           "\n"
           "matched_parts :: String -> Ptr CRegMatch -> IO (String, String, String)\n"
           "matched_parts string p_match = do\n"
           "  start <- (", stdout);
#line 115 "Posix.hsc"
    hsc_peek (regmatch_t, rm_so);
    fputs (") p_match :: IO (", stdout);
#line 115 "Posix.hsc"
    hsc_type (regoff_t);
    fputs (")\n"
           "", stdout);
    hsc_line (116, "Posix.hsc");
    fputs ("  end   <- (", stdout);
#line 116 "Posix.hsc"
    hsc_peek (regmatch_t, rm_eo);
    fputs (") p_match :: IO (", stdout);
#line 116 "Posix.hsc"
    hsc_type (regoff_t);
    fputs (")\n"
           "", stdout);
    hsc_line (117, "Posix.hsc");
    fputs ("  let s = fromIntegral start; e = fromIntegral end\n"
           "  return ( take s string, \n"
           "\t   take (e-s) (drop s string),\n"
           "\t   drop e string )  \n"
           "\n"
           "unpack :: String -> Ptr CRegMatch -> IO (String)\n"
           "unpack string p_match = do\n"
           "  start <- (", stdout);
#line 124 "Posix.hsc"
    hsc_peek (regmatch_t, rm_so);
    fputs (") p_match :: IO (", stdout);
#line 124 "Posix.hsc"
    hsc_type (regoff_t);
    fputs (")\n"
           "", stdout);
    hsc_line (125, "Posix.hsc");
    fputs ("  end   <- (", stdout);
#line 125 "Posix.hsc"
    hsc_peek (regmatch_t, rm_eo);
    fputs (") p_match :: IO (", stdout);
#line 125 "Posix.hsc"
    hsc_type (regoff_t);
    fputs (")\n"
           "", stdout);
    hsc_line (126, "Posix.hsc");
    fputs ("  -- the subexpression may not have matched at all, perhaps because it\n"
           "  -- was optional.  In this case, the offsets are set to -1.\n"
           "  if (start == -1) then return \"\" else do\n"
           "  return (take (fromIntegral (end-start)) (drop (fromIntegral start) string))\n"
           "\n"
           "-- -----------------------------------------------------------------------------\n"
           "-- The POSIX regex C interface\n"
           "\n"
           "-- Flags for regexec\n"
           "", stdout);
#line 135 "Posix.hsc"
    hsc_enum (Int, , hsc_haskellize ("REG_NOTBOL"), REG_NOTBOL);
    hsc_enum (Int, , hsc_haskellize ("REG_NOTEOL"), REG_NOTEOL);
    fputs ("\n"
           "", stdout);
    hsc_line (138, "Posix.hsc");
    fputs ("\n"
           "-- Return values from regexec\n"
           "", stdout);
#line 140 "Posix.hsc"
    hsc_enum (Int, , hsc_haskellize ("REG_NOMATCH"), REG_NOMATCH);
    fputs ("\n"
           "", stdout);
    hsc_line (142, "Posix.hsc");
    fputs ("--\tREG_ESPACE\n"
           "\n"
           "-- Flags for regcomp\n"
           "", stdout);
#line 145 "Posix.hsc"
    hsc_enum (Int, , hsc_haskellize ("REG_EXTENDED"), REG_EXTENDED);
    hsc_enum (Int, , printf ("%s", "regIgnoreCase "),  REG_ICASE);
    hsc_enum (Int, , hsc_haskellize ("REG_NOSUB"), REG_NOSUB);
    hsc_enum (Int, , hsc_haskellize ("REG_NEWLINE"), REG_NEWLINE);
    fputs ("\n"
           "", stdout);
    hsc_line (150, "Posix.hsc");
    fputs ("\n"
           "-- Error codes from regcomp\n"
           "", stdout);
#line 152 "Posix.hsc"
    hsc_enum (Int, , hsc_haskellize ("REG_BADBR"), REG_BADBR);
    hsc_enum (Int, , hsc_haskellize ("REG_BADPAT"), REG_BADPAT);
    hsc_enum (Int, , hsc_haskellize ("REG_BADRPT"), REG_BADRPT);
    hsc_enum (Int, , hsc_haskellize ("REG_ECOLLATE"), REG_ECOLLATE);
    hsc_enum (Int, , hsc_haskellize ("REG_ECTYPE"), REG_ECTYPE);
    hsc_enum (Int, , hsc_haskellize ("REG_EESCAPE"), REG_EESCAPE);
    hsc_enum (Int, , hsc_haskellize ("REG_ESUBREG"), REG_ESUBREG);
    hsc_enum (Int, , hsc_haskellize ("REG_EBRACK"), REG_EBRACK);
    hsc_enum (Int, , hsc_haskellize ("REG_EPAREN"), REG_EPAREN);
    hsc_enum (Int, , hsc_haskellize ("REG_EBRACE"), REG_EBRACE);
    hsc_enum (Int, , hsc_haskellize ("REG_ERANGE"), REG_ERANGE);
    hsc_enum (Int, , hsc_haskellize ("REG_ESPACE"), REG_ESPACE);
    fputs ("\n"
           "", stdout);
    hsc_line (165, "Posix.hsc");
    fputs ("\n"
           "type CRegMatch = ()\n"
           "\n"
           "foreign import ccall unsafe \"regcomp\"\n"
           "  c_regcomp :: Ptr CRegex -> CString -> CInt -> IO CInt\n"
           "\n"
           "foreign import ccall  unsafe \"&regfree\"\n"
           "  ptr_regfree :: FunPtr (Ptr CRegex -> IO ())\n"
           "\n"
           "foreign import ccall unsafe \"regexec\"\n"
           "  c_regexec :: Ptr CRegex -> CString -> CSize\n"
           "\t    -> Ptr CRegMatch -> CInt -> IO CInt\n"
           "\n"
           "", stdout);
#line 178 "Posix.hsc"
#endif /* HAVE_REGEX_H */
    fputs ("\n"
           "", stdout);
    hsc_line (179, "Posix.hsc");
    fputs ("", stdout);
    return 0;
}
