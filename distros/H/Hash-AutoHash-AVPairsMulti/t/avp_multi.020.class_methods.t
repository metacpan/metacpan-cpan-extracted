use lib qw(t);
use Carp;
use Test::More;
use Test::Deep;
use autohashUtil;
use Hash::AutoHash::AVPairsMulti;

test_class_methods('Hash::AutoHash::AVPairsMulti','autohash_set');

done_testing();
