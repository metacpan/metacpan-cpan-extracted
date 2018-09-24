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
# This code example adds a campaign group and sets a performance target for
# that group. To get campaigns, run get_campaigns.pl. To download reports, run
# download_criteria_report_with_awql.pl.

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201809::Campaign;
use Google::Ads::AdWords::v201809::CampaignGroup;
use Google::Ads::AdWords::v201809::CampaignGroupOperation;
use Google::Ads::AdWords::v201809::CampaignGroupPerformanceTarget;
use Google::Ads::AdWords::v201809::CampaignGroupPerformanceTargetOperation;
use Google::Ads::AdWords::v201809::CampaignOperation;
use Google::Ads::AdWords::v201809::Money;
use Google::Ads::AdWords::v201809::PerformanceTarget;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $campaign_ids = ["INSERT_CAMPAIGN_ID_1_HERE", "INSERT_CAMPAIGN_ID_2_HERE"];

# Example main subroutine.
sub add_campaign_groups_and_performance_targets {
  my $client       = shift;
  my $campaign_ids = shift;

  my $campaign_group = _create_campaign_group($client);
  _add_campaigns_to_group($client, $campaign_group->get_id(), $campaign_ids);
  _create_performance_target($client, $campaign_group->get_id());
  printf(
    "Campaign group and its performance target were setup successfully.\n");
  return 1;
}

# Create a campaign group.
sub _create_campaign_group {
  my ($client) = @_;

  # Create the campaign group.
  my $campaign_group = Google::Ads::AdWords::v201809::CampaignGroup->new({
    name => sprintf("Mars campaign group - #%s", uniqid()),
  });
  # Create the operation.
  my $operation = Google::Ads::AdWords::v201809::CampaignGroupOperation->new({
    operator => "ADD",
    operand  => $campaign_group
  });

  my $result =
    $client->CampaignGroupService()->mutate({operations => [$operation]});

  $campaign_group = $result->get_value()->[0];

  printf(
    "Campaign group with ID %d and name '%s' was created.\n",
    $campaign_group->get_id(),
    $campaign_group->get_name());
  return $campaign_group;
}

# Add multiple campaigns to the campaign group.
sub _add_campaigns_to_group {
  my ($client, $campaign_group_id, $campaign_ids) = @_;

  my @operations = ();
  foreach my $campaign_id (@{$campaign_ids}) {
    my $campaign = Google::Ads::AdWords::v201809::Campaign->new({
      id              => $campaign_id,
      campaignGroupId => $campaign_group_id
    });

    # Create operation.
    my $campaign_operation =
      Google::Ads::AdWords::v201809::CampaignOperation->new({
        operator => "SET",
        operand  => $campaign
      });
    push @operations, $campaign_operation;
  }

  # Add campaigns.
  my $result = $client->CampaignService()->mutate({operations => \@operations});

  # Display campaigns.
  foreach my $campaign (@{$result->get_value()}) {
    printf "Campaign with ID %d was added to campaign group with ID %d.\n",
      $campaign->get_id(), $campaign->get_campaignGroupId();
  }
}

# Creates a performance target for the campaign group.
sub _create_performance_target {
  my ($client, $campaign_group_id) = @_;

  # Start the performance target today, and run it for the next 90 days.
  my (undef, undef, undef, $mday, $mon, $year) = localtime(time);
  my $start_date = sprintf("%d%02d%02d", ($year + 1900), ($mon + 1), $mday);
  (undef, undef, undef, $mday, $mon, $year) =
    localtime(time + 60 * 60 * 24 * 90);
  my $end_date = sprintf("%d%02d%02d", ($year + 1900), ($mon + 1), $mday);

  my $performance_target =
    Google::Ads::AdWords::v201809::PerformanceTarget->new({
      # Keep the CPC for the campaigns < $3.
      efficiencyTargetType  => "CPC_LESS_THAN_OR_EQUAL_TO",
      efficiencyTargetValue => 3000000,
      # Keep the maximum spend under $50.
      spendTargetType => "MAXIMUM",
      spendTarget =>
        Google::Ads::AdWords::v201809::Money->new({microAmount => 500000000}),
      # Aim for at least 3000 clicks.
      volumeTargetValue => 3000,
      volumeGoalType    => "MAXIMIZE_CLICKS",
      startDate         => $start_date,
      endDate           => $end_date
    });

  # Create the performance target.
  my $campaign_group_performance_target =
    Google::Ads::AdWords::v201809::CampaignGroupPerformanceTarget->new({
      campaignGroupId   => $campaign_group_id,
      performanceTarget => $performance_target
    });
  # Create the operation.
  my $operation =
    Google::Ads::AdWords::v201809::CampaignGroupPerformanceTargetOperation->new(
    {
      operator => "ADD",
      operand  => $campaign_group_performance_target
    });

  my $result =
    $client->CampaignGroupPerformanceTargetService()
    ->mutate({operations => [$operation]});

  $campaign_group_performance_target = $result->get_value()->[0];

  printf(
    "Campaign performance target with ID %d was added for campaign group ID " .
    "%d.\n",
    $campaign_group_performance_target->get_id(),
    $campaign_group_performance_target->get_campaignGroupId());
}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
  return 1;
}

# Log SOAP XML request, response and API errors.
Google::Ads::AdWords::Logging::enable_all_logging();

# Get AdWords Client, credentials will be read from ~/adwords.properties.
my $client = Google::Ads::AdWords::Client->new({version => "v201809"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_campaign_groups_and_performance_targets($client, $campaign_ids);
