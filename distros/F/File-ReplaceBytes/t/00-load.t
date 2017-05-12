#!perl -T
use 5.006;
use strict;
use warnings;
use Test::Most;

plan tests => 1;

BEGIN {
    use_ok('File::ReplaceBytes') || print "Bail out!\n";
}

diag("Testing File::ReplaceBytes $File::ReplaceBytes::VERSION, Perl $], $^X");

