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

my $maintests = 21;
my $debug     = 'error';

SKIP: {
    eval "use Lasso";
    if ($@) {
        skip 'Lasso not found', $maintests;
    }

    # Initialization
    my ( $issuer, $sp );
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
    ok(
        $res->[2]->[0] =~
          m%<form id="lformDemo" action="#" method="post" class="login Demo">%s,
        'Found Demo choice'
    ) or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ m#<form[^>]+class="login SAML".*?</form>#s,
        'Found SAML choice' )
      or print STDERR Dumper( $res->[2]->[0] );
    $res->[2]->[0] = $&;
    my ( $host, $url, $query ) = expectForm( $res, undef, undef, 'test' );

    # Post SAML choice
    ok(
        $res = $sp->_post(
            '/'    => IO::String->new($query),
            accept => 'text/html',
            length => length($query),
        ),
        'Post SAML choice'
    );
    ( $host, $url, $query ) = expectForm( $res, undef, undef, 'confirm', );

    # IDP must be sorted
    my @idp = map /val="http:\/\/(.+?)\/saml\/metadata">/g, $res->[2]->[0];
    ok( $idp[0] eq 'auth.idp2.com', '1st = idp2' )
      or print STDERR Dumper( \@idp );
    ok( $idp[1] eq 'auth.idp2_z.com', '2nd = idp2_z' )
      or print STDERR Dumper( \@idp );
    ok( $idp[2] eq 'auth.idp3.com', '3rd = idp3' )
      or print STDERR Dumper( \@idp );
    ok( $idp[3] eq 'auth.idp.com', '4th = idp' )
      or print STDERR Dumper( \@idp );

    ok(
        $res->[2]->[0] =~
m%<img src="http://auth.sp.com/static/common/icons/sfa_manager.png" class="mr-2" alt="IDP2" title="My_tooltip" />%,
        'Found IDP icon, tooltip and title tags'
    ) or print STDERR Dumper( $res->[2]->[0] );
    ok( $res->[2]->[0] =~ /idp_Test_DisplayName/, 'Found IDP display name' )
      or print STDERR Dumper( $res->[2]->[0] );

    my $spPdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    # Choose SAML issuer
    $query .= '&idp=http%3A%2F%2Fauth.idp.com%2Fsaml%2Fmetadata';
    ok(
        $res = $sp->_post(
            '/'    => IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            cookie => "$spPdata",
        ),
        'Post SAML choice'
    );
    $spPdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );
    ( $host, $url, $query ) =
      expectAutoPost( $res, 'auth.idp.com', '/saml/singleSignOn',
        'SAMLRequest' );

    # Push SAML request to IdP
    switch ('issuer');
    ok(
        $res = $issuer->_post(
            $url,
            IO::String->new($query),
            accept => 'text/html',
            length => length($query)
        ),
        'Post SAML request to IdP'
    );
    expectOK($res);
    my $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    # Try to authenticate to IdP
    $query = "user=french&password=french&$query";
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
    my $idpId = expectCookie($res);
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
            cookie => "$spPdata",
        ),
        'Post SAML response to SP'
    );

    # Verify authentication on SP
    expectRedirection( $res, 'http://auth.sp.com' );
    my $spId = expectCookie($res);

    ok( $res = $sp->_get( '/', cookie => "lemonldap=$spId" ), 'Get / on SP' );
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
    ( $host, $url, $query ) =
      expectAutoPost( $res, 'auth.idp.com', '/saml/singleLogout',
        'SAMLRequest' );

    # Push SAML logout request to IdP
    switch ('issuer');
    ok(
        $res = $issuer->_post(
            $url,
            IO::String->new($query),
            accept => 'text/html',
            cookie => "lemonldap=$idpId",
            length => length($query)
        ),
        'Post SAML logout request to IdP'
    );
    ( $host, $url, $query ) =
      expectAutoPost( $res, 'auth.sp.com', '/saml/proxySingleLogoutReturn',
        'SAMLResponse' );

    my $removedCookie = expectCookie($res);
    is( $removedCookie, 0, "SSO cookie removed" );

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
            '/', cookie => "lemonldap=$spId"
        ),
        'Test if user is reject on SP'
    );
    expectReject($res);

}

count($maintests);
clean_sessions();
done_testing( count() );

