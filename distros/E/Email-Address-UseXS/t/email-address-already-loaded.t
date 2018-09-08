use strict;
use warnings;

use Test::More;
use Test::Fatal;

like(exception {
    require Email::Address;
    require Email::Address::UseXS;
}, qr/Must load (\S+) before Email::Address/, 'detects Email::Address loaded in wrong order');

done_testing;

