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
# This code example adds a Dynamic Search Ads campaign. To get campaigns, run
# get_campaigns.pl.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201806::AdGroup;
use Google::Ads::AdWords::v201806::AdGroupOperation;
use Google::Ads::AdWords::v201806::AdGroupAd;
use Google::Ads::AdWords::v201806::AdGroupAdOperation;
use Google::Ads::AdWords::v201806::AdGroupCriterionOperation;
use Google::Ads::AdWords::v201806::BiddableAdGroupCriterion;
use Google::Ads::AdWords::v201806::BiddingStrategyConfiguration;
use Google::Ads::AdWords::v201806::Budget;
use Google::Ads::AdWords::v201806::BudgetOperation;
use Google::Ads::AdWords::v201806::Campaign;
use Google::Ads::AdWords::v201806::CampaignCriterion;
use Google::Ads::AdWords::v201806::CampaignCriterionOperation;
use Google::Ads::AdWords::v201806::CampaignOperation;
use Google::Ads::AdWords::v201806::CpcBid;
use Google::Ads::AdWords::v201806::DynamicSearchAdsSetting;
use Google::Ads::AdWords::v201806::ExpandedDynamicSearchAd;
use Google::Ads::AdWords::v201806::Money;
use Google::Ads::AdWords::v201806::Webpage;
use Google::Ads::AdWords::v201806::WebpageCondition;
use Google::Ads::AdWords::v201806::WebpageParameter;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Example main subroutine.
sub add_dynamic_search_ads_campaign {
  my $client = shift;

  my $budget   = _create_budget($client);
  my $campaign = _create_campaign($client, $budget);
  my $ad_group = _create_ad_group($client, $campaign);
  _create_expanded_DSA($client, $ad_group);
  _add_web_page_criteria($client, $ad_group);

  return 1;
}

# Create the budget.
sub _create_budget() {
  my ($client) = @_;

  # Create a budget, which can be shared by multiple campaigns.
  my $shared_budget = Google::Ads::AdWords::v201806::Budget->new({
    name => sprintf("Interplanetary Cruise #%s", uniqid()),
    amount =>
      Google::Ads::AdWords::v201806::Money->new({microAmount => 5000000}),
    deliveryMethod => "STANDARD"
  });

  my $budget_operation = Google::Ads::AdWords::v201806::BudgetOperation->new({
    operator => "ADD",
    operand  => $shared_budget
  });

  # Add budget.
  my $budget =
    $client->BudgetService()->mutate({operations => ($budget_operation)})
    ->get_value()->[0];
  return $budget;
}

# Creates the campaign.
sub _create_campaign {
  my ($client, $budget) = @_;

  # Required: Set the campaign's Dynamic Search Ads settings.
  my $dynamic_search_ads_setting =
    Google::Ads::AdWords::v201806::DynamicSearchAdsSetting->new({
      # Required: Set the domain name and language.
      domainName   => "example.com",
      languageCode => "en"
    });

  # Calculating a start date of today and an end date 1 year from now.
  my (undef, undef, undef, $mday, $mon, $year) = localtime(time + 60 * 60 * 24);
  my $start_date = sprintf("%d%02d%02d", ($year + 1900), ($mon + 1), $mday);
  (undef, undef, undef, $mday, $mon, $year) =
    localtime(time + 60 * 60 * 24 * 365);
  my $end_date = sprintf("%d%02d%02d", ($year + 1900), ($mon + 1), $mday);

  my $campaign = Google::Ads::AdWords::v201806::Campaign->new({
      name => sprintf("Interplanetary Cruise #%s", uniqid()),
      biddingStrategyConfiguration =>
        Google::Ads::AdWords::v201806::BiddingStrategyConfiguration->new({
          biddingStrategyType => "MANUAL_CPC"
        }
        ),
      # Only the budgetId should be sent, all other fields will be ignored by
      # CampaignService.
      budget => Google::Ads::AdWords::v201806::Budget->new(
        {budgetId => $budget->get_budgetId()}
      ),
      advertisingChannelType => "SEARCH",
      settings               => [$dynamic_search_ads_setting],
      # Additional properties (non-required).
      startDate => $start_date,
      endDate   => $end_date,
      # Recommendation: Set the campaign to PAUSED when creating it to stop
      # the ads from immediately serving. Set to ENABLED once you've added
      # targeting and the ads are ready to serve.
      status => "PAUSED"
    });

  # Create operation.
  my $campaign_operation =
    Google::Ads::AdWords::v201806::CampaignOperation->new({
      operator => "ADD",
      operand  => $campaign
    });

  # Add campaigns.
  my $result =
    $client->CampaignService()->mutate({operations => [$campaign_operation]});

  # Display campaigns.
  my $new_campaign = $result->get_value()->[0];
  printf "Campaign with name '%s' and ID %d was added.\n",
    $new_campaign->get_name(),
    $new_campaign->get_id();
  return $new_campaign;
}