sub sp {
    return LLNG::Manager::Test->new( {
            ini => {
                domain         => 'sp.com',
                portal         => 'http://auth.sp.com',
                logLevel       => $debug,
                authentication => 'Choice',
                userDB         => 'Same',

                authChoiceParam   => 'test',
                authChoiceModules => {
                    demo => 'Demo;Demo;Demo',
                    saml => 'SAML;SAML;Null',
                },
                samlIDPMetaDataExportedAttributes => {
                    idp => {
                        mail => "0;mail;;",
                        uid  => "1;uid",
                        cn   => "0;cn"
                    },
                    idp2 => {
                        mail => "0;mail;;",
                        uid  => "1;uid",
                        cn   => "0;cn"
                    },
                    idp3 => {
                        mail => "0;mail;;",
                        uid  => "1;uid",
                        cn   => "0;cn"
                    },
                    idp2_z => {
                        mail => "0;mail;;",
                        uid  => "1;uid",
                        cn   => "0;cn"
                    },
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
                        samlIDPMetaDataOptionsSortNumber               => 2,
                        samlIDPMetaDataOptionsDisplayName              =>
                          'idp_Test_DisplayName',

                    },
                    idp2 => {
                        samlIDPMetaDataOptionsEncryptionMode => 'none',
                        samlIDPMetaDataOptionsSSOBinding     => 'post',
                        samlIDPMetaDataOptionsSLOBinding     => 'post',
                        samlIDPMetaDataOptionsSignSSOMessage => 1,
                        samlIDPMetaDataOptionsSignSLOMessage => 1,
                        samlIDPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlIDPMetaDataOptionsCheckSLOMessageSignature => 1,
                        samlIDPMetaDataOptionsForceUTF8                => 1,
                        samlIDPMetaDataOptionsIcon => 'icons/sfa_manager.png',
                        samlIDPMetaDataOptionsTooltip => 'My_tooltip'
                    },
                    idp3 => {
                        samlIDPMetaDataOptionsEncryptionMode => 'none',
                        samlIDPMetaDataOptionsSSOBinding     => 'post',
                        samlIDPMetaDataOptionsSLOBinding     => 'post',
                        samlIDPMetaDataOptionsSignSSOMessage => 1,
                        samlIDPMetaDataOptionsSignSLOMessage => 1,
                        samlIDPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlIDPMetaDataOptionsCheckSLOMessageSignature => 1,
                        samlIDPMetaDataOptionsForceUTF8                => 1,
                        samlIDPMetaDataOptionsSortNumber               => 1,
                        samlIDPMetaDataOptionsDisplayName => 'Test_Sort',
                    },
                    idp2_z => {
                        samlIDPMetaDataOptionsEncryptionMode => 'none',
                        samlIDPMetaDataOptionsSSOBinding     => 'post',
                        samlIDPMetaDataOptionsSLOBinding     => 'post',
                        samlIDPMetaDataOptionsSignSSOMessage => 1,
                        samlIDPMetaDataOptionsSignSLOMessage => 1,
                        samlIDPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlIDPMetaDataOptionsCheckSLOMessageSignature => 1,
                        samlIDPMetaDataOptionsForceUTF8                => 1
                    },
                },
                samlIDPMetaDataExportedAttributes => {
                    idp => {
                        "uid" => "0;uid;;",
                        "cn"  => "1;cn;;",
                    },
                    idp2 => {
                        "uid" => "0;uid;;",
                        "cn"  => "1;cn;;",
                    },
                    idp3 => {
                        "uid" => "0;uid;;",
                        "cn"  => "1;cn;;",
                    },
                    idp2_z => {
                        "uid" => "0;uid;;",
                        "cn"  => "1;cn;;",
                    },
                },
                samlIDPMetaDataXML => {
                    idp => {
                        samlIDPMetaDataXML =>
                          samlIDPMetaDataXML( 'idp', 'HTTP-POST' )
                    },
                    idp2 => {
                        samlIDPMetaDataXML =>
                          samlIDPMetaDataXML( 'idp2', 'HTTP-POST' )
                    },
                    idp3 => {
                        samlIDPMetaDataXML =>
                          samlIDPMetaDataXML( 'idp3', 'HTTP-POST' )
                    },
                    idp2_z => {
                        samlIDPMetaDataXML =>
                          samlIDPMetaDataXML( 'idp2_z', 'HTTP-POST' )
                    },
                },
                samlOrganizationDisplayName => "SP",
                samlOrganizationName        => "SP",
                samlOrganizationURL         => "http://www.sp.com",
                samlServicePublicKeySig     => saml_key_sp_public_sig,
                samlServicePrivateKeyEnc    => saml_key_sp_private_enc,
                samlServicePrivateKeySig    => saml_key_sp_private_sig,
                samlServicePublicKeyEnc     => saml_key_sp_public_enc,
                samlSPSSODescriptorAuthnRequestsSigned => 1,
            }
        }
    );
}

sub issuer {
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

