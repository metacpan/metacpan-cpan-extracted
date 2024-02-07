#!/usr/bin/perl

use strict;
use warnings;

use Test::CPANfile;
use Test2::V0;

our $VERSION = 0.01;

cpanfile_has_all_used_modules(perl_version => [%min_perl_version %], develop => 1, suggests => 1);

done_testing;
