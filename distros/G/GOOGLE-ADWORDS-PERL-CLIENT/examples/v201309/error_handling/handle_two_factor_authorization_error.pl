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
# This code example illustrates how to handle 2 factor authorization errors.
#
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;

use Cwd qw(abs_path);

# Example main subroutine.
sub handle_two_factor_authorization_error {
  my $client = shift;

  my $auth_handler = $client->get_auth_token_handler();
  my $login_email = "2steptester\@gmail.com";
  my $password = "testaccount";
  $auth_handler->set_email($login_email);
  $auth_handler->set_password($password);

  my $error = $auth_handler->refresh_auth_token();

  if ($error) {
    if ($error->get_content() =~ m/InvalidSecondFactor/) {
      print "The user has enabled two factor authentication in this " .
            "account. Have the user generate an application-specific " .
            "password to make calls against the AdWords API. See " .
            "http://adwordsapi.blogspot.com/2011/02/authentication-changes" .
            "-with-2-step.html for more details.\n";
    } else {
      print "Invalid credentials.\n";
    }
  } else {
    printf "Retrieved an authToken = %s for user %s.\n",
           $auth_handler->get_auth_token(), $login_email;
  }

  return 1;
}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
  return 1;
}

# Get AdWords Client, credentials will be read from ~/adwords.properties.
my $client = Google::Ads::AdWords::Client->new({version => "v201309"});

# Call the example
handle_two_factor_authorization_error($client);
