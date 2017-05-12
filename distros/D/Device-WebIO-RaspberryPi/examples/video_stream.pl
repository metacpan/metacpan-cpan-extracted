#!env perl
use v5.14;
use warnings;
use Device::WebIO;
use Device::WebIO::RaspberryPi;
use Getopt::Long;

my $WIDTH    = 1024;
my $HEIGHT   = 768;
my $BITRATE  = 2000;
my $TYPE     = 'avi';
my $OUT_FILE = '';
Getopt::Long::GetOptions(
    'width=i'   => \$WIDTH,
    'height=i'  => \$HEIGHT,
    'bitrate=i' => \$BITRATE,
    'type=s'    => \$TYPE,
    'out=s'     => \$OUT_FILE,
);
die "Need --out [file]\n" unless $OUT_FILE;

my %TYPE_LOOKUP = (
    avi  => 'video/x-msvideo',
    h264 => 'video/H264',
    #mp4  => 'video/mp4',
);
$TYPE = lc $TYPE;
die "Type '$TYPE' is not supported\n" if ! exists $TYPE_LOOKUP{$TYPE};
my $MIME_TYPE = $TYPE_LOOKUP{$TYPE};


my $rpi = Device::WebIO::RaspberryPi->new({
    vid_use_audio => 1,
});
my $webio = Device::WebIO->new;
$webio->register( 'rpi', $rpi );

$webio->vid_set_width(  'rpi', 0, $WIDTH );
$webio->vid_set_height( 'rpi', 0, $HEIGHT );
$webio->vid_set_kbps(   'rpi', 0, $BITRATE );

open( my $out, '>', $OUT_FILE ) or die "Can't open '$OUT_FILE': $!\n";
binmode $out;
say "Starting video stream . . . ";
$webio->vid_stream_callback( 'rpi', 0, $MIME_TYPE, sub {
    my ($frame) = @_;
    print $out pack( 'C*', @$frame );
    return 1;
});

$SIG{INT} = sub {
    close $out;
    exit 0;
};
$webio->vid_stream_begin_loop( 'rpi', 0 );
