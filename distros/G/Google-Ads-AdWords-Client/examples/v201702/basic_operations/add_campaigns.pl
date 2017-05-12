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
# This example adds campaigns.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201702::BiddingStrategyConfiguration;
use Google::Ads::AdWords::v201702::Budget;
use Google::Ads::AdWords::v201702::BudgetOperation;
use Google::Ads::AdWords::v201702::Campaign;
use Google::Ads::AdWords::v201702::CampaignOperation;
use Google::Ads::AdWords::v201702::FrequencyCap;
use Google::Ads::AdWords::v201702::GeoTargetTypeSetting;
use Google::Ads::AdWords::v201702::ManualCpcBiddingScheme;
use Google::Ads::AdWords::v201702::Money;
use Google::Ads::AdWords::v201702::NetworkSetting;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

sub add_campaigns {
  my $client = shift;

  # Create a budget, which can be shared by multiple campaigns.
  my $budget = Google::Ads::AdWords::v201702::Budget->new({
      # Required attributes.
      name => "Interplanetary budget #" . uniqid(),
      amount =>
        Google::Ads::AdWords::v201702::Money->new({microAmount => 5000000}),
      deliveryMethod => "STANDARD"
  });

  my $budget_operation = Google::Ads::AdWords::v201702::BudgetOperation->new({
      operator => "ADD",
      operand  => $budget
  });

  # Add budget.
  my $budgetId =
    $client->BudgetService()->mutate({operations => ($budget_operation)})
    ->get_value()->get_budgetId()->get_value();

  # Create campaigns.
  my $num_campaigns = 2;
  my @operations    = ();
  for (my $i = 0 ; $i < $num_campaigns ; $i++) {
    my (undef, undef, undef, $mday, $mon, $year) = localtime(time);
    my $today = sprintf("%d%02d%02d", ($year + 1900), ($mon + 1), $mday);
    (undef, undef, undef, $mday, $mon, $year) = localtime(time + 60 * 60 * 24);
    my $tomorrow = sprintf("%d%02d%02d", ($year + 1900), ($mon + 1), $mday);
    my $campaign = Google::Ads::AdWords::v201702::Campaign->new({
        name => "Interplanetary Cruise #" . uniqid(),
        # Bidding strategy (required).
        biddingStrategyConfiguration =>
          Google::Ads::AdWords::v201702::BiddingStrategyConfiguration->new({
            biddingStrategyType => "MANUAL_CPC",
            # You can optionally provide a bidding scheme in place of the type.
          }
          ),
        # Budget (required) - note only the budgetId is required.
        budget =>
          Google::Ads::AdWords::v201702::Budget->new({budgetId => $budgetId}),
        # Create a Search Network with Display Select campaign.
        # To create a Display Only campaign, omit networkSetting and use the
        # DISPLAY advertisingChannelType.
        # NetworkSetting (optional).
        networkSetting => Google::Ads::AdWords::v201702::NetworkSetting->new({
            targetGoogleSearch         => 1,
            targetSearchNetwork        => 1,
            targetContentNetwork       => 1,
            targetPartnerSearchNetwork => 0
          }
        ),
        # Advertising channel type (required).
        advertisingChannelType => "SEARCH",
        # Frequency cap (non-required).
        frequencyCap => Google::Ads::AdWords::v201702::FrequencyCap->new({
            impressions => 5,
            timeUnit    => "DAY",
            level       => "ADGROUP"
          }
        ),
        settings => [
          # Advanced location targeting settings (non-required).
          Google::Ads::AdWords::v201702::GeoTargetTypeSetting->new({
              positiveGeoTargetType => "DONT_CARE",
              negativeGeoTargetType => "DONT_CARE"
            }
          ),
        ],
        # Additional properties (non-required).
        startDate                   => $today,
        endDate                     => $tomorrow,
        # Recommendation: Set the campaign to PAUSED when creating it to stop
        # the ads from immediately serving. Set to ENABLED once you've added
        # targeting and the ads are ready to serve.
        status                      => "PAUSED",
        adServingOptimizationStatus => "ROTATE"
      });

    # Create operation.
    my $campaign_operation =
      Google::Ads::AdWords::v201702::CampaignOperation->new({
        operator => "ADD",
        operand  => $campaign
      });
    push @operations, $campaign_operation;
  }

  # Add campaigns.
  my $result = $client->CampaignService()->mutate({operations => \@operations});

  # Display campaigns.
  foreach my $campaign (@{$result->get_value()}) {
    printf "Campaign with name \"%s\" and id \"%s\" was added.\n",
      $campaign->get_name(), $campaign->get_id();
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
my $client = Google::Ads::AdWords::Client->new({version => "v201702"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_campaigns($client);
