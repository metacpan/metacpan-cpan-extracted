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
# This example adds various types of targeting criteria to a campaign. To get
# campaigns, run basic_operations/get_campaigns.pl.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201708::AdGroupCriterionOperation;
use Google::Ads::AdWords::v201708::AgeRange;
use Google::Ads::AdWords::v201708::BiddableAdGroupCriterion;
use Google::Ads::AdWords::v201708::Gender;

use Cwd qw(abs_path);

use constant GENDER_MALE            => 11;
use constant AGE_RANGE_UNDETERMINED => 503999;

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";

# Example main subroutine.
sub add_demographic_targeting_criteria {
  my $client      = shift;
  my $ad_group_id = shift;

  my @criteria = ();

  # Create gender criteria. The IDs can be found in the documentation:
  # https://developers.google.com/adwords/api/docs/appendix/genders.
  my $gender_male =
    Google::Ads::AdWords::v201708::Gender->new({id => GENDER_MALE});
  push @criteria, $gender_male;

  # Create age range criteria. The IDs can be found in the documentation:
  # https://developers.google.com/adwords/api/docs/appendix/ages.
  my $age_range = Google::Ads::AdWords::v201708::AgeRange->new(
    {id => AGE_RANGE_UNDETERMINED});
  push @criteria, $age_range;

  # Create operations.
  my @operations = ();
  foreach my $criterion (@criteria) {
    my $operation =
      Google::Ads::AdWords::v201708::AdGroupCriterionOperation->new({
        operator => "ADD",
        operand => Google::Ads::AdWords::v201708::BiddableAdGroupCriterion->new(
          {
            adGroupId => $ad_group_id,
            criterion => $criterion
          })});
    push @operations, $operation;
  }

  # Add ad group criteria.
  my $result =
    $client->AdGroupCriterionService()->mutate({operations => \@operations});

  # Display campaign criteria.
  if ($result->get_value()) {
    foreach my $ad_group_criterion (@{$result->get_value()}) {
      printf "Ad group criterion with ad group id '%s', criterion id '%s', " .
        "and type '%s' was added.\n",
        $ad_group_criterion->get_adGroupId(),
        $ad_group_criterion->get_criterion()->get_id(),
        $ad_group_criterion->get_criterion()->get_type();
    }
  } else {
    print "No ad group criteria were added.\n";
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
add_demographic_targeting_criteria($client, $ad_group_id);
