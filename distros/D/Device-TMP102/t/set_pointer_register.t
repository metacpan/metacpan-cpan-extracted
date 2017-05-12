#!/perl
use strict;
use warnings;

use Test::More;

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
  unless ( -r '/dev/i2c-1' ) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests only work on a system with /dev/i2c-1');
  }
}

use Device::Temperature::TMP102;

ok( my $dev = Device::Temperature::TMP102->new( I2CBusDevicePath => '/dev/i2c-1' ),
    "Creating a new Device::Temperature::TMP102 object"
);

ok( $dev->_set_pointer_register(),
    "Calling _set_pointer_register()"
);

done_testing;

