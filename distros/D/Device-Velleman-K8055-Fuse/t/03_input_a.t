use Test::More tests => 5;
use Device::Velleman::K8055::Fuse;
use Data::Dumper;

open FILE, "< t/pathToDevice.txt" || die "Unable to open file!$!";
my $pathToDevice = <FILE>;
close FILE;

open FILE, "< t/testHarness.txt" || die "Unable to open file!$!";
ok( my $testHarness= <FILE>, "Setting device path for test" );
close FILE;
die "Unexpected attribute $testHarness defined by Makefile.PL" unless ($testHarness eq 'y' || $testHarness eq 'n');
$testHarness = 0 if $testHarness eq 'n';
$testHarness = 1 if $testHarness eq 'y';


my $dev = Device::Velleman::K8055::Fuse->new(
    'pathToDevice' => $pathToDevice,
	testHarness => $testHarness,
    'debug'        => 1
) || die "Failed to get an object $!";

SKIP: {
             skip "testHarness", 4 if $testHarness;

	ok( defined($dev) && ref $dev eq 'Device::Velleman::K8055::Fuse',
    'new() works' );

	ok( $dev->ReadAnalogChannel(1) >= 0 , "1 Analog Channel 1" );
	ok( $dev->ReadAnalogChannel(2) >= 0, "2 Analog Channel 2" );
	ok( $dev->ReadAllAnalog(),           "11 All Analog" );
}

