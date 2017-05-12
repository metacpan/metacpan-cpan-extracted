#!/usr/bin/perl
#
# Copyright 2013, Google Inc. All Rights Reserved.
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
# Unit tests for the examples/OAuth/generate_offline_credentials.pl script.

use strict;
use lib qw(lib t t/util);

use Google::Ads::AdWords::Client;

use Test::MockObject;
use Test::More (tests => 15);

# Setting up the test and mocks
my $oauth2_handler_mock = Test::MockObject->new();

my $client = Google::Ads::AdWords::Client->new();
$client->get_auth_handlers()
  ->{Google::Ads::AdWords::Client::OAUTH_2_APPLICATIONS_HANDLER} =
  $oauth2_handler_mock;

my $client_id;
my $client_secret;
my $access_token;
my $refresh_token;
$oauth2_handler_mock->set_always("get_client_id",         "client_id");
$oauth2_handler_mock->set_always("get_client_secret",     "client_secret");
$oauth2_handler_mock->set_false("issue_access_token");
$oauth2_handler_mock->set_always("get_access_token",      "access_token");
$oauth2_handler_mock->set_always("get_refresh_token",     "refresh_token");
$oauth2_handler_mock->set_always("get_authorization_url", "auth_url");

# Faking STDOUT and IN
close STDIN;
open(STDIN, "<", \" confirmation_code \n");
close STDOUT;
my $stdout;
open(STDOUT, ">", \$stdout);

# Calling the offline credentials code
require qw(examples/oauth/generate_offline_credentials.pl);
ok(generate_offline_credentials($client));

# Checking the auth mock was correctly called
$oauth2_handler_mock->called_ok("get_client_id");
$oauth2_handler_mock->called_ok("get_client_secret");
$oauth2_handler_mock->called_ok("issue_access_token");
is($oauth2_handler_mock->call_args_pos(4, 2), "confirmation_code");
$oauth2_handler_mock->called_ok("get_access_token");
$oauth2_handler_mock->called_ok("get_refresh_token");

# Checking the code printed out correctly what was expected
ok($stdout =~ /oAuth2ClientId=client_id/);
ok($stdout =~ /oAuth2ClientSecret=client_secret/);
ok($stdout =~ /oAuth2AccessToken=access_token/);
ok($stdout =~ /oAuth2RefreshToken=refresh_token/);
ok($stdout =~
    /\$client->get_oauth_2_handler\(\)->set_client_id\('client_id'\);/);
ok($stdout =~
    /\$client->get_oauth_2_handler\(\)->set_client_secret\('client_secret'\);/);
ok($stdout =~
    /\$client->get_oauth_2_handler\(\)->set_access_token\('access_token'\);/);
ok($stdout =~
    /\$client->get_oauth_2_handler\(\)->set_refresh_token\('refresh_token'\);/);
