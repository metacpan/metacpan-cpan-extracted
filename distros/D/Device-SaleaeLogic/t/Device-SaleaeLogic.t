use Test::More;
if ($^O =~ /linux|darwin/i) {
    plan skip_all => "Linux SDK API has problems";
}
use_ok('Device::SaleaeLogic');

my $sl = new_ok('Device::SaleaeLogic');
can_ok($sl, 'DESTROY');
can_ok($sl, 'begin');
can_ok($sl, 'get_channel_count');
can_ok($sl, 'get_sample_rate');
can_ok($sl, 'set_sample_rate');
can_ok($sl, 'is_usb2');
can_ok($sl, 'is_streaming');
can_ok($sl, 'get_supported_sample_rates');
can_ok($sl, 'is_logic');
can_ok($sl, 'is_logic16');
can_ok($sl, 'get_device_id');
undef $sl;
done_testing();
