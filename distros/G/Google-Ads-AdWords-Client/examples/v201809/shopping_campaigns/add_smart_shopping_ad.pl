#!/usr/bin/perl -w
#
# Copyright 2018 Google LLC
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
# This example adds a Smart Shopping campaign with an ad group, and ad group
# ad.

use strict;
use lib "../../../lib";
use utf8;

use Data::Uniqid qw(uniqid);

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201809::AdGroup;
use Google::Ads::AdWords::v201809::AdGroupAd;
use Google::Ads::AdWords::v201809::AdGroupAdOperation;
use Google::Ads::AdWords::v201809::AdGroupCriterionOperation;
use Google::Ads::AdWords::v201809::AdGroupOperation;
use Google::Ads::AdWords::v201809::BiddableAdGroupCriterion;
use Google::Ads::AdWords::v201809::Campaign;
use Google::Ads::AdWords::v201809::CampaignOperation;
use Google::Ads::AdWords::v201809::BiddingStrategyConfiguration;
use Google::Ads::AdWords::v201809::Budget;
use Google::Ads::AdWords::v201809::BudgetOperation;
use Google::Ads::AdWords::v201809::GoalOptimizedShoppingAd;
use Google::Ads::AdWords::v201809::Money;
use Google::Ads::AdWords::v201809::ProductPartition;
use Google::Ads::AdWords::v201809::ShoppingSetting;

use Cwd qw(abs_path);

# Replace with valid values of your account.
my $merchant_id = "INSERT_MERCHANT_CENTER_ID_HERE";

# If set to true, a default partition will be created.
# Set it to false if you plan to run the add_product_partition_tree.pl
# example right after this example.
my $should_create_default_partition = 1;

# Example main subroutine.
sub add_smart_shopping_ad {
    my ($client, $merchant_id, $should_create_default_partition) = @_;

    my $budget_id = _create_budget($client);

    my $campaign_id = _create_smart_campaign($client, $budget_id, $merchant_id);

    my $ad_group_id = _create_smart_shopping_ad_group($client, $campaign_id);

    _create_smart_shopping_ad($client, $ad_group_id);

    if (defined($should_create_default_partition)
        && $should_create_default_partition) {
        _create_default_partition($client, $ad_group_id);
    }

    return 1;
}

# Creates a non-shared budget for a Smart Shopping campaign. Smart Shopping
# campaigns support only non-shared budgets.
sub _create_budget() {
    my ($client) = @_;

    my $budget = Google::Ads::AdWords::v201809::Budget->new({
        name => sprintf("Interplanetary Cruise Budget #%s", uniqid()),
        # This budget equals 50.00 units of your account's currency, e.g.,
        # 50 USD if your currency is USD.
        amount =>
            Google::Ads::AdWords::v201809::Money->new({
                microAmount => 50000000
        }),
        deliveryMethod => "STANDARD",
        # Non-shared budgets are required for Smart Shopping campaigns.
        isExplicitlyShared => 0
    });

    my $budget_operation = Google::Ads::AdWords::v201809::BudgetOperation->new({
        operator => "ADD",
        operand  => $budget
    });

    # Add budget.
    my $added_budget =
        $client->BudgetService()->mutate({ operations => ($budget_operation) })
            ->get_value()->[0];

    printf(
        "Budget with name '%s' and ID %d was created.\n",
        $added_budget->get_name(),
        $added_budget->get_budgetId());

    return $added_budget->get_budgetId();
}

# Creates a Smart Shopping campaign.
sub _create_smart_campaign {
    my ($client, $budget_id, $merchant_id) = @_;

    # Create a campaign with required and optional settings.
    my $campaign = Google::Ads::AdWords::v201809::Campaign->new({
        name                         => "Smart Shopping campaign #" . uniqid(),
        # The advertisingChannelType is what makes this a Shopping campaign.
        advertisingChannelType       => "SHOPPING",
        # Sets the advertisingChannelSubType to SHOPPING_GOAL_OPTIMIZED_ADS to
        # make this a Smart Shopping campaign.
        advertisingChannelSubType    => "SHOPPING_GOAL_OPTIMIZED_ADS",
        # Recommendation: Set the campaign to PAUSED when creating it to stop
        # the ads from immediately serving. Set to ENABLED once you've added
        # targeting and the ads are ready to serve.
        status                       => "PAUSED",
        # Set budget (required)
        budget                       =>
            Google::Ads::AdWords::v201809::Budget
                ->new({ budgetId => $budget_id }),
        # Set a bidding strategy. Only MAXIMIZE_CONVERSION_VALUE is supported.
        biddingStrategyConfiguration =>
            Google::Ads::AdWords::v201809::BiddingStrategyConfiguration->new(
                { biddingStrategyType => "MAXIMIZE_CONVERSION_VALUE" }
            ),
        # All Shopping campaigns need a ShoppingSetting.
        settings                     => [
            Google::Ads::AdWords::v201809::ShoppingSetting->new({
                salesCountry => "US",
                merchantId   => $merchant_id
            }) ] });

    my $operation = Google::Ads::AdWords::v201809::CampaignOperation->new({
        operand  => $campaign,
        operator => "ADD"
    });

    # Create the campaign on the server and print out some information.
    my $added_campaign = $client->CampaignService()
        ->mutate({ operations => [ $operation ] })
        ->get_value()->[0];
    printf(
        "Smart Shopping campaign with name '%s' and ID %d was added.\n",
        $added_campaign->get_name(),
        $added_campaign->get_id());

    return $added_campaign->get_id();
}

