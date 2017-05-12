// Ensure that intermixed prints to document.write and tests come out in the
// right order (ie. no buffering problems).
JSAN.addRepository('../lib').use('Test.More');
plan({tests: 20});
var T = Test.Builder.instance();

var nums = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
for (var i in nums) {
    var tnum = nums[i] * 2;
    Test.More.pass("I'm ok");
    T.currentTest(tnum);
    Test.More.Test.output()("ok " + tnum + " - You're ok\n");
}
