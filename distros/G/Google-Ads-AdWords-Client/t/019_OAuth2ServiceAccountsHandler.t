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

use strict;
use lib qw(lib t t/util);

use File::Basename;
use File::Spec;
use Test::More (tests => 31);
use Test::MockObject;
use TestClientUtils qw(get_test_client_no_auth);

use_ok("Google::Ads::AdWords::OAuth2ServiceAccountsHandler");

my $user_agent_mock   = Test::MockObject->new();
my $crypt_module_mock = Test::MockObject->new();

my $handler = Google::Ads::AdWords::OAuth2ServiceAccountsHandler->new({
    __user_agent   => $user_agent_mock,
    __crypt_module => $crypt_module_mock
});

my $client          = get_test_client_no_auth();
my $current_version = $client->get_version();

# Test defaults.
is_deeply($handler->_scope(), qw(https://www.googleapis.com/auth/adwords));
is($handler->_formatted_scopes(), "https://www.googleapis.com/auth/adwords");

##############################################################################
# PEM Authentication
##############################################################################
$handler->initialize(
  $client,
  {
    oAuth2ClientId                           => "client-id",
    oAuth2AccessToken                        => "access-token",
    oAuth2ServiceAccountEmailAddress         => "email",
    oAuth2ServiceAccountDelegateEmailAddress => "delegated-email",
    oAuth2ServiceAccountPEMFile              => "t/testdata/test-cert.pem",
    oAuth2AdditionalScopes => "https://www.googleapis.com/auth/analytics"
  });

# Test initialization.
is($handler->get_client_id(),               "client-id");
is($handler->get_email_address(),           "email");
is($handler->get_delegated_email_address(), "delegated-email");
is($handler->get_additional_scopes(),
  "https://www.googleapis.com/auth/analytics");
my @current_scope  = $handler->_scope();
my @expected_scope = qw(https://www.googleapis.com/auth/analytics
  https://www.googleapis.com/auth/adwords);
ok(eq_array(\@current_scope, \@expected_scope));
is($handler->_formatted_scopes(),
  "https://www.googleapis.com/auth/analytics," .
    "https://www.googleapis.com/auth/adwords");

# Test preset access token.
$user_agent_mock->mock(
  request => sub {
    my $response = HTTP::Response->new(200, "");
    $response->content(
      "{\n\"scope\":\"https://www.googleapis.com/auth/analytics " .
        "https://www.googleapis.com/auth/adwords\"\n\"expires_in\":" .
        (time + 1000) . "\n}");
    return $response;
  });

ok($handler->is_auth_enabled());
is($handler->get_access_token(), "access-token");
ok($handler->get_access_token_expires());

# Test access token generation.
$crypt_module_mock->mock(
  new_private_key => sub {
    my ($self, $file) = @_;

    my $key = Test::MockObject->new();
    $key->mock(use_pkcs1_padding => sub { 1 });
    $key->mock(use_sha256_hash   => sub { 1 });
    $key->mock(
      sign => sub {
        return "signed-claims";
      });

    return $key;
  });

$user_agent_mock->mock(
  request => sub {
    my ($self, $request) = @_;

    my $content_pattern =
      '^grant_type=urn:ietf:params:oauth:grant-type:jwt' .
      '-bearer&assertion=[A-Za-z0-9]+\.[A-Za-z0-9]+\.[A-Za-z0-9]+$';
    ok(
      $request->content =~ /$content_pattern/,
      "test valid JWT request content"
    );
    is($request->method, "POST");
    is($request->url,    "https://accounts.google.com/o/oauth2/token");

    my $response = Test::MockObject->new();
    $response->mock(is_success => sub { 1 });
    $response->mock(
      decoded_content => sub {
        return "{\n\"access_token\":\"123\"\n\"expires_in\":3920\n}";
      });

    return $response;
  });

$handler->set_access_token(undef);
ok($handler->is_auth_enabled());
is($handler->get_access_token(), "123");

##############################################################################
# JSON Authentication
##############################################################################
$handler = Google::Ads::AdWords::OAuth2ServiceAccountsHandler->new({
    __user_agent   => $user_agent_mock,
    __crypt_module => $crypt_module_mock
});

$handler->initialize(
  $client,
  {
    oAuth2ClientId                           => "client-id",
    oAuth2AccessToken                        => "access-token",
    oAuth2ServiceAccountDelegateEmailAddress => "delegated-email",
    oAuth2ServiceAccountJSONFile             => "t/testdata/test-cert.json",
    oAuth2AdditionalScopes => "https://www.googleapis.com/auth/analytics"
  });

# Test initialization.
is($handler->get_client_id(),               "client-id");
is($handler->get_email_address(),           undef);
is($handler->get_delegated_email_address(), "delegated-email");
is($handler->get_additional_scopes(),
  "https://www.googleapis.com/auth/analytics");
@current_scope  = $handler->_scope();
@expected_scope = qw(https://www.googleapis.com/auth/analytics
  https://www.googleapis.com/auth/adwords);
ok(eq_array(\@current_scope, \@expected_scope));
is($handler->_formatted_scopes(),
  "https://www.googleapis.com/auth/analytics," .
    "https://www.googleapis.com/auth/adwords");

# Test preset access token.
$user_agent_mock->mock(
  request => sub {
    my $response = HTTP::Response->new(200, "");
    $response->content(
      "{\n\"scope\":\"https://www.googleapis.com/auth/analytics " .
        "https://www.googleapis.com/auth/adwords\"\n\"expires_in\":" .
        (time + 1000) . "\n}");
    return $response;
  });

ok($handler->is_auth_enabled());
is($handler->get_access_token(), "access-token");
ok($handler->get_access_token_expires());

# Test access token generation.
$crypt_module_mock->mock(
  new_private_key => sub {
    my ($self, $file) = @_;

    my $key = Test::MockObject->new();
    $key->mock(use_pkcs1_padding => sub { 1 });
    $key->mock(use_sha256_hash   => sub { 1 });
    $key->mock(
      sign => sub {
        return "signed-claims";
      });

    return $key;
  });

$user_agent_mock->mock(
  request => sub {
    my ($self, $request) = @_;

    my $content_pattern =
      '^grant_type=urn:ietf:params:oauth:grant-type:jwt' .
      '-bearer&assertion=[A-Za-z0-9]+\.[A-Za-z0-9]+\.[A-Za-z0-9]+$';
    ok(
      $request->content =~ /$content_pattern/,
      "test valid JWT request content"
    );
    is($request->method, "POST");
    is($request->url,    "https://accounts.google.com/o/oauth2/token");

    my $response = Test::MockObject->new();
    $response->mock(is_success => sub { 1 });
    $response->mock(
      decoded_content => sub {
        return "{\n\"access_token\":\"123\"\n\"expires_in\":3920\n}";
      });

    return $response;
  });

$handler->set_access_token(undef);
ok($handler->is_auth_enabled());
is($handler->get_access_token(), "123");
