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
# This example illustrates how to perform multiple requests using the
# BatchJobService using incremental uploads.

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201607::AdGroupCriterion;
use Google::Ads::AdWords::v201607::AdGroupCriterionOperation;
use Google::Ads::AdWords::v201607::BatchJob;
use Google::Ads::AdWords::v201607::BatchJobOperation;
use Google::Ads::AdWords::v201607::BiddableAdGroupCriterion;
use Google::Ads::AdWords::v201607::Keyword;
use Google::Ads::AdWords::Utilities::BatchJobHandler;
use Google::Ads::AdWords::Utilities::BatchJobHandlerError;
use Google::Ads::AdWords::Utilities::BatchJobHandlerStatus;

use Cwd qw(abs_path);

use constant KEYWORD_COUNT => 100;
# Set a timeout to fail if the job does not complete in a specified amount
# of time.
use constant JOB_TIMEOUT_IN_MILLISECONDS => 600000;
# The time to sleep in between polls will start at this time. Then an
# exponential back-off will be instituted.
use constant JOB_BASE_WAITTIME_IN_MILLISECONDS => 30000;

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";

# Example main subroutine.
sub add_keywords_using_incremental_batch_job {
  my $client      = shift;
  my $ad_group_id = shift;

  # Create a batch job, which returns an upload URL to upload the batch
  # operations and a job ID to track the job.
  my $operation = Google::Ads::AdWords::v201607::BatchJobOperation->new({
      operator => 'ADD',
      operand  => Google::Ads::AdWords::v201607::BatchJob->new({})});

  my $batch_job_result =
    $client->BatchJobService()->mutate({operations => [$operation]});

  if (!$batch_job_result->get_value()) {
    print "A batch job could not be created. No operations were uploaded.\n";
    return 1;
  }

  my $batch_job = $batch_job_result->get_value()->[0];

  printf("Batch job with ID %d was created.\n\tInitial upload URL: '%s'\n",
    $batch_job->get_id(), $batch_job->get_uploadUrl()->get_url());

  # Get an instance of a utility that helps with uploading batch operations.
  my $batch_job_handler =
    Google::Ads::AdWords::Utilities::BatchJobHandler->new({client => $client});

  #
  # Upload the keywords in three batches to the upload URL.
  # The process that adds the keywords to the ad group will not start
  # executing until the last request has been sent.
  #

  # Upload #1: This is the first upload.
  my @operations = _create_keyword_operations($ad_group_id);

  # Create an initial batch job status.
  # Convert the list of operations into XML.
  # POST the XML to the upload URL.
  my $batch_job_status =
    Google::Ads::AdWords::Utilities::BatchJobHandlerStatus->new({
      total_content_length => 0,
      resumable_upload_uri => $batch_job->get_uploadUrl()->get_url()});
  $batch_job_status =
    $batch_job_handler->upload_incremental_operations(\@operations,
    $batch_job_status);
  if (!_check_status($batch_job_status)) {
    return 1;
  }

  printf("\tResumable upload URL: '%s'\n",
    $batch_job_status->get_resumable_upload_uri());

  # Upload #2: Make sure to pass in the status returned in the last call
  # into 'upload_incremental_operations'.
  @operations = _create_keyword_operations($ad_group_id);

  # Convert the list of operations into XML.
  # POST the XML to the upload URL.
  $batch_job_status =
    $batch_job_handler->upload_incremental_operations(\@operations,
    $batch_job_status);
  if (!_check_status($batch_job_status)) {
    return 1;
  }

  # Upload #3: Make sure to pass in the status returned in the last request
  # and a true value for $is_last_request indicating that the uploads have
  # finished into 'upload_incremental_operations'.
  @operations = _create_keyword_operations($ad_group_id);

  # Convert the list of operations into XML.
  # POST the XML to the upload URL.
  $batch_job_status =
    $batch_job_handler->upload_incremental_operations(\@operations,
    $batch_job_status, 1);
  if (!_check_status($batch_job_status)) {
    return 1;
  }

  # Verify that the operations completed.
  # This will poll until the job has completed or the timeout has expired.
  my $verify_result =
    _verify_operations($client, $batch_job_handler, $batch_job);

  # Display the results.
  my $error             = $verify_result->{error};
  my $job_result        = $verify_result->{batch_job};
  my $operations_result = $verify_result->{result};

  printf("Job with ID %d has completed with a status of '%s'.\n",
    $job_result->get_id(), $job_result->get_status());
  if (defined $error) {
    printf("%s Error. %s\n", $error->get_type(), $error->get_description());
    if ($error->get_type() eq "PROCESSING") {
      printf("%s\n", $error->get_processing_errors());
    }
    if ($error->get_type() eq "HTTP") {
      printf(
        "Type: %s\nCode: %s\nMessage: %s\nTrigger: %s\nField Path: %s\n",
        $error->get_http_type(),             $error->get_http_response_code(),
        $error->get_http_response_message(), $error->get_http_trigger(),
        $error->get_http_field_path());
    }
  }
  if ($operations_result and $operations_result->get_rval()) {
    for my $item (@{$operations_result->get_rval()}) {
      if ($item->get_errorList()) {
        printf("Error on index %d: %s\n",
          $item->get_index(), $item->get_errorList()->get_errors());
      } else {
        # Print the XML output.
        printf("Successful on index %d\n%s\n",
          $item->get_index(),
          $item->get_result()->get_AdGroupCriterion()->get_criterion()
            ->get_text());
      }
    }
  }

  return 1;
}

