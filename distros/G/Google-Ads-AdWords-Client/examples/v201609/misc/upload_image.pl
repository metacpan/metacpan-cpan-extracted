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
# This example uploads an image. To get images, run
# misc/get_all_images_and_video.pl.

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201609::Image;
use Google::Ads::Common::MapUtils;
use Google::Ads::Common::MediaUtils;

use Cwd qw(abs_path);

# Example main subroutine.
sub upload_image {
  my $client = shift;

  # Create image.
  my $image_data = Google::Ads::Common::MediaUtils::get_base64_data_from_url(
    "http://goo.gl/HJM3L");
  my $image = Google::Ads::AdWords::v201609::Image->new({
      data => $image_data,
      type => "IMAGE"
    }
  );

  # Upload image.
  $image = $client->MediaService()->upload({media => [$image]});

  # Display images.
  if ($image) {
    my $dimensions =
      Google::Ads::Common::MapUtils::get_map($image->get_dimensions());
    printf(
      "Image with id \"%s\", dimensions \"%dx%d\", and MIME type \"%s\" " .
        "was uploaded.\n",
      $image->get_mediaId(),
      $dimensions->{"FULL"}->get_width(),
      $dimensions->{"FULL"}->get_height(),
      $image->get_mimeType()
    );
  } else {
    print "No image was uploaded.\n";
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
upload_image($client);
