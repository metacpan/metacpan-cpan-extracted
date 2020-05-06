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

my $maintests = 20;
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

    # Initialization
    $issuer = register( 'issuer', \&issuer );
    $sp     = register( 'sp',     \&sp );

    # Simple SP access
    my $res;
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
    switch ('issuer');
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

    # Try to authenticate with an unauthorized user to IdP
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
    ok( $res->[2]->[0] =~ /trmsg="89"/, 'Reject reason is 89' )
      or print STDERR Dumper( $res->[2]->[0] );

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
            length => length($s)
        ),
        'Post SAML request to IdP'
    );
    expectOK($res);
    $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    # Try to authenticate with an authorized user to IdP
    $s = "user=davros&password=davros&$s";
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
    my $idpId = expectCookie($res);

    # Expect pdata to be cleared
    $pdata = expectCookie( $res, 'lemonldappdata' );
    ok( $pdata !~ 'issuerRequestsaml', 'SAML request cleared from pdata' );

    ( $host, $url, $s ) =
      expectAutoPost( $res, 'auth.sp.com', '/saml/proxySingleSignOnPost',
        'SAMLResponse' );

    # Post SAML response to SP
    switch ('sp');
    ok(
        $res = $sp->_post(
            $url, IO::String->new($s),
            accept => 'text/html',
            length => length($s),
        ),
        'Post SAML response to SP'
    );

    # Verify authentication on SP
    expectRedirection( $res, 'http://auth.sp.com' );
    my $spId = expectCookie($res);

    ok(
        $res =
          $sp->_get( '/', cookie => "lemonldap=$spId", accept => 'text/html' ),
        'Get / on SP'
    );
    count(1);
    expectOK($res);
    expectAuthenticatedAs( $res, 'davros@badguy.org@idp' );

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
    switch ('issuer');
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
    $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    # Try to authenticate with an authorized user to IdP
    $s = "user=french&password=french&$s";
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
    $idpId = expectCookie($res);

    # Expect pdata to be cleared
    $pdata = expectCookie( $res, 'lemonldappdata' );
    ok( $pdata !~ 'issuerRequestsaml', 'SAML request cleared from pdata' );

    ( $host, $url, $s ) =
      expectAutoPost( $res, 'auth.sp.com', '/saml/proxySingleSignOnPost',
        'SAMLResponse' );

    # Post SAML response to SP
    switch ('sp');
    ok(
        $res = $sp->_post(
            $url, IO::String->new($s),
            accept => 'text/html',
            length => length($s),
        ),
        'Post SAML response to SP'
    );

    # Verify authentication on SP
    expectRedirection( $res, 'http://auth.sp.com' );
    $spId = expectCookie($res);

    ok(
        $res =
          $sp->_get( '/', cookie => "lemonldap=$spId", accept => 'text/html' ),
        'Get / on SP'
    );
    count(1);
    expectOK($res);
    expectAuthenticatedAs( $res, 'fa@badwolf.org@idp' );

    # CheckUser form -> granted
    # ------------------------
    ok(
        $res = $sp->_get(
            '/checkuser',
            cookie => "lemonldap=$spId",
            accept => 'text/html'
        ),
        'CheckUser form',
    );
    my $query;
    ( $host, $url, $query ) =
      expectForm( $res, undef, '/checkuser', 'user', 'url' );
    ok( $res->[2]->[0] =~ m%<span trspan="checkUser">%,
        'Found trspan="checkUser"' )
      or explain( $res->[2]->[0], 'trspan="checkUser"' );
    ok( $res->[2]->[0] =~ m%<td scope="row">uid</td>%, 'Found attribute uid' )
      or explain( $res->[2]->[0], 'Attribute uid' );
    ok( $res->[2]->[0] =~ m%<td scope="row">french</td>%, 'Found value french' )
      or explain( $res->[2]->[0], 'Value french' );
    ok( $res->[2]->[0] =~ m%<td scope="row">_lassoSessionDump</td>%,
        'Found attribute _lassoSessionDump' )
      or explain( $res->[2]->[0], 'Attribute _lassoSessionDump' );
    ok(
        $res->[2]->[0] =~
          m%ProviderID="http://auth.idp.com/saml/metadata" AssertionID=%,
        'Found  ProviderID & AssertionID values'
    ) or explain( $res->[2]->[0], 'Provider & Assertion Ids' );
    count(6);

    # CheckUser request with an unknown user
    $query =~ s/user=fa%40badwolf.org%40idp/user=rtyler/;
    ok(
        $res = $sp->_post(
            '/checkuser',
            IO::String->new($query),
            cookie => "lemonldap=$spId",
            length => length($query),
            accept => 'text/html',
        ),
        'POST checkuser'
    );
    ok(
        $res->[2]->[0] =~
m%<div class="alert alert-warning alert"><div class="text-center"><span trspan="PE5"></span></div></div>%,
        ' PE5 found'
    ) or explain( $res->[2]->[0], 'PE5 - Unknown identity' );
    count(2);

    # CheckUser request with an already authenticated user
    $query =~ s/user=rtyler/user=davros/;
    ok(
        $res = $sp->_post(
            '/checkuser',
            IO::String->new($query),
            cookie => "lemonldap=$spId",
            length => length($query),
            accept => 'text/html',
        ),
        'POST checkuser'
    );

    ( $host, $url, $query ) =
      expectForm( $res, undef, '/checkuser', 'user', 'url' );
    ok( $res->[2]->[0] =~ m%<span trspan="checkUser">%,
        'Found trspan="checkUser"' )
      or explain( $res->[2]->[0], 'trspan="checkUser"' );
    ok( $res->[2]->[0] =~ m%<td scope="row">uid</td>%, 'Found attribute uid' )
      or explain( $res->[2]->[0], 'Attribute uid' );
    ok( $res->[2]->[0] =~ m%<td scope="row">mail</td>%, 'Found attribute mail' )
      or explain( $res->[2]->[0], 'Attribute mail' );
    ok( $res->[2]->[0] =~ m%<td scope="row">davros\@badguy.org</td>%,
        'Found value davros@badguy.org' )
      or explain( $res->[2]->[0], 'Value davros@badguy.org' );
    count(5);

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
    ( $host, $url, $s ) =
      expectAutoPost( $res, 'auth.idp.com', '/saml/singleLogout',
        'SAMLRequest' );

    # Push SAML logout request to IdP
    switch ('issuer');
    ok(
        $res = $issuer->_post(
            $url,
            IO::String->new($s),
            accept => 'text/html',
            cookie => "lemonldap=$idpId",
            length => length($s)
        ),
        'Post SAML logout request to IdP'
    );
    ( $host, $url, $s ) =
      expectAutoPost( $res, 'auth.sp.com', '/saml/proxySingleLogoutReturn',
        'SAMLResponse' );

    my $removedCookie = expectCookie($res);
    is( $removedCookie, 0, "SSO cookie removed" );

    # Post SAML response to SP
    switch ('sp');
    ok(
        $res = $sp->_post(
            $url, IO::String->new($s),
            accept => 'text/html',
            length => length($s),
        ),
        'Post SAML response to SP'
    );
    expectRedirection( $res, 'http://auth.sp.com' );

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
    expectOK($res);
    expectAutoPost( $res, 'auth.idp.com', '/saml/singleSignOn', 'SAMLRequest' );
}

count($maintests);
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
                issuerDBSAMLActivation => 1,
                issuerDBSAMLRule       => '$uid =~ /(?:french|davros)/',
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
                checkUser                         => 1,
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
