#!/usr/bin/env perl
use strict;
use warnings;
use lib '../lib';
use blib;

use Test::More tests => 2;
note( "Testing Device::Trepan::Shell $Devel::Trepan::Shell::VERSION" );

BEGIN {
use_ok( 'Devel::Trepan::Shell' );
}

ok(defined($Devel::Trepan::Shell::VERSION), 
   "\$Devel::Trepan::Shell::VERSION number is set");
