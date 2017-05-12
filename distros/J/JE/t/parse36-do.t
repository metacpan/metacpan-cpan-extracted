#!perl -T

use Test::More tests => 5;
use strict;
use utf8;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->parse( <<'--end--' ), 'JE::Code');

var t4 = 0, t5=0

do ++t4 
while ( 0 )
do++t5;while(0);


function with(){} function you(){}
var away, it = {}, can;

do { away; with(it); } while (you(can));

--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-5: Check side-effects

is( $j->prop('t4'), 1, 'do with white space'   );
is( $j->prop('t5'), 1, 'do without white space' );
