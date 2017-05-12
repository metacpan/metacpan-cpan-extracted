#!/usr/bin/env perl

use strict;
use warnings;
use Device::USB::TranceVibrator;

my $vibe = Device::USB::TranceVibrator->new;

print "input speed of vibrate [1-255] or 'q' to quit> ";
while (<>) {
    chomp;
    last if $_ eq 'q';
    $vibe->vibrate(speed => $_);
    print "$_> ";
}

END {
    $vibe->stop;
}

__END__

