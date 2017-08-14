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
# This example sets ad parameters for a keyword in an ad group. To get keywords,
# run basic_operations/get_keywords.pl.

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201708::AdParam;
use Google::Ads::AdWords::v201708::AdParamOperation;

use Cwd qw(abs_path);

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";
my $keyword_id  = "INSERT_KEYWORD_ID_HERE";

# Example main subroutine.
sub set_ad_parameters {
  my $client      = shift;
  my $ad_group_id = shift;
  my $keyword_id  = shift;

  # Create ad parameters.
  my $ad_param1 = Google::Ads::AdWords::v201708::AdParam->new({
      adGroupId     => $ad_group_id,
      criterionId   => $keyword_id,
      insertionText => "100",
      paramIndex    => "1",
  });

  my $ad_param2 = Google::Ads::AdWords::v201708::AdParam->new({
      adGroupId     => $ad_group_id,
      criterionId   => $keyword_id,
      insertionText => "\$40",
      paramIndex    => "2",
  });

  # Create operations.
  my $ad_param_operation1 =
    Google::Ads::AdWords::v201708::AdParamOperation->new({
      operator => "SET",
      operand  => $ad_param1
    });

  my $ad_param_operation2 =
    Google::Ads::AdWords::v201708::AdParamOperation->new({
      operator => "SET",
      operand  => $ad_param2
    });

  # Set ad parameters.
  my $ad_params =
    $client->AdParamService()
    ->mutate({operations => [$ad_param_operation1, $ad_param_operation2]});

  # Display ad parameters.
  if ($ad_params) {
    foreach my $ad_param (@{$ad_params}) {
      printf "Ad parameter with ad group id \"%d\", criterion id \"%d\", " .
        "insertion text \"%s\", and parameter index \"%d\" was set.\n",
        $ad_param->get_adGroupId(),     $ad_param->get_criterionId(),
        $ad_param->get_insertionText(), $ad_param->get_paramIndex();
    }
  } else {
    print "No ad parameters were set.\n";
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

# Call the example
set_ad_parameters($client, $ad_group_id, $keyword_id);
