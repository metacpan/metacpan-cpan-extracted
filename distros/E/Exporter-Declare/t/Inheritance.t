#!/usr/bin/perl
use strict;
use warnings;

use Fennec::Lite;

use lib 'lib', 't/lib';
use_ok( 'InheritanceChild', 'the_export' );

done_testing;
