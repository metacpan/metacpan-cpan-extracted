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
# This example demonstrates how to handle policy violation errors.

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201710::AdGroupAd;
use Google::Ads::AdWords::v201710::AdGroupAdOperation;
use Google::Ads::AdWords::v201710::ExemptionRequest;
use Google::Ads::AdWords::v201710::ExpandedTextAd;
use Google::Ads::Common::ErrorUtils;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";

# Example main subroutine.
sub handle_policy_violation_error {
  my $client      = shift;
  my $ad_group_id = shift;

  # Don't die on fault it will be handled in code.
  $client->set_die_on_faults(0);
  $client->set_validate_only(1);

  my @operations = ();

  # Create text ad that violates an exemptable policy.
  my $exemptable_text_ad = Google::Ads::AdWords::v201710::ExpandedTextAd->new({
      headlinePart1 => "Mars " . substr(uniqid(), 0, 8) . "!",
      headlinePart2 => "Visit the Red Planet in style.",
      description   => "Low-gravity fun for everyone!",
      finalUrls     => ['http://www.example.com']});

  # Create ad group ad.
  my $exemptable_text_ad_group_ad =
    Google::Ads::AdWords::v201710::AdGroupAd->new({
      adGroupId => $ad_group_id,
      ad        => $exemptable_text_ad,
      # Additional properties (non-required).
      status => "PAUSED"
    });

  # Create operation.
  my $exemptable_text_ad_group_ad_operation =
    Google::Ads::AdWords::v201710::AdGroupAdOperation->new({
      operator => "ADD",
      operand  => $exemptable_text_ad_group_ad
    });
  push @operations, $exemptable_text_ad_group_ad_operation;

  # Validate the ads.
  my $result =
    $client->AdGroupAdService()->mutate({operations => \@operations});
  my @operation_indicies_to_remove = ();
  foreach
    my $error (@{$result->get_detail()->get_ApiExceptionFault()->get_errors()})
  {
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
      my $operation_index = $first_field_path_element->get_index();
      my $operation       = $operations[$operation_index];
      if ($error->get_ApiError__Type() =~ "PolicyViolationError") {
        printf "Ad with headline '%s' violated '%s' policy '%s'.\n",
          $operation->get_operand()->get_ad()->get_headlinePart1(),
          $error->get_isExemptable ? 'exemptable' : 'non-exemptable',
          $error->get_externalPolicyName();

        if ($error->get_isExemptable()) {
          # Add exemption request to the operation.
          printf(
            "Adding exemption request for policy name '%s' on text " .
              "'%s'.\n",
            $error->get_key()->get_policyName(),
            $error->get_key()->get_violatingText());
          $operation->set_exemptionRequests([
              new Google::Ads::AdWords::v201710::ExemptionRequest(
                {key => $error->get_key()})]);
        } else {
          # Remove non-exemptable operation.
          print "Removing from the request.\n";
          push @operation_indicies_to_remove, $operation_index;
        }
      } else {
        # Non-policy error returned, remove ad.
        print "Removing from the request.\n";
        push @operation_indicies_to_remove, $operation_index;
      }
    }
  }

  # Remove operations that cannot be exempted.
  while (scalar @operation_indicies_to_remove > 0) {
    my $index = pop @operation_indicies_to_remove;
    splice @operations, $index, 1;
  }

  if (scalar @operations > 0) {
    #  Disable validate_only so we can submit the AdGroupAds with exemptions.
    $client->set_validate_only(0);

    #  Add ads with exemptions.
    my $result =
      $client->AdGroupAdService()->mutate({operations => \@operations});

    # Display results.
    if ($result->get_value()) {
      foreach my $ad_group_ad (@{$result->get_value()}) {
        printf "Ad with ID %d and headline '%s' was added.\n",
          $ad_group_ad->get_ad()->get_id(),
          $ad_group_ad->get_ad()->get_headlinePart1();
      }
    }
  } else {
    printf("No ads were added.\n");
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
my $client = Google::Ads::AdWords::Client->new({version => "v201710"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
handle_policy_violation_error($client, $ad_group_id);
