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
# This example promotes an experiment, which permanently applies all the
# experiment changes made to its related ad groups, criteria and ads. To add an
# experiment, run campaign_management/add_experiment.pl.
#
# Tags: ExperimentService.mutate
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201309::Experiment;
use Google::Ads::AdWords::v201309::ExperimentOperation;

use Cwd qw(abs_path);

# Replace with valid values of your account.
my $experiment_id = "INSERT_EXPERIMENT_ID_HERE";

# Example main subroutine.
sub promote_experiment {
  my $client = shift;
  my $experiment_id = shift;

  # Set experiment's status to PROMOTED.
  my $experiment = Google::Ads::AdWords::v201309::Experiment->new({
    id => $experiment_id,
    status => "PROMOTED"
  });

  # Create operation.
  my $experiment_operation =
      Google::Ads::AdWords::v201309::ExperimentOperation->new({
        operator => "SET",
        operand => $experiment
      });

  # Update experiment.
  my $result = $client->ExperimentService()->mutate({
    operations => [$experiment_operation]
  });

  # Display experiment.
  if ($result->get_value()) {
    my $experiment = $result->get_value()->[0];
    printf "Experiment with name \"%s\" and id \"%d\" was promoted.\n",
           $experiment->get_name(), $experiment->get_id();
  } else {
    print "No experiment was promoted.\n";
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
promote_experiment($client, $experiment_id);
