#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;
use FindBin;

my $path = $FindBin::Bin . '/myprogram';
ok(-e $path, "found the test program ($path)");

$ENV{GETOPT_COMPLETE} = 'bash';




