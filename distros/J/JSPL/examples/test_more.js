#!./bin/jspl
// 'attach' and 'Attached' are only a proof of concept, don't take them to seriously
// I left them undocumented because they can: change, gone, kill your cat or provoke
// you serious hair loss.
attach('Test::More', 'Test::Exception');

with(Attached) { // A nice use of 'with', no Doug?

    plan('tests', 7);

    function foo() { return "foo"; }

    ok( foo(), "returns true" );
    is( foo(), "foo", "more specifically, 'foo'" );

    ok( 1, "ok" );
    is( 10, 10, "is" );
    throws_ok( function () { throw "died"; }, /ied/, 'throws_ok' );
    like( "foo", /oo/, 'like' );
    unlike( "foo", /bar/, 'unlike' );

}
