#!/usr/bin/perl

# Compile-testing for File::ShareDir

use strict;

BEGIN
{
    $|  = 1;
    $^W = 1;
}

use Test::More;

ok($] > 5.005, 'Perl version is 5.005 or newer');

use_ok('File::ShareDir');

diag("Testing File::ShareDir $File::ShareDir::VERSION, Perl $], $^X, UID: $<");

done_testing();