# Creates a Smart Shopping ad group by setting the ad group type to
# SHOPPING_GOAL_OPTIMIZED_ADS.
sub _create_smart_shopping_ad_group {
    my ($client, $campaign_id) = @_;

    # Create an ad group.
    my $ad_group = Google::Ads::AdWords::v201809::AdGroup->new({
        campaignId  => $campaign_id,
        name        => "Smart Shopping ad group #" . uniqid(),
        # Set the ad group type to SHOPPING_GOAL_OPTIMIZED_ADS.
        adGroupType => "SHOPPING_GOAL_OPTIMIZED_ADS"
    });

    # Create operation.
    my $operation = Google::Ads::AdWords::v201809::AdGroupOperation->new({
        operand  => $ad_group,
        operator => "ADD"
    });

    # Create the ad group on the server and print out some information.
    my $added_ad_group = $client->AdGroupService()
        ->mutate({ operations => [ $operation ] })
        ->get_value()->[0];

    printf(
        "Smart Shopping ad group with name '%s' and ID %d was added.\n",
        $added_ad_group->get_name(),
        $added_ad_group->get_id()
    );
    return $added_ad_group->get_id();
}

# Creates a Smart Shopping ad.
sub _create_smart_shopping_ad {
    my ($client, $ad_group_id) = @_;

    # Create a Smart Shopping ad (Goal-optimized Shopping ad).
    my $smart_shopping_ad
        = Google::Ads::AdWords::v201809::GoalOptimizedShoppingAd->new({ });

    # Create ad group ad.
    my $ad_group_ad = Google::Ads::AdWords::v201809::AdGroupAd->new({
        adGroupId => $ad_group_id,
        ad        => $smart_shopping_ad
    });

    # Create an ad group ad operation and add it to the operations list.
    my $operation = Google::Ads::AdWords::v201809::AdGroupAdOperation->new({
        operand  => $ad_group_ad,
        operator => "ADD"
    });

    # Create the ad group ad on the server and print out some information.
    my $added_ad_group_ad =
        $client->AdGroupAdService()->mutate({ operations => [ $operation ] })
            ->get_value()->[0];
    printf(
        "Smart Shopping ad with ID %d was added.\n",
        $added_ad_group_ad->get_ad()->get_id()
    );
}

# Creates a default product partition as an ad group criterion.
sub _create_default_partition {
    my ($client, $ad_group_id) = @_;

    # Creates an ad group criterion for 'All products'.
    my $product_partition = Google::Ads::AdWords::v201809::ProductPartition
        ->new({ partitionType => "UNIT" });

    # Creates a biddable ad group criterion.
    my $criterion =
        Google::Ads::AdWords::v201809::BiddableAdGroupCriterion->new({
            adGroupId => $ad_group_id,
            criterion => $product_partition
        });

    # Creates an ad group criterion operation.
    my $operation = Google::Ads::AdWords::v201809::AdGroupCriterionOperation
        ->new({
        operand  => $criterion,
        operator => "ADD"
    });

    my $added_ad_group_criterion = $client->AdGroupCriterionService()
        ->mutate({ operations => [ $operation ] })
        ->get_value()->[0];
    printf(
        "Ad group criterion with ID %d in ad group with ID %d"
            . " was added.\n",
        $added_ad_group_criterion->get_criterion()->get_id(),
        $added_ad_group_criterion->get_adGroupId()
    );
}

# Log SOAP XML request, response and API errors.
Google::Ads::AdWords::Logging::enable_all_logging();

# Get AdWords Client, credentials will be read from ~/adwords.properties.
my $client = Google::Ads::AdWords::Client->new({ version => "v201809" });

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_smart_shopping_ad($client, $merchant_id, $should_create_default_partition);
