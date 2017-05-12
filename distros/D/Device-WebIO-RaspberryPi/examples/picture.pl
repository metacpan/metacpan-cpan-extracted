#!env perl
use v5.14;
use warnings;
use Device::WebIO;
use Device::WebIO::RaspberryPi;
use Getopt::Long;

my $WIDTH    = 1024;
my $HEIGHT   = 768;
my $QUALITY  = 100;
my $OUT_FILE = '';
Getopt::Long::GetOptions(
    'width=i'   => \$WIDTH,
    'height=i'  => \$HEIGHT,
    'quality=i' => \$QUALITY,
    'out=s'     => \$OUT_FILE,
);
die "Need --out [file]\n" unless $OUT_FILE;


my $rpi = Device::WebIO::RaspberryPi->new;
my $webio = Device::WebIO->new;
$webio->register( 'rpi', $rpi );


$webio->img_set_width( 'rpi', 0, $WIDTH );
$webio->img_set_height( 'rpi', 0, $HEIGHT );
$webio->img_set_quality( 'rpi', 0, $QUALITY );

open( my $out, '>', $OUT_FILE ) or die "Can't open '$OUT_FILE': $!\n";
my $in = $webio->img_stream( 'rpi', 0, 'image/jpeg' );

while( read( $in, my $buf, 4096 ) ) {
    print $out $buf;
}

close $out;
close $in;
