#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;

BEGIN { use_ok( 'JavaScript::XRay' ); }
diag( "Testing JavaScript::XRay $JavaScript::XRay::VERSION, Perl $], $^X" );
