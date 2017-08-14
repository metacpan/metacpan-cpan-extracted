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
# This example gets all available campaign mobile bid modifier landscapes
# for a given campaign.
# To get campaigns, run basic_operations/get_campaigns.pl.

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201708::OrderBy;
use Google::Ads::AdWords::v201708::Predicate;
use Google::Ads::AdWords::v201708::Selector;

use Cwd qw(abs_path);

# Replace with a valid value of your account.
my $campaign_id = "INSERT_CAMPAIGN_ID_HERE";

# Example main subroutine.
sub get_campaign_criterion_bid_modifier_simulations {
  my $client      = shift;
  my $campaign_id = shift;

  # Create predicates.
  my $campaign_predicate = Google::Ads::AdWords::v201708::Predicate->new({
      field    => "CampaignId",
      operator => "IN",
      values   => [$campaign_id]});

  # Create selector.
  my $selector = Google::Ads::AdWords::v201708::Selector->new({
      fields => [
        "BidModifier",           "CampaignId",
        "CriterionId",           "StartDate",
        "EndDate",               "LocalClicks",
        "LocalCost",             "LocalImpressions",
        "TotalLocalClicks",      "TotalLocalCost",
        "TotalLocalImpressions", "RequiredBudget"
      ],
      predicates => [$campaign_predicate]});

  # Make the getCampaignCriterionBidLandscape request.
  my $page =
    $client->DataService()
    ->getCampaignCriterionBidLandscape({serviceSelector => $selector});

  # Display results.
  if ($page->get_entries()) {
    foreach my $bid_modifier_landscape (@{$page->get_entries()}) {
      printf "Found campaign-level criterion bid modifier landscapes for" .
        " criterion with ID %d, start date '%s', end date '%s', and" .
        " landscape points:\n",
        $bid_modifier_landscape->get_criterionId(),
        $bid_modifier_landscape->get_startDate(),
        $bid_modifier_landscape->get_endDate();
      foreach
        my $landscape_point (@{$bid_modifier_landscape->get_landscapePoints()})
      {
        printf "  bid modifier: %.2f => clicks: %d, cost: %.0f, " .
          "impressions: %d, total clicks: %d, total cost: %.0f, " .
          "total impressions: %d, and required budget: %.0f\n",
          $landscape_point->get_bidModifier(),
          $landscape_point->get_clicks(),
          $landscape_point->get_cost()->get_microAmount(),
          $landscape_point->get_impressions(),
          $landscape_point->get_totalLocalClicks(),
          $landscape_point->get_totalLocalCost()->get_microAmount(),
          $landscape_point->get_totalLocalImpressions(),
          $landscape_point->get_requiredBudget()->get_microAmount();
      }
    }
  } else {
    print "No campaign criterion bid modifier landscapes were found.\n";
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
get_campaign_criterion_bid_modifier_simulations($client, $campaign_id);

