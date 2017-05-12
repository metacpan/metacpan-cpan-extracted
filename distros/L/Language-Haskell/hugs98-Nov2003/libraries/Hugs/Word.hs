-----------------------------------------------------------------------------
-- Unsigned Integers
-- Suitable for use with Hugs 98 on 32 bit systems.
-----------------------------------------------------------------------------
module Hugs.Word
	( Word
	, Word8
	, Word16
	, Word32
	, Word64
	) where

import Hugs.Prelude ( Word, Word8, Word16, Word32, Word64 )
import Data.Bits
import Data.Int
import Hugs.Prelude ( Ix(..) )
import Hugs.Prelude ( (%) )
import Hugs.Prelude ( readDec, showInt )
import Hugs.Prelude ( Num(fromInt), Integral(toInt) )

-----------------------------------------------------------------------------
-- The "official" coercion functions
-----------------------------------------------------------------------------

word8ToInt   :: Word8  -> Int
intToWord8   :: Int    -> Word8
word16ToInt  :: Word16 -> Int
intToWord16  :: Int    -> Word16

word8ToInt  = word32ToInt    . word8ToWord32
intToWord8  = word32ToWord8  . intToWord32
word16ToInt = word32ToInt    . word16ToWord32
intToWord16 = word32ToWord16 . intToWord32

primitive intToWord32 "intToWord32" :: Int    -> Word32
primitive word32ToInt "word32ToInt" :: Word32 -> Int

-----------------------------------------------------------------------------
-- Word8
-----------------------------------------------------------------------------

primitive word8ToWord32 "primWord8ToWord32" :: Word8  -> Word32
primitive word32ToWord8 "primWord32ToWord8" :: Word32 -> Word8

instance Eq  Word8     where (==)    = binop (==)
instance Ord Word8     where compare = binop compare

instance Num Word8 where
    x + y         = to (binop (+) x y)
    x - y         = to (binop (-) x y)
    negate        = to . negate . from
    x * y         = to (binop (*) x y)
    abs           = absReal
    signum        = signumReal
    fromInteger   = to . primIntegerToWord
    fromInt       = intToWord8

instance Bounded Word8 where
    minBound = 0
    maxBound = 0xff

instance Real Word8 where
    toRational x = toInteger x % 1

instance Integral Word8 where
    x `div` y     = to  (binop div x y)
    x `quot` y    = to  (binop quot x y)
    x `rem` y     = to  (binop rem x y)
    x `mod` y     = to  (binop mod x y)
    x `quotRem` y = to2 (binop quotRem x y)
    divMod        = quotRem
    toInteger     = toInteger . from
    toInt         = word8ToInt

instance Ix Word8 where
    range (m,n)          = [m..n]
    index b@(m,n) i
	   | inRange b i = word32ToInt (from (i - m))
	   | otherwise   = error "index: Index out of range"
    inRange (m,n) i      = m <= i && i <= n

instance Enum Word8 where
    toEnum         = to . intToWord32
    fromEnum       = word32ToInt . from
    enumFrom c       = map toEnum [fromEnum c .. fromEnum (maxBound::Word8)]
    enumFromThen c d = map toEnum [fromEnum c, fromEnum d .. fromEnum (last::Word8)]
		       where last = if d < c then minBound else maxBound

instance Read Word8 where
    readsPrec p = readDec

instance Show Word8 where
    showsPrec p = showInt  -- a particularily counterintuitive name!

instance Bits Word8 where
  x .&. y       = to (binop (.&.) x y)
  x .|. y       = to (binop (.|.) x y)
  x `xor` y     = to (binop xor x y)
  complement    = to . complement . from
  x `shift` i   = to (from x `shift` i)
  x `rotate` i  = to (from x `rot` i)
    where rot = primRotateWord 8
  bit           = to . bit
  setBit x i    = to (setBit (from x) i)
  clearBit x i  = to (clearBit (from x) i)
  complementBit x i = to (complementBit (from x) i)
  testBit x i   = testBit (from x) i
  bitSize  _    = 8
  isSigned _    = False

-----------------------------------------------------------------------------
-- Word16
-----------------------------------------------------------------------------

