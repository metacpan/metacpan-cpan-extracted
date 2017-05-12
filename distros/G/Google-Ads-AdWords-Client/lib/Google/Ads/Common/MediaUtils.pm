# Copyright 2013, Google Inc. All Rights Reserved.
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

package Google::Ads::Common::MediaUtils;

use strict;
use version;

# The following needs to be on one line because CPAN uses a particularly hacky
# eval() to determine module versions.
use Google::Ads::Common::Constants; our $VERSION = ${Google::Ads::Common::Constants::VERSION};

use HTTP::Request;
use LWP::UserAgent;
use URI::Escape;
use MIME::Base64;

sub get_base64_data_from_url (%) {
  my $url       = shift;
  my $request   = HTTP::Request->new(GET => $url);
  my $userAgent = LWP::UserAgent->new();
  $userAgent->agent(sprintf("%s: %s", __PACKAGE__, $0));
  my $response = $userAgent->request($request);
  if ($response->is_success()) {
    my $content = $response->content();
    return encode_base64($content);
  }
}

return 1;

=pod

=head1 NAME

Google::Ads::Common::ImageUtils

=head1 SYNOPSIS

 use Google::Ads::Common::ImageUtils;

 my $image_data;
 eval {
   $image_data = Google::Ads::Common::ImageUtils::get_image_data_from_url({
     url => 'https://sandbox.google.com/sandboximages/image.jpg'
   });
 };
 if ($@) {
   # $@ will contain a string explaining why the image data request failed.
 } else {
   # Make use of $image_data.
 }

=head1 DESCRIPTION


=head1 SUBROUTINES

=head2 get_image_data_from_url

Gets the image data (byte representation) from a given URL.

=head3 Parameters

The URL from which the data will be retrieved.

=head3 Returns

A byte array of the image data. Or no return if the image is not found.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Google Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 REPOSITORY INFORMATION

 $Rev: $
 $LastChangedBy: $
 $Id: $

=cut
