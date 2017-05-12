#!perl -T
do './t/jstest.pl' or die __DATA__


Array.prototype.joyne = function(){return peval('join ",",@{+shift}',this)}

// ===================================================
// 15.5.1: String as a function
// 7 tests
// ===================================================

ok(String() === '', 'String()')
ok(String(void 0) === 'undefined', 'String(undefined)')
ok(String(876) === '876', 'String(number)')
ok(String(true) === 'true', 'String(boolean)')
ok(String('ffo') === 'ffo', 'String(str)')
ok(String(null) === 'null', 'String(null)')
ok(String({}) === '[object Object]', 'String(object)')


// ===================================================
// 15.5.2: new String
// 9 tests
// ===================================================

ok(new String().constructor === String, 'prototype of new String')
is(Object.prototype.toString.apply(new String()), '[object String]',
	'class of new String')
ok(new String().valueOf() === '', 'value of new String')
ok(new String('foo').valueOf() === 'foo', 'value of new String(foo)')

ok(new String(void 0).valueOf() === 'undefined', 'new String(undefined)')
ok(new String(876).valueOf() === '876', 'new String(number)')
ok(new String(true).valueOf() === 'true', 'new String(boolean)')
ok(new String(null).valueOf() === 'null', 'new String(null)')
ok(new String({}).valueOf() === '[object Object]', 'new String(object)')


// ===================================================
// 15.5.3 String
// ===================================================

// 10 tests (boilerplate stuff for constructors)
is(typeof String, 'function', 'typeof String');
is(Object.prototype.toString.apply(String), '[object Function]',
	'class of String')
ok(String.constructor === Function, 'String\'s prototype')
ok(String.length === 1, 'String.length')
ok(!String.propertyIsEnumerable('length'),
	'String.length is not enumerable')
ok(!delete String.length, 'String.length cannot be deleted')
is((String.length++, String.length), 1, 'String.length is read-only')
ok(!String.propertyIsEnumerable('prototype'),
	'String.prototype is not enumerable')
ok(!delete String.prototype, 'String.prototype cannot be deleted')
cmp_ok((String.prototype = 7, String.prototype), '!=', 7,
	'String.prototype is read-only')


// ===================================================
// 15.5.3.2: fromCharCode
// ===================================================

// 10 tests
method_boilerplate_tests(String,'fromCharCode',1)

// 1 tests
is(String.fromCharCode(
	undefined,null,true,false,'a','3',{},NaN,+0,-0,Infinity,-Infinity,
	1,32.5,2147483648,3000000000,4000000000.23,5000000000,4294967296,
	4294967298.479,6442450942,6442450943.674,6442450944,6442450945,
	6442450946.74,-1,-32.5,-3000000000,-4000000000.23,-5000000000,
	-4294967298.479,-6442450942,-6442450943.674,-6442450944,
	-6442450945,-6442450946.74
), "\x00\x00\x01\x00\x00\x03\x00\x00\x00\x00\x00\x00\x01\x20\x00帀⠀\uf200"+
   "\x00\x02\ufffe\uffff\x00\x01\x02\uffff￠ꈀ\ud800\u0e00\ufffe\x02\x01" +
   "\x00\uffff\ufffe", 'fromCharCode')

// ===================================================
// 15.5.4: String prototype
// ===================================================

// 3 tests
is(Object.prototype.toString.apply(String.prototype),
	'[object String]',
	'class of String.prototype')
is(String.prototype, '',
	'String.prototype as string')
ok(peval('shift->prototype',String.prototype) === Object.prototype,
	'String.prototype\'s prototype')


// ===================================================
// 15.5.4.1 String.prototype.constructor
// ===================================================

// 2 tests
ok(String.prototype.hasOwnProperty('constructor'),
	'String.prototype has its own constructor property')
ok(String.prototype.constructor === String,
	'value of String.prototype.constructor')


// ===================================================
// 15.5.4.2: toString
// ===================================================

// 10 tests
method_boilerplate_tests(String.prototype,'toString',0)

