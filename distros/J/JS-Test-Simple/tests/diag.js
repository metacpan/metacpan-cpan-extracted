new JSAN('../lib').use('Test.More');
var output = [];
function overwrite () {
    for (var i = 0; i < arguments.length; i++) output.push(arguments[i]);
};

plan({tests: 6});
var test = Test.More.builder();
test.failureOutput(overwrite);
diag("a single line");
var ret = diag("multiple\n", "lines");
isDeeply(output.splice(0, output.length),
	 ["# a single line" + Test.Builder.LF,
      "# multiple" + Test.Builder.LF + "# lines"+ Test.Builder.LF],
	 "We should have got all of the diagnostics");

ok( !ret, 'diag returns false' );

ret = diag("# foo");
isDeeply(output.splice(0, output.length), ["# # foo" + Test.Builder.LF],
	 "diag() adds # even if there's one already" );
ok( !ret, 'diag returns false' );

diag('one', 'two');
isDeeply(output.splice(0, output.length),
	 ["# onetwo"+ Test.Builder.LF], "Separate arguments should just be joined");
diag("one\n", "two\r\n", "three\r");
is(output.splice(0, output.length).join(''),
	 "# one" + Test.Builder.LF + "# two" + Test.Builder.LF + "# three"
     + Test.Builder.LF + "# " + Test.Builder.LF,
	 "OS-dependent line-endings should all be properly escaped");
