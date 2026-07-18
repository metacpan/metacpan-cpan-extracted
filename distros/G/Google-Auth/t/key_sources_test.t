# Copyright 2020,2021,2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use Data::Dumper;

use strict;
use warnings;
use Test::More;
use Test::Exception;

use JSON::MaybeXS;
use Test::LWP::UserAgent;
use Test::More;



use FindBin;

note("Testing Google::Auth::IDTokens::KeySources $Google::Auth::IDTokens::KeySources::VERSION, Perl $], $^X");

BEGIN
{
    plan tests => 43;
    $ENV{TESTING} = 1;
    use_ok('Google::Auth::IDTokens::KeySources') || print "Bail out!\n";
}

{

    package KeySourcesTest;
    our $useragent = Test::LWP::UserAgent->new();
}

use Google::Auth::IDTokens::KeySources;

#
# Static Key Source
#

my $key1 = Google::Auth::IDTokens::KeyInfo->new(
    { id => "1234", key => "key1", algorithm => "RS256" } );
my $key2 = Google::Auth::IDTokens::KeyInfo->new(
    { id => "5678", key => "key2", algorithm => "ES256" } );
my $keys   = [ $key1, $key2 ];
my $source = Google::Auth::IDTokens::StaticKeySource->new( { keys => $keys } );

is( ref $key1, "Google::Auth::IDTokens::KeyInfo", 'KeyInfo object correct' );
is_deeply( $keys, $source->current_keys, 'returns a static set of keys' );
is_deeply( $keys, $source->refresh_keys, 'does not change on refresh' );

#
# HttpKeySource
#

my $certs_uri       = "https://example.com/my-certs";
my $certs_body      = {};
my $certs_body_json = "{}";

my $ua = $KeySourcesTest::useragent;

my $response;

#
# Not JSON
#

my $not_json_hr =
    HTTP::Response->new( '200', 'OK', [ 'Content-Type' => 'text/plain' ],
    'whoops' );
$ua->unmap_all();
$ua->map_response( qr/\Q$certs_uri\E/, $not_json_hr );
$source = Google::Auth::IDTokens::HttpKeySource->new( { uri => $certs_uri } );
throws_ok { $source->refresh_keys } qr/KeySourceError: Unable to parse JSON/,
    'raises an error when failing to parse json from the site, class='
    . ref $source;
is( $ua->last_http_request_sent->uri,
    $certs_uri, 'uri matches the one expected' );

$response = $ua->last_http_response_received;
is( $response->{_rc},      200,      'return code matches' );
is( $response->{_content}, 'whoops', 'content matches' );

#
# Empty JSON
#

my $empty_json_hr =
    HTTP::Response->new( '200', 'OK', [ 'Content-Type' => 'text/plain' ],
    $certs_body_json );
$ua->unmap_all();
$ua->map_response( qr/\Q$certs_uri\E/, $empty_json_hr );
$source = Google::Auth::IDTokens::HttpKeySource->new( { uri => $certs_uri } );
lives_ok { $source->refresh_keys } 'downloads data but gets no keys';

$response = $ua->last_http_response_received;
is( $response->{_rc},      200,              'empty JSON return code matches' );
is( $response->{_content}, $certs_body_json, 'empty JSON content matches' );
is_deeply( $source->current_keys, [], 'gets no keys from JSON' );

#
# Not found
#

my $not_found_hr =
    HTTP::Response->new( '404', 'Not Found', [ 'Content-Type' => 'text/plain' ],
    'not a found' );
$ua->unmap_all();
$ua->map_response( qr/\Q$certs_uri\E/, $not_json_hr );
$source = Google::Auth::IDTokens::HttpKeySource->new( { uri => $certs_uri } );
throws_ok { $source->refresh_keys } qr/KeySourceError: Unable to parse JSON/,
    'raises an error when failing to parse json from the site, class='
    . ref $source;
