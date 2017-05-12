use lib qw(t);
use strict;
use Carp;
use Test::More;
use Test::Deep;
use autohashUtil;
use Hash::AutoHash;

test_class_methods('Hash::AutoHash','autohash_set');

done_testing();
