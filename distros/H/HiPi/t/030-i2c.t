#!perl

use Test::More tests => 93;
use HiPi qw( :rpi :i2c );
use HiPi::RaspberryPi;
use Time::HiRes;

my $sleepwait = 1000;

SKIP: {
        skip 'not in dist testing', 93 unless $ENV{HIPI_MODULES_DIST_TEST_I2C};
        
        diag('I2C tests are running');
        use_ok( HiPi::Device::I2C );
        use_ok( HiPi::Interface::MPL3115A2 );
        use_ok( HiPi::Interface::MCP23017 );
        
        my $mcpaddress = 0x20;
        my $mpladdress = 0x60;
        
        my $driver = HiPi::Device::I2C->get_driver;
        like( $driver, qr/^i2c_bcm2708|i2c_bcm2835$/, 'known driver types');
        is( (HiPi::Device::I2C->get_device_list)[0], '/dev/i2c-1', 'get device list');
        is( HiPi::Device::I2C->get_baudrate, 100_000, 'get baud rate');
        is( HiPi::Device::I2C->get_combined, ( $driver eq 'i2c_bcm2835') ? 'Y' : 'N', 'combined');
        
        my $i2c = HiPi::Device::I2C->new;
        
        is( ($i2c->scan_bus(I2C_SCANMODE_AUTO, $mcpaddress, $mcpaddress ))[0], $mcpaddress, 'scan bus mcp');
        is( ($i2c->scan_bus(I2C_SCANMODE_AUTO, $mpladdress, $mpladdress ))[0], $mpladdress, 'scan bus mpl');
        
        ok( $i2c->check_address($mcpaddress),  'check address mcp' );
        ok( $i2c->check_address($mpladdress),  'check address mpl' );
        ok( $i2c->check_address(2) == 0,  'scan bus fail' );
        
        my $mpl = HiPi::Interface::MPL3115A2->new( address => $mpladdress );
        is( $mpl->who_am_i, 196, 'mpl who am i');
        
        for my $busmode ( qw( smbus i2c ) ) {
        
            my $mcp = HiPi::Interface::MCP23017->new( address => $mcpaddress, backend => $busmode );
            is( $mcp->device->busmode, $busmode, qq(mcp busmode is $busmode));
            
            my @lowbits =  (0,0,0,0,0,0,0,0);
            my @highbits = (1,1,1,1,1,1,1,1);
            my @oddbits  = (0,1,0,1,0,1,0,1);
            my @evenbits = (1,0,1,0,1,0,1,0);
            
            # set all pins output        
            $mcp->write_register_bits('IODIRA', @lowbits, @lowbits );
            
            # set some values
            $mcp->write_register_bits('OLATA',  @oddbits, @evenbits);
            
            # read them back 1 by 1
            my @offpins = ( qw( A0 A2 A4 A6 B1 B3 B5 B7) );
            my @onpins  = ( qw( A1 A3 A5 A7 B0 B2 B4 B6) );
            
            for my $pinname ( @offpins ) {
                is($mcp->pin_value($pinname), 0, qq(mode $busmode pin_value $pinname));
            }
            
            for my $pinname ( @onpins ) {
                is($mcp->pin_value($pinname), 1, qq(mode $busmode pin_value $pinname));
            }
            
            # write a value to an off bank B pin and check that all bank values preserved
            is( $mcp->pin_value('B3'), 0 , qq(mode $busmode checking B3 initial value));
            $mcp->pin_value('B3', 1);
            is(($mcp->read_register_bytes('GPIOB', 1))[0], 0b01011101, qq(mode $busmode checking B3 changed value by register));
            is( $mcp->pin_value('B3'), 1 , qq(mode $busmode checking B3 changed value by pin));
            
            is( $mcp->pin_value('B1'), 0 , qq(mode $busmode checking B1 initial value));
            $mcp->pin_value('B1', 1);
            is(($mcp->read_register_bytes('GPIOB', 1))[0], 0b01011111, qq(mode $busmode checking B1 changed value by register));
            is( $mcp->pin_value('B1'), 1 , qq(mode $busmode checking B1 changed value by pin));
            
            is( $mcp->pin_value('B5'), 0 , qq(mode $busmode checking B5 initial value));
            $mcp->pin_value('B5', 1);
            is(($mcp->read_register_bytes('GPIOB', 1))[0], 0b01111111, qq(mode $busmode checking B5 changed value by register));
            is( $mcp->pin_value('B5'), 1 , qq(mode $busmode checking B5 changed value by pin));
            
            is( $mcp->pin_value('B7'), 0 , qq(mode $busmode checking B7 initial value));
            $mcp->pin_value('B7', 1);
            is(($mcp->read_register_bytes('GPIOB', 1))[0], 0b11111111, qq(mode $busmode checking B7 changed value by register));
            is( $mcp->pin_value('B7'), 1 , qq(mode $busmode checking B7 changed value by pin));
            
            is( $mcp->pin_value('B0'), 1 , qq(mode $busmode checking B0 initial value));
            $mcp->pin_value('B0', 0);
            is(($mcp->read_register_bytes('GPIOB', 1))[0], 0b11111110, qq(mode $busmode checking B0 changed value by register));
            is( $mcp->pin_value('B0'), 0 , qq(mode $busmode checking B0 changed value by pin));
            
            is( $mcp->pin_value('B2'), 1 , qq(mode $busmode checking B2 initial value));
            $mcp->pin_value('B2', 0);
            is(($mcp->read_register_bytes('GPIOB', 1))[0], 0b11111010, qq(mode $busmode checking B2 changed value by register));
            is( $mcp->pin_value('B2'), 0 , qq(mode $busmode checking B2 changed value by pin));
            
            is( $mcp->pin_value('B4'), 1 , qq(mode $busmode checking B4 initial value));
            $mcp->pin_value('B4', 0);
            is(($mcp->read_register_bytes('GPIOB', 1))[0], 0b11101010, qq(mode $busmode checking B4 changed value by register));
            is( $mcp->pin_value('B4'), 0 , qq(mode $busmode checking B4 changed value by pin));
            
            is( $mcp->pin_value('B6'), 1 , qq(mode $busmode checking B6 initial value));
            $mcp->pin_value('B6', 0);
            is(($mcp->read_register_bytes('GPIOB', 1))[0], 0b10101010, qq(mode $busmode checking B6 changed value by register));
            is( $mcp->pin_value('B6'), 0 , qq(mode $busmode checking B6 changed value by pin));
            
            $mcp->write_register_bits('OLATA',  @lowbits);
            $mcp->write_register_bits('OLATB',  @lowbits);
        }
        

} # End SKIP

1;
