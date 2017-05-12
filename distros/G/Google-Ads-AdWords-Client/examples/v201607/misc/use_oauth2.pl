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
# This example demonstrates how to authenticate using OAuth.  This example
# is meant to be run from the command line and requires user input.

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201607::OrderBy;
use Google::Ads::AdWords::v201607::Predicate;
use Google::Ads::AdWords::v201607::Selector;

use Cwd qw(abs_path);

# Replace with valid values, see
# https://developers.google.com/accounts/docs/OAuth2WebServer for more
# information.
my $client_id     = "ENTER_YOUR_CLIENT_ID_HERE";
my $client_secret = "ENTER_YOUR_CLIENT_SECRET_HERE";

# Example main subroutine.
sub use_oauth2 {
  my ($client, $oauth2_client_id, $oauth2_client_secret) = @_;

  my $auth_handler = $client->get_oauth_2_handler();

  $auth_handler->set_client_id($oauth2_client_id);
  $auth_handler->set_client_secret($oauth2_client_secret);

  # Open a browser and point it to the authorization URL, authorize the access
  # and then enter the generated verification code.
  print "Log in to your AdWords account and open the following URL: ",
    $auth_handler->get_authorization_url(), "\n";
  print "Grant access to the applications and enter the authorization code " .
    "display in the page then hit ENTER.\n";
  my $code = <STDIN>;
  # Trimming the value.
  $code =~ s/^\s*(.*)\s*$/$1/;

  # Requesting the access token using the authorization code, so it can be used
  # to access the API.
  if (my $error = $auth_handler->issue_access_token($code)) {
    die($error);
  }

  # After the access token is generated, you should store the
  # access and refresh token and re-use them for future calls, by either
  # changing your adwords.properties file or setting them in the authorization
  # handler as follows:
  # $client->get_oauth_2_handler()->set_access_token($access_token);
  # $client->get_oauth_2_handler()->set_refresh_token($refresh_token);
  print "OAuth2 Access Token: ", $auth_handler->get_access_token(), "\n",
    "OAuth2 Refresh Token: ", $auth_handler->get_refresh_token(), "\n\n";

  # Create selector.
  my $selector = Google::Ads::AdWords::v201607::Selector->new({
      fields   => ["Id", "Name"],
      ordering => [
        Google::Ads::AdWords::v201607::OrderBy->new({
            field     => "Name",
            sortOrder => "ASCENDING"
          })]});

  # Get all campaigns.
  my $page = $client->CampaignService()->get({serviceSelector => $selector});

  # Display campaigns.
  if ($page->get_entries()) {
    foreach my $campaign (@{$page->get_entries()}) {
      print "Campaign with name '", $campaign->get_name(), "' and id '",
        $campaign->get_id(), "' was found.\n";
    }
  } else {
    print "No campaigns were found.\n";
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
my $client = Google::Ads::AdWords::Client->new({version => "v201607"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
use_oauth2($client, $client_id, $client_secret);
