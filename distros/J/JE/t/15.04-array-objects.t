#!perl -T
do './t/jstest.pl' or die __DATA__

function joyne (ary) { // Unlike the built-in, this does not convert
	var ret = '';      // undefined to an empty string.
	for(var i = 0; i<ary.length;++i)
		ret +=(i?',':'')+(i in ary ? ary[i] : '-')
	return ret
}

function keys (o) {
	var a = []
	for(a[a.length] in o);
	a.sort()
	return a
}

// ===================================================
// 15.4.1 Array()
// ===================================================

// 5 tests (number of args != 1)
ok(Array().constructor === Array, 'prototype of retval of Array()')
is(Object.prototype.toString.apply(Array()), '[object Array]',
	'class of Array()')
ok(Array().length === 0, 'Array().length')
ok(Array(1,3,3).length === 3, 'Array(blah blah blah).length')
a =Array(1,"3",3) 
ok(a[0] === 1 && a[1]==='3' && a[2] ===3,
	'what happens to Array()\'s args')

// 9 tests (number of args == 1)
ok(Array(5).constructor === Array, 'prototype of retval of Array(num)')
is(Object.prototype.toString.apply(Array(4)), '[object Array]',
	'class of Array(num)')

error = false
try{Array(-67)}
catch(e){error = e}
ok(error instanceof RangeError, 'Array(-num)')

error = false
try{Array(38383783738773783)}
catch(e){error = e}
ok(error instanceof RangeError, 'Array(big num)')

ok(Array('5').length === 1, 'Array("num").length')
ok(Array('5')[0] === "5", 'Array("num")[0]')
ok(Array(new Number(6)).length === 1, 'Array(number obj)')
ok(Array("478887438888874347743").length === 1, 'Array("big num")')
is(Array('foo'), 'foo', 'Array(str)')


// ===================================================
// 15.4.2 new Array
// ===================================================

// 5 tests (number of args != 1)
ok(new Array().constructor === Array,	
	'prototype of retval of new Array()')
is(Object.prototype.toString.apply(new Array()), '[object Array]',
	'class of new Array()')
ok(new Array().length === 0, 'new Array().length')
ok(new Array(1,3,3).length === 3, 'new Array(blah blah blah).length')
a =new Array(1,"3",3) 
ok(a[0] === 1 && a[1]==='3' && a[2] ===3,
	'what happens to new Array()\'s args')

// 9 tests (number of args == 1)
ok(new Array(5).constructor === Array,
	'prototype of retval of new Array(num)')
is(Object.prototype.toString.apply(new Array(4)), '[object Array]',
	'class of new Array(num)')

error = false
try{new Array(-67)}
catch(e){error = e}
ok(error instanceof RangeError, 'new Array(-num)')

error = false
try{new Array(38383783738773783)}
catch(e){error = e}
ok(error instanceof RangeError, 'new Array(big num)')

ok(new Array('5').length === 1, 'new Array("num").length')
ok(new Array('5')[0] === "5", 'new Array("num")[0]')
ok(new Array(new Number(6)).length === 1, 'new Array(number obj)')
ok(new Array("478887438888874347743").length === 1, 'new Array("big num")')
is(new Array('foo'), 'foo', 'new Array(str)')


// ===================================================
// 15.4.3 Array
// ===================================================

// 10 tests (boilerplate stuff for constructors)
is(typeof Array, 'function', 'typeof Array');
is(Object.prototype.toString.apply(Array), '[object Function]',
	'class of Array')
ok(Array.constructor === Function, 'Array\'s prototype')
ok(Array.length === 1, 'Array.length')
ok(!Array.propertyIsEnumerable('length'),
	'Array.length is not enumerable')
ok(!delete Array.length, 'Array.length cannot be deleted')
is((Array.length++, Array.length), 1, 'Array.length is read-only')
ok(!Array.propertyIsEnumerable('prototype'),
	'Array.prototype is not enumerable')
