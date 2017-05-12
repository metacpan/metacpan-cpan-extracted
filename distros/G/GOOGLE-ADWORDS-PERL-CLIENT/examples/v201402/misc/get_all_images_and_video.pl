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
# This example gets all images and videos associated to the account.
# To upload video, see
# http://adwords.google.com/support/aw/bin/answer.py?hl=en&amp;answer=39454.
# To upload an image, run misc/upload_image.pl.
#
# Tags: MediaService.get
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201402::OrderBy;
use Google::Ads::AdWords::v201402::Paging;
use Google::Ads::AdWords::v201402::Predicate;
use Google::Ads::AdWords::v201402::Selector;
use Google::Ads::Common::MapUtils;

use Cwd qw(abs_path);

use constant PAGE_SIZE => 500;

# Example main subroutine.
sub get_all_images_and_video {
  my $client = shift;

  # Create predicates.
  my $media_type_predicate = Google::Ads::AdWords::v201402::Predicate->new({
    field => "Type",
    operator => "IN",
    values => ["IMAGE", "VIDEO"]
  });

  # Create selector.
  my $paging = Google::Ads::AdWords::v201402::Paging->new({
    startIndex => 0,
    numberResults => PAGE_SIZE
  });
  my $selector = Google::Ads::AdWords::v201402::Selector->new({
    fields => ["MediaId", "Name", "MimeType", "Width", "Height"],
    predicates => [$media_type_predicate],
    ordering => [Google::Ads::AdWords::v201402::OrderBy->new({
      field => "Name",
      sortOrder => "ASCENDING"
    })],
    paging => $paging
  });

  # Paginate through results.
  my $page;
  do {
    # Get all images.
    $page = $client->MediaService()->get({serviceSelector => $selector});

    # Display images.
    if ($page->get_entries()) {
      foreach my $media (@{$page->get_entries()}) {
        if ($media->isa("Google::Ads::AdWords::v201402::Image")) {
          my $dimensions =
              Google::Ads::Common::MapUtils::get_map($media->get_dimensions());
          printf "Image with id \"%s\", dimensions \"%dx%d\", and MIME type " .
                 "\"%s\" was found.\n", $media->get_mediaId(),
                 $dimensions->{"FULL"}->get_width(),
                 $dimensions->{"FULL"}->get_height(), $media->get_mimeType();
        } else {
           printf "Video with id \"%s\" and name \"%s\" was found.\n",
                  $media->get_mediaId(), $media->get_name();
        }
      }
    }
    $paging->set_startIndex($paging->get_startIndex() + PAGE_SIZE);
  } while ($paging->get_startIndex() < $page->get_totalNumEntries());

  return 1;
}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
  return 1;
}

# Log SOAP XML request, response and API errors.
Google::Ads::AdWords::Logging::enable_all_logging();

# Get AdWords Client, credentials will be read from ~/adwords.properties.
my $client = Google::Ads::AdWords::Client->new({version => "v201402"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
get_all_images_and_video($client);
