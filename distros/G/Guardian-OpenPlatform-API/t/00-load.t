#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Guardian::OpenPlatform::API') || print "Bail out!\n"; }

diag( "Testing Guardian::OpenPlatform::API $Guardian::OpenPlatform::API::VERSION, Perl $], $^X" );