// 3 tests for misc this values
0,function(){
	var f = String.prototype.toString;
	var testname='toString with number for this';
	try{f.call(8); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toString with object for this';
	try{f.call({}); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='toString with boolean for this';
	try{f.call(true); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
}()

// 1 test more
ok(new String("foo").toString() === 'foo', 'toString')


// ===================================================
// 15.5.4.3: valueOf
// ===================================================

// 10 tests
method_boilerplate_tests(String.prototype,'valueOf',0)

// 3 tests for misc this values
0,function(){
	var f = String.prototype.valueOf;
	var testname='valueOf with number for this';
	try{f.call(8); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='valueOf with object for this';
	try{f.call({}); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
	var testname='valueOf with boolean for this';
	try{f.call(true); fail(testname) }
	catch(e){ok(e instanceof TypeError,testname)}
}()

// 2 test more
ok(new String("foo").valueOf() === 'foo', 'valueOf with string object')
ok("foo".valueOf() === 'foo', 'valueOf with string')


// ===================================================
// 15.5.4.4: charAt
// ===================================================

// 10 tests
method_boilerplate_tests(String.prototype,'charAt',1)

// 3 tests for misc this values
0,function(){
	var f = String.prototype.charAt;
	is(f.call(87.3,1), 7, 'charAt with number for this')
	is(f.call({},0), '[', 'charAt with object for this')
	is(f.call(false,2), 'l', 'charAt with boolean for this')
}()

// 5 tests: various types for the pos
is('The best laid schemes o’ mice an’ men'.charAt(true),'h','charAt(bool)')
is('gang aft agley,'.charAt(null), 'g', 'charAt(null)')
is('And lea’e us nought but grief an’ pain'.charAt(undefined), "A",	
	'charAt(undef)')
is('for promised joy.'.charAt({}),'f','charAt(obj)')
is('—Robert Burns'.charAt("7"), ' ', 'charAt(str)')

// 4 tests more
ok("34567".charAt(1.7) === '4', 'charAt(non-integer)')
ok('hello'.charAt(-336) === '', 'charAt(negative)')
ok('hello'.charAt(377) === '', 'charAt(big number)')
is('\ud834\udd2b is the symbol for double flat'.charAt(7), 'h',
	"charAt with extra-BMP chars")


// ===================================================
// 15.5.4.5: charCodeAt
// ===================================================

// 10 tests
method_boilerplate_tests(String.prototype,'charCodeAt',1)

// 3 tests for misc this values
0,function(){
	var f = String.prototype.charCodeAt;
	is(f.call(87.3,1), 0x37, 'charCodeAt with number for this')
	is(f.call({},0), 0x5b, 'charCodeAt with object for this')
	is(f.call(false,2), 0x6c, 'charCodeAt with boolean for this')
}()

// 5 tests: various types for the pos
is('The best laid schemes o’ mice an’ men'.charCodeAt(true),0x68,
	'charCodeAt(bool)')
is('gang aft agley,'.charCodeAt(null), 0x67, 'charCodeAt(null)')
is('And lea’e us nought but grief an’ pain'.charCodeAt(undefined), 0x41,
	'charCodeAt(undef)')
is('for promised joy.'.charCodeAt({}),0x66,'charCodeAt(obj)')
is('—Robert Burns'.charCodeAt("7"), 32, 'charCodeAt(str)')

// 4 tests more
ok("34567".charCodeAt(1.7) === 0x34, 'charCodeAt(non-integer)')
ok(is_nan('hello'.charCodeAt(-336)), 'charCodeAt(negative)')
ok(is_nan('hello'.charCodeAt(377)), 'charCodeAt(big number)')
is('\ud834\udd2b is the symbol for double flat'.charCodeAt(7), 0x68,
	"charCodeAt with extra-BMP chars")


// ===================================================
// 15.5.4.6: concat
// ===================================================

// 10 tests
method_boilerplate_tests(String.prototype,'concat',1)

// 3 tests for misc this values
0,function(){
	var f = String.prototype.concat;
	is(f.call(87.3,1), '87.31', 'concat with number for this')
	is(f.call({},0), '[object Object]0', 'concat with object for this')
	is(f.call(false,2), 'false2', 'concat with boolean for this')
}()

// 2 test
ok(new String("ooooo").concat() === 'ooooo', 'concat with no args')
ok(new String('foo').concat(true,false,null,undefined,38.6,"foo",{},[,,])
	=== 'footruefalsenullundefined38.6foo[object Object],',
	'concat with args')

// ===================================================
// 15.5.4.7: indexOf
// ===================================================

// 10 tests
method_boilerplate_tests(String.prototype,'indexOf',1)

// 18 tests
0,function(){
	var f = String.prototype.indexOf;
	ok(f.call(778, '7') === 0, 'indexOf with number for this')
	ok(f.call({}, 'c') === 5, 'indexOf with object for this')
	ok(f.call(false, 'a') === 1, 'indexOf with boolean this')
}()
ok('undefined undefined'.indexOf(undefined) === 0,
	'indexOf with undefined search string')
ok('true true'.indexOf(true) === 0, 'indexOf w/boolean search str')
ok('null null'.indexOf(null) === 0, 'indexOf w/null search str');
ok ('3 3'.indexOf(3) === 0, 'lastIndex of with numeric serach string')
ok('[object Object] [object Object]'.indexOf({}) === 0,
	'indexOf with objectionable search string')

ok('   '.indexOf('', undefined) === 0, 'indexOf w/undefined pos')
	|| diag('   '.indexOf('', undefined) + ' !== 0')
ok('   '.indexOf('', false) === 0, 'indexOf w/boolean pos');
ok('   '.indexOf(' ', '1') === 1, 'indexOf w/str pos');
ok('   '.indexOf(' ', {}) === 0, 'indexOf w/objectionable pos')
ok('   '.indexOf(' ', null) === 0, 'indexOf w/null pos');

ok('   '.indexOf(' ', 1.2) === 1, 'indexOf w/ fractional pos');
ok('   '. indexOf(' ', -3) === 0, 'indexOf w/neg pos');
ok('   '. indexOf(' ', 76) === -1, 'indexOf w pos > length (failed)');
ok('   '. indexOf('', 76) === 3, 'indexOf w pos > length (matched)')
	|| diag('   '. indexOf('', 76) + ' !== 3') ;

ok('   '.indexOf('ntue') === -1, 'indexOf w/failed match')


// ===================================================
// 15.5.4.8: lastIndexOf
// ===================================================

// 10 tests
method_boilerplate_tests(String.prototype,'lastIndexOf',1)

// 18 tests
0,function(){
	var f = String.prototype.lastIndexOf;
	ok(f.call(778, '7') === 1, 'lastIndexOf with number for this')
	ok(f.call({}, 'c') === 12, 'lastIndexOf with object for this')
	ok(f.call(false, 'a') === 1, 'lastIndexOf with boolean this')
}()
ok('undefined undefined'.lastIndexOf(undefined) === 10,
	'lastIndexOf with undefined search string')
ok('true true'.lastIndexOf(true) === 5, 'lastIndexOf w/boolean search str')
ok('null null'.lastIndexOf(null) === 5, 'lastIndexOf w/null search str');
ok ('3 3'.lastIndexOf(3) === 2, 'lastIndex of with numeric serach string')
ok('[object Object] [object Object]'.lastIndexOf({}) === 16,
	'lastIndexOf with objectionable search string')

ok('   '.lastIndexOf('', undefined) === 3, 'lastIndexOf w/undefined pos')
ok('   '.lastIndexOf('', false) === 0, 'lastIndexOf w/boolean pos');
ok('   '.lastIndexOf(' ', '1') === 1, 'lastIndexOf w/str pos');
ok('   '.lastIndexOf(' ', {}) === 2, 'lastIndexOf w/objectionable pos')
ok('   '.lastIndexOf(' ', null) === 0, 'lastIndexOf w/null pos');

ok('   '.lastIndexOf(' ', 1.2) === 1, 'lastIndexOf w/ fractional pos');
ok('   '. lastIndexOf(' ', -3) === -1, 'lastIndexOf w/neg pos (failed)');
ok('   '. lastIndexOf('', -3) === 0, 'lastIndexOf w/neg pos (matched)');
ok('   '. lastIndexOf(' ', 76) === 2, 'lastIndexOf w pos > length');

ok('   '.lastIndexOf('ntue') === -1, 'lastIndexOf w/failed match')


// ===================================================
// 15.5.4.9: localeCompare
// ===================================================

// 10 tests
method_boilerplate_tests(String.prototype,'localeCompare',1)

// ~~~ I can’t test this properly yet, because I haven’t quite decided how
//     it should work.


// ===================================================
// 15.5.4.10: match
// ===================================================

// 10 tests
method_boilerplate_tests(String.prototype,'match',1)

// 3 tests: misc this values
0,function(){
	var f = String.prototype.match;
	is(f.call(778, '7[^7]'), '78',
		'match with number for this')
	is(f.call({}, 'c.'), 'ct', 'match with object for this')
	is(f.call(false, 'a.'), 'al', 'match with boolean this')
}()

// 10 tests: real RegExp objects
0,function(){
	var ret = '  a '.match(/(.)(?!\1)../)
	is({}.toString.call(ret), '[object Array]','class of match retval')
	is(ret.length, '2', 'length of match retval')
	is(ret, ' a , ', 'elements of match retval')
	ok(ret.index===1, 'match retval.index') || diag(typeof ret.index)
	ok(ret.input==='  a ', 'match retval.input')
	
	var ret = ' a '.match(/ ?/g);
	is({}.toString.call(ret), '[object Array]',
		'class of global match retval')
	is(ret.length, '4', 'length of global match retval')
	is(ret, ' ,, ,', 'elements of global match retval')
	ok(!('index' in ret), 'global match retval has no index property')
	ok(!('input' in ret), 'global match retval has no input property')

}()

// 12 tests: regexps of different types
0,function(){
	is(' true '.match(true), 'true','successful match(bool)')
	ok(' tru '.match(true) ===null,'failed match(bool)')
	ok(' null '.match(null),'successful match(null)')
	ok(' tru '.match(null) === null,'failed match(null)')
	is(' 45 '.match(45), '45','successful match(num)')
	ok(' 4 '.match(45) ===null,'failed match(num)')
	is(' undefined'.match(void 0), '',
		'match(undef)')
	is(' 45 '.match('4(\\d)'), '45,5','successful match(str)')
	ok(' 4 '.match('4(\\d)') ===null,'failed match(str)')
	is('undefined'.match({}), 'e','successful match(obj)')
	ok('4'.match({}) ===null,'failed match(obj)')
	is('ndefinedundefined'.match(),'', 'match without args')
}()


// ===================================================
// 15.5.4.11: replace
// ===================================================

// 10 tests
method_boilerplate_tests(String.prototype,'replace',2)

// 3 tests: different types for this
0,function(){
	var f = String.prototype.replace;
	ok(f.call(78,'8',93) === '793', 'replace with number for this')
	is(f.call({}, /c/g, 'd'), '[objedt Objedt]',
		'replace with object for this')
	is(f.call(false, 'a', 'bx'), 'fbxlse', 'replace with boolean this')
}()

// 2 tests: missing args
is('fundefinedoo'.replace(), 'fundefinedoo', 'replace without args')
is('fundefinedoo'.replace(/f/g), 'undefinedundeundefinedinedoo',
	'replace with one arg')

// 19 tests: non-global regular expression
0,function(){
	var stuff = []
	is(' foo fbb'.replace(/f(.)()\1/, function(){
		stuff.push(arguments)
	   }), ' undefined fbb',
	   'replace with non-global re and function returning undefined')
	is(stuff.length, 1,
		'non-global re causes function to be called just once')
	is(stuff[0].length, 5,
		'(non-global re) number of arguments passed to function')
	is(stuff[0][0], 'foo',
		'(non-global re) arg 0 is the matched text')
	is(stuff[0][1], 'o', 
		'(non-global re) arg 1 is the first capture')
	is(stuff[0][2], '', 
		'(non-global re) arg 2 is the next capture')
	ok(stuff[0][3] === 1, 
		'(non-global re) arg -2 is the offset')
	is(stuff[0][4], ' foo fbb', 
		'(non-global re) arg -2 is the original string')
	is('foo'.replace(/o/, function(){return 'string'}), 'fstringo',
		'replace with non-global re and function returning string')
	is('foo'.replace(/o/, function(){return 38.3}), 'f38.3o',
		'replace with non-global re and function returning number')
	is('annoying'.replace(/noy/, function(){return null}), 'annulling',
		'replace with non-global re and function returning null')
	is('foo'.replace(/o/, function(){return {}}), 'f[object Object]o',
		'replace with non-global re and function returning object')
	is('foo'.replace(/o/, function(){return false}), 'ffalseo',
		'replace with non-global re and function returning bool')
	is('foo'.replace(/o/, undefined), 'fundefinedo',
		'replace with non-global re and undefined replacement')
	is('foo'.replace(/o/, null), 'fnullo',
		'replace with non-global re and null replacement')
	is('foo'.replace(/o/, 5), 'f5o',
		'replace with non-global re and numeric replacement')
	is('foo'.replace(/o/, {}), 'f[object Object]o',
		'replace with non-global re and objectionable replacement')
	is('foo'.replace(/o/, true), 'ftrueo',
		'replace with non-global re and veracious replacement')
	is('fordo'.replace(
		/(o)(.)|(?!f)()/,
		"[$$-$&-$`-$'-$1-$2-$3-$01-$02-$03]"
	   ),'f[$-or-f-do-o-r--o-r-]do',
	   'replace with non-global re and $ replacements')
}()

// 25 tests: global regular expression
0,function(){
	var stuff = []
	is(' foo fbb'.replace(/f(.)()\1/g, function(){
		stuff.push(arguments)
	   }), ' undefined undefined',
	   'replace with global re and function returning undefined')
	is(stuff.length, 2,
		'global re causes function to be called multiple times')
	is(stuff[0].length, 5,
		'(global re) num of arguments passed to function 1st time')
	is(stuff[0][0], 'foo',
		'(global re) arg 0 is the matched text 1st time')
	is(stuff[0][1], 'o', 
		'(global re) arg 1 is the first capture 1st time')
	is(stuff[0][2], '', 
		'(global re) arg 2 is the next capture 1st time')
	ok(stuff[0][3] === 1, 
		'(global re) arg -2 is the offset 1st time')
	is(stuff[0][4], ' foo fbb', 
		'(global re) arg -2 is the original string 1st time')
	is(stuff[1].length, 5,
		'(global re) num of arguments passed to function 2nd time')
	is(stuff[1][0], 'fbb',
		'(global re) arg 0 is the matched text 2nd time')
	is(stuff[1][1], 'b', 
		'(global re) arg 1 is the first capture 2nd time')
	is(stuff[1][2], '', 
		'(global re) arg 2 is the next capture 2nd time')
	ok(stuff[1][3] === 5, 
		'(global re) arg -2 is the offset 2nd time')
	is(stuff[1][4], ' foo fbb', 
		'(global re) arg -2 is the original string 2nd time')
	is('foo'.replace(/o/g, function(){return 'str'}), 'fstrstr',
		'replace with global re and function returning string')
	is('foo'.replace(/o/g, function(){return 38.3}), 'f38.338.3',
		'replace with global re and function returning number')
	is('nnoigno'.replace(/no/g,function(){return null}), 'nnullignull',
		'replace with global re and function returning null')
	is('foo'.replace(/o/g, function(){return {}}),
	   'f[object Object][object Object]',
		'replace with global re and function returning object')
	is('foo'.replace(/o/g, function(){return false}), 'ffalsefalse',
		'replace with global re and function returning bool')
	is('foo'.replace(/o/g, undefined), 'fundefinedundefined',
		'replace with global re and undefined replacement')
	is('foo'.replace(/o/g, null), 'fnullnull',
		'replace with global re and null replacement')
	is('foo'.replace(/o/g, 5), 'f55',
		'replace with global re and numeric replacement')
	is('foo'.replace(/o/g, {}), 'f[object Object][object Object]',
		'replace with global re and objectionable replacement')
	is('foo'.replace(/o/g, true), 'ftruetrue',
		'replace with global re and boolean replacement')
	is('fordo'.replace(
		/(o)(.?)|x()/g,
		"[$$-$&-$`-$'-$1-$2-$3-$01-$02-$03]"
	   ),'f[$-or-f-do-o-r--o-r-]d[$-o-ford--o---o--]',
	   'replace with global re and $ replacements')
}()

// 5 tests: different types for the searchValue
is('foo7'.replace(7,8), 'foo8', 'replace with numeric first arg')
is('footrue'.replace(true,8), 'foo8', 'replace with boolean first arg')
is('foo[object Object]'.replace({},8), 'foo8',
	'replace with objectionable first arg')
is('foonull'.replace(null,8), 'foo8', 'replace with null first arg')
is('fooundefined'.replace(void 0,8), 'foo8',
	'replace with undefined first arg')

// 17 tests: string search
0,function(){
	var stuff = []
	is('f.foo fbb'.replace('f.', function(){
		stuff.push(arguments)
	   }), 'undefinedfoo fbb',
	   'replace with search string and function returning undefined')
	is(stuff.length, 1,
		'string search causes function to be called just once')
	is(stuff[0].length, 3,
		'(string search) number of arguments passed to function')
	is(stuff[0][0], 'f.',
		'(string search) arg 0 is the matched text')
	ok(stuff[0][1] === 0, 
		'(string search) arg 1 is the offset')
	is(stuff[0][2], 'f.foo fbb', 
		'(string search) arg 2 is the original string')
	is('foo'.replace('o', function(){return 'string'}), 'fstringo',
		'replace with search string and function returning string')
	is('foo'.replace('o', function(){return 38.3}), 'f38.3o',
		'replace with search string and function returning number')
	is('annoying'.replace('noy', function(){return null}), 'annulling',
		'replace with search string and function returning null')
	is('foo'.replace('o', function(){return {}}), 'f[object Object]o',
		'replace with search string and function returning object')
	is('foo'.replace('o', function(){return false}), 'ffalseo',
		'replace with search string and function returning bool')
	is('foo'.replace('o', undefined), 'fundefinedo',
		'replace with search string and undefined replacement')
	is('foo'.replace('o', null), 'fnullo',
		'replace with search string and null replacement')
	is('foo'.replace('o', 5), 'f5o',
		'replace with search string and numeric replacement')
	is('foo'.replace('o', {}), 'f[object Object]o',
		'replace with search string and objectionable replacement')
	is('foo'.replace('o', true), 'ftrueo',
		'replace with search string and boolean replacement')
	is('fordo'.replace(
		'or',
		"[$$-$&-$`-$']"
	   ),'f[$-or-f-do]do',
	   'replace with search string and $ replacements')
}()

// 1 test
is("$1,$2".replace(/(\$(\d))/g, "$$1-$1$2"), "$1-$11,$1-$22",
	"$ example from the spec.")


// ===================================================
// 15.5.4.12: search
// ===================================================

// 10 tests
method_boilerplate_tests(String.prototype,'search',1)

// 3 tests: misc this values
0,function(){
	var f = String.prototype.search;
	is(f.call(778, '7[^7]'), 1,
		'search with number for this')
	is(f.call({}, 'c.'), '5', 'search with object for this')
	is(f.call(false, 'a.'), '1', 'search with boolean this')
}()

// 16 tests
ok('   a '.search(/(.)(?!\1)../) === 2, 'search with RegExp')
ok('   a '.search(/(.)(?!\1).../) === -1, 'failed search with RegExp')
ok(' a a a a'.search(/\w/g) === 1, 'search with global RegExp')
ok(' a a a a'.search(/b/g) === -1, 'failed search with global RegExp')
is(' true '.search(true), '1','successful search(bool)')
is(' tru '.search(true), -1,'failed search(bool)')
is(' null '.search(null),1,'successful search(null)')
is(' tru '.search(null), -1,'failed search(null)')
is('  45 '.search(45), 2,'successful search(num)')
is(' 4 '.search(45),-1,'failed search(num)')
is(' undefined'.search(void 0), 0,
	'search(undef)')
is(' 345 '.search('4(\\d)'), 2,'successful search(str)')
is(' 4 '.search('4(\\d)'),-1,'failed search(str)')
is('undefined'.search({}), 3,'successful search(obj)')
is('4'.search({}),-1,'failed search(obj)')
is('ndefinedundefined'.search(),0, 'search without args')



// ===================================================
// 15.5.4.13: slice
// ===================================================

// 10 tests
method_boilerplate_tests(String.prototype,'slice',2)

// 3 tests: misc this values
0,function(){
	var f = String.prototype.slice;
	is(f.call(7789, 2,3), 8,
		'slice with number for this')
	is(f.call({}, 2,4), 'bj', 'slice with object for this')
	is(f.call(false, 3,6), 'se', 'search with boolean this')
}()

// 21 tests
ok('foo'.slice() === 'foo', 'slice without args')
is('foo'.slice(undefined), 'foo','slice(undefined)')
is('foo'.slice(null),'foo','slice(null)')
is('foo'.slice(true),'oo','slice(bool)')
is('foo'.slice('2'),'o','slice(str)')
is('foo'.slice({}),'foo','slice(obj)')
is('foo'.slice(1.7),'oo','slice(fraction)')
is('foo'.slice(1,void 0),'oo','slice with undefined endpoint')
is('foo'.slice(1,null),'','slice with null endpoint')
is('foo'.slice(1,'2'),'o','slice with string endpoint')
is('foo'.slice(0,{}),'','slice with objectionable endpoint')
is('foo'.slice(0,true),'f','slice with boolean endpoint')
is('bar'.slice(-1,3),'r','slice with negative start')
is('bar'.slice(0,-1),'ba','slice with negative endpoint')
is('bar'.slice(-2,-1),'a','slice with two negs')
is('bar'.slice(0,2),'ba','slice with two positives')
is('bar'.slice(-7,2),'ba',
	'slice w/negative start reaching beyond the start of the string')
is('bar'.slice(0,-20),'',
	'slice w/negative end reaching beyond the start of the string')
is('bar'.slice(78,79),'', 'slice with start > length')
is('bar'.slice(1,79),'ar','slice with end > length')
is('bar'.slice(2,1),'','slice with positive end > positive start')


// ===================================================
// 15.5.4.14: split
// ===================================================

// 10 tests
method_boilerplate_tests(String.prototype,'split',2)

// 8 tests
0,function(){
	var f = String.prototype.split;
	is(f.call(78,'8'), '7,', 'split with number for this')
	is(f.call({}, 'c'), '[obje,t Obje,t]',
		'split with object for this')
	is(f.call(false, 'a'), 'f,lse', 'split with boolean this')
}()
ok(Object.prototype.toString.apply('foo'.split('bar')) == '[object Array]',
   'split return type')
is('o-o-o-o-o'.split('-',-4294967200).joyne(), 'o,o,o,o,o',
	'split w/negative limit')
is('o-o-o-o-o'.split('-',3.2).joyne(), 'o,o,o','split w/fractional limit')
is('foo'.split(), 'foo', '"foo".split without args')
is(''.split(), '','"".split without args')

// 9 tests
is(''.split(/foo/,undefined).length, 1,
	'failed splitting of empty string on regexp with undefined limit')
is(''.split(/(?:)/,undefined).length, 0,
	'successful splitting of empty string on re with undefined limit')
is('ofxfoo'.split(/(?:f(?!o))?(?!fo)/,undefined).joyne(), 'o,xf,o,o',
	'splitting of non-empty string on re with undefined limit')
is('ofxfoo'.split(/f(x)?/,undefined).joyne(), 'o,x,,undefined,oo',
	'splitting of non-empty string on re w/captures & undefined limit')
is(''.split('foo',undefined).length, 0,
	'failed splitting of empty string on string with undefined limit')
is(''.split('',undefined).joyne(), '',
	'successful splitting of empty string on str with undefined limit')
is('foo'.split('o',undefined).joyne(), 'f,,',
	'split non-empty string on string with undefined limit')
is('foo'.split('',undefined).joyne(), 'f,o,o',
	'split non-empty string on empty string with undefined limit')
is('foo'.split(undefined,undefined).joyne(), 'foo',
	'split non-empty string on undefined with undefined limit')

// 9 tests
is(''.split(/foo/).length, 1,
	'failed splitting of empty string on regexp with no limit')
is(''.split(/(?:)/).length, '0',
	'successful splitting of empty string on re with no limit')
is('ofxfoo'.split(/(?:f(?!o))?(?!fo)/).joyne(), 'o,xf,o,o',
	'splitting of non-empty string on re with no limit')
is('ofxfoo'.split(/f(x)?/).joyne(), 'o,x,,undefined,oo',
	'splitting of non-empty string on re w/captures & no limit')
is(''.split('foo').length, 0,
	'failed splitting of empty string on string with no limit')
is(''.split('').joyne(), '',
	'successful splitting of empty string on str with no limit')
is('foo'.split('o').joyne(), 'f,,',
	'split non-empty string on string with no limit')
is('foo'.split('').joyne(), 'f,o,o',
	'split non-empty string on empty string with no limit')
is('foo'.split(undefined).joyne(), 'foo',
	'split non-empty string on undefined with no limit')

// 11 tests
is(''.split(/foo/,0).length, 0,
	'failed splitting of empty string on regexp with limit')
is(''.split(/(?:)/,7).length, 0,
	'successful splitting of empty string on re with limit')
is('ofxfoo'.split(/(?:f(?!o))?(?!fo)/,3).joyne(), 'o,xf,o',
	'splitting of non-empty string on re with limit')
is('ofxfooooo'.split(/x(f)(o)(o)/,3).joyne(), 'of,f,o',
	'splitting of non-empty string on re w/captures & limit')
is('ofxfooooo'.split(/x(f)(o)(o)/,29).joyne(), 'of,f,o,o,ooo',
	'splitting of non-empty string on re w/captures & unreached limit')
is(''.split('foo',7).length, 0,
	'failed splitting of empty string on string with limit')
is(''.split('',0).length, 0,
	'successful splitting of empty string on str with limit')
is('foo'.split('o',2).joyne(), 'f,',
	'split non-empty string on string with limit')
is('foo'.split('',2).joyne(), 'f,o',
	'split non-empty string on empty string with limit')
is('foo'.split('',23).joyne(), 'f,o,o',
	'split non-empty string on empty string with unreached limit')
is('foo'.split(undefined,2).joyne(), 'foo',
	'split non-empty string on undefined with limit')

// 4 tests
is('fo[object Object]o'.split({}), 'fo,o', 'split on object')
is('fo[trueo'.split(true), 'fo[,o', 'split on boolean')
is('fo[tru5o'.split(5), 'fo[tru,o', 'split on number')
is('fo[nulltru5o'.split(null), 'fo[,tru5o', 'split on null')

// 3 tests: Examples from the spec.
is('ab'.split(/a*?/), 'a,b', 'split on /a*?/')
is('ab'.split(/a*/).joyne(), ',b', 'split on /a*/')
is("A<B>bold</B>and<CODE>coded</CODE>".split(/<(\/)?([^<>]+)>/).joyne(),
	'A,undefined,B,bold,/,B,and,undefined,CODE,coded,/,CODE,',
	'long spec. example')

// 2 tests more
is('aardvark'.split(/a*?/), 'a,a,r,d,v,a,r,k', 'aardvark')
is('aardvark'.split(/(?=\w)a*?/), 'a,a,r,d,v,a,r,k', 'the aardvark again')


// ===================================================
// 15.5.4.15: substring
// ===================================================

// 10 tests
method_boilerplate_tests(String.prototype,'substring',2)

// 3 tests: misc this values
0,function(){
	var f = String.prototype.substring;
	is(f.call(7789, 2,3), 8,
		'substring with number for this')
	is(f.call({}, 2,4), 'bj', 'substring with object for this')
	is(f.call(false, 3,6), 'se', 'search with boolean this')
}()

// 19 tests
ok('foo'.substring() === 'foo', 'substring without args')
is('foo'.substring(undefined), 'foo','substring(undefined)')
is('foo'.substring(null),'foo','substring(null)')
is('foo'.substring(true),'oo','substring(bool)')
is('foo'.substring('2'),'o','substring(str)')
is('foo'.substring({}),'foo','substring(obj)')
is('foo'.substring(1.7),'oo','substring(fraction)')
is('foo'.substring(1,void 0),'oo','substring with undefined endpoint')
is('foo'.substring(1,null),'f','substring with null endpoint')
is('foo'.substring(1,'2'),'o','substring with string endpoint')
is('foo'.substring(0,{}),'','substring with objectionable endpoint')
is('foo'.substring(0,true),'f','substring with boolean endpoint')
is('bar'.substring(-1,3),'bar','substring with negative start')
is('bar'.substring(0,-1),'','substring with negative endpoint')
is('bar'.substring(-2,-1),'','substring with two negs')
is('bar'.substring(0,2),'ba','substring with two positives')
is('bar'.substring(78,79),'', 'substring with start > length')
is('bar'.substring(1,79),'ar','substring with end > length')
is('bar'.substring(2,1),'a','substring with positive end > positive start')


// ===================================================
// 15.5.4.16: toLowerCase
// ===================================================

// 10 tests
method_boilerplate_tests(String.prototype,'toLowerCase',0)

// 2 test
is(typeof ''.toLowerCase(), 'string', 'typeof toLowerCase')
is('ßSSΣσς κλσ σδφκλΞΛΚΔΞΣΦΣΔΞΚΛΦ нДСФКЛФДЛСФ ontTN EUHO OETNU'
   .toLowerCase(),
   'ßssσσς κλσ σδφκλξλκδξσφσδξκλφ ндсфклфдлсф onttn euho oetnu',
   'toLowerCase')


// ===================================================
// 15.5.4.17: toLocaleLowerCase
// ===================================================

// 10 tests
method_boilerplate_tests(String.prototype,'toLocaleLowerCase',0)

// ~~~ ?

// ===================================================
// 15.5.4.18: toUpperCase
// ===================================================

// 10 tests
method_boilerplate_tests(String.prototype,'toUpperCase',0)

// 2 test
is(typeof ''.toUpperCase(), 'string', 'typeof toUpperCase')
is('ßSSΣσς κλσ σδφκλΞΛΚΔΞΣΦΣΔΞΚΛΦ нДСФКЛФДЛСФ ontTN EUHO OETNU'
   .toUpperCase(),
   'SSSSΣΣΣ ΚΛΣ ΣΔΦΚΛΞΛΚΔΞΣΦΣΔΞΚΛΦ НДСФКЛФДЛСФ ONTTN EUHO OETNU',
   'toUpperCase')


// ===================================================
// 15.5.4.19: toLocaleUpperCase
// ===================================================

// 10 tests
method_boilerplate_tests(String.prototype,'toLocaleUpperCase',0)

// ~~~ ?

// ===================================================
// 15.5.5.1: length
// ===================================================

// We have to test this both for objects and strings, since JE sneakily
// foregoes converting a string into an object, for speed’s sake. (In other
// words, we have two implementations to test.)

// 6 tests
s = "hello"
so = new String("hello")
fail = false
for(var i in s) if(i == 'length') { fail = true; break }
ok(!fail, "unenumerability of string.length")
fail = false
for(var i in so) if(i == 'length') { fail = true; break }
ok(!fail, "unenumerability of string object.length")
is(delete s.length, false, 'undeletability of string.length')
is(delete so.length, false, 'undeletability of string object.length')
s.length=6
ok(s.length===5,'unwritability (and value) of string.length')
so.length=6
ok(so.length===5,'unwritability (and value) of string object.length')

diag("To do: finish locale tests")
