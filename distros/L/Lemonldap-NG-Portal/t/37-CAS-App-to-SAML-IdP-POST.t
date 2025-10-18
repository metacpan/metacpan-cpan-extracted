use warnings;
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;

BEGIN {
    require 't/test-lib.pm';
    require 't/saml-lib.pm';
}

my $debug = 'error';
my ( $idp, $proxy, $app, $res );

# Redefine LWP methods for tests
LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        ok( $req->uri =~ m#http://auth.(app|proxy).com([^\?]*)(?:\?(.*))?$#,
            'SOAP request' );
        my $host  = $1;
        my $url   = $2;
        my $query = $3;
        my $res;
        my $client = ( $host eq 'app' ? $app : $proxy );
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

sub test {
    my ($wayf) = @_;

    reset_tmpdir;

    # Initialization
    $idp   = register( 'idp',   sub { idp() } );
    $proxy = register( 'proxy', sub { proxy($wayf) } );
    $app   = register( 'app',   sub { app() } );

    # Query RP for auth
    ok( $res = $app->_get( '/', accept => 'text/html' ),
        'Unauth CAS app request' );
    ok( expectCookie( $res, 'llngcasserver' ) eq 'proxy',
        'Get CAS server cookie' );
    my ( $url, $query ) =
      expectRedirection( $res, qr#http://auth.proxy.com(/cas/login)\?(.*)$# );

    # Push request to Proxy
    ok(
        $res = $proxy->_get(
            $url,
            query  => $query,
            accept => 'text/html',
        ),
        "Push request to proxy"
    );
    my $proxyPdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    if ($wayf) {
        ( $url, $query ) =
          expectRedirection( $res, qr#^http://discovery.example.com/# );

        # Return from WAYF
        ok(
            $res = $proxy->_get(
                "/",
                query => "idp="
                  . uri_escape("http://auth.idp.com/saml/metadata"),
                accept => 'text/html',
                cookie => $proxyPdata,
            ),
            "Return from WAYF"
        );

        $proxyPdata =
          'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );
    }

    my ( $host, $tmp );
    ( $host, $url, $query ) =
      expectAutoPost( $res, 'auth.idp.com', '/saml/singleSignOn',
        'SAMLRequest' );

    # Post SAML request to IdP
    ok(
        $res = $idp->_post(
            $url,
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Launch SAML request to IdP'
    );
    my $idpPdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    # Try to authenticate to IdP
    my $body = $res->[2]->[0];
    $body =~ s/^.*?<form.*?>//s;
    $body =~ s#</form>.*$##s;
    my %fields =
      ( $body =~ /<input type="hidden".+?name="(.+?)".+?value="(.*?)"/sg );
    $fields{user} = $fields{password} = 'french';
    use URI::Escape;
    $query =
      join( '&', map { "$_=" . uri_escape( $fields{$_} ) } keys %fields );
    ok(
        $res = $idp->_post(
            $url,
            IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            cookie => $idpPdata,
        ),
        'Post authentication'
    );

    ( $host, $url, $query ) = expectAutoPost($res);
    $query =~ s/\+/%2B/g;
    my $idpId = expectCookie($res);

    # Expect pdata to be cleared
    $idpPdata = expectCookie( $res, 'lemonldappdata' );
    ok( $idpPdata !~ 'issuerRequestsaml', 'SAML request cleared from pdata' );

    # Post SAML response
    ok(
        $res = $proxy->_post(
            $url, IO::String->new($query),
            length => length($query),
            accept => 'text/html',
            cookie => "$proxyPdata",
        ),
        'POST SAML response'
    );
    my $spId = expectCookie($res);
    ($url) = expectRedirection( $res, qr#http://auth.proxy.com([^?]*)# );
    ok(
        $res = $proxy->_get(
            $url,
            accept => 'text/html',
            cookie => "lemonldap=$spId;$proxyPdata",
        ),
        'Follow internal redirection'
    );

    ($query) =
      expectRedirection( $res, qr#^http://auth.app.com/\?(ticket.*)$# );

    # Follow redirection to App
    ok( $res = $app->_get( '/', query => $query, accept => 'text/html' ),
        'Follow redirection to RP' );
    my $appId = expectCookie($res);

    # Initiate logout on proxy
    ok(
        $res = $proxy->_get(
            '/cas/logout',
            query  => { service => "http://auth.app.com/?logout=1" },
            cookie => "lemonldap=$spId",
            accept => 'text/html'
        ),
        'Initiate logout from proxy'
    );

    # Propagate SAML request to IDP
    ( $host, $url, $query ) =
      expectAutoPost( $res, 'auth.idp.com', '/saml/singleLogout',
        'SAMLRequest', 'RelayState' );
    ok(
        $res = $idp->_post(
            $url,
            IO::String->new($query),
            cookie => "lemonldap=$idpId",
            length => length($query),
            accept => 'text/html',
        ),
        'Send SAML logout request'
    );

    # Return SAML response to proxy
    ( $host, $url, $query ) =
      expectAutoPost( $res, 'auth.proxy.com', '/saml/proxySingleLogoutReturn',
        'SAMLResponse', 'RelayState' );
    ok(
        $res = $proxy->_post(
            $url,
            IO::String->new($query),
            cookie => "lemonldap=$spId",
            length => length($query),
            accept => 'text/html',
        ),
        'Receive SAML logout response'
    );

    # Expect redirection to initial service
    expectRedirection( $res, qr#http://auth.app.com/\?logout=1# );

    is_deeply( getSession($spId)->data,  {}, "SP session was removed" );
    is_deeply( getSession($idpId)->data, {}, "IDP session was removed" );

}

SKIP: {
    eval "use Lasso";
    if ($@) {
        skip 'Lasso not found';
    }
    subtest 'Test without WAYF' => sub {
        test(0);
    };
    subtest 'Test with WAYF' => sub {
        test(1);
    };
}

clean_sessions();
done_testing();

sub idp {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel               => $debug,
                domain                 => 'idp.com',
                portal                 => 'http://auth.idp.com/',
                authentication         => 'Demo',
                userDB                 => 'Same',
                issuerDBSAMLActivation => 1,
                samlSPMetaDataOptions  => {
                    'proxy.com' => {
                        samlSPMetaDataOptionsEncryptionMode           => 'none',
                        samlSPMetaDataOptionsSignSSOMessage           => 1,
                        samlSPMetaDataOptionsSignSLOMessage           => 1,
                        samlSPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlSPMetaDataOptionsCheckSLOMessageSignature => 1,
                    }
                },
                samlSPMetaDataExportedAttributes => {
                    'proxy.com' => {
                        cn =>
'1;cn;urn:oasis:names:tc:SAML:2.0:attrname-format:basic',
                        uid =>
'1;uid;urn:oasis:names:tc:SAML:2.0:attrname-format:basic',
                    }
                },
                samlOrganizationDisplayName => "IDP",
                samlOrganizationName        => "IDP",
                samlOrganizationURL         => "http://www.idp.com/",
                samlServicePrivateKeyEnc    => saml_key_idp_private_enc,
                samlServicePrivateKeySig    => saml_key_idp_private_sig,
                samlServicePublicKeyEnc     => saml_key_idp_public_enc,
                samlServicePublicKeySig     => saml_key_idp_public_sig,
                samlSPMetaDataXML           => {
                    "proxy.com" => {
                        samlSPMetaDataXML =>
                          samlSPMetaDataXML( 'proxy', 'HTTP-POST' )
                    },
                },
            }
        }
    );
}

sub proxy {
    my ($wayf) = @_;
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel              => $debug,
                domain                => 'proxy.com',
                portal                => 'http://auth.proxy.com/',
                authentication        => 'SAML',
                userDB                => 'Same',
                issuerDBCASActivation => 1,
                casAttr               => 'uid',
                casAttributes => { cn => 'cn', uid => 'uid', mail => 'mail', },
                casAccessControlPolicy => 'none',
                multiValuesSeparator   => ';',
                (
                    $wayf
                    ? (
                        samlDiscoveryProtocolURL =>
                          'http://discovery.example.com/',
                        samlDiscoveryProtocolActivation => 1,
                      )
                    : ()
                ),
                samlIDPMetaDataExportedAttributes => {
                    idp => {
                        mail => "0;mail;;",
                        uid  => "1;uid",
                        cn   => "0;cn"
                    }
                },
                samlIDPMetaDataOptions => {
                    idp => {
                        samlIDPMetaDataOptionsEncryptionMode => 'none',
                        samlIDPMetaDataOptionsSSOBinding     => 'post',
                        samlIDPMetaDataOptionsSLOBinding     => 'post',
                        samlIDPMetaDataOptionsSignSSOMessage => 1,
                        samlIDPMetaDataOptionsSignSLOMessage => 1,
                        samlIDPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlIDPMetaDataOptionsCheckSLOMessageSignature => 1,
                        samlIDPMetaDataOptionsForceUTF8                => 1,
                    }
                },
                samlIDPMetaDataExportedAttributes => {
                    idp => {
                        "uid" => "0;uid;;",
                        "cn"  => "1;cn;;",
                    },
                },
                samlIDPMetaDataXML => {
                    idp => {
                        samlIDPMetaDataXML =>
                          samlIDPMetaDataXML( 'idp', 'HTTP-POST' )
                    }
                },
                samlOrganizationDisplayName => "SP",
                samlOrganizationName        => "SP",
                samlOrganizationURL         => "http://www.proxy.com",
                samlServicePublicKeySig     => saml_key_sp_public_sig,
                samlServicePrivateKeyEnc    => saml_key_sp_private_enc,
                samlServicePrivateKeySig    => saml_key_sp_private_sig,
                samlServicePublicKeyEnc     => saml_key_sp_public_enc,
                samlSPSSODescriptorAuthnRequestsSigned => 1,
            },
        }
    );
}

sub app {
    my ( $jwks, $metadata ) = @_;
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                   => $debug,
                domain                     => 'app.com',
                portal                     => 'http://auth.app.com/',
                authentication             => 'CAS',
                userDB                     => 'Same',
                multiValuesSeparator       => ';',
                casSrvMetaDataExportedVars => {
                    proxy => {
                        cn   => 'cn',
                        mail => 'mail',
                        uid  => 'uid',
                    }
                },
                casSrvMetaDataOptions => {
                    proxy => {
                        casSrvMetaDataOptionsUrl => 'http://auth.proxy.com/cas',
                        casSrvMetaDataOptionsGateway => 0,
                    }
                },
            }
        }
    );
}
