var jsan = new JSAN('../lib');
jsan.use('Test.More');
jsan.use('Test.Harness');
plan({tests: 159 });
// Create a harness object.
var harness;
ok(harness = new Test.Harness(), "Create new harness");
if (typeof navigator != "undefined"
    && /Safari/.test(navigator.userAgent)) {
    skip("http://bugs.webkit.org/show_bug.cgi?id=3537", 1);
} else {
    isaOK(harness, 'Test.Harness');
}

// Test default attributes.
is(harness.bonus, 0, "Check bonus attribute");
is(harness.ran, 0, "Check ran attribute");
is(harness.ok, 0, "Check ok attribute");
is(harness.subSkipped, 0, "Check subSkipped attribute");
is(harness.todo, 0, "Check todo attribute");
is(harness.files, 0, "Check files attribute");
is(harness.good, 0, "Check good  attribute");
is(harness.bad, 0, "Check bad attribute");
is(harness.tests, 0, "Check tests attribute");
is(harness.skipped, 0, "Check skipped attribute");
isDeeply(harness.failures, [], "Check failures attribute");

// Test fail list formatting.
is(harness._failList([1, 2, 3, 4, 7, 9, 10, 11]),
   '1-4 7 9-11', "Test _failList() with continuous series");
is(harness._failList([1, 3, 7, 9, 11]),
   '1 3 7 9 11', "Test _failList() with distinct numbers");

// Test file list formatting.
var files = ['foo.html', 'barbar.html'];
isDeeply(harness.outFileNames(files),
         ['foo.html......', 'barbar.html...'],
         "File names should be formatted properly for output");

// Test runTests() class method.
var runner = Test.Harness.prototype.runTests;
Test.Harness.prototype.runTests = function () {
    isDeeply(arguments, files,
             "Harness.runTests() should pass arguments to the instance method");
};
Test.Harness.runTests(files[0], files[1]);
Test.Harness.prototype.runTests = runner;

// Test outputResults().
var pass = [], fail = [];
var out = {
    pass: function (msg) { pass.push(msg); },
    fail: function (msg) { fail.push(msg); }
};

// Start with two passing tests.
var mockTest = {
    TestResults: [
        new Test.Builder.TestResult({
            ok:        true,
            actualOK:  true,
            desc:      'Test 1',
            type:      '',
            reason:    ''
        }),
        new Test.Builder.TestResult({
            ok:        true,
            actualOK:  true,
            desc:      'Test 2',
            type:      '',
            reason:    ''
        })
    ],
    expectedTests: function () { return this.TestResults.length }
};

harness.outputResults(mockTest, "foo.html", out, false);
is(pass.splice(0, pass.length).join(''), "ok" + Test.Harness.LF,
   "We should have success");
is(harness.tests, 1, "We should have one test file");
is(harness.ran, 2, "Two tests should have been run");
is(harness.files, 1, "One file should have run");
is(harness.ok, 2, "We should have two oks");
is(harness.todo, 0, "We should have no todos");
is(harness.bonus, 0, "We should have no unexpected passes");
is(harness.good, 1, "We should have one good test file");
is(harness.skipped, 0, "We should have no skipped test files");
is(harness.bad, 0, "We should have no bad test files");
is(harness.subSkipped, 0, "We should have no skipped tests");
ok(harness._allOK(), "All tests should be OK");
is(harness._bonusmsg(), '', "There should be no bonus message");
harness.outputSummary(out.pass, 215678);
is(pass.splice(0, pass.length).join(''),
   "All tests successful." + Test.Harness.LF
   + "Files=1, Tests=2, 215.678 seconds" + Test.Harness.LF,
   "We should have all tests successful");

// Add a ToDo test.
mockTest.TestResults[2] = new Test.Builder.TestResult({
    ok:        true,
    actualOK:  false,
    desc:      'Test 3',
    type:      'todo',
    reason:    'Gotta get to it'
});
harness.outputResults(mockTest, "bar.html", out, false);
is(pass.splice(0, pass.length).join(''), "ok" + Test.Harness.LF,
   "We should have success");
