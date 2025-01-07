#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

plan tests => 1;

use_ok('File::Tudo');

diag("Testing File::Tudo $File::Tudo::VERSION, Perl $], $^X");
