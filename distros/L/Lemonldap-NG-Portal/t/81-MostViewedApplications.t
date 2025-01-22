use warnings;
use Test::More;
use strict;
use IO::String;

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
    require 't/saml-lib.pm';
}

my $maintests = 30;
my $debug     = "error";

my ( $portal, $psession );
$portal = portal();

#
# OIDC applications
#

oidc_auth( $portal, 'oidc_1' );
oidc_auth( $portal, 'oidc_1' );
oidc_auth( $portal, 'oidc_2' );

reload_session();
ok( ref( $psession->{data}->{_appHistory} ) eq 'HASH',
    'Session contains history hash' );

ok( $psession->{data}->{_appHistory}->{"oidc:app1"}->{access_count} == 2,
    'OIDC App 1 has been accessed twice' );

ok( $psession->{data}->{_appHistory}->{"oidc:app2"}->{access_count} == 1,
    'OIDC App 2 has been accessed once' );

ok( keys( %{ $psession->{data}->{_appHistory} } ) == 2,
    'History contains two entries' );

#
# CAS applications
#

cas_auth( $portal, "cas_1" );
cas_auth( $portal, "cas_1" );
cas_auth( $portal, "cas_2" );

reload_session();
ok( ref( $psession->{data}->{_appHistory} ) eq 'HASH',
    'Session contains history hash' );

ok( $psession->{data}->{_appHistory}->{"cas:app1"}->{access_count} == 2,
    'CAS App 1 has been accessed twice' );

ok( $psession->{data}->{_appHistory}->{"cas:app2"}->{access_count} == 1,
    'CAS App 2 has been accessed once' );

ok( keys( %{ $psession->{data}->{_appHistory} } ) == 4,
    'History contains four entries' );

#
# SAML applications
#

SKIP: {
    eval "use Lasso";
    if ($@) {
        skip 'Lasso not found', 6;
    }

    $portal = portal_with_lasso();

    saml_auth($portal);
    reload_session();

    ok( keys( %{ $psession->{data}->{_appHistory} } ) == 5,
        'History contains five entries' );

    ok( $psession->{data}->{_appHistory}->{"saml:app1"}->{access_count} == 1,
        'SAML App 1 has been accessed once' );
}

clean_sessions();

done_testing($maintests);

sub reload_session {
    $psession = getPSession('dwho');
}

sub oidc_auth {
    my ( $portal, $rp ) = @_;

    my $id = login( $portal, 'dwho' );

    my $params = {
        response_type => "code",

        # Include a weird scope name, to make sure they work (#2168)
        scope        => "openid profile",
        client_id    => $rp,
        state        => "af0ifjsldkj",
        redirect_uri => "http://$rp.example.org"
    };
    my $query = buildForm($params);
    my $res   = $portal->_get(
        "/oauth2/authorize",
        query  => "$query",
        accept => 'text/html',
        cookie => "lemonldap=$id",
    );
    return $res;
}

sub saml_auth {
    my ($portal) = @_;

    my $id = login( $portal, 'dwho' );

    my $login = eval { getAuthnRequest('HTTP-POST'); };

    my $url  = URI->new( $login->msg_url );
    my $url2 = URI->new;
    $url2->query_form( {
            SAMLRequest => $login->msg_body,
            RelayState  => $login->msg_relayState
        }
    );
    my $res = $portal->_post(
        $url->path,
        $url2->query,
        cookie => "lemonldap=$id",
        accept => 'text/html',
    );

    return $res;

    sub getAuthnRequest {
        my ($method) = @_;

        my $saml = Lemonldap::NG::Portal::Lib::SAML->new();

        my $server = Lasso::Server::new_from_buffers(
            samlProxyMetaDataXML( "proxy", $method ),
            saml_key_proxy_private_sig(),
            undef, undef
        );
        $server->add_provider_from_buffer( 2,
            samlIDPMetaDataXML( "idp", $method ) );

        my $login = Lasso::Login->new($server);
        $method = $saml->getHttpMethod($method);
        $login->init_authn_request( "http://auth.idp.com/saml/metadata",
            $method );
        $login->msg_relayState("http://saml_1.example.org");
        $login->build_authn_request_msg();
        return $login;
    }
}