primitive word16ToWord32 "primWord16ToWord32" :: Word16 -> Word32
primitive word32ToWord16 "primWord32ToWord16" :: Word32 -> Word16

instance Eq  Word16     where (==)    = binop (==)
instance Ord Word16     where compare = binop compare

instance Num Word16 where
    x + y         = to (binop (+) x y)
    x - y         = to (binop (-) x y)
    negate        = to . negate . from
    x * y         = to (binop (*) x y)
    abs           = absReal
    signum        = signumReal
    fromInteger   = to . primIntegerToWord
    fromInt       = intToWord16

instance Bounded Word16 where
    minBound = 0
    maxBound = 0xffff

instance Real Word16 where
  toRational x = toInteger x % 1

instance Integral Word16 where
  x `div` y     = to  (binop div x y)
  x `quot` y    = to  (binop quot x y)
  x `rem` y     = to  (binop rem x y)
  x `mod` y     = to  (binop mod x y)
  x `quotRem` y = to2 (binop quotRem x y)
  divMod        = quotRem
  toInteger     = toInteger . from
  toInt         = word16ToInt

instance Ix Word16 where
  range (m,n)          = [m..n]
  index b@(m,n) i
         | inRange b i = word32ToInt (from (i - m))
         | otherwise   = error "index: Index out of range"
  inRange (m,n) i      = m <= i && i <= n

instance Enum Word16 where
  toEnum         = to . intToWord32
  fromEnum       = word32ToInt . from
  enumFrom c       = map toEnum [fromEnum c .. fromEnum (maxBound::Word16)]
  enumFromThen c d = map toEnum [fromEnum c, fromEnum d .. fromEnum (last::Word16)]
		       where last = if d < c then minBound else maxBound

instance Read Word16 where
  readsPrec p = readDec

instance Show Word16 where
  showsPrec p = showInt  -- a particularily counterintuitive name!

instance Bits Word16 where
  x .&. y       = to (binop (.&.) x y)
  x .|. y       = to (binop (.|.) x y)
  x `xor` y     = to (binop xor x y)
  complement    = to . complement . from
  x `shift` i   = to (from x `shift` i)
  x `rotate` i  = to (from x `rot` i)
    where rot = primRotateWord 16
  bit           = to . bit
  setBit x i    = to (setBit (from x) i)
  clearBit x i  = to (clearBit (from x) i)
  complementBit x i = to (complementBit (from x) i)
  testBit x i   = testBit (from x) i
  bitSize  _    = 16
  isSigned _    = False

-----------------------------------------------------------------------------
-- Word32
-----------------------------------------------------------------------------

instance Eq  Word32     where (==)    = primEqWord
instance Ord Word32     where compare = primCmpWord

instance Num Word32 where
    (+)           = primPlusWord
    (-)           = primMinusWord
    negate        = primNegateWord
    (*)           = primMulWord
    abs           = absReal
    signum        = signumReal
    fromInteger   = primIntegerToWord
    fromInt       = intToWord32

instance Bounded Word32 where
    minBound = 0
    maxBound = primMaxWord

instance Real Word32 where
    toRational x = toInteger x % 1

instance Integral Word32 where
    div       = primDivWord
    quot      = primQuotWord
    rem       = primRemWord
    mod       = primModWord
    quotRem   = primQrmWord
    divMod    = quotRem
    toInteger = primWordToInteger
    toInt     = word32ToInt 

instance Ix Word32 where
    range (m,n)          = [m..n]
    index b@(m,n) i
	   | inRange b i = word32ToInt (i - m)
	   | otherwise   = error "index: Index out of range"
    inRange (m,n) i      = m <= i && i <= n

instance Enum Word32 where
    toEnum        = intToWord32
    fromEnum      = word32ToInt

    --No: suffers from overflow problems: 
    --   [4294967295 .. 1] :: [Word32]
    --   = [4294967295,0,1]
    --enumFrom c       = map toEnum [fromEnum c .. fromEnum (maxBound::Word32)]
    --enumFromThen c d = map toEnum [fromEnum c, fromEnum d .. fromEnum (last::Word32)]
    --     	           where last = if d < c then minBound else maxBound

    enumFrom       = boundedEnumFrom
    enumFromTo     = boundedEnumFromTo
    enumFromThen   = boundedEnumFromThen
    enumFromThenTo = boundedEnumFromThenTo

