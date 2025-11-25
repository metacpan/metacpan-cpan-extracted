#!/usr/bin/perl -w

use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 6;

use_ok('Lingua::famibeib');
use_ok('Lingua::famibeib::Word');
use_ok('Lingua::famibeib::Modifier');
use_ok('Lingua::famibeib::Fragment');
use_ok('Lingua::famibeib::Sentence');
use_ok('Lingua::famibeib::Text');

exit 0;
