use I22r::Translate;
use Test::More;

I22r::Translate->config(
    'I22r::Translate::Google' => {
	ENABLED => 1,
	API_KEY => "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abc",
	REFERER => "http://this.is.just.a.test/"
    } );

ok( 1 );
ok( I22r::Translate::Google->config('ENABLED') );
ok( I22r::Translate::Google->config('REFERER')
    eq 'http://this.is.just.a.test/' );

# was I going to do something else with this test?


done_testing();