boundedEnumFrom        :: (Ord a, Num a, Bounded a, Enum a) => a -> [a]
boundedEnumFromThen    :: (Ord a, Num a, Bounded a, Enum a) => a -> a -> [a]
boundedEnumFromTo      :: (Ord a, Num a, Bounded a, Enum a) => a -> a -> [a]
boundedEnumFromThenTo  :: (Ord a, Num a, Bounded a, Enum a) => a -> a -> a -> [a]
boundedEnumFrom n
  | n == maxBound = [n]
  | otherwise     = n : (boundedEnumFrom $! (n+1))
boundedEnumFromThen n m
  | n <= m    = enum (< maxBound - delta) delta n
  | otherwise = enum (> minBound - delta) delta n
 where
  delta = m - n
boundedEnumFromTo n m = takeWhile (<= m) (boundedEnumFrom n)
boundedEnumFromThenTo n n' m 
  | n' >= n   = if n <= m then enum (<= m - delta) delta n else []
  | otherwise = if n >= m then enum (>= m - delta) delta n else []
 where
  delta = n'-n

enum :: (Num a) => (a -> Bool) -> a -> a -> [a]
enum p delta x = if p x then x : (enum p delta $! (x+delta)) else [x]

instance Read Word32 where
    readsPrec p = readDec

instance Show Word32 where
    showsPrec p = showInt  -- a particularily counterintuitive name!

instance Bits Word32 where
  (.&.)         = primAndWord
  (.|.)         = primOrWord
  xor           = primXorWord
  complement    = primComplementWord
  shift         = primShiftWord
  rotate        = primRotateWord 32
  bit           = primBitWord
  setBit x i    = x .|. bit i
  clearBit x i  = x .&. complement (bit i)
  complementBit x i = x `xor` bit i
  testBit       = primTestWord
  bitSize  _    = 32
  isSigned _    = False

-----------------------------------------------------------------------------
-- Word64
-----------------------------------------------------------------------------

primitive word64ToWord32 "primWord64ToWord32" :: Word64 -> (Word32,Word32)
primitive word32ToWord64 "primWord32ToWord64" :: Word32 -> Word32 -> Word64

integerToW64 :: Integer -> Word64
integerToW64 x = case x `quotRem` 0x100000000 of
	(hi,lo) -> word32ToWord64 (fromInteger hi) (fromInteger lo)

w64ToInteger :: Word64 -> Integer
w64ToInteger x = case word64ToWord32 x of
	(hi,lo) -> toInteger hi * 0x100000000 + toInteger lo

instance Eq Word64 where
    x == y = word64ToWord32 x == word64ToWord32 y

instance Ord Word64 where
    compare x y = compare (word64ToWord32 x) (word64ToWord32 y)

instance Bounded Word64 where
    minBound = word32ToWord64 minBound minBound
    maxBound = word32ToWord64 maxBound maxBound

instance Show Word64 where
    showsPrec p = showInt . toInteger

instance Read Word64 where
    readsPrec p s = [ (fromInteger x,r) | (x,r) <- readDec s ]

instance Num Word64 where
    x + y         = fromInteger (toInteger x + toInteger y)
    x - y         = fromInteger (toInteger x - toInteger y)
    x * y         = fromInteger (toInteger x * toInteger y)
    abs           = absReal
    signum        = signumReal
    fromInteger   = integerToW64

instance Real Word64 where
    toRational x = toInteger x % 1

instance Ix Word64 where
    range (m,n)          = [m..n]
    index b@(m,n) i
	   | inRange b i = toInt (i - m)
	   | otherwise   = error "index: Index out of range"
    inRange (m,n) i      = m <= i && i <= n

