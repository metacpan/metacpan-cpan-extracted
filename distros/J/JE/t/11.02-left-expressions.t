#!perl -T

BEGIN { require './t/test.pl' }

use Test::More tests => 37;
use strict;
use utf8;

# Test 1: See if the module loads
BEGIN { use_ok('JE') };


my $j = new JE;


# Tests 2-3: Bind the ok and diag functions
isa_ok( $j->new_function( ok  => \&ok   ), 'JE::Object::Function' );
isa_ok( $j->new_function( diag => \&diag ), 'JE::Object::Function' );


# ===================================================
# 11.2.1 Property accessors
# ===================================================

## Tests 4-22 ##

my($lv, $base);

$lv = $j->eval('0 .Θοῦ');
$base = $lv->base;
ok $base->isa('JE::Number') && $base eq '0' &&
   $lv->property eq 'Θοῦ', 'primaryexpr . ident';
# Note: The base is not converted to an object when the lvalue is created
# (as described in the spec), but JavaScript can't tell, because an object
# is created when the property is accessed or when  a  function  is called
# (the latter is tested below).

$lv = $j->eval('function(){}.Κύριε');
$base = $lv->base;
ok $base->isa('JE::Object::Function') && $lv->property eq 'Κύριε',
   'function(){} . ident';

$lv = $j->eval('"φυλακὴν" [ "toString" ] . τῷ');
$base = $lv->base;
ok $base->id eq $j->eval('String.prototype.toString')->id &&
   $lv->property eq 'τῷ', 'memberexpr [ expr ] . ident';

$lv = $j->eval('"στόματί" . toString . μου');
$base = $lv->base;
ok $base->id eq $j->eval('String.prototype.toString')->id &&
   $lv->property eq 'μου', 'memberexpr . ident . ident';

$lv = $j->eval('new Object ( ) . καὶ');
$base = $lv->base;
ok $base->isa('JE::Object') && $lv->property eq 'καὶ',
   'new memberexpr ( ) . ident';

$lv = $j->eval('"θύραν" [ "περιοχῆς" ]');
$base = $lv->base;
ok $base->isa('JE::String') && $base eq 'θύραν' &&
   $lv->property eq 'περιοχῆς', 'primaryexpr [ expr ]';

$lv = $j->eval('function(){} [ "περὶ" ]');
$base = $lv->base;
ok $base->isa('JE::Object::Function') && $lv->property eq 'περὶ',
   'function(){} [ expr ]';

$lv = $j->eval('"τὰ" [ "toString" ] [ "χείλη" ]');
$base = $lv->base;
ok $base->id eq $j->eval('String.prototype.toString')->id &&
   $lv->property eq 'χείλη', 'memberexpr [ expr ] [ expr ]';

$lv = $j->eval('"μου." . toString [ "Μὴ" ]');
$base = $lv->base;
ok $base->id eq $j->eval('String.prototype.toString')->id &&
   $lv->property eq 'Μὴ', 'memberexpr . ident [ expr ]';

$lv = $j->eval('new Object ( ) [ "ἐκκλίνῆς" ]');
$base = $lv->base;
ok $base->isa('JE::Object') && $lv->property eq 'ἐκκλίνῆς',
   'new memberexpr ( ) [ expr ]';

$lv = $j->eval('Object ( ) . τὴν ');
$base = $lv->base;
ok $base->isa('JE::Object') && $lv->property eq 'τὴν',
   'memberexpr ( ) . ident';

$lv = $j->eval('function(){return Object}() ( ) . καρδίαν ');
$base = $lv->base;
ok $base->isa('JE::Object') && $lv->property eq 'καρδίαν',
   'callexpr ( ) . ident';

$lv = $j->eval('function(){return "μου"}() [ "toString" ] . εἰς ');
$base = $lv->base;
ok $base->id eq $j->eval('String.prototype.toString')->id &&
   $lv->property eq 'εἰς', 'callexpr [ expr ] . ident';