# Create AdGroupCriterion to add keywords.
sub _create_keyword_operations {
  my ($ad_group_id) = @_;

  my @operations = ();

  for (my $i = 1 ; $i < KEYWORD_COUNT ; $i++) {
    # Create keyword.
    my $keyword =
      Google::Ads::AdWords::v201607::Keyword->new({matchType => "BROAD"});
    # Randomly add invalid characters to keyword.
    if (int(rand(10)) == 0) {
      $keyword->set_text(sprintf("keyword %d!!!", $i));
    } else {
      $keyword->set_text(sprintf("keyword %d", $i));
    }

    # Create biddable ad group criterion.
    my $ad_group_criterion =
      Google::Ads::AdWords::v201607::BiddableAdGroupCriterion->new({
        adGroupId => $ad_group_id,
        criterion => $keyword
      });

    # Create operation.
    my $ad_group_criterion_operation =
      Google::Ads::AdWords::v201607::AdGroupCriterionOperation->new({
        operator => "ADD",
        operand  => $ad_group_criterion
      });

    push(@operations, $ad_group_criterion_operation);
  }
  return @operations;
}

# Check the status of uploading incremental operations. Print details if an
# error is found.
sub _check_status {
  my ($batch_job_status) = @_;
  if (!$batch_job_status) {
    # If not given a status back, then this object is an error.
    my $error = $batch_job_status;
    printf("%s Error. %s\n", $error->get_type(), $error->get_description());
    if ($error->get_type() eq "HTTP") {
      printf(
        "Type: %s\nCode: %s\nMessage: %s\nTrigger: %s\nField Path: %s\n",
        $error->get_http_type(),             $error->get_http_response_code(),
        $error->get_http_response_message(), $error->get_http_trigger(),
        $error->get_http_field_path());
    }
  }
  return $batch_job_status;
}

