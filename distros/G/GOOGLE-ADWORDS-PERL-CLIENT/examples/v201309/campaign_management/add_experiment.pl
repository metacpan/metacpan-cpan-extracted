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
# This example creates an experiment using a query percentage of 10, which
# defines what fraction of auctions should go to the control split (90%) vs.
# the experiment split (10%), then adds experimental bid changes for criteria
# and ad groups. To get campaigns, run get_all_campaigns.pl. To get ad groups,
# run basic_operations/get_ad_groups.pl. To get keywords, run
# basic_operations/get_keywords.pl.
#
# Tags: ExperimentService.mutate
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201309::AdGroup;
use Google::Ads::AdWords::v201309::AdGroupAd;
use Google::Ads::AdWords::v201309::AdGroupAdOperation;
use Google::Ads::AdWords::v201309::AdGroupCriterionOperation;
use Google::Ads::AdWords::v201309::AdGroupExperimentData;
use Google::Ads::AdWords::v201309::AdGroupOperation;
use Google::Ads::AdWords::v201309::BidMultiplier;
use Google::Ads::AdWords::v201309::BiddableAdGroupCriterion;
use Google::Ads::AdWords::v201309::BiddableAdGroupCriterionExperimentData;
use Google::Ads::AdWords::v201309::Criterion;
use Google::Ads::AdWords::v201309::Experiment;
use Google::Ads::AdWords::v201309::ExperimentOperation;
use Google::Ads::AdWords::v201309::ManualCPCAdGroupCriterionExperimentBidMultiplier;
use Google::Ads::AdWords::v201309::ManualCPCAdGroupExperimentBidMultipliers;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $campaign_id = "INSERT_CAMPAIGN_ID_HERE";
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";
my $criterion_id = "INSERT_CRITERION_ID_HERE";

# Example main subroutine.
sub add_experiment {
  my $client = shift;
  my $campaign_id = shift;
  my $ad_group_id = shift;
  my $criterion_id = shift;

  # Create experiment.
  my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time + 60 * 60 * 24);
  my $start_time = sprintf("%d%02d%02d %02d%02d%02d", ($year + 1900),
      ($mon + 1), $mday, $hour, $min, $sec);
  ($sec, $min, $hour, $mday, $mon, $year) = localtime(time + 60 * 60 * 24 * 8);
  my $end_time = sprintf("%d%02d%02d %02d%02d%02d", ($year + 1900),
      ($mon + 1), $mday, $hour, $min, $sec);
  my $experiment = Google::Ads::AdWords::v201309::Experiment->new({
    campaignId => $campaign_id,
    name => "Interplanetary Experiment #" . uniqid(),
    queryPercentage => 10,
    # Additional properties (non-required).
    startDateTime => $start_time,
    endDateTime => $end_time
  });

  # Create operation.
  my $experiment_operation =
      Google::Ads::AdWords::v201309::ExperimentOperation->new({
        operator => "ADD",
        operand => $experiment
      });

  # Add experiment.
  my $result = $client->ExperimentService()->mutate({
    operations => [$experiment_operation]
  });

  # Display experiment.
  my $experiment_id = 0;
  if ($result->get_value()) {
    my $experiment = $result->get_value()->[0];
    $experiment_id = $experiment->get_id()->get_value();
    printf "Experiment with name \"%s\" and id \"%d\" was added.\n",
           $experiment->get_name(), $experiment->get_id();
  } else {
    die "No experiment was added.\n";
  }

  # Set ad group for the experiment.
  my $ad_group = Google::Ads::AdWords::v201309::AdGroup->new({
    id => $ad_group_id
  });

  # Create experiment bid multiplier rule that will modify ad group bid for the
  # experiment.
  my $bid_multiplier =
      Google::Ads::AdWords::v201309::ManualCPCAdGroupExperimentBidMultipliers->
          new({
            maxCpcMultiplier => Google::Ads::AdWords::v201309::BidMultiplier->
                new({
                  multiplier => 1.5
                })
          });

  # Set experiment data to the ad group.
  my $experiment_data =
      Google::Ads::AdWords::v201309::AdGroupExperimentData->new({
        experimentId => $experiment_id,
        experimentDeltaStatus => "MODIFIED",
        experimentBidMultipliers => $bid_multiplier
      });
  $ad_group->set_experimentData($experiment_data);

  # Create operation.
  my $operation = Google::Ads::AdWords::v201309::AdGroupOperation->new({
    operand => $ad_group,
    operator => "SET"
  });

  # Update ad group.
  $result = $client->AdGroupService()->mutate({
    operations => [$operation]
  });

  # Display ad group.
  if ($result->get_value()) {
    my $ad_group = $result->get_value();
    printf "Ad group with name \"%s\", id \"%d\", and status \"%s\" was " .
           "updated for the experiment.\n", $ad_group->get_name(),
           $ad_group->get_id(), $ad_group->get_status();
  } else {
    print "No ad group was updated.\n";
  }

  # Set ad group criteria for the experiment.
  my $criterion = Google::Ads::AdWords::v201309::Criterion->new({
    id => $criterion_id,
  });

  my $ad_group_criterion =
      Google::Ads::AdWords::v201309::BiddableAdGroupCriterion->new({
        adGroupId => $ad_group_id,
        criterion => $criterion
      });

  # Create experiment bid multiplier rule that will modify criterion bid for the
  # experiment.
  $bid_multiplier =
      Google::Ads::AdWords::v201309::ManualCPCAdGroupCriterionExperimentBidMultiplier->new({
        maxCpcMultiplier => Google::Ads::AdWords::v201309::BidMultiplier->new({
          multiplier => 1.5
        })
      });

  # Set experiment data to the criterion.
  $experiment_data =
      Google::Ads::AdWords::v201309::BiddableAdGroupCriterionExperimentData->
          new({
            experimentId => $experiment_id,
            experimentDeltaStatus => "MODIFIED",
            experimentBidMultiplier => $bid_multiplier
          });
  $ad_group_criterion->set_experimentData($experiment_data);

  # Create operation.
  $operation =
      Google::Ads::AdWords::v201309::AdGroupCriterionOperation->new({
        operand => $ad_group_criterion,
        operator => "SET"
      });

  # Update ad group criterion.
  $result = $client->AdGroupCriterionService()->mutate({
    operations => [$operation]
  });

  # Display ad group criterion.
  if ($result->get_value()) {
    my $ad_group_criterion = $result->get_value()->[0];
    printf "Ad group criterion with ad group id \"%d\", criterion id \"%d\", " .
           "type \"%s\" was updated for the experiment.\n",
           $ad_group_criterion->get_adGroupId(),
           $ad_group_criterion->get_criterion()->get_id(),
           $ad_group_criterion->get_criterion()->get_Criterion__Type()
  } else {
    print "No ad group criteria were updated.\n";
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
my $client = Google::Ads::AdWords::Client->new({version => "v201309"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_experiment($client, $campaign_id, $ad_group_id, $criterion_id);
