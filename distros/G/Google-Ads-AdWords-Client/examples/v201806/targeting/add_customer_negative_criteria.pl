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
# This example adds various types of negative criteria to a customer. These
# criteria will be applied to all campaigns for the customer.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201806::ContentLabel;
use Google::Ads::AdWords::v201806::CustomerNegativeCriterion;
use Google::Ads::AdWords::v201806::CustomerNegativeCriterionOperation;
use Google::Ads::AdWords::v201806::Placement;

use Cwd qw(abs_path);

# Example main subroutine.
sub add_customer_negative_criteria {
  my ($client) = @_;

  # Get the CustomerNegativeCriterionService.
  my @criteria = ();

  # Exclude tragedy & conflict content.
  my $tragedy_content_label = Google::Ads::AdWords::v201806::ContentLabel->new({
    contentLabelType => 'TRAGEDY'
  });
  push @criteria, $tragedy_content_label;

  # Exclude a specific placement.
  my $placement = Google::Ads::AdWords::v201806::Placement->new({
    url => 'http://www.example.com'
  });
  push @criteria, $placement;

  # Additional criteria types are available for this service. See the types
  # listed under Criterion here:
  # https://developers.google.com/adwords/api/docs/reference/latest/CustomerNegativeCriterionService.Criterion

  # Create operations to add each of the criteria above.
  my @operations = ();
  for my $criterion (@criteria) {
    my $negative_criterion =
      Google::Ads::AdWords::v201806::CustomerNegativeCriterion->new({
        criterion => $criterion
      });
    my $operation =
      Google::Ads::AdWords::v201806::CustomerNegativeCriterionOperation->new({
        operator => 'ADD',
        operand  => $negative_criterion
      });
    push @operations, $operation;
  }

  # Send the request to add the criteria.
  my $result =
    $client->CustomerNegativeCriterionService()
    ->mutate({operations => \@operations});

  # Display the results.
  if ($result->get_value()) {
    foreach my $negative_criterion (@{$result->get_value()}) {
      printf "Campaign negative criterion with criterion ID %d and type " .
        "'%s' was added.\n",
        $negative_criterion->get_criterion()->get_id(),
        $negative_criterion->get_criterion()->get_type();
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
my $client = Google::Ads::AdWords::Client->new({version => "v201806"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_customer_negative_criteria($client);
