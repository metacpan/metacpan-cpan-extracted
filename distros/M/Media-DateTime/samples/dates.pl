#!/usr/bin/perl

use strict;
use warnings;

use Media::DateTime;
use DateTime;

my $dater = Media::DateTime->new();

for (@ARGV) {
    print "Date for $_: ", $dater->datetime($_)->datetime, "\n";
}
