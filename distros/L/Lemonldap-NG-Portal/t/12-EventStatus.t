use warnings;
use Test::More;
use strict;
use IO::String;
use MIME::Base64;
use URI;
use URI::QueryParam;

require 't/test-lib.pm';

my $res;

$ENV{FORCE_STATUS} = 'force status';

my $client = LLNG::Manager::Test->new( {
        ini => {
            portal      => 'https://auth.example.com/',
            useSafeJail => 1,
            eventStatus => 1,
        }
    }
);

# Test normal first access
# ------------------------
ok( $res = $client->_get('/'), 'Unauth JSON request' );
expectReject($res);
expectStatus(9);

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
expectStatus(109);

# Test "first access" with a wildcard-protected url
ok(
    $res = $client->_get(
        '/',
        query  => 'url=' . encode_base64( "http://test.example.llng/", '' ),
        accept => 'text/html'
    ),
    'Get Menu'
);
expectStatus(9);

# Test "first access" with good url
ok(
    $res =
      $client->_get( '/', query => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw==' ),
    'Unauth ajax request with good url'
);
expectReject($res);
expectStatus(9);

ok( $res = $client->_get( '/', accept => 'text/html' ), 'Get Menu' );
expectStatus(9);

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
expectStatus(5);

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
expectStatus(5);

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
expectStatus(0);
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
expectStatus(0);
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
expectStatus(109);
expectOK($res);
expectAuthenticatedAs( $res, 'dwho' );

require 't/test-psgi.pm';

ok( $res = mirror( cookie => "lemonldap=$id" ), 'PSGI test' );
expectOK($res);
expectAuthenticatedAs( $res, 'dwho' );

# Test logout
$client->logout($id);

#print STDERR Dumper($res);

clean_sessions();

done_testing();

sub getStatus {
    return Lemonldap::NG::Handler::Main->tsv->{msgBrokerWriter}
      ->getNextMessage('llng_status');
}

sub expectStatus {
    my ($code) = @_;
    my $status = getStatus();
    $status = getStatus() if $status and $status->{handlerAction};
    ok( ( $status and $status->{portalCode} eq $code ), "Get status $code" )
      or explain( $status, "portalCode => $code" );
}
