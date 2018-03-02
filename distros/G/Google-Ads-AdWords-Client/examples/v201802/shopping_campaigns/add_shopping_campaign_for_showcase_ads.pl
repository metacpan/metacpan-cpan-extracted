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
# This example adds a Shopping campaign for Showcase ads.

use strict;
use lib "../../../lib";
use utf8;

use Data::Uniqid qw(uniqid);

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201802::AdGroup;
use Google::Ads::AdWords::v201802::AdGroupAd;
use Google::Ads::AdWords::v201802::AdGroupAdOperation;
use Google::Ads::AdWords::v201802::AdGroupCriterionOperation;
use Google::Ads::AdWords::v201802::AdGroupOperation;
use Google::Ads::AdWords::v201802::BiddableAdGroupCriterion;
use Google::Ads::AdWords::v201802::Campaign;
use Google::Ads::AdWords::v201802::CampaignOperation;
use Google::Ads::AdWords::v201802::CpcBid;
use Google::Ads::AdWords::v201802::BiddingStrategyConfiguration;
use Google::Ads::AdWords::v201802::Budget;
use Google::Ads::AdWords::v201802::Image;
use Google::Ads::AdWords::v201802::Money;
use Google::Ads::AdWords::v201802::NegativeAdGroupCriterion;
use Google::Ads::AdWords::v201802::ProductCanonicalCondition;
use Google::Ads::AdWords::v201802::ProductPartition;
use Google::Ads::AdWords::v201802::ShoppingSetting;
use Google::Ads::AdWords::v201802::ShowcaseAd;
use Google::Ads::Common::MediaUtils;

use Cwd qw(abs_path);

# Replace with valid values of your account.
my $budget_id   = "INSERT_BUDGET_ID_HERE";
my $merchant_id = "INSERT_MERCHANT_CENTER_ID_HERE";

# Example main subroutine.
sub add_shopping_campaign_for_showcase_ads {
  my ($client, $budget_id, $merchant_id) = @_;

  my $campaign = _create_campaign($client, $budget_id, $merchant_id);
  printf "Campaign name '%s' and ID %d was added.\n",
    $campaign->get_name(),
    $campaign->get_id();

  my $ad_group = _create_ad_group($client, $campaign);
  printf "Ad group with name '%s' and ID %d was added.\n",
    $ad_group->get_name(),
    $ad_group->get_id();

  my $ad_group_ad = _create_showcase_ad($client, $ad_group);
  printf "Showcase ad with ID %d was added.\n",
    $ad_group_ad->get_ad()->get_id();

  my $ad_group_criterion =
    _create_product_partitions($client, $ad_group->get_id());
  printf "Product partition tree with %s nodes was added.\n",
    scalar @{$ad_group_criterion};

  return 1;
}

# Creates a shopping campaign.
sub _create_campaign {
  my ($client, $budget_id, $merchant_id) = @_;

  my $campaign = Google::Ads::AdWords::v201802::Campaign->new({
      name => "Shopping campaign #" . uniqid(),
      # The advertisingChannelType is what makes this a Shopping campaign
      advertisingChannelType => "SHOPPING",
      # Recommendation: Set the campaign to PAUSED when creating it to stop
      # the ads from immediately serving. Set to ENABLED once you've added
      # targeting and the ads are ready to serve.
      status => "PAUSED",
      # Set budget (required)
      budget =>
        Google::Ads::AdWords::v201802::Budget->new({budgetId => $budget_id}),
      # Set bidding strategy (required)
      biddingStrategyConfiguration =>
        Google::Ads::AdWords::v201802::BiddingStrategyConfiguration->new(
        {biddingStrategyType => "MANUAL_CPC"}
        ),
      # Set shopping setting (required)
      settings => [
        # All Shopping campaigns need a ShoppingSetting
        Google::Ads::AdWords::v201802::ShoppingSetting->new({
            salesCountry     => "US",
            campaignPriority => 0,
            merchantId       => $merchant_id,
            # By setting enableLocal to true (1) below, you will enable Local
            # Inventory Ads in your campaign. Set this to false (0) if you want
            # to disable this feature in your campaign.
            enableLocal => 1
          })]});

  # Create operation
  my $operation = Google::Ads::AdWords::v201802::CampaignOperation->new({
    operand  => $campaign,
    operator => "ADD"
  });

  # Make the mutate request
  my $result = $client->CampaignService()->mutate({operations => [$operation]});

  $campaign = $result->get_value()->[0];
  return $campaign;
}

