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
    eval "use GSSAPI";
}
my $userdb = tempdb();

my $maintests = 15;
my $debug     = 'error';
my ( $issuer, $sp, $res );

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

    eval "require GSSAPI";
    if ($@) {
        skip 'GSSAPI not found', $maintests;
    }

    # Initialization
    $issuer = register( 'issuer', \&issuer );
    $sp     = register( 'sp',     \&sp );

    # Simple authentication on IdP
    switch ('issuer');
    my $str = 'user=dwho&password=dwho';
    ok(
        $res = $issuer->_post(
            '/', IO::String->new($str), length => length($str),
        ),
        'Auth query'
    );
    expectOK($res);
    my $idpId = expectCookie($res);
    pass('Waiting timeout');
    Time::Fake->offset("+30s");

    # Simple SP access
    my $res;
    ok(
        $res = $sp->_get(
            '/', accept => 'text/html',
        ),
        'Unauth SP request'
    );
    my ( $host, $url, $query ) =
      expectAutoPost( $res, 'auth.idp.com', '/saml/singleSignOn',
        'SAMLRequest' );

    # Push SAML request to IdP
    switch ('issuer');
    ok(
        $res = $issuer->_post(
            $url,
            IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            cookie => "lemonldap=$idpId",
        ),
        'Post SAML request to IdP'
    );
    my $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );
    my $tmp;
    ( $host, $tmp, $query ) =
      expectForm( $res, undef, '/renewsession', 'confirm' );
    ok( $res->[2]->[0] =~ /trspan="askToRenew"/, 'Propose to renew session' );
    ok(
        $res = $issuer->_post(
            '/renewsession',
            IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            cookie => "lemonldap=$idpId;$pdata",
        ),
        'Ask to renew'
    );
    like( $res->[2]->[0], qr/script.*kerberos.js/, "Found Kerberos JS" );
    $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    ( $host, $tmp, $query ) =
      expectForm( $res, '#', undef, 'upgrading', 'url', 'kerberos',
        'ajax_auth_token' );

    # JS code should call /authkrb
    ok(
        $res = $issuer->_get(
            '/authkrb',
            accept => 'application/json',
            cookie => "lemonldap=$idpId;$pdata",
        ),
        'AJAX query'
    );
    $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );
    is( getHeader( $res, 'WWW-Authenticate' ), 'Negotiate' ),

      ok(
        $res = $issuer->_get(
            '/authkrb',
            accept => 'application/json',
            cookie => "lemonldap=$idpId;$pdata",
            custom => { HTTP_AUTHORIZATION => 'Negotiate c29tZXRoaW5n' },
        ),
        'AJAX query'
      );
    $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );
    my $json = expectJSON($res);
    ok( $json->{ajax_auth_token}, "User token was returned" );
    my $ajax_auth_token = $json->{ajax_auth_token};

    $query =~ s/ajax_auth_token=/ajax_auth_token=$ajax_auth_token/;

    ok(
        $res = $issuer->_post(
            '/renewsession', IO::String->new($query),
            length => length($query),
            accept => 'text/html',
            cookie => "lemonldap=$idpId;$pdata",
        ),
        'Post form'
    );

    # Update pdata
    $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );
    $tmp   = expectCookie($res);
    ok( $tmp ne $idpId, 'Get a new session' );
    $idpId = $tmp;

    $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );
    ( $url, $query ) = expectRedirection( $res,
        qr#http://auth.idp.com(/+saml/singleSignOn)(?:\?(.*))?# );
    ok(
        $res = $issuer->_get(
            $url,
            query  => $query,
            accept => 'text/html',
            cookie => "lemonldap=$idpId;$pdata",
        ),
        'Follow redirection'
    );
    ( $host, $url, $query ) =
      expectAutoPost( $res, 'auth.sp.com', '/saml/proxySingleSignOnPost',
        'SAMLResponse' );

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

    # Verify authentication on SP
    my $spId = expectCookie($res);
    expectRedirection( $res, 'http://auth.sp.com' );

    clean_sessions();
}

count($maintests);
done_testing( count() );

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel                 => $debug,
                domain                   => 'idp.com',
                portal                   => 'http://auth.idp.com',
                authentication           => 'Combination',
                userDB                   => 'Same',
                portalForceAuthnInterval => 5,

                combModules => {
                    'Demo'     => { 'for' => 0, 'type' => 'Demo' },
                    'Kerberos' => { 'for' => 1, 'type' => 'Kerberos' }
                },
                combination            => '[Kerberos, Demo] or [Demo, Demo]',
                krbKeytab              => '/etc/keytab',
                krbByJs                => 1,
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
                logLevel                          => $debug,
                domain                            => 'sp.com',
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
                        samlIDPMetaDataOptionsSSOBinding     => 'post',
                        samlIDPMetaDataOptionsSLOBinding     => 'post',
                        samlIDPMetaDataOptionsSignSSOMessage => 1,
                        samlIDPMetaDataOptionsSignSLOMessage => 1,
                        samlIDPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlIDPMetaDataOptionsCheckSLOMessageSignature => 1,
                        samlIDPMetaDataOptionsForceUTF8                => 1,
                        samlIDPMetaDataOptionsForceAuthn               => 1,
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

# Redefine GSSAPI method for test
no warnings 'redefine';

sub GSSAPI::Context::accept ($$$$$$$$$$) {
    my $a = \@_;
    $a->[4] = bless {}, 'LLNG::GSSR';
    return 1;
}

package LLNG::GSSR;

sub display {
    my $a = \@_;
    $a->[1] = 'dwho@EXAMPLE.COM';
    return 1;
}
