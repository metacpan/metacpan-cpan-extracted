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
# This example illustrates how to create a draft and access its associated
# draft campaign.
#
# See the Campaign Drafts and Experiments guide for more information:
# https://developers.google.com/adwords/api/docs/guides/campaign-drafts-experiments

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201806::CampaignCriterion;
use Google::Ads::AdWords::v201806::CampaignCriterionOperation;
use Google::Ads::AdWords::v201806::Draft;
use Google::Ads::AdWords::v201806::DraftOperation;
use Google::Ads::AdWords::v201806::Language;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with a valid value from your account.
my $base_campaign_id = "INSERT_BASE_CAMPAIGN_ID_HERE";

# Example main subroutine.
sub add_draft {
  my ($client, $base_campaign_id) = @_;

  my $draft = Google::Ads::AdWords::v201806::Draft->new({
      baseCampaignId => $base_campaign_id,
      draftName      => sprintf("Test Draft #%s", uniqid())});

  # Create operation.
  my $draft_operation = Google::Ads::AdWords::v201806::DraftOperation->new({
      operator => "ADD",
      operand  => $draft
  });

  # Add draft.
  my $result =
    $client->DraftService()->mutate({operations => [$draft_operation]});

  if ($result) {
    $draft = $result->get_value()->[0];
    my $draft_id          = $draft->get_draftId();
    my $draft_campaign_id = $draft->get_draftCampaignId();

    printf(
      "Draft with ID %d and base campaign ID %d" .
        " and draft campaign ID %d created.\n",
      $draft_id, $draft->get_baseCampaignId(),
      $draft_campaign_id
    );

    # Once the draft is created, you can modify the draft campaign as if it
    # were a real campaign. For example, you may add criteria, adjust bids,
    # or even include additional ads. Adding a criterion is shown here.
    my $criterion = Google::Ads::AdWords::v201806::Language->new({
        id => 1003    # Spanish
    });

    my $operation =
      Google::Ads::AdWords::v201806::CampaignCriterionOperation->new({
        operator => "ADD",
        operand  => Google::Ads::AdWords::v201806::CampaignCriterion->new({
            campaignId => $draft_campaign_id,
            criterion  => $criterion
          })});

    $result =
      $client->CampaignCriterionService()->mutate({operations => [$operation]});

    $criterion = $result->get_value()->[0];

    printf("Draft updated to include criteria in campaign %d.\n",
      $criterion->get_campaignId());
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
my $client = Google::Ads::AdWords::Client->new({version => "v201806"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_draft($client, $base_campaign_id);
