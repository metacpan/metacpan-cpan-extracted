# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

BEGIN { $| = 1; print "1..14\n"; }
END {print "not ok 1\n" unless $loaded;}
use MCrypt;
my $CBC, $CBC_iv, $OFB, $CFB, $ECB, $enc_hex, $dec_hex ;
$CBC    = "afb7bf8cb2c08bad" ;
$CBC_iv = "7dc3540223f48c91" ;
$OFB    = "d211ff66f55d6bec" ;
$CFB    = "d265135d5a874fa1" ;
$ECB    = "afb7bf8cb2c08bad" ;
my $key = "key" ;
my $block = "block" ;
my $IV = "12345678" ;
$loaded = 1;
print "ok 1\n";

# mcrypt_get_key_size
print "not " unless (mcrypt_get_key_size(MCrypt::MCRYPT_3DES) == 24);
print "ok 2\n" ;
# mcrypt_get_block_size
print "not " unless (mcrypt_get_block_size(MCRYPT_3DES) == 8) ;
print "ok 3\n" ;
# mcrypt_get_cipher_name
print "not " unless (mcrypt_get_cipher_name(MCrypt::MCRYPT_3DES) =~ /^3des$/i) ;
print "ok 4\n" ;
# ################################################## 
# ENCRYPT mcrypt_get_cbc
$enc_hex = mcrypt_cbc_hex(MCrypt::MCRYPT_3DES, $key, $block, MCrypt::MCRYPT_ENCRYPT) ;
print "not " unless ($enc_hex eq $CBC ) ; 
print "ok 5\n" ;
# DECRYPT mcrypt_get_cbc
$dec_hex = mcrypt_cbc_hex(MCrypt::MCRYPT_3DES, $key, $enc_hex, MCrypt::MCRYPT_DECRYPT) ;
print "not " unless ($dec_hex eq $block ) ; 
print "ok 6\n" ;
# ENCRYPT mcrypt_get_cbc with optional IV
$enc_hex = mcrypt_cbc_hex(MCrypt::MCRYPT_3DES, $key, $block, MCrypt::MCRYPT_ENCRYPT, $IV) ;
print "not " unless ($enc_hex eq $CBC_iv ) ; 
print "ok 7\n" ;
# DECRYPT mcrypt_cbc with optional IV
$dec_hex = mcrypt_cbc_hex(MCrypt::MCRYPT_3DES, $key, $enc_hex, MCrypt::MCRYPT_DECRYPT, $IV) ;
print "not " unless ($dec_hex eq $block ) ; 
print "ok 8\n" ;
# ENCRYPT mcrypt_get_ecb
$enc_hex = mcrypt_ecb_hex(MCrypt::MCRYPT_3DES, $key, $block, MCrypt::MCRYPT_ENCRYPT) ;
print "not " unless ($enc_hex eq $ECB ) ; 
print "ok 9\n" ;
# DECRYPT mcrypt_get_ecb
$dec_hex = mcrypt_ecb_hex(MCrypt::MCRYPT_3DES, $key, $enc_hex, MCrypt::MCRYPT_DECRYPT) ;
print "not " unless ($dec_hex eq $block ) ; 
print "ok 10\n" ;
# ENCRYPT mcrypt_get_ofb
$enc_hex = mcrypt_ofb_hex(MCrypt::MCRYPT_3DES, $key, $block, MCrypt::MCRYPT_ENCRYPT, $IV) ;
print "not " unless ($enc_hex eq $OFB ) ; 
print "ok 11\n" ;
# DECRYPT mcrypt_get_ofb
$dec_hex = mcrypt_ofb_hex(MCrypt::MCRYPT_3DES, $key, $enc_hex, MCrypt::MCRYPT_DECRYPT, $IV) ;
print "not " unless ($dec_hex eq $block ) ; 
print "ok 12\n" ;
# ENCRYPT mcrypt_get_cfb
$enc_hex = mcrypt_cfb_hex(MCrypt::MCRYPT_3DES, $key, $block, MCrypt::MCRYPT_ENCRYPT, $IV) ;
print "not " unless ($enc_hex eq $CFB ) ; 
print "ok 13\n" ;
# DECRYPT mcrypt_get_cfb
$dec_hex = mcrypt_cfb_hex(MCrypt::MCRYPT_3DES, $key, $enc_hex, MCrypt::MCRYPT_DECRYPT, $IV) ;
print "not " unless ($dec_hex eq $block ) ; 
print "ok 14\n" ;
