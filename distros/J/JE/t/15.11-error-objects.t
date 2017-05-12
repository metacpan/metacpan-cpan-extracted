#!perl -T
do './t/jstest.pl' or die __DATA__

// 5 tests for prototypes
peval("
my $j = shift;
my $error_proto_id = id{$j->eval('Error.prototype')};
ok $j->eval('RangeError.prototype')->prototype->id == $error_proto_id,
	\"RangeError.prototype's prototype\";
ok $j->eval('ReferenceError.prototype')->prototype->id == $error_proto_id,
	\"ReferenceError.prototype's prototype\";
ok $j->eval('SyntaxError.prototype')->prototype->id == $error_proto_id,
	\"SyntaxError.prototype's prototype\";
ok $j->eval('TypeError.prototype')->prototype->id == $error_proto_id,
	\"TypeError.prototype's prototype\";
ok $j->eval('URIError.prototype')->prototype->id == $error_proto_id,
	\"URIError.prototype's prototype\";
", this);

// ===================================================
// 15.11.1 Error()
// 6 tests
// ===================================================

ok((e = Error()) instanceof Error, 'Error() is an Error')
is({}.toString.call(e), '[object Error]', 'class of Error()')
ok(!e.hasOwnProperty('message'), 'message exists not if none was provided')
is(e.message, 'Unknown error', 'inherited Unknown error message (Error())')
is(Error('dween').message, 'dween', "message is set to Error()'s 1st arg")
ok(Error(67).message === '67', "messages are stringified by Error()")


// ===================================================
// 15.11.2 new Error
// 6 tests
// ===================================================

ok((e = new Error()) instanceof Error, 'new Error() is an Error')
is({}.toString.call(e), '[object Error]', 'class of new Error()')
ok(!e.hasOwnProperty('message'),
  'message exists only if passed to new Error')
is(e.message, 'Unknown error', 'inherited error message (new Error)')
is(new Error('dween').message, 'dween',
  "message is set to new Error's 1st arg")
ok(new Error(67).message === '67',
  "messages are stringified by new Error()")


// ===================================================
// 15.11.3 Error
// ===================================================

// 10 tests (boilerplate stuff for constructors)
is(typeof Error, 'function', 'typeof Error');
is(Object.prototype.toString.apply(Error), '[object Function]',
	'class of Error')
ok(Error.constructor === Function, 'Error\'s prototype')
ok(Error.length === 1, 'Error.length')
ok(!Error.propertyIsEnumerable('length'),
	'Error.length is not enumerable')
ok(!delete Error.length, 'Error.length cannot be deleted')
is((Error.length++, Error.length), 1, 'Error.length is read-only')
ok(!Error.propertyIsEnumerable('prototype'),
	'Error.prototype is not enumerable')
ok(!delete Error.prototype, 'Error.prototype cannot be deleted')
ok((Error.prototype = 24, Error.prototype) !== 24,
	'Error.prototype is read-only')


// ===================================================
// 15.11.4 Error.prototype
// ===================================================

// 2 tests
is(Object.prototype.toString.apply(Error.prototype), '[object Error]',
	'class of Error.prototype')
peval('is shift->prototype, shift, "Error.prototype\'s prototype"',
	Error.prototype, Object.prototype)

// 2 tests
ok(Error.prototype.constructor === Error, 'Error.prototype.constructor')
ok(!Error.prototype.propertyIsEnumerable('constructor'),
	'Error.prototype.constructor is not enumerable')

// 5 tests
ok(Error.prototype.name === 'Error', 'Error.prototype.name')
is(typeof Error.prototype.message, 'string',
 'typeof Error.prototype.message')
is(Error.prototype.message, 'Unknown error','Error.prototype.message')
is(typeof Error.prototype.toString(), 'string', 'typeof toString()')
is(Error.prototype.toString(), 'Error: Unknown error', 'toString()')


// ===================================================
// 15.11.7 Error subclasses
// ===================================================

// All the tests in this block are run five times. The test counts below
// have to take this into account.
for(etype in {Range:0, Reference:0, Syntax:0, Type:0, URI:0}) {
 con/*structor*/ = etype + 'Error'

// 30 tests - 6 tests for constructors called as functions

 ok((e = this[con]()) instanceof Error, con + '() is a '+con)
 is({}.toString.call(e), '[object Error]', 'class of ' + con +'()')
 ok(!e.hasOwnProperty('message'), 'message exists only if provided')
 is(e.message, etype + ' error', 'inherited error message ('+con+'())')
 is(this[con]('dween').message, 'dween',
  "message is set to "+con+"()'s 1st arg")
 ok(this[con](67).message === '67', con+"() stringifies messages")

// 30 tests - 6 tests for constructors called as constructors

 ok((e = new this[con]()) instanceof this[con], 'new '+con+'() is a '+con)
 is({}.toString.call(e), '[object Error]', 'class of new ' +con)
 ok(!e.hasOwnProperty('message'),
   'message exists only if passed to new '+con)
 is(e.message, etype+' error', 'inherited error message (new '+con+')')
 is(new this[con]('dween').message, 'dween',
   "message is set to new "+con+"'s 1st arg")
 ok(new this[con](67).message === '67',
   "messages are stringified by new "+con)

// 50 tests (boilerplate stuff for constructors)
 is(typeof this[con], 'function', 'typeof '+con);
 is(Object.prototype.toString.apply(this[con]), '[object Function]',
  'class of '+con)
 ok(this[con].constructor === Function, con+'\'s prototype')
 ok(this[con].length === 1, con+'.length')
 ok(!this[con].propertyIsEnumerable('length'),
  con+'.length is not enumerable')
 ok(!delete this[con].length, con+'.length cannot be deleted')
 is((this[con].length++, this[con].length), 1, con+'.length is read-only')
 ok(!this[con].propertyIsEnumerable('prototype'),
  con+'.prototype is not enumerable')
 ok(!delete this[con].prototype, con+'.prototype cannot be deleted')
 ok((this[con].prototype = 24, this[con].prototype) !== 24,
  con+'.prototype is read-only')

// 10 tests - 2 tests for attributes of prototype objects
 is(Object.prototype.toString.apply(this[con].prototype),'[object Error]',
  'class of '+con+'.prototype')
 is(peval('shift->prototype',this[con].prototype), Error.prototype,
    etype+"Error.prototype\'s prototype")

// 10 tests - 2 tests for x.prototype.constructor
 ok(Error.prototype.constructor === Error, 'Error.prototype.constructor')
 ok(!Error.prototype.propertyIsEnumerable('constructor'),
  'Error.prototype.constructor is not enumerable')

// 25 tests - 5 tests for other properties of the prototype
 ok(this[con].prototype.name === con, etype+'Error.prototype.name')
 is(typeof this[con].prototype.message, 'string',
  'typeof '+con+'.prototype.message')
 is(this[con].prototype.message, etype+' error',con+'.prototype.message')
 is(typeof this[con].prototype.toString(), 'string',
   'typeof '+con+'.prototype.toString()')
 is(this[con].prototype.toString(), etype+'Error: '+etype+' error',
    con+'.prototype.toString()')

}
