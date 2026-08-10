#!/usr/bin/perl -w

use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 10;

use_ok('Lingua::famibeib');
use_ok('Lingua::famibeib::Word');
use_ok('Lingua::famibeib::Modifier');
use_ok('Lingua::famibeib::Fragment');
use_ok('Lingua::famibeib::Sentence');
use_ok('Lingua::famibeib::Text');
use_ok('Lingua::famibeib::Wellknown');
use_ok('Lingua::famibeib::NameGenerator');
use_ok('Lingua::famibeib::ForeignWord');
use_ok('Lingua::famibeib::Prefix');

exit 0;
