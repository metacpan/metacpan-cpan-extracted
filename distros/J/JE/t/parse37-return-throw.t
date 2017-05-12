#!perl -T

use Test::More tests => 7;
use strict;
use utf8;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->parse( <<'--end--' ), 'JE::Code');

up = 'down';

try { throw up }
catch(fire) { t4 = fire }

try { throw(up) }
catch(fire) { t5 = fire }

t6 = function(home) { return home }('dunno')

t7 = function(home) { return(home) }('dunno')

--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-7: Check side-effects

is( $j->prop('t4'), 'down', 'throw with white space'  );
is( $j->prop('t5'), 'down', 'throw without white space' );
is( $j->prop('t6'), 'dunno', 'return with white space'   );
is( $j->prop('t7'), 'dunno', 'return without white space' );
