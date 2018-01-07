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
# This example updates an ad group by setting the status to 'PAUSED' and by
# setting the CPC bid. To get ad groups, run basic_operations/get_ad_groups.pl.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201710::AdGroup;
use Google::Ads::AdWords::v201710::AdGroupOperation;
use Google::Ads::AdWords::v201710::BiddingStrategyConfiguration;
use Google::Ads::AdWords::v201710::CpcBid;
use Google::Ads::AdWords::v201710::Money;

use Cwd qw(abs_path);

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";
# Set this to undef if you do not want to update the CPC bid.
my $cpc_bid_micro_amount = "INSERT_CPC_BID_MICRO_AMOUNT_HERE";

# Example main subroutine.
sub update_ad_group {
  my ($client, $ad_group_id, $cpc_bid_micro_amount) = @_;
  # Create an ad group with the specified ID.
  # Pause the ad group.
  my $ad_group = Google::Ads::AdWords::v201710::AdGroup->new({
    id     => $ad_group_id,
    status => "PAUSED"
  });

  # Update the CPC bid if specified.
  if ($cpc_bid_micro_amount) {
    my $bidding_strategy_configuration =
      Google::Ads::AdWords::v201710::BiddingStrategyConfiguration->new({
        bids => [
          Google::Ads::AdWords::v201710::CpcBid->new({
              bid => Google::Ads::AdWords::v201710::Money->new({
                  microAmount => $cpc_bid_micro_amount
              }),
            }),
        ]
      });
    $ad_group->set_biddingStrategyConfiguration(
      $bidding_strategy_configuration);
  }

  # Create operation.
  my $operation = Google::Ads::AdWords::v201710::AdGroupOperation->new({
    operand  => $ad_group,
    operator => "SET"
  });

  # Update ad group.
  my $result = $client->AdGroupService()->mutate({operations => [$operation]});

  # Display ad groups.
  foreach my $ad_group_result (@{$result->get_value()}) {
    my $bidding_strategy_configuration =
      $ad_group_result->get_biddingStrategyConfiguration();
    # Find the CpcBid in the bidding strategy configuration's bids collection.
    my $cpc_bid_micros = undef;
    if ($bidding_strategy_configuration) {
      if ($bidding_strategy_configuration->get_bids()) {
        foreach my $bid (@{$bidding_strategy_configuration->get_bids()}) {
          if ($bid->isa("Google::Ads::AdWords::v201710::CpcBid")) {
            $cpc_bid_micros = $bid->get_bid()->get_microAmount();
            last;
          }
        }
      }
    }
    printf("Ad group with ID %d and name '%s' updated to have status '%s' " .
      "and CPC bid %s\n", $ad_group_result->get_id(),
      $ad_group_result->get_name(), $ad_group_result->get_status(),
      ($cpc_bid_micros) ? $cpc_bid_micros : "undef"
    );

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
update_ad_group($client, $ad_group_id, $cpc_bid_micro_amount);
