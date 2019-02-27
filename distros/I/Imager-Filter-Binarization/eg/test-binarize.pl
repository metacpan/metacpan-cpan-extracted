use v5.18;
use strict;
use warnings;

use Imager;
use Imager::Filter::Binarization;

my $file_img = $ARGV[0];
my $img;

$img = Imager->new( file => $file_img );
$img = $img->convert( preset => "noalpha" )->convert( matrix => [[0.333, 0.333, 0.333]] );
$img->write( file => "o-grey.png" );
say "Written o-grey.png";

my ($w, $h) = ( $img->getwidth(), $img->getheight() );
$w = int( $w / 100 );
$h = int( $h / 100 );
$w = 5 if $w < 5;
$h = 5 if $h < 5;

my $geo = $w . 'x' . $h;
say "Geometry: $geo";

my @kids;
for my $method ('sauvola', 'niblack') {
    if (my $pid = fork()) {
        push @kids, $pid;
    } else {
        $img->filter(
            type => "binarization",
            method => $method,
            geometry => $geo,
        ) or die $img->errstr;
        $img->write( file => "o-${method}.png" );
        say "Written o-${method}.png";
        exit(0);
    }
}

wait() for @kids;
