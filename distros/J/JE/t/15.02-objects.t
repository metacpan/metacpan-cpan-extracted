#!perl -T
do './t/jstest.pl' or die __DATA__

function keys(o) {
	var a = []
	for(a[a.length] in o);
	return a
}

// ===================================================
// 15.2.1 Object()
// ===================================================

// 12 tests for empty objects

o = Object();
ok(typeof o === 'object', 'typeof Object() w/o args')
ok(keys(o).length === 0, 'Object() w/o args')
ok(o.constructor === Object, 'Object().constructor')
ok(o.toString() === '[object Object]', 'Object().toString')

o = Object(null);
ok(typeof o === 'object', 'typeof Object(null)')
ok(keys(o).length === 0, 'Object(null)')
ok(o.constructor === Object, 'Object(null).constructor')
ok(o.toString() === '[object Object]', 'Object(null).toString')

o = Object(undefined);
ok(typeof o === 'object', 'typeof Object(undefined)')
ok(keys(o).length === 0, 'Object(undefined)')
ok(o.constructor === Object, 'Object(undefined).constructor')
ok(o.toString() === '[object Object]', 'Object(undefined).toString')


// 6 tests for type conversion

o = Object('fes')
ok(o.constructor === String, 'Object(str).constructor')
ok(o.valueOf() === 'fes', 'Object(str).valueOf')
o = Object(true)
ok(o.constructor === Boolean, 'Object(bool).constructor')
ok(o.valueOf() === true, 'Object(baal).valueOf')
o = Object(32)
ok(o.constructor === Number, 'Object(num).constructor')
ok(o.valueOf() === 32, 'Object(num).valueOf')

// 1 test
o = {}
ok (Object(o) === o, 'Object(obj)')


// ===================================================
// 15.2.2 new Object
// ===================================================

// 12 tests for empty objects

o = new Object();
ok(typeof o === 'object', 'typeof new Object() w/o args')
ok(keys(o).length === 0, 'new Object() w/o args')
ok(o.constructor === Object, 'new Object().constructor')
ok(o.toString() === '[object Object]', 'new Object().toString')

o = new Object(null);
ok(typeof o === 'object', 'typeof new Object(null)')
ok(keys(o).length === 0, 'new Object(null)')
ok(o.constructor === Object, 'new Object(null).constructor')
ok(o.toString() === '[object Object]', 'new Object(null).toString')

o = new Object(undefined);
ok(typeof o === 'object', 'typeof new Object(undefined)')
ok(keys(o).length === 0, 'new Object(undefined)')
ok(o.constructor === Object, 'new Object(undefined).constructor')
ok(o.toString() === '[object Object]', 'new Object(undefined).toString')


// 6 tests for type conversion

o = new Object('fes')
ok(o.constructor === String, 'new Object(str).constructor')
ok(o.valueOf() === 'fes', 'new Object(str).valueOf')
o = new Object(true)
ok(o.constructor === Boolean, 'new Object(bool).constructor')
ok(o.valueOf() === true, 'new Object(baal).valueOf')
o = new Object(32)
ok(o.constructor === Number, 'new Object(num).constructor')
ok(o.valueOf() === 32, 'new Object(num).valueOf')

// 1 test
o = {}
ok (new Object(o) === o, 'new Object(obj)')


// ===================================================
// 15.2.3 Object
// ===================================================

// 10 tests (boilerplate stuff for constructors)
is(typeof Object, 'function', 'typeof Object');
is(Object.prototype.toString.apply(Object), '[object Function]',
	'class of Object')
ok(Function.prototype.isPrototypeOf(Object), 'Object\'s prototype')
ok(Object.length === 1, 'Object.length')
ok(!Object.propertyIsEnumerable('length'),
	'Object.length is not enumerable')
ok(!delete Object.length, 'Object.length cannot be deleted')
is((Object.length++, Object.length), 1, 'Object.length is read-only')
ok(!Object.propertyIsEnumerable('prototype'),
	'Object.prototype is not enumerable')
ok(!delete Object.prototype, 'Object.prototype cannot be deleted')
cmp_ok((Object.prototype = 7, Object.prototype), '!=', 7,
	'Object.prototype is read-only')


// ===================================================
// 15.2.4 Object.prototype
// ===================================================

// 4 tests
peval('is shift->prototype, undef, "Object.prototype has no prototype"',
	Object.prototype)
is(Object.prototype.toString.apply(Object.prototype), '[object Object]',
	'class of Object.prototype')
ok(Object.prototype.constructor === Object, 'Object.prototype.constructor')
ok(!Object.prototype.propertyIsEnumerable('constructor'),
	'Object.prototype.constructor is not enumerable')


// ===================================================
// 15.2.4.2 Object.prototype.toString
// ===================================================

// This doesn’t need to be tested thoroughly here, since it gets tested
// everywhere else.

