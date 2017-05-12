#!/usr/bin/perl -w
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
# This example shows how to use the validate only header to check for errors.
# No objects will be created, but exceptions will still be returned.
#
# Tags: AdGroupAdService.mutate
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201402::AdGroupAd;
use Google::Ads::AdWords::v201402::AdGroupAdOperation;
use Google::Ads::AdWords::v201402::TextAd;

use Cwd qw(abs_path);

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";

# Example main subroutine.
sub validate_text_ad {
  my $client = shift;
  my $ad_group_id = shift;

  # Don't die on fault it will be handled in code.
  $client->set_die_on_faults(0);

  # Set validate only.
  $client->set_validate_only(1);

  # Create invalid text ad
  my $text_ad = Google::Ads::AdWords::v201402::TextAd->new({
    headline => "Luxury Cruise to Mars",
    description1 => "Visit the Red Planet in style.",
    description2 => "Low-gravity fun for all astronauts in orbit.",
    displayUrl => "www.example.com/cruises",
    url => "http://www.example.com"
  });
  my $text_ad_group_ad = Google::Ads::AdWords::v201402::AdGroupAd->new({
    adGroupId => $ad_group_id,
    ad => $text_ad
  });

  # Create operations.
  my $operation = Google::Ads::AdWords::v201402::AdGroupAdOperation->new({
    operand => $text_ad_group_ad,
    operator => "ADD"
  });

  # Validate text ad operation.
  my $result = $client->AdGroupAdService()->mutate({
    operations => [$operation]
  });
  if ($result->isa("SOAP::WSDL::SOAP::Typelib::Fault11")) {
    printf "Validation failed for reason: %s\n", $result->get_faultstring();
  } else {
    print "The ad is valid!\n";
  }

  return 1;
}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
  return 1;
}

# Log SOAP XML request, response and API errors.
Google::Ads::AdWords::Logging::enable_all_logging();

# Get AdWords Client, credentials will be read from ~/adwords.properties.
my $client = Google::Ads::AdWords::Client->new({version => "v201402"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
validate_text_ad($client, $ad_group_id);
