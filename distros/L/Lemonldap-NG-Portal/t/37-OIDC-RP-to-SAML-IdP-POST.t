use lib 'inc';
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
    require 't/saml-lib.pm';
}

my $maintests = 16;
my $debug     = 'error';
my ( $idp, $sp, $rp, $res );

LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        ok( $req->uri =~ m#http://auth.(rp|sp).com(.*)#, ' REST request' );
        my $host = $1;
        my $url  = $2;
        my ( $res, $client );
        count(1);
        if ( $host eq 'sp' ) {
            pass("  Request from RP to OP(sp),     endpoint $url");
            $client = $sp;
        }
        elsif ( $host eq 'rp' ) {
            pass('  Request from OP to RP(proxy)');
            $client = $rp;
        }
        else {
            fail('  Aborting REST request (external)');
            return HTTP::Response->new(500);
        }
        if ( $req->method =~ /^post$/i ) {
            my $s = $req->content;
            ok(
                $res = $client->_post(
                    $url, IO::String->new($s),
                    length => length($s),
                    type   => $req->header('Content-Type'),
                ),
                '  Execute request'
            );
        }
        else {
            ok(
                $res = $client->_get(
                    $url,
                    custom => {
                        HTTP_AUTHORIZATION => $req->header('Authorization'),
                    }
                ),
                '  Execute request'
            );
        }
        ok( $res->[0] == 200, '  Response is 200' );
        ok( getHeader( $res, 'Content-Type' ) =~ m#^application/json#,
            '  Content is JSON' )
          or explain( $res->[1], 'Content-Type => application/json' );
        count(4);
        return $res;
    }
);

SKIP: {
    eval "use Lasso";
    if ($@) {
        skip 'Lasso not found', $maintests;
    }

    # Initialization
    $idp = register( 'idp', \&idp );

    $sp = register( 'sp', \&sp );

    ok(
        $res = $sp->_get('/oauth2/jwks'),
        'Get JWKS,     endpoint /oauth2/jwks'
    );
    expectOK($res);
    my $jwks = $res->[2]->[0];

    ok(
        $res = $sp->_get('/.well-known/openid-configuration'),
        'Get metadata, endpoint /.well-known/openid-configuration'
    );
    expectOK($res);
    my $metadata = $res->[2]->[0];

    $rp = register( 'rp', sub { rp( $jwks, $metadata ) } );

    # Query RP for auth
    ok( $res = $rp->_get( '/', accept => 'text/html' ), 'Unauth SP request' );
    my ( $url, $query ) =
      expectRedirection( $res,
        qr#http://auth.sp.com(/oauth2/authorize)\?(.*)$# );

    # Push request to Proxy
    switch ('sp');
    ok(
        $res = $sp->_get(
            $url,
            query  => $query,
            accept => 'text/html',
        ),
        "Push request to OP,         endpoint $url"
    );
    my $spPdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );
    my ( $host, $tmp );
    ( $host, $url, $query ) =
      expectAutoPost( $res, 'auth.idp.com', '/saml/singleSignOn',
        'SAMLRequest' );

    # Post SAML request to IdP
    switch ('idp');
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

    # Post SAML response
    switch ('sp');
    ok(
        $res = $sp->_post(
            $url, IO::String->new($query),
            length => length($query),
            accept => 'text/html',
            cookie => "$spPdata",
        ),
        'POST SAML response'
    );
    my $spId = expectCookie($res);
    ( $url, $query ) = expectRedirection( $res,
        qr#http://auth.sp.com/*(/oauth2[^\?]*)(?:\?(.*))?$# );

    # Follow internal redirection
    ok(
        $res = $sp->_get(
            $url,
            query  => $query,
            accept => 'text/html',
            cookie => "lemonldap=$spId;$spPdata"
        ),
        'Follow internal redirection from SAML-SP to OIDC-OP'
    );

    $spPdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );
    ( $host, $tmp, $query ) =
      expectForm( $res, undef, qr#^/oauth2/authorize#, 'confirm' );
    ok(
        $res = $sp->_get(
            '/oauth2/authorize',
            query  => $query,
            accept => 'text/html',
            cookie => "lemonldap=$spId;$spPdata"
        ),
        'Confirm OIDC sharing'
    );
    ($query) = expectRedirection( $res, qr#http://auth.rp.com/*\?(.*)$# );

    # Follow redirection to RP
    switch ('rp');
    ok( $res = $rp->_get( '/', query => $query, accept => 'text/html' ),
        'Follow redirection to RP' );
    my $rpId = expectCookie($res);

    # Logout initiated by RP
    ok(
        $res = $rp->_get(
            '/',
            query  => 'logout',
            cookie => "lemonldap=$rpId",
            accept => 'text/html'
        ),
        'Query RP for logout'
    );
    ( $url, $query ) = expectRedirection( $res,
        qr#http://auth.sp.com(/oauth2/logout)\?(post_logout_redirect_uri=.+)$#
    );

    # Push logout request to proxy
    switch ('sp');
    ok(
        $res = $sp->_get(
            $url,
            query  => $query,
            cookie => "lemonldap=$spId",
            accept => 'text/html'
        ),
        "Push logout request to OP/SP,  endpoint $url"
    );
    ( $host, $tmp, $query ) = expectForm( $res, '#', undef, 'confirm' );
    ok(
        $res = $sp->_post(
            $url, IO::String->new($query),
            length => length($query),
            accept => 'text/html',
            cookie => "lemonldap=$spId",
        ),
        "Confirm logout,                endpoint $url"
    );
    ( $host, $url, $query ) =
      expectForm( $res, 'auth.idp.com', '/saml/singleLogout', 'SAMLRequest' );

    # Push logout to SAML IdP
    switch ('idp');
    ok(
        $res = $idp->_post(
            $url, IO::String->new($query),
            length => length($query),
            cookie => "lemonldap=$idpId",
            accept => 'text/html',
        ),
        'Push logout to SAML IdP'
    );
    ( $host, $url, $query ) =
      expectForm( $res, 'auth.sp.com', '/saml/proxySingleLogoutReturn' );

    my $removedCookie = expectCookie($res);
    is( $removedCookie, 0, "SSO cookie removed" );

    # Push logout to SAML SP
    switch ('sp');
    ok(
        $res = $sp->_post(
            $url, IO::String->new($query),
            length => length($query),
            cookie => "lemonldap=$spId",
            accept => 'text/html',
        ),
        'Push logout to SAML IdP'
    );

    #print STDERR Dumper($res);
}

count($maintests);
clean_sessions();
done_testing( count() );

sub idp {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel               => $debug,
                domain                 => 'idp.com',
                portal                 => 'http://auth.idp.com',
                authentication         => 'Demo',
                userDB                 => 'Same',
                issuerDBSAMLActivation => 1,
                samlSPMetaDataOptions  => {
                    'sp.com' => {
                        samlSPMetaDataOptionsEncryptionMode           => 'none',
                        samlSPMetaDataOptionsSignSSOMessage           => 1,
                        samlSPMetaDataOptionsSignSLOMessage           => 1,
                        samlSPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlSPMetaDataOptionsCheckSLOMessageSignature => 1,
                    }
                },
                samlSPMetaDataExportedAttributes => {
                    'sp.com' => {
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
                    "sp.com" => {
                        samlSPMetaDataXML =>
                          samlSPMetaDataXML( 'sp', 'HTTP-POST' )
                    },
                },
            }
        }
    );
}