# Creates the ad group.
sub _create_ad_group {
  my ($client, $campaign) = @_;

  my $ad_group = Google::Ads::AdWords::v201806::AdGroup->new({
      name       => sprintf("Earth to Mars Cruises #%s", uniqid()),
      campaignId => $campaign->get_id(),
      # Required: Set the ad group's type to Dynamic Search Ads.
      adGroupType => "SEARCH_DYNAMIC_ADS",
      status      => "PAUSED",
      # Recommended: Set a tracking URL template for your ad group if you want
      # to use URL tracking software.
      trackingUrlTemplate =>
        "http://tracker.example.com/traveltracker/{escapedlpurl}",
      biddingStrategyConfiguration =>
        Google::Ads::AdWords::v201806::BiddingStrategyConfiguration->new({
          bids => [
            Google::Ads::AdWords::v201806::CpcBid->new({
                bid => Google::Ads::AdWords::v201806::Money->new(
                  {microAmount => 3000000}
                ),
              }
            ),
          ]})});

  # Create operation.
  my $ad_group_operation =
    Google::Ads::AdWords::v201806::AdGroupOperation->new({
      operator => "ADD",
      operand  => $ad_group
    });

  my $result =
    $client->AdGroupService()->mutate({operations => [$ad_group_operation]});
  my $new_ad_group = $result->get_value()->[0];
  printf "Ad group with name '%s' and ID %d was added.\n",
    $new_ad_group->get_name(), $new_ad_group->get_id();
  return $new_ad_group;
}

# Creates the expanded Dynamic Search Ad.
sub _create_expanded_DSA {
  my ($client, $ad_group) = @_;
  # Create the expanded Dynamic Search Ad. This ad will have its headline and
  # final URL auto-generated at serving time according to domain name specific
  # information provided by DynamicSearchAdsSetting at the campaign level.
  my $expanded_DSA =
    Google::Ads::AdWords::v201806::ExpandedDynamicSearchAd->new({
      # Set the ad description.
      description => "Buy your tickets now!",
    });

  # Create the ad group ad.
  my $ad_group_ad = Google::Ads::AdWords::v201806::AdGroupAd->new({
    adGroupId => $ad_group->get_id(),
    ad        => $expanded_DSA,
    # Optional: Set the status.
    status => "PAUSED"
  });

  # Create operation.
  my $operation = Google::Ads::AdWords::v201806::AdGroupAdOperation->new({
    operator => "ADD",
    operand  => $ad_group_ad
  });

  my $result =
    $client->AdGroupAdService()->mutate({operations => [$operation]});
  my $new_ad_group_ad = $result->get_value()->[0];
  my $new_expanded_dsa = $new_ad_group_ad->get_ad();
  printf
    "Expanded Dynamic Search Ad with ID %d and description '%s' was added.\n",
    $new_expanded_dsa->get_id(), $new_expanded_dsa->get_description();
}

# Adds a web page criteria to target Dynamic Search Ads.
sub _add_web_page_criteria {
  my ($client, $ad_group) = @_;

  my $url_condition = Google::Ads::AdWords::v201806::WebpageCondition->new({
    operand  => "URL",
    argument => "/specialoffers"
  });

  my $title_condition = Google::Ads::AdWords::v201806::WebpageCondition->new({
    operand  => "PAGE_TITLE",
    argument => "Special Offer"
  });

  # Create a webpage criterion for special offers.
  my $param = Google::Ads::AdWords::v201806::WebpageParameter->new({
      criterionName => "Special offers",
      conditions    => [$url_condition, $title_condition]});

  my $webpage = Google::Ads::AdWords::v201806::Webpage->new({
    parameter => $param
  });

  # Create biddable ad group criterion.
  my $biddable_ad_group_criterion =
    Google::Ads::AdWords::v201806::BiddableAdGroupCriterion->new({
      adGroupId  => $ad_group->get_id(),
      criterion  => $webpage,
      userStatus => "PAUSED",
      # Optional: set a custom bid.
      biddingStrategyConfiguration =>
        Google::Ads::AdWords::v201806::BiddingStrategyConfiguration->new({
          bids => [
            Google::Ads::AdWords::v201806::CpcBid->new({
                bid => Google::Ads::AdWords::v201806::Money->new(
                  {microAmount => 1000000}
                ),
              }
            ),
          ]})});

  # Create operation.
  my $operation =
    Google::Ads::AdWords::v201806::AdGroupCriterionOperation->new({
      operator => "ADD",
      operand  => $biddable_ad_group_criterion
    });

  # Create the criterion.
  my $result =
    $client->AdGroupCriterionService()->mutate({operations => [$operation]});
  my $new_ad_group_criterion = $result->get_value()->[0];
  printf "Webpage criterion with ID %d was added to ad group ID %d.\n",
    $new_ad_group_criterion->get_criterion()->get_id(),
    $new_ad_group_criterion->get_adGroupId();
}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
  return 1;
}

# Log SOAP XML request, response and API errors.
Google::Ads::AdWords::Logging::enable_all_logging();

# Get AdWords Client, credentials will be read from ~/adwords.properties.
my $client = Google::Ads::AdWords::Client->new({version => "v201806"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_dynamic_search_ads_campaign($client);
