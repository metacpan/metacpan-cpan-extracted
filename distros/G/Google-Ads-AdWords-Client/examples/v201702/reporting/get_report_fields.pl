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
# This example gets report fields of a CRITERIA_PERFORMANCE_REPORT.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;

use Cwd qw(abs_path);

# Example main subroutine.
sub get_report_fields {
  my $client = shift;

  # The type of the report to get fields for.
  my $report_type = "CRITERIA_PERFORMANCE_REPORT";

  # Get report fields.
  my $report_definition_fields =
    $client->ReportDefinitionService()
    ->getReportFields({reportType => $report_type});

  # Display report fields.
  printf "The report type \"%s\" contains the following fields:\n",
    $report_type;

  foreach my $report_definition_field (@{$report_definition_fields}) {
    printf("- %s (%s)",
      $report_definition_field->get_fieldName(),
      $report_definition_field->get_fieldType());
    if ($report_definition_field->get_enumValues()) {
      printf " := [%s]",
        join(", ", @{$report_definition_field->get_enumValues()});
    }
    print "\n";
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
my $client = Google::Ads::AdWords::Client->new({version => "v201702"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
get_report_fields($client);
