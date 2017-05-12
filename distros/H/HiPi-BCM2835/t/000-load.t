#!perl

use Test::More tests => 3;

BEGIN {
    use_ok( 'HiPi::BCM2835' );
    use_ok( 'HiPi::BCM2835::I2C' );
    use_ok( 'HiPi::BCM2835::Pin' );
}

1;
