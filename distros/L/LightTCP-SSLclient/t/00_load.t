use strict;
use warnings;
use Test::More tests => 3;

use lib '../lib';

BEGIN {
    use_ok('LightTCP::SSLclient');
}

ok($LightTCP::SSLclient::VERSION, "VERSION is defined: $LightTCP::SSLclient::VERSION");

cmp_ok($LightTCP::SSLclient::VERSION, '>=', 1.03, "VERSION is 1.03 or higher for keep-alive support");
