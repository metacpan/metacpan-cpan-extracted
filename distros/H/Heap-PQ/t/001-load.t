#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok('Heap::PQ') || print "Bail out!\n";
}

diag("Testing heap $Heap::PQ::VERSION, Perl $], $^X");
