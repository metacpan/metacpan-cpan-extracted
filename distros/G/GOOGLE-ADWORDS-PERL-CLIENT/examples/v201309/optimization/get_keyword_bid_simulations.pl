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
# This example gets bid landscapes for a keywords. To get keywords, run
# basic_operations/get_keywords.pl.
#
# Tags: DataService.getCriterionBidLandscape
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201309::OrderBy;
use Google::Ads::AdWords::v201309::Predicate;
use Google::Ads::AdWords::v201309::Selector;

use Cwd qw(abs_path);

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";
my $keyword_id = "INSERT_CRITERION_ID_HERE";

# Example main subroutine.
sub get_keyword_bid_simulations {
  my $client = shift;
  my $ad_group_id = shift;
  my $keyword_id = shift;

  # Create predicates.
  my $adgroup_predicate = Google::Ads::AdWords::v201309::Predicate->new({
    field => "AdGroupId",
    operator => "IN",
    values => [$ad_group_id]
  });
  my $criterion_predicate = Google::Ads::AdWords::v201309::Predicate->new({
    field => "CriterionId",
    operator => "IN",
    values => [$keyword_id]
  });

  # Create selector.
  my $selector = Google::Ads::AdWords::v201309::Selector->new({
    fields => ["AdGroupId", "CriterionId", "StartDate", "EndDate", "Bid",
               "LocalClicks", "LocalCost", "MarginalCpc", "LocalImpressions"],
    predicates => [$adgroup_predicate, $criterion_predicate]
  });

  # Get bid landscape for ad group criteria.
  my $page = $client->DataService()->getCriterionBidLandscape({
    serviceSelector => $selector
  });

  # Display bid landscapes.
  if ($page->get_entries()) {
    foreach my $bid_landscape (@{$page->get_entries()}) {
      printf "Found criterion bid landscape with ad group id \"%s\", " .
             "criterion id \"%s\", start date \"%s\", end date \"%s\", and " .
             "landscape points:\n", $bid_landscape->get_adGroupId(),
             $bid_landscape->get_criterionId(), $bid_landscape->get_startDate(),
             $bid_landscape->get_endDate();
      foreach my $point (@{$bid_landscape->get_landscapePoints()}) {
        printf "- bid: %d => clicks: %d, cost: %d, marginalCpc: %d, " .
               "impressions: %d\n", $point->get_bid()->get_microAmount(),
               $point->get_clicks(), $point->get_cost()->get_microAmount(),
               $point->get_marginalCpc()->get_microAmount(),
               $point->get_impressions();
      }
    }
  } else {
    print "No criterion bid landscapes were found.\n";
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
my $client = Google::Ads::AdWords::Client->new({version => "v201309"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
get_keyword_bid_simulations($client, $ad_group_id, $keyword_id);
