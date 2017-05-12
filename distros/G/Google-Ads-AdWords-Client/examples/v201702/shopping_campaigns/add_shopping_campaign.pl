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
# This example adds a Shopping campaign.

use strict;
use lib "../../../lib";
use utf8;

use Data::Uniqid qw(uniqid);

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201702::AdGroup;
use Google::Ads::AdWords::v201702::AdGroupAd;
use Google::Ads::AdWords::v201702::AdGroupAdOperation;
use Google::Ads::AdWords::v201702::AdGroupOperation;
use Google::Ads::AdWords::v201702::Campaign;
use Google::Ads::AdWords::v201702::CampaignOperation;
use Google::Ads::AdWords::v201702::BiddingStrategyConfiguration;
use Google::Ads::AdWords::v201702::Budget;
use Google::Ads::AdWords::v201702::ProductAd;
use Google::Ads::AdWords::v201702::ShoppingSetting;

use Cwd qw(abs_path);

# Replace with valid values of your account.
my $budget_id   = "INSERT_BUDGET_ID_HERE";
my $merchant_id = "INSERT_MERCHANT_CENTER_ID_HERE";

# Example main subroutine.
sub add_shopping_campaign {
  my ($client, $budget_id, $merchant_id) = @_;

  my $campaign = Google::Ads::AdWords::v201702::Campaign->new({
      name => "Shopping campaign #" . uniqid(),
      # The advertisingChannelType is what makes this a Shopping campaign
      advertisingChannelType => "SHOPPING",
      # Recommendation: Set the campaign to PAUSED when creating it to stop
      # the ads from immediately serving. Set to ENABLED once you've added
      # targeting and the ads are ready to serve.
      status => "PAUSED",
      # Set budget (required)
      budget =>
        Google::Ads::AdWords::v201702::Budget->new({budgetId => $budget_id}),
      # Set bidding strategy (required)
      biddingStrategyConfiguration =>
        Google::Ads::AdWords::v201702::BiddingStrategyConfiguration->new(
        {biddingStrategyType => "MANUAL_CPC"}
        ),
      # Set shopping setting (required)
      settings => [
        # All Shopping campaigns need a ShoppingSetting
        Google::Ads::AdWords::v201702::ShoppingSetting->new({
            salesCountry     => "US",
            campaignPriority => 0,
            merchantId       => $merchant_id,
            # By setting enableLocal to true (1) below, you will enable Local
            # Inventory Ads in your campaign. Set this to false (0) if you want
            # to disable this feature in your campaign.
            enableLocal => 1
          })]});

  # Create operation
  my $operation = Google::Ads::AdWords::v201702::CampaignOperation->new({
      operand  => $campaign,
      operator => "ADD"
  });

  # Make the mutate request
  my $result = $client->CampaignService()->mutate({operations => [$operation]});

  # Display result
  $campaign = $result->get_value()->[0];
  printf "Campaign name '%s' and ID %d was added.\n",
    $campaign->get_name(),
    $campaign->get_id();

  # Create ad group
  my $ad_group = Google::Ads::AdWords::v201702::AdGroup->new({
      campaignId => $campaign->get_id(),
      name       => "Ad Group #" . uniqid()});

  # Create operation
  $operation = Google::Ads::AdWords::v201702::AdGroupOperation->new({
      operand  => $ad_group,
      operator => "ADD"
  });

  # Make the mutate request
  $result = $client->AdGroupService()->mutate({operations => [$operation]});

  # Display result
  $ad_group = $result->get_value()->[0];
  printf "Ad group with name '%s' and ID %d was added.\n",
    $ad_group->get_name(),
    $ad_group->get_id();

  # Create product ad
  my $product_ad = Google::Ads::AdWords::v201702::ProductAd->new();

  # Create ad group ad
  my $ad_group_ad = Google::Ads::AdWords::v201702::AdGroupAd->new({
      adGroupId => $ad_group->get_id(),
      ad        => $product_ad
  });

  # Create operation
  $operation = Google::Ads::AdWords::v201702::AdGroupAdOperation->new({
      operand  => $ad_group_ad,
      operator => "ADD"
  });

  # Make the mutate request
  $result = $client->AdGroupAdService()->mutate({operations => [$operation]});

  # Display result
  $ad_group_ad = $result->get_value()->[0];
  printf "Product ad with ID %d was added.\n", $ad_group_ad->get_ad()->get_id();

  return 1;
}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
  return 1;
}

# Log SOAP XML request, response and API errors.
Google::Ads::AdWords::Logging::enable_all_logging();

# Get AdWords Client, credentials will be read from ~/adwords.properties.
my $client = Google::Ads::AdWords::Client->new({version => "v201702"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_shopping_campaign($client, $budget_id, $merchant_id);
