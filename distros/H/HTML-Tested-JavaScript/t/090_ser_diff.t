use strict;
use warnings FATAL => 'all';

use Test::More tests => 40;
use File::Temp qw(tempdir);
use File::Slurp;
use File::Basename qw(dirname);
use Cwd qw(abs_path);

BEGIN { our $_T = 38; do "t/use_guitester.pl"; }

my $td = tempdir('/tmp/ht_ser_XXXXXX', CLEANUP => 1);
write_file("$td/a.html", <<'ENDS');
<html>
<head>
<title>Diff Page</title>
<script src="javascript/serializer.js"></script>
<script>
var o1 = { a: 12, b: "hi", c: undefined };
var o2 = { a: 12, b: "ho", d: "a" };
var r1 = {};
var a1 = [ { a: 1, b: 2, c: "e", d: "b" }, { a: 2, b: 1, c: "e", d: "b" }
		, { a: 3, b: 3, k: 4 } ];
var a2 = [ { a: 2, b: 1, c: "e", d: "c" }, { a: 1, b: 2, c: "e", d: "b" }
		, { a: 5, b: 5, f: "g", h: 7 } ];
var ra = [];
var d = [];
var b1 = [ { a: 1, b: 1 }, { a: 2, b: 2 } ];
var b2 = [ { a: 1, b: 3 }, { a: 2, b: 2 } ];
var b3 = [];
var b4 = [];

var c1 = [];
var c2 = [ { a: 1 } ];
var c3 = [];
var c4 = [];

var e1 = [ { a: 1, b: 1 }, { a: 2, b: 2 } ];
var e2 = [ { a: 2, b: 2 }, { a: 1, b: 1 } ];
var e3 = [];
var e4 = [];

var f1 = { a: 3, b: 4 };
var f2 = { a: 5 };
var f3 = {};

var uh = { u: [ { a: 0, b: undefined } ] };
</script>
</head>
<body>
</body>
</html>
ENDS
symlink(abs_path(dirname($0) . "/../javascript"), "$td/javascript");

my $mech = Mozilla::Mechanize::GUITester->new(quiet => 1, visible => 0);
ok($mech->get("file://$td/a.html"));
is($mech->title, 'Diff Page');

is($mech->run_js('return ht_serializer_diff_hash({}, {}, {})'), 0);
is_deeply($mech->console_messages, []) or exit 1;

is($mech->run_js('return ht_serializer_diff_hash(o1, o2, r1)'), 3);
is_deeply($mech->console_messages, []) or exit 1;
is($mech->run_js('return ht_serializer_encode(r1)'), 'b=ho&d=a&c=');

is($mech->run_js('return ht_serializer_diff_array([ "a", "b" ], a1, a2, ra, d)')
		, 4);
is_deeply($mech->console_messages, []) or exit 1;
is($mech->run_js('return d.length'), 1);
is($mech->run_js('return ht_serializer_encode(d[0])'), 'a=3&b=3');

is($mech->run_js('return ht_serializer_encode({ d: d })')
	, 'd__1__a=3&d__1__b=3') or exit 1;

is($mech->run_js('return ht_serializer_encode({ k: [], d: d })')
	, 'k=&d__1__a=3&d__1__b=3');
is_deeply($mech->console_messages, []) or exit 1;

is($mech->run_js('return ht_serializer_encode({ k: [ 1, 2 ], d: d })')
	, 'k=1%2C2&d__1__a=3&d__1__b=3');

is($mech->run_js('return ra.length'), 3);
is($mech->run_js('return ht_serializer_encode({ ra: ra })')
	, 'ra__1__d=c&ra__1__a=2&ra__1__b=1&ra__2__a=1&ra__2__b=2'
		. '&ra__3__a=5&ra__3__b=5&ra__3__f=g&ra__3__h=7');
is_deeply($mech->console_messages, []) or exit 1;

is($mech->run_js('return ht_serializer_diff_array([ "a" ], b1, b2, b3, b4)')
		, 1);
is_deeply($mech->console_messages, []) or exit 1;
is($mech->run_js('return b3.length'), 2);
is($mech->run_js('return b4.length'), 0);
is($mech->run_js('return ht_serializer_encode({ b: b3 })')
	, 'b__1__b=3&b__1__a=1&b__2__a=2');

is($mech->run_js('return ht_serializer_diff_array([ "a" ], c1, c2, c3, c4)')
		, 1);
is($mech->run_js('return c3.length'), 1);
is($mech->run_js('return c4.length'), 0);
is($mech->run_js('return ht_serializer_encode({ c: c3 })'), 'c__1__a=1');
is_deeply($mech->console_messages, []) or exit 1;

is($mech->run_js('return ht_serializer_diff_array([ "a" ], e1, e2, e3, e4)'), 2);
is($mech->run_js('return e3.length'), 2);
is($mech->run_js('return e4.length'), 0);
is($mech->run_js('return ht_serializer_encode({ e: e3 })')
		, 'e__1__a=2&e__2__a=1');
is_deeply($mech->console_messages, []) or exit 1;

$mech->run_js("e3 = []; e4 = [];");
is_deeply($mech->console_messages, []) or exit 1;
is($mech->run_js('return ht_serializer_diff_array([ "a" ], e1, e2, e3, e4, 1)'), 0);

is($mech->run_js('return ht_serializer_encode(uh)'), 'u__1__a=0&u__1__b=');
is_deeply($mech->console_messages, []) or exit 1;

is($mech->run_js('return ht_serializer_diff_hash(f1, f2, f3)'), 2);
is_deeply($mech->console_messages, []) or exit 1;
is($mech->run_js('return ht_serializer_encode(f3)'), 'a=5&b=');

