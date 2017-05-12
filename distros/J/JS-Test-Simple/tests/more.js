new JSAN('../lib').use('Test.More');
plan({tests: 35});

ok( 2 == 2,             'two is two is two is two' );
is( "foo", "foo",       'foo is foo' );
isnt( "foo", "bar",     'foo isnt bar');
like("fooble", /^foo/,   'foo is like fooble');
like("FooBle", /foo/i,   'foo is like FooBle');
like("/usr/local/pr0n/", '^\/usr\/local', 'regexes with slashes in like' );

unlike("fbar", /^bar/,    'unlike bar');
unlike("FooBle", /foo/,   'foo is unlike FooBle');
unlike("/var/local/pr0n/", '^\/usr\/local','regexes with slashes in unlike' );

var foo = ['foo', 'bar', 'baz'];
unlike(foo, /foo/, 'An array is unlike foo');

canOK('Test.Builder', 'reset', 'plan', 'skipAll', 'ok', 'isEq',
      'isNum', 'isntEq', 'isntNum', 'like', 'unlike', 'cmpOK', 'skip',
      'todoSkip', 'skipRest', 'diag', 'todo');

var safari = typeof navigator != "undefined"
  && /Safari|Konqueror/.test(navigator.userAgent)
    ? true
    : false;
if (safari) skip("http://bugs.webkit.org/show_bug.cgi?id=3537", 1);
else canOK(new Test.Builder(), 'reset', 'plan', 'skipAll', 'ok', 'isEq',
           'isNum', 'isntEq', 'isntNum', 'like', 'unlike', 'cmpOK', 'skip',
           'todoSkip', 'skipRest', 'diag', 'todo');

isaOK([], "Array");
isaOK({}, "Object");
isaOK(Test.Builder.Test, "Test.Builder");
isaOK(Test.Builder.Test, "Object")

Test.More.pass('pass() passed');

isDeeply(['this', 'that', 'whatever'], ['this', 'that', 'whatever'],
         'isDeeply() with simple arrays');
isDeeply({foo: 42, bar: 23}, {foo: 42, bar: 23},
         'isDeeply() with simple objects');
isSet(['this', 'that', 'whatever'], ['that', 'whatever', 'this'],
      'isSet() with simple sets');

var complexArray1 = [
    ['this', 'that', 'whatever'],
    {foo: 42, bar: 23},
    "moo",
    "yarrow",
    [488, 10, 29]
];
var complexArray2 = [
    ['this', 'that', 'whatever'],
    {foo: 42, bar: 23},
    "moo",
    "yarrow",
    [488, 10, 29]
];
isDeeply( complexArray1, complexArray2, 'isDeeply() with complex arrays' );
isSet( complexArray1, complexArray2, 'isSet() with complex arrays' );

var array1 = [
    'this',
    'that',
    'whatever',
    {foo: 23, bar: 42}
];
var array2 = [
    'this',
    'that',
    'whatever',
    {foo: 24, bar: 42}
];

var stack = [], seen = [];
ok(!Test.More._eqArray(array1, array2, stack, seen),
   '_eqArray() with slightly different complicated arrays' );
stack = [];
seen  = [];
ok(!Test.More._eqSet(array1, array2, stack, seen), 
   '_eqSet() with slightly different complicated arrays' );

var hash1 = {
    foo: 23,
    bar: ['this', 'that', 'whatever'],
    ha: { foo: 24, bar: 42 }
};
var hash2 = {
    foo: 23,
    bar: ['this', 'that', 'whatever'],
    ha: { foo: 24, bar: 42 }
};
isDeeply( hash1, hash2,    'isDeeply() with complicated objects' );
stack = [];
seen  = [];
ok(Test.More._eqAssoc(hash1, hash2, stack, seen), '_eqAssoc() with complicated hashes');

hash2['bar'][1] = 'tha';
stack = [];
seen  = [];
ok(!Test.More._eqAssoc(hash1, hash2, stack, seen),
   '_eqAssoc() with slightly different complicated hashes');
is(Test.Builder.instance(), Test.More.builder(), 'builder()');

cmpOK(42, '==', 42,        'cmpOK ==');
cmpOK('foo', 'eq', 'foo',  '      eq');
cmpOK(42.5, '<', 42.6,     '      <');
cmpOK(0, '||', 1,          '      ||');

isSet([1, 2, [3]], [[3], 1, 2], "isSet() should work with refs" );
isSet([1, 2, [3]], [1, [3], 2], "isSet() should work with reordered refs" );

function TestObject() {
    this.myMethod = function () {};
}
TestObject.prototype.protoMethod = function () {};
var testObject = new TestObject();
canOK( testObject, 'myMethod', 'protoMethod' );