# Creates an ad group in a Shopping campaign.
sub _create_ad_group {
  my ($client, $campaign) = @_;

  # Create ad group
  my $ad_group = Google::Ads::AdWords::v201802::AdGroup->new({
      campaignId => $campaign->get_id(),
      name       => "Ad Group #" . uniqid(),
      # Required: Set the ad group type to SHOPPING_SHOWCASE_ADS.
      adGroupType => "SHOPPING_SHOWCASE_ADS",
      # Required: Set the ad group's bidding strategy configuration.
      # Showcase ads require either ManualCpc or EnhancedCpc in the campaign's
      # BiddingStrategyConfiguration.
      biddingStrategyConfiguration =>
        Google::Ads::AdWords::v201802::BiddingStrategyConfiguration->new({
          bids                => [
            Google::Ads::AdWords::v201802::CpcBid->new({
                bid => Google::Ads::AdWords::v201802::Money->new(
                  {microAmount => 1000000}
                ),
              }
            ),
          ]}
        ),
    });

  # Create operation
  my $operation = Google::Ads::AdWords::v201802::AdGroupOperation->new({
    operand  => $ad_group,
    operator => "ADD"
  });

  # Make the mutate request
  my $result = $client->AdGroupService()->mutate({operations => [$operation]});

  $ad_group = $result->get_value()->[0];
  return $ad_group;
}

# Creates a Showcase ad.
sub _create_showcase_ad {
  my ($client, $ad_group) = @_;

  # Create the Showcase ad.
  my $showcase_ad = Google::Ads::AdWords::v201802::ShowcaseAd->new({
    name       => "Showcase ad #" . uniqid(),
    finalUrls  => ["http://example.com/showcase"],
    displayUrl => "example.com"
  });

  # Required: Set the ad's expanded image.
  my $expanded_image = Google::Ads::AdWords::v201802::Image->new({
      mediaId => _upload_image(
        $client, "https://goo.gl/IfVlpF"
      )});
  $showcase_ad->set_expandedImage($expanded_image);

  # Optional: Set the collapsed image.
  my $collapsed_image = Google::Ads::AdWords::v201802::Image->new({
      mediaId => _upload_image(
        $client, "https://goo.gl/NqTxAE"
      )});
  $showcase_ad->set_collapsedImage($collapsed_image);

  # Create ad group ad.
  my $ad_group_ad = Google::Ads::AdWords::v201802::AdGroupAd->new({
    adGroupId => $ad_group->get_id(),
    ad        => $showcase_ad
  });

  # Create operation.
  my $operation = Google::Ads::AdWords::v201802::AdGroupAdOperation->new({
    operand  => $ad_group_ad,
    operator => "ADD"
  });

  # Make the mutate request.
  my $result =
    $client->AdGroupAdService()->mutate({operations => [$operation]});

  $ad_group_ad = $result->get_value()->[0];
  return $ad_group_ad;
}

# Uploads an image.
sub _upload_image {
  my ($client, $url) = @_;

  # Create image.
  my $image_data =
    Google::Ads::Common::MediaUtils::get_base64_data_from_url($url);
  my $image = Google::Ads::AdWords::v201802::Image->new({
    data => $image_data,
    type => "IMAGE"
  });

  # Upload image.
  $image = $client->MediaService()->upload({media => [$image]});
  return $image->get_mediaId();
}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
  return 1;
}

