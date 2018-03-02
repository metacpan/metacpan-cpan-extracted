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
# This example sets a bid modifier for the mobile platform on given campaign.
# To get campaigns, run basic_operations/get_campaigns.pl.

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201802::CampaignCriterionOperation;
use Google::Ads::AdWords::v201802::Platform;

use Cwd qw(abs_path);

use constant BID_MODIFIER => 1.5;

# Replace with valid values of your account.
my $campaign_id = "INSERT_CAMPAIGN_ID_HERE";

# Example main subroutine.
sub set_bid_modifier {
  my $client      = shift;
  my $campaign_id = shift;

  # Create mobile platform. The ID can be found in the documentation.
  # https://developers.google.com/adwords/api/docs/appendix/platforms
  my $mobile = Google::Ads::AdWords::v201802::Platform->new({id => 30001});

  # Create criterion with modified bid.
  my $criterion = Google::Ads::AdWords::v201802::CampaignCriterion->new({
      campaignId  => $campaign_id,
      criterion   => $mobile,
      bidModifier => BID_MODIFIER
  });

  # Create SET operation.
  my $operation =
    Google::Ads::AdWords::v201802::CampaignCriterionOperation->new({
      operator => "SET",
      operand  => $criterion
    });

  # Update campaign criteria.
  my $result =
    $client->CampaignCriterionService()->mutate({operations => [$operation]});

  # Display campaign criteria.
  if ($result->get_value()) {
    foreach my $campaign_criterion (@{$result->get_value()}) {
      printf "Campaign criterion with campaign id '%s', criterion id '%s', " .
        "and type '%s' was modified with bid %.2f.\n",
        $campaign_criterion->get_campaignId(),
        $campaign_criterion->get_criterion()->get_id(),
        $campaign_criterion->get_criterion()->get_type(),
        $campaign_criterion->get_bidModifier();
    }
  } else {
    print "No campaign criteria were modified.\n";
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
my $client = Google::Ads::AdWords::Client->new({version => "v201802"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
set_bid_modifier($client, $campaign_id);
