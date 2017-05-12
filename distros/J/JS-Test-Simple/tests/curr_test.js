JSAN.addRepository('../lib').use('Test.Builder');
var test = new Test.Builder();
test.plan({tests: 2});
test.output()("ok 1" + Test.Builder.LF);
test.output()("ok 2" + Test.Builder.LF);
test.currentTest(2);
