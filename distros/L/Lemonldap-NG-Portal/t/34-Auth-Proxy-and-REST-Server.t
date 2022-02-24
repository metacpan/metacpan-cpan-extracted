use lib 'inc';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;

BEGIN {
    require 't/test-lib.pm';
}

my $debug = 'error';
my ( $issuer, $sp, $res, $spId, $idpId );

LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        ok( $req->uri =~ m#http://auth.idp.com([^\?]*?)(?:\?(.*))?$#,
            ' @ REST request (' . $req->method . " $1)" );
        count(1);
        my $url   = $1;
        my $query = $2;
        my $res;
        my $s = $req->content;
        if ( $req->method =~ /^(post|put)$/i ) {
            my $mth = '_' . lc($1);
            my $s   = $req->content;
            ok(
                $res = $issuer->$mth(
                    $url,
                    IO::String->new($s),
                    ( $query ? ( query => $query ) : () ),
                    length => length($s),
                    type   => $req->header('Content-Type'),
                ),
                ' Post request'
            );
            count(1);
            expectOK($res);
            $idpId = expectCookie($res) unless ( $req->param('all') );
        }
        elsif ( $req->method =~ /^(get|delete)$/i ) {
            my $mth = '_' . lc($1);
            ok(
                $res = $issuer->$mth(
                    $url,
                    ( $query ? ( query => $query ) : () ),
                    accept => $req->header('Accept'),
                    cookie => $req->header('Cookie')
                ),
                ' Execute request'
            );
            count(1);
            expectOK($res);
        }
        ok(
            getHeader( $res, 'Content-Type' ) =~ m#^(?:text|application)/json#,
            'Content is JSON'
        ) or explain( $res->[1], 'Content-Type => application/json' );
        count(1);
        return $res;
    }
);

$issuer = register( 'issuer', \&issuer );
$sp     = register( 'sp',     \&sp );

# Simple SP access
ok(
    $res = $sp->_get(
        '/', accept => 'text/html',
    ),
    'Unauth SP request'
);
expectOK($res);

# Try to auth
ok(
    $res = $sp->_post(
        '/', IO::String->new('user=dwho&password=dwho'),
        length => 23,
        accept => 'text/html'
    ),
    'Post user/password'
);
count(2);
expectRedirection( $res, 'http://auth.sp.com' );
$spId = expectCookie($res);

# Test other REST queries
switch ('issuer');

# Session content
ok( $res = $issuer->_get("/sessions/global/$idpId"), 'Session content' );
expectOK($res);
ok( $res = eval { JSON::from_json( $res->[2]->[0] ) }, ' GET JSON' )
  or print STDERR $@;
ok( $res->{_session_id} eq $idpId, ' Good ID' )
  or explain( $res, "_session_id => $idpId" );
count(3);

# Session key
ok( $res = $issuer->_get("/sessions/global/$idpId/[_session_id,uid]"),
    'Some session keys' );
expectOK($res);
ok( $res = eval { JSON::from_json( $res->[2]->[0] ) }, ' GET JSON' )
  or print STDERR $@;
ok( $res->{_session_id} eq $idpId, ' Good ID' )
  or explain( $res, "_session_id => $idpId" );
ok( $res->{uid} eq 'dwho', ' Uid is dwho' ) or explain( $res, 'uid => dwho' );
count(4);

# New session
ok(
    $res = $issuer->_post(
        '/sessions/global', IO::String->new('{"uid":"zz","_whatToTrace":"zz"}'),
        length => 32,
        type   => 'application/json'
    ),
    'Create session'
);
expectOK($res);
ok( $res = eval { JSON::from_json( $res->[2]->[0] ) }, ' GET JSON' )
  or print STDERR $@;
my $newId = $res->{session}->{_session_id};

# Verify a key
ok( $res = $issuer->_get("/sessions/global/$newId/uid"), 'Verify uid' );
ok( $res->[2]->[0] eq 'zz',                              ' Uid is good' );
count(4);

# Update a key
ok(
    $res = $issuer->app->( {
            HTTP_ACCEPT            => 'application/json',
            HTTP_ACCEPT_LANGUAGE   => 'fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3',
            HTTP_HOST              => 'auth.idp.com',
            PATH_INFO              => "/sessions/global/$newId",
            REMOTE_ADDR            => '127.0.0.1',
            REQUEST_METHOD         => 'PUT',
            REQUEST_URI            => "/sessions/global/$newId",
            SCRIPT_NAME            => '',
            SERVER_NAME            => 'auth.example.com',
            SERVER_PORT            => '80',
            SERVER_PROTOCOL        => 'HTTP/1.1',
            'psgix.input.buffered' => 0,
            'psgi.input'           => IO::String->new('{"cn":"CN"}'),
            CONTENT_TYPE           => 'application/json',
            CONTENT_LENGTH         => 11,
        }
    ),
    'Put a new key'
);
expectOK($res);
ok( $res = eval { JSON::from_json( $res->[2]->[0] ) }, ' GET JSON' )
  or print STDERR $@;