sub sp {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                        => $debug,
                domain                          => 'sp.com',
                portal                          => 'http://auth.sp.com',
                authentication                  => 'SAML',
                userDB                          => 'Same',
                issuerDBSAMLActivation          => 0,
                issuerDBOpenIDConnectActivation => 1,
                oidcRPMetaDataExportedVars      => {
                    rp => {
                        email       => "mail",
                        family_name => "cn",
                        name        => "cn"
                    }
                },
                oidcRPMetaDataOptionsExtraClaims => {
                    rp => {
                        email => 'email',
                    },
                },
                oidcServiceAllowHybridFlow            => 1,
                oidcServiceAllowImplicitFlow          => 1,
                oidcServiceAllowAuthorizationCodeFlow => 1,
                oidcRPMetaDataOptions                 => {
                    rp => {
                        oidcRPMetaDataOptionsDisplayName       => "RP",
                        oidcRPMetaDataOptionsIDTokenExpiration => 3600,
                        oidcRPMetaDataOptionsClientID          => "rpid",
                        oidcRPMetaDataOptionsIDTokenSignAlg    => "HS512",
                        oidcRPMetaDataOptionsBypassConsent     => 0,
                        oidcRPMetaDataOptionsClientSecret      => "rpsecret",
                        oidcRPMetaDataOptionsUserIDAttr        => "",
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600
                    }
                },
                oidcOPMetaDataOptions           => {},
                oidcOPMetaDataJSON              => {},
                oidcOPMetaDataJWKS              => {},
                oidcServiceMetaDataAuthnContext => {
                    'loa-4' => 4,
                    'loa-1' => 1,
                    'loa-5' => 5,
                    'loa-2' => 2,
                    'loa-3' => 3
                },
                oidcServicePrivateKeySig          => oidc_key_op_private_sig,
                oidcServicePublicKeySig           => oidc_cert_op_public_sig,
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
                samlOrganizationURL         => "http://www.sp.com",
                samlServicePublicKeySig     => saml_key_sp_public_sig,
                samlServicePrivateKeyEnc    => saml_key_sp_private_enc,
                samlServicePrivateKeySig    => saml_key_sp_private_sig,
                samlServicePublicKeyEnc     => saml_key_sp_public_enc,
                samlSPSSODescriptorAuthnRequestsSigned => 1,
            },
        }
    );
}

sub rp {
    my ( $jwks, $metadata ) = @_;
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                   => $debug,
                domain                     => 'rp.com',
                portal                     => 'http://auth.rp.com',
                authentication             => 'OpenIDConnect',
                userDB                     => 'Same',
                oidcOPMetaDataExportedVars => {
                    sp => {
                        cn   => "name",
                        uid  => "sub",
                        sn   => "family_name",
                        mail => "email"
                    }
                },
                oidcOPMetaDataOptions => {
                    sp => {
                        oidcOPMetaDataOptionsJWKSTimeout  => 0,
                        oidcOPMetaDataOptionsClientSecret => "rpsecret",
                        oidcOPMetaDataOptionsScope => "openid profile email",
                        oidcOPMetaDataOptionsStoreIDToken     => 0,
                        oidcOPMetaDataOptionsDisplay          => "",
                        oidcOPMetaDataOptionsClientID         => "rpid",
                        oidcOPMetaDataOptionsConfigurationURI =>
                          "https://auth.sp.com/.well-known/openid-configuration"
                    }
                },
                oidcOPMetaDataJWKS => {
                    sp => $jwks,
                },
                oidcOPMetaDataJSON => {
                    sp => $metadata,
                },
            }
        }
    );
}
