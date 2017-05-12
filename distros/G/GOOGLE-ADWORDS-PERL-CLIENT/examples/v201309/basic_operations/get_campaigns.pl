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
# This example gets all campaigns. To add a campaign, run
# basic_operations/add_campaign.pl.
#
# Tags: CampaignService.get
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201309::OrderBy;
use Google::Ads::AdWords::v201309::Paging;
use Google::Ads::AdWords::v201309::Predicate;
use Google::Ads::AdWords::v201309::Selector;

use constant PAGE_SIZE => 500;

use Cwd qw(abs_path);

# Example main subroutine.
sub get_campaigns {
  my $client = shift;

  # Create selector.
  my $paging = Google::Ads::AdWords::v201309::Paging->new({
    startIndex => 0,
    numberResults => PAGE_SIZE
  });
  my $selector = Google::Ads::AdWords::v201309::Selector->new({
    fields => ["Id", "Name"],
    ordering => [Google::Ads::AdWords::v201309::OrderBy->new({
      field => "Name",
      sortOrder => "ASCENDING"
    })],
    paging => $paging
  });

  # Paginate through results.
  my $page;
  do {
    # Get all campaigns.
    $page = $client->CampaignService()->get({serviceSelector => $selector});

    # Display campaigns.
    if ($page->get_entries()) {
      foreach my $campaign (@{$page->get_entries()}) {
        printf "Campaign with name \"%s\" and id \"%d\" was found.\n",
               $campaign->get_name(), $campaign->get_id();
      }
    }
    $paging->set_startIndex($paging->get_startIndex() + PAGE_SIZE);
  } while ($paging->get_startIndex() < $page->get_totalNumEntries());

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
get_campaigns($client);