$lv = $j->eval('function(){return "λόγους"}() . toString . πονηρίας ');
$base = $lv->base;
ok $base->id eq $j->eval('String.prototype.toString')->id &&
   $lv->property eq 'πονηρίας', 'callexpr . ident . ident';

$lv = $j->eval('Object ( ) [ "τοῦ" ]');
$base = $lv->base;
ok $base->isa('JE::Object') && $lv->property eq 'τοῦ',
   'memberexpr ( ) [ expr ]';

$lv = $j->eval('function(){return Object}() ( ) [ "προφασίζεσθαι" ] ');
$base = $lv->base;
ok $base->isa('JE::Object') && $lv->property eq 'προφασίζεσθαι',
   'callexpr ( ) [ expr ]';

$lv = $j->eval('function(){return "προφάσεις"}() [ "toString" ] [ "ἐν" ]');
$base = $lv->base;
ok $base->id eq $j->eval('String.prototype.toString')->id &&
   $lv->property eq 'ἐν', 'callexpr [ expr ] [ expr ]';

$lv = $j->eval('function(){return "ἁμαρτίαις."}() . toString [ "Σὺν" ] ');
$base = $lv->base;
ok $base->id eq $j->eval('String.prototype.toString')->id &&
   $lv->property eq 'Σὺν', 'callexpr . ident [ expr ]';

is eval { $j->eval('[]["\ud800"]') }, 'undefined',
 'Arrays don\'t die on access to a property with a surrogate in its name.';


# JS tests
defined $j->eval( <<'--end--' ) or die;

// ===================================================
// 11.2.2 new
// ===================================================

/* Tests 23-8 */

function keys(obj) {
	var k = []
	for(k[k.length] in obj);
	return k
}

o = new Object;
ok(keys(o) == '' && o.constructor === Object,
	'"new memberexpr" when memberexpr returns a function');

error = false
try { new {} }
catch(E) { E instanceof TypeError && (error = 1) }
ok(error, '"new memberexpr" when memberexpr returns a non-function object')

error = false
try { new true }
catch(E) { E instanceof TypeError && (error = 1) }
ok(error, '"new memberexpr" when memberexpr does not return an object')

o = new Object();
ok(keys(o) == '' && o.constructor === Object,
	'"new memberexpr()" when memberexpr returns a function');

error = false
try { new {}() }
catch(E) { E instanceof TypeError && (error = 1) }
ok(error,
	'"new memberexpr()" when memberexpr returns a non-function object')

error = false
try { new true() }
catch(E) { E instanceof TypeError && (error = 1) }
ok(error, '"new memberexpr()" when memberexpr does not return an object')


// ===================================================
// 11.2.3 Function calls
// ===================================================

/* Tests 29-34 */

ok(function(){
	function x() { return this }
	return x()
   }() === this, 'lvalue() when the lvalue\'s base is a call object')

o = { method: function() { return this } }
ok( o.method() === o, 'lvalue()')
ok( (0,o.method)() === this, 'non_lvalue()')

error = false
try { o() }
catch(E) { E instanceof TypeError && (error = 1) }
ok(error, 'object() when object is not a function')

error = false
try { false() }
catch(E) { E instanceof TypeError && (error = 1) }
ok(error, 'thing() when thing is not an object')

Number.prototype.method = o.method
ok(typeof 0 .method() == 'object' && 0 .method().valueOf() === 0,
	'foo.bar() when foo is not an object')

// ===================================================
// 11.2.4 Argument lists
// ===================================================

/* Tests 35-7 */

0,function(){
	ok(Array.prototype.join.call(arguments, ',') === '',
		'empty argument list')
}(),
function(){
	ok(Array.prototype. join.call(arguments, ',') === '1',
		'argument list without comma')
}(1),
function(){
	ok(Array.prototype. join.call(arguments, ',') === '1,2',
		'argument list with a comma')
}(1,2)


--end--
