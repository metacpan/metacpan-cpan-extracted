#!perl -T

use Test::More tests => 4;
use strict;
use utf8;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->parse(''), 'JE::Code');

#--------------------------------------------------------------------#
# Tests 3-4: Run code

is($code->execute, 'undefined', 'execute code');
is($@, '', 'code should not return an error');
