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
# This example gets all alerts for all clients of an MCC account. The effective
# user (clientCustomerId, or authToken) must be an MCC user to
# get results.
#
# Note: This example won't work if your token is not approved and you are only
# targeting test accounts. See
# https://developers.google.com/adwords/api/docs/test-accounts
#
# Tags: AlertService.get
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201402::AlertQuery;
use Google::Ads::AdWords::v201402::AlertSelector;
use Google::Ads::AdWords::v201402::Paging;

use Cwd qw(abs_path);

use constant PAGE_SIZE => 500;

# Example main subroutine.
sub get_account_alerts {
  my $client = shift;

  # Force to use the MCC credentials.
  $client->set_client_id(undef);

  # Create alert query.
  my $alert_query = new Google::Ads::AdWords::v201402::AlertQuery({
    clientSpec => "ALL",
    filterSpec => "ALL",
    types => ["ACCOUNT_BUDGET_BURN_RATE","ACCOUNT_BUDGET_ENDING",
              "ACCOUNT_ON_TARGET","CAMPAIGN_ENDED","CAMPAIGN_ENDING",
              "CREDIT_CARD_EXPIRING","DECLINED_PAYMENT",
              "MANAGER_LINK_PENDING","MISSING_BANK_REFERENCE_NUMBER",
              "PAYMENT_NOT_ENTERED","TV_ACCOUNT_BUDGET_ENDING",
              "TV_ACCOUNT_ON_TARGET","TV_ZERO_DAILY_SPENDING_LIMIT",
              "USER_INVITE_ACCEPTED","USER_INVITE_PENDING",
              "ZERO_DAILY_SPENDING_LIMIT"],
    severities => ["GREEN", "YELLOW", "RED"],
    triggerTimeSpec => "ALL_TIME"
  });

  # Create selector.
  my $paging = Google::Ads::AdWords::v201402::Paging->new({
    startIndex => 0,
    numberResults => PAGE_SIZE
  });
  my $selector = Google::Ads::AdWords::v201402::AlertSelector->new({
    query => $alert_query,
    paging => $paging
  });

  # Paginate through results.
  my $page;
  do {
    # Get a page of alerts.
    $page = $client->AlertService()->get({
      selector => $selector
    });

    # Display alerts.
    if ($page->get_entries()) {
      foreach my $alert (@{$page->get_entries()}) {
        printf "Alert of type '%s' and severity '%s' for account '%s' was "
               . "found.\n", $alert->get_alertType(),
               $alert->get_alertSeverity(), $alert->get_clientCustomerId();
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
my $client = Google::Ads::AdWords::Client->new({version => "v201402"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
get_account_alerts($client);