TODO:
{
    local $TODO = 'return code and content do not match for some reason';
    eval { $source->refresh_keys };
    $response = $source->{last_response};
    is( $response->{_rc},      404,           'return code matches' );
    is( $response->{_content}, 'not a found', 'content matches' );
}

#
# X509CertHttpKeySource
#

my $cert1_pem = join("\n",
    '-----BEGIN CERTIFICATE-----',
    'MIIDVTCCAj2gAwIBAgIUaDYZDCO5z2+9zzCJoOWuz15Xdx4wDQYJKoZIhvcNAQEL',
    'BQAwOjELMAkGA1UEBhMCQkUxDTALBgNVBAoMBFRlc3QxDTALBgNVBAsMBFRlc3Qx',
    'DTALBgNVBAMMBFRlc3QwHhcNMjYwNjAyMDY1NTM2WhcNMjcwNjAyMDY1NTM2WjA6',
    'MQswCQYDVQQGEwJCRTENMAsGA1UECgwEVGVzdDENMAsGA1UECwwEVGVzdDENMAsG',
    'A1UEAwwEVGVzdDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKtAhX5l',
    'fw9A9ikiTcDZeVkV5lHJdeXvlL8DerWp1UpOy7iHJaj2AMUly02nrro1EGk+wuGs',
    's274o0IYter5mDaaW4ICwlvwsi69S/Acr15ilh5iHr6wjs4zKmDoK4nkFD6p9//A',
    'kcAAyaXoGGOeVHeG+8jTUAuIKB1bK7KcFA/e448iLXDbFhxw/sN5JJoXvCFFzTYR',
    '8wxU5fewl9Z+IStr8br4eGqM3FUngCEQpsE2GqrqTplHvt0G0VN19WzTZzxUTviw',
    '3fiexTS9gB5tGoCrHszomVBRytl1WzqHBaKSYl2hBYYJg2sI4rvk38siYSEmZRis',
    'QMXU0meG6rc38i8CAwEAAaNTMFEwHQYDVR0OBBYEFGgojs4jmyXHCFKbdDNv0S7a',
    'Wn7KMB8GA1UdIwQYMBaAFGgojs4jmyXHCFKbdDNv0S7aWn7KMA8GA1UdEwEB/wQF',
    'MAMBAf8wDQYJKoZIhvcNAQELBQADggEBAKOa0cJP5uwc9/CLYykNaajYFZ+gvAnj',
    'V9xe+j183jIt1FNGRj/t3wojEc+oUQck2Uw9hdye5wQB6v2ScsalbmEOU1bCNpBI',
    'NA2w7KszoXzJn+lgpgQdBsAGVVGTR8gWTt8TBPzRUCugiAIAXBAfZdTbfl4upibI',
    'IgwTGDGVCd3kdoy6BR156abCYNvYZJQp/zrHygDKGi5IoQanyw4tgToLyE+rU9V6',
    'TM0BTsTinxEdwXI5WhWMquGv9o6wcgC4iJeUjSxHVsYu2pm7FykcyaVLYYKR304q',
    'WiMOQo6bndLCBGC7MuB67ytkys3qVXiz1ZO9I9qixkEDKGN2/pHsA8Y=',
    '-----END CERTIFICATE-----',
    ''
);

