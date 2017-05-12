#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use lib '/home/protected/lib';
use CGI::Carp 'fatalsToBrowser';
use Cairo;
use Image::PNG::Cairo 'cairo_to_png';
use Image::PNG::Libpng ':all';
use Image::PNG::Const ':all';
use constant { M_PI => 3.14159265 };
my $xsize = 200;
my $ysize = 50;
my $surface = Cairo::ImageSurface->create ('argb32', $xsize, $ysize);
my $cr = Cairo::Context->create ($surface);

# Make a background

$cr->set_source_rgb (0, 0, 0);
$cr->rectangle (0, 0, $xsize, $ysize);
$cr->fill ();

# Get six randomly-chosen letters

my $captcha = random_letters (6);

# Draw the captcha text in white
my $gap = 10;
$cr->set_source_rgb (1, 1, 1);
$cr->set_font_size ($ysize - $gap);
$cr->move_to ($gap, $ysize - $gap);
$cr->show_text ($captcha);
$cr->fill ();

# Obscure the text with translucent circles in random colours.

for (0..50) {
    $cr->set_source_rgba (random_colours (), 0.4);
    $cr->arc (rand ($xsize), rand ($ysize), rand (25), 0, 2 * M_PI);
    $cr->fill ();
}

# Get the PNG data out of it.

my $png = cairo_to_png ($surface);

# Put the captcha into the PNG itself, and set a modification time.

$png->set_text ([{compression => PNG_TEXT_COMPRESSION_NONE,
		  key => 'captcha', text => $captcha}]);
$png->set_tIME ();

# Get the PNG data from $png and print it out.

my $data = write_to_scalar ($png);
binmode STDOUT;
print "Content-Type: image/png\r\n\r\n$data";
exit;

sub random_colours
{
    my @r;
    for (1..3) {
	push @r, rand (1);
    }
    return @r;
}

sub random_letters
{
    my ($length) = @_;
    my @letters = ('0' .. '9', 'a' .. 'z', 'A' .. 'Z');
    my $r = '';
    for (1..$length) {
	$r .= $letters[rand (@letters)];
    }
    return $r;
} 
