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
use Google::Ads::AdWords::v201309::AdGroupBidModifierOperation;
use Google::Ads::AdWords::v201309::AdGroupBidModifier;
use Google::Ads::AdWords::v201309::Platform;

use Cwd qw(abs_path);

use constant BID_MODIFIER => 1.5;

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";

# Example main subroutine.
sub add_ad_group_bid_modifier {
  my $client = shift;
  my $ad_group_id = shift;

  # Create mobile platform. The ID can be found in the documentation.
  # https://developers.google.com/adwords/api/docs/appendix/platforms
  my $mobile = Google::Ads::AdWords::v201309::Platform->new({
    id => 30001
  });

  # Create the bid modifier.
  my $modifier = Google::Ads::AdWords::v201309::AdGroupBidModifier->new({
    adGroupId => $ad_group_id,
    criterion => $mobile,
    bidModifier => BID_MODIFIER
  });

  # Create ADD operation.
  my $operation =
      Google::Ads::AdWords::v201309::AdGroupBidModifierOperation->new({
        operator => "ADD",
        operand => $modifier
      });

  # Update campaign criteria.
  my $result = $client->AdGroupBidModifierService()->mutate({
    operations => [$operation]
  });

  # Display campaign criteria.
  if ($result->get_value()) {
    foreach my $modifier (@{$result->get_value()}) {
      printf "Ad Group ID '%s', criterion ID '%s', " .
          "and type '%s' was modified with bid %.2f.\n",
          $modifier->get_adGroupId(),
          $modifier->get_criterion()->get_id(),
          $modifier->get_criterion()->get_type(),
          $modifier->get_bidModifier();
    }
  } else {
    print "No ad group bid modifier was added.\n";
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
add_ad_group_bid_modifier($client, $ad_group_id);
