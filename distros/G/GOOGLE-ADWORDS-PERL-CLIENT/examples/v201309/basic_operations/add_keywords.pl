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
# This example adds multiple keywords to an ad group. To get ad groups run
# basic_operations/get_ad_groups.pl.
#
# Tags: AdGroupCriterionService.mutate
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201309::AdGroupCriterionOperation;
use Google::Ads::AdWords::v201309::BiddableAdGroupCriterion;
use Google::Ads::AdWords::v201309::BiddingStrategyConfiguration;
use Google::Ads::AdWords::v201309::CpcBid;
use Google::Ads::AdWords::v201309::Keyword;
use Google::Ads::AdWords::v201309::Money;
use Google::Ads::AdWords::v201309::Placement;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";

# Example main subroutine.
sub add_keywords {
  my $client = shift;
  my $ad_group_id = shift;
  # Create keywords.
  my @keywords = ();


  # Create operations.
  my $num_keywords = 5;
  my @operations = ();
  for(my $i = 0; $i < $num_keywords; $i++) {
    my $keyword = Google::Ads::AdWords::v201309::Keyword->new({
      text => "mars cruise " . uniqid(),
      matchType => "BROAD"
    });

    # Create biddable ad group criterion.
    my $keyword_biddable_ad_group_criterion =
        Google::Ads::AdWords::v201309::BiddableAdGroupCriterion->new({
          adGroupId => $ad_group_id,
          criterion => $keyword,
          # Set bids (non-required).
          biddingStrategyConfiguration =>
              Google::Ads::AdWords::v201309::BiddingStrategyConfiguration->new({
                bids => [
                  Google::Ads::AdWords::v201309::CpcBid->new({
                    bid => Google::Ads::AdWords::v201309::Money->new({
                      microAmount => 500000
                    })
                  }),
                ]
              }),
          # Additional properties (non-required).
          userStatus => "PAUSED",
          destinationUrl => "http://www.example.com/mars"
        });
    # Create operation.
    my $keyword_ad_group_operation =
      Google::Ads::AdWords::v201309::AdGroupCriterionOperation->new({
        operator => "ADD",
        operand => $keyword_biddable_ad_group_criterion
      });
    push @operations, $keyword_ad_group_operation;
  }

  # Add ad group criteria.
  my $result = $client->AdGroupCriterionService()->mutate({
    operations => \@operations
  });

  # Display ad group criteria.
  if ($result->get_value()) {
    foreach my $keyword (@{$result->get_value()}) {
      printf "Keyword with ad group id \"%d\", id \"%d\", " .
             "text \"%s\" and match type \"%s\" was added.\n",
             $keyword->get_adGroupId(),
             $keyword->get_criterion()->get_id(),
             $keyword->get_criterion()->get_text(),
             $keyword->get_criterion()->get_matchType();
    }
  } else {
    print "No keywords were added.";
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
add_keywords($client, $ad_group_id);
