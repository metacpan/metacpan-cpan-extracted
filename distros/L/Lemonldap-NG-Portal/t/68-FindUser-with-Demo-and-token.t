use Test::More;
use strict;
use JSON;
use IO::String;

require 't/test-lib.pm';

my $res;
my $json;
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                    => 'error',
            authentication              => 'Demo',
            userDB                      => 'Same',
            useSafeJail                 => 1,
            requireToken                => 1,
            findUser                    => 1,
            impersonationRule           => 1,
            findUserSearchingAttributes =>
              { 'uid##1' => 'Login', 'guy##1' => 'Kind', 'cn##1' => 'Name' },
            findUserExcludingAttributes =>
              { type => 'mutant', uid => 'rtyler' },
        }
    }
);

## Simple access
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Portal', );
my ( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'spoofId', 'token' );
( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'uid', 'guy', 'cn', 'token' );
ok(
    $res->[2]->[0] =~
      m%<input id="token" type="hidden" name="token" value="([\d_]+?)" />%,
    'Token value found'
) or explain( $res->[2]->[0], 'Token value' );
my $count = $res->[2]->[0] =~ s/$1//g;
ok( $count == 2, 'Two token value found' )
  or explain( $res->[2]->[0], '2 token values found' );
count(3);

$query =~ s/uid=/uid=dwho/;
ok(
    $res = $client->_post(
        '/finduser', IO::String->new($query),
        accept => 'application/json',
        length => length($query)
    ),
    'Post FindUser request'
);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{user} eq 'dwho', ' Good user' )
  or explain( $json, 'user => dwho' );
count(3);

ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Portal', );
( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'uid', 'guy', 'cn', 'token' );
Time::Fake->offset("+150s");
$query =~ s/uid=/uid=dwho/;
ok(
    $res = $client->_post(
        '/finduser', IO::String->new($query),
        accept => 'application/json',
        length => length($query)
    ),
    'Post expired FindUser request'
);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{error} == 82, ' Token expired' )
  or explain( $json, 'Token expired' );
ok( $json->{result} == 0, ' result => 0' )
  or explain( $json, 'Result => 0' );
ok( $json->{token} =~ /\w+/, ' Token found' )
  or explain( $json, 'Token renewed' );
count(6);

ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Portal', );
( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'guy', 'cn', 'token' );
$query = 'uid=dwho';
ok(
    $res = $client->_post(
        '/finduser', IO::String->new($query),
        accept => 'application/json',
        length => length($query)
    ),
    'Post FindUser request without token'
);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{error} == 81, ' No Token' )
  or explain( $json, 'No token' );
ok( $json->{result} == 0, ' result => 0' )
  or explain( $json, 'Result => 0' );
ok( $json->{token} =~ /\w+/, ' Token found' )
  or explain( $json, 'Token renewed' );
count(6);

ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Portal', );
( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'guy', 'cn', 'token' );
$query =~ s/user=/user=dwho/;
$query =~ s/password=/password=dwho/;
$query =~ s/spoofId=/spoofId=rtyler/;
ok(
    $res = $client->_post(
        '/', IO::String->new($query),
        accept => 'application/json',
        length => length($query)
    ),
    'Post FindUser request with token'
);
my $id = expectCookie($res);
ok( $json = eval { from_json( $res->[2]->[0] ) }, 'Response is JSON' )
  or print STDERR "$@\n" . Dumper($res);
ok( $json->{result} == 1, ' result => 1' )
  or explain( $json, 'Result => 1' );
ok(
    $res = $client->_get(
        '/',
        accept => 'text/html',
        cookie => "lemonldap=$id",
    ),
    'GET Portal'
);
expectOK($res);
expectAuthenticatedAs( $res, 'rtyler' );
count(5);

$client->logout($id);
clean_sessions();
done_testing( count() );
