#!/usr/bin/perl
use strict;
use warnings;
use Imager;
use lib 'lib';
use Math::Random::AcceptReject;

# PDF properties
my $ymax = 1;
my $xmin = 1;
my $xmax = 10;
my $pdf  = '1/x';
my $generator = 'rand';

# file properties
my $file = 'inverse_of_x.png';
my $xsize = 1280;
my $ysize = 1024;

# bins, number of random numbers
my $n = 1000000;
my $bins = 1280;
my $notify_step = 10000;

# create generator
my $rnd = Math::Random::AcceptReject->new(
    xmin => $xmin,
    xmax => $xmax,
    ymax => $ymax,
    pdf => $pdf,
    random => $generator,
);


my @bins = (0) x $bins;

# fill bins
foreach (1..$n) {
    print "$_\n" if not $_ % $notify_step;
    my $rand = $rnd->rand();
    $bins[@bins * ( ($rand-$xmin) / ($xmax-$xmin) )]++;
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


