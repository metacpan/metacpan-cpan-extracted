JSAN.addRepository('../lib').use('Test.More');

plan({ tests: 9 });
var result;

try { 
    result = new Test.Builder.TestResult({wibble : 7});
    if ({}.hasOwnProperty)
        throw new Error("Shouldn't make it this far");
    else 
        skip("Can't validate without hasOwnProperty", 1);
}
catch (ex) {
    ok(ex.message.match(/Invalid/), "Reject invalid constructor param");
}

result = new Test.Builder.TestResult();
isaOK(result, 'Test.Builder.TestResult');

result.setOK(true);
is(result.getOK(), true, "set/get ok");
result.setActualOK(true);
is(result.getActualOK(), true, "set/get actualOK");
result.setDesc("nasty, brutish and short")
is(result.getDesc(), "nasty, brutish and short", "set/get desc");
result.setReason("Because I said so.");
is(result.getReason(), "Because I said so.", "set/get reason");
result.setType("todo");
is(result.getType(), "todo", "set/get type");
result.setOutput("foo");
is(result.getOutput(), "foo", "set/get output");

result.appendOutput("bar");
is(result.getOutput(), "foobar", "appendOutput");

