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
# This example gets all campaign targeting criteris for a campaign.
# To add campaign targeting criteria, run
# targeting/add_campaign_targeting_criteria.pl. To get campaigns, run
# basic_operations/get_campaigns.pl.
#
# Tags: CampaignCriterionService.get
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201309::Selector;
use Google::Ads::AdWords::v201309::Paging;

use Cwd qw(abs_path);

use constant PAGE_SIZE => 500;

# Replace with valid values of your account.
my $campaign_id = "INSERT_CAMPAIGN_ID_HERE";

# Example main subroutine.
sub get_campaign_targeting_criteria {
  my $client = shift;
  my $campaign_id = shift;

  # Create predicate.
  my $campaign_predicate = Google::Ads::AdWords::v201309::Predicate->new({
    field => "CampaignId",
    operator => "IN",
    values => [$campaign_id]
  });

  # Create selector.
  my $paging = Google::Ads::AdWords::v201309::Paging->new({
    startIndex => 0,
    numberResults => PAGE_SIZE
  });
  my $selector = Google::Ads::AdWords::v201309::Selector->new({
    predicates => [$campaign_predicate],
    fields => ["Id", "CriteriaType", "CampaignId"],
    paging => $paging
  });

  # Paginate through results.
  my $page;
  do {
    # Get all campaign targets.
    $page = $client->CampaignCriterionService()->get({
      serviceSelector => $selector
    });
    # Display campaign targets.
    if ($page->get_entries()) {
      foreach my $campaign_criterion (@{$page->get_entries()}) {
        my $negative =
            $campaign_criterion->isa(
                "Google::Ads::AdWords::v201309::NegativeCampaignCriterion")
            ? "Negative "
            : "";
        printf $negative . "Campaign criterion with id \"%d\" and type " .
                   "\"%s\" was found for campaign id \"%s\".\n",
               $campaign_criterion->get_criterion()->get_id(),
               $campaign_criterion->get_criterion()->get_Criterion__Type(),
               $campaign_criterion->get_campaignId();
      }
    } else {
      print "No campaign criteria were found.\n";
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
get_campaign_targeting_criteria($client, $campaign_id);
