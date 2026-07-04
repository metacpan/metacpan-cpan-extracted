#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use_ok('File::Raw::Archive')        or print "Bail out!\n";
use_ok('File::Raw::Archive::Entry') or print "Bail out!\n";
ok(File::Raw::Archive->can('open'), 'File::Raw::Archive->open is defined');

done_testing;

diag("Testing File::Raw::Archive $File::Raw::Archive::VERSION, Perl $], $^X");