sub cas_auth {
    my ( $portal, $app ) = @_;

    # Query IdP
    my $res = $portal->_get(
        '/cas/login',
        query  => "service=http://$app.example.org/",
        accept => 'text/html'
    );
    my $pdata = 'lemonldappdata=' . expectCookie( $res, 'lemonldappdata' );

    # Authenticate to IdP
    my $body = $res->[2]->[0];
    $body =~ s/^.*?<form.*?>//s;
    $body =~ s#</form>.*$##s;
    my %fields =
      ( $body =~ /<input type="hidden".+?name="(.+?)".+?value="(.*?)"/sg );
    $fields{user} = $fields{password} = 'dwho';
    use URI::Escape;
    my $s = join( '&', map { "$_=" . uri_escape( $fields{$_} ) } keys %fields );
    $res = $portal->_post(
        '/cas/login',
        IO::String->new($s),
        cookie => $pdata,
        accept => 'text/html',
        length => length($s),
    );

    my ($query) =
      expectRedirection( $res, qr#^http://$app.example.org/\?(ticket=[^&]+)$# );

    $res = $portal->_get(
        '/cas/serviceValidate',
        query  => "service=http://$app.example.org/&$query",
        accept => 'text/html'
    );
}

sub portal {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel       => $debug,
                domain         => 'op.com',
                portal         => 'http://auth.idp.com/',
                authentication => 'Demo',
                userDB         => 'Same',

                appAccessHistoryEnabled => 1,

                # OIDC conf.
                issuerDBOpenIDConnectActivation => 1,
                oidcRPMetaDataOptions           => {
                    app1 => {
                        oidcRPMetaDataOptionsDisplayName   => "OIDC App 1",
                        oidcRPMetaDataOptionsClientID      => "oidc_1",
                        oidcRPMetaDataOptionsBypassConsent => 1,
                        oidcRPMetaDataOptionsRedirectUris  =>
"http://oidc_1.example.org http://oidc_1.example.org/oidcredirect",
                    },
                    app2 => {
                        oidcRPMetaDataOptionsDisplayName   => "OIDC App 2",
                        oidcRPMetaDataOptionsClientID      => "oidc_2",
                        oidcRPMetaDataOptionsBypassConsent => 1,
                        oidcRPMetaDataOptionsRedirectUris  =>
"http://oidc_2.example.org http://oidc_2.example.org/oidcredirect",
                    },
                    app3 => {
                        oidcRPMetaDataOptionsDisplayName   => "OIDC App 3",
                        oidcRPMetaDataOptionsClientID      => "oidc_3",
                        oidcRPMetaDataOptionsBypassConsent => 1,
                        oidcRPMetaDataOptionsRedirectUris  =>
"http://oidc_3.example.org http://oidc_3.example.org/oidcredirect",
                    },
                },

                # CAS conf.
                issuerDBCASActivation => 1,
                casAttr               => 'uid',
                casAttributes => { cn => 'cn', uid => 'uid', multi => 'multi' },
                casAccessControlPolicy => 'none',
                multiValuesSeparator   => ';',
                macros                 =>
                  { multi => '"value1;value2"', _whatToTrace => '$uid' },
                casAppMetaDataOptions => {
                    app1 => {
                        casAppMetaDataOptionsService =>
                          'http://cas_1.example.org',
                    },
                    app2 => {
                        casAppMetaDataOptionsService =>
                          'http://cas_2.example.org',
                    },
                },
            }
        }
    );
}

sub portal_with_lasso {
    return LLNG::Manager::Test->new( {
            ini => {
                logLevel       => $debug,
                domain         => 'op.com',
                portal         => 'http://auth.idp.com/',
                authentication => 'Demo',
                userDB         => 'Same',

                appAccessHistoryEnabled => 1,

                # SAML conf.
                issuerDBSAMLActivation => 1,
                samlSPMetaDataOptions  => {
                    app1 => {
                        samlSPMetaDataOptionsEncryptionMode           => 'none',
                        samlSPMetaDataOptionsSignSSOMessage           => 1,
                        samlSPMetaDataOptionsSignSLOMessage           => 1,
                        samlSPMetaDataOptionsCheckSSOMessageSignature => 1,
                        samlSPMetaDataOptionsCheckSLOMessageSignature => 1,
                    }
                },
                samlSPMetaDataExportedAttributes => {
                    app1 => {
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
                    app1 => {
                        samlSPMetaDataXML =>
                          samlProxyMetaDataXML( 'proxy', 'HTTP-Redirect' )
                    },
                },
            }
        }
    );
}