ok(!delete Array.prototype, 'Array.prototype cannot be deleted')
cmp_ok((Array.prototype = 7, Array.prototype), '!=', 7,
	'Array.prototype is read-only')


// ===================================================
// 15.4.4: Array prototype
// ===================================================

// 3 tests
is(Object.prototype.toString.apply(Array.prototype),
	'[object Array]',
	'class of Array.prototype')
ok(Array.prototype.length === 0,
	'Array.prototype.length')
ok(peval('shift->prototype',Array.prototype) === Object.prototype,
	'Array.prototype\'s prototype')


// ===================================================
// 15.4.4.1 Array.prototype.constructor
// ===================================================

// 2 tests
ok(Array.prototype.hasOwnProperty('constructor'),
	'Array.prototype has its own constructor property')
ok(Array.prototype.constructor === Array,
	'value of Array.prototype.constructor')


// ===================================================
// 15.4.4.2: toString
// ===================================================

// 10 tests
method_boilerplate_tests(Array.prototype,'toString',0)

// 4 tests specific to toString
is([1,null,true,false,void 0,{},"kjd"].toString(),
	'1,,true,false,,[object Object],kjd',
	'toString')
name = 'toString stringifies functions inside the array'
try {
 is(
   [Array].toString(), Array.toString(),
   name
 )
}
catch(e) { fail(name); diag(e) }


try { Array.prototype.toString.apply(3) }
catch(it) { ok(it.message.substring(0,22) == 'Object is not an Array',
               "toString's error message")
            ok(it instanceof TypeError,
               "toString's error type") }


// ===================================================
// 15.4.4.3: toLocaleString
// ===================================================

// 10 tests
method_boilerplate_tests(Array.prototype,'toLocaleString',0)

// 3 tests specific to toLocaleString
is([1,null,true,false,void 0,{},"kjd"].toLocaleString(),
	'1,,true,false,,[object Object],kjd',
	'toLocaleString')

try { Array.prototype.toLocaleString.apply(3) }
catch(it) { ok(it.message.substring(0,22) == 'Object is not an Array')
            ok(it instanceof TypeError) }


// ===================================================
// 15.4.4.4: concat
// ===================================================

// 10 tests
method_boilerplate_tests(Array.prototype,'concat',1)

// 5 tests specific to concat
a = [1,2,3].concat(true,[,7,8,],"fff",{})
is (a.length, 9, 'array length after concat')
ok(a[0] === 1
 &&a[1] === 2
 &&a[2] === 3
 &&a[3] === true
 &&!(4 in a)
 &&a[5] === 7
 &&a[6] === 8
 &&a[7] === 'fff'
 &&a[8] == '[object Object]',
	'elements of array returned by concat') || diag(a)

o = {length: 78, 0:82}
a =Array.prototype.concat.call(o,[1,2,3])
is(a.length, 4,
	'length of array returned by concat with a non-array this value')
ok(a[0] == o && a == '[object Object],1,2,3',
	'elements of array returned by concat with a non-array this value')
is(typeof Array.prototype.concat.call(true)[0], 'object',
    '1st elem of array returned by concat when called w/a bool is an obj')


// ===================================================
// 15.4.4.5: join
// ===================================================

// 10 tests
method_boilerplate_tests(Array.prototype,'join',1)

// 16 tests specific to join
0,function(){
	var f = Array.prototype.join
	is (f.call({0:0}), '', 'join with no length')
	is (f.call({length:undefined,0:0}),'', 'join w/undefined length')
	is (f.call({length: true, 0:'usl/s'}), 'usl/s', 'join w/bool len')
	is (f.call({length: null, 0:'etet'}), '',' join with null length')
	is (f.call({length: {}, 0:'Upsot'}), '','join w/obj 4 length')
	is (f.call({length: '3', 1: 'Npd;;d'}),',Npd;;d,','join w/str len')
	is(f.call({length: 2.3, 1: 'g;'}), ',g;', 'join w/fractional len')
	is(f.call({length:-4294967290,1:'co'}), ',co,,,,','join w/neg len')
}()
is( [1,2,3].join(), '1,2,3', 'join w/ no args')
is([1,2,3].join(true),'1true2true3','join w/bool arg')
is([1,2,3].join(23),'1232233','join w/numeric arg')
is([1,2,3].join('stringy'),'1stringy2stringy3','join w/stringy arg')
is([1,2,3].join(null),'1null2null3','join w/null arg');
is([1,2,3].join({}),'1[object Object]2[object Object]3','join w/obj arg');
is([1,2,3].join(undefined),'1,2,3','join w/undef arg');
is([1,null,true,false,void 0,{},"kjd"].join(),
	'1,,true,false,,[object Object],kjd',
	'join w/different types of array elems')


