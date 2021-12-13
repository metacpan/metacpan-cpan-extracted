#!/usr/bin/perl

use strict;
use warnings;

use Dir::Split;

my $dir = Dir::Split->new(
    source => 'source',
    target => 'target',
);

$dir->split_num(verbose => 1);
#$dir->split_char(verbose => 1);

$dir->print_summary;
