use Test::More tests => 29;
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
             skip "testHarness", 27 if $testHarness;

ok( $dev->OutputAnalogChannel( 1, 0 ) == 0, "1 Analog Channel 1 to  0" );
ok( $dev->OutputAnalogChannel( 2, 0 ) == 0, "1 Analog Channel 2 to  0" );

ok( $dev->{io}->{analog_out1} == 0, "1 Check output 1" );
ok( $dev->{io}->{analog_out2} == 0, "1 Check output 2" );

ok( $dev->OutputAnalogChannel( 1, 2 ) == 2, "3 Analog Channel 1 to  2" );
ok( $dev->OutputAnalogChannel( 2, 2 ) == 2, "3 Analog Channel 2 to  2" );

ok( $dev->{io}->{analog_out1} == 2, "3 Check output 1" );
ok( $dev->{io}->{analog_out2} == 2, "3 Check output 2" );

ok( $dev->OutputAnalogChannel( 1, 1 ) == 1, "2 Analog Channel 1 to  1" );
ok( $dev->OutputAnalogChannel( 2, 1 ) == 1, "2 Analog Channel 2 to  1" );

ok( $dev->{io}->{analog_out1} == 1, "2 Check output 1" );
ok( $dev->{io}->{analog_out2} == 1, "2 Check output 2" );

ok( $dev->SetAllAnalog() == 255, "4 Analog Channels  to  255" );

ok( $dev->{io}->{analog_out1} == 255, "4 Check output 1" );
ok( $dev->{io}->{analog_out2} == 255, "4 Check output 2" );

ok( scalar($dev->OutputAllAnalog(100,200)) == 2, "5 Analog Channels  to  255" );

ok( $dev->{io}->{analog_out1} == 100, "5 Check output 1" );
ok( $dev->{io}->{analog_out2} == 200, "5 Check output 2" );

ok( scalar($dev->SetAnalogChannel(1)) == 255, "6 Analog Channels  to  255" );
ok( $dev->{io}->{analog_out1} == 255, "6 Check output 1 after Set" );
ok( $dev->{io}->{analog_out2} == 200, "6 Check output 2 after Set" );

ok( scalar($dev->SetAnalogChannel(2)) == 255, "7 Analog Channels  to  255" );
ok( $dev->{io}->{analog_out1} == 255, "7 Check output 1 after Set" );
ok( $dev->{io}->{analog_out2} == 255, "7 Check output 2 after Set" );

ok( scalar($dev->ClearAnalogChannel(2)) == 0, "7 Analog Channels  to  255" );
ok( $dev->{io}->{analog_out1} == 255, "7 Check output 1 after Set" );
ok( $dev->{io}->{analog_out2} == 0, "7 Check output 2 after Set" );

} 
#print Dumper $dev;
#print Dumper $dev;
