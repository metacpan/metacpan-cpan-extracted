use Test::More;

BEGIN {
    use_ok 'Device::HID';
}

ok Device::HID::init;
Device::HID::exit;

done_testing;

