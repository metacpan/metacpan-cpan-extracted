#!/usr/bin/perl
use strict;
use warnings;
use Imager;
use lib 'lib';
use Math::Random::Cauchy;

# PDF properties
my $fwhm = 1;
my $mid = 10;
my $generator = 'rand';

my $xmin = $mid - 3*$fwhm;
my $xmax = $mid + 3*$fwhm;

# file properties
my $file = 'cauchy.png';
my $xsize = 1280;
my $ysize = 1024;

# bins, number of random numbers
my $n = 1000000;
my $bins = 1280;
my $notify_step = 10000;

# create generator
my $rnd = Math::Random::Cauchy->new(
    middle => $mid,
    fwhm => $fwhm,
    random => $generator,
);


my @bins = (0) x $bins;

# fill bins
foreach (1..$n) {
    print "$_\n" if not $_ % $notify_step;
    my $rand = $rnd->rand();
    my $binno = @bins * ( ($rand-$xmin) / ($xmax-$xmin) );

    # sigma undefined, remember?
    redo if $binno < 0;
    redo if @bins < $binno;
    $bins[$binno]++;
}

# prepare image
my $image = Imager->new(xsize => $xsize, ysize => $ysize);
$image->box(filled => 1, color => 'white');

# find maximum number of events in a bin
my $max = 0;
foreach (@bins) {
    $max = $_ if $_ > $max;
}

# plot bins
print "Plotting image...\n";
foreach my $binno (0..$#bins) {
    print "Bin $binno\n";
    my $x = $binno * $xsize/@bins;
    my $y = $bins[$binno]/$max;
    $image->box(
        filled => 1, color => 'blue',
        xmin => $x, xmax => $x + $xsize/@bins - 1,
        ymin => $ysize - $y*$ysize, ymax => $ysize,
    );
}

# write file
print "Writing image...\n";
$image->write( file => $file )
  or die "Cannot write file $file: " . $image->errstr;


