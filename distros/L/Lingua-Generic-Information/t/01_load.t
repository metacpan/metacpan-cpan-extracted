#!/usr/bin/perl -w

use v5.20;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 2;

use_ok('Lingua::Generic::Information');
use_ok('Lingua::Generic::Information::Language');

exit 0;
