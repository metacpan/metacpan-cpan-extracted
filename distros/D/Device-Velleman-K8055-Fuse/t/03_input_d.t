use Test::More tests => 8;
use Device::Velleman::K8055::Fuse;
use Data::Dumper;

open FILE, "< t/pathToDevice.txt" || die "Unable to open file!$!";
ok( my $pathToDevice= <FILE>, "Get device path for test" );
close FILE;

open FILE, "< t/testHarness.txt" || die "Unable to open file!$!";
ok( my $testHarness= <FILE>, "Get test harness flag" );
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
             skip "testHarness", 6 if $testHarness;

	ok( $dev->ReadDigitalChannel(1) >= 0, "3 Digital Channel 1" );
	ok( $dev->ReadDigitalChannel(2) >= 0, "4 Digital Channel 2" );
	ok( $dev->ReadDigitalChannel(3) >= 0, "5 Digital Channel 3" );
	ok( $dev->ReadDigitalChannel(4) >= 0, "6 Digital Channel 4" );
	ok( $dev->ReadDigitalChannel(5) >= 0, "7 Digital Channel 5" );
	ok( $dev->ReadAllDigital(),           "8 All Digital" );
}



