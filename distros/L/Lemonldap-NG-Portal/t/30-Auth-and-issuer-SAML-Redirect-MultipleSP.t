use lib 'inc';
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

my $maintests = 30;
my $debug     = 'error';
my ( $issuer, $sp, $sp2, $sp3, $res );

# Redefine LWP methods for tests
LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        fail('POST should not launch SOAP requests');
        count(1);
        return [ 500, [], [] ];
    }
);

SKIP: {
    eval "use Lasso";
    if ($@) {
        skip 'Lasso not found', $maintests;
    }

    # Initialization
    $issuer = register( 'issuer', \&issuer );

    $sp = register( 'sp', \&sp );

    $sp2 = register( 'sp2', \&sp2 );

    $sp3 = register( 'sp3', \&sp3 );

    # Simple SP access
    my $res;
    ok(
        $res = $sp->_get(
            '/',
            accept => 'text/html',
            query  => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw=='
        ),
        'Unauth SP request'
    );
    my ( $host, $url, $query );
    ( $url, $query ) = expectRedirection( $res,
        qr#^http://auth.idp.com(/saml/singleSignOn)\?(SAMLRequest=.+)# );

    # Push SAML request to IdP
    switch ('issuer');
    ok(
        $res = $issuer->_get(
            $url,
            query  => $query,
            accept => 'text/html',
        ),
        'Launch SAML request to IdP'
    );
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
    $query =
      join( '&', map { "$_=" . uri_escape( $fields{$_} ) } keys %fields );
    ok(
        $res = $issuer->_post(
            $url,
            IO::String->new($query),
            accept => 'text/html',
            cookie => $pdata,
            length => length($query),
        ),
        'Post authentication'
    );
    expectOK($res);
    my $idpId = expectCookie($res);
    ( $host, $url, $query ) =
      expectForm( $res, 'auth.sp.com', '/saml/proxySingleSignOnPost',
        'SAMLResponse', 'RelayState' );

    # Post SAML response to SP
    switch ('sp');
    ok(
        $res = $sp->_post(
            $url, IO::String->new($query),
            accept => 'text/html',
            length => length($query),
        ),
        'Post SAML response to SP'
    );
    my $spId = expectCookie($res);
    expectRedirection( $res, 'http://test1.example.com/' );

    ok( $res = $sp->_get( '/', cookie => "lemonldap=$spId" ), 'Get / on SP' );
    expectOK($res);
    expectAuthenticatedAs( $res, 'fa@badwolf.org@idp' );

    # Verify UTF-8
    ok( $res = $sp->_get("/sessions/global/$spId"), 'Get UTF-8' );
    expectOK($res);
    ok( $res = eval { JSON::from_json( $res->[2]->[0] ) }, ' GET JSON' )
      or print STDERR $@;
    ok( $res->{cn} eq 'Frédéric Accents', 'UTF-8 values' )
      or explain( $res, 'cn => Frédéric Accents' );

    # Simple SP2 access

    switch ('sp2');
    ok(
        $res = $sp2->_get(
            '/',
            accept => 'text/html',
            query  => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw=='
        ),
        'Unauth SP2 request'
    );

    ( $url, $query ) = expectRedirection( $res,
        qr#^http://auth.idp.com(/saml/singleSignOn)\?(SAMLRequest=.+)# );

    # Push SAML request to IdP
    switch ('issuer');
    ok(
        $res = $issuer->_get(
            $url,
            query  => $query,
            accept => 'text/html',
            cookie => "lemonldap=$idpId",
        ),
        'Launch SAML request to IdP'
    );
    ( $host, $url, $query ) =
      expectForm( $res, 'auth.sp2.com', '/saml/proxySingleSignOnPost',
        'SAMLResponse', 'RelayState' );

    # Post SAML response to SP2
    switch ('sp2');
    ok(
        $res = $sp2->_post(
            $url, IO::String->new($query),
            accept => 'text/html',
            length => length($query),
        ),
        'Post SAML response to SP2'
    );
    my $sp2Id = expectCookie($res);
    expectRedirection( $res, 'http://test1.example.com/' );

    ok( $res = $sp2->_get( '/', cookie => "lemonldap=$spId" ), 'Get / on SP2' );
    expectOK($res);
    expectAuthenticatedAs( $res, 'fa@badwolf.org@idp' );

    # Simple SP3 access
    switch ('sp3');
    ok(
        $res = $sp3->_get(
            '/',
            accept => 'text/html',
            query  => 'url=aHR0cDovL3Rlc3QxLmV4YW1wbGUuY29tLw=='
        ),
        'Unauth SP3 request'
    );

    ( $url, $query ) = expectRedirection( $res,
        qr#^http://auth.idp.com(/saml/singleSignOn)\?(SAMLRequest=.+)# );

    # Push SAML request to IdP
    switch ('issuer');
    ok(
        $res = $issuer->_get(
            $url,
            query  => $query,
            accept => 'text/html',
            cookie => "lemonldap=$idpId",
        ),
        'Launch SAML request to IdP'
    );
    ( $host, $url, $query ) =
      expectForm( $res, 'auth.sp3.com', '/saml/proxySingleSignOnPost',
        'SAMLResponse', 'RelayState' );

    # Post SAML response to SP3
    switch ('sp3');
    ok(
        $res = $sp3->_post(
            $url, IO::String->new($query),
            accept => 'text/html',
            length => length($query),
        ),
        'Post SAML response to SP3'
    );
    my $sp3Id = expectCookie($res);
    expectRedirection( $res, 'http://test1.example.com/' );

    ok( $res = $sp3->_get( '/', cookie => "lemonldap=$spId" ), 'Get / on SP3' );
    expectOK($res);
    expectAuthenticatedAs( $res, 'fa@badwolf.org@idp' );

    # Logout initiated by SP
    ok(
        $res = $sp->_get(
            '/',
            query  => 'logout',
            cookie => "lemonldap=$spId",
            accept => 'text/html'
        ),
        'Query SP for logout'
    );

    ( $url, $query ) = expectRedirection( $res,
        qr#^http://auth.idp.com(/saml/singleLogout)\?(SAMLRequest=.+)# );

    # Push SAML logout request to IdP
    switch ('issuer');
    ok(
        $res = $issuer->_get(
            $url,
            query  => $query,
            accept => 'text/html',
            cookie => "lemonldap=$idpId",
        ),
        'Launch SAML logout request to IdP'
    );

    my $removedCookie = expectCookie($res);
    is( $removedCookie, 0, "SSO cookie removed" );

    my $relaypage = $res;

    my %iframes = $res->[2]->[0] =~
      m%<iframe src="http://([^/]+)/saml/proxySingleLogout\?([^"]*)"%g;
    is( scalar keys %iframes, 2,
        "Got one iframe for both additional services" );

    # Logout from SP2
    # Load iframe
    my $iframe = $iframes{'auth.sp2.com'};
    switch ('sp2');
    ok(
        $res = $sp2->_get(
            '/saml/proxySingleLogout',
            query  => $iframe,
            cookie => "lemonldap=$sp2Id",
            accept => 'text/html',
        ),
        'Start logout from SP2'
    );

    ( $url, $query ) = expectRedirection( $res,
        qr#^http://auth.idp.com(/saml/singleLogoutReturn)\?(SAMLResponse=.+)# );

    # Get OK icon from IDP
    switch ('issuer');
    ok(
        $res = $issuer->_get(
            $url,
            query  => $query,
            accept => 'text/html',
        ),
        'get SAML response from IDP',
    );
    expectRedirection( $res, "http://auth.idp.com/static/common/icons/ok.png" );

    # Logout from SP3
    # Load iframe
    $iframe = $iframes{'auth.sp3.com'};
    switch ('sp3');
    ok(
        $res = $sp3->_get(
            '/saml/proxySingleLogout',
            query  => $iframe,
            cookie => "lemonldap=$sp3Id",
            accept => 'text/html',
        ),
        'Start logout from SP3'
    );

    ( $url, $query ) = expectRedirection( $res,
        qr#^http://auth.idp.com(/saml/singleLogoutReturn)\?(SAMLResponse=.+)# );

    # Get OK icon from IDP
    switch ('issuer');
    ok(
        $res = $issuer->_get(
            $url,
            query  => $query,
            accept => 'text/html',
        ),
        'get SAML response from IDP',
    );
    expectRedirection( $res, "http://auth.idp.com/static/common/icons/ok.png" );

    # Post global logout form
    ( $host, $url, $query ) =
      expectForm( $relaypage, 'auth.idp.com',
        '/saml/relaySingleLogoutTermination', 'relay' );

    ok(
        $res = $issuer->_post(
            $url,
            IO::String->new($query),
            accept => 'text/html',
            length => length($query),
        ),
        'Post final logout'
    );
    ( $url, $query ) = expectRedirection( $res,
qr#^http://auth.sp.com(/saml/proxySingleLogoutReturn)\?(SAMLResponse=.+)#
    );

    # Send SAML response to SP
    switch ('sp');
    ok(
        $res = $sp->_get(
            $url,
            query  => $query,
            accept => 'text/html',
        ),
        'Send SAML logout response to SP'
    );

    # Test if logout is done
    switch ('issuer');
    ok(
        $res = $issuer->_get(
            '/', cookie => "lemonldap=$idpId",
        ),
        'Test if user is reject on IdP'
    );
    expectReject($res);

    switch ('sp');
    ok(
        $res = $sp->_get(
            '/',
            accept => 'text/html',
            cookie => "lemonldap=$spId"
        ),
        'Test if user is reject on SP'
    );
    expectRedirection( $res,
        qr#^http://auth.idp.com(/saml/singleSignOn)\?(SAMLRequest=.+)# );

    switch ('sp2');
    ok(
        $res = $sp2->_get(
            '/',
            accept => 'text/html',
            cookie => "lemonldap=$sp2Id"
        ),
        'Test if user is reject on SP2'
    );
    expectRedirection( $res,
        qr#^http://auth.idp.com(/saml/singleSignOn)\?(SAMLRequest=.+)# );

    switch ('sp3');
    ok(
        $res = $sp3->_get(
            '/',
            accept => 'text/html',
            cookie => "lemonldap=$sp3Id"
        ),
        'Test if user is reject on SP3'
    );
    expectRedirection( $res,
        qr#^http://auth.idp.com(/saml/singleSignOn)\?(SAMLRequest=.+)# );
}

count($maintests);
clean_sessions();
done_testing( count() );

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel               => $debug,
                domain                 => 'idp.com',
                pdataDomain            => 'idp.com',
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
                    },
                    'sp2.com' => {
                        samlSPMetaDataOptionsEncryptionMode           => 'none',
                        samlSPMetaDataOptionsSignSSOMessage           => 1,
                        samlSPMetaDataOptionsSignSLOMessage           => 1,
                        samlSPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlSPMetaDataOptionsCheckSLOMessageSignature => 1,
                    },
                    'sp3.com' => {
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
                    },
                    'sp2.com' => {
                        cn =>
'1;cn;urn:oasis:names:tc:SAML:2.0:attrname-format:basic',
                        uid =>
'1;uid;urn:oasis:names:tc:SAML:2.0:attrname-format:basic',
                    },
                    'sp3.com' => {
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
                          samlSPMetaDataXML( 'sp', 'HTTP-Redirect' )
                    },
                    "sp2.com" => {
                        samlSPMetaDataXML =>
                          samlSPMetaDataXML( 'sp2', 'HTTP-Redirect' )
                    },
                    "sp3.com" => {
                        samlSPMetaDataXML =>
                          samlSPMetaDataXML( 'sp3', 'HTTP-Redirect' )
                    },
                },
            }
        }
    );
}

sub sp {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                          => $debug,
                domain                            => 'sp.com',
                pdataDomain                       => 'sp.com',
                portal                            => 'http://auth.sp.com',
                authentication                    => 'SAML',
                userDB                            => 'Same',
                issuerDBSAMLActivation            => 0,
                restSessionServer                 => 1,
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
                        samlIDPMetaDataOptionsSSOBinding     => 'redirect',
                        samlIDPMetaDataOptionsSLOBinding     => 'redirect',
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
                          samlIDPMetaDataXML( 'idp', 'HTTP-Redirect' )
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

sub sp2 {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                          => $debug,
                domain                            => 'sp2.com',
                portal                            => 'http://auth.sp2.com',
                authentication                    => 'SAML',
                userDB                            => 'Same',
                issuerDBSAMLActivation            => 0,
                restSessionServer                 => 1,
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
                        samlIDPMetaDataOptionsSSOBinding     => 'redirect',
                        samlIDPMetaDataOptionsSLOBinding     => 'redirect',
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
                          samlIDPMetaDataXML( 'idp', 'HTTP-Redirect' )
                    }
                },
                samlOrganizationDisplayName => "SP",
                samlOrganizationName        => "SP",
                samlOrganizationURL         => "http://www.sp2.com",
                samlServicePublicKeySig     => saml_key_sp_public_sig,
                samlServicePrivateKeyEnc    => saml_key_sp_private_enc,
                samlServicePrivateKeySig    => saml_key_sp_private_sig,
                samlServicePublicKeyEnc     => saml_key_sp_public_enc,
                samlSPSSODescriptorAuthnRequestsSigned => 1,
            },
        }
    );
}

sub sp3 {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                          => $debug,
                domain                            => 'sp3.com',
                portal                            => 'http://auth.sp3.com',
                authentication                    => 'SAML',
                userDB                            => 'Same',
                issuerDBSAMLActivation            => 0,
                restSessionServer                 => 1,
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
                        samlIDPMetaDataOptionsSSOBinding     => 'redirect',
                        samlIDPMetaDataOptionsSLOBinding     => 'redirect',
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
                          samlIDPMetaDataXML( 'idp', 'HTTP-Redirect' )
                    }
                },
                samlOrganizationDisplayName => "SP",
                samlOrganizationName        => "SP",
                samlOrganizationURL         => "http://www.sp3.com",
                samlServicePublicKeySig     => saml_key_sp_public_sig,
                samlServicePrivateKeyEnc    => saml_key_sp_private_enc,
                samlServicePrivateKeySig    => saml_key_sp_private_sig,
                samlServicePublicKeyEnc     => saml_key_sp_public_enc,
                samlSPSSODescriptorAuthnRequestsSigned => 1,
            },
        }
    );
}
