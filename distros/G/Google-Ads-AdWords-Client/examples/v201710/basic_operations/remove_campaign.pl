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
# This example removes a campaign by setting the status to 'REMOVED'.
# To get campaigns, run basic_operations/get_campaigns.pl.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201710::Campaign;
use Google::Ads::AdWords::v201710::CampaignOperation;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $campaign_id = "INSERT_CAMPAIGN_ID_HERE";

# Example main subroutine.
sub remove_campaign {
  my $client      = shift;
  my $campaign_id = shift;

  # Create campaign with REMOVED status.
  my $campaign = Google::Ads::AdWords::v201710::Campaign->new({
      id     => $campaign_id,
      status => "REMOVED"
  });

  # Create operations.
  my $operation = Google::Ads::AdWords::v201710::CampaignOperation->new({
      operand  => $campaign,
      operator => "SET"
  });

  # Remove campaign.
  my $result = $client->CampaignService()->mutate({operations => [$operation]});

  # Display campaign.
  if ($result->get_value()) {
    my $campaign = $result->get_value()->[0];
    printf "The campaign with id %d was removed.\n", $campaign->get_id();
  } else {
    print "No campaign was removed.\n";
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
remove_campaign($client, $campaign_id);
