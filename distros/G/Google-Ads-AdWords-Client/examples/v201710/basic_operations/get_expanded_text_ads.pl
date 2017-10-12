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
# This example gets non-removed expanded text ads in an ad group. To add
# expanded text ads, run add_expanded_text_ads.pl.
# To get ad groups, run get_ad_groups.pl.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201710::OrderBy;
use Google::Ads::AdWords::v201710::Paging;
use Google::Ads::AdWords::v201710::Predicate;
use Google::Ads::AdWords::v201710::Selector;
use Google::Ads::AdWords::Utilities::PageProcessor;

use constant PAGE_SIZE => 500;

use Cwd qw(abs_path);

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";

# Example main subroutine.
sub get_expanded_text_ads {
  my $client      = shift;
  my $ad_group_id = shift;

  # Create predicates.
  my $ad_group_predicate = Google::Ads::AdWords::v201710::Predicate->new({
      field    => "AdGroupId",
      operator => "IN",
      values   => [$ad_group_id]});
  my $status_predicate = Google::Ads::AdWords::v201710::Predicate->new({
      field    => "Status",
      operator => "IN",
      values   => ["ENABLED", "PAUSED"]});
  my $ad_type_predicate = Google::Ads::AdWords::v201710::Predicate->new({
      field    => "AdType",
      operator => "EQUALS",
      values   => ["EXPANDED_TEXT_AD"]});

  # Create selector.
  my $paging = Google::Ads::AdWords::v201710::Paging->new({
      startIndex    => 0,
      numberResults => PAGE_SIZE
  });
  my $selector = Google::Ads::AdWords::v201710::Selector->new({
      fields =>
        ["Id", "Status", "HeadlinePart1", "HeadlinePart2", "Description"],
      predicates =>
        [$ad_group_predicate, $status_predicate, $ad_type_predicate],
      ordering => [
        Google::Ads::AdWords::v201710::OrderBy->new({
            field     => "Id",
            sortOrder => "ASCENDING"
          })
      ],
      paging => $paging
    });

  # Paginate through results.
  # The contents of the subroutine will be executed for each text ad.
  Google::Ads::AdWords::Utilities::PageProcessor->new({
      client   => $client,
      service  => $client->AdGroupAdService(),
      selector => $selector
    }
    )->process_entries(
    sub {
      my ($ad_group_ad) = @_;
      printf "Expanded text ad with id \"%d\", status \"%s\", and " .
        "headline \"%s - %s\" was found.\n",
        $ad_group_ad->get_ad()->get_id(),
        $ad_group_ad->get_status(),
        $ad_group_ad->get_ad()->get_headlinePart1(),
        $ad_group_ad->get_ad()->get_headlinePart2();
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
my $client = Google::Ads::AdWords::Client->new({version => "v201710"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
get_expanded_text_ads($client, $ad_group_id);