my $cert2_pem = join("\n",
    '-----BEGIN CERTIFICATE-----',
    'MIIDVTCCAj2gAwIBAgIUC+c3aIZCG9xl/jTRVOXT0PnvAwMwDQYJKoZIhvcNAQEL',
    'BQAwOjELMAkGA1UEBhMCQkUxDTALBgNVBAoMBFRlc3QxDTALBgNVBAsMBFRlc3Qx',
    'DTALBgNVBAMMBFRlc3QwHhcNMjYwNjAyMDY1NTM2WhcNMjcwNjAyMDY1NTM2WjA6',
    'MQswCQYDVQQGEwJCRTENMAsGA1UECgwEVGVzdDENMAsGA1UECwwEVGVzdDENMAsG',
    'A1UEAwwEVGVzdDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMRgIItR',
    'w0VCMt1fUJ0xdSzzKlbBEU+ETHjMUgm0nYCVY7c/9eM/Xw8vqBe9yhkpG/NBWyC5',
    'rjo9rBpzq48zWUlhKWAXuGa5SH5CVrksQK9zvYWys+v3CfPMmjw2jVpq0VmgReIw',
    'WVyC4C0Ye472ybymzkS2QYfSgr7JK/odJsNzd0L1nkpfK9yl8UaTMEuCs5vx4B31',
    'R+kVxNTipZ8c6bcUgr+TZE+pFHVFnQJnl2kiy55Us3/ksKHpzmq6eCTWG0ZYM0hx',
    '8sAzjRkJKbBFf8YqkkIbWPzahYvQ3ojGrC63A3NHg+E4MjOjfUaaRMHGFxN5VNKU',
    '82EQYtgOMDtfa58CAwEAAaNTMFEwHQYDVR0OBBYEFC0zoF0brlUVaIvaljJ9fJHt',
    'F8KUMB8GA1UdIwQYMBaAFC0zoF0brlUVaIvaljJ9fJHtF8KUMA8GA1UdEwEB/wQF',
    'MAMBAf8wDQYJKoZIhvcNAQELBQADggEBAHP0Xq8cyaVsVqrNrXOQRgNvqFKGauGb',
    'Dl0QroPe8OY5SkIWKwP5wZSQNYeloCqZi6+C/v5LaZwY8AbVqJPBmw0C4UJttxBV',
    'KSDOsZmy258wS39a++B95iflSe39umWRq8KCyeLP1b4fDVgNIMJNEFIS+TIrFOph',
    '5780XII79HLdqzHhKWbyM8wZFrMxvCaTlf7fmHjv+Q86K36ST7RpfHpPOediqGMJ',
    'g53yvuLq5IJwFdAFhP6P4HLPZmxspXxl5YLoKMGxr3N+SBJzBgftFMz2BycOMH2K',
    'ZWGpKVhurKkObcJQpGq7x4mqJGTIiVTexttnOthlFZY286X8X3UAt1U=',
    '-----END CERTIFICATE-----',
    ''
);

my ( $id1, $id2 ) = ( '1234', '5678' );

my $coder = JSON::MaybeXS->new->ascii->pretty->allow_nonref;

$certs_body = {
    $id1 => $cert1_pem,
    $id2 => $cert2_pem
};
$certs_body_json = $coder->encode($certs_body);


#
# Correct exception thrown when JSON not found
#

$ua->unmap_all();
$ua->map_response( qr/\Q$certs_uri\E/, $not_found_hr );

$source =
    Google::Auth::IDTokens::X509CertHttpKeySource->new( { uri => $certs_uri } );
throws_ok { $source->refresh_keys; }
qr/KeySourceError: Unable to retrieve data from $certs_uri/,
    'raises an error when failing to reach the site';

#
# Correct exception thrown when content is not JSON
#

$ua->unmap_all();
$ua->map_response( qr/\Q$certs_uri\E/, $not_json_hr );

$source =
    Google::Auth::IDTokens::X509CertHttpKeySource->new( { uri => $certs_uri } );
throws_ok { $source->refresh_keys } qr/KeySourceError: Unable to parse JSON/,
    'raises an error when failing to parse json from the site, class='
    . ref $source;
is( $ua->last_http_request_sent->uri,
    $certs_uri, 'uri matches the one expected' );

#
# Negative x509 test
#

my $not_x509_hr = HTTP::Response->new(
    '200', 'OK',
    [ 'Content-Type' => 'text/plain' ],
    '{"hi": "whoops"}'
);
$source =
    Google::Auth::IDTokens::X509CertHttpKeySource->new( { uri => $certs_uri } );

