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
# This example illustrates how to perform asynchronous requests using the
# MutateJobService.
#
# Tags: MutateJobService.mutate, MutateJobService.get,
#       MutateJobService.getResult
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201309::AdGroupAd;
use Google::Ads::AdWords::v201309::AdGroupAdOperation;
use Google::Ads::AdWords::v201309::AdGroupCriterion;
use Google::Ads::AdWords::v201309::AdGroupCriterionOperation;
use Google::Ads::AdWords::v201309::BiddableAdGroupCriterion;
use Google::Ads::AdWords::v201309::BulkMutateJobPolicy;
use Google::Ads::AdWords::v201309::BulkMutateJobSelector;
use Google::Ads::AdWords::v201309::Keyword;
use Google::Ads::AdWords::v201309::TextAd;
use Google::Ads::Common::ErrorUtils;

use Cwd qw(abs_path);

# Constants
use constant WAIT_TIME => 30; # In seconds
use constant MAX_RETRIES => 10;
use constant KEYWORD_COUNT => 100;

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";

# Example main subroutine.
sub add_keywords_in_bulk {
  my $client = shift;
  my $ad_group_id = shift;

  # Create operations.
  my @operations = ();
  for (my $i = 1 ; $i < KEYWORD_COUNT; $i++) {
    # Create keyword.
    my $keyword = Google::Ads::AdWords::v201309::Keyword->new({
      matchType => "BROAD"
    });
    # Randomly add invalid characters to keyword.
    if (int(rand(10)) == 0) {
      $keyword->set_text(sprintf("keyword %d!!!", $i));
    } else {
      $keyword->set_text(sprintf("keyword %d", $i));
    }

    # Create biddable ad group criterion.
    my $ad_group_criterion =
        Google::Ads::AdWords::v201309::BiddableAdGroupCriterion->new({
          adGroupId => $ad_group_id,
          criterion => $keyword
        });

    # Create operation.
    my $ad_group_criterion_operation =
        Google::Ads::AdWords::v201309::AdGroupCriterionOperation->new({
          operator => "ADD",
          operand => $ad_group_criterion
        });

    push(@operations, $ad_group_criterion_operation);
  }

  # Call mutate to create a new job.
  my $job = $client->MutateJobService()->mutate({
        operations => \@operations,
        policy => Google::Ads::AdWords::v201309::BulkMutateJobPolicy->new({
          # You can specify up to 3 job IDs that must successfully complete
          # before this job can be processed.
          prerequisiteJobIds => []
        })
      });
  my $job_id = $job->get_id();
  printf("Job with ID '%d' was created.\n", $job_id);

  # Monitor and retrieve results from job.
  my $job_selector = Google::Ads::AdWords::v201309::BulkMutateJobSelector->new({
    jobIds => [$job_id],
    includeStats => 1,
    includeHistory => 1
  });

  # Loop while waiting for the job to complete.
  my $retries = 0;
  do {
    sleep WAIT_TIME;

    my $jobs = $client->MutateJobService->get({
      selector => $job_selector
    });
    $job = @{$jobs}[0];

    if ($job->get_status() eq "PENDING") {
      printf "The job has been pending since %s.\n",
             $job->get_history()->[0]->get_dateTime();
    } elsif ($job->get_status() eq "PROCESSING") {
      printf "The job is processing and approximately %d%% complete.\n",
             $job->get_stats()->get_progressPercent();
    } elsif ($job->get_status() eq "COMPLETED") {
      printf "The job is complete and took approximately %d seconds" .
             " to process.\n",
             ($job->get_stats()->get_processingTimeMillis() / 100);
    } elsif ($job->get_status() eq "FAILED") {
      die("The job failed with reason " .  $job->get_failureReason() . ".\n");
    }
    $retries++;
  } while ($retries < MAX_RETRIES and ($job->get_status() eq "PENDING" or
           $job->get_status() eq "PROCESSING"));

  if ($retries >= MAX_RETRIES) {
    die("Job didn't finish after " . MAX_RETRIES . " retries.");
  }

  # Retrieve results of the job.
  my $job_result = $client->MutateJobService->getResult({
    selector => $job_selector
  })->get_SimpleMutateResult();

  # Sort keywords into groups based on the results.
  my @succeeded = ();
  my @lost = ();
  my @skipped = ();
  my @failed = ();
  my %errors = ();
  my @generic_errors = ();

  # Examine the errors.
  my $job_errors = $job_result->get_errors();
  if ($job_errors) {
    foreach my $error (@{$job_errors}) {
      my $index =
          Google::Ads::Common::ErrorUtils->get_source_operation_index($error);
      if ($index) {
        my $keyword =
            $operations[$index]->get_operand()->get_criterion()->get_text();
        if ($error->get_reason() eq "LOST_RESULT") {
          push @lost, $keyword;
        } elsif ($error->get_reason() eq "UNPROCESSED_RESULT" ||
                 $error->get_reason() eq "BATCH_FAILURE") {
          push @skipped, $keyword;
        } else {
          push @failed, $keyword;
          push @{$errors{$keyword}}, $error if $errors{$keyword};
          $errors{$keyword} = [$error] if !$errors{$keyword};
        }
      } else {
        push @generic_errors, $error;
      }
    }
  }

  # Examine the results to determine which keywords were added successfully.
  my $results = $job_result->get_results();
  if ($results) {
    foreach my $result (@{$results}) {
      my $keyword_criterion = $result->get_AdGroupCriterion();
      if ($keyword_criterion) {
        push @succeeded, $keyword_criterion->get_criterion()->get_text();
      }
    }
  }

  # Display results of the job.
  printf "%d keywords were added successfully: %s\n", scalar(@succeeded),
         join(", ", @succeeded);

  printf "%d keywords were skipped and should be retried: %s\n",
         scalar(@skipped), join(", ", @skipped);

  printf "%d keywords were not added due to errors:\n", scalar(@failed);
  foreach my $keyword (@failed) {
    my @errors_string = ();
    foreach my $error (@{$errors{$keyword}}) {
      push @errors_string, $error->get_errorString();
    }
    printf "- %s: %s\n", $keyword, join(", ", @errors_string);
  }

  printf "%d generic errors were encountered:\n", scalar(@generic_errors);
  foreach my $error (@generic_errors) {
    printf "- %s\n", $error->get_errorString();
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
add_keywords_in_bulk($client, $ad_group_id);
