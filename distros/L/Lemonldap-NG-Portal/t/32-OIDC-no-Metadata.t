use warnings;
use Test::More;
use strict;
use IO::String;
use LWP::UserAgent;
use LWP::Protocol::PSGI;
use MIME::Base64;
use Hash::Merge::Simple qw/merge/;
use JSON;

BEGIN {
    require 't/test-lib.pm';
    require 't/oidc-lib.pm';
}

my $debug = 'error';

my $previousPrivateKey = "-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCiv4iLnob2CLj+
Y5A/nzdZc/tzNwS84O8Y4n6aE13OUyj0Pv2Uti3KljrUBfHNz0shsG6bx2IBHA+b
nldk0ye1JJrr5pMDgkWgHNTMdKJNwNoSLAd+Aq/2GISFUrwxSD/AU5L46YPtHKoB
0NMxH6clCg6xNMGMExEmCyfLFvnkzwZKlAR7Z/kF+8Va97yX4adRcxZW+P+YouVG
TBcD8l5jWZhcqnU02rKAx3rHi010MbY7nwdScGPI5Q7eAJLiX4YeGmxlXA+gnMfC
CSenreDA8tnHsxUZO85DYrp5+uNW2Yhubs/XgOlkLEj2EhYqkBDqBkxvtnipjLNa
g8f98RUPAgMBAAECggEAfQeAMyL6tBFHbce3jekXcJV127Gs5h44EXoPoPa33kZs
9BdgYNsEmtqHH1PhzCcwpRUSJIMse4W/R+KBaWf+3V7d1dUxpER0kOkVYm1IM0ux
PLyulNQjsoBrbrF8+q9yqqKKCsf7HjIjOXnghaC3m/D6EJFjD+WmCwAO9isUl/5q
QITFy/qC7puXU3sjXmUugMctFYkJv1n9tFEuiltGPOGaKBM+MCtLnh1jnSc8DE/y
cTHNP08oZaZBOsLLPAsTrVJsLkJc4GaW9XcIdO6vkJDSYV7KKIKzf4h0mKiNvR7B
k3u8GtwgIXa/GRW3iCenvWFMSGll1hEOe7aay+VIYQKBgQDPb+aY3uxesan5Gpug
Ma7rBTwc1yEfbEyXF64RSZbvEAdGt+szrvCIwlZTDyIHMkgif6vOdk9k3ORgIq7b
RGIJKl5F59oBcGzBwZzw6c9ACib3UKpGXuTjh921d6jx3ik26cpLCicU7bVuegEG
6lUFsoF81snTKFBpxMRxS8ZQYwKBgQDI2VcNMkYeR43y+wN2JRzD9JFemSIs+Bv9
XaAFd0WRaXNae3PzltQob2GgzXJw45+Xl7ngKISdb4SVQ0gWRzbyFEQLUIwQ+xti
GAaIPO2ikZM6IgOFnV+KVlYJf4m9YEzpJnLauAj4K0InWC97lZMru5dkTaniYWlV
lKn4dIqKZQKBgD88wtS5qN9ZVBLfvK/CVavKBcBZCPz2XAb3rhYRFBU/EqjJasdv
vl5CuGRLybjd6EW0HCEtyhhairiP+jRYDXbz1peDDd/AcTdEGd8LuCWyspxUmAQp
66c9hSZMG1HYw0G9VfE4YB+uM9BBG00LZO3+tCDlrdNUh+cmmChdzFA3AoGAQDX7
tqRT9mo532yQdrz2rU8LCos6edX4XNAJ0LWI8CweTNcbAs09lo/FTntgEucypmxD
aH6Lpyl34aBY84Zg8pO4DUX7AZLF9l5n+DZCYq7XusYVCip92OQxLWgwyPJ4pDE+
lt4vP+fUhm+S/pebLWgTxmVt4onx+wJENMJNaGECgYBAlDlAgZOM/oituP536ljR
Hk8mmnqMWjSfvEWGj70MdrdKGB9zYog9uIXsS7bLJ9cmfKCsCApccP9mBnbm6bbu
dvmECwoUU+sAmX84V8DmEA3YY0tBmB9p81wNWoNJfZsHAJdluHbQ1IfNHK4shoFG
UZ3yY+puVg+xaIwvlFNu9A==
-----END PRIVATE KEY-----
";
my $previousPublicKey = "-----BEGIN CERTIFICATE-----
MIICsjCCAZqgAwIBAgIEQDp3EzANBgkqhkiG9w0BAQsFADAbMRkwFwYDVQQDDBBz
c28ubGluYWdvcmEuY29tMB4XDTIzMDYxOTEwMjEzN1oXDTQzMDYxNDEwMjEzN1ow
GzEZMBcGA1UEAwwQc3NvLmxpbmFnb3JhLmNvbTCCASIwDQYJKoZIhvcNAQEBBQAD
ggEPADCCAQoCggEBAKK/iIuehvYIuP5jkD+fN1lz+3M3BLzg7xjifpoTXc5TKPQ+
/ZS2LcqWOtQF8c3PSyGwbpvHYgEcD5ueV2TTJ7UkmuvmkwOCRaAc1Mx0ok3A2hIs
B34Cr/YYhIVSvDFIP8BTkvjpg+0cqgHQ0zEfpyUKDrE0wYwTESYLJ8sW+eTPBkqU
BHtn+QX7xVr3vJfhp1FzFlb4/5ii5UZMFwPyXmNZmFyqdTTasoDHeseLTXQxtjuf
B1JwY8jlDt4AkuJfhh4abGVcD6Ccx8IJJ6et4MDy2cezFRk7zkNiunn641bZiG5u
z9eA6WQsSPYSFiqQEOoGTG+2eKmMs1qDx/3xFQ8CAwEAATANBgkqhkiG9w0BAQsF
AAOCAQEAoWgiObm47/UA6XTrNC4swYIthyHtz+w9anm8gCRCunnqRD/FvdSFPmiz
PByPDwh3IFbYpCOH+Kij1Zujv6FGFwOieYwSV0eJWfXrJ12A5XNX9bHeQy9dp5iz
jcdHN17pTgpVRgWVKVZI9E8uSq6Q7I4cQwBYsgqJ5U7ikn78p60cPmLhAO4U2QLm
gYy9JY//7KkvY3qXqtSzvNQuILqXbIhP9DvEQyd43csLH+Z6kpFXInKrb9o8Z8as
5WndlDGrht0jByAeIIbKhx2NQUoRBdpSQJZB9vCZUuZ5r9FrasV2EbsODppM7Buf
6X+S9KrcSoCOlewcylIA/TsIncV2FA==
-----END CERTIFICATE-----
";