# Creates the production partition tree for an ad group.
sub _create_product_partitions {
  my ($client, $ad_group_id) = @_;

  my $operations = [];
  my $next_id    = -1;

  # Make the root node a subdivision.
  my $root = _create_subdivision($operations, $next_id--, $ad_group_id);

  # Add a unit node for condition = NEW to include it.
  _create_unit(
    $operations,
    $ad_group_id,
    $root,
    Google::Ads::AdWords::v201802::ProductCanonicalCondition->new(
      {condition => "NEW"}));

  # Add a unit node for condition = USED to include it.
  _create_unit(
    $operations,
    $ad_group_id,
    $root,
    Google::Ads::AdWords::v201802::ProductCanonicalCondition->new(
      {condition => "USED"}));

  # Exclude everything else.
  _create_unit($operations, $ad_group_id, $root,
    Google::Ads::AdWords::v201802::ProductCanonicalCondition->new({}));

  my $result =
    $client->AdGroupCriterionService()->mutate({operations => $operations});
  my $ad_group_criterion = $result->get_value();
  return $ad_group_criterion;
}

# Return a new subdivision product partition and add to the provided list
# an operation to create the partition. The parent and value fields
# should not be specified for the root node.
# operations: The list of operations to add to.
# temp_id: The temporary ID to use for the new partition.
# ad_group_id: The ID of the ad group for the new partition.
# parent: (Optional) The parent partition for the new partition.
# value: (Optional) The case value (product dimension) for the new partition.
sub _create_subdivision {
  my ($operations, $temp_id, $ad_group_id, $parent, $value) = @_;
  my $division = Google::Ads::AdWords::v201802::ProductPartition->new({
    partitionType => "SUBDIVISION",
    id            => $temp_id
  });

  # The root node has neither a parent nor a value.
  if ($parent) {
    $division->set_parentCriterionId($parent->get_id());
    $division->set_caseValue($value);
  }

  my $ad_group_criterion =
    Google::Ads::AdWords::v201802::BiddableAdGroupCriterion->new({
      adGroupId => $ad_group_id,
      criterion => $division
    });

  my $operation = Google::Ads::AdWords::v201802::AdGroupCriterionOperation->new(
    {
      operand  => $ad_group_criterion,
      operator => "ADD"
    });
  push $operations, $operation;

  return $division;
}

# Return a new unit product partition and add to the provided list
# an operation to create the partition. The parent, value and bid_amount
# fields should not be specified for the root node.
# operations: The list of operations to add to.
# ad_group_id: The ID of the ad group for the new partition.
# parent: (Optional) The parent partition for the new partition.
# value: (Optional) The case value (product dimension) for the new partition.
# bid_amount: (Optional) The bid amount for the AdGroupCriterion.  If specified
#   then the AdGroupCriterion will be a BiddableAdGroupCriterion.
sub _create_unit {
  my ($operations, $ad_group_id, $parent, $value, $bid_amount) = @_;
  my $unit = Google::Ads::AdWords::v201802::ProductPartition->new(
    {partitionType => "UNIT",});

  # The root node has neither a parent nor a value.
  if ($parent) {
    $unit->set_parentCriterionId($parent->get_id());
    $unit->set_caseValue($value);
  }

  my $criterion;
  if ($bid_amount && $bid_amount > 0) {
    my $biddingStrategyConfiguration =
      Google::Ads::AdWords::v201802::BiddingStrategyConfiguration->new({
        bids => [
          Google::Ads::AdWords::v201802::CpcBid->new({
              bid => Google::Ads::AdWords::v201802::Money->new(
                {microAmount => $bid_amount})})]});

    $criterion =
      Google::Ads::AdWords::v201802::BiddableAdGroupCriterion->new(
      {biddingStrategyConfiguration => $biddingStrategyConfiguration});
  } else {
    $criterion = Google::Ads::AdWords::v201802::NegativeAdGroupCriterion->new();
  }

  $criterion->set_adGroupId($ad_group_id);
  $criterion->set_criterion($unit);

  my $operation = Google::Ads::AdWords::v201802::AdGroupCriterionOperation->new(
    {
      operand  => $criterion,
      operator => "ADD"
    });
  push $operations, $operation;

  return $unit;
}

# Log SOAP XML request, response and API errors.
Google::Ads::AdWords::Logging::enable_all_logging();

# Get AdWords Client, credentials will be read from ~/adwords.properties.
my $client = Google::Ads::AdWords::Client->new({version => "v201802"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_shopping_campaign_for_showcase_ads($client, $budget_id, $merchant_id);
