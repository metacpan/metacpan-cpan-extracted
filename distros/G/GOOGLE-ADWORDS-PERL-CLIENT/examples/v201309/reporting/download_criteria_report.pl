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
# This code example gets and downloads a criteria report from an XML
# report definition.
# Currently, there is only production support for reports download.
#
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::Reports::Predicate;
use Google::Ads::AdWords::Reports::ReportDefinition;
use Google::Ads::AdWords::Reports::Selector;
use Google::Ads::Common::ReportUtils;

use Cwd qw(abs_path);
use File::Basename;

# Example main subroutine.
sub download_criteria_report {
  my $client = shift;
  my $path = shift;

  # Create criteria status predicate.
  my $predicate = Google::Ads::AdWords::Reports::Predicate->new({
    field => "Status",
    operator => "IN",
    values => ["ACTIVE", "PAUSED"]
  });

  # Create selector.
  my $selector = Google::Ads::AdWords::Reports::Selector->new({
    fields => ["CampaignId", "AdGroupId", "Id", "Impressions", "Clicks", "Cost"],
    predicates => [$predicate]
  });

  # Create report definition.
  my (undef, undef, undef, $mday, $mon, $year) = localtime(time);
  my $today = sprintf("%d%02d%02d", ($year + 1900), ($mon + 1), $mday);

  my $report_definition = Google::Ads::AdWords::Reports::ReportDefinition->new({
    reportName => "Last 7 days CRITERIA_PERFORMANCE_REPORT #" . $today,
    dateRangeType => "LAST_7_DAYS",
    reportType => "CRITERIA_PERFORMANCE_REPORT",
    downloadFormat => "CSV",
    selector => $selector,
    # Enable to get rows with zero impressions.
    includeZeroImpressions => 0
  });

  # Download report.
  my $error = Google::Ads::Common::ReportUtils::download_report(
      $report_definition, $client, $path);

  if (ref $error eq "Google::Ads::Common::ReportDownloadError") {
    printf("An error has occurred of type '%s', triggered by '%s'.\n",
           $error->get_type(), $error->get_trigger());
  } else {
    printf("Report was downloaded to \"%s\".\n", $path);
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
download_criteria_report($client, dirname($0) . "/criteria_report.csv");
