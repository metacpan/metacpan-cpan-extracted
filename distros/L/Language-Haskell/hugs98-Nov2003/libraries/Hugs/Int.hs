-----------------------------------------------------------------------------
-- Signed Integers
-- Suitable for use with Hugs 98 on 32 bit systems.
-----------------------------------------------------------------------------

module Hugs.Int
	( Int8
	, Int16
	, Int32
	, Int64
	-- plus Eq, Ord, Num, Bounded, Real, Integral, Ix, Enum, Read,
	--  Show and Bits instances for each of Int8, Int16 and Int32
	) where

import Hugs.Prelude ( Int8, Int16, Int32, Int64 )
import Hugs.Prelude ( Ix(..) )
import Hugs.Prelude ( (%) )
import Hugs.Prelude ( readDec, showInt )
import Hugs.Prelude ( Num(fromInt), Integral(toInt) )
import Hugs.Bits
import Data.Bits

-----------------------------------------------------------------------------
-- The "official" coercion functions
-----------------------------------------------------------------------------

int8ToInt  :: Int8  -> Int  
intToInt8  :: Int   -> Int8 
int16ToInt :: Int16 -> Int  
intToInt16 :: Int   -> Int16

int8ToInt  = int32ToInt   . int8ToInt32
intToInt8  = int32ToInt8  . intToInt32
int16ToInt = int32ToInt   . int16ToInt32
intToInt16 = int32ToInt16 . intToInt32  

-----------------------------------------------------------------------------
-- Int8
-----------------------------------------------------------------------------

primitive int8ToInt32 "primInt8ToInt32" :: Int8 -> Int32
primitive int32ToInt8 "primInt32ToInt8" :: Int32 -> Int8

instance Eq  Int8     where (==)    = binop (==)
instance Ord Int8     where compare = binop compare

instance Num Int8 where
    x + y         = to (binop (+) x y)
    x - y         = to (binop (-) x y)
    negate        = to . negate . from
    x * y         = to (binop (*) x y)
    abs           = absReal
    signum        = signumReal
    fromInteger   = to . fromInteger
    fromInt       = intToInt8

instance Bounded Int8 where
    minBound = 0x80
    maxBound = 0x7f 

instance Real Int8 where
    toRational x = toInteger x % 1

instance Integral Int8 where
    x `div` y     = to  (binop div x y)
    x `quot` y    = to  (binop quot x y)
    x `rem` y     = to  (binop rem x y)
    x `mod` y     = to  (binop mod x y)
    x `quotRem` y = to2 (binop quotRem x y)
    toInteger     = toInteger . from
    toInt         = int8ToInt

instance Ix Int8 where
    range (m,n)          = [m..n]
    index b@(m,n) i
	      | inRange b i = toInt (i - m)
	      | otherwise   = error "index: Index out of range"
    inRange (m,n) i      = m <= i && i <= n

instance Enum Int8 where
    toEnum           = fromInt
    fromEnum         = toInt
    enumFrom c       = map toEnum [fromEnum c .. fromEnum (maxBound::Int8)]
    enumFromThen c d = map toEnum [fromEnum c, fromEnum d .. fromEnum (last::Int8)]
			  where last = if d < c then minBound else maxBound

instance Read Int8 where
    readsPrec p s = [ (to x,r) | (x,r) <- readsPrec p s ]

instance Show Int8 where
    showsPrec p = showsPrec p . from

binop8 :: (Int32 -> Int32 -> a) -> (Int8 -> Int8 -> a)
binop8 op x y = int8ToInt32 x `op` int8ToInt32 y

instance Bits Int8 where
  x .&. y       = int32ToInt8 (binop8 (.&.) x y)
  x .|. y       = int32ToInt8 (binop8 (.|.) x y)
  x `xor` y     = int32ToInt8 (binop8 xor x y)
  complement    = int32ToInt8 . complement . int8ToInt32
  x `shift` i   = int32ToInt8 (int8ToInt32 x `shift` i)
  rotate        = rotateSigned
  bit           = int32ToInt8 . bit
  setBit x i    = int32ToInt8 (setBit (int8ToInt32 x) i)
  clearBit x i  = int32ToInt8 (clearBit (int8ToInt32 x) i)
  complementBit x i = int32ToInt8 (complementBit (int8ToInt32 x) i)
  testBit x i   = testBit (int8ToInt32 x) i
  bitSize  _    = 8
  isSigned _    = True

-----------------------------------------------------------------------------
-- Int16
-----------------------------------------------------------------------------

primitive int16ToInt32 "primInt16ToInt32" :: Int16 -> Int32
primitive int32ToInt16 "primInt32ToInt16" :: Int32 -> Int16

instance Eq  Int16     where (==)    = binop (==)
instance Ord Int16     where compare = binop compare

instance Num Int16 where
    x + y         = to (binop (+) x y)
    x - y         = to (binop (-) x y)
    negate        = to . negate . from
    x * y         = to (binop (*) x y)
    abs           = absReal
    signum        = signumReal
    fromInteger   = to . fromInteger
    fromInt       = intToInt16

instance Bounded Int16 where
    minBound = 0x8000
    maxBound = 0x7fff 

