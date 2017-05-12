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
# This example adds a location ad extension to a campaign for a location
# obtained from the GeoLocationService. To get campaigns, run
# basic_operations/get_campaigns.pl.
#
# Tags: GeoLocationService.get, CampaignAdExtensionService.mutate
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201402::Address;
use Google::Ads::AdWords::v201402::CampaignAdExtension;
use Google::Ads::AdWords::v201402::CampaignAdExtensionOperation;
use Google::Ads::AdWords::v201402::GeoLocationSelector;
use Google::Ads::AdWords::v201402::LocationExtension;

use Cwd qw(abs_path);

# Replace with valid values of your account.
my $campaign_id = "INSERT_CAMPAIGN_ID_HERE";

# Example main subroutine.
sub add_location_extension {
  my $client = shift;
  my $campaign_id = shift;

  # Create address.
  my $address = Google::Ads::AdWords::v201402::Address->new({
    streetAddress => "1600 Amphitheatre Parkway",
    cityName => "Mountain View",
    provinceCode => "US-CA",
    postalCode => "94043",
    countryCode => "US"
  });

  # Create geo location selector.
  my $selector = Google::Ads::AdWords::v201402::GeoLocationSelector->new({
    addresses => [$address]
  });

  # Get geo location.
  my $geo_location = @{$client->GeoLocationService->get({
    selector => $selector
  })}[0];

  # Create location extension.
  my $location_extension =
      Google::Ads::AdWords::v201402::LocationExtension->new({
        address => $geo_location->get_address(),
        geoPoint => $geo_location->get_geoPoint(),
        encodedLocation => $geo_location->get_encodedLocation(),
        source => "ADWORDS_FRONTEND",
        # Additional properties (non-required).
        companyName => "Google",
        phoneNumber => "650-253-0000"
      });

  # Create campaign location ad extension.
  my $campaign_location_ad_extension =
      Google::Ads::AdWords::v201402::CampaignAdExtension->new({
        campaignId => $campaign_id,
        adExtension => $location_extension
      });

  # Create operation.
  my $operation =
      Google::Ads::AdWords::v201402::CampaignAdExtensionOperation->new({
        operand => $campaign_location_ad_extension,
        operator => "ADD"
      });

  # Add campaign ad extension.
  my $result = $client->CampaignAdExtensionService()->mutate({
    operations => [$operation]
  });

  # Display campaign ad extension.
  if ($result->get_value()) {
    my $campaign_ad_extension = $result->get_value()->[0];
    printf "Campaign location extension with campaign id \"%d\", id \"%d\", " .
           "and type \"%s\" was added.\n",
           $campaign_ad_extension->get_campaignId(),
           $campaign_ad_extension->get_adExtension()->get_id(),
           $campaign_ad_extension->get_adExtension()->get_AdExtension__Type();
  } else {
    print "No campaign ad extension was added.";
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
add_location_extension($client, $campaign_id);
