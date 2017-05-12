#!perl -T

use Test::More;

BEGIN {
    use_ok( 'Device::FTDI' ) or print "Bail out!\n";

    use_ok( 'Device::FTDI::MPSSE' ) or print "Bail out!\n";
    use_ok( 'Device::FTDI::SPI' ) or print "Bail out!\n";
    use_ok( 'Device::FTDI::I2C' ) or print "Bail out!\n";

    use_ok( 'Device::Chip::Adapter::FTDI' );
}

diag( "Testing Device::FTDI $Device::FTDI::VERSION, Perl $], $^X" );

done_testing;
