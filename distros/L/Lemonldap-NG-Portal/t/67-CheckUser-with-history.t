use Test::More;
use strict;
use IO::String;

require 't/test-lib.pm';

my $res;
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                => 'error',
            authentication          => 'Demo',
            userDB                  => 'Same',
            loginHistoryEnabled     => 1,
            checkUser               => 1,
            checkUserDisplayHistory => '$uid eq "dwho"',
            macros                  => {
                _whatToTrace =>
                  '$_auth eq "SAML" ? "$_user\@$_idpConfKey" : "$_user"',
                mail => 'uc $mail',
            }
        }
    }
);

## Try to authenticate (build history)
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
my ( $host, $url, $query ) = expectForm( $res, '#', undef, 'user', 'password' );
$query =~ s/user=/user=dwho/;
$query =~ s/password=/password=ohwd/;
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Auth query'
);
count(2);

ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
( $host, $url, $query ) = expectForm( $res, '#', undef, 'user', 'password' );
$query =~ s/user=/user=dwho/;
$query =~ s/password=/password=dwho/;
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Auth query'
);
count(2);
my $id = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );
$client->logout($id);

ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
( $host, $url, $query ) = expectForm( $res, '#', undef, 'user', 'password' );
$query =~ s/user=/user=dwho/;
$query =~ s/password=/password=dwho/;
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Auth query'
);
count(2);
$id = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

# CheckUser form
# ------------------------
ok(
    $res = $client->_get(
        '/checkuser',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'CheckUser form',
);
( $host, $url, $query ) =
  expectForm( $res, undef, '/checkuser', 'user', 'url' );
ok( $res->[2]->[0] =~ m%<span trspan="checkUser">%, 'Found trspan="checkUser"' )
  or explain( $res->[2]->[0], 'trspan="checkUser"' );
ok( $res->[2]->[0] =~ m%<span trspan="lastLogins">%,
    'Found trspan="lastLogins"' )
  or explain( $res->[2]->[0], 'trspan="lastLogins"' );
ok( $res->[2]->[0] =~ m%<span trspan="lastFailedLogins">%,
    'Found trspan="lastFailedLogins"' )
  or explain( $res->[2]->[0], 'trspan="lastFailedLogins"' );
ok( $res->[2]->[0] =~ m%<td scope="row">ipAddr=127.0.0.1</td>%,
    'Success entry found' )
  or explain( $res->[2]->[0], 'Success entry' );
ok( $res->[2]->[0] =~ m%<td scope="row">error=5; ipAddr=127.0.0.1</td>%,
    'Failed entry found' )
  or explain( $res->[2]->[0], 'Failed entry' );
count(6);

$client->logout($id);
clean_sessions();

done_testing( count() );
