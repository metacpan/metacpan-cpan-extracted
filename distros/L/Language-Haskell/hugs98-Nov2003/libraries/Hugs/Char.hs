module Hugs.Char (
    isAscii, isLatin1, isControl, isPrint, isSpace, isUpper, isLower,
    isAlpha, isDigit, isOctDigit, isHexDigit, isAlphaNum,
    intToDigit,
    toUpper, toLower,
    ord, chr,
    readLitChar, showLitChar, lexLitChar
    ) where

import Hugs.Prelude(
    isSpace, isUpper, isLower,
    isAlpha, isDigit, isOctDigit, isHexDigit, isAlphaNum,
    readLitChar, showLitChar, lexLitChar)

-- The Hugs Char type covers only the ISO 8859-1 (Latin-1) subset of Unicode,
-- i.e. '\0' to '\xff'.

-- Character-testing operations (some others are in Hugs.Prelude)
isAscii, isLatin1, isControl, isPrint :: Char -> Bool

isAscii c                =  c < '\x80'

isLatin1 c               =  True	-- c <= '\xff'
 
isControl c              =  c < ' ' || c >= '\DEL' && c <= '\x9f'
 
isPrint c                =  not (isControl c)

-- Digit conversion operations
intToDigit               :: Int -> Char
intToDigit i
  | i >= 0  && i <=  9   =  toEnum (fromEnum '0' + i)
  | i >= 10 && i <= 15   =  toEnum (fromEnum 'a' + i - 10)
  | otherwise            =  error "Char.intToDigit: not a digit"

-- Case-changing operations
toUpper                  :: Char -> Char
toUpper '\xdf'           = '\xdf'	-- lower, but no upper in Latin-1
toUpper '\xff'           = '\xff'	-- lower, but no upper in Latin-1
toUpper c | isLower c    =  toEnum (fromEnum c - fromEnum 'a' + fromEnum 'A')
          | otherwise    =  c

toLower                  :: Char -> Char
toLower c | isUpper c    =  toEnum (fromEnum c - fromEnum 'A' + fromEnum 'a')
          | otherwise    =  c

-- Character code functions
ord                      :: Char -> Int
ord                      =  fromEnum

chr                      :: Int  -> Char
chr                      =  toEnum
