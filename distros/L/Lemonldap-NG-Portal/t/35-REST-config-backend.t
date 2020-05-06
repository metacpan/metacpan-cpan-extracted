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
my ( $issuer, $sp, $res, $spId );

# Redefine LWP methods for tests
LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        ok(
            $req->uri =~ m#http://auth.idp.com(.*?)(?:\?(.*))?$#,
            ' @ REST request (' . $req->method . " $1)"
        );
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
                    length => length($s),
                    type   => $req->header('Content-Type'),
                ),
                ' Post request'
            );
            count(1);
            expectOK($res);
        }
        elsif ( $req->method =~ /^(get|delete)$/i ) {
            my $mth = '_' . lc($1);
            ok(
                $res = $issuer->$mth(
                    $url,
                    accept => $req->header('Accept'),
                    cookie => $req->header('Cookie'),
                    query  => $query,
                ),
                ' Execute request'
            );
            ok( ( $res->[0] == 200 or $res->[0] == 400 ),
                ' Response is 200 or 400' )
              or explain( $res->[0], '200 or 400' );
            count(2);
        }
        pass(' @ END OF REST REQUEST');
        count(1);
        return $res;
    }
);

$issuer = register( 'issuer', \&issuer );

# Test REST config backend
ok( $res = $issuer->_get('/config/latest'), 'Get latest conf metadata' );
count(1);
expectOK($res);

$sp = register( 'sp', \&sp );

switch ('sp');

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
        '/', IO::String->new('user=french&password=french'),
        length => 27,
        accept => 'text/html'
    ),
    'Post user/password'
);
count(2);
expectRedirection( $res, 'http://auth.sp.com' );
$spId = expectCookie($res);

# Test auth
ok( $res = $sp->_get( '/', cookie => "lemonldap=$spId" ), 'Auth test' );
count(1);
expectOK($res);

# Test other REST queries
switch ('issuer');

# Session content
ok( $res = $issuer->_get("/sessions/global/$spId"), 'Session content' );
expectOK($res);
ok( $res = eval { JSON::from_json( $res->[2]->[0] ) }, ' GET JSON' )
  or print STDERR $@;
ok( $res->{_session_id} eq $spId, ' Good ID' )
  or explain( $res, "_session_id => $spId" );
count(3);

# Session key
ok( $res = $issuer->_get("/sessions/global/$spId/[_session_id,uid,cn]"),
    'Some session keys' );
expectOK($res);
ok( $res = eval { JSON::from_json( $res->[2]->[0] ) }, ' GET JSON' )
  or print STDERR $@;
ok( $res->{_session_id} eq $spId, ' Good ID' )
  or explain( $res, "_session_id => $spId" );
ok( $res->{uid} eq 'french', ' Uid is french' )
  or explain( $res, 'uid => french' );
ok( $res->{cn} eq 'Frédéric Accents', ' UTF-8 values' );
count(5);

# Retrieve error messages
ok(
    $res = $issuer->_get("/error/fr/9"),
    'Retrieve error message: 9 from lang: fr'
);
expectOK($res);
ok( $res = eval { JSON::from_json( $res->[2]->[0] ) }, ' GET JSON' )
  or print STDERR $@;
ok( $res->{lang} eq 'fr', ' Good lang' )
  or explain( $res, 'lang => fr' );
ok( $res->{errorNum} eq '9', ' Good errorNum' )
  or explain( $res, 'errorNum => 9' );
ok( $res->{errorMsgRef} eq 'PE9', ' Good errorMsgName' )
  or explain( $res, 'errorMsgName => PE9' );
ok( $res->{errorsFileURL} eq '/static/languages/fr.json', ' Good file URL' )
  or explain( $res, 'URL' );
ok( $res->{result} eq '1', ' Good result' )
  or explain( $res, 'result => 1' );
count(7);

ok(
    $res = $issuer->_get("/error/es"),
    'Retrieve ALL error messages from lang: es'
);
expectOK($res);
ok( $res = eval { JSON::from_json( $res->[2]->[0] ) }, ' GET JSON' )
  or print STDERR $@;
ok( $res->{lang} eq 'es', ' Good lang' )
  or explain( $res, 'lang => es' );
ok( $res->{errorNum} eq 'all', ' Good errorNum' )
  or explain( $res, 'errorNum => all' );
ok( $res->{errorsFileURL} eq '/static/languages/es.json', ' Good file URL' )
  or explain( $res, 'URL' );
ok( $res->{result} eq '1', ' Good result' )
  or explain( $res, 'result => 1' );
count(6);

ok( $res = $issuer->_get("/error"),
    'Retrieve ALL error messages from lang: en (default)' );
expectOK($res);
ok( $res = eval { JSON::from_json( $res->[2]->[0] ) }, ' GET JSON' )
  or print STDERR $@;
ok( $res->{lang} eq 'en', ' Good lang' )
  or explain( $res, 'lang => en' );
ok( $res->{errorNum} eq 'all', ' Good errorNum' )
  or explain( $res, 'errorNum => all' );
ok( $res->{errorsFileURL} eq '/static/languages/en.json', ' Good file URL' )
  or explain( $res, 'URL' );
ok( $res->{result} eq '1', ' Good result' )
  or explain( $res, 'result => 1' );
count(6);

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
                templateDir       => 'site/templates',
                staticPrefix      => '/static',
            }
        }
    );
}

sub sp {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel       => $debug,
                domain         => 'sp.com',
                portal         => 'http://auth.sp.com',
                authentication => 'Demo',
                userDB         => 'Same',
                configStorage  => {
                    type    => 'REST',
                    baseUrl => 'http://auth.idp.com/config',
                },
            },
        }
    );
}
