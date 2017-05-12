use Test::More tests => 4;
BEGIN { use_ok( 'Device::Blkid::E2fsprogs', ':funcs' ) };

#########################

# Check for valid/invalid return values
$sz = get_dev_size("t/img/ext3.fs");
is   ($sz, 1048576,        'Check get_dev_size against correct size');
isnt ($sz, 12345,          'Check get_dev_size against incorrect size');

# Ensure proper exception propogation from package
local $@;
$sz = eval { get_dev_size("t/img/badpath.fs") };
if ($@) {
    pass('Check invalid file path');
}