use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Digest::GOST'); }
BEGIN { use_ok('Digest::GOST::CryptoPro'); }

diag "Testing Digest::GOST $Digest::GOST::VERSION";

done_testing;