sub getop {
    my ($options) = @_;
    return LLNG::Manager::Test->new( {
            ini => merge {
                logLevel                        => $debug,
                domain                          => 'idp.com',
                portal                          => 'http://auth.op.com/',
                authentication                  => 'Demo',
                userDB                          => 'Same',
                issuerDBOpenIDConnectActivation => 1,
                oidcRPMetaDataExportedVars      => {
                    rp => {
                        email       => "mail",
                        family_name => "cn",
                        name        => "cn"
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
                        oidcRPMetaDataOptionsClientSecret      => "rpsecret",
                        oidcRPMetaDataOptionsUserIDAttr        => "",
                        oidcRPMetaDataOptionsAccessTokenExpiration => 3600,
                        oidcRPMetaDataOptionsBypassConsent         => 1,
                    },
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
                oidcServiceKeyIdSig         => 'currentKey',
                oidcServicePrivateKeySig    => oidc_key_op_private_sig,
                oidcServicePublicKeySig     => oidc_cert_op_public_sig,
                oidcServiceOldKeyIdSig      => 'previousKey',
                oidcServiceOldPrivateKeySig => $previousPrivateKey,
                oidcServiceOldPublicKeySig  => $previousPublicKey,
                oidcServiceHideMetadata     => 1,
            },
            $options
        },
    );
}

my $op = getop();

# Query Metadata URI
my $res;
ok(
    $res = $op->_get(
        "/.well-known/openid-configuration", accept => 'text/html',
    ),
    'Query OIDC metadata'
);
expectOK($res);
expectForm($res);

clean_sessions();
done_testing();
