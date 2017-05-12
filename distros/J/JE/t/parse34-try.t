#!perl -T

use Test::More tests => 9;
use strict;
use utf8;

#--------------------------------------------------------------------#
# Test 1: See if the module loads

BEGIN { use_ok('JE') };

#--------------------------------------------------------------------#
# Test 2: Parse code

my $j = new JE;

isa_ok( my $code = $j->parse( <<'--end--' ), 'JE::Code');

try { t4 = 4; throw 5 }
catch ( a ) { t4b = 5 }

try { t5 = 5 }
finally { t5b = 'b' }

try { t6a = 'a'; throw 'up' }
catch ( ateed ) { t6b = 'b' }
finally { t6c = 'de' }


try{t7 = 4; throw 5}catch(a){t7b = 5}
try{t8 = 5}finally{t8b = 'b'}
try{t9a = 'a'; throw 'up'}catch(ateed){t9b = 'b'}finally{t9c = 'de'}

--end--

#--------------------------------------------------------------------#
# Test 3: Run code

$code->execute;
is($@, '', 'execute code');

#--------------------------------------------------------------------#
# Tests 4-9: Check side-effects

ok( $j->prop('t4') eq 4 &&
    $j->prop('t4b') eq 5,  'try { } catch ( a ) { }'        );
ok( $j->prop('t5')  eq 5 &&
    $j->prop('t5b') eq 'b', 'try { } finally { }'               );
ok( $j->prop('t6a') eq 'a' && $j->prop('t6b') eq 'b' && 
    $j->prop('t6c') eq 'de', 'try { } catch ( a ) { } finally { }' );
ok( $j->prop('t7')  eq 4    &&
    $j->prop('t7b') eq 5,    'try{}catch(a){}'                        );
ok( $j->prop('t8')  eq 5    &&
    $j->prop('t8b') eq 'b',  'try{}finally{}'                           );
ok( $j->prop('t9a') eq 'a' && $j->prop('t9b') eq 'b' && 
    $j->prop('t9c') eq 'de', 'try{}catch(a){}finally{}'                  );
