new JSAN('../lib').use('Test.More');
plan({tests: 9});
var output = [];
function testout () {
    for (var i = 0; i < arguments.length; i++) output.push(arguments[i]);
};

var failout = [];
function testfail () {
    for (var i = 0; i < arguments.length; i++) failout.push(arguments[i]);
};

{
    var test = Test.Builder.create();
    test.output(testout);
    test.endOutput(testfail);
    test.failureOutput(testfail);

    // Ensure stray newline in name escaping works.
    test.noEnding(true);
    test.plan({tests: 5});
    test.ok(1, "ok");
    test.ok(1, "ok\n");
    test.ok(1, "ok, like\nok");
    test.skip("wibble\nmoof");
    test.todoSkip("todo\nskip\n");

    is(output.splice(0, output.length).join(''),
       "1..5" + Test.Builder.LF +
       "ok 1 - ok" + Test.Builder.LF +
       "ok 2 - ok" + Test.Builder.LF +
       "# " + Test.Builder.LF +
       "ok 3 - ok, like" + Test.Builder.LF +
       "# ok" + Test.Builder.LF +
       "ok 4 # skip wibble" + Test.Builder.LF +
       "# moof" + Test.Builder.LF +
       "not ok 5 # TODO & SKIP todo" + Test.Builder.LF +
       "# skip" + Test.Builder.LF +
       "# "+ Test.Builder.LF,
       'Check the output'
     );
}

{
    var test = Test.Builder.create();
    test.output(testout);
    test.endOutput(testfail);
    test.failureOutput(testfail);
    test.plan({tests: 3});
    test.ok(1, 'Foo');
    test.ok(0, 'Bar');
    test.ok(1, 'Yar');
    test.ok(1, 'Car');
    test.ok(0, 'Sar');
    test._ending(); // Trigger the ending.

    is(output.splice(0, output.length).join(''),
       "1..3" + Test.Builder.LF +
       "ok 1 - Foo" + Test.Builder.LF +
       "not ok 2 - Bar" + Test.Builder.LF +
       "ok 3 - Yar" + Test.Builder.LF +
       "ok 4 - Car" + Test.Builder.LF +
       "not ok 5 - Sar" + Test.Builder.LF,
       "We should have the corret extra output"
    );

    is(failout.splice(0, failout.length).join(''),
       "#     Failed test" + Test.Builder.LF +
       "#     Failed test" + Test.Builder.LF +
       "# Looks like you planned 3 tests but ran 5." + Test.Builder.LF,
       "...and we should get the correct extras output"
    );
}

{
    var test = Test.Builder.create();
    test.output(testout);
    test.endOutput(testfail);
    test.failureOutput(testfail);
    test.plan({tests: 1});
    test.ok(1);
    test.ok(1);
    test.ok(1);
    test._ending(); // Trigger the ending.

    is(output.splice(0, output.length).join(''),
       "1..1" + Test.Builder.LF +
       "ok 1" + Test.Builder.LF +
       "ok 2" + Test.Builder.LF +
       "ok 3" + Test.Builder.LF,
       "We should have the correct test count"
     );
    is(failout.splice(0, failout.length).join(''),
       "# Looks like you planned 1 test but ran 3." + Test.Builder.LF,
       "...and we should have the correct failure output"
     );
}

{
    // Test skipRest().
    try {
	var test = Test.Builder.create();
	test.output(testout);
	test.plan({tests: 5});
	test.ok(1);
	test.ok(1);
	test.skipRest("I'm outta here!");
	test.ok(1);
	test.ok(1);
    }
    catch (e) {}

    is(output.splice(0, output.length).join(''),
       "1..5" + Test.Builder.LF +
       "ok 1" + Test.Builder.LF +
       "ok 2" + Test.Builder.LF +
       "ok 3 # skip I'm outta here!" + Test.Builder.LF +
       "ok 4 # skip I'm outta here!" + Test.Builder.LF +
       "ok 5 # skip I'm outta here!" + Test.Builder.LF,
       "We should have the correct output for skipRest()"
    );
       
}

{
    // Test skipAll().
    try {
	var test = Test.Builder.create();
	test.output(testout);
	test.plan({skipAll: 'I just want to skip it!'});
	test.ok(1);
	test.ok(1);
	test.ok(1);
	test.ok(1);
    }
    catch (e) {}

    is(output.splice(0, output.length).join(''),
       "1..0 # Skip I just want to skip it!" + Test.Builder.LF,
       "We should have the correct output for skipAll()"
    );
       
}

{
    // Test BAILOUT().
    var test = Test.Builder.create();
    try {
	test.output(testout);
	test.endOutput(testfail);
	test.failureOutput(testfail);
	test.plan({tests: 7});
	test.ok(1);
	test.ok(1);
	test.BAILOUT("Oof!");
	test.ok(1);
	test.ok(1);
	test.ok(1);
	test.ok(1);
    }
    catch (e) {}
    test._ending(); // Trigger the ending.

    is(output.splice(0, output.length).join(''),
       "1..7" + Test.Builder.LF +
       "ok 1" + Test.Builder.LF +
       "ok 2" + Test.Builder.LF +
       "Bail out! Oof!",
       "We should have the correct output for BAILOUT()"
    );

    is(failout.splice(0, failout.length).join(''),
       "# Looks like you planned 7 tests but ran 2." + Test.Builder.LF,
       "...and we should have the correct failure output"
     );
}
