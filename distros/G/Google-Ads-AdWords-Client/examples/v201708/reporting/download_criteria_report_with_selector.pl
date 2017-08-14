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
# This code example gets and downloads a criteria report from an XML
# report definition.
# Currently, there is only production support for reports download.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::Reports::Predicate;
use Google::Ads::AdWords::Reports::ReportDefinition;
use Google::Ads::AdWords::Reports::Selector;
use Google::Ads::Common::ReportUtils;

use Cwd qw(abs_path);
use File::HomeDir;
use File::Spec;

# Example main subroutine.
sub download_criteria_report_with_selector {
  my $client      = shift;
  my $output_file = shift;

  # Create criteria status predicate.
  my $predicate = Google::Ads::AdWords::Reports::Predicate->new({
      field    => "Status",
      operator => "IN",
      values   => ["ENABLED", "PAUSED"]});

  # Create selector.
  my $selector = Google::Ads::AdWords::Reports::Selector->new({
      fields => [
        "CampaignId", "AdGroupId", "Id",          "CriteriaType",
        "Criteria",   "FinalUrls", "Impressions", "Clicks",
        "Cost"
      ],
      predicates => [$predicate]});

  # Create report definition.
  my (undef, undef, undef, $mday, $mon, $year) = localtime(time);
  my $today = sprintf("%d%02d%02d", ($year + 1900), ($mon + 1), $mday);

  my $report_definition = Google::Ads::AdWords::Reports::ReportDefinition->new({
      reportName     => "Last 7 days CRITERIA_PERFORMANCE_REPORT #" . $today,
      dateRangeType  => "LAST_7_DAYS",
      reportType     => "CRITERIA_PERFORMANCE_REPORT",
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

  # Get the report handler.
  my $report_handler =
    Google::Ads::Common::ReportUtils::get_report_handler($report_definition,
    $client);

  # Download the report using the appropriate method on ReportDownloadHandler.
  my $result;
  if ($output_file) {
    $result = $report_handler->save($output_file);
  } else {
    $result = $report_handler->get_as_string();
  }

  if (!$result) {
    printf("An error has occurred of type '%s', triggered by '%s'.\n",
      $result->get_type(), $result->get_trigger());
  } elsif ($output_file) {
    printf("Report was downloaded to \"%s\".\n", $output_file);
  } else {
    printf("%s\n", $result);
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

my $output_file =
  File::Spec->catfile(File::HomeDir->my_home, "criteria_report.csv");

# Call the example
download_criteria_report_with_selector($client, $output_file);
