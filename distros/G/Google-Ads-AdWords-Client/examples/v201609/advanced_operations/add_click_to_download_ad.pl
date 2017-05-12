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
# This code example adds a click to download ad to a given ad group.
# To get ad groups, run basic_operations/get_ad_groups.pl.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::Common::MediaUtils;
use Google::Ads::AdWords::v201609::AdGroupAd;
use Google::Ads::AdWords::v201609::AdGroupAdOperation;
use Google::Ads::AdWords::v201609::Image;
use Google::Ads::AdWords::v201609::TemplateAd;
use Google::Ads::AdWords::v201609::TemplateElementField;
use Google::Ads::Common::MediaUtils;

use Cwd qw(abs_path);

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";

# Example main subroutine.
sub add_click_to_download_ad {
  my $client      = shift;
  my $ad_group_id = shift;

  my @operations = ();

  # Create the template ad.
  my $click_to_download_ad = Google::Ads::AdWords::v201609::TemplateAd->new({
    name       => "Ad for demo game",
    templateId => 353,
    finalUrls =>
      ["http://play.google.com/store/apps/details?id=com.example.demogame"],
    displayUrl => "play.google.com"
  });

  # Create the template elements for the ad. You can refer to
  # https://developers.google.com/adwords/api/docs/appendix/templateads
  # for the list of avaliable template fields.
  my $headline = Google::Ads::AdWords::v201609::TemplateElementField->new({
    name      => "headline",
    fieldText => "Enjoy your drive in Mars",
    type      => "TEXT"
  });

  my $description1 = Google::Ads::AdWords::v201609::TemplateElementField->new({
    name      => "description1",
    fieldText => "Realistic physics simulation",
    type      => "TEXT"
  });

  my $description2 = Google::Ads::AdWords::v201609::TemplateElementField->new({
    name      => "description2",
    fieldText => "Race against players online",
    type      => "TEXT"
  });

  my $appId = Google::Ads::AdWords::v201609::TemplateElementField->new({
    name      => "appId",
    fieldText => "com.example.demogame",
    type      => "TEXT"
  });

  my $appStore = Google::Ads::AdWords::v201609::TemplateElementField->new({
    name      => "appStore",
    fieldText => "2",
    type      => "ENUM"
  });

  # Optionally specify a landscape image. The image needs to be in a BASE64
  # encoded form. Here we download a demo image and encode it for this ad.
  my $image_data = Google::Ads::Common::MediaUtils::get_base64_data_from_url(
    "http://goo.gl/9JmyKk");
  my $image = Google::Ads::AdWords::v201609::Image->new({
    data => $image_data,
    type => "IMAGE"
  });
  my $landscapeImage = Google::Ads::AdWords::v201609::TemplateElementField->new(
    {
      name       => "landscapeImage",
      fieldMedia => $image,
      type       => "IMAGE"
    });

  my $adData = Google::Ads::AdWords::v201609::TemplateElement->new({
      uniqueName => "adData",
      fields     => [
        $headline, $description1, $description2,
        $appId,    $appStore,     $landscapeImage
      ]});

  $click_to_download_ad->set_templateElements([$adData]);

  # Create the AdGroupAd.
  my $click_to_download_ad_group_ad =
    Google::Ads::AdWords::v201609::AdGroupAd->new({
      adGroupId => $ad_group_id,
      ad        => $click_to_download_ad,
      # Additional properties (non-required).
      status => "PAUSED"
    });
  my $text_ad_group_ad_operation =
    Google::Ads::AdWords::v201609::AdGroupAdOperation->new({
      operator => "ADD",
      operand  => $click_to_download_ad_group_ad
    });

  push @operations, $text_ad_group_ad_operation;

  # Add text ads.
  my $result =
    $client->AdGroupAdService()->mutate({operations => \@operations});

  # Display results.
  if ($result->get_value()) {
    foreach my $ad_group_ad (@{$result->get_value()}) {
      printf "New click-to-download ad with id \"%d\" and display url " .
        "\"%s\" was added.\n",
        $ad_group_ad->get_ad()->get_id(),
        $ad_group_ad->get_ad()->get_displayUrl();
    }
  } else {
    print "No click-to-download ads were added.\n";
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
add_click_to_download_ad($client, $ad_group_id);
