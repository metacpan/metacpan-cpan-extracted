# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Device-Aurora.t'

#########################

use strict;
use warnings;

use Test::More tests => 29;
use Test::Device::SerialPort;

BEGIN { use_ok('Device::Inverter::Aurora') };

#########################

{
	no warnings 'once';
	# Patch on the fly - Test::Device::SerialPort is missing this method
	*Test::Device::SerialPort::datatype = sub {
		my ($self, $arg) = @_;
		$self->{datatype} = $arg if defined $arg;
		return $self->{datatye};
	};
	# Let Device::Inverter::Aurora know it's testing
	$Device::Inverter::Aurora::TEST = 1;
}

# Most tests can be summarised in a simple but large array.
my @tests = (
	['commCheck',              "\x02\x3a\x00\x20\x20\x20\x20\x20\xc9\x59", "\x00\x06\x49\x4b\x4e\x4e\x1f\x7b", 1],
	['getState',               "\x02\x32\x00\x20\x20\x20\x20\x20\x25\x87", "\x00\x06\x02\x07\x02\x00\xd4\x4a", {
		globalState       => [6, 'Run'],
		inverterState     => [2, 'Run'],
		channel1DCDCState => [7, 'Input Low'],
		channel2DCDCState => [2, 'MPPT'],
		alarmState        => [0, 'No Alarm']
	}],
	['getLastAlarms',          "\x02\x56\x00\x20\x20\x20\x20\x20\xd6\x4c", "\x00\x06\x00\x00\x00\x00\x17\xcc", [
		([0, 'No Alarm'])x4
	]],
	['getPartNumber',          "\x02\x34\x00\x20\x20\x20\x20\x20\xe8\xdf", "\x2d\x31\x32\x33\x34\x2d\xce\xaf", '-1234-'],
	['getSerialNumber',        "\x02\x3F\x00\x20\x20\x20\x20\x20\x6a\xa9", "\x31\x32\x33\x34\x35\x36\x72\xe6", '123456'],
	['getVersion',             "\x02\x3a\x00\x2e\x20\x20\x20\x20\x71\x38", "\x00\x06\x49\x4b\x4e\x4e\x1f\x7b", {
		model             => [73, 'Aurora 3.6 kW indoor'],
		regulation        => [75, 'AS 4777'],
		transformer       => [78, 'transformerless'],
		type              => [78, 'photovoltic'],
	}],
	['getManufactureDate',     "\x02\x41\x00\x20\x20\x20\x20\x20\x07\x3e", "\x00\x06\x30\x31\x31\x30\x6e\xc2", {
		year              => '10',
		month             => '01',
	}],
	['getFirmwareVersion',     "\x02\x48\x00\x20\x20\x20\x20\x20\x3e\x7f", "\x00\x06\x63\x31\x32\x33\x46\x2a", 'c.1.2.3'],
	['getConfiguration',       "\x02\x4d\x00\x20\x20\x20\x20\x20\x9d\x8f", "\x00\x06\x00\x00\x00\x00\x17\xcc", [
		0,
		'System operating with both strings.'
	]],
	['getDailyEnergy',         "\x02\x4e\x00\x00\x20\x20\x20\x20\x62\x47", "\x00\x06\x00\x00\x30\x39\xf7\xd6", '12345'],
	['getWeeklyEnergy',        "\x02\x4e\x01\x00\x20\x20\x20\x20\x49\x43", "\x00\x06\x00\x01\x51\x8f\x1b\x20", '86415'],
	['getMonthlyEnergy',       "\x02\x4e\x03\x00\x20\x20\x20\x20\x1f\x4b", "\x00\x06\x00\x05\xa6\xae\xf1\x42", '370350'],
	['getYearlyEnergy',        "\x02\x4e\x04\x00\x20\x20\x20\x20\xce\x57", "\x00\x06\x00\x44\xc1\x45\xdb\x6f", '4505925'],
	['getTotalEnergy',         "\x02\x4e\x05\x00\x20\x20\x20\x20\xe5\x53", "\x00\x06\x19\xc8\x87\x9e\xbe\x86", '432572318'],
	['getPartialEnergy',       "\x02\x4e\x06\x00\x20\x20\x20\x20\x98\x5f", "\x00\x06\x00\x52\x81\x86\x66\x8e", '5407110'],
	['getFrequency',           "\x02\x3b\x04\x00\x20\x20\x20\x20\x21\xb6", "\x00\x06\x42\x47\xf1\xab\xac\x17", '49.9860038757324'],
	['getGridVoltage',         "\x02\x3b\x01\x00\x20\x20\x20\x20\xa6\xa2", "\x00\x06\x43\x6a\xe0\xfd\xa9\x4c", '234.878860473633'],
	['getGridCurrent',         "\x02\x3b\x02\x00\x20\x20\x20\x20\xdb\xae", "\x00\x06\x3f\x6d\x5d\xad\x4e\xd5", '0.927210628986359'],
	['getGridPower',           "\x02\x3b\x03\x00\x20\x20\x20\x20\xf0\xaa", "\x00\x06\x42\x93\x61\xd8\x83\xa3", '73.6911010742188'],
	['getInput1Voltage',       "\x02\x3b\x17\x00\x20\x20\x20\x20\xec\xf8", "\x00\x06\x42\x81\xd2\xb0\xe6\x6c", '64.9114990234375'],
	['getInput1Current',       "\x02\x3b\x19\x00\x20\x20\x20\x20\x4e\xc1", "\x00\x06\x3c\x99\xba\x86\x96\x24", '0.0187656991183758'],
	['getInput2Voltage',       "\x02\x3b\x1a\x00\x20\x20\x20\x20\x33\xcd", "\x00\x06\x43\x89\xa4\xd7\x32\x05", '275.287811279297'],
	['getInput2Current',       "\x02\x3b\x1b\x00\x20\x20\x20\x20\x18\xc9", "\x00\x06\x3e\xc2\x09\x17\xa3\x22", '0.378975600004196'],
	['getInverterTemperature', "\x02\x3b\x15\x00\x20\x20\x20\x20\xba\xf0", "\x00\x06\x42\x7c\x0f\xde\x96\x7a", '63.015495300293'],
	['getBoosterTemperature',  "\x02\x3b\x16\x00\x20\x20\x20\x20\xc7\xfc", "\x00\x06\x42\x60\x74\xbb\x67\x7a", '56.1139945983887'],
);

