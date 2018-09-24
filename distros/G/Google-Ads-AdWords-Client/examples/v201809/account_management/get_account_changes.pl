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
# This example gets all account changes that happened within the last 24 hours,
# for all your campaigns.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201809::CustomerSyncSelector;
use Google::Ads::AdWords::v201809::DateTimeRange;
use Google::Ads::AdWords::v201809::Selector;

use Cwd qw(abs_path);

sub get_formatted_list ($);

# Example main subroutine.
sub get_account_changes {
  my $client = shift;

  # A date range of last 24 hours.
  my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time - (60 * 60 * 24));
  my $min_date_time = sprintf(
    "%d%02d%02d %02d%02d%02d",
    ($year + 1900),
    ($mon + 1),
    $mday, $hour, $min, $sec
  );
  ($sec, $min, $hour, $mday, $mon, $year) = localtime(time);
  my $max_date_time = sprintf(
    "%d%02d%02d %02d%02d%02d",
    ($year + 1900),
    ($mon + 1),
    $mday, $hour, $min, $sec
  );

  # Get a list of all campaign ids.
  my @campaign_ids = ();
  my $campaigns    = $client->CampaignService()->get({
      serviceSelector =>
        Google::Ads::AdWords::v201809::Selector->new({fields => ["Id"]})});
  if ($campaigns->get_entries()) {
    foreach my $campaign (@{$campaigns->get_entries()}) {
      push @campaign_ids, $campaign->get_id();
    }
  }

  # Create date time range.
  my $date_time_range = Google::Ads::AdWords::v201809::DateTimeRange->new({
      min => $min_date_time,
      max => $max_date_time
  });

  # Create selector.
  my $selector = Google::Ads::AdWords::v201809::CustomerSyncSelector->new({
      dateTimeRange => $date_time_range,
      campaignIds   => \@campaign_ids
  });

  # Get all account changes for campaign.
  my $account_changes =
    $client->CustomerSyncService()->get({selector => $selector});

  # Display changes.
  if ($account_changes && $account_changes->get_changedCampaigns()) {
    printf "Displaying changes up to: %s\n",
      $account_changes->get_lastChangeTimestamp();
    foreach my $campaign_changes (@{$account_changes->get_changedCampaigns()}) {
      printf "Campaign with id \"%d\" was changed:\n",
        $campaign_changes->get_campaignId();
      printf "\tCampaign changed status: %s\n",
        $campaign_changes->get_campaignChangeStatus();
      if ($campaign_changes->get_campaignChangeStatus() ne "NEW") {
        printf "\tAdded campaign criteria: %s\n",
          get_formatted_list($campaign_changes->get_addedCampaignCriteria());
        printf "\tRemoved campaign criteria: %s\n",
          get_formatted_list($campaign_changes->get_removedCampaignCriteria());

        if ($campaign_changes->get_changedAdGroups()) {
          foreach
            my $ad_group_changes (@{$campaign_changes->get_changedAdGroups()})
          {
            printf "\tAd group with id \"%d\" was changed:\n",
              $ad_group_changes->get_adGroupId();
            printf "\t\tAd group changed status: %s\n",
              $ad_group_changes->get_adGroupChangeStatus();
            if ($ad_group_changes->get_adGroupChangeStatus() ne "NEW") {
              printf "\t\tAds changed: %s\n",
                get_formatted_list($ad_group_changes->get_changedAds());
              printf "\t\tCriteria changed: %s\n",
                get_formatted_list($ad_group_changes->get_changedCriteria());
              printf "\t\tCriteria removed: %s\n",
                get_formatted_list($ad_group_changes->get_removedCriteria());
            }
          }
        }
      }
      print "\n";
    }
  } else {
    print "No account changes were found.\n";
  }

  return 1;
}

sub get_formatted_list ($) {
  my $list = $_[0];
  if (!$list) {
    return "{ }";
  }
  return "{ " . join(", ", @{$list}) . " }";
}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
  return 1;
}

# Log SOAP XML request, response and API errors.
Google::Ads::AdWords::Logging::enable_all_logging();

# Get AdWords Client, credentials will be read from ~/adwords.properties.
my $client = Google::Ads::AdWords::Client->new({version => "v201809"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
get_account_changes($client);