instance Real Int16 where
    toRational x = toInteger x % 1

instance Integral Int16 where
    x `div` y     = to  (binop div x y)
    x `quot` y    = to  (binop quot x y)
    x `rem` y     = to  (binop rem x y)
    x `mod` y     = to  (binop mod x y)
    x `quotRem` y = to2 (binop quotRem x y)
    toInteger     = toInteger . from
    toInt         = int16ToInt

instance Ix Int16 where
    range (m,n)          = [m..n]
    index b@(m,n) i
	      | inRange b i = toInt (i - m)
	      | otherwise   = error "index: Index out of range"
    inRange (m,n) i      = m <= i && i <= n

instance Enum Int16 where
    toEnum           = fromInt 
    fromEnum         = toInt
    enumFrom c       = map toEnum [fromEnum c .. fromEnum (maxBound::Int16)]
    enumFromThen c d = map toEnum [fromEnum c, fromEnum d .. fromEnum (last::Int16)]
			  where last = if d < c then minBound else maxBound

instance Read Int16 where
    readsPrec p s = [ (to x,r) | (x,r) <- readsPrec p s ]

instance Show Int16 where
    showsPrec p = showsPrec p . from

binop16 :: (Int32 -> Int32 -> a) -> (Int16 -> Int16 -> a)
binop16 op x y = int16ToInt32 x `op` int16ToInt32 y

instance Bits Int16 where
  x .&. y       = int32ToInt16 (binop16 (.&.) x y)
  x .|. y       = int32ToInt16 (binop16 (.|.) x y)
  x `xor` y     = int32ToInt16 (binop16 xor x y)
  complement    = int32ToInt16 . complement . int16ToInt32
  x `shift` i   = int32ToInt16 (int16ToInt32 x `shift` i)
  rotate        = rotateSigned
  bit           = int32ToInt16 . bit
  setBit x i    = int32ToInt16 (setBit (int16ToInt32 x) i)
  clearBit x i  = int32ToInt16 (clearBit (int16ToInt32 x) i)
  complementBit x i = int32ToInt16 (complementBit (int16ToInt32 x) i)
  testBit x i   = testBit (int16ToInt32 x) i
  bitSize  _    = 16
  isSigned _    = True

-----------------------------------------------------------------------------
-- Int32
-----------------------------------------------------------------------------

primitive int32ToInt "primInt32ToInt" :: Int32 -> Int
primitive intToInt32 "primIntToInt32" :: Int -> Int32
primitive primEqInt32  :: Int32 -> Int32 -> Bool
primitive primCmpInt32 :: Int32 -> Int32 -> Ordering

instance Eq  Int32 where (==)    = primEqInt32
instance Ord Int32 where compare = primCmpInt32

instance Num Int32 where
    x + y         = intToInt32 (binop32 (+) x y)
    x - y         = intToInt32 (binop32 (-) x y)
    negate        = intToInt32 . negate . int32ToInt
    x * y         = intToInt32 (binop32 (*) x y)
    abs           = absReal
    signum        = signumReal
    fromInteger   = intToInt32 . fromInteger
    fromInt       = intToInt32

instance Bounded Int32 where
    minBound = intToInt32 minBound
    maxBound = intToInt32 maxBound

instance Real Int32 where
    toRational x = toInteger x % 1

instance Integral Int32 where
    x `div` y     = intToInt32 (binop32 div x y)
    x `quot` y    = intToInt32 (binop32 quot x y)
    x `rem` y     = intToInt32 (binop32 rem x y)
    x `mod` y     = intToInt32 (binop32 mod x y)
    x `quotRem` y = to2' (binop32 quotRem x y)
    toInteger     = toInteger . int32ToInt
    toInt         = int32ToInt

instance Ix Int32 where
    range (m,n)          = [m..n]
    index b@(m,n) i
	      | inRange b i = toInt (i - m)
	      | otherwise   = error "index: Index out of range"
    inRange (m,n) i      = m <= i && i <= n

instance Enum Int32 where
    toEnum           = fromInt
    fromEnum         = toInt
    enumFrom c       = map toEnum [fromEnum c .. fromEnum (maxBound::Int32)]
    enumFromThen c d = map toEnum [fromEnum c, fromEnum d .. fromEnum (last::Int32)]
			  where last = if d < c then minBound else maxBound

instance Read Int32 where
    readsPrec p s = [ (intToInt32 x,r) | (x,r) <- readsPrec p s ]

instance Show Int32 where
    showsPrec p = showsPrec p . int32ToInt

instance Bits Int32 where
    x .&. y       = intToInt32 (binop32 (.&.) x y)
    x .|. y       = intToInt32 (binop32 (.|.) x y)
    x `xor` y     = intToInt32 (binop32 xor x y)
    complement    = intToInt32 . complement . int32ToInt
    x `shift` i   = intToInt32 (int32ToInt x `shift` i)
    rotate        = rotateSigned
    bit           = intToInt32 . bit
    setBit x i    = intToInt32 (setBit (int32ToInt x) i)
    clearBit x i  = intToInt32 (clearBit (int32ToInt x) i)
    complementBit x i = intToInt32 (complementBit (int32ToInt x) i)
    testBit x i   = testBit (int32ToInt x) i
    bitSize  _    = 32
    isSigned _    = True

