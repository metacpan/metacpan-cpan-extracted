#!/usr/bin/perl -w

use v5.20;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 1;

use_ok('Lingua::Lapine::Word');

exit 0;
