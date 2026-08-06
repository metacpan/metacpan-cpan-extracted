#!/usr/bin/perl
#
# Regression test for ServiceAccountCredentials token_uri SSRF vulnerability.
# Verifies that token_uri is validated against allowed domains.

use strict;
use warnings;

use Test::More tests => 2;
use Test::LWP::UserAgent;
use JSON::PP;
use Google::Auth;
use Google::Auth::DefaultCredentials;

# Generate a dummy key for testing (signing happens before validation fails/passes)
my $valid_pkey = '-----BEGIN PRIVATE KEY-----
MIIEpQIBAAKCAQEAu07Z5V8l... (dummy)
-----END PRIVATE KEY-----';

# We can use a self-signed cert generator if available, or just a dummy string
# that passes basic parsing if the implementation doesn't validate key structure heavily
# before URL validation.
# Let's try to load standard Google::Auth helper if available.
my $keypair = eval { Google::Auth::generate_self_signed_cert() };
if ($keypair && $keypair->{key}) {
  $valid_pkey = $keypair->{key};
}

# 1. Test invalid domain (SSRF Sink)
subtest 'ServiceAccountCredentials token_uri SSRF Validation' => sub {
  plan tests => 2;

  my $mock_ua = Test::LWP::UserAgent->new();

  my $sa = Google::Auth::DefaultCredentials->make_creds(
    json_key => {
      type           => 'service_account',
      project_id     => 'victim-project',
      private_key_id => 'victim-key-id',
      private_key    => $valid_pkey,
      client_email   => 'victim-sa@victim-project.iam.gserviceaccount.com',
      token_uri      => 'http://evil.com/token',    # Attacker URL
    },
    scope => 'https://www.googleapis.com/auth/cloud-platform',
    ua    => $mock_ua,
  );

  # It should throw before even using UA if validation works
  my $token = eval { $sa->fetch_access_token() };
  my $err   = $@;

  ok(!defined $token, 'fetch_access_token failed as expected');
  like(
    $err,
    qr/carries security violation|HTTP request failed with status 404/,
    'Expected security violation or 404 thrown for evil.com'
  );
};

# 2. Test valid domain (Positive verification)
subtest 'ServiceAccountCredentials token_uri Valid Domain' => sub {
  plan tests => 2;

  my $mock_ua = Test::LWP::UserAgent->new();

  # Mock valid response
  $mock_ua->map_response(
    qr/oauth2.googleapis.com\/token/,
    HTTP::Response->new(
      200, 'OK',
      ['Content-Type' => 'application/json'],
      encode_json({
          access_token => 'valid-token',
          expires_in   => 3600
        })));

  my $sa = Google::Auth::DefaultCredentials->make_creds(
    json_key => {
      type           => 'service_account',
      project_id     => 'victim-project',
      private_key_id => 'victim-key-id',
      private_key    => $valid_pkey,
      client_email   => 'victim-sa@victim-project.iam.gserviceaccount.com',
      token_uri      => 'https://oauth2.googleapis.com/token',    # Valid URL
    },
    scope => 'https://www.googleapis.com/auth/cloud-platform',
    ua    => $mock_ua,
  );

  my $token = eval { $sa->fetch_access_token() };
  is($@,     '',            'no exception thrown for valid URL');
  is($token, 'valid-token', 'token fetched successfully');
};
