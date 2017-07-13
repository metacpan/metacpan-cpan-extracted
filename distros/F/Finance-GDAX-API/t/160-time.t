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
    
$time->debug(0); # We're using production system for this since no signing is required.

ok (my $result = $time->get, 'can get current time');
is (ref $result, 'HASH', 'get returns hash');
ok (defined $$result{iso}, 'ISO time key defined');
ok (defined $$result{epoch}, 'epoch time defined');

done_testing();
