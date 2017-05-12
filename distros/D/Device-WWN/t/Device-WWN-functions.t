#!perl
use strict; use warnings;
use Test::Most tests => 5;
use ok 'Device::WWN', ':all';

my $x0 = Device::WWN->new( '10:00:00:00:c9:22:fc:01' );
my $x1 = Device::WWN->new( '200000e069415402' );
my $x2 = Device::WWN->new( '20:00:00:e0:69:41:54:02' );
my $x3 = Device::WWN->new( '2000:00e0:6941:5402' );
my $x4 = Device::WWN->new( '50:06:04:81:D6:F3:45:42' );
my $x5 = Device::WWN->new( '200000e069415402' );
my $x6 = Device::WWN->new( '200000e0694157a0' );
my $x7 = Device::WWN->new( '200000e069415773' );
my $x8 = Device::WWN->new( '200000e069415036' );
my $x9 = Device::WWN->new( '10000000c9282238' );
my $xa = Device::WWN->new( '10000000c9282256' );
my $xb = Device::WWN->new( '5006016012345678' );
my $xc = Device::WWN->new( '500604872363ee43' );
my $xd = Device::WWN->new( '500604872363ee53' );
my $xe = Device::WWN->new( '500604872363ee4c' );
my $xf = Device::WWN->new( '500604872363ee5c' );

ok( $x1 == $x2, "x1 == x2" );
ok( $x1 eq $x2, "x1 eq x2" );
ok( $x1 == $x3, "x1 == x3" );
ok( $x1 eq $x3, "x1 eq x3" );
