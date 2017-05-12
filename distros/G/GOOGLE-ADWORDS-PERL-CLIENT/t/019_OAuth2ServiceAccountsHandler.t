#!/usr/bin/perl
#
# Copyright 2012, Google Inc. All Rights Reserved.
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
#
# Unit tests for the Google::Ads::AdWords::OAuth2ServiceAccountsHandler module.
#
# Author: David Torres <david.t@google.com>

use strict;
use lib qw(lib t t/util);

use File::Basename;
use File::Spec;
use Test::More (tests => 13);
use Test::MockObject;
use TestClientUtils qw(get_test_client_no_auth);

use_ok("Google::Ads::AdWords::OAuth2ServiceAccountsHandler");

my $user_agent_mock = Test::MockObject->new();
my $crypt_module_mock = Test::MockObject->new();

my $handler = Google::Ads::AdWords::OAuth2ServiceAccountsHandler->new({
  __user_agent => $user_agent_mock,
  __crypt_module => $crypt_module_mock
});

my $client = get_test_client_no_auth();
my $current_version = $client->get_version();

# Test defaults.
is($handler->_scope(), "https://adwords.google.com/api/adwords/");

$handler->initialize($client, {
  oAuth2ClientId => "client-id",
  oAuth2AccessToken => "access-token",
  oAuth2ServiceAccountEmailAddress => "email",
  oAuth2ServiceAccountDelegateEmailAddress => "delegated-email",
  oAuth2ServiceAccountPEMFile => "t/testdata/test-cert.pem"
});

# Test initialization.
is($handler->get_client_id(), "client-id");
is($handler->get_email_address(), "email");
is($handler->get_delegated_email_address(), "delegated-email");

# Test preset access token.
my $exp = (time + 1000);
$user_agent_mock->mock(request => sub {
  my $response = HTTP::Response->new(200, "");
  $response->content("{\n\"scope\":\"https://adwords.google.com/api/" .
                     "adwords/\"\n\"expires_in\":" . $exp . "\n}");
  return $response;
});

ok($handler->is_auth_enabled());
is($handler->get_access_token(), "access-token");
ok($handler->get_access_token_expires());

# Test access token generation.
$crypt_module_mock->mock(new_private_key => sub {
  my ($self, $file) = @_;

  my $key = Test::MockObject->new();
  $key->mock(use_pkcs1_padding => sub { 1 });
  $key->mock(use_sha256_hash => sub { 1 });
  $key->mock(sign => sub {
    return "signed-claims"
  });

  return $key;
});

$user_agent_mock->mock(request => sub {
  my ($self, $request) = @_;

  ok($request->content =~
     /^grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=[A-Za-z0-9]+\.[A-Za-z0-9]+\.[A-Za-z0-9]+$/,
     "test valid JWT request content");
  is($request->method, "POST");
  is($request->url, "https://accounts.google.com/o/oauth2/token");

  my $response = Test::MockObject->new();
  $response->mock(is_success => sub { 1 });
  $response->mock(decoded_content => sub {
    return "{\n\"access_token\":\"123\"\n\"expires_in\":3920\n}"
  });

  return $response;
});

$handler->set_access_token(undef);
ok($handler->is_auth_enabled());
is($handler->get_access_token(), "123");
