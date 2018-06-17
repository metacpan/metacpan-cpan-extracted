#!/usr/bin/perl -w
#
# Copyright 2018 Google LLC
#
# License:: Licensed under the Apache License, Version 2.0 (the "License");
#           you may not use this file except in compliance with the License.
#           You may obtain a copy of the License at
#
#           http://www.apache.org/licenses/LICENSE-2.0
#
#           Unless required by applicable law or agreed to in writing, software
#           distributed under the License is distributed on an "AS IS" BASIS,
#           WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
#           implied.
#           See the License for the specific language governing permissions and
#           limitations under the License.
#
# This example adds a responsive search ad to a given ad group.
# To get ad groups, run get_ad_groups.pl.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201806::AdGroupAd;
use Google::Ads::AdWords::v201806::AdGroupAdOperation;
use Google::Ads::AdWords::v201806::AssetLink;
use Google::Ads::AdWords::v201806::ResponsiveSearchAd;
use Google::Ads::AdWords::v201806::TextAsset;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";

# Example main subroutine.
sub add_responsive_search_ad {
  my ($client, $ad_group_id) = @_;

  my $responsive_search_ad =
      Google::Ads::AdWords::v201806::ResponsiveSearchAd->new({
      headlines    => [
          Google::Ads::AdWords::v201806::AssetLink->new({
              asset       => Google::Ads::AdWords::v201806::TextAsset->new({
                  assetText => "Cruise to Mars #" . substr(uniqid(), 0, 8)
              }),
              pinnedField => "HEADLINE_1"
          }),
          Google::Ads::AdWords::v201806::AssetLink->new({
              asset => Google::Ads::AdWords::v201806::TextAsset->new({
                  assetText => "Best Space Cruise Line"
              }),
          }),
          Google::Ads::AdWords::v201806::AssetLink->new({
              asset => Google::Ads::AdWords::v201806::TextAsset->new({
                  assetText => "Experience the Stars"
              }),
          }) ],
      descriptions => [
          Google::Ads::AdWords::v201806::AssetLink->new({
              asset => Google::Ads::AdWords::v201806::TextAsset->new({
                  assetText => "Buy your tickets now"
              }),
          }),
          Google::Ads::AdWords::v201806::AssetLink->new({
              asset => Google::Ads::AdWords::v201806::TextAsset->new({
                  assetText => "Visit the Red Planet"
              })
          })
      ],
      finalUrls    => [ "http://www.example.com/cruise" ],
      path1        => "all-inclusive",
      path2        => "deals"
  });

  my $ad_group_ad = Google::Ads::AdWords::v201806::AdGroupAd->new({
      adGroupId => $ad_group_id,
      ad        => $responsive_search_ad,
      # Additional properties (non-required).
      status    => "PAUSED"
  });

  # Create operation.
  my $operation =
      Google::Ads::AdWords::v201806::AdGroupAdOperation->new({
          operator => "ADD",
          operand  => $ad_group_ad
      });

  # Add ad.
  my $result =
      $client->AdGroupAdService()->mutate({ operations => [ $operation ] });
  if ($result->get_value()) {
    foreach my $ad_group_ad (@{$result->get_value()}) {
      printf "New responsive search ad with ID %d was added.\n",
          $ad_group_ad->get_ad()->get_id();
      printf "  Headlines:\n";
      foreach my $headline (@{$ad_group_ad->get_ad()->get_headlines()}) {
        my $pinned = $headline->get_pinnedField();
        printf "    %s\n", $headline->get_asset()->get_assetText();
        if ($pinned) {
          printf "      (pinned to %s)\n", $pinned;
        }
      }
      printf "  Descriptions:\n";
      foreach my $description (@{$ad_group_ad->get_ad()->get_descriptions()}) {
        my $pinned = $description->get_pinnedField();
        printf "    %s\n", $description->get_asset()->get_assetText();
        if ($pinned) {
          printf "      (pinned to %s)\n", $pinned;
        }
      }
    }
  }
  else {
    print "No ads were added.\n";
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
my $client = Google::Ads::AdWords::Client->new({ version => "v201806" });

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_responsive_search_ad($client, $ad_group_id);
