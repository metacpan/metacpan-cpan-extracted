<!DOCTYPE xsl:stylesheet>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="text" media-type="text/plain" encoding="utf-8"/>

<xsl:template match="/"><![CDATA[
-- This is an automatically generated file. 
-- This is an automatically generated file. 
-- This is an automatically generated file. 
-- This is an automatically generated file. 
-- This is an automatically generated file. 

-- See doc/protocol.xml and doc/doc2haskell.xsl

-- primitive enc/decoders

module KGSProtocoll where
import Numeric
import Data.Word
import Data.Int
import Control.Monad.State

type U8  = Word8
type U16 = Word16
type U32 = Word32
type U64 = Word64
type I8  = Int8
type I16 = Int16
type I32 = Int32 
type I64 = Int64

data DecState = DecState { data :: [Word8] }

-- type DecS a = State DecState a
type DecS a = StateT DecState IO a -- for dec_HEX

hasData :: DecS Bool
hasData = do
           xs <- get
           return $ not $ null xs

dec_U8 :: Word8
dec_U8 =
  do (x:xs) <- get
     put xs 
     return x

dec_U16 :: DecS Word16
dec_U16 =
 do a <- dec_U8
    b <- dec_U8
    return $ (fromIntegral a :: Word16) + (fromIntegral b :: Word16) * 256


dec_U64 :: DecS Word64
dec_U64 =
  do a1 <- dec_U16
     a2 <- dec_U16
     a3 <- dec_U16
     a4 <- dec_U16
     return $   (fI a4) `shiftL` 48
              + (fI a3) `shiftL` 32
              + (fI a2) `shiftL` 16
              + (fI a1)
     where fI a = fromIntegral a :: Word64


dec_I8 :: DecS Int8
dec_I8 =
  do w8 <- dec_U8
     return $ fromIntegral w8 :: Int8

dec_I16 :: DecS Int16
dec_I16 =
  do w16 <- dec_U16
     return $ fromIntegral w16 :: Int16

dec_I32 :: DecS Int32
dec_I32 =
  do w16_1 <- dec_U16
     w16_2 <- dec_U16
     return $   (fI w16_2) `shiftL` 16
              + (fI w16_1)
     where fI a = fromIntegral a :: Int32

dec_DATA :: DecS [Word8]
dec_DATA =
  do da <- get
     put []
     return da

dec_STRING :: DecS [Word16]
dec_STRING =
  do c <- dec_U16
     if c == 0 then do return []
     else return (c:dec_STRING)

{-  do da <- get
     let (str,rest) = mkstr da
     where 
       mkstr str [] =
         (reverse str,[])
       mkstr str (0:rest) =
         (reverse str, rest)
       mkstr str (c:rest) =
         mkstr ((toEnum (fromIntegral c :: Int)):str) rest -}

{-
sub dec_STRING {
   $data =~ s/^((?:..)*?)(?:\x00\x00|\Z)//s;
   # use Encode...
   join "", map chr, unpack "v*", $1; -- marc ???
} 
-}

dec_CONSTANT :: DecS a
dec_CONSTANT x = x

type Password = Word64

dec_password :: DecS Password
dec_password = dec_U64

dec_HEX :: DecS ()
dec_HEX =
  do da <- get
     putStr "HEX: "
     putStrLn $ (dec_data da) ""
     where dec_data (x:xs) = 
             ((drop 2) . showHex x . (':':)) . (dec_data xs)
           dec_data []     = (\_ -> "")

#############################################################################

enc_U8 :: Word8 -> DecS ()
enc_U8 a = 
  do x <- get
     put (a:x)
     return ()

enc_U16 :: Word16 -> DecS ()
enc_U16 a =
  do x <- get
     let b1 = fromIntegral (a `shiftR` 8) :: Word8
         b2 = fromIntegral a :: Word8
     put (b1:b2:x)

enc_U32 :: Word32 -> DecS ()
enc_U32 a =
  let b1 = fromIntegral (a `shiftR` 16) :: Word16
      b2 = fromIntegral a :: Word16
   enc_U16 b2
   enc_U16 b1

enc_U64 :: Word64 -> DecS ()
enc_U64 a =
  let b1 = fromIntegral (a `shiftR` 48) :: Word16
      b2 = fromIntegral (a `shiftR` 32) :: Word16
      b3 = fromIntegral (a `shiftR` 16) :: Word16
      b4 = fromIntegral a :: Word16
   enc_U16 b4
   enc_U16 b3
   enc_U16 b2
   enc_U16 b1

enc_I8 :: Int8 -> DecS ()
enc_I8 a =
  enc_U8 (fromIntegral a :: Word8)

enc_I16 :: Int16 -> DecS ()
enc_I16 a =
  let b1 = fromIntegral (a `shiftR` 8) :: Word8
      b2 = fromIntegral a :: Word8
  enc_U8 b2
  enc_U8 b1
 
enc_I32 :: Int32 -> DecS ()
enc_I32 a =
  let 
      b1 = fromIntegral (a `shiftR` 16) :: Word16
      b2 = fromIntegral a :: Word16
  enc_U16 b2
  enc_U16 b1

enc_DATA :: [Word8] -> DecS ()
enc_DATA d =
  do x <- get 
     put $ (reverse d) ++ x

enc_STRING :: [Word16] -> DecS ()
enc_STRING (s:ss) =
  do enc_U16 s
     enc_STRING ss

{-  do let mstr = reverse s
         putall (u:ls) =
           do enc_U8 u
              putall ls
         putall [] = return ()
      putall mstr
      enc_U8 0 -}

enc_CONSTANT :: a -> DecS ()
enc_CONSTANT _ = return ()

enc_password :: Password -> DecS ()
enc_password (p:ps) =
 (1055 * (enc_password ps)) + (fromEnum p)

{- marc???
sub enc_password {
   require Math::BigInt; # I insist on 32-bit-perl.. should use C
   # $hash must be 64 bit
   my $hash = new Math::BigInt;
   $hash = $hash * 1055 + ord for split //, $_[0];
   enc_U64 $hash;
}
-}

]]>

