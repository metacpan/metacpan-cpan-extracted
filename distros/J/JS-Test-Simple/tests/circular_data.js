new JSAN('../lib').use('Test.More');
if (typeof window != "undefined" && window.opera)
    plan({skipAll: "Opera no likey circular references" });
else
    plan({tests: 7});

var a1 = [ 1, 2, 3 ];
a1.push(a1);
var a2 = [ 1, 2, 3 ];
a2.push(a2);

isDeeply(a1, a2, "isDeeply() with circular arrays");
if (typeof navigator != "undefined" && /Safari/.test(navigator.userAgent))
    skip("http://bugs.webkit.org/show_bug.cgi?id=3539", 1);
else isSet(a1, a2, "isSet() with circular arrays");
ok( Test.More._eqArray(a1, a2, [], []), "_eqArray() with cirular arrays");

var h1 = { a: 1, b: 2, c: 3 };
h1.d = h1;
var h2 = { a: 1, b: 2, c: 3 };
h2.d = h2;

isDeeply(h1, h2, "isDeeply() with circular objects");
ok( Test.More._eqAssoc(h1, h2, [], []), "_eqAssoc() with cirular objects");

{
    // Make sure the circular ref checks don't get confused by a reference 
    // that is simply repeating.
    var a = { foo: 1 };
    var b = { foo: 1 };
    var c = { foo: 1 };

    isDeeply( [a, a], [b, c],
	      "isDeeply() with repeating references in arrays" );
    isDeeply( { foo: a, bar: a }, { foo: b, bar: c },
	      "isDeeply() with repeating references in objects" );
}
