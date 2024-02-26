#!perl

use Test::More tests => 3;
use HiPi qw( :rpi );
use HiPi::RaspberryPi;
use Time::HiRes;

my $sleepwait = 5000;

SKIP: {
      skip 'not in dist testing', 3 unless ( $ENV{HIPI_MODULES_DIST_TEST_1WIRE} );
      
diag('DEVICE 1-WIRE (sys) tests are running');

use_ok( 'HiPi::Interface::DS18X20' );


my @devids = HiPi::Interface::DS18X20->list_devices();

for my $dev ( @devids ) {
    my $therm = HiPi::Interface::DS18X20->new( id => $dev->{id}, divider => 1000 );
	my $out = $therm->temperature || 0;
    diag 'Temperature ' . $out;
    my $val = ( $out > 0 ) ? 1 : 0;
    
    is( $val, 1, qq($dev->{id} therm temperature));
    
}

} # End SKIP

1;
