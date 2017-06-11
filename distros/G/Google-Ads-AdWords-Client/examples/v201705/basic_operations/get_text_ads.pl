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
# This example gets text ads in an ad group. To add text ads, run
# add_text_ads.pl. To get ad groups, run basic_operations/get_ad_groups.pl.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201705::OrderBy;
use Google::Ads::AdWords::v201705::Paging;
use Google::Ads::AdWords::v201705::Predicate;
use Google::Ads::AdWords::v201705::Selector;
use Google::Ads::AdWords::Utilities::PageProcessor;

use constant PAGE_SIZE => 500;

use Cwd qw(abs_path);

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";

# Example main subroutine.
sub get_text_ads {
  my $client      = shift;
  my $ad_group_id = shift;

  # Create predicates.
  my $ad_group_predicate = Google::Ads::AdWords::v201705::Predicate->new({
      field    => "AdGroupId",
      operator => "IN",
      values   => [$ad_group_id]});
  my $status_predicate = Google::Ads::AdWords::v201705::Predicate->new({
      field    => "Status",
      operator => "IN",
      values   => ["ENABLED", "PAUSED", "DISABLED"]});
  my $ad_type_predicate = Google::Ads::AdWords::v201705::Predicate->new({
      field    => "AdType",
      operator => "EQUALS",
      values   => ["TEXT_AD"]});

  # Create selector.
  my $paging = Google::Ads::AdWords::v201705::Paging->new({
      startIndex    => 0,
      numberResults => PAGE_SIZE
  });
  my $selector = Google::Ads::AdWords::v201705::Selector->new({
      fields => [
        "Id",           "Status", "Headline", "Description1",
        "Description2", "DisplayUrl"
      ],
      predicates =>
        [$ad_group_predicate, $status_predicate, $ad_type_predicate],
      ordering => [
        Google::Ads::AdWords::v201705::OrderBy->new({
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
      printf "Text ad with id \"%s\", and status \"%s\" was found:\n",
        $ad_group_ad->get_ad()->get_id(),
        $ad_group_ad->get_status();
      printf "%s\n%s\n%s\n%s\n\n",
        $ad_group_ad->get_ad()->get_headline(),
        $ad_group_ad->get_ad()->get_description1(),
        $ad_group_ad->get_ad()->get_description2(),
        $ad_group_ad->get_ad()->get_displayUrl();
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
my $client = Google::Ads::AdWords::Client->new({version => "v201705"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
get_text_ads($client, $ad_group_id);
