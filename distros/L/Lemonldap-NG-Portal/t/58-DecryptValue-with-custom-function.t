use Test::More;
use strict;
use IO::String;
use lib 't/lib';

BEGIN {
    require 't/test-lib.pm';
}

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel              => 'error',
            authentication        => 'Demo',
            userDB                => 'Same',
            key                   => 'Demo',
            loginHistoryEnabled   => 0,
            brutForceProtection   => 0,
            requireToken          => 0,
            decryptValueRule      => 1,
            decryptValueFunctions =>
'Lemonldap::NG::Portal::Custom::empty Lemonldap::NG::Portal::Custom::test_uc Lemonldap::NG::Portal::Custom::undefined',
        }
    }
);

## Try to authenticate
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
count(1);
my ( $host, $url, $query ) = expectForm( $res, '#', undef, 'user', 'password' );

$query = 'user=dwho&password=dwho';
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
ok(
    $res = $client->_get(
        '/',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'CheckUser form',
);
ok( $res->[2]->[0] =~ m%<img src="/static/common/icons/decryptValue\.png"%,
    'Found decryptValue.png' )
  or explain( $res->[2]->[0], 'decryptValue.png' );
count(3);

# DecryptValue form
# ------------------------
ok(
    $res = $client->_get(
        '/decryptvalue',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'DecryptValue form',
);
( $host, $url, $query ) =
  expectForm( $res, undef, '/decryptvalue', 'cipheredValue' );
ok( $res->[2]->[0] =~ m%<span trspan="decryptCipheredValue">%,
    'Found trspan="decryptCipheredValue"' )
  or explain( $res->[2]->[0], 'trspan="decryptCipheredValue"' );
count(2);

# Decrypt ciphered value
$query =~ s%cipheredValue=%cipheredValue=lowercase%;
ok(
    $res = $client->_post(
        '/decryptvalue',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
        accept => 'text/html',
    ),
    'POST decryptvalue with valid value'
);
ok( $res->[2]->[0] =~ m%<span trspan="LOWERCASE_DEMO"></span>%,
    'Found decryted value' )
  or explain( $res->[2]->[0], 'Decryted value NOT found' );
count(2);
( $host, $url, $query ) =
  expectForm( $res, undef, '/decryptvalue', 'cipheredValue' );

$client->logout($id);
clean_sessions();

done_testing( count() );