// ===================================================
// 15.4.4.6: pop
// ===================================================

// 10 tests
method_boilerplate_tests(Array.prototype,'pop',0)

// 18 tests specific to pop
0,function(){
	var f = Array.prototype.pop
	var o = {0:0};;
	is (f.call(o), 'undefined', 'retval of pop with no length')
	is (o[0], 0,'pop w/no length does nothing')
	ok (o.length === 0, '  except set the length to 0')
	o = {length:undefined,0:0}
	is (f.call(o),'undefined', 'retval of pop w/undefined length')
	is (o.length, 0, 'pop w/undefined sets length to 0')
	o = {length: true, 0:'usl/s'}
	is (f.call(o), 'usl/s', 'pop w/bool len')
	is (o.length, 0, 'pop w/bool length sets the length')
	ok (!(0 in o), 'pop deletes a property of a non-array objct')
	is (f.call({length: null, 0:'etet'}),'undefined',' pop w/null len')
	is (f.call({length: {}, 0:'Upsot'}),void 0,'pop w/obj 4 length')
	is (f.call({length: '3', 1: 'Npd;;d'}),'undefined','pop w/str len')
	o = {length: 2.3, 1: 'g;'}
	is(f.call(o), 'g;', 'pop w/fractional len')
	is(o.length, 1, 'length after pop w/fraction length')
	o= {length:-4294967290,1:'co'}, f.call(o)
	ok(o.length === 5, 'pop w/neg len')
}()
a = []
is(a.pop(), undefined, 'pop with zero-length real array')
is(a.length, 0,'array length after pop on zero-length array');
a = [5,6,7,8,]
ok(a.pop() === 8, 'retval of "normal" array pop')
is(a,'5,6,7', 'what pop did to the array')


// ===================================================
// 15.4.4.7: push
// ===================================================

// 10 tests
method_boilerplate_tests(Array.prototype,'push',1)

// 18 tests specific to push
0,function(){
	var f = Array.prototype.push
	var o = {0:0};;
	is (f.call(o,8,9), 2, 'retval of push on obj with no length')
	is (o[0]+''+o[1], 89,'elems created by push w/no length')
	ok (o.length === 2,'length after push w/no length')||diag(o.length)
	o = {length:undefined,0:0}
	is (f.call(o,7),1, 'retval of push w/undefined length')
	is (o.length, 1, 'length after push on obj w/undefined length')
	o = {length: true, 0:'usl/s', 1:73}
	is (f.call(o,"ooo"), '2', 'push w/bool len')
	is (o.length, 2, 'length after push w/bool length')
	is (o[1], 'ooo', 'push overwrites existing props')
	is (f.call({length: null, 0:'etet'}),0,'push w/null len')
	is (f.call({length: {}, 0:'Upsot'}),0,'push w/obj 4 length')
	ok (f.call({length: '3', 1: 'Npd;;d'})===3,'push w/str len')||diag(typeof f.call({length: '3', 1: 'Npd;;d'}))
	o = {length: 2.3, 1: 'g;'}
	is(f.call(o,78), '3', 'push w/fractional len')
	is(o.length, 3, 'length after push w/fraction length')
	o= {length:-4294967290,1:'co'}, f.call(o)
	is(o.length, 6, 'push w/neg len')
}()
a = [1,2,3]
is(a.push(), 3, 'push on real array with no args')
is(a.length, 3,'array length after push real array w/no args');
ok(a.push(5.7,8,7) === 6, 'retval of "normal" array push')
is(a,'1,2,3,5.7,8,7', 'what push did to the array')


