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
# This example gets all campaigns using AWQL. To add a campaign, run
# basic_operations/add_campaign.pl.

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

# Example main subroutine.
sub get_campaigns_with_awql {
  my $client = shift;

  # Get all the campaigns for this account.
  my $query = "SELECT Id, Name, Status ORDER BY Name";

  # Paginate through results.
  # The contents of the subroutine will be executed for each campaign.
  Google::Ads::AdWords::Utilities::PageProcessor->new({
      client    => $client,
      service   => $client->CampaignService(),
      query     => $query,
      page_size => PAGE_SIZE
    }
    )->process_entries(
    sub {
      my ($campaign) = @_;
      printf "Campaign with name \"%s\" and id \"%d\" was found.\n",
        $campaign->get_name(), $campaign->get_id();
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
get_campaigns_with_awql($client);