# Lets test what we can and can't do
can_ok('Device::Inverter::Aurora', 'crc', map {$_->[0]} @tests);

my $obj = new Device::Inverter::Aurora();
isa_ok $obj, 'Device::Inverter::Aurora';

isa_ok $obj->{port}, 'Test::Device::SerialPort';
$obj->{port}->set_test_mode_active(1);
$obj->{port}->{_no_random_data} = 1;

for my $test (@tests) {
	my $func = $test->[0];
	my $result;

	subtest "Test function $func" => sub {
		plan tests => 3;

		# Inject the reply into the port
		$obj->{port}->lookclear($test->[2]);

		# Execute the function
		ok $result = $obj->$func(), "Function called";

		# Compare the tx buffer on the port with the expected value
		cmp_ok $obj->{port}->{_tx_buf}, 'eq', $test->[1], 'Expected TX';
		$obj->{port}->{_tx_buf} = '';

		# Compare the result of the function with expected results
		if (ref $test->[3] || $test->[3] =~ /^c/ || $test->[3] !~ /\./) {
			# For everything that isn't a float
			is_deeply $result, $test->[3], 'Expected return';
		}
		else {
			#Floats
			cmp_ok sprintf('%0.8f', $result), 'eq', sprintf('%0.8f', $test->[3]), 'Expected return';
		}
	}
}
