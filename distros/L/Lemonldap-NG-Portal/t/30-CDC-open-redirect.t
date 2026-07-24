use warnings;
use Test::More;
use strict;
use MIME::Base64;

BEGIN {
    require 't/test-lib.pm';
    require 't/saml-lib.pm';
}

# Non-regression test for the unauthenticated open redirect (CWE-601) in the
# SAML Common Domain Cookie endpoint. The CDC `url` parameter is base64-encoded
# and was redirected to without any origin control: an attacker could turn the
# SSO host into an open redirector.
#
# The CDC is a *cross-domain* IdP discovery service, so the trusted return
# targets are the federation members (SAML SP/IdP metadata hosts) and the
# explicitly trusted domains -- NOT the local protected applications
# (locationRules). See Lemonldap::NG::Portal::CDC::_buildTrustedDomainsRe.

my ( $cdc, $res );

use_ok('Lemonldap::NG::Portal::CDC');

ok(
    $cdc = LLNG::Manager::Test->new( {
            ini => {
                logLevel                     => 'error',
                samlCommonDomainCookieDomain => 'cdc.com',

                # Federation members declared through their SAML metadata: their
                # endpoint hosts (auth.sp.com, auth.idp.com) must become trusted
                # return targets.
                samlSPMetaDataXML => {
                    'sp' => {
                        samlSPMetaDataXML =>
                          samlSPMetaDataXML( 'sp', 'HTTP-POST' )
                    },
                },
                samlIDPMetaDataXML => {
                    'idp' => {
                        samlIDPMetaDataXML =>
                          samlIDPMetaDataXML( 'idp', 'HTTP-POST' )
                    },
                },

                # A non-SAML federation member, allowed via trustedDomains
                trustedDomains => 'partner.example.org',
            },
            class => 'Lemonldap::NG::Portal::CDC'
        }
    ),
    'CDC endpoint'
);

# --- Legitimate return URLs (must keep working: 302) ---

# Federation member (SP) known through its SAML metadata
my $spMember = 'http://auth.sp.com/?foo=bar';
ok(
    $res = $cdc->_get( '/', query => 'url=' . encode_base64( $spMember, '' ) ),
    'Return URL of a SAML SP federation member'
);
expectRedirection( $res, qr#^http://auth\.sp\.com/# );

# Federation member (IdP) known through its SAML metadata
my $idpMember = 'http://auth.idp.com/';
ok(
    $res = $cdc->_get( '/', query => 'url=' . encode_base64( $idpMember, '' ) ),
    'Return URL of a SAML IdP federation member'
);
expectRedirection( $res, $idpMember );

# Federation member allowed through trustedDomains
my $partner = 'https://partner.example.org/';
ok(
    $res = $cdc->_get( '/', query => 'url=' . encode_base64( $partner, '' ) ),
    'Return URL allowed by trustedDomains'
);
expectRedirection( $res, $partner );

# The portal hosting the CDC is also a valid target
my $portal = 'http://auth.example.com/';
ok(
    $res = $cdc->_get( '/', query => 'url=' . encode_base64( $portal, '' ) ),
    'Return URL pointing to the local portal'
);
expectRedirection( $res, $portal );

# --- Open redirect attempts (must be rejected: 400) ---

# Arbitrary external host
ok(
    $res = $cdc->_get(
        '/', query => 'url=' . encode_base64( 'https://attacker.example.com', '' )
    ),
    'External host is refused'
);
expectBadRequest($res);
is( getHeader( $res, 'Location' ),
    undef, 'No Location header for untrusted URL' );

# A local protected application (locationRules) must NOT be a valid CDC target
ok(
    $res = $cdc->_get(
        '/', query => 'url=' . encode_base64( 'http://test1.example.com/', '' )
    ),
    'Local protected vhost is not a CDC redirect target'
);
expectBadRequest($res);

# Protocol-relative URL (//attacker.example.com): rejected, not absolute http(s)
ok(
    $res = $cdc->_get(
        '/', query => 'url=' . encode_base64( '//attacker.example.com', '' )
    ),
    'Protocol-relative URL is refused'
);
expectBadRequest($res);

# Backslash-prefixed protocol-relative variant (/\attacker.example.com)
ok(
    $res = $cdc->_get(
        '/', query => 'url=' . encode_base64( '/\\attacker.example.com', '' )
    ),
    'Backslash protocol-relative URL is refused'
);
expectBadRequest($res);

# A relative path is not an absolute http(s) URL: refused
ok(
    $res =
      $cdc->_get( '/', query => 'url=' . encode_base64( '/somewhere', '' ) ),
    'Relative path is refused'
);
expectBadRequest($res);

# Subdomain suffix trick (auth.sp.com.attacker.com)
ok(
    $res = $cdc->_get(
        '/',
        query => 'url=' . encode_base64( 'http://auth.sp.com.attacker.com/', '' )
    ),
    'Suffixed trusted host is refused'
);
expectBadRequest($res);

# CRLF / header injection attempt: even with a trusted host, the Location
# header must never carry a CR/LF
ok(
    $res = $cdc->_get(
        '/',
        query => 'url='
          . encode_base64(
            "https://partner.example.org/\r\nSet-Cookie: pwned=1", ''
          )
    ),
    'CRLF injection attempt'
);
my $loc = getHeader( $res, 'Location' ) // '';
unlike( $loc, qr/[\r\n]/, 'Location header is free of CR/LF' );

clean_sessions();
done_testing();