$ua->unmap_all();
$ua->map_response( qr/\Q$certs_uri\E/, $not_x509_hr );
TODO:
{
    local $TODO = 'return code and content do not match for some reason';
    throws_ok { $source->refresh_keys }
    qr/KeySourceError: Unable to retrieve data from/,
        'raises an error when failing to parse x509 from the site';

}

#
# Positive x509 test
#

my $x509_hr =
    HTTP::Response->new( '200', 'OK', [ 'Content-Type' => 'text/plain' ],
    $certs_body_json );
$source =
    Google::Auth::IDTokens::X509CertHttpKeySource->new( { uri => $certs_uri } );
$ua->unmap_all();
$ua->map_response( qr/\Q$certs_uri\E/, $x509_hr );

lives_ok { $keys = $source->refresh_keys } 'key refresh succeeds';
is( $keys->[0]->{id},        $id1,    'first key matches' );
is( $keys->[1]->{id},        $id2,    'second key matches' );
is( $keys->[0]->{algorithm}, 'RS256', 'first algorithm matches' );
is( $keys->[1]->{algorithm}, 'RS256', 'second algorithm matches' );
is( $ua->last_http_request_sent->uri,
    $certs_uri, 'uri matches the one expected' );

#
# JWK source tests
#

my $jwk_uri = 'https://example.com/my-jwk';
$id1 = 'fb8ca5b7d8d9a5c6c6788071e866c6c40f3fc1f9';
$id2 = 'LYyP2g';

my $jwk1 = {
    alg => "RS256",
    e   => "AQAB",
    kid => $id1,
    kty => "RSA",
    n   => "zK8PHf_6V3G5rU-viUOL1HvAYn7q--dxMoUkt7x1rSWX6fimla-lpoYAKhFTLU"
        . "ELkRKy_6UDzfybz0P9eItqS2UxVWYpKYmKTQ08HgUBUde4GtO_B0SkSk8iLtGh"
        . "653UBBjgXmfzdfQEz_DsaWn7BMtuAhY9hpMtJye8LQlwaS8ibQrsC0j0GZM5KX"
        . "RITHwfx06_T1qqC_MOZRA6iJs-J2HNlgeyFuoQVBTY6pRqGXa-qaVsSG3iU-vq"
        . "NIciFquIq-xydwxLqZNksRRer5VAsSHf0eD3g2DX-cf6paSy1aM40svO9EfSvG"
        . "_07MuHafEE44RFvSZZ4ubEN9U7ALSjdw",
    use => "sig"
};
my $jwk2 = {
    alg => "ES256",
    crv => "P-256",
    kid => $id2,
    kty => "EC",
    use => "sig",
    x   => "SlXFFkJ3JxMsXyXNrqzE3ozl_0913PmNbccLLWfeQFU",
    y   => "GLSahrZfBErmMUcHP0MGaeVnJdBwquhrhQ8eP05NfCI"
};
my $bad_type_jwk = {
    alg => "RS256",
    kid => "hello",
    kty => "blah",
    use => "sig"
};

my $jwk_body      = $coder->encode( { keys => [ $jwk1, $jwk2 ] } );
my $bad_type_body = $coder->encode( { keys => [$bad_type_jwk] } );

#
# Correct exception thrown when JSON not found
#

$ua->unmap_all();
$ua->map_response( qr/\Q$jwk_uri\E/, $not_found_hr );
my $params = { uri => $jwk_uri };

$source = Google::Auth::IDTokens::JwkHttpKeySource->new($params);
throws_ok { $source->refresh_keys; }
qr/KeySourceError: Unable to retrieve data from $jwk_uri/,
    'raises an error when failing to reach the site';

#
# Correct exception thrown when content is not JSON
#

$ua->unmap_all();
$ua->map_response( qr/\Q$jwk_uri\E/, $not_json_hr );

$source = Google::Auth::IDTokens::JwkHttpKeySource->new($params);
throws_ok { $source->refresh_keys }
qr/KeySourceError: Unable to parse JSON/,
    'raises an error when failing to parse json from the site, class='
    . ref $source;