# Poll for completion of the batch job using an exponential back off
# waiting until the progress of the job is DONE or CANCELED.
# If the job does not finish in the alloted time, attempt to cancel it once.
# This returns a hash of return values:
#   error => undef if no error and BatchJobHandlerError if an error occurred
#   batch_job => the batch job with the id, status, progressStats,
#                processingErrors, and downloadUrl
#   result => BatchJobOpsService::mutateResponse object with contents from the
#             job's download URL
sub _verify_operations {
  my ($client, $batch_job_handler, $batch_job) = @_;

  my $job_id = sprintf("%d", $batch_job->get_id());
  my $predicate = Google::Ads::AdWords::v201607::Predicate->new({
      field    => "Id",
      operator => "IN",
      values   => [$job_id]});
  my $paging = Google::Ads::AdWords::v201607::Paging->new({
      startIndex    => 0,
      numberResults => 1
  });
  my $selector = Google::Ads::AdWords::v201607::Selector->new({
      fields =>
        ["Id", "Status", "ProgressStats", "ProcessingErrors", "DownloadUrl"],
      predicates => [$predicate],
      paging     => $paging
  });

  # Loop while waiting for the job to complete.
  my $job;
  my $poll_attempts        = 0;
  my $end_time             = time + JOB_TIMEOUT_IN_MILLISECONDS;
  my $was_cancel_requested = 0;
  do {
    my $batch_job_page = $client->BatchJobService->get({selector => $selector});
    $job = $batch_job_page->get_entries()->[0];

    printf("Job with ID %d has a status of: %s.\n",
      $job->get_id(), $job->get_status());

    my $waittime_in_milliseconds =
      JOB_BASE_WAITTIME_IN_MILLISECONDS * (2**$poll_attempts);
    if (
      (time + $waittime_in_milliseconds) < $end_time
      and ($job->get_status() eq "ACTIVE"
        or $job->get_status() eq "AWAITING_FILE"
        or $job->get_status() eq "CANCELING")
      )
    {
      printf("Sleeping %d milliseconds...\n", $waittime_in_milliseconds);
      sleep($waittime_in_milliseconds / 1000);    # Convert to seconds.
      $poll_attempts++;
    } else {
      # Optional:
      # If there isn't enough time to sleep and do another loop, then cancel.
      # If a cancel was already unsuccessful, get out of the loop.
      $end_time = time;
      if ( !($job->get_status() eq "DONE" or $job->get_status() eq "CANCELED")
        && !$was_cancel_requested)
      {
        $was_cancel_requested = 1;
        $job->set_status("CANCELING");
        my $operation = Google::Ads::AdWords::v201607::BatchJobOperation->new({
            operator => 'SET',
            operand  => $job
        });
        my $job_result =
          $client->BatchJobService()->mutate({operations => [$operation]});
        if (!$job_result->get_value()) {
          sprint("Unable to cancel job with ID %d.", $job->get_id());
        } else {
          $job = $job_result->get_value()->[0];
          # Reset the timer to give the job time to cancel.
          $poll_attempts = 0;
          $end_time      = time + JOB_TIMEOUT_IN_MILLISECONDS;
          printf("Job with ID %d did not complete within a timeout of %d " .
              "milliseconds. Requested cancellation of batch job.\n",
            $job->get_id(), JOB_TIMEOUT_IN_MILLISECONDS);
        }
      }
    }
    } while (
    time < $end_time
    and !(
         $job->get_status() eq "DONE"
      or $job->get_status() eq "CANCELED"
    ));

  # If the timeout was exceeded, then return an error.
  my $error;
  if (!($job->get_status() eq "DONE" or $job->get_status() eq "CANCELED")) {
    $error = Google::Ads::AdWords::Utilities::BatchJobHandlerError->new({
        type        => "UPLOAD",
        description => sprintf(
          "Job with ID %d did not complete" .
            "within a timeout of %d milliseconds.",
          $job->get_id(), JOB_TIMEOUT_IN_MILLISECONDS
        )});
  }

  # Check for processing errors.
  if ($job->get_processingErrors()) {
    $error = Google::Ads::AdWords::Utilities::BatchJobHandlerError->new({
        type => "PROCESSING",
        description =>
          sprintf("Job ID %d had processing errors.", $job->get_id()),
        processing_errors => $job->get_processingErrors()});
  }

  my $download_url_result;
  if ($job->get_downloadUrl()) {
    my $download_url = $job->get_downloadUrl()->get_url();
    printf("Batch job with ID %d.\n\tDownload URL: '%s'\n",
      $job->get_id(), $download_url);
    $download_url_result = $batch_job_handler->download_response($download_url);
    if (!$download_url_result) {
      $error               = $download_url_result;
      $download_url_result = undef;
    }
  }
  return {
    error     => $error,
    batch_job => $job,
    result    => $download_url_result
  };
}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
  return 1;
}

# Log SOAP XML request, response and API errors.
Google::Ads::AdWords::Logging::enable_all_logging();

# Get AdWords Client, credentials will be read from ~/adwords.properties.
my $client = Google::Ads::AdWords::Client->new({version => "v201607"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_keywords_using_incremental_batch_job($client, $ad_group_id);
