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
# This example updates the bid of a keyword. To get keywords, run
# basic_operations/get_keywords.pl.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201710::AdGroupCriterionOperation;
use Google::Ads::AdWords::v201710::BiddableAdGroupCriterion;
use Google::Ads::AdWords::v201710::Criterion;

use Cwd qw(abs_path);

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";
my $keyword_id  = "INSERT_KEYWORD_ID_HERE";

# Example main subroutine.
sub update_keyword {
  my $client      = shift;
  my $ad_group_id = shift;
  my $keyword_id  = shift;

  # Create base class criterion to avoid setting keyword specific fields.
  my $criterion =
    Google::Ads::AdWords::v201710::Criterion->new({id => $keyword_id,});

  # Create ad group criterion.
  my $ad_group_criterion =
    Google::Ads::AdWords::v201710::BiddableAdGroupCriterion->new({
      adGroupId => $ad_group_id,
      criterion => $criterion
    });

  # Create bids.
  my $bids = Google::Ads::AdWords::v201710::BiddingStrategyConfiguration->new({
      bids => [
        Google::Ads::AdWords::v201710::CpcBid->new({
            bid => Google::Ads::AdWords::v201710::Money->new(
              {microAmount => 1000000})}
        ),
      ]});

  $ad_group_criterion->set_biddingStrategyConfiguration($bids);

  # Create operation.
  my $operation = Google::Ads::AdWords::v201710::AdGroupCriterionOperation->new(
    {
      operand  => $ad_group_criterion,
      operator => "SET"
    });

  # Update ad group criteria.
  my $result =
    $client->AdGroupCriterionService()->mutate({operations => [$operation]});

  # Display ad group criteria.
  if ($result->get_value()) {
    my $ad_group_criterion = $result->get_value()->[0];
    printf "Keyword with ad group id \"%d\", id \"%d\" was updated with bid " .
      "amount = \"%d\" micros.\n",
      $ad_group_criterion->get_adGroupId(),
      $ad_group_criterion->get_criterion()->get_id,
      $ad_group_criterion->get_biddingStrategyConfiguration()->get_bids()->[0]
      ->get_bid()->get_microAmount();
  } else {
    print "No keyword was updated.\n";
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
update_keyword($client, $ad_group_id, $keyword_id);