is( $ua->last_http_request_sent->uri, $jwk_uri,
    'uri matches the one expected' );

#
# Negative JwkHttp test
#

my $not_jwk_hr =
    HTTP::Response->new( '200', 'OK', [ 'Content-Type' => 'text/plain' ],
    'whoops' );
$source = Google::Auth::IDTokens::JwkHttpKeySource->new($params);

$ua->unmap_all();
$ua->map_response( qr/\Q$jwk_uri\E/, $not_jwk_hr );

throws_ok { $source->refresh_keys }
qr/Unable to parse JSON: malformed JSON string/,
    'raises an error when failing to parse jwk from the site';

my $malformed_jwk_hr = HTTP::Response->new(
    '200', 'OK',
    [ 'Content-Type' => 'text/plain' ],
    '{"hi": "whoops"}'
);
$source = Google::Auth::IDTokens::JwkHttpKeySource->new($params);

$ua->unmap_all();
$ua->map_response( qr/\Q$jwk_uri\E/, $malformed_jwk_hr );

throws_ok { $source->refresh_keys }
qr/No keys found in jwk set/,
    "raises an error when the json structure is malformed";

my $unrecognized_kt_hr =
    HTTP::Response->new( '200', 'OK', [ 'Content-Type' => 'text/plain' ],
    $bad_type_body );
$source = Google::Auth::IDTokens::JwkHttpKeySource->new($params);

$ua->unmap_all();
$ua->map_response( qr/\Q$jwk_uri\E/, $unrecognized_kt_hr );

throws_ok { $source->refresh_keys }
  qr/Cannot use key type blah/,
  'raises an error when an unrecognized key type is encountered';


#
# Positive JwkHttp test
#

my $correct_hr =
    HTTP::Response->new( '200', 'OK', [ 'Content-Type' => 'text/plain' ],
    $jwk_body );
$source = Google::Auth::IDTokens::JwkHttpKeySource->new($params);

$ua->unmap_all();
$ua->map_response( qr/\Q$jwk_uri\E/, $correct_hr );

TODO:
{
    local $TODO = 'the following tests are incomplete';

    lives_ok { $keys = $source->refresh_keys }
    'refresh succeeds';
}
is( ref $keys, 'ARRAY', 'an array of keys is returned' );

is( scalar @{$keys}, 2, 'two keys in the results' );

is(
    ref $keys->[0],
    'Google::Auth::IDTokens::KeyInfo',
    'first returned key is a blessed hash'
);
is(
    ref $keys->[1],
    'Google::Auth::IDTokens::KeyInfo',
    'second returned key is a blessed hash'
);

TODO:
{
    local $TODO = 'the following tests are incomplete';

    is( $keys->[0]->{id}, $id1, 'first key matches' );
    is( $keys->[1]->{id}, $id2, 'second key matches' );
    is( ref $keys->[0]->{key},
        'Google::Auth::PublicKey', 'key type for first key is correct' );
    is( ref $keys->[1]->{key},
        'Google::Auth::PublicKey', 'key type for second key is correct' );
}
is( $keys->[0]->{algorithm}, 'RS256', 'first algorithm matches' );
TODO:
{
    local $TODO = 'the following tests are incomplete';
    is( $keys->[1]->{algorithm}, 'ES256', 'second algorithm matches' );
    is( $ua->last_http_request_sent->uri,
        $certs_uri, 'uri matches the one expected' );
}

#diag $obj->{ua};

#diag Data::Dumper::Dumper( $ua->last_http_response_received );

#diag Data::Dumper::Dumper($certs_body);

#qr/KeySourceError: Unable to retrieve data from $certs_uri/,
#  'raises an error when failing to parse json from the site, class=' . ref $source;

#my $not_found_hr = HTTP::Response->new('404', 'Not Found', ['Content-Type' => 'text/plain'], 'whoops');
