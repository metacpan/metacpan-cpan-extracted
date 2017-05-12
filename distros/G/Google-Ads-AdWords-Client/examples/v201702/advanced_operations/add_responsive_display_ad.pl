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
# This code example adds an image representing the ad using the MediaService and
# then adds a responsive display ad to a given ad group.
# To get ad groups, run basic_operations/get_ad_groups.pl.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::Common::MediaUtils;
use Google::Ads::AdWords::v201702::AdGroupAd;
use Google::Ads::AdWords::v201702::AdGroupAdOperation;
use Google::Ads::AdWords::v201702::ResponsiveDisplayAd;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";

# Example main subroutine.
sub add_responsive_display_ad {
  my $client      = shift;
  my $ad_group_id = shift;

  # Create image.
  my $image_data = Google::Ads::Common::MediaUtils::get_base64_data_from_url(
    "https://goo.gl/3b9Wfh");
  my $image = Google::Ads::AdWords::v201702::Image->new({
      data => $image_data,
      type => "IMAGE"
  });

  # Upload image.
  $image = $client->MediaService()->upload({media => [$image]});

  # This ad format does not allow the creation of an image using the
  # Image.data field. An image must first be created using the MediaService,
  # and Image.mediaId must be populated when creating the ad.
  my $marketing_image = Google::Ads::AdWords::v201702::Image->new(
    {mediaId => $image->get_mediaId()});

  # Create the responsive display ad.
  my $responsive_display_ad =
    Google::Ads::AdWords::v201702::ResponsiveDisplayAd->new({
      marketingImage => $marketing_image,
      shortHeadline  => "Travel",
      longHeadline   => "Travel the World",
      description    => "Take to the air!",
      businessName   => "Interplanetary Cruises",
      finalUrls      => ["http://www.example.com/"],
    });

  # Create ad group ad for the responsive display ad.
  my $responsive_display_ad_group_ad =
    Google::Ads::AdWords::v201702::AdGroupAd->new({
      adGroupId => $ad_group_id,
      ad        => $responsive_display_ad,
      # Additional properties (non-required).
      status => "PAUSED"
    });

  # Create operation.
  my $responsive_display_ad_group_ad_operation =
    Google::Ads::AdWords::v201702::AdGroupAdOperation->new({
      operator => "ADD",
      operand  => $responsive_display_ad_group_ad
    });

  # Add responsive display ad.
  my $result =
    $client->AdGroupAdService()
    ->mutate({operations => [$responsive_display_ad_group_ad_operation]});

  # Display results.
  if ($result->get_value()) {
    foreach my $ad_group_ad (@{$result->get_value()}) {
      printf "New responsive display ad with id \"%d\" and " .
        "short headline \"%s\" was added.\n",
        $ad_group_ad->get_ad()->get_id(),
        $ad_group_ad->get_ad()->get_shortHeadline();
    }
  } else {
    print "No responsive display ads were added.\n";
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
my $client = Google::Ads::AdWords::Client->new({version => "v201702"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_responsive_display_ad($client, $ad_group_id);
