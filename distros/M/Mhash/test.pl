BEGIN { $| = 1; print "1..26\n"; }
END {print "not ok 1\n" unless $loaded;}
use Mhash;
my $CRC32, $CRC32_HMAC, $MD5, $MD5_HMAC, $SHA1, $SHA1_HMAC, $HAVAL256, $HAVAL256_HMAC, $RIPEMD160, $RIPEMD160_HMAC, $TIGER, $TIGER_HMAC, $GOST, $GOST_HMAC, $CRC32B, $CRC32B_HMAC, $HAVAL224, $HAVAL224_HMAC, $HAVAL192, $HAVAL192_HMAC, $HAVAL160, $HAVAL160_HMAC ;

$CRC32          = "1ebece79" ;
$CRC32_HMAC     = "f3c1e628" ;
$MD5            = "d03cb659cbf9192dcd066272249f8412" ;
# HMAC(MD5) should be 750c783e6ab0b503eaa86e310a5db738 according to RFC 2104.
$MD5_HMAC       = "750c783e6ab0b503eaa86e310a5db738" ;
$SHA1           = "8f820394f95335182045da24f34de52bf8bc3432" ;
$SHA1_HMAC      = "effcdf6ae5eb2fa2d27416d5f184df9c259a7c79" ;
$HAVAL256       = "809ae6159a0c95bfea5bba88dc7b0b8a8064295990bacf51941e87f8bac751ba" ;
$HAVAL256_HMAC  = "1486e7a244de991e369b24177655dd209cd092603774d119a7341a3f1664b069" ;
$RIPEMD160      = "a196884228dbeac5115327b2374711cc84b77a4d" ;
$RIPEMD160_HMAC = "dda6c0213a485a9e24f4742064a7f033b43c4069" ;
$TIGER          = "0695d88720e3c513c4dee399f8299201ac915f5cf32fc1fa" ;
$TIGER_HMAC     = "8fdc0a1909824780b42feee8ff568d01e60fe10ccc6d2259" ;
$GOST           = "4a844e7b6e94cd8f223733952544f6404d898b0b9b4e364d8f5251d7921d7139" ;
$GOST_HMAC      = "f21d212cec23fa36bd729ba41207e1e9dac81f3672aa6a8e3e739612a25c10b8" ;
$CRC32B         = "6c0ac76b" ;
$CRC32B_HMAC    = "de879ff8" ;
$HAVAL224       = "cfd5bd1cc4e39ddadf31caa6d8b4f2deacdfa94a6a156bf73313e627" ;
$HAVAL224_HMAC  = "402360f4d8e13cbffbf97229d62d4dd71f2b316c2a2aa8af53a7444f" ;
$HAVAL192       = "1f7049624ed69a584ee120047a34a57f1e8975dc33e865c7" ;
$HAVAL192_HMAC  = "5a15d0efe0fc532d383132965aaed65ac81c97978cfa3638" ;
$HAVAL160       = "1a74c214b10fa8f091580bd78261fc2dea56e4db" ;
$HAVAL160_HMAC  = "3c08cd84a4cf016876d7bdae17cb96161fcbd24a" ;

my $la ;
my $key = "Jefe" ;
my $data = "what do ya want for nothing?" ;

$loaded = 1;
print "ok 1\n";
# CRC32
print "not " unless (mhash_hex(Mhash::MHASH_CRC32, $data) eq $CRC32 );
print "ok 2\n" ;
# MD5
print "not " unless (mhash_hex(Mhash::MHASH_MD5, $data) eq $MD5 ) ;
print "ok 3\n" ;
# SHA1
print "not " unless (mhash_hex(Mhash::MHASH_SHA1, $data) eq $SHA1 ) ;
print "ok 4\n" ;
# HAVAL256
print "not " unless (mhash_hex(Mhash::MHASH_HAVAL256, $data) eq $HAVAL256 ) ; 
print "ok 5\n" ;
# RIPEMD160
print "not " unless (mhash_hex(Mhash::MHASH_RIPEMD160, $data) eq $RIPEMD160 ) ; 
print "ok 6\n" ;
# TIGER
print "not " unless (mhash_hex(Mhash::MHASH_TIGER, $data) eq $TIGER ) ; 
print "ok 7\n" ;
# GOST
print "not " unless (mhash_hex(Mhash::MHASH_GOST, $data) eq $GOST ) ; 
print "ok 8\n" ;
# CRC32B
print "not " unless (mhash_hex(Mhash::MHASH_CRC32B, $data) eq $CRC32B ) ; 
print "ok 9\n" ;
# HAVAL224
print "not " unless (mhash_hex(Mhash::MHASH_HAVAL224, $data) eq $HAVAL224 ) ; 
print "ok 10\n" ;
# HAVAL192
print "not " unless (mhash_hex(Mhash::MHASH_HAVAL192, $data) eq $HAVAL192 ) ; 
print "ok 11\n" ;
# HAVAL160
print "not " unless (mhash_hex(Mhash::MHASH_HAVAL160, $data) eq $HAVAL160 ) ; 
print "ok 12\n" ;
# CRC32 HMAC
print "not " unless (mhash_hmac_hex(Mhash::MHASH_CRC32, $data, $key) eq $CRC32_HMAC );
print "ok 13\n" ;
# MD5 HMAC
print "not " unless (mhash_hmac_hex(Mhash::MHASH_MD5, $data, $key) eq $MD5_HMAC );
print "ok 14\n" ;
# SHA1 HMAC
print "not " unless (mhash_hmac_hex(Mhash::MHASH_SHA1, $data, $key) eq $SHA1_HMAC );
print "ok 15\n" ;
# HAVAL256 HMAC
print "not " unless (mhash_hmac_hex(Mhash::MHASH_HAVAL256, $data, $key) eq $HAVAL256_HMAC );
print "ok 16\n" ;
# RIPEMD160 HMAC
print "not " unless (mhash_hmac_hex(Mhash::MHASH_RIPEMD160, $data, $key) eq $RIPEMD160_HMAC );
print "ok 17\n" ;
# TIGER HMAC
print "not " unless (mhash_hmac_hex(Mhash::MHASH_TIGER, $data, $key) eq $TIGER_HMAC );
print "ok 18\n" ;
# GOST HMAC
print "not " unless (mhash_hmac_hex(Mhash::MHASH_GOST, $data, $key) eq $GOST_HMAC );
print "ok 19\n" ;
# CRC32B HMAC
print "not " unless (mhash_hmac_hex(Mhash::MHASH_CRC32B, $data, $key) eq $CRC32B_HMAC );
print "ok 20\n" ;
# HAVAL224 HMAC
print "not " unless (mhash_hmac_hex(Mhash::MHASH_HAVAL224, $data, $key) eq $HAVAL224_HMAC );
print "ok 21\n" ;
# HAVAL192 HMAC
print "not " unless (mhash_hmac_hex(Mhash::MHASH_HAVAL192, $data, $key) eq $HAVAL192_HMAC );
print "ok 22\n" ;
# HAVAL160 HMAC
print "not " unless (mhash_hmac_hex(Mhash::MHASH_HAVAL160, $data, $key) eq $HAVAL160_HMAC );
print "ok 23\n" ;
# mhash_get_block_size
print "not " unless (mhash_get_block_size(Mhash::MHASH_MD5) == 16 );
print "ok 24\n" ;
# mhash_get_hash_name
print "not " unless (mhash_get_hash_name(Mhash::MHASH_MD5) eq "MD5" );
print "ok 25\n" ;
# mhash_count
print "not " unless (mhash_count() > 0 );
print "ok 26\n" ;
