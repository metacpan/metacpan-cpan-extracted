#!/usr/bin/perl
#
# Copyright 2011, Google Inc. All Rights Reserved.
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
# Unit tests for the Google::Ads::AdWords::Serializer module.

use strict;
use lib qw(t/util);

use File::Basename;
use File::Spec;
use Test::Deep;
use Test::MockObject;
use Test::More (tests => 7);
use TestClientUtils qw(get_test_client_no_auth);
use TestUtils qw(read_test_properties read_client_properties
  replace_properties);
use XML::Simple;

use_ok("Google::Ads::AdWords::Client");
use_ok("Google::Ads::AdWords::Serializer");

my $client = get_test_client_no_auth();
$client->get_oauth_2_handler()->set_access_token("test-auth-token");

my $current_version   = $client->get_version();
my $client_properties = read_client_properties()->{properties};
$client_properties->{version}    = $current_version;
$client_properties->{libVersion} = ${Google::Ads::AdWords::Client::VERSION};

use_ok("Google::Ads::AdWords::${current_version}::Selector");
use_ok("Google::Ads::AdWords::${current_version}::CampaignService::get");
use_ok("Google::Ads::AdWords::${current_version}::CampaignService::" .
    "RequestHeader");

my $serializer = Google::Ads::AdWords::Serializer->new({client => $client});

my $header =
  "Google::Ads::AdWords::${current_version}::CampaignService::RequestHeader"
  ->new();

my $body =
  "Google::Ads::AdWords::${current_version}::CampaignService::get"->new({
    serviceSelector =>
      "Google::Ads::AdWords::${current_version}::Selector"->new()});

my $logger = Test::MockObject->new();
my $logged_message;
$client->set_always("_get_auth_handler",
  Google::Ads::Common::OAuth2ApplicationsHandler->new());
$logger->set_always('info', 1);
$logger->mock(
  'warn',
  sub {
    $logged_message = $_[1];
  });
no warnings 'redefine';
*Google::Ads::AdWords::Logging::get_soap_logger = sub {
  return $logger;
};

my $envelope = $serializer->serialize({
    method => "get",
    header => $header,
    body   => $body
});

my $properties      = read_test_properties();
my $expected_output = "";
$expected_output = $properties->getProperty("serializer_expected_output_cid");

# Set the application name to the default if not provided.
# Verify that it is ASCII.
my $application_name =
      ($client->get_user_agent()
        && ($client->get_user_agent() ne "INSERT_USER_AGENT_HERE")
      ? $client->get_user_agent()
      : Google::Ads::AdWords::Constants::DEFAULT_USER_AGENT);
if ($application_name =~ /[[:^ascii:]]/) {
  my $error_message = sprintf(
    "userAgent [%s] in client must be ASCII.", $application_name);
  die($error_message);
}

my $user_agent = sprintf(
  "%s (AwApi-Perl/%s, Common-Perl/%s, SOAP-WSDL/%s, " .
    "libwww-perl/%s, perl/%s, Logging/Disabled)",
  $application_name,
  ${Google::Ads::AdWords::Constants::VERSION},
  ${Google::Ads::Common::Constants::VERSION},
  ${SOAP::WSDL::VERSION},
  ${LWP::UserAgent::VERSION},
  $]
);
$client_properties->{userAgent} = $user_agent;
$expected_output = replace_properties($expected_output, $client_properties);

# Convert actual and expected output to hashes and compare deeply.
cmp_deeply(
  XML::Simple->new()->XMLin($envelope,        ForceContent => 1),
  XML::Simple->new()->XMLin($expected_output, ForceContent => 1),
  "check serializer output"
);

# Test error propagation when invalid nested structure is given.
# Issue #58, http://goo.gl/mZkw6z
eval {
  "Google::Ads::AdWords::${current_version}::CampaignService::get"
    ->new({serviceSelector => {invalid_field => 1}});
};
isnt($@, "", "check error propagation on invalid nested objects contruction");
