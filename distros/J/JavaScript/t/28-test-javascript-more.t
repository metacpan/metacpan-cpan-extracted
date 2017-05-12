# We're not testing Test::JavaScript::More very well here, but given
# that they're just bound to their perl counterparts we can probably
# live with that for the time being.

use Test::JavaScript::More;

plan(10);

ok( 1, "ok" );
is( 10, 10, "is" );
throws_ok( function () { throw "died"; }, /ied/, 'throws_ok' );
like( "foo", /oo/, 'like' );
unlike( "foo", /bar/, 'unlike' );

// repeated, wrapped in TODO; these should now not fail the script
todo("not yet");
ok( 0, 'ok' );
is( 1, 9, 'is' );
throws_ok( function () { return "lived"; }, /ied/, 'throws_ok' );
like( "foo", /bar/, 'like' );
unlike( "foo", /oo/, 'unlike' );
todo(0);

diag("here I am!");
