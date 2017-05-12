#!/usr/bin/perl -w
#
# Copyright 2016, Google Inc. All Rights Reserved.
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
# This example adds ad groups to a campaign. To get campaigns, run
# get_all_campaigns.pl.

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201607::AdGroup;
use Google::Ads::AdWords::v201607::AdGroupOperation;
use Google::Ads::AdWords::v201607::BiddingStrategyConfiguration;
use Google::Ads::AdWords::v201607::CpcBid;
use Google::Ads::AdWords::v201607::Money;
use Google::Ads::AdWords::v201607::TargetingSetting;
use Google::Ads::AdWords::v201607::TargetingSettingDetail;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $campaign_id = "INSERT_CAMPAIGN_ID_HERE";

# Example main subroutine.
sub add_ad_groups {
  my $client      = shift;
  my $campaign_id = shift;

  my $num_ad_groups = 2;
  my @operations    = ();
  for (my $i = 0 ; $i < $num_ad_groups ; $i++) {
    # Create ad group.
    my $ad_group = Google::Ads::AdWords::v201607::AdGroup->new({
        name       => "Earth to Mars Cruises #" . uniqid(),
        campaignId => $campaign_id,
        biddingStrategyConfiguration =>
          Google::Ads::AdWords::v201607::BiddingStrategyConfiguration->new({
            bids => [
              Google::Ads::AdWords::v201607::CpcBid->new({
                  bid => Google::Ads::AdWords::v201607::Money->new(
                    {microAmount => 1000000}
                  ),
                }
              ),
            ]}
          ),
        # Additional properties (non-required).
        status   => "ENABLED",
        settings => [
          # Targeting restriction settings. Depending on the
          # criterionTypeGroup value, most TargetingSettingDetail only
          # affect Display campaigns. However, the USER_INTEREST_AND_LIST
          # value works for RLSA campaigns - Search campaigns targeting
          # using a remarketing list.
          Google::Ads::AdWords::v201607::TargetingSetting->new({
              details => [
                # Restricting to serve ads that match your ad group placements.
                # This is equivalent to choosing "Target and bid" in the UI.
                Google::Ads::AdWords::v201607::TargetingSettingDetail->new({
                    criterionTypeGroup => "PLACEMENT",
                    targetAll          => 0
                  }
                ),
                # Using your ad group verticals only for bidding. This is equivalent
                # to choosing "Bid only" in the UI.
                Google::Ads::AdWords::v201607::TargetingSettingDetail->new({
                    criterionTypeGroup => "VERTICAL",
                    targetAll          => 1
                  })]})]});
    # Create operation.
    my $ad_group_operation =
      Google::Ads::AdWords::v201607::AdGroupOperation->new({
        operator => "ADD",
        operand  => $ad_group
      });
    push @operations, $ad_group_operation;
  }

  # Add ad groups.
  my $result = $client->AdGroupService()->mutate({operations => \@operations});

  # Display ad groups.
  foreach my $ad_group (@{$result->get_value()}) {
    printf "Ad group with name \"%s\" and id \"%d\" was added.\n",
      $ad_group->get_name(), $ad_group->get_id();
  }

  return 1;
}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
  return 1;
}

# Log SOAP XML request, response and API errors.
Google::Ads::AdWords::Logging::enable_all_logging();

# Get AdWords Client, credentials will be read from ~/adwords.properties.
my $client = Google::Ads::AdWords::Client->new({version => "v201607"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_ad_groups($client, $campaign_id);
