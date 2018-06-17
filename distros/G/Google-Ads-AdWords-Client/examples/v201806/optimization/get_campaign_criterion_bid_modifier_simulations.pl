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
use Google::Ads::AdWords::v201806::OrderBy;
use Google::Ads::AdWords::v201806::Paging;
use Google::Ads::AdWords::v201806::Predicate;
use Google::Ads::AdWords::v201806::Selector;

use Cwd qw(abs_path);

use constant PAGE_SIZE => 100;

# Replace with a valid value of your account.
my $campaign_id = "INSERT_CAMPAIGN_ID_HERE";

# Example main subroutine.
sub get_campaign_criterion_bid_modifier_simulations {
  my $client      = shift;
  my $campaign_id = shift;

  # Create predicates.
  my $campaign_predicate = Google::Ads::AdWords::v201806::Predicate->new({
      field    => "CampaignId",
      operator => "IN",
      values   => [$campaign_id]});
  # Create selector.
  my $paging = Google::Ads::AdWords::v201806::Paging->new({
    startIndex    => 0,
    numberResults => PAGE_SIZE
  });
  my $selector = Google::Ads::AdWords::v201806::Selector->new({
      fields => [
        "BidModifier",           "CampaignId",
        "CriterionId",           "StartDate",
        "EndDate",               "LocalClicks",
        "LocalCost",             "LocalImpressions",
        "TotalLocalClicks",      "TotalLocalCost",
        "TotalLocalImpressions", "RequiredBudget"
      ],
      paging     => $paging,
      predicates => [$campaign_predicate]});

  # Display bid landscapes.
  my $landscape_points_in_previous_page = 0;
  my $start_index                       = 0;
  do {
    # Offset the start index by the number of landscape points in the last
    # retrieved page, NOT the number of entries (bid landscapes) in the page.
    $start_index += $landscape_points_in_previous_page;
    $selector->get_paging()->set_startIndex($start_index);

    # Reset the count of landscape points in preparation for processing the
    # next page.
    $landscape_points_in_previous_page = 0;

    # Request the next page of bid landscapes.
    my $page =
      $client->DataService()
      ->getCampaignCriterionBidLandscape({serviceSelector => $selector});

    if ($page->get_entries()) {
      foreach my $criterion_bid_landscape (@{$page->get_entries()}) {
        printf "Found campaign-level criterion bid modifier landscapes for" .
          " criterion with ID %d, start date '%s', end date '%s', and" .
          " landscape points:\n",
          $criterion_bid_landscape->get_criterionId(),
          $criterion_bid_landscape->get_startDate(),
          $criterion_bid_landscape->get_endDate();
        my @landscape_points = @{$criterion_bid_landscape
          ->get_landscapePoints()};
        foreach my $landscape_point (@landscape_points) {
          $landscape_points_in_previous_page++;
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
    }
  } while ($landscape_points_in_previous_page >= PAGE_SIZE);

  return 1;
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
get_campaign_criterion_bid_modifier_simulations($client, $campaign_id);

