var t = new Test.Base();

t.plan(1);
t.filters({ input: 'upper_case' });
t.run_is('input', 'output');

function upper_case(string) {
    return string.toUpperCase();
}

/* Test
=== Test Multiline Upper Case
--- input
foo
bar
baz
--- output
FOO
BAR
BAZ

*/
