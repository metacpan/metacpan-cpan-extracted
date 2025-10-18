use strict;
use warnings;
use Test::More;
use IO::String;
use JSON qw(from_json);

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel          => 'error',
            useSafeJail       => 1,
            portalMainLogo    => 'common/logos/logo_llng_old.png',
            authentication    => 'Choice',
            restSessionServer => 1,
            nullAuthnLevel    => 1,
            userDB            => 'Same',
            authChoiceParam   => 'test',
            authChoiceModules => {
                '1_securenull' =>
'Custom;Custom;Null;;;{"nullAuthnLevel": 3, "customAuth": "t::SecureNull", "customUserDB": "::UserDB::Null"}',
                '2_null' =>
'Custom;Custom;Null;;;{"customAuth": "::Auth::Null", "customUserDB": "::UserDB::Null"}',
            },
        }
    }
);

ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu' );
ok( $res->[2]->[0] =~ /1_securenull/, '1_securenull displayed' );
ok( $res->[2]->[0] =~ /2_null/,       '2_null displayed' );
ok( $res->[2]->[0] =~ /input type="checkbox" id="checkLogins1_securenull"/, '1_securenull checkbox displayed' );
ok( $res->[2]->[0] =~ /input type="checkbox" id="checkLogins2_null"/,       '2_null checkbox displayed' );

# Authenticate on first choice
my $postString = 'user=dwho&password=dwho&test=1_securenull';

ok(
    $res = $client->_post(
        '/',
        IO::String->new($postString),
        length => length($postString)
    ),
    'Auth query'
);
expectOK($res);
my $id = expectCookie($res);
my $session = getSession($id)->data;
is( $session->{authenticationLevel},
    3, "Overriden authentication level" );
is( $session->{_auth},
    "SecureNull", "Allow custom modules to override their name" );
$client->logout($id);

# Authenticate on second choice
$postString = 'user=dwho&password=dwho&test=2_null';

# Try to authenticate
# -------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new($postString),
        length => length($postString)
    ),
    'Auth query'
);
expectOK($res);
$id = expectCookie($res);
$session = getSession($id)->data;
is( $session->{authenticationLevel},
    1, "Default authentication level" );
is( $session->{_auth},
    "Null", "Correct fallback when no name is defined" );
$client->logout($id);

clean_sessions();
done_testing();

BEGIN {
    package t::SecureNull;
    use Mouse;
    extends 'Lemonldap::NG::Portal::Auth::Null';

    use constant name => "SecureNull";
}

1;
