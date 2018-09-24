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
# This example gets keywords in an ad group. To add keywords, run
# basic_operations/add_keywords.pl. To get ad groups, run
# basic_operations/get_ad_groups.pl.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201809::OrderBy;
use Google::Ads::AdWords::v201809::Paging;
use Google::Ads::AdWords::v201809::Predicate;
use Google::Ads::AdWords::v201809::Selector;
use Google::Ads::AdWords::Utilities::PageProcessor;

use Cwd qw(abs_path);

use constant PAGE_SIZE => 500;

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";

# Example main subroutine.
sub get_keywords {
  my $client      = shift;
  my $ad_group_id = shift;

  # Create selector.
  my $ad_group_id_predicate = Google::Ads::AdWords::v201809::Predicate->new({
      field    => "AdGroupId",
      operator => "IN",
      values   => [$ad_group_id]});
  my $criteria_type_predicate = Google::Ads::AdWords::v201809::Predicate->new({
      field    => "CriteriaType",
      operator => "EQUALS",
      values   => ["KEYWORD"]});
  my $paging = Google::Ads::AdWords::v201809::Paging->new({
      startIndex    => 0,
      numberResults => PAGE_SIZE
  });
  my $selector = Google::Ads::AdWords::v201809::Selector->new({
      fields => ["Id", "CriteriaType", "KeywordMatchType", "KeywordText"],
      predicates => [$ad_group_id_predicate, $criteria_type_predicate],
      ordering => Google::Ads::AdWords::v201809::OrderBy->new({
          field     => "KeywordText",
          sortOrder => "ASCENDING"
        }
      ),
      paging => $paging
    });

  # Paginate through results.
  # The contents of the subroutine will be executed for each criterion.
  Google::Ads::AdWords::Utilities::PageProcessor->new({
      client   => $client,
      service  => $client->AdGroupCriterionService(),
      selector => $selector
    }
    )->process_entries(
    sub {
      my ($ad_group_criterion) = @_;
      my $prefix = "Keyword";
      if (
        $ad_group_criterion->isa(
          "Google::Ads::AdWords::v201809::NegativeAdGroupCriterion"))
      {
        my $prefix = "Negative keyword";
      }
      printf "$prefix with text '%s', match type '%s', criteria type '%s', "
        . "and ID %d was found.\n",
        $ad_group_criterion->get_criterion()->get_text(),
        $ad_group_criterion->get_criterion()->get_matchType(),
        $ad_group_criterion->get_criterion()->get_type(),
        $ad_group_criterion->get_criterion()->get_id();
    });

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
get_keywords($client, $ad_group_id);
