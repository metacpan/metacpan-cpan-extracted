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

my $maintests = 13;
my $debug     = 'error';
my ( $issuer, $proxy, $sp, $res );

# Redefine LWP methods for tests
LWP::Protocol::PSGI->register(
    sub {
        my $req = Plack::Request->new(@_);
        ok( $req->uri =~ m#http://auth.(idp|proxy).com([^\?]*)(?:\?(.*))?$#,
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
    eval "use Lasso;use XML::Simple";
    if ($@) {
        skip 'Lasso or XML::Simple not found', $maintests;
    }

    # Initialization
    # Build CAS server
    $issuer = register( 'issuer', \&issuer );
    $proxy  = register( 'proxy',  \&proxy );
    $sp     = register( 'sp',     \&sp );

    # Simple SP access
    my $res;
    ok(
        $res = $sp->_get(
            '/', accept => 'text/html',
        ),
        'Unauth SP request'
    );

    my ( $host, $url, $query ) =
      expectAutoPost( $res, 'auth.proxy.com', '/saml/singleSignOn',
        'SAMLRequest' );

    # Push SAML request to IdP
    switch ('proxy');
    ok(
        $res = $proxy->_post(
            $url,
            IO::String->new($query),
            accept => 'text/html',
            length => length($query)
        ),
        'Post SAML request to IdP'
    );
    my $proxyPdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );
    ok( $res->[2]->[0] =~ s#^.*(<form [^>]*CAS.*?</form>).*$#$1#s,
        'Found SAML choice' );
    my $tmp;
    ( $host, $tmp, $query ) = expectForm($res);
    $query .= '&test=cas';
    ok(
        $res = $proxy->_post(
            $url,
            IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            cookie => $proxyPdata,
        ),
        'Select "CAS"'
    );
    $proxyPdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    ok( expectCookie( $res, 'llngcasserver' ) eq 'idp',
        'Get CAS server cookie' );
    ($query) = expectRedirection( $res,
qr'^http://auth.idp.com/cas/login\?(service=http%3A%2F%2Fauth.proxy.com%2F.*)$'
    );

    # Follow redirection to CAS server
    switch ('issuer');
    ok(
        $res = $issuer->_get(
            '/cas/login',
            query  => $query,
            accept => 'text/html'
        ),
        'Query CAS server'
    );
    my $idpPdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );
    ( $host, $url, $query ) = expectForm($res);
    $query =~ s/&?user=//;

    # Try to authenticate to IdP
    $query .= "&user=french&password=french";
    ok(
        $res = $issuer->_post(
            '/cas/login',
            IO::String->new($query),
            accept => 'text/html',
            length => length($query),
            cookie => $idpPdata,
        ),
        'Post authentication'
    );
    my $idpId = expectCookie($res);

    ( $url, $query ) = expectRedirection( $res,
        qr#^http://auth.proxy.com(/saml/singleSignOn)\?(.*ticket=.*)$# );

    # Push CAS response to proxy
    switch ('proxy');
    ok(
        $res = $proxy->_get(
            $url,
            query  => $query,
            accept => 'text/html',
            length => length($query),
            cookie => "llngcasserver=idp;$proxyPdata",
        ),
        'Push CAS response to proxy'
    );

    my $proxyId = expectCookie($res);
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
    expectRedirection( $res, 'http://auth.sp.com' );
    my $spId = expectCookie($res);

    ok( $res = $sp->_get( '/', cookie => "lemonldap=$spId" ), 'Get / on SP' );
    expectOK($res);
    expectAuthenticatedAs( $res, 'fa@badwolf.org@proxy' );

    # Verify UTF-8
    ok( $res = $sp->_get("/sessions/global/$spId"), 'Get UTF-8' );
    expectOK($res);
    ok( $res = eval { JSON::from_json( $res->[2]->[0] ) }, ' GET JSON' )
      or print STDERR $@;
    ok( $res->{cn} eq 'Frédéric Accents', 'UTF-8 values' )
      or explain( $res, 'cn => Frédéric Accents' );

}

count($maintests);
clean_sessions();
done_testing( count() );

sub issuer {
    return LLNG::Manager::Test->new( {
            ini => {
                skipRenewConfirmation => 1,
                logLevel              => $debug,
                domain                => 'idp.com',
                portal                => 'http://auth.idp.com',
                authentication        => 'Demo',
                userDB                => 'Same',
                issuerDBCASActivation => 1,
                casAttr               => 'uid',
                casAttributes => { cn => 'cn', uid => 'uid', mail => 'mail', },
                casAccessControlPolicy   => 'none',
                multiValuesSeparator     => ';',
                portalForceAuthnInterval => -1,
            }
        }
    );
}

sub proxy {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel          => $debug,
                domain            => 'proxy.com',
                portal            => 'http://auth.proxy.com',
                authentication    => 'Choice',
                userDB            => 'Same',
                authChoiceParam   => 'test',
                authChoiceModules => {
                    cas  => 'CAS;CAS;Null',
                    demo => 'Demo;Demo;Null',
                },
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
                issuerDBCASActivation  => 0,
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
                samlOrganizationURL         => "http://www.proxy.com/",
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
                    proxy => {
                        mail => "0;mail;;",
                        uid  => "1;uid",
                        cn   => "0;cn"
                    }
                },
                samlIDPMetaDataOptions => {
                    proxy => {
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
                    proxy => {
                        "uid" => "0;uid;;",
                        "cn"  => "1;cn;;",
                    },
                },
                samlIDPMetaDataXML => {
                    proxy => {
                        samlIDPMetaDataXML =>
                          samlIDPMetaDataXML( 'proxy', 'HTTP-POST' )
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
