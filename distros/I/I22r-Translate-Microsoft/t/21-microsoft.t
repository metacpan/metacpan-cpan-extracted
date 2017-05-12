use I22r::Translate;
use Test::More;

I22r::Translate->config(
    'I22r::Translate::Microsoft' => {
	ENABLED => 1,
	CLIENT_ID => 'test',
	SECRET => 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqr',
	REFERER => "http://this.is.just.a.test/"
    } );

ok( 1 );
ok( I22r::Translate::Microsoft->config('ENABLED') );
ok( I22r::Translate::Microsoft->config('REFERER')
    eq 'http://this.is.just.a.test/' );

# was I going to do something else with this test?


done_testing();
