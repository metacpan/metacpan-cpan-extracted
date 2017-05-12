new JSAN('../lib').use('Test.More');
var output = [];
function overwrite () {
    for (var i = 0; i < arguments.length; i++) output.push(arguments[i]);
};

plan({tests: 6});
var more_tb = Test.More.builder();
var new_tb  = new Test.Builder;
if (typeof navigator != "undefined" && /Safari/.test(navigator.userAgent)) {
    skip("http://bugs.webkit.org/show_bug.cgi?id=3537", 2);
} else {
    isaOK(new_tb,  'Test.Builder');
    isaOK(more_tb, 'Test.Builder');
}

isnt(more_tb, new_tb, 'Test.Builder.create() makes a new object');

is(more_tb, Test.More.builder(), 'new does not interfere with .builder()');
is(more_tb, Test.Builder.instance(),  'instance does not interfere with .new()');

new_tb.output(overwrite);
new_tb.endOutput(overwrite);
new_tb.failureOutput(overwrite);
new_tb.plan({tests: 1});
new_tb.ok(1);
new_tb._ending(); // Trigger the ending.
is(output.splice(0, output.length).join(''),
                 "1..1" + Test.Builder.LF + "ok 1" + Test.Builder.LF,
                 "Check output");
