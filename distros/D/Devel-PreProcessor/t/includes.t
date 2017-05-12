#!/usr/bin/perl

# This is a minimal test script that doesn't do much verification.

use strict;
use Test;
BEGIN { plan tests => 1, todo => [] }

use lib qw( ./lib );

use Devel::PreProcessor qw( Includes );

open TRASH, '>/dev/null';
select(TRASH);
Devel::PreProcessor::parse_file('t/includes.t');
select(STDOUT);

ok( 1 );

