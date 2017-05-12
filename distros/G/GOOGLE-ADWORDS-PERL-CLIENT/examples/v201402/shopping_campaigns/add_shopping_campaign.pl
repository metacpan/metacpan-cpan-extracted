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
# This example adds a Shopping campaign.
#
# Tags: CampaignService.mutate
# Author: Josh Radcliff <api.jradcliff@gmail.com>

use strict;
use lib "../../../lib";

use Data::Uniqid qw(uniqid);

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201402::AdGroup;
use Google::Ads::AdWords::v201402::AdGroupAd;
use Google::Ads::AdWords::v201402::AdGroupAdOperation;
use Google::Ads::AdWords::v201402::AdGroupOperation;
use Google::Ads::AdWords::v201402::Campaign;
use Google::Ads::AdWords::v201402::CampaignOperation;
use Google::Ads::AdWords::v201402::BiddingStrategyConfiguration;
use Google::Ads::AdWords::v201402::Budget;
use Google::Ads::AdWords::v201402::KeywordMatchSetting;
use Google::Ads::AdWords::v201402::ProductAd;
use Google::Ads::AdWords::v201402::ShoppingSetting;

use Cwd qw(abs_path);

# Replace with valid values of your account.
my $budget_id = "INSERT_BUDGET_ID_HERE";
my $merchant_id = "INSERT_MERCHANT_CENTER_ID_HERE";

# Example main subroutine.
sub add_shopping_campaign_example {
  my $client = shift;

  my $campaign = Google::Ads::AdWords::v201402::Campaign->new({
    name => "Shopping campaign #" . uniqid(),
    # The advertisingChannelType is what makes this a Shopping campaign
    advertisingChannelType => "SHOPPING",
    # Set shared budget (required)
    budget => Google::Ads::AdWords::v201402::Budget->new({
      budgetId => $budget_id
    }),
    # Set bidding strategy (required)
    biddingStrategyConfiguration =>
      Google::Ads::AdWords::v201402::BiddingStrategyConfiguration->new({
        biddingStrategyType => "MANUAL_CPC"
    }),
    # Set keyword matching setting (required)
    settings => [
      Google::Ads::AdWords::v201402::KeywordMatchSetting->new({
        optIn => 0
      }),
      # All Shopping campaigns need a ShoppingSetting
      Google::Ads::AdWords::v201402::ShoppingSetting->new({
        salesCountry => "US",
        campaignPriority => 0,
        merchantId => $merchant_id
      })
    ]
  });

  # Create operation
  my $operation = Google::Ads::AdWords::v201402::CampaignOperation->new({
    operand => $campaign,
    operator => "ADD"
  });

  # Make the mutate request
  my $result = $client->CampaignService()->mutate({
    operations => [ $operation ]
  });

  # Display result
  $campaign = $result->get_value()->[0];
  printf "Campaign name '%s' and ID %d was added.\n",
    $campaign->get_name(),
    $campaign->get_id();

  # Create ad group
  my $ad_group = Google::Ads::AdWords::v201402::AdGroup->new({
    campaignId => $campaign->get_id(),
    name => "Ad Group #" . uniqid()
  });

  # Create operation
  $operation = Google::Ads::AdWords::v201402::AdGroupOperation->new({
    operand => $ad_group,
    operator => "ADD"
  });

  # Make the mutate request
  $result = $client->AdGroupService()->mutate({
    operations => [ $operation ]
  });

  # Display result
  $ad_group = $result->get_value()->[0];
  printf "Ad group with name '%s' and ID %d was added.\n",
    $ad_group->get_name(),
    $ad_group->get_id();

  # Create product ad
  my $product_ad = Google::Ads::AdWords::v201402::ProductAd->new();

  # Create ad group ad
  my $ad_group_ad = Google::Ads::AdWords::v201402::AdGroupAd->new({
    adGroupId => $ad_group->get_id(),
    ad => $product_ad
  });

  # Create operation
  $operation = Google::Ads::AdWords::v201402::AdGroupAdOperation->new({
    operand => $ad_group_ad,
    operator => "ADD"
  });

  # Make the mutate request
  $result = $client->AdGroupAdService()->mutate({
    operations => [ $operation ]
  });

  # Display result
  $ad_group_ad = $result->get_value()->[0];
  printf "Product ad with ID %d was added.\n",
    $ad_group_ad->get_ad()->get_id();

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
add_shopping_campaign_example($client, $budget_id, $merchant_id);
