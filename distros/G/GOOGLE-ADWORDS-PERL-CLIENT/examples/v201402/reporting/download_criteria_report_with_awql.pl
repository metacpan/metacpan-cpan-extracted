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
# This code example gets and downloads a criteria report using an AWQL query.
# Currently, there is only production support for reports download.
#
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::Common::ReportUtils;

use Cwd qw(abs_path);
use File::Basename;

# Example main subroutine.
sub download_criteria_report_with_awql {
  my $client = shift;
  my $path = shift;

  # Create report query.
  my (undef, undef, undef, $mday, $mon, $year) = localtime(time - 60 * 60 * 24);
  my $yesterday = sprintf("%d%02d%02d", ($year + 1900), ($mon + 1), $mday);
  (undef, undef, undef, $mday, $mon, $year) =
      localtime(time - 60 * 60 * 24 * 4);
  my $last_4_days = sprintf("%d%02d%02d", ($year + 1900), ($mon + 1), $mday);

  my $report_query =
      "SELECT CampaignId, AdGroupId, Id, Criteria, CriteriaType, " .
      "Impressions, Clicks, Cost FROM CRITERIA_PERFORMANCE_REPORT " .
      "WHERE Status IN [ACTIVE, PAUSED] " .
      "DURING $last_4_days, $yesterday";

  # Download report.
  my $error = Google::Ads::Common::ReportUtils::download_report({
    query => $report_query,
    format => "CSV"
  }, $client, $path);

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
my $client = Google::Ads::AdWords::Client->new({version => "v201402"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
download_criteria_report_with_awql($client, dirname($0) .
                                   "/criteria_report.csv");
