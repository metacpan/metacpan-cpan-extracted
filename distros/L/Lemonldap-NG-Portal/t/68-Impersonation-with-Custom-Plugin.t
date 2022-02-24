use Test::More;
use strict;
use IO::String;
use JSON;
use Lemonldap::NG::Portal::Main::Constants qw(PE_BADCREDENTIALS);

require 't/test-lib.pm';

my $res;
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel          => 'error',
            passwordDB        => 'Demo',
            impersonationRule => 1,
            customFunctions   =>
              'My::accesToTrace   My::return0,,  My::return1  ',
            customPlugins =>
't::AfterDataCustomPlugin    t::CasHookPlugin,, t::OidcHookPlugin ',
            customPluginsParams => { uid => 'rtyler' }
        }
    }
);

ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu' );
count(1);
my ( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'spoofId' );

# Try to authenticate
# -------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23
    ),
    'Auth query'
);
count(1);
expectOK($res);
my $id = expectCookie($res);
$client->logout($id);

# Try to authenticate
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=rtyler&password=rtyler'),
        length => 27
    ),
    'Auth query'
);
eval { $res = JSON::from_json( $res->[2]->[0] ) };
ok( not($@), 'Content is JSON' )
  or explain( $res->[2]->[0], 'JSON content' );
ok( $res->{error} == PE_BADCREDENTIALS, 'BAD CREDENTIALS' );
count(3);

clean_sessions();
done_testing( count() );