// 10 tests (boilerplate stuff for methods)
with(Object.prototype) {
is(typeof toString, 'function', 'typeof toString');
is(Object.prototype.toString.apply(toString), '[object Function]',
	'class of toString')
ok(toString.constructor === Function, 'toString\'s prototype')
$catched = false;
try{ new toString } catch(e) { $catched = e }
ok($catched, 'new toString fails')
ok(!('prototype' in toString), 'toString has no prototype property')
ok(toString.length === 0, 'toString.length')
ok(! toString.propertyIsEnumerable('length'),
	'toString.length is not enumerable')
ok(!delete toString.length, 'toString.length cannot be deleted')
is((toString.length++, toString.length), 0, 'toString.length is read-only')
ok(!Object.prototype.propertyIsEnumerable('toString'),
	'toString is not enumerable')
}

// 1 tests
ok(Object.prototype.toString.call({}) === '[object Object]',
	'toString returns a string')

// ===================================================
// 15.2.4.3 Object.prototype.toLocaleString
// ===================================================

// 10 tests (boilerplate stuff for methods)
method_boilerplate_tests(Object.prototype,'toLocaleString',0)

// 7 tests
ok(Object.prototype.toLocaleString.call({}) === '[object Object]',
	'Object.prototype.toLocaleString with an Object')
