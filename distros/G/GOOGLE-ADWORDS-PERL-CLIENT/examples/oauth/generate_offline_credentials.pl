#!/usr/bin/perl -w
#
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
#
# This utility script demonstrate how to generate offline credentials for
# OAuth2 Installed Applications. The generated refresh token can then be used
# to configure the client library, refer to the OAuth2 section of the
# adwords.properties file. This example is meant to be run from the command line
# and requires user input.
#
# Author: David Torres <api.davidtorres@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;

use Cwd qw(abs_path);

# Main subroutine.
sub generate_offline_credentials {
  my ($client) = @_;

  my $auth_handler = $client->get_oauth_2_handler();

  print "Please enter your OAuth 2.0 Client ID and Client Secret.\n" .
        "These values can be generated from the Google Developers Console, " .
        "https://console.developers.google.com under the Projects tab.\n" .
        "Use a Client ID for Installed applications.\n" .
        "Enter Client ID: ";
  my $client_id = <STDIN>;
  $client_id = trim($client_id);

  print "Enter Client secret: ";
  my $client_secret = <STDIN>;
  $client_secret = trim($client_secret);

  $auth_handler->set_client_id($client_id);
  $auth_handler->set_client_secret($client_secret);

  # Open a browser and point it to the authorization URL, authorize the access
  # and then enter the generated verification code.
  print "Log in to your AdWords account and open the following URL:\n\n",
        $auth_handler->get_authorization_url(), "\n\n";
  print "Grant access to the applications and enter the authorization code " .
        "display in the page then hit ENTER.\nEnter confirmation code: ";
  my $code = <STDIN>;
  $code = trim($code);

  # Requesting the access token using the authorization code, so it can be used
  # to access the API.
  if (my $error = $auth_handler->issue_access_token($code)) {
    die($error);
  }

  # After the access token is generated, you should store the
  # access and refresh token and re-use them for future calls, by either
  # changing your adwords.properties file or setting them in the authorization
  # handler as follows:
  # $client->get_oauth_2_handler()->set_client_id($client_id);
  # $client->get_oauth_2_handler()->set_client_secret($client_secret);
  # $client->get_oauth_2_handler()->set_access_token($access_token);
  # $client->get_oauth_2_handler()->set_refresh_token($refresh_token);
  printf "\nThe following are the keys you can replace in your " .
         "adwords.properties configuration:\n\n" .
         "oAuth2ClientId=%1\$s\n" .
         "oAuth2ClientSecret=%2\$s\n" .
         "oAuth2AccessToken=%3\$s\n" .
         "oAuth2RefreshToken=%4\$s\n" .
         "\nOr use at runtime, like:\n\n" .
         "\$client->get_oauth_2_handler()->set_client_id('%1\$s');\n" .
         "\$client->get_oauth_2_handler()->set_client_secret('%2\$s');\n" .
         "\$client->get_oauth_2_handler()->set_access_token('%3\$s');\n" .
         "\$client->get_oauth_2_handler()->set_refresh_token('%4\$s');\n",
         $client_id, $client_secret, $auth_handler->get_access_token(),
         $auth_handler->get_refresh_token();

  return 1;
}

sub trim {
  my $str = shift;
  $str =~ s/^\s*(.*?)\s*$/$1/;
  return $str;
}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
  return 1;
}

# Get AdWords Client, credentials will be read from ~/adwords.properties.
my $client = Google::Ads::AdWords::Client->new();

# Call the example
generate_offline_credentials($client);