// ===================================================
// 15.4.4.8: reverse
// ===================================================

// 10 tests
method_boilerplate_tests(Array.prototype,'reverse',0)

// 13 tests specific to reverse
0,function(){
	var f = Array.prototype.reverse
	var o = {0:0};;
	f.call(o)
	is (keys(o), '0',
	 'reverse on obj w/no length appears not to do anything')
	o = {length:undefined,0:0}
	f.call(o)
	is (keys(o)+o[0]+o.length, '0,length0undefined',
		'reverse on obj w/undefined length appears to do nothing')
	o = {length: true, 0:'usl/s', 1:73}
	f.call(o)
	is(o.length+o[0]+o[1],'trueusl/s73',
		'reverse w/bool length likewise does nothing')
	is (keys(f.call({length: null, 0:'etet'})),'0,length',
		'reverse w/null len')
	is(keys(f.call({length:{},0:'Upsot'})),'0,length',
		'reverse w/obj 4 length')
	f.call(o = {length:'3',2:'Npd;;d'})
	is /*are, actually*/ (keys(o), '0,length',
	 'reverse on obj w/gaps in its numeric props adds & deletes props')
	f.call(o = {length: 10, 0: true, 2: false, 3: 78, 8: {}})
	is(o[1]+o[6]+o[7]+o[9], '[object Object]78falsetrue',
	 '  and the properties it adds have the right values')
	o = {length: 2.3, 1: 'g;'}
	is(f.call(o)[0], 'g;','reverse w/fractional len')
	o= {length:-4294967290,1:'co'}, f.call(o)
	is(o[4], 'co', 'reverse w/neg len')
}()
a = [1,2,3]
ok(a.reverse()=== a, 'reverse returns the object itself')
is(a, '3,2,1', 'reverse reverses the elements of a real array')
;(a = [1,,undefined,,]).reverse()
is(''+(0 in a)+(1 in a)+(2 in a)+(3 in a),
 'falsetruefalsetrue',
 "reverse's treatment of defined vs nonexistent properties in real arrays")
is(a.length, 4,'array length after reverse real array w/no args');


//...

// ===================================================
// 15.4.4.10: slice
// ===================================================

// 10 tests
method_boilerplate_tests(Array.prototype,'slice',2)

// 1 test for now
is(["one","two","three"].slice(1), "two,three", 'slice');

// ~~~ more tests
/*
different types for the length value; different numbers, too
different types for the first arg (start), including no args
first arg rounding
positive/negative start
start greater than length
negative start, the abs value of which > length
different types for the this value
undefined/omitted end
different types for the end value
end value rounding
negative end value
negative end, the abs value of which > length
end value greater than lengtnh
nonexistent properties less than length
*/


// ===================================================
// 15.4.4.11: sort
// ===================================================

// 10 tests
method_boilerplate_tests(Array.prototype,'sort',1)

// 1 test from RT #39462 (by Christian Forster)
function UserSubmit(user,submits) 
{
	this.user=user;
	this.submits=submits;
}

function UserSubmitSort (a, b)
{
	return a.submits - b.submits;
}


var um=new Array(
	new UserSubmit("a",3),
	new UserSubmit("bc",1),
	new UserSubmit("add",35),
	new UserSubmit("eaea",23)
);

um.sort(UserSubmitSort);

output = ''
for(i=0;i<um.length;i++)
{
	output+=(um[i].submits+" "+um[i].user+"\n");
}

is(output, '1 bc\n3 a\n23 eaea\n35 add\n', 'sort with a custom routine')


// 12 tests more
a=['a','b',undefined,,'d','e']
ok(a.sort()===a, 'sort returns its this value')
is(a[0]+a[1]+a[2]+a[3]+a[4]+(5 in a), 'abdeundefinedfalse',
	'sorting a real array')
