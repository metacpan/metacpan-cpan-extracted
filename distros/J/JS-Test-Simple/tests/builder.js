JSAN.addRepository('../lib').use('Test.Builder');

// Change the array prototype to ensure that we're not doing
// "for (var i in someArray)".
Array.prototype.foo = true;

// Change the object prototype to make sure that plan() doesn't
// get horked.
Object.prototype._foo = true;

var test = new Test.Builder;
test.plan({tests: 6 });
test.ok(1, 'compiled and new');
test.isEq('foo', 'foo',  'isEq');
test.isNum('23.0', '23', 'isNum');
test.isNum(test.currentTest(), 3, 'currentTest() get');
var testNum = test.currentTest() + 1;
test.currentTest(testNum);
test.output()("ok 5 - currentTest() set\n");
test.ok(1, 'counter still good');

// Make the world safe again.
delete Array.prototype.foo;
delete Object.prototype._foo;
