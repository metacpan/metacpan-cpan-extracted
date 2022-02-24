use Test::More;
use strict;
use JSON;
use IO::String;

require 't/test-lib.pm';

my $res;
my $json;
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
            authChoiceFindUser          => '1_dem',
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
        accept => 'text/html',
        length => length($query)
    ),
    'Post FindUser request'
);
ok(
    $res->[2]->[0] =~
m%<input name="spoofId" type="text" class="form-control" value="" autocomplete="off"%,
    'value=""'
) or explain( $res->[2]->[0], 'value=""' );
( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'uid', 'guy', 'cn', 'token' );
$query =~ s/user=/user=rtyler/;
$query =~ s/password=/password=rtyler/;
$query =~ s/2_ssl/1_demo/;
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Auth query'
);
my $id = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );
$client->logout($id);
count(3);

clean_sessions();
done_testing( count() );
