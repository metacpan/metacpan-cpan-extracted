#!/usr/bin/perl

# Jeff Mock
# 1859 Scott St.
# San Francisco, CA 94115
#
# jeff@mock.com
# (c) 1999

#
# This CGI script generates a GIF image of an HP3585A 
# spectrum analyser.  This is a quick and dirty script,
# it doesn't do any checking, it's just an example using
# the GD module with GPIB to generate images from test
# equipment in a CGI script.
#

use GD;
use GPIB::hp3585a;

# Size of image, original data is 1001 wide, 1024 tall
$width = 501;
$height = 512;

# Open device
$g = GPIB::hp3585a->new("HP3585A");

# New image
$im = new GD::Image($width, $height);

# Allocate some colors
$white = $im->colorAllocate(255,255,255);
$black = $im->colorAllocate(0,0,0);
$grid = $im->colorAllocate(80,80,80);
$red = $im->colorAllocate(255,0,0);
$blue = $im->colorAllocate(0,0,255);
$green = $im->colorAllocate(0,255,0);

# background
$im->filledRectangle(0, 0, $width-1, $height-1, $black);

# Vertical grid lines
for($i=0; $i<$width; $i += ($width-1)/10.0) {
    $im->line($i, 0, $i, $height-1, $grid);
}

# Horizontal grid lines
for($i=0; $i<$height; $i += ($height * 1000.0/1024.0)/10.0) {
    $im->line(0, $height-1-$i, $width-1, $height-1-$i, $grid);
}

# Get data from sprectrum analyser
@items = $g->getCaption;
@vals =  $g->getDisplay;

# Get marker list and fixup data for display
@markers = ();
for ($i=1; $i<@vals; $i++) {
    push (@markers, $i) if ($vals[$i] & 0x400);
    $vals[$i] = 1023 - ($vals[$i] & 0x3ff);
}

# Add captions to image
for($i=0; $i<5; $i++) {
    # Left side
    $im->string(gdLargeFont, 10, 16 + 16*$i,    
            $items[$i*2], $white);
    # Right side
    $im->string(gdLargeFont,$width-10-8*length($items[$i*2+1]), 16 + 16*$i, 
            $items[$i*2+1], $white);
}

# Add trace data to image
for($i=1; $i<1000; $i++) {
    $im->line($i * $width / 1000.0, $vals[$i] * $height / 1024.0,
            ($i+1) * $width / 1000.0, $vals[$i+1] * $height / 1024.0, $red);
}

# Draw circles at markers
for (@markers) {
    $im->arc($_ * $width / 1000.0, $vals[$_] * $height / 1024.0,
            10.0, 10.0, 0, 360, $white);
}

binmode(STDOUT);        

print "Content-type: image/gif\n";
print "Pragma: no-cache\n";
print "Expires: now\n";
print "\n";
print $im->gif;
