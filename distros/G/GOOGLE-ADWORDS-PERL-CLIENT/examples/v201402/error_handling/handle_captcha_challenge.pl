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
# This example illustrates how to handle 'captcha required' authorization
# errors. Refer to the best practices guide on how to avoid this error:
#
# https://developers.google.com/adwords/api/docs/guides/bestpractices#auth_tokens
#
# Author: David Torres <david.t@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::Common::AuthError;
use Google::Ads::AdWords::AuthTokenHandler;
use Google::Ads::Common::CaptchaRequiredError;

use Cwd qw(abs_path);

use constant RETRIES => 500;

# Example main subroutine.
sub handle_captcha_challenge {
  my $client = shift;

  my $retry = RETRIES;
  # Brute forcing the generation of a captcha challenge.
  my $handler = $client->get_auth_token_handler();
  my $error;
  while ($retry--) {
    $error = $handler->issue_new_token();
    if ($error) {
      last;
    }
  }

  if (!$error) {
    print "Failed to trigger a captcha challenge.\n";
    return;
  }

  if ($error->isa("Google::Ads::Common::CaptchaRequiredError")) {
    my $captcha_error = $error;

    # Captured a captcha required error.
    print "A captcha challenge error has ocurred. To recover open the " .
          "following URL in a browser:\n" .
          $captcha_error->get_image();
    print "\nEnter the captcha code and press ENTER to retry: ";
    my $code = <STDIN>;

    $error = $handler->issue_new_token($captcha_error->get_token(), $code);

    if (!$error) {
      print "Successfully retrieved token: " . $handler->get_auth_token() .
            "\n";
    };
    if ($error) {
      print "Invalid captcha code given.\nError: " . $error. "\n";
    }
  } else {
    # Captured a different authentication error.
    print "A different authentication error has occurred, please check your " .
          "client credentials.\nError:\n";
    print $error;
  }

  return 1;
}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
  return 1;
}

# Get AdWords Client, credentials will be read from ~/adwords.properties.
my $client = Google::Ads::AdWords::Client->new({version => "v201402"});

# Call the example
handle_captcha_challenge($client);
