#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok('Devel::XRay');
}

diag("Testing Devel::XRay $Devel::XRay::VERSION, Perl $], $^X");
