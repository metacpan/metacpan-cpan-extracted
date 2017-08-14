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
use Google::Ads::AdWords::v201708::AdGroup;
use Google::Ads::AdWords::v201708::AdGroupAd;
use Google::Ads::AdWords::v201708::AdGroupAdOperation;
use Google::Ads::AdWords::v201708::AdGroupCriterionOperation;
use Google::Ads::AdWords::v201708::AdGroupOperation;
use Google::Ads::AdWords::v201708::BiddableAdGroupCriterion;
use Google::Ads::AdWords::v201708::BiddingStrategyConfiguration;
use Google::Ads::AdWords::v201708::Budget;
use Google::Ads::AdWords::v201708::Campaign;
use Google::Ads::AdWords::v201708::CampaignOperation;
use Google::Ads::AdWords::v201708::CpcBid;
use Google::Ads::AdWords::v201708::ProductAd;
use Google::Ads::AdWords::v201708::ProductPartition;
use Google::Ads::AdWords::v201708::ShoppingSetting;

use Cwd qw(abs_path);

# Replace with valid values of your account.
my $budget_id   = "INSERT_BUDGET_ID_HERE";
my $merchant_id = "INSERT_MERCHANT_CENTER_ID_HERE";
# If set to true (1), a default partition will be created. If running the
# add_product_partition_tree.pl example right after this example,
# make sure this stays set to false (0).
my $create_default_partition = 0;

# Example main subroutine.
sub add_shopping_campaign {
  my ($client, $budget_id, $merchant_id, $create_default_partition) = @_;

  my $campaign = Google::Ads::AdWords::v201708::Campaign->new({
      name => "Shopping campaign #" . uniqid(),
      # The advertisingChannelType is what makes this a Shopping campaign
      advertisingChannelType => "SHOPPING",
      # Recommendation: Set the campaign to PAUSED when creating it to stop
      # the ads from immediately serving. Set to ENABLED once you've added
      # targeting and the ads are ready to serve.
      status => "PAUSED",
      # Set budget (required)
      budget =>
        Google::Ads::AdWords::v201708::Budget->new({budgetId => $budget_id}),
      # Set bidding strategy (required)
      biddingStrategyConfiguration =>
        Google::Ads::AdWords::v201708::BiddingStrategyConfiguration->new(
        {biddingStrategyType => "MANUAL_CPC"}
        ),
      # Set shopping setting (required)
      settings => [
        # All Shopping campaigns need a ShoppingSetting
        Google::Ads::AdWords::v201708::ShoppingSetting->new({
            salesCountry     => "US",
            campaignPriority => 0,
            merchantId       => $merchant_id,
            # By setting enableLocal to true (1) below, you will enable Local
            # Inventory Ads in your campaign. Set this to false (0) if you want
            # to disable this feature in your campaign.
            enableLocal => 1
          })]});

  # Create operation
  my $operation = Google::Ads::AdWords::v201708::CampaignOperation->new({
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
  my $ad_group = Google::Ads::AdWords::v201708::AdGroup->new({
      campaignId => $campaign->get_id(),
      name       => "Ad Group #" . uniqid()});

  # Create operation
  $operation = Google::Ads::AdWords::v201708::AdGroupOperation->new({
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
  my $product_ad = Google::Ads::AdWords::v201708::ProductAd->new();

  # Create ad group ad
  my $ad_group_ad = Google::Ads::AdWords::v201708::AdGroupAd->new({
    adGroupId => $ad_group->get_id(),
    ad        => $product_ad
  });

  # Create operation
  $operation = Google::Ads::AdWords::v201708::AdGroupAdOperation->new({
    operand  => $ad_group_ad,
    operator => "ADD"
  });

  # Make the mutate request
  $result = $client->AdGroupAdService()->mutate({operations => [$operation]});

  # Display result
  $ad_group_ad = $result->get_value()->[0];
  printf "Product ad with ID %d was added.\n", $ad_group_ad->get_ad()->get_id();

  if ($create_default_partition) {
    # Create an ad group criterion for 'All products'.
    my $product_partition =
      Google::Ads::AdWords::v201708::ProductPartition->new({
        partitionType => 'UNIT',
        # Make sure the caseValue is null and the parentCriterionId is null.
        caseValue         => undef,
        parentCriterionId => undef
      });

    my $ad_group_criterion =
      Google::Ads::AdWords::v201708::BiddableAdGroupCriterion->new({
        adGroupId => $ad_group->get_id(),
        criterion => $product_partition,
        biddingStrategyConfiguration =>
          Google::Ads::AdWords::v201708::BiddingStrategyConfiguration->new({
            bids => [
              Google::Ads::AdWords::v201708::CpcBid->new({
                  bid => Google::Ads::AdWords::v201708::Money->new(
                    {microAmount => 500000})}
              ),
            ]})});

    # Create operation.
    $operation = Google::Ads::AdWords::v201708::AdGroupCriterionOperation->new({
      operator => "ADD",
      operand  => $ad_group_criterion
    });

    # Make the mutate request
    $result =
      $client->AdGroupCriterionService()->mutate({operations => [$operation]});

    # Display result
    $ad_group_criterion = $result->get_value()->[0];
    printf "Ad group criterion with ID %d in ad group with ID %d was added.\n",
      $ad_group_criterion->get_criterion()->get_id(),
      $ad_group_criterion->get_adGroupId();
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
add_shopping_campaign($client, $budget_id, $merchant_id,
  $create_default_partition);
