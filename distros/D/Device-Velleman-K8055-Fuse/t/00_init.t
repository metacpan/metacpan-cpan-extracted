use Test::More tests => 15;
use Data::Dumper;

use_ok( Device::Velleman::K8055::Fuse,
    "Device::Velleman::K8055::Fuse availability" );

open FILE, "< t/pathToDevice.txt" || die "Unable to open file!$!";
ok( my $pathToDevice = <FILE>, "Setting device path for test" );
close FILE;

open FILE, "< t/testHarness.txt" || die "Unable to open file!$!";
ok( my $testHarness= <FILE>, "Setting device path for test" );
close FILE;
die "Unexpected attribute $testHarness defined by Makefile.PL" unless ($testHarness eq 'y' || $testHarness eq 'n');
$testHarness = 0 if $testHarness eq 'n';
$testHarness = 1 if $testHarness eq 'y';

my $feedback = '';
my $newArgs   = {
    pathToDevice => $pathToDevice,
    testHarness => $testHarness,
    debug        => 1,
    initDevice   => { pathToDevice => $pathToDevice, fuseArgs => 'nonempty' },
};

opendir(DIR,$pathToDevice) || die "Cant opendir $pathToDevice: $!";
my @commandList = readdir(DIR);
closedir(DIR);

if ( scalar @commandList > 5 ) {
    $feedback = ' in test mode. Device already activated';
    $newArgs->{initDevice}->{test} = 1;
} else {
    $feedback = '... Device activation succesful.';
}

$dev = Device::Velleman::K8055::Fuse->new(%$newArgs)
  || die "Failed to get an object $!";

ok( defined($dev) && ref $dev eq 'Device::Velleman::K8055::Fuse',
    'new() works' . $feedback );

ok( $myPathToDevice = $dev->{'pathToDevice'}, "path to device succesfully set" );

ok( -e "$myPathToDevice/analog_in1" || $testHarness,  "analog_in1" );
ok( -e "$myPathToDevice/analog_in2" || $testHarness,  "analog_in2" );
ok( -e "$myPathToDevice/analog_out1" || $testHarness, "analog_out1" );
ok( -e "$myPathToDevice/analog_out2" || $testHarness, "analog_out2" );
ok( -e "$myPathToDevice/counter1" || $testHarness,    "counter1" );
ok( -e "$myPathToDevice/counter2" || $testHarness,    "counter2" );
ok( -e "$pathToDevice/debounce1" || $testHarness,   "debounce1" );
ok( -e "$pathToDevice/debounce2" || $testHarness,   "debounce2" );
ok( -e "$pathToDevice/digital_in" || $testHarness,  "digital_in" );
ok( -e "$pathToDevice/digital_out" || $testHarness, "digital_out" );


