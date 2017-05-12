#!/usr/bin/perl -w
#
# Copyright 2013, Google Inc. All Rights Reserved.
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
# This example adds a Shared Bidding Strategy and uses it to
# construct a campaign.
#
# Tags: BiddingStrategyService.mutate
# Tags: BudgetService.mutate, CampaignService.mutate
# Author: Paul Matthews <api.pmatthews@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201402::SharedBiddingStrategy;
use Google::Ads::AdWords::v201402::TargetSpendBiddingScheme;
use Google::Ads::AdWords::v201402::Money;
use Google::Ads::AdWords::v201402::BiddingStrategyOperation;
use Google::Ads::AdWords::v201402::BudgetOperation;
use Google::Ads::AdWords::v201402::KeywordMatchSetting;
use Google::Ads::AdWords::v201402::NetworkSetting;
use Google::Ads::AdWords::v201402::CampaignOperation;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $budget_id = 0;

# Example main subroutine.
sub use_shared_bidding_strategy {
  my $client = shift;
  my $budget_id = shift;

  my $biddingStrategy = create_bidding_strategy($client);
  if (!$biddingStrategy) {
    return 0;
  }

  if (!$budget_id) {
    my $budget = create_shared_budget($client);
    if (!$budget) {
      return 0;
    }
    $budget_id = $budget->get_budgetId();
  }

  create_campaign_with_bidding_strategy($client, $biddingStrategy->get_id(),
      $budget_id);

  return 1;
}

# Creates the bidding strategy object.
sub create_bidding_strategy {
  my $client = shift;

  my @operations = ();

  # Create a shared bidding strategy.
  my $bidding_strategy =
      Google::Ads::AdWords::v201402::SharedBiddingStrategy->new({
        name => "Maximize Clicks " . uniqid(),
        type => "TARGET_SPEND",

        # Create the bidding scheme.
        biddingScheme =>
            Google::Ads::AdWords::v201402::TargetSpendBiddingScheme->new({
              # Optionally set additional bidding scheme parameters.
              bidCeiling => Google::Ads::AdWords::v201402::Money->new({
                microAmount => 2000000,
              })
            })
      });

  # Create operation.
  my $operation =
      Google::Ads::AdWords::v201402::BiddingStrategyOperation->new({
        operator => "ADD",
        operand => $bidding_strategy
      });

  push @operations, $operation;

  my $result = $client->BiddingStrategyService()->mutate({
    operations => \@operations
  });

  if ($result->get_value()) {
    my $strategy = $result->get_value()->[0];
    printf "Shared bidding strategy with name \"%s\" and ID %d of type %s " .
        "was created.\n", $strategy->get_name(), $strategy->get_id(),
        $strategy->get_biddingScheme()->get_BiddingScheme__Type();
    return $strategy;
  } else {
    print "No shared bidding strategies were added.\n";
    return 0;
  }
}

# Creates an explicit budget to be used only to create the Campaign.
sub create_shared_budget {
  my $client = shift;

  my @operations = ();

  # Create a shared budget operation.
  my $operation = Google::Ads::AdWords::v201402::BudgetOperation->new({
    operator => 'ADD',
    operand => Google::Ads::AdWords::v201402::Budget->new({
      period => 'DAILY',
      amount => Google::Ads::AdWords::v201402::Money->new({
        microAmount => 50000000
      }),
      deliveryMethod => 'STANDARD',
      isExplicitlyShared => 0
    })
  });

  push @operations, $operation;

  # Make the mutate request.
  my $result = $client->BudgetService()->mutate({ operations => \@operations });

  if ($result->get_value()) {
    return $result->get_value()->[0];
  } else {
    print "No budgets were added.\n";
    return 0;
  }
}

# Create a Campaign with a Shared Bidding Strategy.
sub create_campaign_with_bidding_strategy {
  my $client = shift;
  my $bidding_strategy_id = shift;
  my $budget_id = shift;

  my @operations = ();

  # Create campaign.
  my $campaign = Google::Ads::AdWords::v201402::Campaign->new({
    name => 'Interplanetary Cruise #' . uniqid(),
    budget => Google::Ads::AdWords::v201402::Budget->new({
      budgetId => $budget_id
    }),
    # Set bidding strategy (required).
    biddingStrategyConfiguration =>
        Google::Ads::AdWords::v201402::BiddingStrategyConfiguration->new({
          biddingStrategyId => $bidding_strategy_id
        }),
    # Set keyword matching setting (required).
    settings => [
        Google::Ads::AdWords::v201402::KeywordMatchSetting->new({
          optIn => 0
        })
    ],
    # Network targeting (recommended).
    networkSetting => Google::Ads::AdWords::v201402::NetworkSetting->new({
      targetGoogleSearch => 1,
      targetSearchNetwork => 1,
      targetContentNetwork => 1
    })
  });

  # Create operation.
  my $operation = Google::Ads::AdWords::v201402::CampaignOperation->new({
    operator => 'ADD',
    operand => $campaign
  });

  push @operations, $operation;

  my $result = $client->CampaignService()->mutate({
    operations => \@operations
  });

  if ($result->get_value()) {
    my $new_campaign = $result->get_value()->[0];
    printf "Campaign with name \"%s\", ID %d and bidding strategy ID %d was "
        . "created.\n", $new_campaign->get_name(), $new_campaign->get_id(),
          $new_campaign->get_biddingStrategyConfiguration()
              ->get_biddingStrategyId();
    return $new_campaign;
  } else {
    print "No campaigns were added.\n";
    return 0;
  }
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
use_shared_bidding_strategy($client, $budget_id);
