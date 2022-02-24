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
my $userdb = tempdb();

my $maintests = 20;
my $debug     = 'error';
my ( $issuer, $sp, $res );

eval { require XML::Simple };
plan skip_all => "Missing dependencies: $@" if ($@);

# Redefine LWP methods for tests
LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        ok( $req->uri =~ m#http://auth.((?:id|s)p).com([^\?]*)(?:\?(.*))?$#,
            'SOAP request' );
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
                "Execute POST request to $url"
            );
        }
        else {
            ok(
                $res = $client->_get(
                    $url,
                    type  => 'application/xml',
                    query => $query,
                ),
                "Execute request to $url"
            );
        }
        expectOK($res);
        ok( getHeader( $res, 'Content-Type' ) =~ m#xml#, 'Content is XML' )
          or explain( $res->[1], 'Content-Type => application/xml' );
        count(3);
        return $res;
    }
);

SKIP: {
    eval { require DBI; require DBD::SQLite; };
    if ($@) {
        skip 'DBD::SQLite not found', $maintests;
    }

    # Build SQL DB
    my $dbh = DBI->connect("dbi:SQLite:dbname=$userdb");
    $dbh->do(
'CREATE TABLE users (user text,password text,name text,uid text,cn text,mail text)'
    );
    $dbh->do(
"INSERT INTO users VALUES ('dwho','dwho','Doctor who','dwho','Doctor who','dwho\@badwolf.org')"
    );

    # Build CAS server
    $issuer = register( 'issuer', \&issuer );

    # Build CAS app
    $sp = register( 'sp', \&sp );

    # Simple SP access
    # Connect to CAS app
    ok(
        $res = $sp->_get(
            '/', accept => 'text/html',
        ),
        'Unauth SP request'
    );
    ok( expectCookie( $res, 'llngcasserver' ) eq 'idp',
        'Get CAS server cookie' );
    expectRedirection( $res,
        'http://auth.idp.com/cas/login?service=http%3A%2F%2Fauth.sp.com%2F' );

    # Follow redirection to CAS server
    switch ('issuer');
    ok(
        $res = $issuer->_get(
            '/cas/login',
            query  => 'service=http://auth.sp.com/',
            accept => 'text/html'
        ),
        'Query CAS server'
    );
    expectOK($res);
    my $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    # Try to authenticate to IdP
    my $body = $res->[2]->[0];
    $body =~ s/^.*?<form.*?>//s;
    $body =~ s#</form>.*$##s;
    my %fields =
      ( $body =~ /<input type="hidden".+?name="(.+?)".+?value="(.*?)"/sg );
    $fields{user} = $fields{password} = 'dwho';
    $fields{test} = 'sql';
    use URI::Escape;
    my $s = join( '&', map { "$_=" . uri_escape( $fields{$_} ) } keys %fields );
    ok(
        $res = $issuer->_post(
            '/cas/login',
            IO::String->new($s),
            accept => 'text/html',
            cookie => $pdata,
            length => length($s),
        ),
        'Post authentication'
    );
    my ($query) =
      expectRedirection( $res, qr#^http://auth.sp.com/\?(ticket=[^&]+)$# );
    my $idpId = expectCookie($res);

    # Expect pdata to be cleared
    $pdata = expectCookie( $res, 'lemonldappdata' );
    ok( $pdata !~ 'issuerRequestsaml', 'SAML request cleared from pdata' );

    # Back to SP
    switch ('sp');

    # Follow redirection to CAS app
    ok(
        $res = $sp->_get(
            '/',
            query  => $query,
            accept => 'text/html',
            cookie => 'llngcasserver=idp',
        ),
        'Query SP with ticket'
    );
    my $spId = expectCookie($res);

    # Test authentication
    ok(
        $res = $sp->_get( '/', cookie => "lemonldap=$spId,llngcasserver=idp" ),
        'Get / on SP'
    );
    expectOK($res);
    expectAuthenticatedAs( $res, 'dwho' );

    # Renew test
    ok(
        $res = $sp->_get(
            '/', accept => 'text/html',
        ),
        'Unauth SP request (2)'
    );
    ok( expectCookie( $res, 'llngcasserver' ) eq 'idp',
        'Get CAS server cookie' );
    expectRedirection( $res,
        'http://auth.idp.com/cas/login?service=http%3A%2F%2Fauth.sp.com%2F' );

    # Follow redirection to CAS server with "renew" set to "true"
    switch ('issuer');
    ok(
        $res = $issuer->_get(
            '/cas/login',
            query  => 'service=http://auth.sp.com/&renew=true',
            cookie => "lemonldap=$idpId",
            accept => 'text/html'
        ),
        'Query CAS server (2)'
    );
    $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    # Verify that confirmation is asked
    my ( $host, $url );
    ( $host, $url, $query ) =
      expectForm( $res, undef, '/renewsession', 'confirm', 'url' );

    # Verify that autopost is required (skipRenewConfirmation is set to 1)
    ok( $res->[2]->[0] =~ /autoRenew\.(?:min\.)js/m, ' Get autorenew.js' );
    ok(
        $res = $issuer->_post(
            '/renewsession', IO::String->new($query),
            length => length($query),
            cookie => "lemonldap=$idpId; $pdata",
            accept => 'text/html'
        ),
        'Post confirm'
    );
    ( $host, $url, $query ) = expectForm( $res, undef, undef, 'upgrading' );
    $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    # Try to authenticate
    $query =~ s/&?password=//;
    $query .= '&password=dwho';
    ok(
        $res = $issuer->_post(
            '/renewsession', IO::String->new($query),
            length => length($query),
            cookie => "lemonldap=$idpId; $pdata",
            accept => 'text/html'
        ),
        'Post credentials'
    );
    expectRedirection( $res, 'http://auth.idp.com/cas/login' );
    $idpId = expectCookie($res);
    ok(
        $res = $issuer->_get(
            '/cas/login',
            cookie => "lemonldap=$idpId; $pdata",
            accept => 'text/html'
        ),
        'Follow redirection'
    );
    ($query) =
      expectRedirection( $res, qr#http://auth.sp.com/?\?(ticket=.*)$# );

    # Follow redirection to CAS app
    switch ('sp');
    ok( $res = $sp->_get( '/', query => $query ), 'Follow redirection' );

    expectCookie($res);

    # Logout initiated by SP

    # Try to logout from CAS app
    ok(
        $res = $sp->_get(
            '/',
            query  => 'logout',
            cookie => "lemonldap=$spId,llngcasserver=idp",
            accept => 'text/html'
        ),
        'Query SP for logout'
    );
    expectOK($res);
    ok(
        $res->[2]->[0] =~
          m#iframe src="http://auth.idp.com(/cas/logout)\?(.+?)"#s,
        'Found iframe'
    );

    # Query IdP with iframe src
    $url   = $1;
    $query = $2;
    expectCspChildOK( $res, "auth.idp.com" );

    # Get iframe from CAS server
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
    expectRedirection( $res, 'http://auth.sp.com/?logout' );

    # Verify that user has been disconnected
    ok( $res = $issuer->_get( '/', cookie => "lemonldap=$idpId" ),
        'Query CAS server' );
    expectReject($res);

    switch ('sp');
    ok(
        $res = $sp->_get(
            '/',
            accept => 'text/html',
            cookie => "lemonldap=$idpId,llngcasserver=idp"
        ),
        'Query CAS app'
    );
    expectRedirection( $res,
        'http://auth.idp.com/cas/login?service=http%3A%2F%2Fauth.sp.com%2F' );

    clean_sessions();
}

count($maintests);
done_testing( count() );

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                skipRenewConfirmation => 1,
                logLevel              => $debug,
                domain                => 'idp.com',
                portal                => 'http://auth.idp.com',
                authentication        => 'Choice',
                userDB                => 'Same',
                authChoiceParam       => 'test',
                authChoiceModules     => {
                    demo => 'Demo;Demo;Demo',
                    sql  => 'DBI;DBI;DBI',
                },
                dbiAuthChain             => "dbi:SQLite:dbname=$userdb",
                dbiAuthUser              => '',
                dbiAuthPassword          => '',
                dbiAuthTable             => 'users',
                dbiAuthLoginCol          => 'user',
                dbiAuthPasswordCol       => 'password',
                dbiAuthPasswordHash      => '',
                issuerDBCASActivation    => 1,
                casAttr                  => 'uid',
                casAttributes            => { cn => 'cn', uid => 'uid', },
                casAccessControlPolicy   => 'none',
                multiValuesSeparator     => ';',
                portalForceAuthnInterval => -1,
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
            },
        }
    );
}
