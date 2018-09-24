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
# This example gets all disapproved ads in an ad group. To add ads, run
# basic_operations/add_text_ads.pl. To get ad groups, run
# basic_operations/get_ad_groups.pl.

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201809::OrderBy;
use Google::Ads::AdWords::v201809::Paging;
use Google::Ads::AdWords::v201809::Predicate;
use Google::Ads::AdWords::v201809::Selector;
use Google::Ads::AdWords::Utilities::PageProcessor;

use Cwd qw(abs_path);

use constant PAGE_SIZE => 100;

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";

# Example main subroutine.
sub get_all_disapproved_ads {
  my $client      = shift;
  my $ad_group_id = shift;

  # Create predicates (Filters).
  my $ad_group_predicate = Google::Ads::AdWords::v201809::Predicate->new({
      field    => "AdGroupId",
      operator => "IN",
      values   => [$ad_group_id]});

  my $disapproved_predicate = Google::Ads::AdWords::v201809::Predicate->new({
      field    => "CombinedApprovalStatus",
      operator => "EQUALS",
      values   => ["DISAPPROVED"]});

  # Create selector.
  my $paging = Google::Ads::AdWords::v201809::Paging->new({
    startIndex    => 0,
    numberResults => PAGE_SIZE
  });
  my $selector = Google::Ads::AdWords::v201809::Selector->new({
      fields     => ["Id", "PolicySummary"],
      predicates => [$ad_group_predicate, $disapproved_predicate],
      ordering   => [
        Google::Ads::AdWords::v201809::OrderBy->new({
            field     => "Id",
            sortOrder => "ASCENDING"
          })
      ],
      paging => $paging
    });

  # Paginate through results.
  # The contents of the subroutine will be executed for each ad.
  my $disapproved_ad_count = 0;
  Google::Ads::AdWords::Utilities::PageProcessor->new({
      client   => $client,
      service  => $client->AdGroupAdService(),
      selector => $selector
    }
    )->process_entries(
    sub {
      my ($ad_group_ad) = @_;
      $disapproved_ad_count++;
      my $policy_summary = $ad_group_ad->get_policySummary();
      printf "Ad with ID %d and type '%s' was disapproved with the " .
        "following policy topic entries:\n", $ad_group_ad->get_ad()->get_id(),
        $ad_group_ad->get_ad()->get_Ad__Type();
      foreach
        my $policy_topic_entry (@{$policy_summary->get_policyTopicEntries()}) {
        printf "  topic id: %s, topic name: '%s', Help Center URL: '%s'\n",
          $policy_topic_entry->get_policyTopicId(),
          $policy_topic_entry->get_policyTopicName(),
          $policy_topic_entry->get_policyTopicHelpCenterUrl();
        # Display the attributes and values that triggered the policy topic.
        if ($policy_topic_entry->get_policyTopicEvidences()) {
          foreach
            my $evidence (@{$policy_topic_entry->get_policyTopicEvidences()}) {
            printf("    evidence type: '%s'\n",
              $evidence->get_policyTopicEvidenceType());
            if ($evidence->get_evidenceTextList()) {
              for (
                my $i = 0;
                $i < scalar(@{$evidence->get_evidenceTextList()}) ;
                $i++
                )
              {
                printf("      evidence text[%d]: '%s'\n",
                  $i, $evidence->get_evidenceTextList()->[$i]);
              }
            }
          }
        }

      }
    });

  if ($disapproved_ad_count == 0) {
    print("No disapproved ads were found.\n");
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
my $client = Google::Ads::AdWords::Client->new({version => "v201809"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
get_all_disapproved_ads($client, $ad_group_id);
