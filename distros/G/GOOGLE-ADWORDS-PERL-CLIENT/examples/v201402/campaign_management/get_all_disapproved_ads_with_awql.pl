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
# This example gets all disapproved ads in an ad group using AWQL.
# To add ads, run basic_operations/add_text_ads.pl. To get ad groups, run
# basic_operations/get_ad_groups.pl.
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

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";

# Example main subroutine.
sub get_all_disapproved_ads_with_awql {
  my $client = shift;
  my $ad_group_id = shift;

  # Get all the disapproved ads for the given ad group.
  my $query = "SELECT Id, AdGroupAdDisapprovalReasons WHERE AdGroupId = " .
              "${ad_group_id} AND AdGroupCreativeApprovalStatus = " .
              "DISAPPROVED ORDER BY Id";

  # Paginate through results.
  my $page;
  my $offset = 0;
  do {
    my $page_query = "${query} LIMIT ${offset}," . PAGE_SIZE;

    # Get a page of dissaproved ads.
    $page = $client->AdGroupAdService()->query({query => $page_query});

    # Display ad parameters.
    if ($page->get_entries()) {
      foreach my $ad_group_ad (@{$page->get_entries()}) {
        printf "Ad with id \"%s\" and type \"%s\" was disapproved for the " .
               "following reasons:\n", $ad_group_ad->get_ad()->get_id(),
               $ad_group_ad->get_ad()->get_Ad__Type();
        foreach my $reason
            (@{$ad_group_ad->get_ad()->get_disapprovalReasons()}) {
          printf "  \"%s\"\n", $reason;
        }
      }
    } else {
      print "No disapproved ads were found.\n";
    }
    $offset += PAGE_SIZE;
  } while ($offset < $page->get_totalNumEntries());

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
get_all_disapproved_ads_with_awql($client, $ad_group_id);
