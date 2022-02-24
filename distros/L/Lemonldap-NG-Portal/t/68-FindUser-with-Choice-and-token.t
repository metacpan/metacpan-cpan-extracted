use Test::More;
use strict;
use JSON;
use IO::String;

require 't/test-lib.pm';

my $res;
my $json;
my $token;
my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel          => 'error',
            authentication    => 'Choice',
            userDB            => 'Same',
            passwordDB        => 'Choice',
            authChoiceModules => {
                '1_demo' => 'Demo;Demo;Null',
                '2_ssl'  => 'SSL;Demo;Null',
            },
            authChoiceFindUser          => '1_demo',
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
my @form = ( $res->[2]->[0] =~ m#<form.*?</form>#sg );
ok( @form == 3, 'Display 3 forms' )
  or explain( $res->[2]->[0], 'Forms are missing' );
ok( $query =~ /lmAuth=2_ssl/, 'lmAuth=2_ssl' )
  or explain( $query, 'lmAuth is not well defined' );
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
ok( $token = $json->{token}, 'Found token' );
count(4);

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
ok( $token = $json->{token}, 'Found token' );
count(6);

clean_sessions();
done_testing( count() );
