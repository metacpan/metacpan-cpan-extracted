#!/usr/bin/env perl

use strict;
use warnings;

use Path::Class;

#my $fh = dir($ARGV[ 0 ], 'lib')->file('AFTER_BUILD.txt')->openw();
my $fh = file(__FILE__)->parent->file('phases.txt')->open('>>');
binmode $fh;
print $fh join(' ', @ARGV) . "\n";
close $fh;