ok( $res->{result} == 1, ' Result is 1' );
count(3);

# Verify new key
ok( $res = $issuer->_get("/sessions/global/$newId/cn"), 'Verify cn' );
ok( $res->[2]->[0] eq 'CN',                             ' CN is good' );
count(2);

use_ok('Lemonldap::NG::Common::Apache::Session::REST');
ok(
    $res =
      Lemonldap::NG::Common::Apache::Session::REST->get_key_from_all_sessions( {
            baseUrl => 'http://auth.idp.com/sessions/global/',
        }
      ),
    'Search all sessions'
);

my ( $c1, $c2 ) = ( 0, 0 );
if ( ok( ref($res) eq 'HASH', ' Result is an hash' ) ) {
    my $tmp = 1;
    foreach ( keys %$res ) {
        $c1++;
        unless ( $res->{$_}->{_session_id} ) {
            $tmp = 0;
            diag "Bad session:\n" . Dumper( $res->{$_} );
        }
    }
    ok( $c1,  " Found $c1 sessions" );
    ok( $tmp, ' All sessions are valid' );
    count(2);
}
count(3);

ok(
    $res =
      Lemonldap::NG::Common::Apache::Session::REST->get_key_from_all_sessions(
        { baseUrl => 'http://auth.idp.com/sessions/global/' },
        sub { return 'a' }
      ),
    'Search all sessions with a code'
);

if ( ok( ref($res) eq 'HASH', ' Result is an hash' ) ) {
    my $tmp = 1;
    my $c   = 0;
    foreach ( keys %$res ) {
        $c++;
        unless ( $res->{$_} eq 'a' ) {
            $tmp = 0;
            diag "Bad session:\n" . Dumper( $res->{$_} );
        }
    }
    ok( $c == $c1, " Found the same count" ) or explain( $c, $c1 );
    ok( $tmp,      ' All sessions are valid' );
    count(2);
}
count(2);

ok(
    $res = Lemonldap::NG::Common::Apache::Session::REST->searchOn( {
            baseUrl => 'http://auth.idp.com/sessions/global/'
        },
        'uid', 'dwho'
    ),
    'Search dwho sessions'
);
if ( ok( ref($res) eq 'HASH', ' Result is an hash' ) ) {
    my $tmp = 1;
    foreach ( keys %$res ) {
        $c2++;
        unless ( $res->{$_}->{_session_id} ) {
            $tmp = 0;
            diag "Bad session:\n" . Dumper( $res->{$_} );
        }
    }
    ok( $c2,  " Found $c2 sessions" );
    ok( $tmp, ' All sessions are valid' );
    count(2);
}

ok( $c2 < $c1,
    'searchOn() count is lower than get_key_from_all_sessions() count' );
count(3);

# Del new session
ok(
    $res = $issuer->app->( {
            HTTP_ACCEPT          => 'application/json',
            HTTP_ACCEPT_LANGUAGE => 'fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3',
            HTTP_HOST            => 'auth.idp.com',
            PATH_INFO            => "/sessions/global/$newId",
            REMOTE_ADDR          => '127.0.0.1',
            REQUEST_METHOD       => 'DELETE',
            REQUEST_URI          => "/sessions/global/$newId",
            SCRIPT_NAME          => '',
            SERVER_NAME          => 'auth.example.com',
            SERVER_PORT          => '80',
            SERVER_PROTOCOL      => 'HTTP/1.1',
        }
    ),
    'Delete new session'
);
expectOK($res);
ok( $res = eval { JSON::from_json( $res->[2]->[0] ) }, ' GET JSON' )
  or print STDERR $@;
ok( $res->{result} == 1, ' Result is 1' );
count(3);

# Verify that session is deleted
ok( $res = $issuer->_get("/sessions/global/$newId/cn"),
    'New session is deleted' );
ok( $res->[0] == 400, ' Session does not exist' );
count(2);

# Logout
switch ('sp');
ok(
    $res = $sp->_get(
        '/',
        query  => 'logout',
        accept => 'text/html',
        cookie => "lemonldap=$spId"
    ),
    'Ask for logout'
);
count(1);
expectOK($res);

# Test if user is reject on IdP
ok(
    $res = $sp->_get(
        '/', cookie => "lemonldap=$spId",
    ),
    'Test if user is reject on IdP'
);
count(1);
expectReject($res);

clean_sessions();
done_testing( count() );

# Redefine LWP methods for tests
sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel          => $debug,
                domain            => 'idp.com',
                portal            => 'http://auth.idp.com',
                authentication    => 'Demo',
                userDB            => 'Same',
                restSessionServer => 1,
                restConfigServer  => 1,
            }
        }
    );
}

sub sp {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel         => $debug,
                domain           => 'sp.com',
                portal           => 'http://auth.sp.com',
                authentication   => 'Proxy',
                userDB           => 'Same',
                proxyAuthService => 'http://auth.idp.com',
                proxyUseSoap     => 0,
                whatToTrace      => '_whatToTrace',
            },
        }
    );
}