-----------------------------------------------------------------------------
-- Int64
-----------------------------------------------------------------------------

-- Assume a 2s-complement representation, and that this function
-- separates the top 32 bits from the lower 32.

primitive int64ToInt32 "primInt64ToInt32" :: Int64 -> (Int32,Int32)
primitive int32ToInt64 "primInt32ToInt64" :: Int32 -> Int32 -> Int64

integerToI64 :: Integer -> Int64
integerToI64 x = case x `divMod` 0x100000000 of
    (hi,lo) -> int32ToInt64 (fromInteger hi) (fromInteger lo)

i64ToInteger :: Int64 -> Integer
i64ToInteger x = case int64ToInt32 x of
    (hi,lo) -> (if lo<0 then toInteger hi+1 else toInteger hi)*0x100000000 +
	toInteger lo

instance Eq Int64 where
    x == y = int64ToInt32 x == int64ToInt32 y

instance Ord Int64 where
    compare x y = compare (toInteger x) (toInteger y)

instance Bounded Int64 where
    minBound = int32ToInt64 minBound 0
    maxBound = int32ToInt64 maxBound (-1)

instance Show Int64 where
    showsPrec p = showsPrec p . toInteger

instance Read Int64 where
    readsPrec p s = [ (fromInteger x,r) | (x,r) <- readDec s ]

instance Num Int64 where
    x + y         = fromInteger (toInteger x + toInteger y)
    x - y         = fromInteger (toInteger x - toInteger y)
    x * y         = fromInteger (toInteger x * toInteger y)
    abs           = absReal
    signum        = signumReal
    fromInteger   = integerToI64

instance Real Int64 where
    toRational x = toInteger x % 1

instance Ix Int64 where
    range (m,n)          = [m..n]
    index b@(m,n) i
	      | inRange b i = toInt (i - m)
	      | otherwise   = error "index: Index out of range"
    inRange (m,n) i      = m <= i && i <= n

instance Enum Int64 where
    toEnum           = fromInt
    fromEnum         = toInt

    succ             = fromInteger . (+1) . toInteger
    pred             = fromInteger . (subtract 1) . toInteger
    enumFrom x       = map fromInteger [toInteger x ..]
    enumFromTo x y   = map fromInteger [toInteger x .. toInteger y]
    enumFromThen x y = map fromInteger [toInteger x, toInteger y ..]
    enumFromThenTo x y z =
                       map fromInteger [toInteger x, toInteger y .. toInteger z]

instance Integral Int64 where
    x `quotRem` y = (fromInteger q, fromInteger r)
	where (q,r) = toInteger x `quotRem` toInteger y
    toInteger     = i64ToInteger

instance Bits Int64 where
    x .&. y       = liftBinary (.&.) x y
    x .|. y       = liftBinary (.|.) x y
    x `xor` y     = liftBinary xor x y
    complement    = liftUnary complement
    x `shift` i   = fromInteger (toInteger x `shift` i)
    rotate        = rotateSigned
    bit i | i `mod` 64 < 32 = int32ToInt64 0 (bit i)
          | otherwise       = int32ToInt64 (bit i) 0
    bitSize  _    = 64
    isSigned _    = True

liftBinary :: (Int32 -> Int32 -> Int32) -> Int64 -> Int64 -> Int64
liftBinary op x y = int32ToInt64 (op xhi yhi) (op xlo ylo)
	where	(xhi,xlo) = int64ToInt32 x
		(yhi,ylo) = int64ToInt32 y

liftUnary :: (Int32 -> Int32) -> Int64 -> Int64
liftUnary op x = int32ToInt64 (op xhi) (op xlo)
	where	(xhi,xlo) = int64ToInt32 x

rotateSigned :: (Bits a, Ord a) => a -> Int -> a
rotateSigned x i | i<0 && x<0
                        = let left = i+bitSize x in
                          ((x `shift` i) .&. complement ((-1) `shift` left))
                          .|. (x `shift` left)
                 | i<0  = (x `shift` i) .|. (x `shift` (i+bitSize x))
                 | i==0 = x
                 | i>0  = (x `shift` i) .|. (x `shift` (i-bitSize x))

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
  to   :: Int32 -> a
  from :: a -> Int32

instance Coerce Int where
  from = intToInt32
  to   = int32ToInt

instance Coerce Int8 where
  from = int8ToInt32
  to   = int32ToInt8

instance Coerce Int16 where
  from = int16ToInt32
  to   = int32ToInt16

binop :: Coerce int => (Int32 -> Int32 -> a) -> (int -> int -> a)
binop op x y = from x `op` from y

to2 :: Coerce int => (Int32, Int32) -> (int, int)
to2 (x,y) = (to x, to y)

to2' :: (Int, Int) -> (Int32, Int32)
to2' (x,y) = (intToInt32 x, intToInt32 y)

binop32 :: (Int -> Int -> a) -> (Int32 -> Int32 -> a)
binop32 op x y = int32ToInt x `op` int32ToInt y

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
