#!perl -T

BEGIN { require './t/test.pl' }

use Test::More tests => 19;
use strict;
use utf8;

# Test 1: See if the module loads
BEGIN { use_ok('JE') };


my $j = new JE;


# Tests 2-3: Bind the ok and diag functions
isa_ok( $j->new_function( ok  => \&ok   ), 'JE::Object::Function' );
isa_ok( $j->new_function( diag => \&diag ), 'JE::Object::Function' );


# JS tests
defined $j->eval( <<'--end--' ) or die;

// ===================================================
// 11.3.1 ++
// ===================================================

/* Tests 4-11 */

x = void 0;
ok(isNaN(x++) && isNaN(x), 'undefined++')
x = null
ok(x++===0&&x===1,         'null++')
x = true
ok(x++===1&&x===2,         'true++')
x = false
ok(x++===0&&x===1,         'false++')
x = 'a'
ok(isNaN(x++) && isNaN(x), '"a"++')
x = '3'
ok(x++===3&&x===4,         '"3"++')
x = 4.2
ok(x++===4.2&&x===5.2,     '4.2++')
x = {}
ok(isNaN(x++) && isNaN(x), '{}++')


// ===================================================
// 11.3.2 --
// ===================================================

/* Tests 12-19 */

x = void 0;
ok(isNaN(x--) && isNaN(x), 'undefined--')
x = null
ok(x--===0&&x===-1,        'null--')
x = true
ok(x--===1&&x===0,         'true--')
x = false
ok(x--===0&&x===-1,        'false--')
x = 'a'
ok(isNaN(x--) && isNaN(x), '"a"--')
x = '3'
ok(x--===3&&x===2,         '"3"--')
x = 4.2
ok(x--===4.2&&x===3.2,     '4.2--')
x = {}
ok(isNaN(x--) && isNaN(x), '{}--')


--end--
