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
# Unit tests for the Google::Ads::AdWords::Deserializer module.
#
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib qw(t/util);

use File::Basename;
use File::Spec;
use Test::More (tests => 12);
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

# Test we can deserialize a regular response.
my $properties = read_test_properties();
my $deserializer_input = $properties->getProperty ("deserializer_input");
$deserializer_input = replace_properties($deserializer_input,
                                         {version => $client->get_version()});

my @results = $deserializer->deserialize($deserializer_input);

isa_ok($results[0],
       "Google::Ads::AdWords::${current_version}::CampaignPage",
       "test return value");

# Test we can deserialize a policy violation error response from ad group
# criterion service.
use_ok("Google::Ads::AdWords::${current_version}::TypeMaps::AdGroupCriterionService");

$deserializer = Google::Ads::AdWords::Deserializer->new({
  client => $client,
  class_resolver =>
      "Google::Ads::AdWords::${current_version}::TypeMaps::AdGroupCriterionService",
  strict => "1"
});

$deserializer_input =
    $properties->getProperty("deserializer_policy_violation_input");
$deserializer_input = replace_properties($deserializer_input,
                                         {version => $client->get_version()});

@results = $deserializer->deserialize($deserializer_input);

isa_ok($results[0], "SOAP::WSDL::SOAP::Typelib::Fault11");
isa_ok($results[0]->get_detail(), "Google::Ads::AdWords::FaultDetail");
isa_ok($results[0]->get_detail()->get_ApiExceptionFault(),
       "Google::Ads::AdWords::${current_version}::ApiException");

# Test we can deserialize a policy violation error response from mutate job
# service.
use_ok("Google::Ads::AdWords::${current_version}::TypeMaps::MutateJobService");

$deserializer = Google::Ads::AdWords::Deserializer->new({
  client => $client,
  class_resolver =>
      "Google::Ads::AdWords::${current_version}::TypeMaps::MutateJobService",
  strict => "1"
});

$deserializer_input =
    $properties->getProperty("deserializer_policy_violation_bulk_mutate_input");
$deserializer_input = replace_properties($deserializer_input,
                                         {version => $client->get_version()});

@results = $deserializer->deserialize($deserializer_input);

isa_ok($results[0], "SOAP::WSDL::SOAP::Typelib::Fault11");
isa_ok($results[0]->get_detail(), "Google::Ads::AdWords::FaultDetail");
isa_ok($results[0]->get_detail()->get_ApiExceptionFault(),
       "Google::Ads::AdWords::${current_version}::ApiException");
