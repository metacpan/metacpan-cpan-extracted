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
# This example adds a label to multiple campaigns.

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201609::Campaign;
use Google::Ads::AdWords::v201609::CampaignLabel;
use Google::Ads::AdWords::v201609::CampaignLabelOperation;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $campaign_ids = ["INSERT_CAMPAIGN_ID_1_HERE", "INSERT_CAMPAIGN_ID_2_HERE"];
my $label_id = "INSERT_LABEL_ID_HERE";

# Example main subroutine.
sub add_campaign_labels {
  my $client       = shift;
  my $campaign_ids = shift;
  my $label_id     = shift;

  my @operations = ();

  # Create label operations.
  foreach my $campaign_id (@{$campaign_ids}) {
    my $campaign_label = Google::Ads::AdWords::v201609::CampaignLabel->new({
        campaignId => $campaign_id,
        labelId    => $label_id
    });
    my $campaign_label_operation =
      Google::Ads::AdWords::v201609::CampaignLabelOperation->new({
        operator => "ADD",
        operand  => $campaign_label
      });
    push @operations, $campaign_label_operation;
  }

  # Add campaign labels.
  my $result =
    $client->CampaignService()->mutateLabel({operations => \@operations});

  # Display campaign labels.
  foreach my $campaign_label (@{$result->get_value()}) {
    printf "Campaign label for campaign ID %d and label ID %d was added.\n",
      $campaign_label->get_campaignId(), $campaign_label->get_labelId();
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
my $client = Google::Ads::AdWords::Client->new({version => "v201609"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_campaign_labels($client, $campaign_ids, $label_id);