#############################################################################
# types
<xsl:apply-templates select="descendant::type"/>

#############################################################################
# structures
<xsl:apply-templates select="descendant::struct"/>

#############################################################################
# "less" primitive types<![CDATA[

dec_TREE
enc_TREE

]]>

#############################################################################
# messages
data KGS_server_msg = 
  KGS_server_msg_null
<xsl:for-each select="descendant::message[@src='server']">
  | KGS_server_<xsl:value-of select="@name"/> {
<xsl:apply-templates select="member" mode="decl"/>
  <xsl:text>    }</xsl:text>
</xsl:for-each>

data KGS_client_msg =
  KGS_server_msg_null
<xsl:for-each select="descendant::message[@src='client']">
  | KGS_client_<xsl:value-of select="@name"/> {
<xsl:apply-templates select="member" mode="decl"/>
  <xsl:text>    }</xsl:text>
</xsl:for-each>

<xsl:apply-templates select="descendant::message"/>
}

1;
</xsl:template>

<xsl:template match="type[@type = 'S']">
type <xsl:value-of select="@name"/> = String

-- decode UCS-2 string of length <xsl:value-of select="@length"/>
-- the first 0 terminates the string, but not the field
dec_<xsl:value-of select="@name"/> :: DecS String
dec_<xsl:value-of select="@name"/> = 
  do getS <xsl:value-of select="@length"/>
  where 
--    getS ls 0 = reverse ls
    getS ls 0 = reverse (map (\c -> toEnum (fromIntegral c :: Int)) ls)
    getS ls n = dec_U8 >>=\c getS (c:[]) (n-1)

-- likewise, encode as UCS-2, fill space with 0
enc_<xsl:value-of select="@name"/> :: String -> DecS ()
enc_<xsl:value-of select="@name"/> str = 
  do let rlen = (length str) - <xsl:value-of select="@length"/>
     putS str
     putN rlen
  where
    putN 0      = return ()
    putN n      = enc_U8 0 n-1
    putS []     = return ()
    putS (c:cs) = do enc_U8 c
                     putS cs
</xsl:template>

<xsl:template match="type[@type = 'A']">
type <xsl:value-of select="@name"/> = String

