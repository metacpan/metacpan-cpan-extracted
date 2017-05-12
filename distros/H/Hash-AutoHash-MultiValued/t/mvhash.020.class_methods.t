use lib qw(t);
use Carp;
use Test::More;
use Test::Deep;
use mvhashUtil;
use Hash::AutoHash::MultiValued;

test_class_methods('Hash::AutoHash::MultiValued','autohash_set');

done_testing();
