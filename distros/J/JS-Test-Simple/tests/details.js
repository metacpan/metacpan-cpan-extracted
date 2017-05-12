new JSAN('../lib').use('Test.More');
var test = Test.Builder.instance();

test.plan({tests: 9});
var Expected_Details = [];

test.isNum(test.summary().length, 0, 'no tests yet, no summary');
Expected_Details.push({
    ok:        true,
    actual_ok: true,
    desc:      'no tests yet, no summary',
    type:      '',
    reason:    ''
});

test.skip('just testing skip');

Expected_Details.push({
    ok:        true,
    actual_ok: true,
    desc:      '',
    type:      'skip',
    reason:    'just testing skip'
});

TODO: {
    test.todo('I need a todo', 1);
    test.ok(0, 'a test to todo!');

    Expected_Details.push({
	ok:        true,
	actual_ok: false,
        desc:      'a test to todo!',
        type:      'todo',
        reason:    'I need a todo'
    });
}

test.todoSkip('I need both');

Expected_Details.push({
    ok:        true,
    actual_ok: false,
    desc:      '',
    type:      'todo_skip',
    reason:    'I need both'
});

test.isNum(test.summary().length, 4, 'summary should have four records');

Expected_Details.push({
    ok:        true,
    actual_ok: true,
    desc:      'summary should have four records',
    type:      '',
    reason:    ''
});

test.currentTest(test.currentTest() + 1);

test.output()("ok " + test.currentTest() + " - currentTest incremented" + Test.Builder.LF);

Expected_Details.push({
    ok:        true,
    actual_ok: null,
    desc:      null,
    type:      'unknown',
    reason:    'incrementing test number'
});

var details = test.details();
test.isNum(details.length, test.currentTest(),
	   'details() should return a list of all test details');

Expected_Details.push({
    ok:        true,
    actual_ok: true,
    desc:      'details() should return a list of all test details',
    type:      '',
    reason:    ''
});

// Hack. I should really set this specifically, but that's more work
// than I'm really interested in at this point. It's too changeable.
for (var i = 0; i < details.length; i++)
    Expected_Details[i].output = details[i].output; 

isDeeply( details, Expected_Details, "We should have the expected details" );

// This test has to come last because it thrashes the test details.
{
    var curr_test = test.currentTest();
    test.currentTest(4);
    details = test.details().length;

    test.currentTest(curr_test);
    test.isNum(details, 4, "Details should have been truncated to 4" );
}
