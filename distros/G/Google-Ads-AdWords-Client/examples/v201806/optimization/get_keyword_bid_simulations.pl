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
# This example gets bid landscapes for a keywords. To get keywords, run
# basic_operations/get_keywords.pl.

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::Utilities::ServiceQueryBuilder;

use Cwd qw(abs_path);

use constant PAGE_SIZE => 100;

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";
my $keyword_id  = "INSERT_CRITERION_ID_HERE";

# Example main subroutine.
sub get_keyword_bid_simulations {
  my ($client, $ad_group_id, $keyword_id) = @_;


  # Create a query to select all keyword bid simulations for the
  # specified ad group.
  my $query_builder = Google::Ads::AdWords::Utilities::ServiceQueryBuilder->new(
      {client => $client})
      ->select([
      "AdGroupId",                "CriterionId",
      "StartDate",                "EndDate",
      "Bid",                      "BiddableConversions",
      "BiddableConversionsValue", "LocalClicks",
      "LocalCost",                "LocalImpressions"])
      ->where("AdGroupId")->in([$ad_group_id])
      ->where("CriterionId")->in([$keyword_id])
      ->limit(0, PAGE_SIZE);

  # Display bid landscapes.
  my $landscape_points_in_previous_page = 0;
  my $page;
  do {
    # Offset the start index by the number of landscape points in the last
    # retrieved page, NOT the number of entries (bid landscapes) in the page.
    if (defined($page)) {
      $query_builder->next_page($landscape_points_in_previous_page);
    }

    # Reset the count of landscape points in preparation for processing the
    # next page.
    $landscape_points_in_previous_page = 0;

    # Request the next page of bid landscapes.
    $page =
      $client->DataService()
      ->queryCriterionBidLandscape({query => $query_builder->build()});

    if ($page->get_entries()) {
      foreach my $criterion_bid_landscape (@{$page->get_entries()}) {
        printf "Criterion bid landscape with ad group ID %d, criterion ID " .
          " %d, start date %s, end date %s, with landscape points:\n",
          $criterion_bid_landscape->get_adGroupId(),
          $criterion_bid_landscape->get_criterionId(),
          $criterion_bid_landscape->get_startDate(),
          $criterion_bid_landscape->get_endDate();
        foreach my $bid_landscape_point (
          @{$criterion_bid_landscape->get_landscapePoints()})
        {
          $landscape_points_in_previous_page++;
          printf "  bid: %d => clicks: %d, cost: %d, impressions: %d" .
            ", biddable conversions: %.2f, biddable " .
            "conversions value: %.2f\n",
            $bid_landscape_point->get_bid()->get_microAmount(),
            $bid_landscape_point->get_clicks(),
            $bid_landscape_point->get_cost()->get_microAmount(),
            $bid_landscape_point->get_impressions(),
            $bid_landscape_point->get_biddableConversions(),
            $bid_landscape_point->get_biddableConversionsValue();
        }
        printf(" was found.");
      }
    }
  } while ($query_builder->has_next($page, $landscape_points_in_previous_page));
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
get_keyword_bid_simulations($client, $ad_group_id, $keyword_id);
