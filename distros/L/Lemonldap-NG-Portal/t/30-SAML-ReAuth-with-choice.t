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
my $userdb = tempdb();

my $maintests = 10;
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
    eval { require DBI; require DBD::SQLite; };
    if ($@) {
        skip 'DBD::SQLite not found', $maintests;
    }
    my $dbh = DBI->connect("dbi:SQLite:dbname=$userdb");
    $dbh->do(
'CREATE TABLE users (user text,password text,name text,uid text,cn text,mail text)'
    );
    $dbh->do(
"INSERT INTO users VALUES ('dwho','dwho','Doctor who','dwho','Doctor who','dwho\@badwolf.org')"
    );

    # Initialization
    $issuer = register( 'issuer', \&issuer );
    $sp     = register( 'sp',     \&sp );

    # Simple authentication on IdP
    switch ('issuer');
    ok(
        $res = $issuer->_post(
            '/', IO::String->new('user=dwho&password=dwho&test=sql'),
            length => 32
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
    ( $host, $tmp, $query ) =
      expectForm( $res, '#', undef, 'upgrading', 'url' );
    $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );
    $query =~ s/user=[^&]*//;
    $query =~ s/^&//;
    $query =~ s/&$//;
    $query =~ s/&&/&/;
    $query .= '&user=dwho&password=dwho';
    ok(
        $res = $issuer->_post(
            '/renewsession',
            IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            cookie => "lemonldap=$idpId;$pdata",
        ),
        'Re auth'
    );
    $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );
    $tmp   = expectCookie($res);
    ok( $tmp ne $idpId, 'Get a new session' );
    $idpId = $tmp;
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
                authentication           => 'Choice',
                userDB                   => 'Same',
                portalForceAuthnInterval => 5,
                authChoiceParam          => 'test',
                authChoiceModules        => {
                    demo => 'Demo;Demo;Demo',
                    sql  => 'DBI;DBI;DBI',
                },
                dbiAuthChain           => "dbi:SQLite:dbname=$userdb",
                dbiAuthUser            => '',
                dbiAuthPassword        => '',
                dbiAuthTable           => 'users',
                dbiAuthLoginCol        => 'user',
                dbiAuthPasswordCol     => 'password',
                dbiAuthPasswordHash    => '',
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
