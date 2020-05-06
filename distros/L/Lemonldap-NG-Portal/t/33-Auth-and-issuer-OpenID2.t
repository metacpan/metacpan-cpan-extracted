use lib 'inc';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;

BEGIN {
    require 't/test-lib.pm';
}

my $maintests = 12;
my $debug     = 'error';
my ( $issuer, $sp, $res );

LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        ok( $req->uri =~ m#http://auth.idp.com(.*)#,
            ' Request from SP to IdP' );
        my $url = $1;
        my ($res);
        count(1);
        if ( $req->method =~ /^post$/i ) {
            my $s = $req->content;
            ok(
                $res = $issuer->_post(
                    $url, IO::String->new($s),
                    length => length($s),
                    type   => $req->header('Content-Type'),
                    accept => 'text/plain',
                ),
                '  Execute request'
            );
        }
        else {
            ok( $res = $issuer->_get( $url, accept => 'text/plain', ),
                '  Execute post request' );
        }
        expectOK($res);
        count(1);
        return $res;
    }
);

SKIP: {
    eval { require Net::OpenID::Consumer; require Net::OpenID::Server; };
    if ($@) {
        skip 'Net::OpenID::* notfound', $maintests;
    }

    $issuer = register( 'issuer', \&issuer );

    $sp = register( 'sp', \&sp );

    # Simple SP access
    my $res;
    ok(
        $res = $sp->_get(
            '/', accept => 'text/html',
        ),
        'Unauth SP request'
    );
    my ( $host, $url, $query ) = expectForm( $res, '#', undef );
    ok( $res->[2]->[0] =~ /name="openid_identifier"/,
        ' Ask for OpenID identity' );

    $query .=
      '&openid_identifier=http%3A%2F%2Fauth.idp.com%2Fopenidserver%2Ffrench';

    ok(
        $res = $sp->_post(
            '/', IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post OpenID identity'
    );
    my $uri;
    ( $uri, $query ) = expectRedirection( $res,
        qr#http://auth.idp.com(/openidserver/?)\?(openid.*)$# );

    # Follow redirection do IdP
    switch ('issuer');
    ok( $res = $issuer->_get( $uri, query => $query, accept => 'text/html' ),
        'Follow redirection to IdP' );
    expectOK($res);
    my ($tmp);
    my $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );
    ( $host, $tmp, $query ) = expectForm( $res, '#', undef );
    $query .= '&user=french&password=french';

    # Try to authenticate with an unauthorized user
    ok(
        $res = $issuer->_post(
            $uri, IO::String->new($query),
            length => length($query),
            accept => 'text/html',
            cookie => $pdata,
        ),
        'Try to authenticate'
    );
    ok( $res->[2]->[0] =~ /trmsg="91"/, 'Reject reason is 91' )
      or print STDERR Dumper( $res->[2]->[0] );
    count(1);

    # Simple SP access
    ok(
        $res = $sp->_get(
            '/', accept => 'text/html',
        ),
        'Unauth SP request'
    );
    ( $host, $url, $query ) = expectForm( $res, '#', undef );
    ok( $res->[2]->[0] =~ /name="openid_identifier"/,
        ' Ask for OpenID identity' );

    $query .=
      '&openid_identifier=http%3A%2F%2Fauth.idp.com%2Fopenidserver%2Fdwho';

    ok(
        $res = $sp->_post(
            '/', IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post OpenID identity'
    );
    ( $uri, $query ) = expectRedirection( $res,
        qr#http://auth.idp.com(/openidserver/?)\?(openid.*)$# );

    # Follow redirection do IdP
    switch ('issuer');
    ok( $res = $issuer->_get( $uri, query => $query, accept => 'text/html' ),
        'Follow redirection to IdP' );
    expectOK($res);
    $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );
    ( $host, $tmp, $query ) = expectForm( $res, '#', undef );
    $query .= '&user=dwho&password=dwho';

    # Try to authenticate with an authorized user
    ok(
        $res = $issuer->_post(
            $uri, IO::String->new($query),
            length => length($query),
            accept => 'text/html',
            cookie => $pdata,
        ),
        'Try to authenticate'
    );
    my $idpId = expectCookie($res);
    ( $host, $tmp, $query ) = expectForm( $res, '#', undef, 'confirm' );

    # Confirm
    ok(
        $res = $issuer->_post(
            $uri, IO::String->new($query),
            length => length($query),
            cookie => "lemonldap=$idpId",
            accept => 'text/html'
        ),
        'Confirm choice'
    );
    ($query) = expectRedirection( $res, qr#^http://auth.sp.com/?\?(.*)# );

    # Push redirection to SP
    switch ('sp');
    ok( $res = $sp->_get( '/', query => $query, accept => 'text/html' ),
        'Follow redirection to SP' );
    my $spId = expectCookie($res);
    expectRedirection( $res, qr#^http://auth.sp.com/?$# );

    #print STDERR Dumper($res);
}

count($maintests);
clean_sessions();
done_testing( count() );

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                 => $debug,
                domain                   => 'idp.com',
                portal                   => 'http://auth.idp.com',
                authentication           => 'Demo',
                userDB                   => 'Same',
                issuerDBOpenIDActivation => 1,
                issuerDBOpenIDRule       => '$uid eq "dwho"',
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
                authentication => 'OpenID',
                userDB         => 'Same',
                openIdSecret   => 'qwerty',
                exportedVars   => {
                    mail => 'email',
                },
                openIdIDPList => '0;',
            },
        }
    );
}
