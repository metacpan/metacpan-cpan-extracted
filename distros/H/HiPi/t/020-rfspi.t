#!perl

use Test::More tests => 12;
use HiPi qw( :rpi );
use HiPi::RaspberryPi;
use Time::HiRes;

my $sleepwait = 1000;

SKIP: {
        skip 'not in dist testing', 12 unless $ENV{HIPI_MODULES_DIST_TEST_RFSPI};

diag('SPI RF tests are running');
    
use_ok( HiPi::Energenie );

my $handler = HiPi::Energenie->new(
    board      => 'ENER314_RT',
    devicename => '/dev/spidev0.1',
);

my $val = $handler->process_request(
    command         => 'query',
    sensor_key      => '0004-0001-000A54',
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
    sensor_key      => '0004-0002-000E08',
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

is( $handler->switch_socket( 0x0C976E, 2, 1 ), undef ,'socket on');
sleep 2;
is( $handler->switch_socket( 0x0C976E, 2, 0 ), undef ,'socket off');

} # End SKIP

1;
