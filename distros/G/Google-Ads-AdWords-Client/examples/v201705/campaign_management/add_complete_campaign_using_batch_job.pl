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
# This example illustrates how to perform multiple requests using the
# BatchJobService.

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201705::AdGroup;
use Google::Ads::AdWords::v201705::AdGroupAd;
use Google::Ads::AdWords::v201705::AdGroupAdOperation;
use Google::Ads::AdWords::v201705::AdGroupCriterionOperation;
use Google::Ads::AdWords::v201705::AdGroupOperation;
use Google::Ads::AdWords::v201705::BatchJob;
use Google::Ads::AdWords::v201705::BatchJobOperation;
use Google::Ads::AdWords::v201705::BiddableAdGroupCriterion;
use Google::Ads::AdWords::v201705::Budget;
use Google::Ads::AdWords::v201705::BudgetOperation;
use Google::Ads::AdWords::v201705::CampaignCriterionOperation;
use Google::Ads::AdWords::v201705::CampaignOperation;
use Google::Ads::AdWords::v201705::CpcBid;
use Google::Ads::AdWords::v201705::ExpandedTextAd;
use Google::Ads::AdWords::v201705::Keyword;
use Google::Ads::AdWords::v201705::Money;
use Google::Ads::AdWords::v201705::NegativeCampaignCriterion;
use Google::Ads::AdWords::v201705::Predicate;
use Google::Ads::AdWords::v201705::Paging;
use Google::Ads::AdWords::v201705::Selector;
use Google::Ads::AdWords::Utilities::BatchJobHandler;
use Google::Ads::AdWords::Utilities::BatchJobHandlerError;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Set a timeout to fail if the job does not complete in a specified amount
# of time.
use constant JOB_TIMEOUT_IN_MILLISECONDS => 180000;
# The time to sleep in between polls will start at this time. Then an
# exponential back-off will be instituted.
use constant JOB_BASE_WAITTIME_IN_MILLISECONDS => 30000;
use constant NUMBER_OF_CAMPAIGNS_TO_ADD        => 2;
use constant NUMBER_OF_ADGROUPS_TO_ADD         => 2;
use constant NUMBER_OF_KEYWORDS_TO_ADD         => 5;
# Temporary IDs are negative. Keep decrementing the number in order to always
# have a unique temporary ID.
my $temporary_id = -1;

# Example main subroutine.
sub add_complete_campaign_using_batch_job {
  my $client = shift;

  # Create a batch job, which returns an upload URL to upload the batch
  # operations and a job ID to track the job.
  my $operation = Google::Ads::AdWords::v201705::BatchJobOperation->new({
      operator => 'ADD',
      operand  => Google::Ads::AdWords::v201705::BatchJob->new({})});

  my $batch_job_result =
    $client->BatchJobService()->mutate({operations => [$operation]});

  if (!$batch_job_result->get_value()) {
    print "A batch job could not be created. No operations were uploaded.\n";
    return 1;
  }

  my $batch_job = $batch_job_result->get_value()->[0];

  printf("Batch job with ID %d was created.\n\tInitial upload URL: '%s'\n",
    $batch_job->get_id(), $batch_job->get_uploadUrl()->get_url());

  my @operations = ();
  # Create and add an operation to create a new budget.
  my $budget_operation = _create_budget_operation();
  push @operations, $budget_operation;

  # Create and add operations to create new campaigns.
  my @campaign_operations = _create_campaign_operations($budget_operation);
  push @operations, @campaign_operations;

  # Create and add operations to create new negative keyword criteria
  # for each campaign.
  my @campaign_criterion_operations =
    _create_campaign_criterion_operations(@campaign_operations);
  push @operations, @campaign_criterion_operations;

  # Create and add operations to create new ad groups.
  my @ad_group_operations = _create_ad_group_operations(@campaign_operations);
  push @operations, @ad_group_operations;

  # Create and add operations to create new ad group criteria (keywords).
  my @ad_group_criterion_operations =
    _create_ad_group_criterion_operations(@ad_group_operations);
  push @operations, @ad_group_criterion_operations;

  # Create and add operations to create new ad group ads (text ads).
  my @ad_group_ad_operations =
    _create_ad_group_ad_operations(@ad_group_operations);
  push @operations, @ad_group_ad_operations;

  # Get an instance of a utility that helps with uploading batch operations.
  my $batch_job_handler =
    Google::Ads::AdWords::Utilities::BatchJobHandler->new({client => $client});

  # Convert the list of operations into XML.
  # POST the XML to the upload URL.
  my $upload_result =
    $batch_job_handler->upload_operations(\@operations,
    $batch_job->get_uploadUrl()->get_url());
  if (!$upload_result) {
    printf("%s Error. %s\n",
      $upload_result->get_type(),
      $upload_result->get_description());
    if ($upload_result->get_type() eq "HTTP") {
      printf(
        "Type: %s\nCode: %s\nMessage: %s\nTrigger: %s\nField Path: %s\n",
        $upload_result->get_http_type(),
        $upload_result->get_http_response_code(),
        $upload_result->get_http_response_message(),
        $upload_result->get_http_trigger(),
        $upload_result->get_http_field_path());
    }
    return 1;
  }

  printf("\tOperations uploaded to upload URL: '%s'\n",
    $upload_result->get_resumable_upload_uri());

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
  if ($operations_result) {
    for my $item (@{$operations_result->get_rval()}) {
      if ($item->get_errorList()) {
        printf("Error on index %d: %s\n",
          $item->get_index(), $item->get_errorList()->get_errors());
      } else {
        # Print the XML output.
        printf("Successful on index %d\n%s\n", $item->get_index(), $item);
      }
    }
  }

  return 1;
}

