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
# This example shows the use of an XPath expression to gather all campaign
# budget objects from an API response. In general any object returned from a
# service call is able to accept XPath queries.
#
# Tags: CampaignService.get
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201402::OrderBy;
use Google::Ads::AdWords::v201402::Selector;
use Google::Ads::AdWords::v201402::Paging;

use Cwd qw(abs_path);

use constant PAGE_SIZE => 500;

# Example main subroutine.
sub use_xpath {
  my $client = shift;

  # Create selector.
  my $paging = Google::Ads::AdWords::v201402::Paging->new({
    startIndex => 0,
    numberResults => PAGE_SIZE
  });
  my $selector = Google::Ads::AdWords::v201402::Selector->new({
    fields => ["Amount", "DeliveryMethod", "Period"],
    paging => $paging
  });

  # Paginate through results.
  my $page;
  do {
    # Get a page of campaigns.
    $page = $client->CampaignService()->get({serviceSelector => $selector});

    # Get all campaigns and then find all associated budgets.
    my $budgets = $client->CampaignService()->
        get({serviceSelector => $selector})->find('//entries/budget');

    # Display budgets.
    foreach my $budget (@{$budgets}) {
      printf "Budget with period \"%s\", amount \"%s\" and delivery method " .
             "\"%s\" was found.\n", $budget->get_period(),
             $budget->get_amount()->get_microAmount(),
             $budget->get_deliveryMethod();
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
my $client = Google::Ads::AdWords::Client->new({version => "v201402"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
use_xpath($client);
