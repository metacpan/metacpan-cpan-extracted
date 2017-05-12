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
# Unit tests for the Google::Ads::AdWords::OAuth2ApplicationsHandler module.
#
# Author: David Torres <david.t@google.com>

use strict;
use lib qw(lib t t/util);

use File::Basename;
use File::Spec;
use Test::More (tests => 26);
use Test::MockObject;
use TestClientUtils qw(get_test_client_no_auth);

use_ok("Google::Ads::AdWords::OAuth2ApplicationsHandler");

my $user_agent_mock = Test::MockObject->new();

my $handler = Google::Ads::AdWords::OAuth2ApplicationsHandler->new({
  __user_agent => $user_agent_mock
});

my $client = get_test_client_no_auth();
my $current_version = $client->get_version();

ok(!$handler->is_auth_enabled());

# Test defaults.
is($handler->get_access_type(), "offline");
is($handler->get_approval_prompt(), "auto");
is($handler->get_redirect_uri(), "urn:ietf:wg:oauth:2.0:oob");
is($handler->_scope(), "https://adwords.google.com/api/adwords/");

$handler->initialize($client, {
  oAuth2ClientId => "client-id",
  oAuth2ClientSecret => "client-secret",
  oAuth2AccessType => "access-type",
  oAuth2ApprovalPrompt => "approval-prompt",
  oAuth2AccessToken => "access-token",
  oAuth2RefreshToken => "refresh-token",
  oAuth2RedirectUri => "uri"
});

$user_agent_mock->mock(request => sub {
  my $response = HTTP::Response->new(200, "");
  $response->content("{\n\"scope\":\"https://adwords.google.com/api/" .
                     "adwords/\"\n\"expires_in\":" . (time + 1000) . "\n}");

  return $response;
});

# Test initialization.
ok($handler->is_auth_enabled());
is($handler->get_client_id(), "client-id");
is($handler->get_client_secret(), "client-secret");
is($handler->get_access_type(), "access-type");
is($handler->get_approval_prompt(), "approval-prompt");
is($handler->get_access_token(), "access-token");
is($handler->get_refresh_token(), "refresh-token");
is($handler->get_redirect_uri(), "uri");
ok($handler->get_access_token_expires());

# Test OAuth2 Flow methods
is($handler->get_authorization_url("state"),
   "https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=" .
   "client-id&redirect_uri=uri&scope=https%3A%2F%2Fadwords.google.com%2Fapi" .
   "%2Fadwords%2F&access_type=access-type&approval_prompt=approval-prompt&" .
   "state=state");

$user_agent_mock->mock(request => sub {
  my ($self, $request) = @_;

  is($request->content,
     "code=code&client_id=client-id&client_secret=client-secret&redirect_uri=" .
     "uri&grant_type=authorization_code");
  is($request->method, "POST");
  is($request->url, "https://accounts.google.com/o/oauth2/token");

  my $response = Test::MockObject->new();
  $response->mock(is_success => sub { 0 });
  $response->mock(decoded_content =>
                  sub { return "{\n\"error\":\"invalid_request\"\n}" });

  return $response;
});

is($handler->issue_access_token("code"), "{\n\"error\":\"invalid_request\"\n}");

$user_agent_mock->mock(request => sub {
  my ($self, $request) = @_;

  is($request->content,
     "code=code&client_id=client-id&client_secret=client-secret&redirect_uri=" .
     "uri&grant_type=authorization_code");
  is($request->method, "POST");
  is($request->url, "https://accounts.google.com/o/oauth2/token");

  my $response = Test::MockObject->new();
  $response->mock(is_success => sub { 1 });
  $response->mock(decoded_content => sub {
    return "{\n\"access_token\":\"123\"\n\"expires_in\":3920\n" .
           "\"refresh_token\":\"345\"\n}"
  });

  return $response;
});

ok(!$handler->issue_access_token("code"));
is($handler->get_access_token(), "123");
is($handler->get_refresh_token(), "345");
