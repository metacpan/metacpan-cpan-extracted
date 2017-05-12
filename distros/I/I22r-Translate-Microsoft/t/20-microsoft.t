use I22r::Translate;
use I22r::Translate::Microsoft;
use I22r::Translate::Request;
use Test::More;
use Data::Dumper;
use t::Constants;

if (!$t::Constants::CONFIGURED) {
   ok(1, 'not configured for Microsoft backend. Skipping remaining tests.');
   t::Constants->skip_remaining_tests;
}


I22r::Translate::Microsoft->config( 
    "ENABLED" => 1,
    "CLIENT_ID" => $t::Constants::BING_CLIENT_ID,
    "SECRET" => $t::Constants::BING_SECRET,
    "NETWORK" => 'check',
);

ok( I22r::Translate::Microsoft->config->{ENABLED} );
ok( !I22r::Translate::Microsoft->config("API_KEY") );
ok( I22r::Translate::Microsoft->config("CLIENT_ID") );
ok( I22r::Translate::Microsoft->config("SECRET") );
ok( !I22r::Translate::Microsoft->config("bogus") );

ok( I22r::Translate::Microsoft->can_translate('en','es'), 'valid can_translate' );
ok( I22r::Translate::Microsoft->can_translate('en','ru'), 'valid can_translate' );
ok( I22r::Translate::Microsoft->can_translate('en','vi'), 'valid can_translate' );
ok( !I22r::Translate::Microsoft->can_translate('foo','bar'),
    'can_translate fails for invalid languages' );


my $req = I22r::Translate::Request->new(
    src => 'en',
    dest => 'es',
    text => {
   	1 => 'hello world',
	2 => 'goodbye world',
    },
    return_type => 'hash'
);
$req->backend('I22r::Translate::Microsoft');

my @r = eval { I22r::Translate::Microsoft->get_translations($req) };
ok( @r != 0, 'translation results' );
ok(grep($_ eq '1',@r) && grep($_ eq '2',@r),
   'translation results for inputs');
my %r = %{ $req->results };
$req->backend(undef);

my $r1 = eval { $r{1}->text };
my $r2 = eval { $r{2}->text };

diag map{" ".ord}split//, $r2;

ok( $r1 ne '', 'translation result 1' );
ok( $r1 ne 'hello world', 'translation result 1 changed text' );
ok( $r2 ne '', 'translation result 2' );
ok( $r2 ne 'goodbye world', 'translation result 2 changed text' );

done_testing();

# TODO - translation into non-latin character sets
# TODO - translation from non-latin character sets