instance Enum Word64 where
    toEnum           = fromInt
    fromEnum         = toInt

    succ             = fromInteger . (+1) . toInteger
    pred             = fromInteger . (subtract 1) . toInteger
    enumFrom x       = map fromInteger [toInteger x ..]
    enumFromTo x y   = map fromInteger [toInteger x .. toInteger y]
    enumFromThen x y = map fromInteger [toInteger x, toInteger y ..]
    enumFromThenTo x y z =
                       map fromInteger [toInteger x, toInteger y .. toInteger z]

instance Integral Word64 where
    x `quotRem` y = (fromInteger q, fromInteger r)
	where (q,r) = toInteger x `quotRem` toInteger y
    toInteger     = w64ToInteger

instance Bits Word64 where
    x .&. y       = liftBinary (.&.) x y
    x .|. y       = liftBinary (.|.) x y
    x `xor` y     = liftBinary xor x y
    complement    = liftUnary complement
    x `shift` i   = fromInteger (toInteger x `shift` i)
    x `rotate` i  | i<0  = (x `shift` i) .|. (x `shift` (i+bitSize x))
		  | i==0 = x
		  | i>0  = (x `shift` i) .|. (x `shift` (i-bitSize x))
    bit i | i `mod` 64 < 32 = word32ToWord64 0 (bit i)
          | otherwise       = word32ToWord64 (bit i) 0
    bitSize  _    = 64
    isSigned _    = False

liftBinary :: (Word32 -> Word32 -> Word32) -> Word64 -> Word64 -> Word64
liftBinary op x y = word32ToWord64 (op xhi yhi) (op xlo ylo)
	where	(xhi,xlo) = word64ToWord32 x
		(yhi,ylo) = word64ToWord32 y

liftUnary :: (Word32 -> Word32) -> Word64 -> Word64
liftUnary op x = word32ToWord64 (op xhi) (op xlo)
	where	(xhi,xlo) = word64ToWord32 x

-----------------------------------------------------------------------------
-- End of exported definitions
--
-- The remainder of this file consists of definitions which are only
-- used in the implementation.
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Coercions - used to make the instance declarations more uniform
-----------------------------------------------------------------------------

class Coerce a where
  to   :: Word32 -> a
  from :: a -> Word32

instance Coerce Word8 where
  from = word8ToWord32
  to   = word32ToWord8

instance Coerce Word16 where
  from = word16ToWord32
  to   = word32ToWord16

binop :: Coerce word => (Word32 -> Word32 -> a) -> (word -> word -> a)
binop op x y = from x `op` from y

to2 :: Coerce word => (Word32, Word32) -> (word, word)
to2 (x,y) = (to x, to y)

-----------------------------------------------------------------------------
-- primitives
-----------------------------------------------------------------------------

primitive primEqWord        :: Word32 -> Word32 -> Bool
primitive primCmpWord       :: Word32 -> Word32 -> Ordering
primitive primPlusWord,
	  primMinusWord,
	  primMulWord	    :: Word32 -> Word32 -> Word32
primitive primNegateWord    :: Word32 -> Word32
primitive primIntegerToWord :: Integer -> Word32
primitive primMaxWord       :: Word32
primitive primDivWord,
	  primQuotWord,
	  primRemWord,
	  primModWord       :: Word32 -> Word32 -> Word32
primitive primQrmWord       :: Word32 -> Word32 -> (Word32,Word32)
primitive primWordToInteger :: Word32 -> Integer
primitive primAndWord       :: Word32 -> Word32 -> Word32
primitive primOrWord        :: Word32 -> Word32 -> Word32
primitive primXorWord       :: Word32 -> Word32 -> Word32
primitive primComplementWord:: Word32 -> Word32
primitive primShiftWord     :: Word32 -> Int -> Word32
primitive primRotateWord    :: Int -> Word32 -> Int -> Word32
primitive primBitWord       :: Int -> Word32
primitive primTestWord      :: Word32 -> Int -> Bool

-----------------------------------------------------------------------------
-- Code copied from the Prelude
-----------------------------------------------------------------------------

absReal x    | x >= 0    = x
	     | otherwise = -x

signumReal x | x == 0    =  0
	     | x > 0     =  1
	     | otherwise = -1

-----------------------------------------------------------------------------
-- End
-----------------------------------------------------------------------------
