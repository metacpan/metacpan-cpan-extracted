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
# This example gets all ad groups in a campaign. To add ad groups, run
# basic_operations/add_ad_group.pl. To get campaigns, run
# basic_operations/get_campaigns.pl.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201702::OrderBy;
use Google::Ads::AdWords::v201702::Paging;
use Google::Ads::AdWords::v201702::Predicate;
use Google::Ads::AdWords::v201702::Selector;
use Google::Ads::AdWords::Utilities::PageProcessor;

use constant PAGE_SIZE => 500;

# Replace with valid values of your account.
my $campaign_id = "INSERT_CAMPAIGN_ID_HERE";

use Cwd qw(abs_path);

# Example main subroutine.
sub get_ad_groups {
  my $client      = shift;
  my $campaign_id = shift;

  # Create predicates.
  my $campaign_predicate = Google::Ads::AdWords::v201702::Predicate->new({
      field    => "CampaignId",
      operator => "IN",
      values   => [$campaign_id]});

  # Create selector.
  my $paging = Google::Ads::AdWords::v201702::Paging->new({
      startIndex    => 0,
      numberResults => PAGE_SIZE
  });
  my $selector = Google::Ads::AdWords::v201702::Selector->new({
      fields     => ["Id", "Name"],
      predicates => [$campaign_predicate],
      ordering   => [
        Google::Ads::AdWords::v201702::OrderBy->new({
            field     => "Name",
            sortOrder => "ASCENDING"
          })
      ],
      paging => $paging
    });

  # Paginate through results.
  # The contents of the subroutine will be executed for each ad group.
  Google::Ads::AdWords::Utilities::PageProcessor->new({
      client   => $client,
      service  => $client->AdGroupService(),
      selector => $selector
    }
    )->process_entries(
    sub {
      my ($ad_group) = @_;
      printf "Ad group with name \"%s\" and id \"%d\" was found.\n",
        $ad_group->get_name(), $ad_group->get_id();
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
my $client = Google::Ads::AdWords::Client->new({version => "v201702"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
get_ad_groups($client, $campaign_id);
