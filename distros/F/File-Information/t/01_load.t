#!/usr/bin/perl -w

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally
    
use Test::More tests => 11;

use_ok('File::Information');
use_ok('File::Information::Base');
use_ok('File::Information::Filesystem');
use_ok('File::Information::Link');
use_ok('File::Information::Inode');
use_ok('File::Information::Tagpool');
use_ok('File::Information::Remote');
use_ok('File::Information::Deep');
use_ok('File::Information::VerifyBase');
use_ok('File::Information::VerifyResult');
use_ok('File::Information::VerifyTestResult');

exit 0;
