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
# This example streams the result of an ad hoc report, collecting total
# impressions by campaign for each line. This demonstrates how you can extract
# data from a large report without holding the entire result set in memory
# or using files.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::Utilities::ReportQueryBuilder;
use Google::Ads::Common::ReportUtils;

use Cwd qw(abs_path);

# Example main subroutine.
sub stream_criteria_report_results {
  my $client = shift;

  my $report_query =
      Google::Ads::AdWords::Utilities::ReportQueryBuilder->new(
          {client => $client})
          ->select([
          "Id", "AdNetworkType1", "Impressions",
      ])->from("CRITERIA_PERFORMANCE_REPORT")
          ->where("Status")
          ->in(["ENABLED", "PAUSED"])
          ->during("LAST_7_DAYS")
          ->build();

  # Optional: Set the reporting configuration of the session to suppress
  # header, column name, or summary rows in the report output. You can also
  # configure this via your adwords.properties configuration file.
  # In addition, you can set whether you want to explicitly include or
  # exclude zero impression rows and you can set whether to return enum values
  # or display values for enum fields.
  $client->get_reporting_config()->set_skip_header(1);
  $client->get_reporting_config()->set_skip_column_header(1);
  $client->get_reporting_config()->set_skip_summary(1);
  $client->get_reporting_config()->set_include_zero_impressions(0);
  $client->get_reporting_config()->set_use_raw_enum_values(0);

  # Get the report handler.
  my $report_handler = Google::Ads::Common::ReportUtils::get_report_handler({
      query  => $report_query,
      format => "CSV"
    },
    $client
  );

  # Pass in the anonymous subroutine that will be called as data is available
  # for processing.
  my %impressions_by_ad_network_type1 = ();
  my $incomplete_line                 = '';
  my $result                          = $report_handler->process_contents(
    sub {
      my ($data, $response) = @_;
      # If the line is starting in the middle, then prepend the incomplete line
      # from last time.
      $data            = $incomplete_line . $data;
      $incomplete_line = '';
      # Match the line that is ID,AdNetworkType1,Impressions
      # Example: 123456,Search Network,5
      while ($data =~ /(\d+),([^,]+),(\d+)\n/g) {
        my ($ad_network_type1, $impressions) = ($2, $3);
        my $impressions_total =
          $impressions_by_ad_network_type1{$ad_network_type1};
        $impressions_total =
          (defined($impressions_total)) ? $impressions_total : 0;
        $impressions_by_ad_network_type1{$ad_network_type1} =
          $impressions_total + $impressions;
      }
      # If everything wasn't processed, then save off the incomplete line to
      # be prepended the next time this subroutine is called.
      if ($data =~ /\n(.*)$/) {
        $incomplete_line = $1;
      }
    });

  if (!$result) {
    printf("An error has occurred of type '%s', triggered by '%s'.\n",
      $result->get_type(), $result->get_trigger());
    return 1;
  }

  # Print the impression totals by ad network type 1.
  print("Total impressions by ad network type 1:\n");
  while (my ($key, $val) = each %impressions_by_ad_network_type1) {
    printf "$key\t$val\n";
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
my $client = Google::Ads::AdWords::Client->new({version => "v201809"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example.
stream_criteria_report_results($client);