# Create a BudgetOperation for the Campaign.
sub _create_budget_operation {
  my $budget = Google::Ads::AdWords::v201705::Budget->new({
    # Required attributes.
    budgetId => _next_id(),
    name     => "Interplanetary budget #" . uniqid(),
    amount =>
      Google::Ads::AdWords::v201705::Money->new({microAmount => 5000000}),
    deliveryMethod => "STANDARD"
  });

  my $budget_operation = Google::Ads::AdWords::v201705::BudgetOperation->new({
    operator => "ADD",
    operand  => $budget
  });
  return $budget_operation;
}

# Create a CampaignOperations to add Campaigns.
sub _create_campaign_operations {
  my ($budget_operation) = @_;

  my @campaign_operations = ();

  for (my $i = 1 ; $i < NUMBER_OF_CAMPAIGNS_TO_ADD ; $i++) {
    my $campaign = Google::Ads::AdWords::v201705::Campaign->new({
        id                     => _next_id(),
        name                   => "Batch Campaign #" . uniqid(),
        advertisingChannelType => "SEARCH",
        # Recommendation: Set the campaign to PAUSED when creating it to stop
        # the ads from immediately serving. Set to ENABLED once you've added
        # targeting and the ads are ready to serve.
        status                 => "PAUSED",
        # Bidding strategy (required).
        biddingStrategyConfiguration =>
          Google::Ads::AdWords::v201705::BiddingStrategyConfiguration->new({
            biddingStrategyType => "MANUAL_CPC",
            # You can optionally provide a bidding scheme in place of the type.
          }
          ),
        budget => Google::Ads::AdWords::v201705::Budget->new(
          {budgetId => $budget_operation->get_operand()->get_budgetId()})});
    my $campaign_operation =
      Google::Ads::AdWords::v201705::CampaignOperation->new({
        operator => "ADD",
        operand  => $campaign
      });
    push @campaign_operations, $campaign_operation;
  }
  return @campaign_operations;
}

# Create CampaignCriterionOperations.
sub _create_campaign_criterion_operations() {
  my (@campaign_operations) = @_;

  my @campaign_criterion_operations = ();

  for my $campaign_operation (@campaign_operations) {
    # Create keyword.
    my $keyword = Google::Ads::AdWords::v201705::Keyword->new(
      {matchType => "BROAD", text => "venus"});

    my $negative_criterion =
      Google::Ads::AdWords::v201705::NegativeCampaignCriterion->new({
        campaignId => $campaign_operation->get_operand()->get_id(),
        criterion  => $keyword
      });

    # Create operation.
    my $negative_criterion_operation =
      Google::Ads::AdWords::v201705::CampaignCriterionOperation->new({
        operator => "ADD",
        operand  => $negative_criterion
      });

    push @campaign_criterion_operations, $negative_criterion_operation;
  }
  return @campaign_criterion_operations;
}

# Create AdGroupOperations to add AdGroups.
sub _create_ad_group_operations {
  my (@campaign_operations) = @_;

  my @ad_group_operations = ();
  for my $campaign_operation (@campaign_operations) {
    for (my $i = 1 ; $i < NUMBER_OF_ADGROUPS_TO_ADD ; $i++) {
      my $ad_group = Google::Ads::AdWords::v201705::AdGroup->new({
          id         => _next_id(),
          campaignId => $campaign_operation->get_operand()->get_id(),
          name       => "Batch Ad Group #" . uniqid(),
          biddingStrategyConfiguration =>
            Google::Ads::AdWords::v201705::BiddingStrategyConfiguration->new({
              bids => [
                Google::Ads::AdWords::v201705::CpcBid->new({
                    bid => Google::Ads::AdWords::v201705::Money->new(
                      {microAmount => 10000000})})]})});
      my $ad_group_operation =
        Google::Ads::AdWords::v201705::AdGroupOperation->new({
          operator => "ADD",
          operand  => $ad_group
        });
      push @ad_group_operations, $ad_group_operation;
    }
  }
  return @ad_group_operations;
}

