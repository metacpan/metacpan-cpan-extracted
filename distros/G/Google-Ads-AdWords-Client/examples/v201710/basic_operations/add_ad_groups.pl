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
# This example adds ad groups to a campaign. To get campaigns, run
# get_all_campaigns.pl.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201710::AdGroup;
use Google::Ads::AdWords::v201710::AdGroupAdRotationMode;
use Google::Ads::AdWords::v201710::AdGroupOperation;
use Google::Ads::AdWords::v201710::BiddingStrategyConfiguration;
use Google::Ads::AdWords::v201710::CpcBid;
use Google::Ads::AdWords::v201710::Money;
use Google::Ads::AdWords::v201710::TargetingSetting;
use Google::Ads::AdWords::v201710::TargetingSettingDetail;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $campaign_id = "INSERT_CAMPAIGN_ID_HERE";

# Example main subroutine.
sub add_ad_groups {
  my ($client, $campaign_id) = @_;

  my @operations = ();

  # Create ad group.
  my $ad_group = Google::Ads::AdWords::v201710::AdGroup->new({
    name       => sprintf("Earth to Mars Cruises #%s", uniqid()),
    status     => "ENABLED",
    campaignId => $campaign_id
  });

  # Optional settings.

  # Restricting to serve ads that match your ad group placements.
  # This is equivalent to choosing "Target and bid" in the UI.
  my $placements = Google::Ads::AdWords::v201710::TargetingSettingDetail->new({
    criterionTypeGroup => "PLACEMENT",
    targetAll          => 0
  });

  # Using your ad group verticals only for bidding. This is equivalent
  # to choosing "Bid only" in the UI.
  my $verticals = Google::Ads::AdWords::v201710::TargetingSettingDetail->new({
    criterionTypeGroup => "VERTICAL",
    targetAll          => 1
  });

  # Targeting restriction settings. Depending on the criterionTypeGroup value,
  # most TargetingSettingDetail only affect Display campaigns. However, the
  # USER_INTEREST_AND_LIST value works for RLSA campaigns - Search campaigns
  # targeting using a remarketing list.
  my $targeting = Google::Ads::AdWords::v201710::TargetingSetting->new({
      details => [$placements, $verticals]});
  $ad_group->set_settings([$targeting]);

  # Set the rotation mode.
  my $rotation_mode = Google::Ads::AdWords::v201710::AdGroupAdRotationMode->new(
    {
      adRotationMode => 'OPTIMIZE'
    });
  $ad_group->set_adGroupAdRotationMode($rotation_mode);

  # Create ad group bid.
  my $bidding_strategy_configuration =
    Google::Ads::AdWords::v201710::BiddingStrategyConfiguration->new({
      bids => [
        Google::Ads::AdWords::v201710::CpcBid->new({
            bid => Google::Ads::AdWords::v201710::Money->new({
                microAmount => 1000000
              }
            ),
          }
        ),
      ]});
  $ad_group->set_biddingStrategyConfiguration($bidding_strategy_configuration);

  # Add as many additional ad groups as you need.
  my $ad_group_2 = Google::Ads::AdWords::v201710::AdGroup->new({
    name       => sprintf("Earth to Mars Cruises #%s", uniqid()),
    status     => "ENABLED",
    campaignId => $campaign_id
  });

  my $bidding_strategy_configuration_2 =
    Google::Ads::AdWords::v201710::BiddingStrategyConfiguration->new({
      bids => [
        Google::Ads::AdWords::v201710::CpcBid->new({
            bid => Google::Ads::AdWords::v201710::Money->new({
                microAmount => 1000000
              }
            ),
          }
        ),
      ]});
  $ad_group_2->set_biddingStrategyConfiguration(
    $bidding_strategy_configuration_2);

  # Create operations.
  my $operation = Google::Ads::AdWords::v201710::AdGroupOperation->new({
    operator => "ADD",
    operand  => $ad_group
  });
  push @operations, $operation;
  my $operation_2 = Google::Ads::AdWords::v201710::AdGroupOperation->new({
    operator => "ADD",
    operand  => $ad_group_2
  });
  push @operations, $operation_2;

  # Add ad groups.
  my $result = $client->AdGroupService()->mutate({operations => \@operations});

  # Display ad groups.
  foreach my $ad_group (@{$result->get_value()}) {
    printf "Ad group with name \"%s\" and ID %d was added.\n",
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
my $client = Google::Ads::AdWords::Client->new({version => "v201710"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_ad_groups($client, $campaign_id);
