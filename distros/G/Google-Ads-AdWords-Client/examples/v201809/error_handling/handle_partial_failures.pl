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
# This example demonstrates how to handle partial failures.

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201809::AdGroupCriterionOperation;
use Google::Ads::AdWords::v201809::BiddableAdGroupCriterion;
use Google::Ads::AdWords::v201809::Keyword;
use Google::Ads::Common::ErrorUtils;

use Cwd qw(abs_path);

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";

# Example main subroutine.
sub handle_partial_failures {
  my $client      = shift;
  my $ad_group_id = shift;

  # Setting partial failures flag.
  $client->set_partial_failure(1);

  # Create keywords.
  my @keywords = (
    Google::Ads::AdWords::v201809::Keyword->new({
        text      => "mars cruise",
        matchType => "BROAD"
      }
    ),
    Google::Ads::AdWords::v201809::Keyword->new({
        text      => "inv\@lid cruise",
        matchType => "BROAD"
      }
    ),
    Google::Ads::AdWords::v201809::Keyword->new({
        text      => "venus cruise",
        matchType => "BROAD"
      }
    ),
    Google::Ads::AdWords::v201809::Keyword->new({
        text      => "b\(a\)d keyword cruise",
        matchType => "BROAD"
      }));

  # Create biddable ad group criterions and operations.
  my @operations = ();
  for my $keyword (@keywords) {
    my $keyword_biddable_ad_group_criterion =
      Google::Ads::AdWords::v201809::BiddableAdGroupCriterion->new({
        adGroupId => $ad_group_id,
        criterion => $keyword
      });
    push @operations,
      Google::Ads::AdWords::v201809::AdGroupCriterionOperation->new({
        operator => "ADD",
        operand  => $keyword_biddable_ad_group_criterion
      });
  }

  # Add ad group criteria.
  my $result =
    $client->AdGroupCriterionService()->mutate({operations => \@operations});

  # Display results.
  if ($result->get_value() || $result->get_partialFailureErrors()) {
    # Display added criteria.
    foreach my $ad_group_criterion (@{$result->get_value()}) {
      if (
        $ad_group_criterion->isa(
          "Google::Ads::AdWords::v201809::BiddableAdGroupCriterion"))
      {
        printf "Ad group criterion with ad group id \"%d\", criterion id " .
          "\"%d\", and keyword \"%s\" was added.\n",
          $ad_group_criterion->get_adGroupId(),
          $ad_group_criterion->get_criterion()->get_id(),
          $ad_group_criterion->get_criterion()->get_text();
      }
    }

    # Check partial failures.
    foreach my $error (@{$result->get_partialFailureErrors()}) {
      # Get the index of the failed operation from the error's field path
      # elements.
      my $field_path_elements = $error->get_fieldPathElements();
      my $first_field_path_element =
        ($field_path_elements && (scalar $field_path_elements > 0))
        ? $field_path_elements->[0]
        : undef;
      if ( $first_field_path_element
        && $first_field_path_element->get_field() eq "operations"
        && defined $first_field_path_element->get_index())
      {
        my $error_index        = $first_field_path_element->get_index();
        my $ad_group_criterion = $operations[$error_index]->get_operand();
        printf "Ad group criterion with ad group id \"%d\" and keyword " .
          "\"%s\" as trigger a failure for the following reason: " .
          "\"%s\".\n",
          $ad_group_criterion->get_adGroupId(),
          $ad_group_criterion->get_criterion()->get_text(),
          $error->get_errorString();
      } else {
        printf "A failure for the following reason: \"%s\" has ocurred.\n",
          $error->get_errorString();
      }
    }
  } else {
    print "No ad group criteria were added.";
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

# Call the example
handle_partial_failures($client, $ad_group_id);
