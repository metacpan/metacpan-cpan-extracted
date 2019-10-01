#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

plan tests => 1;

use_ok('Eval::Safe');

diag("Testing Eval::Safe $Eval::Safe::VERSION, Perl $], $^X, $ENV{SHELL}");
