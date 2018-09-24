#!/usr/bin/perl -w
#
# Copyright 2018 Google LLC
#
# License:: Licensed under the Apache License, Version 2.0 (the "License");
#           you may not use this file except in compliance with the License.
#           You may obtain a copy of the License at
#
#           http://www.apache.org/licenses/LICENSE-2.0
#
#           Unless required by applicable law or agreed to in writing, software
#           distributed under the License is distributed on an "AS IS" BASIS,
#           WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
#           implied.
#           See the License for the specific language governing permissions and
#           limitations under the License.
#
# This example gets non-removed responsive search ads in an ad group. To add
# responsive search ads, run add_responsive_search_ad.pl.
# To get ad groups, run get_ad_groups.pl.

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

use constant PAGE_SIZE => 500;

use Cwd qw(abs_path);

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";

# Example main subroutine.
sub get_responsive_search_ads {
  my ($client, $ad_group_id) = @_;

  # Get all the ads for this ad group.
  my $ad_group_predicate = Google::Ads::AdWords::v201809::Predicate->new({
      field    => "AdGroupId",
      operator => "IN",
      values   => [ $ad_group_id ] });
  my $status_predicate = Google::Ads::AdWords::v201809::Predicate->new({
      field    => "Status",
      operator => "IN",
      values   => [ "ENABLED", "PAUSED" ] });
  my $ad_type_predicate = Google::Ads::AdWords::v201809::Predicate->new({
      field    => "AdType",
      operator => "EQUALS",
      values   => [ "RESPONSIVE_SEARCH_AD" ] });

  # Create selector.
  my $paging = Google::Ads::AdWords::v201809::Paging->new({
      startIndex    => 0,
      numberResults => PAGE_SIZE
  });
  my $selector = Google::Ads::AdWords::v201809::Selector->new({
      fields     =>
          [ "Id", "Status", "ResponsiveSearchAdHeadlines",
              "ResponsiveSearchAdDescriptions" ],
      predicates =>
          [ $ad_group_predicate, $status_predicate, $ad_type_predicate ],
      ordering   => [
          Google::Ads::AdWords::v201809::OrderBy->new({
              field     => "Id",
              sortOrder => "ASCENDING"
          })
      ],
      paging     => $paging
  });

  # Paginate through results.
  # The contents of the subroutine will be executed for each ad.
  Google::Ads::AdWords::Utilities::PageProcessor->new({
      client   => $client,
      service  => $client->AdGroupAdService(),
      selector => $selector
  }
  )->process_entries(
      sub {
        my ($ad_group_ad) = @_;
        printf "Responsive search ad with ID %d and status %s was found.\n",
            $ad_group_ad->get_ad()->get_id(),
            $ad_group_ad->get_status();
        printf "  Headlines:\n";
        foreach my $headline (@{$ad_group_ad->get_ad()->get_headlines()}) {
          my $pinned = $headline->get_pinnedField();
          printf "    %s\n", $headline->get_asset()->get_assetText();
          if ($pinned) {
            printf "      (pinned to %s)\n", $pinned;
          }
        }
        printf "  Descriptions:\n";
        foreach my $description
          (@{$ad_group_ad->get_ad()->get_descriptions()}) {
          my $pinned = $description->get_pinnedField();
          printf "    %s\n", $description->get_asset()->get_assetText();
          if ($pinned) {
            printf "      (pinned to %s)\n", $pinned;
          }
        }
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
my $client = Google::Ads::AdWords::Client->new({ version => "v201809" });

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
get_responsive_search_ads($client, $ad_group_id);
