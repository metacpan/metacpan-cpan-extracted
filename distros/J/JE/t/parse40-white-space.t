#!perl -T

use Test::More tests => 12;
use strict;
use utf8;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->parse( <<"--end--" ), 'JE::Code') or diag $@;
/* comment at start of code */var\tt4\ck=\f4//comment
var t5\xa0=\x{2001}5/*
*/var\nt6\r=\x{2028}6
var\x{2029}t7=7

t8=8\nt9=9\rt10=10\x{2028}t11=11\x{2029}t12=12


--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-12: Check side-effects

is( $j->prop("t$_"), $_ ) for 4..12;
