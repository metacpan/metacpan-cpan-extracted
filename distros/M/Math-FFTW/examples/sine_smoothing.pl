#!perl
use strict;
use warnings;
use lib 'lib';
use Math::FFTW;

# You need a gnuplot to run this example.
# Multiple instances of gnuplot will be spawned to display data.
# Enter 'q' in the gnuplot shell to exit an instance. Execution will
# continue afterwards.

# Leave as 'gnuplot' if it's in PATH, otherwise set to full
# gnuplot path:
my $gp = 'gnuplot';

use File::Temp qw/tempfile/;

# This is a sine with some randomness. Sampled at 10000 points from
# 1/100 to 100.
my @x   = (1..10000);
my @y   = map {
    my $y = sin($_/100);
    $y-=0.25*$y;$y+=rand($y*0.5);
    $y
} @x;

# Plot the input data.
print "Plotting input data...\n";
plot(\@x, \@y);

print "Computing Discrete Fourier Transform...\n";
my $res = Math::FFTW::fftw_dft_real2complex_1d(\@y);

print "Plotting coefficients (real, imaginary, real, ...)...\n";
plot(\@x, $res);

print "Setting all coefficients beyond 25 to 0 for smoothing...\n";
for (50..$#$res) {
    $res->[$_] = 0;
}

print "Computing inverse DFT...\n";
my $res2 = Math::FFTW::fftw_idft_complex2real_1d($res);

print "Plotting smoothed data...\n";
plot(\@x, $res2);

sub plot {
    my $xdata = shift;
    my $ydata = shift;
    my ($fh, $fname) = tempfile(UNLINK => 1);
    foreach my $i (0..$#$xdata) {
        print $fh $xdata->[$i], ' ', $ydata->[$i], "\n";
    }
    if (@$ydata > @$xdata) {
        foreach my $i (@$xdata..$#$ydata) {
            print $fh "$i $ydata->[$i]\n";
        }
    }
    close $fh;
    
    my ($dh, $dname) = tempfile(UNLINK => 1);
    print $dh <<"HERE";
plot '$fname'
HERE
    close $dh;
    system($gp, $dname, '-');
}

