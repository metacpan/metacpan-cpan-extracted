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
# This example gets and downloads an Ad Hoc report from an XML report
# definition for all accounts directly under a manager account.
# This example should be run against an AdWords manager account.
# NOTE: Even though this example is called parallel_report_download, this shows
# how to download the reports serially.

use strict;
use warnings;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::Reports::ReportDefinition;
use Google::Ads::AdWords::Reports::Selector;
use Google::Ads::Common::ReportUtils;
use Google::Ads::AdWords::v201802::Paging;
use Google::Ads::AdWords::v201802::Selector;

use Cwd qw(abs_path);
use File::Spec;
use File::Temp qw/ tempdir /;

use constant PAGE_SIZE => 500;
# Set a timeout to fail if the report is not downloaded in a specified amount
# of time.
use constant JOB_TIMEOUT_IN_MILLISECONDS => 180000;
# The time to sleep in between retries will start at this time. Then an
# exponential back-off will be instituted.
use constant JOB_BASE_WAITTIME_IN_MILLISECONDS => 10000;

# Example main subroutine.
sub parallel_report_download {
  my $client           = shift;
  my $report_directory = tempdir();

  # Retrieve all accounts under the manager account.
  my @customers = __get_all_managed_customers($client);

  # Create selector.
  my $selector = Google::Ads::AdWords::Reports::Selector->new(
    {fields => ["CampaignId", "AdGroupId", "Impressions", "Clicks", "Cost"]});

  # Create report definition.
  my $report_definition = Google::Ads::AdWords::Reports::ReportDefinition->new({
      reportName     => "Custom ADGROUP_PERFORMANCE_REPORT",
      dateRangeType  => "LAST_7_DAYS",
      reportType     => "ADGROUP_PERFORMANCE_REPORT",
      downloadFormat => "CSV",
      selector       => $selector
  });

  # Optional: Modify the reporting configuration of the client to suppress
  # header, column, or summary rows in the report output and include data with
  # zero impressions. You can choose to return enum field values as enum
  # values instead of display values.
  # You can also configure this via your adwords.properties configuration file.
  $client->get_reporting_config()->set_skip_header(0);
  $client->get_reporting_config()->set_skip_column_header(0);
  $client->get_reporting_config()->set_skip_summary(0);
  $client->get_reporting_config()->set_include_zero_impressions(0);
  $client->get_reporting_config()->set_use_raw_enum_values(0);

  printf("Downloading report for %d managed customers.\n", scalar @customers);

  my $successful_reports = {};
  my $failed_reports     = {};
  foreach my $customer_id (@customers) {
    my $output_file =
      File::Spec->catfile($report_directory,
      sprintf("adgroup_%010d.csv", $customer_id));
    $client->set_client_id($customer_id);

    # Get the report handler.
    my $report_handler =
      Google::Ads::Common::ReportUtils::get_report_handler($report_definition,
      $client);

    # If there is a failure, then retry the request.
    my $result;
    my $retries  = 0;
    my $end_time = time + JOB_TIMEOUT_IN_MILLISECONDS;
    do {
      # Download the report.
      $result = $report_handler->save($output_file);

      my $waittime_in_milliseconds =
        JOB_BASE_WAITTIME_IN_MILLISECONDS * (2**$retries);
      if (  ((time + $waittime_in_milliseconds) < $end_time)
        and !$result
        and $result->get_response_code() >= 500)
      {
        printf("Report for client customer ID %s was not downloaded" .
            " due to: %s - %s\n",
          $customer_id, $result->get_type(), $result->get_trigger());
        printf("Sleeping %d milliseconds before retrying...\n",
          $waittime_in_milliseconds);
        sleep($waittime_in_milliseconds / 1000);    # Convert to seconds.
        $retries++;
      }
    } while (time < $end_time
      and !$result
      and $result->get_response_code() >= 500);

    if (!$result) {
      printf("Report for client customer ID %s was not downloaded" .
          " due to: %s - %s\n",
        $customer_id, $result->get_type(), $result->get_trigger());
      $failed_reports->{$customer_id} = sprintf("%s: %s - %s",
        $output_file, $result->get_type(), $result->get_trigger());
    } else {
      printf(
        "Report for client customer ID %s successfully downloaded to: %s\n",
        $customer_id, $output_file);
      $successful_reports->{$customer_id} = $output_file;
    }
  }

  printf("All downloads completed. Results:\n");
  printf("Successful reports:\n");
  foreach my $client_customer_id (keys $successful_reports) {
    printf("\tClient ID %s => '%s'\n",
      $client_customer_id, $successful_reports->{$client_customer_id});
  }
  printf("Failed reports:\n");
  foreach my $client_customer_id (keys $failed_reports) {
    printf("\tClient ID %s => '%s'\n",
      $client_customer_id, $failed_reports->{$client_customer_id});
  }
  printf("End of results.");

  return 1;
}

# Retrieve all the customers under a manager account.
sub __get_all_managed_customers {
  my ($client) = @_;

  # Create selector.
  my $paging = Google::Ads::AdWords::v201802::Paging->new({
      startIndex    => 0,
      numberResults => PAGE_SIZE
  });
  my $predicate = Google::Ads::AdWords::v201802::Predicate->new({
      field    => "CanManageClients",
      operator => "EQUALS",
      values   => "false"
  });
  my $selector = Google::Ads::AdWords::v201802::Selector->new({
      fields     => ["CustomerId"],
      paging     => $paging,
      predicates => [$predicate]});

  my $page;
  my @customers = ();
  do {
    $page =
      $client->ManagedCustomerService()->get({serviceSelector => $selector});

    if ($page->get_entries()) {
      foreach my $customer (@{$page->get_entries()}) {
        push @customers, $customer->get_customerId();
      }
    }
    $paging->set_startIndex($paging->get_startIndex() + PAGE_SIZE);
  } while ($paging->get_startIndex() < $page->get_totalNumEntries());

  return @customers;
}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
  return 1;
}

# Log SOAP XML request, response and API errors.
Google::Ads::AdWords::Logging::enable_all_logging();

# Get AdWords Client, credentials will be read from ~/adwords.properties.
my $client = Google::Ads::AdWords::Client->new({version => "v201802"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
parallel_report_download($client);