like(Object.prototype.toLocaleString.call(function(){}),
	/^function [\w\d]+\(/.toString(),
	'Object.prototype.toLocaleString with a Function')
is(Object.prototype.toLocaleString.call([]), '',
	'Object.prototype.toLocaleString with an Array')
is(Object.prototype.toLocaleString.call(.3), '0.3',
	'Object.prototype.toLocaleString with a Number')
is(Object.prototype.toLocaleString.call(true), 'true',
	'Object.prototype.toLocaleString with a Boolean')
is(Object.prototype.toLocaleString.call('sfo'), 'sfo',
	'Object.prototype.toLocaleString with a String')
is({toString:function(){return"Ush"}}.toLocaleString(),'Ush',
	'toLocaleString on an object with its own toString method')

// ===================================================
// 15.2.4.4 Object.prototype.valueOf
// ===================================================

// 10 tests (boilerplate stuff for methods)
with(Object.prototype) {
is(typeof valueOf, 'function', 'typeof valueOf');
is(Object.prototype.toString.apply(valueOf), 
	'[object Function]',
	'class of valueOf')
ok(valueOf.constructor === Function, 'valueOf\'s prototype')
$catched = false;
try{ new valueOf } catch(e) { $catched = e }
ok($catched, 'new valueOf fails')
ok(!('prototype' in valueOf), 'valueOf has no prototype property')
ok(valueOf.length === 0, 'valueOf.length')
ok(! valueOf.propertyIsEnumerable('length'),
	'valueOf.length is not enumerable')
ok(!delete valueOf.length, 'valueOf.length cannot be deleted')
is((valueOf.length++, valueOf.length), 0,
	 'valueOf.length is read-only')
ok(!Object.prototype.propertyIsEnumerable('valueOf'),
	'valueOf is not enumerable')
}

// 1 test
o = new String('');
ok(Object.prototype.valueOf.call(o) === o, 'valueOf returns this')


// ===================================================
// 15.2.4.5 Object.prototype.hasOwnProperty
// ===================================================

// 12 tests (boilerplate stuff for methods)
with(Object.prototype) {
is(typeof hasOwnProperty, 'function', 'typeof hasOwnProperty');
is(Object.prototype.toString.apply(hasOwnProperty), 
	'[object Function]',
	'class of hasOwnProperty')
ok(hasOwnProperty.constructor === Function, 'hasOwnProperty\'s prototype')
$catched = false;
try{ new hasOwnProperty } catch(e) { $catched = e }
ok($catched, 'new hasOwnProperty fails')
ok(!('prototype' in hasOwnProperty), 'hasOwnProperty has no prototype property')
ok(hasOwnProperty.length === 1, 'hasOwnProperty.length')
ok(! hasOwnProperty.propertyIsEnumerable('length'),
	'hasOwnProperty.length is not enumerable')
ok(!delete hasOwnProperty.length, 'hasOwnProperty.length cannot be deleted')
is((hasOwnProperty.length++, hasOwnProperty.length), 1,
	 'hasOwnProperty.length is read-only')
ok(hasOwnProperty() === false, 'hasOwnProperty() w/o args (false)')
ok(this.hasOwnProperty() === true, 'hasOwnProperty() w/o args (true)')
ok(!Object.prototype.propertyIsEnumerable('hasOwnProperty'),
	'hasOwnProperty is not enumerable')
}

// 3 tests
ok({}.hasOwnProperty('toString') === false,
	'hasOwnProperty returns false for an inherited one')
ok({}.hasOwnProperty('oenuteth') === false,
	'hasOwnProperty returns false for a nonexistent property')
ok({a:3}.hasOwnProperty('a') === true,
	'hasOwnProperty returning true')


// ===================================================
// 15.2.4.6 Object.prototype.isPrototypeOf
// ===================================================

// 11 tests (boilerplate stuff for methods)
with(Object.prototype) {
is(typeof isPrototypeOf, 'function', 'typeof isPrototypeOf');
is(Object.prototype.toString.apply(isPrototypeOf), 
	'[object Function]',
	'class of isPrototypeOf')
ok(isPrototypeOf.constructor === Function, 'isPrototypeOf\'s prototype')
$catched = false;
try{ new isPrototypeOf } catch(e) { $catched = e }
ok($catched, 'new isPrototypeOf fails')
ok(!('prototype' in isPrototypeOf), 'isPrototypeOf has no prototype property')
ok(isPrototypeOf.length === 1, 'isPrototypeOf.length')
ok(! isPrototypeOf.propertyIsEnumerable('length'),
	'isPrototypeOf.length is not enumerable')
ok(!delete isPrototypeOf.length, 'isPrototypeOf.length cannot be deleted')
is((isPrototypeOf.length++, isPrototypeOf.length), 1,
	 'isPrototypeOf.length is read-only')
ok(isPrototypeOf() === false, 'isPrototypeOf() w/o args')
ok(!Object.prototype.propertyIsEnumerable('isPrototypeOf'),
	'isPrototypeOf is not enumerable')
}

// 4 tests
ok(Object.prototype.isPrototypeOf('etetet') === false,
	'isPrototypeOf(primitve) returns false')
ok({}.isPrototypeOf(Object.prototype) === false,
	'isPrototypeOf(obj w/o prototype) returns false')
ok(Function.prototype.isPrototypeOf(new Function) === true,
	'thing.isPrototypeOf(obj) when thing is obj\'s prototype')
ok(Object.prototype.isPrototypeOf(new new Function) === true,
	'thing.isPrototypeOf(obj) when obj inherits indirectly from thing')


// ===================================================
// 15.2.4.7 Object.prototype. propertyIsEnumerable
// ===================================================


// 12 tests (boilerplate stuff for methods)
with(Object.prototype) {
is(typeof propertyIsEnumerable, 'function', 'typeof propertyIsEnumerable');
is(Object.prototype.toString.apply(propertyIsEnumerable), 
	'[object Function]',
	'class of propertyIsEnumerable')
ok(propertyIsEnumerable.constructor === Function,
	'propertyIsEnumerable\'s prototype')
$catched = false;
try{ new propertyIsEnumerable } catch(e) { $catched = e }
ok($catched, 'new propertyIsEnumerable fails')
ok(!('prototype' in propertyIsEnumerable),
	'propertyIsEnumerable has no prototype property')
ok(propertyIsEnumerable.length === 1, 'propertyIsEnumerable.length')
ok(! propertyIsEnumerable.propertyIsEnumerable('length'),
	'propertyIsEnumerable.length is not enumerable')
ok(!delete propertyIsEnumerable.length, 'propertyIsEnumerable.length cannot be deleted')
is((propertyIsEnumerable.length++, propertyIsEnumerable.length), 1,
	 'propertyIsEnumerable.length is read-only')
ok(propertyIsEnumerable() === false,
	'propertyIsEnumerable() w/o args')
ok({'undefined':0}.propertyIsEnumerable() === true,
	'propertyIsEnumerable() w/o args (true)')
ok(!Object.prototype.propertyIsEnumerable('propertyIsEnumerable'),
	'propertyIsEnumerable is not enumerable')
}

// 3 tests
ok({a:'b'}.propertyIsEnumerable('a') === true,
	'isPrototypeOf with the object\'s own property')
Object.prototype.foo = 'bar';
ok({}. propertyIsEnumerable('foo') === false,
	'propertyIsEnumerable ignores the prototype chain')
ok({}. propertyIsEnumerable('bar') === false,
	'propertyIsEnumerable with nonexistent properties')

// 10 tests for type conversion
ok(!propertyIsEnumerable(undefined),
	'propertyIsEnumerable(undefined)')
ok(!{}.propertyIsEnumerable(undefined),
	'propertyIsEnumerable(undefined) (nonexistent)')
ok({6:7}.propertyIsEnumerable(6),
	'propertyIsEnumerable(number)')
ok(!propertyIsEnumerable(6),
	'propertyIsEnumerable(number) (nonexistent)')
ok({'true':7}.propertyIsEnumerable(true),
	'propertyIsEnumerable(bool)')
ok(!propertyIsEnumerable(true),
	'propertyIsEnumerable(bool) (nonexistent)')
ok({'null':7}.propertyIsEnumerable(null),
	'propertyIsEnumerable(null)')
ok(!propertyIsEnumerable(null),
	'propertyIsEnumerable(null) (nonexistent)')
ok({'[object Object]':7}.propertyIsEnumerable({}),
	'propertyIsEnumerable(obj)')
ok(!propertyIsEnumerable({}),
	'propertyIsEnumerable(obj) (nonexistent)')