is(harness.tests, 2, "We should have two test files");
is(harness.ran, 5, "Five tests should have been run");
is(harness.files, 2, "Two files should have run");
is(harness.ok, 5, "We should have four oks");
is(harness.todo, 1, "We should have one todo");
is(harness.bonus, 0, "We should have no unexpected passes");
is(harness.good, 2, "We should have two good test files");
is(harness.skipped, 0, "We should have no skipped test files");
is(harness.bad, 0, "We should have no bad test files");
is(harness.subSkipped, 0, "We should have no skipped tests");
ok(harness._allOK(), "All tests should be OK");
is(harness._bonusmsg(), '', "There should be no bonus message");
harness.outputSummary(out.pass, 215678);
is(pass.splice(0, pass.length).join(''),
   "All tests successful." + Test.Harness.LF
   + "Files=2, Tests=5, 215.678 seconds" + Test.Harness.LF,
   "We should have all tests successful");

// Change it to a passing ToDo test.
mockTest.TestResults[2].setActualOK(true);
harness.outputResults(mockTest, "bat.html", out, false);
is(pass.splice(0, pass.length).join(''), "ok" + Test.Harness.LF,
   "We should have success");
is(harness.tests, 3, "We should have three test files");
is(harness.ran, 8, "Eight tests should have been run");
is(harness.files, 3, "Three files should have run");
is(harness.ok, 8, "We should have eight oks");
is(harness.todo, 2, "We should have two todos");
is(harness.bonus, 1, "We should have one unexpected pass");
is(harness.good, 3, "We should have three good test files");
is(harness.skipped, 0, "We should have no skipped test files");
is(harness.bad, 0, "We should have no bad test files");
is(harness.subSkipped, 0, "We should have no skipped tests");
ok(harness._allOK(), "All tests should be OK");
is(harness._bonusmsg(), ' (1 subtest UNEXPECTEDLY SUCCEEDED)',
   "We should have a bonus message");
harness.outputSummary(out.pass, 215678);
is(pass.splice(0, pass.length).join(''),
   "All tests successful (1 subtest UNEXPECTEDLY SUCCEEDED)." + Test.Harness.LF
   + "Files=3, Tests=8, 215.678 seconds" + Test.Harness.LF,
   "We should have all tests successful with bonus");

// Change it to a failing ToDo test.
mockTest.TestResults[2].setActualOK(false);
mockTest.TestResults[2].setOK(false);
harness.outputResults(mockTest, "gah.html", out, false);
is(pass.splice(0, pass.length).join(''), "ok" + Test.Harness.LF,
   "We should have success");
is(harness.tests, 4, "We should have four test files");
is(harness.ran, 11, "11 tests should have been run");
is(harness.files, 4, "Four files should have run");
is(harness.ok, 10, "We should have 10 oks");
is(harness.todo, 3, "We should have three todos");
is(harness.bonus, 1, "We should have one unexpected pass");
is(harness.good, 4, "We should have four good test files");
is(harness.skipped, 0, "We should have no skipped test files");
is(harness.bad, 0, "We should have no bad test files");
is(harness.subSkipped, 0, "We should have no skipped tests");
ok(harness._allOK(), "All tests should be OK");
is(harness._bonusmsg(), ' (1 subtest UNEXPECTEDLY SUCCEEDED)',
   "We should still have a bonus message");
harness.outputSummary(out.pass, 215678);
is(pass.splice(0, pass.length).join(''),
   "All tests successful (1 subtest UNEXPECTEDLY SUCCEEDED)." + Test.Harness.LF
   + "Files=4, Tests=11, 215.678 seconds" + Test.Harness.LF,
   "We should have all tests successful with bonus");

// Change it to a failing test.
mockTest.TestResults[2].setType('');
harness.outputResults(mockTest, "gar.html", out, false);
is(fail.splice(0, fail.length).join(''),
   "NOK # Failed test 3 in gar.html" + Test.Harness.LF,
   "We should have failure");
is(harness.tests, 5, "We should have five test files");
is(harness.ran, 14, "14 tests should have been run");
is(harness.files, 5, "Four files should have run");
is(harness.ok, 12, "We should have 12 oks");
is(harness.todo, 3, "We should have three todos");
is(harness.bonus, 1, "We should have one unexpected pass");
is(harness.good, 4, "We should have four good test files");
is(harness.skipped, 0, "We should have no skipped test files");
is(harness.bad, 1, "We should have one bad test files");
is(harness.subSkipped, 0, "We should have no skipped tests");
ok(!harness._allOK(), "All tests should not be OK");
is(harness._bonusmsg(), ' (1 subtest UNEXPECTEDLY SUCCEEDED)',
   "We should still have a bonus message");
