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

my $iap_token =
    'eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjBvZUxjUSJ9.eyJhdWQiOiIvcH'
  . 'JvamVjdHMvNjUyNTYyNzc2Nzk4L2FwcHMvY2xvdWQtc2FtcGxlcy10ZXN0cy1waHAtaWFwI'
  . 'iwiZW1haWwiOiJkYXp1bWFAZ29vZ2xlLmNvbSIsImV4cCI6MTU5MTMzNTcyNCwiZ29vZ2xl'
  . 'Ijp7ImFjY2Vzc19sZXZlbHMiOlsiYWNjZXNzUG9saWNpZXMvNTE4NTUxMjgwOTI0L2FjY2V'
  . 'zc0xldmVscy9yZWNlbnRTZWN1cmVDb25uZWN0RGF0YSIsImFjY2Vzc1BvbGljaWVzLzUxOD'
  . 'U1MTI4MDkyNC9hY2Nlc3NMZXZlbHMvdGVzdE5vT3AiLCJhY2Nlc3NQb2xpY2llcy81MTg1N'
  . 'TEyODA5MjQvYWNjZXNzTGV2ZWxzL2V2YXBvcmF0aW9uUWFEYXRhRnVsbHlUcnVzdGVkIiwi'
  . 'YWNjZXNzUG9saWNpZXMvNTE4NTUxMjgwOTI0L2FjY2Vzc0xldmVscy9jYWFfZGlzYWJsZWQ'
  . 'iLCJhY2Nlc3NQb2xpY2llcy81MTg1NTEyODA5MjQvYWNjZXNzTGV2ZWxzL3JlY2VudE5vbk'
  . '1vYmlsZVNlY3VyZUNvbm5lY3REYXRhIiwiYWNjZXNzUG9saWNpZXMvNTE4NTUxMjgwOTI0L'
  . '2FjY2Vzc0xldmVscy9jb25jb3JkIiwiYWNjZXNzUG9saWNpZXMvNTE4NTUxMjgwOTI0L2Fj'
  . 'Y2Vzc0xldmVscy9mdWxseVRydXN0ZWRfY2FuYXJ5RGF0YSIsImFjY2Vzc1BvbGljaWVzLzU'
  . 'xODU1MTI4MDkyNC9hY2Nlc3NMZXZlbHMvZnVsbHlUcnVzdGVkX3Byb2REYXRhIl19LCJoZC'
  . 'I6Imdvb2dsZS5jb20iLCJpYXQiOjE1OTEzMzUxMjQsImlzcyI6Imh0dHBzOi8vY2xvdWQuZ'
  . '29vZ2xlLmNvbS9pYXAiLCJzdWIiOiJhY2NvdW50cy5nb29nbGUuY29tOjExMzc3OTI1ODA4'
  . 'MTE5ODAwNDY5NCJ9.2BlagZOoonmX35rNY-KPbONiVzFAdNXKRGkX45uGFXeHryjKgv--K6'
  . 'siL8syeCFXzHvgmWpJk31sEt4YLxPKvQ';

my $iap_jwk_body = q{
{
  "keys" : [
    {
        "alg" : "ES256",
        "crv" : "P-256",
        "kid" : "LYyP2g",
        "kty" : "EC",
        "use" : "sig",
        "x" : "SlXFFkJ3JxMsXyXNrqzE3ozl_0913PmNbccLLWfeQFU",
        "y" : "GLSahrZfBErmMUcHP0MGaeVnJdBwquhrhQ8eP05NfCI"
    },
    {
        "alg" : "ES256",
        "crv" : "P-256",
        "kid" : "mpf0DA",
        "kty" : "EC",
        "use" : "sig",
        "x" : "fHEdeT3a6KaC1kbwov73ZwB_SiUHEyKQwUUtMCEn0aI",
        "y" : "QWOjwPhInNuPlqjxLQyhveXpWqOFcQPhZ3t-koMNbZI"
    },
    {
        "alg" : "ES256",
        "crv" : "P-256",
        "kid" : "b9vTLA",
        "kty" : "EC",
        "use" : "sig",
        "x" : "qCByTAvci-jRAD7uQSEhTdOs8iA714IbcY2L--YzynI",
        "y" : "WQY0uCoQyPSozWKGQ0anmFeOH5JNXiZa9i6SNqOcm7w"
    },
    {
        "alg" : "ES256",
        "crv" : "P-256",
        "kid" : "0oeLcQ",
        "kty" : "EC",
        "use" : "sig",
        "x" : "MdhRXGEoGJLtBjQEIjnYLPkeci9rXnca2TffkI0Kac0",
        "y" : "9BoREHfX7g5OK8ELpA_4RcOnFCGSjfR4SGZpBo7juEY"
    },
    {
        "alg" : "ES256",
        "crv" : "P-256",
        "kid" : "g5X6ig",
        "kty" : "EC",
        "use" : "sig",
        "x" : "115LSuaFVzVROJiGfdPN1kT14Hv3P4RIjthfslZ010s",
        "y" : "-FAaRtO4yvrN4uJ89xwGWOEJcSwpLmFOtb0SDJxEAuc"
    }
  ]
}
};

my $expected_iap_aud = '/projects/652562776798/apps/cloud-samples-tests-php-iap';
my $unexpired_iap_test_time = 1591335143;
my $expired_iap_test_time   = $unexpired_iap_test_time + 86400;

# Stub HTTP mock user agent
package KeySourcesTest;
our $useragent = Test::LWP::UserAgent->new();
package main;

my $ua = $KeySourcesTest::useragent;
$ua->unmap_all();
$ua->map_response(
    qr/iap\/verify\/public_key-jwk/,
    HTTP::Response->new( '200', 'OK', [ 'Content-Type' => 'application/json' ], $iap_jwk_body )
);

subtest 'IAP good validation' => sub {
    my $payload = eval {
        Google::Auth::IDTokens::Verifier->verify_iap(
            $iap_token,
            aud       => $expected_iap_aud,
            time_now  => $unexpired_iap_test_time
        );
    };
    is( $@, '', 'IAP verification succeeded without throwing' );
    ok( defined $payload, 'payload is defined' );
    is( $payload->{aud}, $expected_iap_aud, 'aud matches expected' );
    is( $payload->{iss}, 'https://cloud.google.com/iap', 'iss matches expected' );
    done_testing();
};

subtest 'IAP corrupted token' => sub {
    throws_ok {
        Google::Auth::IDTokens::Verifier->verify_iap(
            $iap_token . 'bad',
            aud       => $expected_iap_aud,
            time_now  => $unexpired_iap_test_time
        );
    } qr/SignatureError: Token signature verification failed/, 'throws SignatureError on corrupted IAP token';
    done_testing();
};

subtest 'IAP expired token' => sub {
    throws_ok {
        Google::Auth::IDTokens::Verifier->verify_iap(
            $iap_token,
            aud       => $expected_iap_aud,
            time_now  => $expired_iap_test_time
        );
    } qr/ExpiredTokenError: Token signature is expired/, 'throws ExpiredTokenError on expired IAP token';
    done_testing();
};

done_testing();