is([2,10].sort(), '10,2', 'default sort is stringwise')

0,function(){
	var f = Array.prototype.sort
	var o = {0:'b',1:'a',2:undefined,4:'d',5:'e',length:6}
	f.call(o)
	is(a[0]+a[1]+a[2]+a[3]+a[4]+(5 in a), 'abdeundefinedfalse',
		'sorting a non-array object')

	var o = {0:0};;
	f.call(o)
	is (keys(o), '0',
	 'sort on obj w/no length appears not to do anything')
	o = {length:undefined,0:0}
	f.call(o)
	is (keys(o)+o[0]+o.length, '0,length0undefined',
		'sort on obj w/undefined length appears to do nothing')
	o = {length: true, 0:'usl/s', 1:73}
	f.call(o)
	is(o.length+o[0]+o[1],'trueusl/s73',
		'sort w/bool length likewise does nothing')
	is (keys(f.call({length: null, 0:'etet'})),'0,length',
		'sort w/null len')
	is(keys(f.call({length:{},0:'Upsot'})),'0,length',
		'sort w/obj 4 length')
	f.call(o = {length:'3',2:'Npd;;d','3':'a'})
	is /*are, actually*/ (keys(o), '0,3,length',
		'sort with str length')
	o = {length: 2.3, 1: 'g;'}
	is(f.call(o)[0], 'g;','sort w/fractional len')
	o= {length:-4294967290,1:'co',5:6,6:7}, f.call(o)
	is(keys(o), '0,1,6,length', 'sort w/neg len')
}()

// ...

// ===================================================
// 15.4.4.12: splice
// ===================================================

// 10 tests
method_boilerplate_tests(Array.prototype,'splice',2)

// 6 tests for fewer args than three
a = [1,2,3]
is(joyne(a.splice()), '', 'retval of argless splice')
is(joyne(a), '1,2,3', 'argless splice is of none effect');
is(joyne(a.splice(1)), '', 'retval of splice w/1 arg')
is(joyne(a), '1,2,3', 'splice w/1 arg hath none effect');
is(joyne(a.splice(1,1)), '2', 'retval of splice w/2 argz')
is(joyne(a), '1,3', 'effect of splice w/2 args');

// 10 tests for weird length values
a = {0:7,1:8,2:9,length:2.3}
is(joyne([].splice.call(a,1,7,6)), '8',
	'retval of splice on obj w/fractional len')
is( a[0] + '' + a[1] + a[2] + a.length, '7692',
	'affect of splice on obj with fractional length');
a = {length:"1"}
;[].splice.call(a)
is(typeof a.length, 'number', 'length is converted to a number by splice')
a = {length: -4294967290}
;[].splice.call(a,0,1)
is(a.length, 5, 'splice on obj w/negative length')
delete a.length
;[].splice.call(a,0,0,0)
is(a.length, 1, 'splice on obj w/no length')
a = {length: true}
;[].splice.call(a,0,0,0)
is(a.length, 2, 'splice on obj w/boolean length')
a = {length: null}
;[].splice.call(a,0,0,0)
is(a.length, 1, 'splice on obj w/null length')
a = {length: '2'}
;[].splice.call(a,0,0,0)
ok(a.length === 3, 'splice on obj w/string length') || diag (a.length)
a = {length: void 0}
;[].splice.call(a,0,0,0)
is(a.length, 1, 'splice on obj w/undef length')
a = {length: new String ("3")}
;[].splice.call(a,0,0,0)
ok(a.length === 4, 'splice on obj w/objectionable length')

// 18 tests for different start values
a = [1,2,3,4,5]
is(joyne(a.splice(2,1)), '3',
	'retval of splice with positive integer start')
is(joyne(a), '1,2,4,5', 'effect of splice with positive integer start');
is(joyne(a.splice(-3,1)), '2',
	'retval of splice with negative start')
is(joyne(a), '1,4,5', 'effect of splice with negative start');
is(joyne(a.splice(1.7,1,2,3,4)), '4',
	'retval of splice with fractional start')
