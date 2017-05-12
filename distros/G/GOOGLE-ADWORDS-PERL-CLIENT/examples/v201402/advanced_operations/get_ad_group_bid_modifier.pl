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
# Retrieves all the ad group level bid modifiers of the account.
#
# Tags: AdGroupAdService.get
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201402::OrderBy;
use Google::Ads::AdWords::v201402::Paging;
use Google::Ads::AdWords::v201402::Predicate;
use Google::Ads::AdWords::v201402::Selector;

use Cwd qw(abs_path);

use constant PAGE_SIZE => 500;

# Example main subroutine.
sub get_ad_group_bid_modifier {
  my $client = shift;

  # Create selector.
  my $paging = Google::Ads::AdWords::v201402::Paging->new({
    startIndex => 0,
    numberResults => PAGE_SIZE
  });
  my $selector = Google::Ads::AdWords::v201402::Selector->new({
    fields => ["CampaignId", "AdGroupId", "BidModifier", "Id"],
    paging => $paging
  });

  # Paginate through results.
  my $page;
  do {
    # Get a page of bid modifiers.
    $page = $client->AdGroupBidModifierService()->get({
      selector => $selector
    });

    # Display bid modifiers.
    if ($page->get_entries()) {
      foreach my $modifier (@{$page->get_entries()}) {
        my $modifier_value = $modifier->get_bidModifier() || "unset";
        printf "Campaign ID %s, AdGroup ID %s, Criterion ID %s has ad group " .
               "level modifier: %s\n", $modifier->get_campaignId(),
               $modifier->get_adGroupId(), $modifier->get_criterion()->get_id(),
               $modifier_value;
      }
    } else {
      print "No ad group level bid overrides returned.\n";
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
get_ad_group_bid_modifier($client);
