use lib qw(t);
use Carp;
use Test::More;
use Test::Deep;
use autohashUtil;
use Hash::AutoHash::AVPairsSingle;

test_class_methods('Hash::AutoHash::AVPairsSingle','autohash_set');

done_testing();
