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
# Unit tests for the Google::Ads::AdWords::AuthTokenHandler module.
#
# Author: David Torres <david.t@google.com>

use strict;
use lib qw(t/util lib);

use File::Basename;
use File::Spec;
use HTTP::Response;
use Test::More (tests => 27);
use Test::MockObject;
use TestClientUtils qw(get_test_client_no_auth);
use URI::Escape;

use_ok("Google::Ads::AdWords::AuthTokenHandler");

my $user_agent_mock = Test::MockObject->new();

my $auth_token_handler = new Google::Ads::AdWords::AuthTokenHandler({
  __user_agent => $user_agent_mock,
});
$user_agent_mock->mock(env_proxy => "");
$user_agent_mock->mock(agent => sub { return ""; });

# Test the proper service is provisioned.
is($auth_token_handler->_service, "adwords");

# Test custom setter.
$auth_token_handler->set_auth_token("token");
is($auth_token_handler->get_auth_token(), "token");
ok(!$auth_token_handler->get_issued_in());

$auth_token_handler->set_email("email");
is($auth_token_handler->get_email(), "email");
ok(!$auth_token_handler->get_auth_token());
ok(!$auth_token_handler->get_issued_in());

$auth_token_handler->set_password("pass");
is($auth_token_handler->get_password(), "pass");
ok(!$auth_token_handler->get_auth_token());
ok(!$auth_token_handler->get_issued_in());

# Test no initialization error.
$auth_token_handler->set_email(undef);
my $error = $auth_token_handler->issue_new_token();
isa_ok($error, "Google::Ads::Common::AuthError");
like($error->get_message(),
     qr/Required '.*' not available, handler not properly initiliazed?/);

my $client = get_test_client_no_auth();
my $current_version = $client->get_version();

$auth_token_handler->initialize($client, {
  email => "user\@domain.com",
  password => "123"
});

# Test bad authentication error.
$user_agent_mock->mock(request => sub {
  my $response = HTTP::Response->new(403, "Forbidden (code 403)");
  $response->content("Error=BadAuthentication");
  return $response;
});

$error = $auth_token_handler->issue_new_token();
isa_ok($error, "Google::Ads::Common::AuthError", "Authentication error");
is($error->get_code(), 403, "Error 403 code");
is($error->get_message(), "Forbidden (code 403)", "Error message");
is($error->get_content(), "Error=BadAuthentication", "Error content");

# Test captcha error.
$user_agent_mock->mock(request => sub {
  my $response = HTTP::Response->new(403, "Forbidden (code 403)");
  $response->content("Error=CaptchaRequired\nCaptchaToken=123\nCaptchaUrl=" .
                     "captcha_image_url\nUrl=url");
  return $response;
});
$error = $auth_token_handler->issue_new_token();
isa_ok($error, "Google::Ads::Common::CaptchaRequiredError", "Captcha error");
is($error->get_token(), "123", "Captcha token");
is($error->get_image(),
   "https://www.google.com/accounts/captcha_image_url",
   "Captcha image");
is($error->get_url(), "url", "Captcha URL");

# Test correct request.
$user_agent_mock->mock(request => sub {
  my ($self, $request) = @_;

  is($request->content_type, "application/x-www-form-urlencoded");
  is($request->content, "accountType=GOOGLE&Email=user%40domain.com&" .
                        "Passwd=123&service=adwords");

  my $response = HTTP::Response->new(200, "");
  $response->content("Auth=AuthToken");
  return $response;
});
$error = $auth_token_handler->issue_new_token();
ok(!$error);
is($auth_token_handler->get_auth_token(), "AuthToken");
ok($auth_token_handler->get_issued_in());

my $request = $auth_token_handler->prepare_request("http://google.com",
    [test_header => "header-value"],
    "<RequestHeader xmlns=\"\"></RequestHeader>");

my $xmlns = "https://adwords.google.com/api/adwords/cm/" .
    $client->get_version();
is($request->method, "POST");
is($request->content,
   "<RequestHeader xmlns=\"\"><authToken xmlns=\"$xmlns\">AuthToken" .
   "</authToken></RequestHeader>");
