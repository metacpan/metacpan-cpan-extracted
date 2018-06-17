#!/usr/bin/perl -w
#
# Copyright 2018, Google Inc. All Rights Reserved.
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
# This code example adds a Gmail ad to a given ad group. The ad group's campaign
# needs to have an AdvertisingChannelType of DISPLAY and
# AdvertisingChannelSubType of DISPLAY_GMAIL_AD.
# To get ad groups, run basic_operations/get_ad_groups.pl.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::Common::MediaUtils;
use Google::Ads::AdWords::v201806::AdGroupAd;
use Google::Ads::AdWords::v201806::AdGroupAdOperation;
use Google::Ads::AdWords::v201806::GmailAd;
use Google::Ads::AdWords::v201806::GmailTeaser;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";

# Example main subroutine.
sub add_gmail_ad {
  my ($client, $ad_group_id) = @_;

  # This ad format does not allow the creation of an image using the
  # Image.data field. An image must first be created using the MediaService,
  # and Image.mediaId must be populated when creating the ad.
  my $logo_image = _upload_image($client, 'https://goo.gl/mtt54n');
  my $logo = Google::Ads::AdWords::v201806::Image->new({
    mediaId => $logo_image->get_mediaId(),
  });

  my $ad_image = _upload_image($client, "http://goo.gl/3b9Wfh");
  my $marketing_image = Google::Ads::AdWords::v201806::Image->new(
    {mediaId => $ad_image->get_mediaId()});

  my $teaser = Google::Ads::AdWords::v201806::GmailTeaser->new({
    headline     => "Dream",
    description  => "Create your own adventure",
    businessName => "Interplanetary Ships",
    logoImage    => $logo_image
  });

  # Create the Gmail ad.
  my $gmail_ad = Google::Ads::AdWords::v201806::GmailAd->new({
      teaser => $teaser,
      marketingImage            => $marketing_image,
      marketingImageHeadline    => "Travel",
      marketingImageDescription => "Take to the skies!",
      finalUrls                 => ["http://www.example.com/"]
  });

  # Create ad group ad for the Gmail ad.
  my $gmail_ad_group_ad = Google::Ads::AdWords::v201806::AdGroupAd->new({
    adGroupId => $ad_group_id,
    ad        => $gmail_ad,
    # Additional properties (non-required).
    status => "PAUSED"
  });

  # Create operation.
  my $gmail_ad_group_ad_operation =
    Google::Ads::AdWords::v201806::AdGroupAdOperation->new({
      operator => "ADD",
      operand  => $gmail_ad_group_ad
    });

  # Add Gmail ad.
  my $result =
    $client->AdGroupAdService()
    ->mutate({operations => [$gmail_ad_group_ad_operation]});

  # Display results.
  if ($result->get_value()) {
    foreach my $ad_group_ad (@{$result->get_value()}) {
      printf "New Gmail ad with ID %d and headline \"%s\" was added.\n",
        $ad_group_ad->get_ad()->get_id(),
        $ad_group_ad->get_ad()->get_teaser()->get_headline();
    }
  } else {
    print "No Gmail ads were added.\n";
    return 0;
  }

  return 1;
}

sub _upload_image {
  my ($client, $url) = @_;

  # Creates an image and upload it to the server.
  my $image_data =
    Google::Ads::Common::MediaUtils::get_base64_data_from_url($url);
  my $image = Google::Ads::AdWords::v201806::Image->new({
    data => $image_data,
    type => "IMAGE"
  });

  return $client->MediaService()->upload({media => [$image]});
}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
  return 1;
}

# Log SOAP XML request, response and API errors.
Google::Ads::AdWords::Logging::enable_all_logging(1);

# Get AdWords Client, credentials will be read from ~/adwords.properties.
my $client = Google::Ads::AdWords::Client->new({version => "v201806"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_gmail_ad($client, $ad_group_id);

