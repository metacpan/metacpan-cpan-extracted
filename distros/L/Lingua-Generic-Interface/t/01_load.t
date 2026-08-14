#!/usr/bin/perl -w

use v5.20;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 2;

use_ok('Lingua::Generic::Interface');
use_ok('Lingua::Generic::Interface::Word');

exit 0;
