use v5.20;
use warnings;
use Test::More;
use lib qw(lib t/lib);
use GDAXTestHelper;

BEGIN {
    use_ok('Finance::GDAX::API::Time');
}

my $time = new_ok('Finance::GDAX::API::Time');
can_ok($time, 'get');
    
$time->debug(1); # Make sure this is set to 1 or you'll use live data

ok (my $result = $time->get, 'can get current time');
is (ref $result, 'HASH', 'get returns hash');
ok (defined $$result{iso}, 'ISO time key defined');
ok (defined $$result{epoch}, 'epoch time defined');

done_testing();