harness.outputSummary(out.pass, 215678);
is(pass.splice(0, pass.length).join(''),
   "(1 subtest UNEXPECTEDLY SUCCEEDED)." + Test.Harness.LF
   + "Failed 1/5 test scripts, 80.00% okay. 2/14 subtests failed, 85.71% okay."
   + Test.Harness.LF
   + "Files=5, Tests=14, 215.678 seconds"  + Test.Harness.LF,
   "We should a failure with a bonus");

// Add a second failure.
mockTest.TestResults.push(
    new Test.Builder.TestResult({
        ok:        false,
        actualOK:  false,
        desc:      'Test 4',
        type:      '',
        reason:    ''
    })
);
harness.outputResults(mockTest, "bwah.html", out, false);
is(fail.splice(0, fail.length).join(''),
   "NOK # Failed tests 3-4 in bwah.html" + Test.Harness.LF,
   "We should have two failures");
is(harness.tests, 6, "We should have six test files");
is(harness.ran, 18, "18 tests should have been run");
is(harness.files, 6, "Six files should have run");
is(harness.ok, 14, "We should have 14 oks");
is(harness.todo, 3, "We should have three todos");
is(harness.bonus, 1, "We should have one unexpected pass");
is(harness.good, 4, "We should have four good test files");
is(harness.skipped, 0, "We should have no skipped test files");
is(harness.bad, 2, "We should have two bad test files");
is(harness.subSkipped, 0, "We should have no skipped tests");
ok(!harness._allOK(), "All tests should not be OK");
is(harness._bonusmsg(), ' (1 subtest UNEXPECTEDLY SUCCEEDED)',
   "We should still have a bonus message");
harness.outputSummary(out.pass, 215678);
is(pass.splice(0, pass.length).join(''),
   "(1 subtest UNEXPECTEDLY SUCCEEDED)." + Test.Harness.LF
   + "Failed 2/6 test scripts, 66.67% okay. 4/18 subtests failed, 77.78% okay."
   + Test.Harness.LF
   + "Files=6, Tests=18, 215.678 seconds"  + Test.Harness.LF,
   "We should two failures with a bonus");

// Now try skipping all.
mockTest.TestResults = [];
mockTest.SkipAll = true;
mockTest.Buffer  = ["1..0 # Skip This is bogus" ];
harness.outputResults(mockTest, "feh.html", out, false);
is(pass.splice(0, pass.length).join(''),
   "all skipped: This is bogus",
   "Skip one");
is(harness.tests, 7, "We should have seven test files");
is(harness.ran, 18, "18 tests should have been run");
is(harness.files, 6, "Six files should have run");
is(harness.ok, 14, "We should have 14 oks");
is(harness.todo, 3, "We should have three todos");
is(harness.bonus, 1, "We should have one unexpected pass");
is(harness.good, 5, "We should have four good test files");
is(harness.skipped, 1, "We should have one skipped test file");
is(harness.bad, 2, "We should have two bad test files");
is(harness.subSkipped, 0, "We should have no skipped tests");
ok(!harness._allOK(), "All tests should not be OK");
is(harness._bonusmsg(), ' (1 subtest UNEXPECTEDLY SUCCEEDED), 1 test skipped',
   "We should have a new bonus message");
harness.outputSummary(out.pass, 215678);
is(pass.splice(0, pass.length).join(''),
   "(1 subtest UNEXPECTEDLY SUCCEEDED), 1 test skipped." + Test.Harness.LF
   + "Failed 2/7 test scripts, 71.43% okay. 4/18 subtests failed, 77.78% okay."
   + Test.Harness.LF
   + "Files=7, Tests=18, 215.678 seconds"  + Test.Harness.LF,
   "We should still have two failures with a bonus");

// Now try no results and no SkipAll.
mockTest.SkipAll = false;
harness.outputResults(mockTest, "meh.html", out, false);
is(fail.splice(0, fail.length).join(''),
   "FAILED before any test output arrived" + Test.Harness.LF,
   "No tests run!");
is(harness.tests, 8, "We should have seven test files");
is(harness.ran, 18, "18 tests should have been run");
is(harness.files, 7, "Six files should have run");
is(harness.ok, 14, "We should have 14 oks");
is(harness.todo, 3, "We should have three todos");
is(harness.bonus, 1, "We should have one unexpected pass");
is(harness.good, 5, "We should have four good test files");
is(harness.skipped, 1, "We should have one skipped test file");
is(harness.bad, 3, "We should have three bad test files");
is(harness.subSkipped, 0, "We should have no skipped tests");
ok(!harness._allOK(), "All tests should not be OK");
is(harness._bonusmsg(), ' (1 subtest UNEXPECTEDLY SUCCEEDED), 1 test skipped',
   "We should still have the new bonus message");
