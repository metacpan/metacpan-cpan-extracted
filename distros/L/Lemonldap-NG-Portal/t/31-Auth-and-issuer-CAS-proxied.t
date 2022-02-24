use lib 'inc';
use Test::More;    # skip_all => 'CAS is in rebuild';
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;

BEGIN {
    require 't/test-lib.pm';
}

my $debug = 'error';
my ( $issuer, $sp, $res );

eval { require XML::Simple };
plan skip_all => "Missing dependencies: $@" if ($@);

# Redefine LWP methods for tests
LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        ok( $req->uri =~ m#http://auth.((?:id|s)p).com([^\?]*)(?:\?(.*))?$#,
            ' Request to ' . $req->uri );
        my $host  = $1;
        my $url   = $2;
        my $query = $3;
        my $res;
        my $client = ( $host eq 'idp' ? $issuer : $sp );
        if ( $req->method eq 'POST' ) {
            my $s = $req->content;
            ok(
                $res = $client->_post(
                    $url, IO::String->new($s),
                    length => length($s),
                    query  => $query,
                    type   => 'application/xml',
                ),
                " Execute POST request to $url"
            );
        }
        else {
            ok(
                $res = $client->_get(
                    $url,
                    type  => 'application/xml',
                    query => $query,
                ),
                " Execute request to $url"
            );
        }
        expectOK($res);
        count(2);
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
count(1);
ok( expectCookie( $res, 'llngcasserver' ) eq 'idp', 'Get CAS server cookie' );
count(1);
expectRedirection( $res,
    'http://auth.idp.com/cas/login?service=http%3A%2F%2Fauth.sp.com%2F' );

# Query IdP
switch ('issuer');
ok(
    $res = $issuer->_get(
        '/cas/login',
        query  => 'service=http://auth.sp.com/',
        accept => 'text/html'
    ),
    'Query CAS server'
);
count(1);
expectOK($res);
my $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

# Try to authenticate to IdP
my $body = $res->[2]->[0];
$body =~ s/^.*?<form.*?>//s;
$body =~ s#</form>.*$##s;
my %fields =
  ( $body =~ /<input type="hidden".+?name="(.+?)".+?value="(.*?)"/sg );
$fields{user} = $fields{password} = 'french';
use URI::Escape;
my $s = join( '&', map { "$_=" . uri_escape( $fields{$_} ) } keys %fields );
ok(
    $res = $issuer->_post(
        '/cas/login',
        IO::String->new($s),
        cookie => $pdata,
        accept => 'text/html',
        length => length($s),
    ),
    'Post authentication'
);
count(1);
my ($query) =
  expectRedirection( $res, qr#^http://auth.sp.com/\?(ticket=[^&]+)$# );
my $idpId = expectCookie($res);

# Back to SP
switch ('sp');
ok(
    $res = $sp->_get(
        '/',
        query  => $query,
        accept => 'text/html',
        cookie => 'llngcasserver=idp',
    ),
    'Query SP with ticket'
);
count(1);
my $spId = expectCookie($res);

# Test authentication
ok( $res = $sp->_get( '/', cookie => "lemonldap=$spId,llngcasserver=idp" ),
    'Get / on SP' );
count(1);
expectOK($res);
expectAuthenticatedAs( $res, 'french' );

# Test attributes
ok( $res = $sp->_get("/sessions/global/$spId"), 'Get UTF-8' );
expectOK($res);
ok( $res = eval { JSON::from_json( $res->[2]->[0] ) }, ' GET JSON' )
  or print STDERR $@;
ok( $res->{cn} eq 'Frédéric Accents', 'UTF-8 values' )
  or explain( $res, 'cn => Frédéric Accents' );
count(3);

# Logout initiated by SP
ok(
    $res = $sp->_get(
        '/',
        query  => 'logout',
        cookie => "lemonldap=$spId,llngcasserver=idp",
        accept => 'text/html'
    ),
    'Query SP for logout'
);
count(1);
expectOK($res);
ok(
    $res->[2]->[0] =~ m#iframe src="http://auth.idp.com(/cas/logout)\?(.+?)"#s,
    'Found iframe'
);
count(1);

# Query IdP with iframe src
my $url = $1;
$query = $2;
expectCspChildOK( $res, "auth.idp.com" );

switch ('issuer');
ok(
    $res = $issuer->_get(
        $url,
        query  => $query,
        accept => 'text/html',
        cookie => "lemonldap=$idpId"
    ),
    'Get iframe from IdP'
);
count(1);
expectRedirection( $res, 'http://auth.sp.com/?logout' );
my $h = getHeader( $res, 'Content-Security-Policy' );
ok( ( not $h or $h !~ /frame-ancestors/ ), ' Frame can be embedded' )
  or explain( $res->[1],
    'Content-Security-Policy does not contain a frame-ancestors' );
count(1);

# Verify that user has been disconnected
ok( $res = $issuer->_get( '/', cookie => "lemonldap=$idpId" ), 'Query IdP' );
count(1);
expectReject($res);

switch ('sp');
ok(
    $res = $sp->_get(
        '/',
        accept => 'text/html',
        cookie => "lemonldap=$idpId,llngcasserver=idp"
    ),
    'Query IdP'
);
count(1);
expectRedirection( $res,
    'http://auth.idp.com/cas/login?service=http%3A%2F%2Fauth.sp.com%2F' );

clean_sessions();
done_testing( count() );

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel               => $debug,
                domain                 => 'idp.com',
                portal                 => 'http://auth.idp.com',
                authentication         => 'Demo',
                userDB                 => 'Same',
                issuerDBCASActivation  => 1,
                casAttr                => 'uid',
                casAttributes          => { cn => 'cn', uid => 'uid', },
                casAccessControlPolicy => 'none',
                multiValuesSeparator   => ';',
            }
        }
    );
}

sub sp {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                   => $debug,
                domain                     => 'sp.com',
                portal                     => 'http://auth.sp.com',
                authentication             => 'CAS',
                userDB                     => 'CAS',
                restSessionServer          => 1,
                issuerDBCASActivation      => 0,
                multiValuesSeparator       => ';',
                casSrvMetaDataExportedVars => {
                    idp => {
                        cn   => 'cn',
                        mail => 'mail',
                        uid  => 'uid',
                    }
                },
                casSrvMetaDataOptions => {
                    idp => {
                        casSrvMetaDataOptionsUrl => 'http://auth.idp.com/cas',
                        casSrvMetaDataOptionsGateway => 0,
                    }
                },
                casSrvMetaDataOptionsProxiedServices => {
                    idp => {
                        test => 'http://test.sp.com/',
                    }
                },
            },
        }
    );
}
