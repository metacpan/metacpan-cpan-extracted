% -----------------------------------------------------------------------------
% $Id: ForeignObj.lhs,v 1.25 2002/09/09 11:13:16 simonmar Exp $
%
% (c) The GRAP/AQUA Project, Glasgow University & The FFI task force, 2000
%

All of this module is deprecated, replaced by ForeignPtr.

\begin{code}
{-# OPTIONS -monly-3-regs #-}

#include "MachDeps.h"

module ForeignObj
        ( 
 	  -- SDM: deprecated, use ForeignPtr instead
	  ForeignObj,         -- abstract, instance of: Eq
        , newForeignObj       -- :: Addr -> IO () -> IO ForeignObj
        , addForeignFinalizer -- :: ForeignObj -> IO () -> IO ()
	, withForeignObj      -- :: ForeignObj -> (Addr -> IO b) -> IO b
	, touchForeignObj     -- :: ForeignObj -> IO ()

        -- SUP: deprecated, the address associated with a foreign object is immutable
        , writeForeignObj     -- :: ForeignObj  -> Addr{-new obj-}   -> IO ()
        -- SUP: deprecated, the address associated with a foreign object is immutable
	, writeForeignObjOffAddr -- :: Addr -> Int -> ForeignObj -> IO ()

        -- SUP: deprecated
        , makeForeignObj      -- :: Addr -> Addr -> IO ForeignObj
	, mkForeignObj        -- :: Addr -> IO ForeignObj
        , foreignObjToPtr     -- :: ForeignObj -> Ptr a
        , foreignObjToAddr    -- :: ForeignObj -> Addr

        -- SUP: deprecated, use class Storable
        , indexCharOffForeignObj    -- :: ForeignObj -> Int -> Char
        , indexAddrOffForeignObj    -- :: ForeignObj -> Int -> Addr
        , indexFloatOffForeignObj   -- :: ForeignObj -> Int -> Float
        , indexDoubleOffForeignObj  -- :: ForeignObj -> Int -> Double
       
        , indexIntOffForeignObj     -- :: ForeignObj -> Int -> Int
        , indexInt8OffForeignObj    -- :: ForeignObj -> Int -> Int8
        , indexInt16OffForeignObj   -- :: ForeignObj -> Int -> Int16
        , indexInt32OffForeignObj   -- :: ForeignObj -> Int -> Int32
        , indexInt64OffForeignObj   -- :: ForeignObj -> Int -> Int64

        , indexWordOffForeignObj    -- :: ForeignObj -> Int -> Word
        , indexWord8OffForeignObj   -- :: ForeignObj -> Int -> Word8
        , indexWord16OffForeignObj  -- :: ForeignObj -> Int -> Word16
        , indexWord32OffForeignObj  -- :: ForeignObj -> Int -> Word32
        , indexWord64OffForeignObj  -- :: ForeignObj -> Int -> Word64

        , readCharOffForeignObj     -- :: ForeignObj -> Int -> IO Char
        , readAddrOffForeignObj     -- :: ForeignObj -> Int -> IO Addr
        , readFloatOffForeignObj    -- :: ForeignObj -> Int -> IO Float
        , readDoubleOffForeignObj   -- :: ForeignObj -> Int -> IO Double
       
        , readIntOffForeignObj      -- :: ForeignObj -> Int -> IO Int
        , readInt8OffForeignObj     -- :: ForeignObj -> Int -> IO Int8
        , readInt16OffForeignObj    -- :: ForeignObj -> Int -> IO Int16
        , readInt32OffForeignObj    -- :: ForeignObj -> Int -> IO Int32
        , readInt64OffForeignObj    -- :: ForeignObj -> Int -> IO Int64

        , readWordOffForeignObj     -- :: ForeignObj -> Int -> IO Word
        , readWord8OffForeignObj    -- :: ForeignObj -> Int -> IO Word8
        , readWord16OffForeignObj   -- :: ForeignObj -> Int -> IO Word16
        , readWord32OffForeignObj   -- :: ForeignObj -> Int -> IO Word32
        , readWord64OffForeignObj   -- :: ForeignObj -> Int -> IO Word64

        , writeCharOffForeignObj    -- :: ForeignObj -> Int -> Char   -> IO ()
        , writeAddrOffForeignObj    -- :: ForeignObj -> Int -> Addr   -> IO ()
        , writeFloatOffForeignObj   -- :: ForeignObj -> Int -> Float  -> IO ()
        , writeDoubleOffForeignObj  -- :: ForeignObj -> Int -> Double -> IO ()

        , writeIntOffForeignObj     -- :: ForeignObj -> Int -> Int    -> IO ()
        , writeInt8OffForeignObj    -- :: ForeignObj -> Int -> Int8   -> IO ()
        , writeInt16OffForeignObj   -- :: ForeignObj -> Int -> Int16  -> IO ()
        , writeInt32OffForeignObj   -- :: ForeignObj -> Int -> Int32  -> IO ()
        , writeInt64OffForeignObj   -- :: ForeignObj -> Int -> Int64  -> IO ()

        , writeWordOffForeignObj    -- :: ForeignObj -> Int -> Word   -> IO ()
        , writeWord8OffForeignObj   -- :: ForeignObj -> Int -> Word8  -> IO ()
        , writeWord16OffForeignObj  -- :: ForeignObj -> Int -> Word16 -> IO ()
        , writeWord32OffForeignObj  -- :: ForeignObj -> Int -> Word32 -> IO ()
        , writeWord64OffForeignObj  -- :: ForeignObj -> Int -> Word64 -> IO ()
        ) 
	where
\end{code}

\begin{code}
import GHC.Word
import GHC.Int
import GHC.IOBase	( IO(..) )
import GHC.Base
import GHC.Float	( Float(..), Double(..) )
import GHC.Ptr

import Addr
\end{code}

\begin{code}
data ForeignObj = ForeignObj ForeignObj#   -- another one
  
mkForeignObj  :: Addr -> IO ForeignObj
mkForeignObj (A# obj) = IO ( \ s# ->
    case mkForeignObj# obj s# of
      (# s1#, fo# #) -> (# s1#,  ForeignObj fo# #) )

makeForeignObj_ :: Addr -> IO () -> IO ForeignObj
makeForeignObj_ addr finalizer = do
   fObj <- mkForeignObj addr
   addForeignFinalizer fObj finalizer
   return fObj

addForeignFinalizer :: ForeignObj -> IO () -> IO ()
addForeignFinalizer (ForeignObj fo) finalizer
  = IO $ \s -> case mkWeak# fo () finalizer s of { (# s1, w #) -> (# s1, () #) }

{-# DEPRECATED writeForeignObj "ForeignObj has been replaced by ForeignPtr" #-}
writeForeignObj :: ForeignObj -> Addr -> IO ()
writeForeignObj (ForeignObj fo#) (A# datum#) = IO ( \ s# ->
    case writeForeignObj# fo# datum# s# of { s1# -> (# s1#, () #) } )

{-# DEPRECATED newForeignObj "ForeignObj has been replaced by ForeignPtr" #-}
newForeignObj :: Addr -> IO () -> IO ForeignObj
newForeignObj addr fin = makeForeignObj_ addr fin

{-# DEPRECATED makeForeignObj "ForeignObj has been replaced by ForeignPtr" #-}
makeForeignObj :: Addr -> Addr -> IO ForeignObj
makeForeignObj addr finAddr
  | finAddr == nullAddr = newForeignObj addr (return ())
  | otherwise =
       newForeignObj addr 
	  (ap0 (castPtrToFunPtr (addrToPtr finAddr)) (addrToPtr addr))

foreign import dynamic ap0 :: FunPtr (Addr -> IO()) -> (Ptr () -> IO ())

{-# DEPRECATED foreignObjToPtr "ForeignObj has been replaced by ForeignPtr" #-}
foreignObjToPtr :: ForeignObj -> Ptr a
foreignObjToPtr (ForeignObj fo) = Ptr (foreignObjToAddr# fo)

{-# DEPRECATED foreignObjToAddr "ForeignObj has been replaced by ForeignPtr" #-}
foreignObjToAddr :: ForeignObj -> Addr
foreignObjToAddr (ForeignObj fo) = A# (foreignObjToAddr# fo)

{-# DEPRECATED touchForeignObj "ForeignObj has been replaced by ForeignPtr" #-}
touchForeignObj :: ForeignObj -> IO ()
touchForeignObj (ForeignObj fo) 
   = IO $ \s -> case touch# fo s of s -> (# s, () #)

{-# DEPRECATED withForeignObj "ForeignObj has been replaced by ForeignPtr" #-}
withForeignObj :: ForeignObj -> (Addr -> IO b) -> IO b
withForeignObj fo io = do
   r <- io (foreignObjToAddr fo)
   touchForeignObj fo
   return r

eqForeignObj  :: ForeignObj -> ForeignObj -> Bool
eqForeignObj (ForeignObj fo1#) (ForeignObj fo2#) = eqForeignObj# fo1# fo2#

instance Eq ForeignObj where 
    p == q = eqForeignObj p q
    p /= q = not (eqForeignObj p q)

writeForeignObjOffAddr   :: Addr -> Int -> ForeignObj -> IO ()
writeForeignObjOffAddr (A# a#) (I# i#) (ForeignObj e#) = IO $ \ s# ->
      case (writeForeignObjOffAddr#  a# i# e# s#) of s2# -> (# s2#, () #)
\end{code}

read value out of immutable memory

\begin{code}
indexCharOffForeignObj   :: ForeignObj -> Int -> Char
indexCharOffForeignObj (ForeignObj fo#) (I# i#) = C# (indexCharOffForeignObj# fo# i#)

indexIntOffForeignObj    :: ForeignObj -> Int -> Int
indexIntOffForeignObj (ForeignObj fo#) (I# i#) = I# (indexIntOffForeignObj# fo# i#)

indexWordOffForeignObj    :: ForeignObj -> Int -> Word
indexWordOffForeignObj (ForeignObj fo#) (I# i#) = W# (indexWordOffForeignObj# fo# i#)

indexAddrOffForeignObj   :: ForeignObj -> Int -> Addr
indexAddrOffForeignObj (ForeignObj fo#) (I# i#) = A# (indexAddrOffForeignObj# fo# i#)

indexFloatOffForeignObj  :: ForeignObj -> Int -> Float
indexFloatOffForeignObj (ForeignObj fo#) (I# i#) = F# (indexFloatOffForeignObj# fo# i#)

indexDoubleOffForeignObj :: ForeignObj -> Int -> Double
indexDoubleOffForeignObj (ForeignObj fo#) (I# i#) = D# (indexDoubleOffForeignObj# fo# i#)

indexInt8OffForeignObj  :: ForeignObj -> Int -> Int8
indexInt8OffForeignObj (ForeignObj a#) (I# i#) = I8# (indexInt8OffForeignObj# a# i#)

indexInt16OffForeignObj  :: ForeignObj -> Int -> Int16
indexInt16OffForeignObj (ForeignObj a#) (I# i#) = I16# (indexInt16OffForeignObj# a# i#)

indexInt32OffForeignObj  :: ForeignObj -> Int -> Int32
indexInt32OffForeignObj (ForeignObj a#) (I# i#) = I32# (indexInt32OffForeignObj# a# i#)

indexInt64OffForeignObj  :: ForeignObj -> Int -> Int64
indexInt64OffForeignObj (ForeignObj a#) (I# i#) = I64# (indexInt64OffForeignObj# a# i#)

indexWord8OffForeignObj  :: ForeignObj -> Int -> Word8
indexWord8OffForeignObj (ForeignObj a#) (I# i#) = W8# (indexWord8OffForeignObj# a# i#)

indexWord16OffForeignObj  :: ForeignObj -> Int -> Word16
indexWord16OffForeignObj (ForeignObj a#) (I# i#) = W16# (indexWord16OffForeignObj# a# i#)

indexWord32OffForeignObj  :: ForeignObj -> Int -> Word32
indexWord32OffForeignObj (ForeignObj a#) (I# i#) = W32# (indexWord32OffForeignObj# a# i#)

indexWord64OffForeignObj  :: ForeignObj -> Int -> Word64
indexWord64OffForeignObj (ForeignObj a#) (I# i#) = W64# (indexWord64OffForeignObj# a# i#)
\end{code}

read value out of mutable memory

\begin{code}
readCharOffForeignObj        :: ForeignObj -> Int -> IO Char
readCharOffForeignObj fo i   =  withForeignObj fo (\a -> readCharOffAddr a i)

readIntOffForeignObj         :: ForeignObj -> Int -> IO Int
readIntOffForeignObj fo i    =  withForeignObj fo (\a -> readIntOffAddr a i)

readWordOffForeignObj        :: ForeignObj -> Int -> IO Word
readWordOffForeignObj fo i   =  withForeignObj fo (\a -> readWordOffAddr a i)

readAddrOffForeignObj        :: ForeignObj -> Int -> IO Addr
readAddrOffForeignObj fo i   =  withForeignObj fo (\a -> readAddrOffAddr a i)

readFloatOffForeignObj       :: ForeignObj -> Int -> IO Float
readFloatOffForeignObj fo i  =  withForeignObj fo (\a -> readFloatOffAddr a i)

readDoubleOffForeignObj      :: ForeignObj -> Int -> IO Double
readDoubleOffForeignObj fo i =  withForeignObj fo (\a -> readDoubleOffAddr a i)

readInt8OffForeignObj         :: ForeignObj -> Int -> IO Int8
readInt8OffForeignObj fo i    =  withForeignObj fo (\a -> readInt8OffAddr a i)

readInt16OffForeignObj         :: ForeignObj -> Int -> IO Int16
readInt16OffForeignObj fo i    =  withForeignObj fo (\a -> readInt16OffAddr a i)

readInt32OffForeignObj         :: ForeignObj -> Int -> IO Int32
readInt32OffForeignObj fo i    =  withForeignObj fo (\a -> readInt32OffAddr a i)

readInt64OffForeignObj         :: ForeignObj -> Int -> IO Int64
readInt64OffForeignObj fo i    =  withForeignObj fo (\a -> readInt64OffAddr a i)

readWord8OffForeignObj         :: ForeignObj -> Int -> IO Word8
readWord8OffForeignObj fo i    =  withForeignObj fo (\a -> readWord8OffAddr a i)

readWord16OffForeignObj         :: ForeignObj -> Int -> IO Word16
readWord16OffForeignObj fo i    =  withForeignObj fo (\a -> readWord16OffAddr a i)

readWord32OffForeignObj         :: ForeignObj -> Int -> IO Word32
readWord32OffForeignObj fo i    =  withForeignObj fo (\a -> readWord32OffAddr a i)

readWord64OffForeignObj         :: ForeignObj -> Int -> IO Word64
readWord64OffForeignObj fo i    =  withForeignObj fo (\a -> readWord64OffAddr a i)
\end{code}

write value into mutable memory

\begin{code}
writeCharOffForeignObj   :: ForeignObj -> Int -> Char   -> IO ()
writeCharOffForeignObj fo i e = withForeignObj fo (\a -> writeCharOffAddr a i e)

writeIntOffForeignObj    :: ForeignObj -> Int -> Int    -> IO ()
writeIntOffForeignObj fo i e = withForeignObj fo (\a -> writeIntOffAddr a i e)

writeWordOffForeignObj    :: ForeignObj -> Int -> Word  -> IO ()
writeWordOffForeignObj fo i e = withForeignObj fo (\a -> writeWordOffAddr a i e)

writeAddrOffForeignObj   :: ForeignObj -> Int -> Addr   -> IO ()
writeAddrOffForeignObj fo i e = withForeignObj fo (\a -> writeAddrOffAddr a i e)

writeFloatOffForeignObj  :: ForeignObj -> Int -> Float  -> IO ()
writeFloatOffForeignObj fo i e = withForeignObj fo (\a -> writeFloatOffAddr a i e)

writeDoubleOffForeignObj :: ForeignObj -> Int -> Double -> IO ()
writeDoubleOffForeignObj fo i e =  withForeignObj fo (\a -> writeDoubleOffAddr a i e)

writeInt8OffForeignObj    :: ForeignObj -> Int -> Int8    -> IO ()
writeInt8OffForeignObj fo i e = withForeignObj fo (\a -> writeInt8OffAddr a i e)

writeInt16OffForeignObj    :: ForeignObj -> Int -> Int16  -> IO ()
writeInt16OffForeignObj fo i e = withForeignObj fo (\a -> writeInt16OffAddr a i e)

writeInt32OffForeignObj    :: ForeignObj -> Int -> Int32  -> IO ()
writeInt32OffForeignObj fo i e = withForeignObj fo (\a -> writeInt32OffAddr a i e)

writeInt64OffForeignObj    :: ForeignObj -> Int -> Int64  -> IO ()
writeInt64OffForeignObj fo i e = withForeignObj fo (\a -> writeInt64OffAddr a i e)

writeWord8OffForeignObj    :: ForeignObj -> Int -> Word8   -> IO ()
writeWord8OffForeignObj fo i e = withForeignObj fo (\a -> writeWord8OffAddr a i e)

writeWord16OffForeignObj    :: ForeignObj -> Int -> Word16 -> IO ()
writeWord16OffForeignObj fo i e = withForeignObj fo (\a -> writeWord16OffAddr a i e)

writeWord32OffForeignObj    :: ForeignObj -> Int -> Word32 -> IO ()
writeWord32OffForeignObj fo i e = withForeignObj fo (\a -> writeWord32OffAddr a i e)

writeWord64OffForeignObj    :: ForeignObj -> Int -> Word64 -> IO ()
writeWord64OffForeignObj fo i e = withForeignObj fo (\a -> writeWord64OffAddr a i e)
\end{code}
