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
# This code example adds text ads to a given ad group. To get ad groups,
# run basic_operations/get_ad_groups.pl.
#
# Tags: AdGroupAdService.mutate
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201309::AdGroupAd;
use Google::Ads::AdWords::v201309::AdGroupAdOperation;
use Google::Ads::AdWords::v201309::Image;
use Google::Ads::AdWords::v201309::ImageAd;
use Google::Ads::AdWords::v201309::TemplateAd;
use Google::Ads::AdWords::v201309::TextAd;
use Google::Ads::AdWords::v201309::Video;
use Google::Ads::Common::MediaUtils;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";

# Example main subroutine.
sub add_text_ads {
  my $client = shift;
  my $ad_group_id = shift;

  my $num_ads = 5;
  my @operations = ();
  for(my $i = 0; $i < $num_ads; $i++) {
    # Create text ad.
    my $text_ad = Google::Ads::AdWords::v201309::TextAd->new({
      headline => "Cruise to Mars #" . substr(uniqid(), 0, 8),
      description1 => "Visit the Red Planet in style.",
      description2 => "Buy your tickets now!",
      displayUrl => "www.example.com/cruises",
      url => "http://www.example.com"
    });

    # Create ad group ad for the text ad.
    my $text_ad_group_ad = Google::Ads::AdWords::v201309::AdGroupAd->new({
      adGroupId => $ad_group_id,
      ad => $text_ad,
      # Additional properties (non-required).
      status => "PAUSED"
    });

    # Create operation.
    my $text_ad_group_ad_operation =
      Google::Ads::AdWords::v201309::AdGroupAdOperation->new({
        operator => "ADD",
        operand => $text_ad_group_ad
      });
    push @operations, $text_ad_group_ad_operation;
  }

  # Add text ads.
  my $result = $client->AdGroupAdService()->mutate({
    operations => \@operations
  });

  # Display results.
  if ($result->get_value()) {
    foreach my $ad_group_ad (@{$result->get_value()}) {
      printf "New text ad with id \"%d\" and display url \"%s\" was added.\n",
             $ad_group_ad->get_ad()->get_id(),
             $ad_group_ad->get_ad()->get_displayUrl();
    }
  } else {
    print "No text ads were added.\n";
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
add_text_ads($client, $ad_group_id);
