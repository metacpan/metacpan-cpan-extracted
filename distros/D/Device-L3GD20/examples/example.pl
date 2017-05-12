use FindBin qw($Bin);
use lib "$Bin/../lib";

use Device::Gyroscope::L3GD20;

my $g = Device::Gyroscope::L3GD20->new(
    I2CBusDevicePath => '/dev/i2c-1',
    XZero => -26.99,
    YZero => 7.46,
    ZZero => -9.07,
);

$g->enable();
use Data::Dumper;
my ($x,$y,$z) = (0,0,0);
my ($dx,$dy,$dz) = (0,0,0);
my $count = 0;
while(){
    $gyro = $g->getReadingDegreesPerSecond();
    $graw = $g->getRawReading();
#    print 'Gyroscope(Raw): ' . Dumper $g->getRawReading();
#    print "Gyroscope: $gyro->{x}\t$gyro->{y}\t$gyro->{z}\n" ;
    $dx += $gyro->{x}*$g->timeDrift;
    $dy += $gyro->{y}*$g->timeDrift;
    $dz += $gyro->{z}*$g->timeDrift;
    print "Gyroscope: $gyro->{x}\t$gyro->{y}\t$gyro->{z}\n" ;
#    print "Gyroscope(aggregate): $dx\t$dy\t$dz\n" ;
#    print "TIME DRIFT: " . $g->timeDrift . "\n" ;


=head2

    $x+= $graw->{x};
    $y+= $graw->{y};
    $z+= $graw->{z};
    $count++;
    print "AVERAGE: " . ($x/$count) . ", " . ($y/$count) . ", " . ($z/$count) . "\n";

=cut

}
