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
# Unit tests for the Google::Ads::AdWords::RequestStats module and stats
# aggregation at the Google::Ads::AdWords::Client.
#
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib qw(t/util lib);

use File::Basename;
use File::Spec;
use Test::More (tests => 21);
use TestClientUtils qw(get_test_client_no_auth);
use TestUtils qw(read_test_properties replace_properties);

use_ok("Google::Ads::AdWords::Client");
use_ok("Google::Ads::AdWords::Deserializer");

my $client = get_test_client_no_auth();
my $current_version = $client->get_version();

use_ok("Google::Ads::AdWords::${current_version}::TypeMaps::CampaignService");

my $deserializer = Google::Ads::AdWords::Deserializer->new({
  client => $client,
  class_resolver =>
      "Google::Ads::AdWords::${current_version}::TypeMaps::CampaignService",
  strict => "1"
});

my $properties = read_test_properties();
my $deserializer_input = $properties->getProperty("deserializer_input");
$deserializer_input = replace_properties($deserializer_input,
                                         {version => $client->get_version()});
my $deserializer_fault_input =
    $properties->getProperty("deserializer_fault_input");
$deserializer_fault_input = replace_properties(
    $deserializer_fault_input, {version => $client->get_version()});

my @results = $deserializer->deserialize($deserializer_input);

is($client->get_last_request_stats()->get_service_name(), "CampaignService");
is($client->get_last_request_stats()->get_method_name(), "get");
is($client->get_last_request_stats()->get_response_time(), 442);
is($client->get_last_request_stats()->get_request_id(),
    "cb09bce743f82da6de62ea4dcf18a9a8");
is($client->get_last_request_stats()->get_operations(), 2);
is($client->get_last_request_stats()->get_is_fault(), "");

is($client->get_requests_count(), 1);
is($client->get_operations_count(), 2);
is($client->get_failed_requests_count(), 0);

@results = $deserializer->deserialize($deserializer_fault_input);

is($client->get_last_request_stats()->get_service_name(), "CampaignService");
is($client->get_last_request_stats()->get_method_name(), "get");
is($client->get_last_request_stats()->get_response_time(), 2429);
is($client->get_last_request_stats()->get_request_id(),
    "07a93c67b1dd3ff5242c98d436ba7043");
is($client->get_last_request_stats()->get_operations(), 1);
is($client->get_last_request_stats()->get_is_fault(), 1);

is($client->get_requests_count(), 2);
is($client->get_operations_count(), 3);
is($client->get_failed_requests_count(), 1);
