#!/usr/bin/env perl
use strict;
use warnings;
use lib '../lib';
use blib;

use Test::More tests => 2;
note( "Testing Devel::Trepan::Disassemble $Devel::Trepan::Disassemble::VERSION" );

BEGIN {
use_ok( 'Devel::Trepan::Disassemble' );
}

ok(defined($Devel::Trepan::Disassemble::VERSION),
   "\$Devel::Trepan::Disassemble number is set");
