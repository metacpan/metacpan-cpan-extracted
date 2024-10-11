#!/usr/bin/perl -w 

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally
    
use Test::More tests => 3;

use_ok('File::ValueFile');
use_ok('File::ValueFile::Simple::Reader');
use_ok('File::ValueFile::Simple::Writer');

exit 0;
