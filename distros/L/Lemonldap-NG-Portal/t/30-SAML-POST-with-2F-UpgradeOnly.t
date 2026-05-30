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
    require 't/smtp.pm';
}

my $debug = 'error';
my ( $issuer, $sp, $res );

# Redefine LWP methods for tests
LWP::Protocol::PSGI->register( denyLwpRequests() );

SKIP: {
    eval "use Lasso";
    if ($@) {
        skip 'Lasso not found';
    }

    # Initialization
    $issuer = register( 'issuer', \&issuer );
    $sp     = register( 'sp',     \&sp );

    ## FIRST CASE##
    # * Login directly to SP, 2FA is asked

    # Simple SP access
    ok(
        $res = $sp->_get(
            '/', accept => 'text/html',
        ),
        'Unauth SP request'
    );
    expectOK($res);
    my ( $host, $url, $s ) =
      expectAutoPost( $res, 'auth.idp.com', '/saml/singleSignOn',
        'SAMLRequest' );

    # Push SAML request to IdP
    ok(
        $res = $issuer->_post(
            $url,
            IO::String->new($s),
            accept => 'text/html',
            length => length($s)
        ),
        'Post SAML request to IdP'
    );
    expectOK($res);
    my $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    # Try to authenticate with an authorized user to IdP
    $s = "user=dwho&password=dwho&$s";
    ok(
        $res = $issuer->_post(
            $url,
            IO::String->new($s),
            accept => 'text/html',
            cookie => $pdata,
            length => length($s),
        ),
        'Post authentication'
    );

    ( $host, $url, $s ) =
      expectForm( $res, undef, '/mail2fcheck?skin=bootstrap', 'token', 'code' );

    ok(
        $res->[2]->[0] =~
qr%<input name="code" value="" type="text" class="form-control" id="extcode" trplaceholder="code"%,
        'Found EXTCODE input'
    ) or print STDERR Dumper( $res->[2]->[0] );

    ok( mail() =~ m%<b>(\d{4})</b>%, 'Found 2F code in mail' )
      or print STDERR Dumper( mail() );

    my $code = $1;

    $s =~ s/code=/code=${code}/;
    ok(
        $res = $issuer->_post(
            '/mail2fcheck',
            IO::String->new($s),
            length => length($s),
            cookie => $pdata,
            accept => 'text/html',
        ),
        'Post code'
    );

    my $idpId = expectCookie($res);
    $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );
    expectRedirection( $res, 'http://auth.idp.com/saml' );

    ok(
        $res = $issuer->_get(
            '/saml',
            cookie => "lemonldap=$idpId; $pdata",
            accept => 'text/html',
        ),
        'Follow redirection'
    );

    # Expect pdata to be cleared
    $pdata = expectCookie( $res, 'lemonldappdata' );
    ok( $pdata !~ 'issuerRequestsaml', 'SAML request cleared from pdata' );

    ( $host, $url, $s ) =
      expectAutoPost( $res, 'auth.sp.com', '/saml/proxySingleSignOnPost',
        'SAMLResponse' );

    # Post SAML response to SP
    ok(
        $res = $sp->_post(
            $url, IO::String->new($s),
            accept => 'text/html',
            length => length($s),
        ),
        'Post SAML response to SP'
    );

    # Verify authentication on SP
    expectRedirection( $res, 'http://auth.sp.com/' );
    my $spId = expectCookie($res);

    ok( $res = $sp->_get( '/', cookie => "lemonldap=$spId" ), 'Get / on SP' );
    expectOK($res);
    expectAuthenticatedAs( $res, 'dwho@badwolf.org@idp' );

    ## SECOND CASE##
    # * Login to IDP without 2FA
    # * Login to SP, 2FA is asked to upgrade session

    # Login to IDP
    $s = "user=dwho&password=dwho";
    ok(
        $res = $issuer->_post(
            "/",
            IO::String->new($s),
            accept => 'text/html',
            length => length($s),
        ),
        'Post authentication'
    );

    # No 2FA asked
    $idpId = expectCookie($res);

    # Simple SP access
    ok(
        $res = $sp->_get(
            '/', accept => 'text/html',
        ),
        'Unauth SP request'
    );
    expectOK($res);
    ( $host, $url, $s ) =
      expectAutoPost( $res, 'auth.idp.com', '/saml/singleSignOn',
        'SAMLRequest' );

    # Push SAML request to IdP
    ok(
        $res = $issuer->_post(
            $url,
            IO::String->new($s),
            accept => 'text/html',
            cookie => "lemonldap=$idpId",
            length => length($s)
        ),
        'Post SAML request to IdP'
    );
    expectOK($res);
    $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    # IDP should offer to upgrade the session
    ( $host, $url, $s ) =
      expectForm( $res, undef, '/upgradesession', 'confirm', 'url' );

    ok(
        $res = $issuer->_post(
            '/upgradesession',
            IO::String->new($s),
            length => length($s),
            accept => 'text/html',
            cookie => "lemonldap=$idpId; $pdata",
        ),
        'Post code'
    );

    $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    ( $host, $url, $s ) =
      expectForm( $res, undef, '/mail2fcheck?skin=bootstrap', 'token', 'code' );

    ok(
        $res->[2]->[0] =~
qr%<input name="code" value="" type="text" class="form-control" id="extcode" trplaceholder="code"%,
        'Found EXTCODE input'
    ) or print STDERR Dumper( $res->[2]->[0] );

    ok( mail() =~ m%<b>(\d{4})</b>%, 'Found 2F code in mail' )
      or print STDERR Dumper( mail() );

    $code = $1;

    $s =~ s/code=/code=${code}/;
    ok(
        $res = $issuer->_post(
            '/mail2fcheck',
            IO::String->new($s),
            length => length($s),
            cookie => "lemonldap=$idpId; $pdata",
            accept => 'text/html',
        ),
        'Post code'
    );

    $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );
    expectRedirection( $res, 'http://auth.idp.com/saml/singleSignOn' );

    ok(
        $res = $issuer->_get(
            '/saml',
            cookie => "lemonldap=$idpId; $pdata",
            accept => 'text/html',
        ),
        'Follow redirection'
    );

    # Expect pdata to be cleared
    $pdata = expectCookie( $res, 'lemonldappdata' );
    ok( $pdata !~ 'issuerRequestsaml', 'SAML request cleared from pdata' );

    ( $host, $url, $s ) =
      expectAutoPost( $res, 'auth.sp.com', '/saml/proxySingleSignOnPost',
        'SAMLResponse' );

    # Post SAML response to SP
    ok(
        $res = $sp->_post(
            $url, IO::String->new($s),
            accept => 'text/html',
            length => length($s),
        ),
        'Post SAML response to SP'
    );

    # Verify authentication on SP
    expectRedirection( $res, 'http://auth.sp.com/' );
    $spId = expectCookie($res);

    ok( $res = $sp->_get( '/', cookie => "lemonldap=$spId" ), 'Get / on SP' );
    expectOK($res);
    expectAuthenticatedAs( $res, 'dwho@badwolf.org@idp' );

    ## THIRD CASE##
    # * Login to IDP without 2FA
    # * Login to SP, 2FA has to be registered to upgrade session

    # Login to IDP
    $s = "user=msmith&password=msmith";
    ok(
        $res = $issuer->_post(
            "/",
            IO::String->new($s),
            accept => 'text/html',
            length => length($s),
        ),
        'Post authentication'
    );

    # No 2FA asked
    $idpId = expectCookie($res);
    is( getSession($idpId)->data->{authenticationLevel},
        1, "Expected authnlevel" );

    # Simple SP access
    ok(
        $res = $sp->_get(
            '/', accept => 'text/html',
        ),
        'Unauth SP request'
    );
    expectOK($res);
    ( $host, $url, $s ) =
      expectAutoPost( $res, 'auth.idp.com', '/saml/singleSignOn',
        'SAMLRequest' );

    # Push SAML request to IdP
    ok(
        $res = $issuer->_post(
            $url,
            IO::String->new($s),
            accept => 'text/html',
            cookie => "lemonldap=$idpId",
            length => length($s)
        ),
        'Post SAML request to IdP'
    );
    expectOK($res);
    $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    # IDP should offer to upgrade the session
    ( $host, $url, $s ) =
      expectForm( $res, undef, '/upgradesession', 'confirm', 'url' );

    ok(
        $res = $issuer->_post(
            '/upgradesession',
            IO::String->new($s),
            length => length($s),
            accept => 'text/html',
            cookie => "lemonldap=$idpId; $pdata",
        ),
        'Post code'
    );

    $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    expectRedirection( $res, 'http://auth.idp.com/2fregisters' );
    ok(
        $res = $issuer->_get(
            '/2fregisters',
            accept => 'text/html',
            cookie => "lemonldap=$idpId; $pdata",
        ),
        'Move to 2FA list'
    );
    like( $res->[2]->[0],
        qr/trspan="2fRegRequired"/, "Found registration required prompt" );
    like( $res->[2]->[0],
        qr(href="/2fregisters/totp"), "Found link to TOTP registration" );

    ok(
        $res = $issuer->_get(
            '/2fregisters/totp',
            accept => 'text/html',
            cookie => "lemonldap=$idpId; $pdata",
        ),
        'On TOTP registration page'
    );

    ok( $res->[2]->[0] =~ /totpregistration\.(?:min\.)?js/, 'Found TOTP js' );

    # JS query
    ok(
        $res = $issuer->_post(
            '/2fregisters/totp/getkey',
            IO::String->new(''),
            cookie => "lemonldap=$idpId; $pdata",
            length => 0,
            custom => {
                HTTP_X_CSRF_CHECK => 1,
            },
        ),
        'Get new key'
    );
    eval { $res = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), 'Content is JSON' )
      or explain( $res->[2]->[0], 'JSON content' );
    my ( $key, $token );
    ok( $key   = $res->{secret}, 'Found secret' ) or print STDERR Dumper($res);
    ok( $token = $res->{token},  'Found token' )  or print STDERR Dumper($res);
    is( $res->{user}, 'msmith', 'Found user' );
    $key = Convert::Base32::decode_base32($key);

    # Post code
    ok( $code = getTotp($key), 'Code' );
    ok( $code =~ /^\d{6}$/,    'Code contains 6 digits' );
    ok(
        $res = $issuer->_post(
            '/2fregisters/totp/verify',
            {
                code     => $code,
                token    => $token,
                TOTPName => "mytotp",
            },
            cookie => "lemonldap=$idpId; $pdata",
            custom => {
                HTTP_X_CSRF_CHECK => 1,
            },
        ),
        'Post code'
    );
    eval { $res = JSON::from_json( $res->[2]->[0] ) };
    ok( not($@), 'Content is JSON' )
      or explain( $res->[2]->[0], 'JSON content' );
    ok( $res->{result} == 1, 'TOTP is registered' );

    # JS sends us to ?continue=1
    ok(
        $res = $issuer->_get(
            '/2fregisters',
            query  => "continue=1",
            accept => 'text/html',
            cookie => "lemonldap=$idpId; $pdata",
        ),
        'Continue registration'
    );

    $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );
    expectRedirection( $res, 'http://auth.idp.com/saml/singleSignOn' );

    ok(
        $res = $issuer->_get(
            '/saml',
            cookie => "lemonldap=$idpId; $pdata",
            accept => 'text/html',
        ),
        'Follow redirection'
    );

    # Expect pdata to be cleared
    $pdata = expectCookie( $res, 'lemonldappdata' );
    ok( $pdata !~ 'issuerRequestsaml', 'SAML request cleared from pdata' );

    ( $host, $url, $s ) =
      expectAutoPost( $res, 'auth.sp.com', '/saml/proxySingleSignOnPost',
        'SAMLResponse' );

    # Post SAML response to SP
    ok(
        $res = $sp->_post(
            $url, IO::String->new($s),
            accept => 'text/html',
            length => length($s),
        ),
        'Post SAML response to SP'
    );

    # Verify authentication on SP
    expectRedirection( $res, 'http://auth.sp.com/' );
    $spId = expectCookie($res);

    ok( $res = $sp->_get( '/', cookie => "lemonldap=$spId" ), 'Get / on SP' );
    expectOK($res);
    expectAuthenticatedAs( $res, 'msmith@badwolf.org@idp' );
}

clean_sessions();
done_testing();

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel               => $debug,
                domain                 => 'idp.com',
                portal                 => 'http://auth.idp.com/',
                authentication         => 'Demo',
                userDB                 => 'Same',
                sfOnlyUpgrade          => 1,
                issuerDBSAMLActivation => 1,
                totp2fActivation       => '$uid eq "msmith" and has2f("TOTP")',
                totp2fSelfRegistration => 1,
                totp2fAuthnLevel       => 5,
                sfRequired             => 1,
                mail2fActivation       => '$uid eq "dwho"',
                mail2fCodeRegex        => '\d{4}',
                mail2fAuthnLevel       => 5,
                samlSPMetaDataOptions  => {
                    'sp.com' => {
                        samlSPMetaDataOptionsEncryptionMode           => 'none',
                        samlSPMetaDataOptionsSignSSOMessage           => 1,
                        samlSPMetaDataOptionsSignSLOMessage           => 1,
                        samlSPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlSPMetaDataOptionsCheckSLOMessageSignature => 1,
                        samlSPMetaDataOptionsAuthnLevel               => 4,
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
                portal                            => 'http://auth.sp.com/',
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
