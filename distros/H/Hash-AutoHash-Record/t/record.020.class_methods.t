use lib qw(t);
use Carp;
use Test::More;
use Test::Deep;
use recordUtil;
use Hash::AutoHash::Record;

test_class_methods('Hash::AutoHash::Record','autohash_set');

done_testing();