# Create AdGroupCriterionOperations.
sub _create_ad_group_criterion_operations {
  my (@ad_group_operations) = @_;

  my @ad_group_criterion_operations = ();

  for my $ad_group_operation (@ad_group_operations) {
    for (my $i = 1 ; $i < NUMBER_OF_KEYWORDS_TO_ADD ; $i++) {
      # Create keyword.
      my $keyword = Google::Ads::AdWords::v201705::Keyword->new({
          matchType => "BROAD",
          # Make 50% of keywords invalid to demonstrate error handling.
          text => sprintf("mars%d%s", $i, (($i % 2 == 0) ? "!!!" : ""))});

      # Create biddable ad group criterion.
      my $ad_group_criterion =
        Google::Ads::AdWords::v201705::BiddableAdGroupCriterion->new({
          adGroupId => $ad_group_operation->get_operand()->get_id(),
          criterion => $keyword
        });

      # Create operation.
      my $ad_group_criterion_operation =
        Google::Ads::AdWords::v201705::AdGroupCriterionOperation->new({
          operator => "ADD",
          operand  => $ad_group_criterion
        });
      push @ad_group_criterion_operations, $ad_group_criterion_operation;
    }
  }
  return @ad_group_criterion_operations;
}

# Create AdGroupAdOperations.
sub _create_ad_group_ad_operations() {
  my (@ad_group_operations) = @_;

  my @ad_group_ad_operations = ();
  for my $ad_group_operation (@ad_group_operations) {
    my $ad_group_id = $ad_group_operation->get_operand()->get_id();

    my $text_ad = Google::Ads::AdWords::v201705::ExpandedTextAd->new({
        headlinePart1 => "Cruise to Mars",
        headlinePart2 => "Visit the Red Planet in style.",
        description   => "Low-gravity for everyone!",
        finalUrls     => ["http://www.example.com/1"]});

    # Create ad group ad for the text ad.
    my $text_ad_group_ad = Google::Ads::AdWords::v201705::AdGroupAd->new({
      adGroupId => $ad_group_id,
      ad        => $text_ad,
      # Additional properties (non-required).
      status => "PAUSED"
    });

    # Create operation.
    my $text_ad_group_ad_operation =
      Google::Ads::AdWords::v201705::AdGroupAdOperation->new({
        operator => "ADD",
        operand  => $text_ad_group_ad
      });

    push @ad_group_ad_operations, $text_ad_group_ad_operation;
  }
  return @ad_group_ad_operations;
}

# Return the next available temporary ID.
sub _next_id() {
  return $temporary_id--;
}

# Poll for completion of the batch job using an exponential back off
# waiting until the progress of the job is DONE or CANCELED.
# This returns a hash of return values:
#   error => undef if no error and BatchJobHandlerError if an error occurred
#   batch_job => the batch job with the id, status, progressStats,
#                processingErrors, and downloadUrl
#   result => BatchJobOpsService::mutateResponse object with contents from the
#             job's download URL
sub _verify_operations {
  my ($client, $batch_job_handler, $batch_job) = @_;

  my $job_id = sprintf("%d", $batch_job->get_id());
  my $predicate = Google::Ads::AdWords::v201705::Predicate->new({
      field    => "Id",
      operator => "IN",
      values   => [$job_id]});
  my $paging = Google::Ads::AdWords::v201705::Paging->new({
    startIndex    => 0,
    numberResults => 1
  });
  my $selector = Google::Ads::AdWords::v201705::Selector->new({
    fields =>
      ["Id", "Status", "ProgressStats", "ProcessingErrors", "DownloadUrl"],
    predicates => [$predicate],
    paging     => $paging
  });

  # Loop while waiting for the job to complete.
  my $job;
  my $poll_attempts = 0;
  my $end_time      = time + JOB_TIMEOUT_IN_MILLISECONDS;
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
        or $job->get_status() eq "AWAITING_FILE"))
    {
      printf("Sleeping %d milliseconds...\n", $waittime_in_milliseconds);
      sleep($waittime_in_milliseconds / 1000);    # Convert to seconds.
      $poll_attempts++;
    } else {
      # If there isn't enough time to sleep and do another loop, then get out
      # of the loop.
      $end_time = time;
    }
    } while (
    time < $end_time
    and !(
         $job->get_status() eq "DONE"
      or $job->get_status() eq "CANCELED"
    ));

  # If the tiemout was exceeded, then return an error.
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

  my $download_url = $job->get_downloadUrl()->get_url();
  printf("Batch job with ID %d.\n\tDownload URL: '%s'\n",
    $job->get_id(), $download_url);
  my $download_url_result =
    $batch_job_handler->download_response($download_url);
  if (!$download_url_result) {
    $error               = $download_url_result;
    $download_url_result = undef;
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
my $client = Google::Ads::AdWords::Client->new({version => "v201705"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_complete_campaign_using_batch_job($client);
