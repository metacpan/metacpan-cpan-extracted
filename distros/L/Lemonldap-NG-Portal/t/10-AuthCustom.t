use Test::More;
use strict;
use IO::String;
use MIME::Base64;

require 't/test-lib.pm';

my $res;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel       => 'error',
            useSafeJail    => 1,
            authentication => "Custom",
            customAuth     => "::Auth::Demo",
            customUserDB   => "::UserDB::Demo"
        }
    }
);

# Test normal first access
# ------------------------
ok( $res = $client->_get('/'), 'Unauth JSON request' );
expectReject($res);

# Test "first access" with an unprotected url
ok(
    $res = $client->_get(
        '/',
        query  => 'url=' . encode_base64( "http://test.example.fr/", '' ),
        accept => 'text/html'
    ),
    'Get Menu'
);
expectPortalError( $res, 109, 'Rejected with PE_UNPROTECTEDURL' );
ok( $res->[2]->[0] =~ m%<span id="languages"></span>%, ' Language icons found' )
  or print STDERR Dumper( $res->[2]->[0] );
count(3);

# Test "first access" with a wildcard-protected url
ok(
    $res = $client->_get(
        '/',
        query  => 'url=' . encode_base64( "http://test.example.llng/", '' ),
        accept => 'text/html'
    ),
    'Get Menu'
);
ok( $res->[2]->[0] =~ /<span trmsg="9">/, 'Rejected with PE_FIRSTACCESS' )
  or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m%<span id="languages"></span>%, ' Language icons found' )
  or print STDERR Dumper( $res->[2]->[0] );
count(3);

# Test "first access" with good url
ok(
    $res =
      $client->_get( '/', query => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==' ),
    'Unauth ajax request with good url'
);
count(1);
expectReject($res);

ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu' );
ok( $res->[2]->[0] =~ m%<span id="languages"></span>%, ' Language icons found' )
  or print STDERR Dumper( $res->[2]->[0] );
count(2);

# Try to authenticate with unknown user
# -------------------------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=jdoe&password=jdoe'),
        accept => 'text/html',
        length => 23
    ),
    'Auth query'
);
ok(
    $res->[2]->[0] =~ /<span trmsg="5">/,
    'jdoe rejected with PE_BADCREDENTIALS'
) or print STDERR Dumper( $res->[2]->[0] );
ok( $res->[2]->[0] =~ m%<span trspan="connect">Connect</span>%,
    'Found connect button' )
  or print STDERR Dumper( $res->[2]->[0] );
count(3);

# Try to authenticate with bad password
# -------------------------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=jdoe'),
        accept => 'text/html',
        length => 23
    ),
    'Auth query'
);
count(1);
ok(
    $res->[2]->[0] =~ /<span trmsg="5">/,
    'dwho rejected with PE_BADCREDENTIALS'
) or print STDERR Dumper( $res->[2]->[0] );
count(1);
ok( $res->[2]->[0] =~ m%<span trspan="connect">Connect</span>%,
    'Found connect button' )
  or print STDERR Dumper( $res->[2]->[0] );
count(1);

# Try to authenticate with good password
# --------------------------------------
ok(
    $res = $client->_post(
        '/',
        IO::String->new('user=dwho&password=dwho'),
        length => 23,
    ),
    'Auth query'
);
count(1);
expectOK($res);
my $id = expectCookie($res);

# Try to get a redirection for an auth user with a valid url
# ----------------------------------------------------------
ok(
    $res = $client->_get(
        '/',
        query  => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'Auth ajax request with good url'
);
count(1);
expectRedirection( $res, 'http://test1.example.com/' );
expectAuthenticatedAs( $res, 'dwho' );

# Try to get a redirection for an auth user with a bad url (host undeclared
# in manager)
# -------------------------------------------------------------------------
ok(
    $res = $client->_get(
        '/',
        query  => 'url=aHR0cHM6Ly90LmV4YW1wbGUuY29tLw==',
        cookie => "lemonldap=$id",
        accept => 'text/html'
    ),
    'Auth request with bad url'
);
count(1);
expectOK($res);
expectAuthenticatedAs( $res, 'dwho' );

require 't/test-psgi.pm';

ok( $res = mirror( cookie => "lemonldap=$id" ), 'PSGI test' );
count(1);
expectOK($res);
expectAuthenticatedAs( $res, 'dwho' );

# Test logout
$client->logout($id);

#print STDERR Dumper($res);

clean_sessions();

done_testing( count() );
