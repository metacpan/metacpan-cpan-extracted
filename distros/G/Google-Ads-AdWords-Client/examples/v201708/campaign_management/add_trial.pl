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
# This example illustrates how to create a trial and wait for it to complete.
#
# See the Campaign Drafts and Experiments guide for more information:
# https://developers.google.com/adwords/api/docs/guides/campaign-drafts-experiments

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201708::Predicate;
use Google::Ads::AdWords::v201708::Selector;
use Google::Ads::AdWords::v201708::Trial;
use Google::Ads::AdWords::v201708::TrialOperation;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $base_campaign_id = "INSERT_BASE_CAMPAIGN_ID_HERE";
my $draft_id         = "INSERT_DRAFT_ID_HERE";

# Set a timeout to fail if the trial is not created in a specified amount
# of time.
use constant JOB_TIMEOUT_IN_MILLISECONDS => 180000;
# The time to sleep in between polls will start at this time. Then an
# exponential back-off will be instituted.
use constant JOB_BASE_WAITTIME_IN_MILLISECONDS => 10000;

# Example main subroutine.
sub add_trial {
  my ($client, $base_campaign_id, $draft_id) = @_;

  my $trial = Google::Ads::AdWords::v201708::Trial->new({
      draftId             => $draft_id,
      baseCampaignId      => $base_campaign_id,
      name                => sprintf("Test Trial #%s", uniqid()),
      trafficSplitPercent => 50,
  });

  # Create operation.
  my $trial_operation = Google::Ads::AdWords::v201708::TrialOperation->new({
      operator => "ADD",
      operand  => $trial
  });

  # Add trial.
  my $result =
    $client->TrialService()->mutate({operations => [$trial_operation]});

  if ($result) {
    my $trial_id = $result->get_value()->[0]->get_id()->get_value();

    my $predicate = Google::Ads::AdWords::v201708::Predicate->new({
        field    => "Id",
        operator => "IN",
        values   => [$trial_id]});
    my $paging = Google::Ads::AdWords::v201708::Paging->new({
        startIndex    => 0,
        numberResults => 1
    });
    my $selector = Google::Ads::AdWords::v201708::Selector->new({
        fields => ["Id", "Status", "BaseCampaignId", "TrialCampaignId"],
        predicates => [$predicate],
        paging     => $paging
    });

    # Since creating a trial is asynchronous, we have to poll it to wait for
    # it to finish.
    my $poll_attempts = 0;
    my $is_pending    = 1;
    my $end_time      = time + JOB_TIMEOUT_IN_MILLISECONDS;
    do {
      # Check to see if the trial is still in the process of being created.
      my $result = $client->TrialService()->get({selector => $selector});
      $trial = $result->get_entries()->[0];
      my $waittime_in_milliseconds =
        JOB_BASE_WAITTIME_IN_MILLISECONDS * (2**$poll_attempts);
      if (((time + $waittime_in_milliseconds) < $end_time)
        and $trial->get_status() eq 'CREATING')
      {
        printf("Sleeping %d milliseconds...\n", $waittime_in_milliseconds);
        sleep($waittime_in_milliseconds / 1000);    # Convert to seconds.
        $poll_attempts++;
      }
    } while (time < $end_time
      and $trial->get_status() eq 'CREATING');

    if ($trial->get_status() eq 'ACTIVE') {
      # The trial creation was successful.
      printf("Trial created with ID %d and trial campaign ID %d.\n",
        $trial->get_id(), $trial->get_trialCampaignId());
    } elsif ($trial->get_status() eq 'CREATION_FAILED') {
      # The trial creation failed, and errors can be fetched from the
      # TrialAsyncErrorService.
      my $error_selector = Google::Ads::AdWords::v201708::Selector->new({
          fields     => ["TrialId", "AsyncError"],
          predicates => [
            Google::Ads::AdWords::v201708::Predicate->new({
                field    => "TrialId",
                operator => "IN",
                values   => [$trial_id]})]});

      my $errors =
        $client->TrialAsyncErrorService->get({selector => $error_selector})
        ->get_entries();
      if (!$errors) {
        printf("Could not retrieve errors for trial %d", $trial->get_id());
      } else {
        printf("Could not create trial due to the following errors:");
        my $index = 0;
        for my $error ($errors) {
          printf("Error %d: %s", $index, $error->get_asyncError()
          ->get_errorString());
          $index++;
        }
      }
    } else {
      # Most likely, the trial is still being created. You can continue polling,
      # but we have limited the number of attempts in the example.
      printf("Timed out waiting to create trial from draft %d with base " .
          "campaign %d.\n",
        $draft_id, $base_campaign_id);
    }
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
my $client = Google::Ads::AdWords::Client->new({version => "v201708"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_trial($client, $base_campaign_id, $draft_id);
