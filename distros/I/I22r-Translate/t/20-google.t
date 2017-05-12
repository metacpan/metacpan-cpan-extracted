use I22r::Translate;
use I22r::Translate::Google;
use I22r::Translate::Request;
use Test::More;
use Data::Dumper;
use t::Constants;

if (!$t::Constants::CONFIGURED || !$t::Constants::GOOGLE_API_KEY) {
   ok(1, 'not configured for Google backend. Skipping remaining tests.');
   t::Constants->skip_remaining_tests;
}


I22r::Translate::Google->config( 
    "ENABLED" => 1,
    "API_KEY" => $t::Constants::GOOGLE_API_KEY,
    "REFERER" => "http://just.doing.some.testing/",
    "NETWORK" => 'check',
);

ok( I22r::Translate::Google->config->{ENABLED} );
ok( I22r::Translate::Google->config("API_KEY") );
ok( !I22r::Translate::Google->config("bogus") );

ok( I22r::Translate::Google->can_translate('en','es'), 'valid can_translate' );
ok( I22r::Translate::Google->can_translate('en','ru'), 'valid can_translate' );
ok( I22r::Translate::Google->can_translate('en','vi'), 'valid can_translate' );
ok( I22r::Translate::Google->can_translate('foo','bar') <= 0,
    'can_translate fails for invalid languages' );


my $req = I22r::Translate::Request->new(
    src => 'en',
    dest => 'es',
    text => {
   	1 => 'hello worm',
	2 => 'goodbye world',
    },
    return_type => 'hash'
);
$req->backend('I22r::Translate::Google');

my @r = eval { I22r::Translate::Google->get_translations($req) };
ok( @r != 0, 'translation results' );
ok( " @r " =~ / 1 / && " @r " =~ / 2 /,
    'translation results for inputs' );
my %r = %{ $req->results };
$req->backend(undef);

my $r1 = eval { $r{1}->text };
my $r2 = eval { $r{2}->text };

ok( $r1 ne '', 'translation result 1' ) or diag $r1;
ok( $r1 ne 'hello worm', 'translation result 1 changed text' ) or diag $r1;
ok( $r2 ne '', 'translation result 2' ) or diag $r2;
ok( $r2 ne 'goodbye world', 'translation result 2 changed text' )
    or diag $r2;

done_testing();
