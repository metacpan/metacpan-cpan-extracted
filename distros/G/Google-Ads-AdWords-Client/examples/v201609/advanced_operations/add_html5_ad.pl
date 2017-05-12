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
# This code example adds an HTML5 ad to a given ad group.
# To get ad groups, run basic_operations/get_ad_groups.pl.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201609::AdGroupAd;
use Google::Ads::AdWords::v201609::AdGroupAdOperation;
use Google::Ads::AdWords::v201609::Dimensions;
use Google::Ads::AdWords::v201609::MediaBundle;
use Google::Ads::AdWords::v201609::TemplateAd;
use Google::Ads::AdWords::v201609::TemplateElementField;
use Google::Ads::Common::MediaUtils;

use Cwd qw(abs_path);

# Replace with valid values of your account.
my $ad_group_id = "INSERT_ADGROUP_ID_HERE";

# Example main subroutine.
sub add_html5_ad {
  my $client      = shift;
  my $ad_group_id = shift;

  my @operations = ();

  # Create the template ad.
  my $html5_ad = Google::Ads::AdWords::v201609::TemplateAd->new({
      name       => "Ad for HTML5",
      templateId => 419,
      finalUrls  => ["http://example.com/html5"],
      displayUrl => "www.example.com/html5",
      dimensions => Google::Ads::AdWords::v201609::Dimensions->new({
          width  => 300,
          height => 250
        })});

  # The HTML5 zip file contains all the HTML, CSS, and images needed for the
  # HTML5 ad. For help on creating an HTML5 zip file, check out Google Web
  # Designer (https://www.google.com/webdesigner/).
  my $html5_zip = Google::Ads::Common::MediaUtils::get_base64_data_from_url(
    "https://goo.gl/9Y7qI2");

  # Create a media bundle containing the zip file with all the HTML5 components.
  # NOTE: You may also upload an HTML5 zip using MediaService.upload()
  # and simply set the mediaId field below. See upload_media_bundle.pl
  # for an example.
  my $media_bundle = Google::Ads::AdWords::v201609::MediaBundle->new({
      data       => $html5_zip,
      entryPoint => "carousel/index.html",
      type       => "MEDIA_BUNDLE"
  });

  # Create the template elements for the ad. You can refer to
  # https://developers.google.com/adwords/api/docs/appendix/templateads
  # for the list of available template fields.
  my $media = Google::Ads::AdWords::v201609::TemplateElementField->new({
      name       => "Custom_layout",
      fieldMedia => $media_bundle,
      type       => "MEDIA_BUNDLE"
  });
  my $layout = Google::Ads::AdWords::v201609::TemplateElementField->new({
      name      => "layout",
      fieldText => "Custom",
      type      => "ENUM"
  });

  my $adData = Google::Ads::AdWords::v201609::TemplateElement->new({
      uniqueName => "adData",
      fields     => [$media, $layout]});

  $html5_ad->set_templateElements([$adData]);

  # Create the AdGroupAd.
  my $html5_ad_group_ad = Google::Ads::AdWords::v201609::AdGroupAd->new({
      adGroupId => $ad_group_id,
      ad        => $html5_ad,
      # Additional properties (non-required).
      status => "PAUSED"
  });
  my $ad_group_ad_operation =
    Google::Ads::AdWords::v201609::AdGroupAdOperation->new({
      operator => "ADD",
      operand  => $html5_ad_group_ad
    });

  push @operations, $ad_group_ad_operation;

  # Add HTML5 ad.
  my $result =
    $client->AdGroupAdService()->mutate({operations => \@operations});

  # Display results.
  if ($result->get_value()) {
    foreach my $ad_group_ad (@{$result->get_value()}) {
      printf "New HTML5 ad with id \"%d\" and display url " .
        "\"%s\" was added.\n",
        $ad_group_ad->get_ad()->get_id(),
        $ad_group_ad->get_ad()->get_displayUrl();
    }
  } else {
    print "No HTML5 ads were added.\n";
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
add_html5_ad($client, $ad_group_id);
