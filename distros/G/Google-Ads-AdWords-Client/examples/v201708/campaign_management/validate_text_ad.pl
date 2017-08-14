#!/usr/bin/perl -w
#
# Copyright 2017, Google Inc. All Rights Reserved.
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

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201708::AdGroupAd;
use Google::Ads::AdWords::v201708::AdGroupAdOperation;
use Google::Ads::AdWords::v201708::ExpandedTextAd;

use Cwd qw(abs_path);

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";

# Example main subroutine.
sub validate_text_ad {
  my $client      = shift;
  my $ad_group_id = shift;

  # Don't die on fault it will be handled in code.
  $client->set_die_on_faults(0);

  # Set validate only.
  $client->set_validate_only(1);

  # Create invalid expanded text ad
  my $text_ad = Google::Ads::AdWords::v201708::ExpandedTextAd->new({
      headlinePart1 => "Luxury Cruise to Mars",
      headlinePart2 => "Visit the Red Planet in style.",
      description   => "Low-gravity fun for all astronauts in orbit.",
      finalUrls     => ["http://www.example.com"]});
  my $text_ad_group_ad = Google::Ads::AdWords::v201708::AdGroupAd->new({
    adGroupId => $ad_group_id,
    ad        => $text_ad
  });

  # Create operations.
  my $operation = Google::Ads::AdWords::v201708::AdGroupAdOperation->new({
    operand  => $text_ad_group_ad,
    operator => "ADD"
  });

  # Validate text ad operation.
  my $result =
    $client->AdGroupAdService()->mutate({operations => [$operation]});
  if (defined($result) and $result->isa("SOAP::WSDL::SOAP::Typelib::Fault11")) {
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
my $client = Google::Ads::AdWords::Client->new({version => "v201708"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
validate_text_ad($client, $ad_group_id);
