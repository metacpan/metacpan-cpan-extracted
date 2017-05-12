use Test::More tests => 24;
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
    'debug'        => 1
) || die "Failed to get an object $!";

ok( defined($dev) && ref $dev eq 'Device::Velleman::K8055::Fuse',
    'new() works' );

my $sleep = shift @ARGV || 0;

ok( $dev->dec2bin(0) == 0,            "1 dec2bin 0" );
ok( $dev->dec2bin(1) == 1,            "2 dec2bin 1" );
ok( $dev->dec2bin(2) == 10,           "3 dec2bin 2" );
ok( $dev->dec2bin(254) == '11111110', "4 dec2bin 254" );
ok( $dev->dec2bin(255) == '11111111', "5 dec2bin 255" );

ok( $dev->bin2dec('0') == 0,          "6 bin2dec: 0" );
ok( $dev->bin2dec('1') == 1,          "3 bin2dec: 1" );
ok( $dev->bin2dec('10') == 2,         "4 bin2dec: 10" );
ok( $dev->bin2dec('100') == 4,        "5 bin2dec: 100" );
ok( $dev->bin2dec('1000') == 8,       "6 bin2dec: 1000" );
ok( $dev->bin2dec('10000') == 16,     "7 bin2dec: 10000" );
ok( $dev->bin2dec('100000') == 32,    "8 bin2dec: 100000" );
ok( $dev->bin2dec('1000000') == 64,   "9 bin2dec: 1000000" );
ok( $dev->bin2dec('10000000') == 128, "A bin2dec: 10000000" );
ok( $dev->bin2dec('11111111') == 255, "B bin2dec: 11111111" );
ok( $dev->bin2dec('00000001') == 1,   "C bin2dec: 00000001" );
ok( $dev->bin2dec('0000001') == 1,    "D bin2dec: 0000001" );
ok( $dev->bin2dec('000001') == 1,     "E bin2dec: 000001" );
ok( $dev->bin2dec('00001') == 1,      "F bin2dec: 00001" );
ok( $dev->bin2dec('0001') == 1,       "G bin2dec: 0001" );
ok( $dev->bin2dec('001') == 1,        "H bin2dec: 001" );
ok( $dev->bin2dec('01') == 1,         "I bin2dec: 01" );

