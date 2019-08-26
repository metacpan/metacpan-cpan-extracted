#!/usr/bin/env perl

# A quick script to use to restore the console to text mode,
# if it is stuck in graphics mode.

use strict;

chomp(my $tty = `tty`);

open(my $ftty,'>',$tty);
ioctl($ftty,0x4B3A,0);
close($ftty);

exec('reset');