is(joyne(a), '1,2,3,4,5', 'effect of splice with fractional start');
is(joyne(a.splice(true,1)), '2',
	'retval of splice with boolean start')
is(joyne(a), '1,3,4,5', 'effect of splice with boolean start');
is(joyne(a.splice(null,1)), '1',
	'retval of splice with null start')
is(joyne(a), '3,4,5', 'effect of splice with null start');
is(joyne(a.splice('2',1)), '5',
	'retval of splice with stringy start')
is(joyne(a), '3,4', 'effect of splice with stringy start');
is(joyne(a.splice(new String(0),1,7,8,9)), '3',
	'retval of splice with object start')
is(joyne(a), '7,8,9,4', 'effect of splice with objectionable start');
is(joyne(a.splice(undefined,1)), '7',
	'retval of splice with undefined start')
is(joyne(a), '8,9,4', 'effect of splice with undefined start');
is(joyne(a.splice(78,1,3)), '',
	'retval of splice with start > length')
is(joyne(a), '8,9,4,3', 'effect of splice with start > length');

// 20 tests for different delete counts
a = [1,2,3,4,5]
is(joyne(a.splice(2,-1)), '',
	'retval of splice with negative delete count')
is(joyne(a), '1,2,3,4,5', 'effect of splice with negative delete count');
is(joyne(a.splice(2,0)), '',
	'retval of splice with 0 for the delete count')
is(joyne(a), '1,2,3,4,5', 'effect of splice with 0 for the delete count');
is(joyne(a.splice(2,2)), '3,4',
	'retval of splice with positive integer delete count')
is(joyne(a), '1,2,5', 'effect of splice w/positive int delete count');
is(joyne(a.splice(0,2.3)), '1,2',
	'retval of splice with fractional delete count')
is(joyne(a), '5', 'effect of splice w/fractional delete count');
a = [1,2,3,4,5]
is(joyne(a.splice(2,7)), '3,4,5',
	'retval of splice with extra large delete count')
is(joyne(a), '1,2', 'effect of splice w/extra large delete count');
a = [1,2,3,4,5]
is(joyne(a.splice(2,true)), '3',
	'retval of splice with boolean delete count')
is(joyne(a), '1,2,4,5', 'effect of splice w/boolean delete count');
is(joyne(a.splice(2,'1')), '4',
	'retval of splice with stringy delete count')
is(joyne(a), '1,2,5', 'effect of splice w/stringy delete count');
is(joyne(a.splice(2,null)), '',
	'retval of splice with null delete count')
is(joyne(a), '1,2,5', 'effect of splice w/null delete count');
is(joyne(a.splice(2,undefined)), '',
	'retval of splice with undefined delete count')
is(joyne(a), '1,2,5', 'effect of splice w/undefined delete count');
is(joyne(a.splice(0,{toString: function(){return 2}})), '1,2',
	'retval of splice with object for the delete count')
is(joyne(a), '5', 'effect of splice w/object for the delete count');

// 5 tests for (non-)existent properties, and shifting of properties
a = [undefined,,3,5,7,,,undefined]
is(joyne(a.splice(0,3,"foo", void 0, void 0)), 'undefined,-,3',
  'splice retval: non-existent props, insert/remove same number of items')
is(joyne(a), 'foo,undefined,undefined,5,7,-,-,undefined',
  'splice effect: non-existent props, insert/remove same number of items')
a.splice(0,3)
is(joyne(a), '5,7,-,-,undefined',
  'splice shifting properties left')
a.splice(1,1,true,false)
is(joyne(a), '5,true,false,-,-,undefined',
  'splice shifting properties right')
a = {0: 7,1:8,2:9,length:3};
[].splice.call(a,0,1);
is(a[0]+''+a[1]+a[2]+' '+a.length, '899 2',
	"splice's weird behaviour when shifting left on a non-array obj");
	// (This is according to spec, but Safari and Opera don’t do this.
	//  SpiderMonkey does.)


// ...


