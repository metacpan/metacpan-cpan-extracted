#!perl
use strict;
use warnings;
use Math::Fractal::Julia;
use Imager;

my $width  = 640;
my $height = 480;
my $view   = [ -1.6, -1.2, 1.6, 1.2 ];    # [ min_x, $min_y, $max_x, $max_y]

# See http://en.wikipedia.org/wiki/File:Julia_set_%28ice%29.png
my $julia = Math::Fractal::Julia->new(
    max_iter => 255,
    bounds   => [ @$view, $width, $height ],
    constant => [ -0.726895347709114071439, 0.188887129043845954792 ],
);

my @palette = map { [ $_, $_, $_ ] } 0 .. 255;
$palette[0] = [ 255, 255, 255 ];

my $img = Imager->new( xsize => $width, ysize => $height );

for my $y ( 0 .. $height - 1 ) {
    for my $x ( 0 .. $width - 1 ) {
        my $iter = $julia->point( $x, $height - $y - 1 );
        $img->setpixel( x => $x, y => $y, color => $palette[$iter] );
    }
}

$img->write( file => 'julia.png' );

