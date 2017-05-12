use Test::More tests => 2;
use Encode::Base58::GMP;
use Config;

SKIP: {
  skip "No bigint support", 2 unless $Config{use64bitint} || $Config{longsize} > 7;
  is('9235113611380768826', int decode_base58('nrkMyzsS7w7'), 'Successful bigint decode');
  is('nrkMyzsS7w7', encode_base58('9235113611380768826'), 'Successful bigint encode');  
}
