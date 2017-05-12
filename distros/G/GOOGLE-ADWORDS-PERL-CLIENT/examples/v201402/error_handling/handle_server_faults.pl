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
# This example shows how to handle server faults, and how to access the server
# fault information.
#
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201402::BiddingStrategyConfiguration;
use Google::Ads::AdWords::v201402::Budget;
use Google::Ads::AdWords::v201402::Campaign;
use Google::Ads::AdWords::v201402::CampaignOperation;
use Google::Ads::AdWords::v201402::ConversionOptimizerBiddingScheme;
use Google::Ads::AdWords::v201402::Money;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Example main subroutine.
sub handle_server_faults {
  my $client = shift;

  # Don't die on fault it will be handled in code.
  $client->set_die_on_faults(0);

  # Create campaign.
  my (undef, undef, undef, $mday, $mon, $year) = localtime(time);
  my $today = sprintf("%d%02d%02d", ($year + 1900), ($mon + 1), $mday);
  my $campaign = Google::Ads::AdWords::v201402::Campaign->new({
    startDate => $today,
    name => "Interplanetary Cruise #" . uniqid(),
    status => "PAUSED"
  });

  # Set an invalid bidding strategy this will trigger a server error.
  my $biddingStrategyConfiguration =
      Google::Ads::AdWords::v201402::BiddingStrategyConfiguration->new({
        biddingStrategyType => "CONVERSION_OPTIMIZER",
        biddingScheme =>
            Google::Ads::AdWords::v201402::ConversionOptimizerBiddingScheme->
                new({
                  pricingMode => "CLICKS",
                  bidType => "TARGET_CPA"
                })
      });

  $campaign->set_biddingStrategyConfiguration($biddingStrategyConfiguration);
  my $budget = Google::Ads::AdWords::v201402::Budget->new({
    amount => Google::Ads::AdWords::v201402::Money->new({
      microAmount => 50000000
    }),
    deliveryMethod => "STANDARD",
    period => "DAILY"
  });
  $campaign->set_budget($budget);

  # Generate the mutate operation.
  my $campaignOperation =
      Google::Ads::AdWords::v201402::CampaignOperation->new({
        operator => "ADD",
        operand => $campaign
      });

  # Invoke the service.
  my $response =
    $client->CampaignService()->mutate({operations => ($campaignOperation)});

  # Display results.
  if ($response->isa("SOAP::WSDL::SOAP::Typelib::Fault11")) {
    printf "Can't create campaign, error: \"%s\"\n",
           $response->get_faultstring();
  } else {
    printf "Created new campaign with id: \"%d\"\n",
           $response->get_value()->[0]->get_id();
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
my $client = Google::Ads::AdWords::Client->new({version => "v201402"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
handle_server_faults($client);