-- decode ASCII string of length <xsl:value-of select="@length"/>
-- the first 0 terminates the string, but not the field
dec_<xsl:value-of select="@name"/> :: DecS String
dec_<xsl:value-of select="@name"/> = 
  do getS <xsl:value-of select="@length"/>
  where 
    getS ls 0 = reverse (map (\c -> toEnum (fromIntegral c :: Int)) ls)
--    getS (0:ls) n = getS (0:ls) (n-1)
    getS ls n = dec_U8 >>=\c getS (c:[]) (n-1)

-- likewise, encode as ASCII, fill space with 0
enc_<xsl:value-of select="@name"/> :: String -> DecS ()
enc_<xsl:value-of select="@name"/> str = 
  do let rlen = (length str) - <xsl:value-of select="@length"/>
     putS str
     putN rlen
  where
    putN 0      = return ()
    putN n      = enc_U8 0 n-1
    putS []     = return ()
    putS (c:cs) = do enc_U8 c
                     putS cs
</xsl:template>

<xsl:template match="type[@multiplier]">
type <xsl:value-of select="@name"/> = Float

dec_<xsl:value-of select="@name"/> = do
   n &lt;- dec_<xsl:value-of select="@type"/>
   return $ n * (1 / <xsl:value-of select="@multiplier"/>)

enc_<xsl:value-of select="@name"/> n =
   enc_<xsl:value-of select="@type"/> $ n * <xsl:value-of select="@multiplier"/>

<xsl:text>
</xsl:text>
</xsl:template>

<xsl:template match="member[@array = 'yes']" mode="dec">
   $r->{<xsl:value-of select="@name"/>} = (my $array = []);
   while (length $data) {
      push @$array, dec_<xsl:value-of select="@type"/>
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="@value"/>;
   }
</xsl:template>

<xsl:template match="member" mode="dec">
   <xsl:if test="@guard-cond">
      <xsl:text>   if </xsl:text><xsl:value-of select="@guard-member"/><xsl:text> </xsl:text> <xsl:value-of select="@guard-cond"/> then do
      </xsl:if>
   <xsl:text>   </xsl:text><xsl:value-of select="@name"/> &lt;- dec_<xsl:value-of select="@type"/>
<xsl:text>
</xsl:text>
</xsl:template>

<xsl:template match="member" mode="enc">
   <xsl:text>   enc_</xsl:text><xsl:value-of select="@type"/> $ <xsl:value-of select="@name"/> s
</xsl:template>

<xsl:template match="member" mode="decl">
   <xsl:text>      </xsl:text><xsl:value-of select="@name"/> ::	<xsl:value-of select="@type"/>
<xsl:text>
</xsl:text>
</xsl:template>

<xsl:template match="struct">
data KGS_<xsl:value-of select="@name"/> = KGS_<xsl:value-of select="@name"/>
    {
<xsl:apply-templates select="member" mode="decl"/>
    }

dec_<xsl:value-of select="@name"/> = do
<xsl:apply-templates select="member" mode="dec"/>
   return $ KGS_<xsl:value-of select="@name"/><xsl:for-each select="member"><xsl:text> </xsl:text><xsl:value-of select="@name"/></xsl:for-each>

enc_<xsl:value-of select="@name"/> s =
<xsl:apply-templates select="member" mode="enc"/>
<xsl:text>
</xsl:text>
</xsl:template>

<xsl:template match="message">
-- <xsl:value-of select="@name"/>
dec_<xsl:value-of select="@src"/>_<xsl:value-of select="@type"/> = do
<xsl:apply-templates select="member" mode="dec"/>
   return $ KGS_<xsl:value-of select="@name"/><xsl:for-each select="member"><xsl:text> </xsl:text><xsl:value-of select="@name"/></xsl:for-each>

enc_<xsl:value-of select="@src"/>_<xsl:value-of select="@name"/> =
   enc_U16 0x<xsl:value-of select="@type"/>
<xsl:apply-templates select="member" mode="enc"/>

</xsl:template>

<xsl:template match="text()">
</xsl:template>

</xsl:stylesheet>

