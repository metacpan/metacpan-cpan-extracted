#!perl

use Test::More tests => 18;
use HiPi qw( :rpi :mcp23017 );
use HiPi::RaspberryPi;
use Time::HiRes;
use HiPi::GPIO;
use HiPi::Interface::MCP23017;

my $sleepwait = 1000;

SKIP: {
        skip 'not in dist testing', 18 unless( $ENV{HIPI_MODULES_DIST_TEST_RFSPI_DEV_0} || $ENV{HIPI_MODULES_DIST_TEST_RFSPI_DEV_1} );

diag('SPI RF tests are running');
    
use_ok( HiPi::Energenie );

my $monitor_1 = '0004-0001-000A54';
my $adapter_1 = '0004-0002-000E08';
my $adapter_2 = '0004-0002-002BA0';

#my $reset_pin = RPI_PIN_22;
#
#my $gpio = HiPi::GPIO->new;
#$gpio->set_pin_mode( $reset_pin, RPI_MODE_OUTPUT ) if( $gpio->get_pin_mode($reset_pin) != RPI_MODE_OUTPUT );
#$gpio->pin_write($reset_pin, RPI_LOW);

my $mcp = HiPi::Interface::MCP23017->new(
    devicename => '/dev/i2c-1',
    address    => 0x20,
);

$mcp->pin_mode( MCP_PIN_A1, MCP23017_OUTPUT );

my $device_name = $ENV{HIPI_MODULES_DIST_TEST_RFSPI_DEV_0} ? '/dev/spidev0.0' : '/dev/spidev0.1';

my %handler_params = ( $ENV{HIPI_MODULES_DIST_TEST_RFSPI_HIGH_POWER} )
    ? ( backend => 'RF69HW', devicename => $device_name )
    : ( backend => 'ENER314_RT', devicename => $device_name );

my $handler = HiPi::Energenie->new(
    %handler_params,
    reset_gpio => sub {
        my $value = shift;
        $mcp->pin_value( MCP_PIN_A1, $value );
    }
);

if ($handler_params{backend} eq 'RF69HW' ) {
    diag 'RF SPI USING HIGH POWER MODULE ON ' . $handler_params{devicename};
} else {
    diag 'RF SPI USING LOW POWER MODULE ON ' . $handler_params{devicename};
}

my $val = $handler->process_request(
    command         => 'query',
    sensor_key      => $monitor_1,
);

my $data = $val->{data};

my $record = $data->records->[0];
is( $record->name, 'Real Power', 'monitor Real Power name' );


$record = $data->records->[1];
is( $record->name, 'Reactive Power', 'monitor Reactive Power name' );


$record = $data->records->[2];
is( $record->name, 'Voltage', 'monitor Voltage name' );


$record = $data->records->[3];
is( $record->name, 'Frequency', 'monitor Frequency name' );

$val = $handler->process_request(
    command         => 'query',
    sensor_key      => $adapter_1,
);

$data = $val->{data};

$record = $data->records->[0];
is( $record->name, 'Real Power', 'adapter Real Power name' );


$record = $data->records->[1];
is( $record->name, 'Reactive Power', 'adapter Reactive Power name' );


$record = $data->records->[2];
is( $record->name, 'Voltage', 'adapter Voltage name' );


$record = $data->records->[3];
is( $record->name, 'Frequency', 'adapter Frequency name' );

$record = $data->records->[4];
is( $record->name, 'Switch State', 'adapter Switch State name' );

$val = $handler->process_request(
    command         => 'switch',
    sensor_key      => $adapter_2,
    switch_state    => 1
);

is( $val->{success}, 1, 'adapter switched on' );

$record = $val->{data}->records->[-1];
is( $record->name, 'Switch State', 'adapter switched on Switch State name' );
is( $record->value, 1, 'adapter switched on value' );

sleep 2;

$val = $handler->process_request(
    command         => 'switch',
    sensor_key      => $adapter_2,
    switch_state    => 0
);

is( $val->{success}, 1, 'adapter switched off' );

$record = $val->{data}->records->[-1];
is( $record->name, 'Switch State', 'adapter switched off Switch State name' );
is( $record->value, 0, 'adapter switched off value' );

is( $handler->switch_socket( 0x0C976E, 2, 1 ), undef ,'socket on');
sleep 2;
is( $handler->switch_socket( 0x0C976E, 2, 0 ), undef ,'socket off');

} # End SKIP

1;
