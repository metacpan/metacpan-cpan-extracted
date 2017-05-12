use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Device::LSM303DLHC;
#use Device::Magnetometer::LSM303DLHC;
#use Device::Accelerometer::LSM303DLHC;

my $dev = Device::LSM303DLHC->new(I2CBusDevicePath => '/dev/i2c-1');
$dev->Magnetometer->enable();
$dev->Accelerometer->enable();
use Data::Dumper;
my ($minx, $miny, $minz, $maxx, $maxy, $maxz) = (500,500,500,0,0,0);
my ($avg,$avgCount) = (0,0);
while(){
    my $accelerometer = $dev->Accelerometer->getRawReading();
    #my $accelerometer = $dev->Accelerometer->getAccelerationVectorInG();
    #my $accelerometer = $dev->Accelerometer->getAccelerationVectorInMSS();
    my $compass = $dev->Magnetometer->getRawReading();
    my $accAngle = $dev->Accelerometer->getAccelerationVectorAngles();


    #print "COMPASS: $compass->{x}\t$compass->{y}\t$compass->{z}\t\n";
    print "\tACCELEROMETER: $accelerometer->{x}\t$accelerometer->{y}\t$accelerometer->{z}\t\tCOMPASS: $compass->{x}\t$compass->{y}\t$compass->{z}\t\n" ;

=head2 

=cut

    #print "\tACC_ANGLE: " . Dumper $accAngle ;


=head2 

    $minx = $accelerometer->{x} < $minx ? $accelerometer->{x} : $minx;
    $miny = $accelerometer->{y} < $miny ? $accelerometer->{y} : $miny;
    $minz = $accelerometer->{z} < $minz ? $accelerometer->{z} : $minz;
    $maxx = $accelerometer->{x} > $maxx ? $accelerometer->{x} : $maxx;
    $maxy = $accelerometer->{y} > $maxy ? $accelerometer->{y} : $maxy;
    $maxz = $accelerometer->{z} > $maxz ? $accelerometer->{z} : $maxz;
    #print "\tmax/min: $minx\t$miny\t$minz\t$maxx\t$maxy\t$maxz\n" ;
    my $acceleration_net = $accelerometer->{x}**2 + $accelerometer->{y}**2 + $accelerometer->{z}**2;
    my $net = ($acceleration_net**.5);
    $avg+=$net;
    $avgCount++;
    print "Net Acceleration : " . $net . "\n" ;
    print "Net Acceleration (avg): " . $avg/$avgCount . "\n" ;

=cut

    
    #print 'COMPASS: ' . Dumper {$dev->Magnetometer->getRawReading()};
    #print 'ACCELEROMETER: ' . Dumper {$dev->Accelerometer->getRawReading()};
}

