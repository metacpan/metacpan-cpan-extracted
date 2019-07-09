#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 2;

BEGIN {
    use_ok('IO::BlockSync')      || print "Bail out!\n";
    use_ok('IO::BlockSync::App') || print "Bail out!\n";
}

diag("Testing IO::BlockSync $IO::BlockSync::VERSION, Perl $], $^X");
