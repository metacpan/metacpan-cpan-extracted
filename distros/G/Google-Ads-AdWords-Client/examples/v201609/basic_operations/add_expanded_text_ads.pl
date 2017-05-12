#!/usr/bin/perl -w
#
# Copyright 2016, Google Inc. All Rights Reserved.
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
# This code example adds expanded text ads to a given ad group.
# To get ad groups, run get_ad_groups.pl.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201609::AdGroupAd;
use Google::Ads::AdWords::v201609::AdGroupAdOperation;
use Google::Ads::AdWords::v201609::ExpandedTextAd;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";

# Example main subroutine.
sub add_expanded_text_ads {
  my $client      = shift;
  my $ad_group_id = shift;

  my $num_ads    = 5;
  my @operations = ();
  for (my $i = 0 ; $i < $num_ads ; $i++) {
    # Create text ad.
    my $expanded_text_ad = Google::Ads::AdWords::v201609::ExpandedTextAd->new({
        headlinePart1 => "Cruise to Mars #" . substr(uniqid(), 0, 8),
        headlinePart2 => "Best Space Cruise Line",
        description   => "Buy your tickets now!",
        finalUrls     => ["http://www.example.com/" . $i],
        path1         => "all-inclusive",
        path2         => "deals"
    });

    # Create ad group ad for the expanded text ad.
    my $ad_group_ad = Google::Ads::AdWords::v201609::AdGroupAd->new({
        adGroupId => $ad_group_id,
        ad        => $expanded_text_ad,
        # Additional properties (non-required).
        status => "PAUSED"
    });

    # Create operation.
    my $ad_group_ad_operation =
      Google::Ads::AdWords::v201609::AdGroupAdOperation->new({
        operator => "ADD",
        operand  => $ad_group_ad
      });
    push @operations, $ad_group_ad_operation;
  }

  # Add expanded text ad.
  my $result =
    $client->AdGroupAdService()->mutate({operations => \@operations});

  # Display results.
  if ($result->get_value()) {
    foreach my $ad_group_ad (@{$result->get_value()}) {
      printf "New expanded text ad with id \"%d\" and " .
        "headline \"%s - %s\" was added.\n",
        $ad_group_ad->get_ad()->get_id(),
        $ad_group_ad->get_ad()->get_headlinePart1(),
        $ad_group_ad->get_ad()->get_headlinePart2();
    }
  } else {
    print "No expanded text ads were added.\n";
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
my $client = Google::Ads::AdWords::Client->new({version => "v201609"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_expanded_text_ads($client, $ad_group_id);
