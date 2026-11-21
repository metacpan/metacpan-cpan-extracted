#!/usr/bin/perl -w 

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 5;

use_ok('File::FStore');
use_ok('File::FStore::Base');
use_ok('File::FStore::Adder');
use_ok('File::FStore::File');
use_ok('File::FStore::Migration');

exit 0;
