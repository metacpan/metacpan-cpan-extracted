use Test::More;
use strict;
use IO::String;

BEGIN {
    require 't/test-lib.pm';
}

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel            => 'error',
            authentication      => 'Demo',
            userDB              => 'Same',
            loginHistoryEnabled => 0,
            brutForceProtection => 0,
            decryptValueRule    => '$uid eq "dwho"',
            requireToken        => 1,
        }
    }
);

## Try to authenticate
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
count(1);
my ( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'token' );

$query =~ s/user=/user=rtyler/;
$query =~ s/password=/password=rtyler/;
ok(
    $res = $client->_post(
        '/',
        IO::String->new($query),
        length => length($query),
        accept => 'text/html',
    ),
    'Auth query'
);
count(1);

my $id = expectCookie($res);
expectRedirection( $res, 'http://auth.example.com/' );

# DecryptValue form for a foridden user
# ------------------------
ok(
    $res = $client->_get(
        '/decryptvalue',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'Try DecryptValue form for a forbidden user',
);
count(1);
ok( $res->[2]->[0] =~ m%<span trmsg="95">%, 'Found trmsg="95"' )
  or explain( $res->[2]->[0], 'trmsg="95"' );
count(1);
$client->logout($id);

## Try to authenticate
ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu', );
count(1);
( $host, $url, $query ) =
  expectForm( $res, '#', undef, 'user', 'password', 'token' );

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

$id = expectCookie($res);
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
  expectForm( $res, undef, '/decryptvalue', 'cipheredValue', 'token' );
ok( $res->[2]->[0] =~ m%<span trspan="decryptCipheredValue">%,
    'Found trspan="decryptCipheredValue"' )
  or explain( $res->[2]->[0], 'trspan="decryptCipheredValue"' );
count(2);

# Valid ciphered value
$query =~
s%cipheredValue=%cipheredValue=CNCERR4E3BPrrEY0BZGnl3ISfUZARKXNhnDj3x7/xO5kxodXbeLzTk2VSHh1rq/C4TU78wzyWiove81YseYj/g==%;
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
ok( $res->[2]->[0] =~ m%<span trspan="dwho"></span>%, 'Found decryted value' )
  or explain( $res->[2]->[0], 'Decryted value NOT found' );
count(2);
( $host, $url, $query ) =
  expectForm( $res, undef, '/decryptvalue', 'cipheredValue', 'token' );

# Unvalid ciphered value
$query =~ s%cipheredValue=%cipheredValue=test%;
ok(
    $res = $client->_post(
        '/decryptvalue',
        IO::String->new($query),
        cookie => "lemonldap=$id",
        length => length($query),
        accept => 'text/html',
    ),
    'POST decryptvalue with unvalid value'
);
ok( $res->[2]->[0] =~ m%<span trspan="notAnEncryptedValue">%,
    'Found trspan="notAnEncryptedValue"' )
  or explain( $res->[2]->[0], 'trspan="notAnEncryptedValue"' );
count(2);
( $host, $url, $query ) =
  expectForm( $res, undef, '/decryptvalue', 'cipheredValue', 'token' );

$client->logout($id);
clean_sessions();

done_testing( count() );
