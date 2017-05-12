#!/usr/bin/perl -w

# Load test the File::Tasks module

use strict;

# Does everything load?
use Test::More 'tests' => 2;
ok( $] >= 5.005, 'Your perl is new enough' );
use_ok('File::Tasks');


