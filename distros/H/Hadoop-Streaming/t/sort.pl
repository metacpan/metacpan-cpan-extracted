#!/usr/bin/perl

use strict;
use warnings;

# Imitation of sort command, just for testing.

my @lines;
while(<>)
{
    push @lines, $_;
}
print $_ for sort @lines;
