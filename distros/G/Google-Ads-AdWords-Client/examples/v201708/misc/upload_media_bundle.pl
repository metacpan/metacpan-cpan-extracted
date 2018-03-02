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
# This example uploads an HTML5 zip file as a MediaBundle.

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201708::MediaBundle;
use Google::Ads::Common::MapUtils;
use Google::Ads::Common::MediaUtils;

use Cwd qw(abs_path);

# Example main subroutine.
sub upload_media_bundle {
  my $client = shift;

  # Create $zip media.
  my $html5_zip = Google::Ads::Common::MediaUtils::get_base64_data_from_url(
    "https://goo.gl/9Y7qI2");

  # Create a media bundle containing the zip file with all the HTML5 components.
  my $media_bundle = Google::Ads::AdWords::v201708::MediaBundle->new({
      data       => $html5_zip,
      type       => "MEDIA_BUNDLE"
  });

  # Upload HTML5 zip.
  $media_bundle = $client->MediaService()->upload({media => [$media_bundle]});

  # Display HTML5 zip.
  if ($media_bundle) {
    my $dimensions =
      Google::Ads::Common::MapUtils::get_map($media_bundle->get_dimensions());
    printf(
      "Media bundle with ID %d, dimensions \"%dx%d\", and MIME type \"%s\ " .
        "was uploaded.\n",
      $media_bundle->get_mediaId(),
      $dimensions->{"FULL"}->get_width(),
      $dimensions->{"FULL"}->get_height(),
      $media_bundle->get_mimeType()
    );
  } else {
    print "No media bundle was uploaded.\n";
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
my $client = Google::Ads::AdWords::Client->new({version => "v201708"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
upload_media_bundle($client);
