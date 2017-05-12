JSAN.errorLevel = 'die';
JSAN.addRepository('../lib').use('Test.Builder');
var test = new Test.Builder;
if (Test.PLATFORM == 'director')
    test.plan({ skipAll: "Async testing not yet supported for Director" });
test.plan({ tests: 4 });
var id = test.beginAsync(3000);
window.setTimeout(
    function () {
        test.ok(true, "This should be test four");
        test.endAsync(id);
    }, 2000
);
test.ok(true, "This should be test three");
test.diag("Waiting for the asynchronous test...");
var output = [];
function testout () { output.push(arguments[0]) };
var failout = [];
function testfail () { failout.push(arguments[0]) };
var otherTest = Test.Builder.create();
otherTest.output(testout);
otherTest.endOutput(testfail);
otherTest.failureOutput(testfail);
otherTest.plan({ tests: 1 });
var otherid = otherTest.beginAsync();
window.setTimeout(function () { otherTest.ok(true, 'other ok') }, 1200);
otherTest._ending(); // Force the test to end.
var newid = test.beginAsync;
test.diag("Waiting to check timeout output");
window.setTimeout(
    function () {
        test.ok(output.splice(0, output.length).join('') ==
           "1..1" + Test.Builder.LF + "ok 1 - other ok" + Test.Builder.LF,
           "test two checks the output"
        );
        test.ok(failout.splice(0, failout.length).join('') ==
           "# No tests run!" + Test.Builder.LF,
           "test three checks the fail output"
        );
    }, 1800
);
