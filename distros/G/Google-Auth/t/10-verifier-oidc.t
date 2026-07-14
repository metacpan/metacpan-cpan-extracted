# Copyright 2026 Google LLC
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

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::LWP::UserAgent;
use HTTP::Response;

BEGIN
{
    $ENV{TESTING} = 1;
    use_ok('Google::Auth::IDTokens::KeySources') || print "Bail out!\n";
    use_ok('Google::Auth::IDTokens::Verifier')   || print "Bail out!\n";
}

my $oidc_token =
    'eyJhbGciOiJSUzI1NiIsImtpZCI6IjQ5MjcxMGE3ZmNkYjE1Mzk2MGNlMDFmNzYwNTIwY'
  . 'TMyYzg0NTVkZmYiLCJ0eXAiOiJKV1QifQ.eyJhdWQiOiJodHRwOi8vZXhhbXBsZS5jb20'
  . 'iLCJhenAiOiI1NDIzMzkzNTc2MzgtY3IwZHNlcnIyZXZnN3N2MW1lZ2hxZXU3MDMyNzRm'
  . 'M2hAZGV2ZWxvcGVyLmdzZXJ2aWNlYWNjb3VudC5jb20iLCJlbWFpbCI6IjU0MjMzOTM1N'
  . 'zYzOC1jcjBkc2VycjJldmc3c3YxbWVnaHFldTcwMzI3NGYzaEBkZXZlbG9wZXIuZ3Nlcn'
  . 'ZpY2VhY2NvdW50LmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJleHAiOjE1OTEzNDI'
  . '3NzYsImlhdCI6MTU5MTMzOTE3NiwiaXNzIjoiaHR0cHM6Ly9hY2NvdW50cy5nb29nbGUu'
  . 'Y29tIiwic3ViIjoiMTA0MzQxNDczMTMxODI1OTU3NjAzIn0.GGDE_5HoLacyqdufdxnAC'
  . 'rXxYySKQYAzSQ5qfGjSUriuO3uLm2-rwSPFfLzzBeflEHdVX7XRFFszpxKajuZklF4dXd'
  . '0evB1u5i3QeCJ8MSZKKx6qus_ETJv4rtuPNEuyhaRcShB7BwI8RY0IZ4_EDrhYqYInrO2'
  . 'wQyJGYvc41JcmoKzRoNnEVydN0Qppt9bqevq_lJg-9UjJkJ2QHjPfTgMjwhLIgNptKgtR'
  . 'qdoRpJmleFlbuUqyPPJfAzv3Tc6h3kw88tEcI8R3n04xmHOSMwERFFQYJdQDMd2F9SSDe'
  . 'rh40codO_GuPZ7bEUiKq9Lkx2LH5TuhythfsMzIwJpaEA';

my $oidc_jwk_body = q{
{
  "keys": [
    {
      "kid": "fb8ca5b7d8d9a5c6c6788071e866c6c40f3fc1f9",
      "e": "AQAB",
      "alg": "RS256",
      "use": "sig",
      "n": "zK8PHf_6V3G5rU-viUOL1HvAYn7q--dxMoUkt7x1rSWX6fimla-lpoYAKhFTLUELkRKy_6UDzfybz0P9eItqS2UxVWYpKYmKTQ08HgUBUde4GtO_B0SkSk8iLtGh653UBBjgXmfzdfQEz_DsaWn7BMtuAhY9hpMtJye8LQlwaS8ibQrsC0j0GZM5KXRITHwfx06_T1qqC_MOZRA6iJs-J2HNlgeyFuoQVBTY6pRqGXa-qaVsSG3iU-vqNIciFquIq-xydwxLqZNksRRer5VAsSHf0eD3g2DX-cf6paSy1aM40svO9EfSvG_07MuHafEE44RFvSZZ4ubEN9U7ALSjdw",
      "kty": "RSA"
    },
    {
      "kty": "RSA",
      "kid": "492710a7fcdb153960ce01f760520a32c8455dff",
      "e": "AQAB",
      "alg": "RS256",
      "use": "sig",
      "n": "wl6TaY_3dsuLczYH_hioeQ5JjcLKLGYb--WImN9_IKMkOj49dgs25wkjsdI9XGJYhhPJLlvfjIfXH49ZGA_XKLx7fggNaBRZcj1y-I3_77tVa9N7An5JLq3HT9XVt0PNTq0mtX009z1Hva4IWZ5IhENx2rWlZOfFAXiMUqhnDc8VY3lG7vr8_VG3cw3XRKvlZQKbb6p2YIMFsUwaDGL2tVF4SkxpxIazUYfOY5lijyVugNTslOBhlEMq_43MZlkznSrbFx8ToQ2bQX4Shj-r9pLyofbo6A7K9mgWnQXGY5rQVLPYYRzUg0ThWDzwHdgxYC5MNxKyQH4RC2LPv3U0LQ"
    }
  ]
}
};

my $expected_oidc_aud = 'http://example.com';
my $expected_oidc_azp = '542339357638-cr0dserr2evg7sv1meghqeu703274f3h@developer.gserviceaccount.com';
my $unexpired_oidc_test_time = 1591339181;
my $expired_oidc_test_time   = $unexpired_oidc_test_time + 86400;

# Stub HTTP mock user agent
package KeySourcesTest;
our $useragent = Test::LWP::UserAgent->new();
package main;

my $ua = $KeySourcesTest::useragent;
$ua->unmap_all();
$ua->map_response(
    qr/oauth2\/v3\/certs/,
    HTTP::Response->new( '200', 'OK', [ 'Content-Type' => 'application/json' ], $oidc_jwk_body )
);

subtest 'OIDC good validation' => sub {
    my $payload = eval {
        Google::Auth::IDTokens::Verifier->verify_oidc(
            $oidc_token,
            aud       => $expected_oidc_aud,
            azp       => $expected_oidc_azp,
            time_now  => $unexpired_oidc_test_time
        );
    };
    is( $@, '', 'OIDC verification succeeded without throwing' );
    ok( defined $payload, 'payload is defined' );
    is( $payload->{aud}, $expected_oidc_aud, 'aud matches expected' );
    is( $payload->{azp}, $expected_oidc_azp, 'azp matches expected' );
    is( $payload->{iss}, 'https://accounts.google.com', 'iss matches expected' );
    done_testing();
};

subtest 'OIDC corrupted token' => sub {
    throws_ok {
        Google::Auth::IDTokens::Verifier->verify_oidc(
            $oidc_token . 'modified',
            aud       => $expected_oidc_aud,
            time_now  => $unexpired_oidc_test_time
        );
    } qr/SignatureError: Token signature verification failed/, 'throws SignatureError on corrupted token signature';
    done_testing();
};

subtest 'OIDC expired token' => sub {
    throws_ok {
        Google::Auth::IDTokens::Verifier->verify_oidc(
            $oidc_token,
            aud       => $expected_oidc_aud,
            time_now  => $expired_oidc_test_time
        );
    } qr/ExpiredTokenError: Token signature is expired/, 'throws ExpiredTokenError on expired token';
    done_testing();
};

done_testing();
