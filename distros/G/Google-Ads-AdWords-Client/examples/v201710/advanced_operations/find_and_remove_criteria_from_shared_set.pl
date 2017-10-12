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
# This example demonstrates how to find and remove shared sets and shared set
# criteria.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201710::CampaignSharedSet;
use Google::Ads::AdWords::v201710::CampaignSharedSetOperation;
use Google::Ads::AdWords::v201710::Criterion;
use Google::Ads::AdWords::v201710::Keyword;
use Google::Ads::AdWords::v201710::OrderBy;
use Google::Ads::AdWords::v201710::Paging;
use Google::Ads::AdWords::v201710::Placement;
use Google::Ads::AdWords::v201710::Predicate;
use Google::Ads::AdWords::v201710::Selector;
use Google::Ads::AdWords::v201710::SharedCriterion;
use Google::Ads::AdWords::v201710::SharedCriterionOperation;
use Google::Ads::AdWords::v201710::SharedSet;
use Google::Ads::AdWords::v201710::SharedSetOperation;
use Google::Ads::AdWords::Utilities::PageProcessor;

use constant PAGE_SIZE => 500;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $campaign_id = "INSERT_CAMPAIGN_ID_HERE";

# Example main subroutine.
sub find_and_remove_criteria_from_shared_set {
  my $client      = shift;
  my $campaign_id = shift;

  # First, retrieve all shared sets associated with the campaign.
  my $paging = Google::Ads::AdWords::v201710::Paging->new({
      startIndex    => 0,
      numberResults => PAGE_SIZE
  });
  my $selector = Google::Ads::AdWords::v201710::Selector->new({
      fields => ["SharedSetId", "CampaignId", "SharedSetName", "SharedSetType"],
      predicates => [
        Google::Ads::AdWords::v201710::Predicate->new({
            field    => "CampaignId",
            operator => "EQUALS",
            values   => [$campaign_id]})
      ],
      paging => $paging
    });

  # Paginate through results and collect the shared set IDs.
  # The subroutine will be executed for each shared set.
  my @shared_set_ids = Google::Ads::AdWords::Utilities::PageProcessor->new({
      client   => $client,
      service  => $client->CampaignSharedSetService(),
      selector => $selector
    }
    )->process_entries(
    sub {
      my ($campaign_shared_set) = @_;
      printf "Campaign shared set ID %d and name '%s' found for " .
        " campaign ID %d.\n",
        $campaign_shared_set->get_sharedSetId(),
        $campaign_shared_set->get_sharedSetName(),
        $campaign_shared_set->get_campaignId();
      return $campaign_shared_set->get_sharedSetId()->get_value();
    });

  if (!@shared_set_ids) {
    printf "No shared sets found for campaign ID %d.\n", $campaign_id;
    return 1;
  }

  # Next, retrieve criterion IDs for all found shared sets.
  $paging = Google::Ads::AdWords::v201710::Paging->new({
      startIndex    => 0,
      numberResults => PAGE_SIZE
  });
  $selector = Google::Ads::AdWords::v201710::Selector->new({
      fields => [
        "SharedSetId", "Id", "KeywordText", "KeywordMatchType", "PlacementUrl"
      ],
      predicates => [
        Google::Ads::AdWords::v201710::Predicate->new({
            field    => "SharedSetId",
            operator => "IN",
            values   => \@shared_set_ids
          })
      ],
      paging => $paging
    });

  my @remove_criterion_operations =
    Google::Ads::AdWords::Utilities::PageProcessor->new({
      client   => $client,
      service  => $client->SharedCriterionService(),
      selector => $selector
    }
    )->process_entries(
    sub {
      my ($shared_criterion) = @_;
      my $criterion = $shared_criterion->get_criterion();
      if ($criterion->isa("Google::Ads::AdWords::v201710::Keyword")) {
        printf "Shared negative keyword with ID %d and text '%s' was " .
          "found.\n",
          $criterion->get_id(),
          $criterion->get_text();
      } elsif ($criterion->isa("Google::Ads::AdWords::v201710::Placement")) {
        printf "Shared negative placement with ID %d and URL '%s' was " .
          "found.\n",
          $criterion->get_id(),
          $criterion->get_url();
      } else {
        printf "Shared criterion with ID %d was found.\n", $criterion->get_id();
      }

      # Create an operation to remove this criterion.
      my $shared_criterion_operation =
        Google::Ads::AdWords::v201710::SharedCriterionOperation->new({
          operator => 'REMOVE',
          operand  => Google::Ads::AdWords::v201710::SharedCriterion->new({
              criterion => Google::Ads::AdWords::v201710::Criterion->new(
                {id => $criterion->get_id()}
              ),
              sharedSetId => $shared_criterion->get_sharedSetId()})});
      return $shared_criterion_operation;
    });

  # Finally, remove the criteria.
  if (@remove_criterion_operations) {
    my $remove_criteria_result =
      $client->SharedCriterionService()
      ->mutate({operations => \@remove_criterion_operations});
    foreach my $removed_criterion (@{$remove_criteria_result->get_value()}) {
      printf "Shared criterion ID %d was successfully removed from shared " .
        "set ID %d.\n",
        $removed_criterion->get_criterion()->get_id(),
        $removed_criterion->get_sharedSetId();
    }
  } else {
    printf "No shared criteria to remove.\n";
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
my $client = Google::Ads::AdWords::Client->new({version => "v201710"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
find_and_remove_criteria_from_shared_set($client, $campaign_id);
