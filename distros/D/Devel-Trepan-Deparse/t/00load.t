#!/usr/bin/env perl
use strict;
use warnings;
use lib '../lib';
use blib;

use Test::More tests => 2;
note( "Testing Devel::Trepan::Deparse $Devel::Trepan::Deparse::VERSION" );

BEGIN {
use_ok( 'Devel::Trepan::Deparse' );
}

ok(defined($Devel::Trepan::Deparse::VERSION),
   "\$Devel::Trepan::Deparse number is set");
