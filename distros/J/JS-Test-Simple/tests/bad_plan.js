JSAN.addRepository('../lib').use('Test.Builder');
// Utility testing functions.
var T = new Test.Builder();
T.plan({ tests: 2 });

var test = new Test.Builder();
try { 
    test.plan(7);
    throw new Error("Shouldn't make it this far");
}
catch (ex) {
    T.ok(ex.message.match(/plan\(\) doesn\'t understand 7/), 
        'bad plan() -- lonely number');
}

try { 
    test.plan({wibble : 7});
    if ({}.hasOwnProperty)
        throw new Error("Shouldn't make it this far");
    else 
        T.skip("Can't validate without hasOwnProperty");
}
catch (ex) {
    T.ok(ex.message.match(/plan\(\) doesn\'t understand wibble 7/), 
        'bad plan() -- invalid labeled param');
};
