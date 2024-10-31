#!/usr/bin/perl
use 5.016;
use strict;

use Test::More tests => 1;

use_ok('File::Strfile');

diag("Testing File::Strfile $File::Strfile::VERSION, Perl $], $^X");
