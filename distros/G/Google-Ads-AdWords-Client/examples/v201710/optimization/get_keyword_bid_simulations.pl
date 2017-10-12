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
use Google::Ads::AdWords::v201710::OrderBy;
use Google::Ads::AdWords::v201710::Paging;
use Google::Ads::AdWords::v201710::Predicate;
use Google::Ads::AdWords::v201710::Selector;

use Cwd qw(abs_path);

use constant PAGE_SIZE => 100;

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";
my $keyword_id  = "INSERT_CRITERION_ID_HERE";

# Example main subroutine.
sub get_keyword_bid_simulations {
  my ($client, $ad_group_id, $keyword_id) = @_;

  # Create predicates.
  my $adgroup_predicate = Google::Ads::AdWords::v201710::Predicate->new({
      field    => "AdGroupId",
      operator => "IN",
      values   => [$ad_group_id]});
  my $criterion_predicate = Google::Ads::AdWords::v201710::Predicate->new({
      field    => "CriterionId",
      operator => "IN",
      values   => [$keyword_id]});

  # Create selector.
  my $paging = Google::Ads::AdWords::v201710::Paging->new({
    startIndex    => 0,
    numberResults => PAGE_SIZE
  });
  my $selector = Google::Ads::AdWords::v201710::Selector->new({
      fields => [
        "AdGroupId", "CriterionId", "StartDate", "EndDate",
        "Bid",       "LocalClicks", "LocalCost", "LocalImpressions"
      ],
      paging     => $paging,
      predicates => [$adgroup_predicate, $criterion_predicate]});

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
        printf "Criterion bid landscape with ad group ID %d, criterion ID " .
          " %d, start date %s, end date %s, with landscape points:\n",
          $criterion_bid_landscape->get_criterionId(),
          $criterion_bid_landscape->get_startDate(),
          $criterion_bid_landscape->get_endDate();
        foreach my $bid_landscape_point (
          @{$criterion_bid_landscape->get_landscapePoints()})
        {
          $landscape_points_in_previous_page++;
          printf "\t{bid: %d clicks: %d cost: %d impressions: %d}\n",
            $bid_landscape_point->get_bid()->get_microAmount(),
            $bid_landscape_point->get_clicks(),
            $bid_landscape_point->get_cost()->get_microAmount(),
            $bid_landscape_point->get_impressions();
        }
        printf(" was found.");
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
my $client = Google::Ads::AdWords::Client->new({version => "v201710"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
get_keyword_bid_simulations($client, $ad_group_id, $keyword_id);
