module ParsePkgConf( parsePackageConfig, parseOnePackageConfig ) where

-- ReadP version of fptools/ghc/utils/ghc-pkg/ParsePkgConfLite.y
-- (so we don't have to rely on Happy)

import Control.Monad (guard, liftM)
import Data.Char
import Text.ParserCombinators.ReadP
import Text.Read.Lex
import Prelude hiding (lex)

import Package

parsePackageConfig :: String -> [PackageConfig]
parsePackageConfig = read

parseOnePackageConfig :: String -> PackageConfig
parseOnePackageConfig = read

instance Read PackageConfig where
    readsPrec _ = readP_to_S package
    readList = readP_to_S (list package)

package :: ReadP PackageConfig
package = do
    lexeme "Package"
    lexeme "{"
    fs <- optCommaList field
    lexeme "}"
    return (foldl (flip ($)) defaultPackageConfig fs)

field :: ReadP (PackageConfig -> PackageConfig)
field = do
    Ident fieldName <- lex
    lexeme "="
    case fieldName of
	"name"		   -> liftM set_name stringLiteral
	"auto"		   -> liftM set_auto bool
	"import_dirs"      -> liftM set_import_dirs (list stringLiteral)
	"source_dirs"      -> liftM set_source_dirs (list stringLiteral)
	"library_dirs"     -> liftM set_library_dirs (list stringLiteral)
	"hs_libraries"     -> liftM set_hs_libraries (list stringLiteral)
	"extra_libraries"  -> liftM set_extra_libraries (list stringLiteral)
	"include_dirs"     -> liftM set_include_dirs (list stringLiteral)
	"c_includes"       -> liftM set_c_includes (list stringLiteral)
	"package_deps"     -> liftM set_package_deps (list stringLiteral)
	"extra_ghc_opts"   -> liftM set_extra_ghc_opts (list stringLiteral)
	"extra_cc_opts"    -> liftM set_extra_cc_opts (list stringLiteral)
	"extra_ld_opts"    -> liftM set_extra_ld_opts (list stringLiteral)
	"framework_dirs"   -> liftM set_framework_dirs (list stringLiteral)
	"extra_frameworks" -> liftM set_extra_frameworks (list stringLiteral)
  where
    set_name s p		= p{name = s}
    set_auto b p		= p{auto = b}
    set_import_dirs ss p	= p{import_dirs = ss}
    set_source_dirs ss p	= p{source_dirs = ss}
    set_library_dirs ss p	= p{library_dirs = ss}
    set_hs_libraries ss p	= p{hs_libraries = ss}
    set_extra_libraries ss p	= p{extra_libraries = ss}
    set_include_dirs ss p	= p{include_dirs = ss}
    set_c_includes ss p		= p{c_includes = ss}
    set_package_deps ss p	= p{package_deps = ss}
    set_extra_ghc_opts ss p	= p{extra_ghc_opts = ss}
    set_extra_cc_opts ss p	= p{extra_cc_opts = ss}
    set_extra_ld_opts ss p	= p{extra_ld_opts = ss}
    set_framework_dirs ss p	= p{framework_dirs = ss}
    set_extra_frameworks ss p	= p{extra_frameworks = ss}

bool :: ReadP Bool
bool = (lexeme "True" >> return True) <++ (lexeme "False" >> return False)

list :: ReadP a -> ReadP [a]
list p = do
    lexeme "["
    vs <- optCommaList p
    lexeme "]"
    return vs

stringLiteral :: ReadP String
stringLiteral = do
    String s <- lex
    return s

identifier :: ReadP String
identifier = do
    Ident s <- lex
    return s

optCommaList :: ReadP a -> ReadP [a]
optCommaList p = p_list <++ return []
    where
	p_list = do
	    a <- p
	    do
		lexeme ","
		as <- p_list
		return (a:as)
	     <++
		return [a]

lexeme :: String -> ReadP ()
lexeme s = do
    s' <- hsLex
    guard (s == s')
