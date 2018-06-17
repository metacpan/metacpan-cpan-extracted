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
# This example illustrates how to graduate a trial.
#
# See the Campaign Drafts and Experiments guide for more information:
# https://developers.google.com/adwords/api/docs/guides/campaign-drafts-experiments

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201806::Budget;
use Google::Ads::AdWords::v201806::BudgetOperation;
use Google::Ads::AdWords::v201806::Trial;
use Google::Ads::AdWords::v201806::TrialOperation;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with a valid value from your account.
my $trial_id = "INSERT_TRIAL_ID_HERE";

# Example main subroutine.
sub graduate_trial {
  my ($client, $trial_id) = @_;

  # To graduate a trial, you must specify a different budget from the base
  # campaign. The base campaign (in order to have had a trial based on it)
  # must have a non-shared budget, so it cannot be shared with the new
  # independent campaign created by graduation.
  my $budget = Google::Ads::AdWords::v201806::Budget->new({
      name => sprintf("Budget #%s", uniqid()),
      amount =>
        Google::Ads::AdWords::v201806::Money->new({microAmount => 5000000}),
      deliveryMethod => "STANDARD"
  });

  my $budget_operation = Google::Ads::AdWords::v201806::BudgetOperation->new({
      operator => "ADD",
      operand  => $budget
  });

  # Add budget.
  my $budget_id =
    $client->BudgetService()->mutate({operations => ($budget_operation)})
    ->get_value()->get_budgetId()->get_value();

  my $trial = Google::Ads::AdWords::v201806::Trial->new({
      id       => $trial_id,
      budgetId => $budget_id,
      status   => "GRADUATED"
  });

  # Create operation.
  my $trial_operation = Google::Ads::AdWords::v201806::TrialOperation->new({
      operator => "SET",
      operand  => $trial
  });

  # Graduate trial.
  my $result =
    $client->TrialService()->mutate({operations => [$trial_operation]});

  # Update the trial.
  $trial = $result->get_value()->[0];

  # Graduation is a synchronous operation, so the campaign is already ready.
  # If you promote instead, make sure to see the polling scheme demonstrated
  # in add_trial.pl to wait for the asynchronous operation to finish.
  printf("Trial ID %d graduated. Campaign %d was given a new budget ID %d " .
      "and is no longer dependent on this trial.\n",
    $trial->get_id(), $trial->get_trialCampaignId(), $budget_id);

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
graduate_trial($client, $trial_id);
