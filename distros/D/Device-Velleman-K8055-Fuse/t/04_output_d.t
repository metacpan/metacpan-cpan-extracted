use Test::More tests => 38;
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

my $_00000000 = [ 0, 0, 0, 0, 0, 0, 0, 0 ];
my $_00000010 = [ 0, 0, 0, 0, 0, 0, 1, 0 ];
my $_00000001 = [ 0, 0, 0, 0, 0, 0, 0, 1 ];
my $_00000011 = [ 0, 0, 0, 0, 0, 0, 1, 1 ];
my $_00011111 = [ 0, 0, 0, 1, 1, 1, 1, 1 ];
my $_11111111 = [ 1, 1, 1, 1, 1, 1, 1, 1 ];
my $_11111000 = [ 1, 1, 1, 1, 0, 0, 0, 0 ];
my $_11110000 = [ 1, 1, 1, 1, 0, 0, 0, 0 ];
my $_11100000 = [ 1, 1, 1, 0, 0, 0, 0, 0 ];

SKIP: {
             skip "testHarness", 36 if $testHarness;


ok( $dev->ClearAllDigital() == 0, "0a Clear all Digital Channels" );
ok( eq_array( $dev->{binary_out}, $_00000000 ),
    "0a Initial Channels are clear" );

ok( $dev->SetDigitalChannel(1), "1a Set Digital Channel 1" );
ok( eq_array( $dev->{binary_out}, $_00000001 ), "1a Check SetDigitalChannel" );

ok( $dev->SetDigitalChannel(2), "1b Set Digital Channel 2" );
ok( eq_array( $dev->{binary_out}, $_00000011 ), "1b Check Set 2" );

ok( $dev->ClearDigitalChannel(2), "1c Clear 2" );
ok( eq_array( $dev->{binary_out}, $_00000001 ), "1c Check Clear 2" );

ok( $dev->ClearDigitalChannel(1) == 0, "1d Clear 1" );
ok( eq_array( $dev->{binary_out}, $_00000000 ), "1d Check Set 1" );

ok( $dev->ClearAllDigital() == 0, "1e Clear all" );
ok( eq_array( $dev->{binary_out}, $_00000000 ), "1e check clear all" );

ok( $dev->SetDigitalChannel(1), "2 Set Digital Channel 1" );
ok( $dev->SetDigitalChannel(2), "2 Set Digital Channel 2" );
ok( $dev->SetDigitalChannel(3), "2 Set Digital Channel 3" );
ok( $dev->SetDigitalChannel(4), "2 Set Digital Channel 4" );
ok( $dev->SetDigitalChannel(5), "2 Set Digital Channel 5" );
ok( $dev->SetDigitalChannel(6), "2 Set Digital Channel 6" );
ok( $dev->SetDigitalChannel(7), "2 Set Digital Channel 7" );
ok( $dev->SetDigitalChannel(8), "2 Set Digital Channel 8" );

ok(
    eq_array( $dev->{binary_out}, $_11111111 ),
    "2 Check Set " . join( '', @$_11111111 )
);

ok( $dev->ClearAllDigital() == 0, "3 start by clearing all" );
ok( $dev->SetDigitalChannel(1),   "3 Set Digital Channel 1" );
ok( $dev->SetDigitalChannel(2),   "3 Set Digital Channel 2" );
ok( $dev->SetDigitalChannel(3),   "3 Set Digital Channel 3" );
ok( $dev->SetDigitalChannel(4),   "3 Set Digital Channel 4" );
ok( $dev->SetDigitalChannel(5),   "3 Set Digital Channel 5" );
ok(
    eq_array( $dev->{binary_out}, $_00011111 ),
    "3 check " . join( '', @$_00011111 )
);
ok( $dev->ClearAllDigital() == 0, "3 Clear all" );

ok( eq_array( $dev->{binary_out}, $_00000000 ), "3 check clear all" );
ok( $dev->SetDigitalChannel(6), "3 Set Digital Channel 6" );
ok( $dev->SetDigitalChannel(7), "3 Set Digital Channel 7" );
ok( $dev->SetDigitalChannel(8), "3 Set Digital Channel 8" );

#ok(print Dumper $dev,"Check Dumper dev");

ok(
    eq_array( $dev->{binary_out}, $_11100000 ),
    "3 Check Set " . join( '', @$_11100000 )
);

ok( $dev->ClearAllDigital() == 0, "3 Clear all" );

for ( 1 .. 100 ) {
    $dev->SetDigitalChannel( int( rand(8) ) + 1 );
    $dev->ClearDigitalChannel( int( rand(8) ) + 1 );
}

ok( print Dumper $dev->{binary_out}, "Correlate to card digital out LEDs" );
}