harness.outputSummary(out.pass, 215678);
is(pass.splice(0, pass.length).join(''),
   "(1 subtest UNEXPECTEDLY SUCCEEDED), 1 test skipped." + Test.Harness.LF
   + "Failed 3/8 test scripts, 62.50% okay. 4/18 subtests failed, 77.78% okay."
   + Test.Harness.LF
   + "Files=8, Tests=18, 215.678 seconds"  + Test.Harness.LF,
   "We should now have three failures with a bonus");

// Now add a skipped test.
mockTest.TestResults.push(
    new Test.Builder.TestResult({
        ok:       true,
        actualOK: true,
        desc:     'Test 1',
        type:     '',
        reason:   ''
    }),
    new Test.Builder.TestResult({
        ok:       true,
        actualOK: true,
        desc:     'Test 2',
        type:     'skip',
        reason:   'Because I said so'
    })
);
harness.outputResults(mockTest, "skip.html", out, false);
is(pass.splice(0, pass.length).join(''), "ok" + Test.Harness.LF,
   "We should have success");
is(harness.tests, 9, "We should have nine test files");
is(harness.ran, 20, "19 tests should have been run");
is(harness.files, 8, "Eight files should have run");
is(harness.ok, 16, "We should have 16 oks");
is(harness.todo, 3, "We should have three todos");
is(harness.bonus, 1, "We should have one unexpected pass");
is(harness.good, 6, "We should have six good test files");
is(harness.skipped, 1, "We should have one skipped test file");
is(harness.bad, 3, "We should have three bad test files");
is(harness.subSkipped, 1, "We should have one skipped test");
ok(!harness._allOK(), "All tests should not be OK");
is(harness._bonusmsg(),
   ' (1 subtest UNEXPECTEDLY SUCCEEDED), 1 test and 1 subtest skipped',
   "The bonus message should have the subtest");
harness.outputSummary(out.pass, 215678);
is(pass.splice(0, pass.length).join(''),
   "(1 subtest UNEXPECTEDLY SUCCEEDED), 1 test and 1 subtest skipped." + Test.Harness.LF
   + "Failed 3/9 test scripts, 66.67% okay. 4/20 subtests failed, 80.00% okay."
   + Test.Harness.LF
   + "Files=9, Tests=20, 215.678 seconds"  + Test.Harness.LF,
   "We should now have three failures with a double bonus");

// Now try with no files.
ok(harness = new Test.Harness(), "Create new harness");
harness.outputSummary(out.pass, 2156);
is(pass.splice(0, pass.length).join(''),
   "FAILED -- no tests were run for some reason." + Test.Harness.LF
   + "Files=0, Tests=0, 2.156 seconds" + Test.Harness.LF,
   "We should have a no files error message");

// Now try with no results.
mockTest = { TestResults: [], expectedTests: function () { return 0 } };
harness.outputResults(mockTest, "cak.html", out, false);
is(fail.splice(0, fail.length).join(''),
   "FAILED before any test output arrived" + Test.Harness.LF,
   "We should have failure");
is(harness.tests, 1, "We should have one test file");
is(harness.ran, 0, "No tests should have been run");
is(harness.files, 1, "One file should have run");
is(harness.ok, 0, "We should have no oks");
is(harness.todo, 0, "We should have no todos");
is(harness.bonus, 0, "We should have no unexpected passes");
is(harness.good, 0, "We should have no good test files");
is(harness.skipped, 0, "We should have no skipped test files");
is(harness.bad, 1, "We should have one bad test file");
is(harness.subSkipped, 0, "We should have no skipped tests");
ok(!harness._allOK(), "All tests should not be OK");
is(harness._bonusmsg(), '', "There should be no bonus message");
harness.outputSummary(out.pass, 215678);
is(pass.splice(0, pass.length).join(''),
   "FAILED -- 1 test file could be run: alas, no output ever seen." + Test.Harness.LF
   + "Files=1, Tests=0, 215.678 seconds" + Test.Harness.LF,
   "We should have a no tests error message");
