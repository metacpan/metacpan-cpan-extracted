#!/usr/bin/perl -w
#
# Copyright 2014, Google Inc. All Rights Reserved.
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
# This example adds a feed that syncs feed items from a Google
# Places account and associates the feed with a customer.
#
# Tags: CustomerFeedService.mutate, FeedService.mutate
# Author: Josh Radcliff <api.jradcliff@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201402::ConstantOperand;
use Google::Ads::AdWords::v201402::CustomerFeed;
use Google::Ads::AdWords::v201402::CustomerFeedOperation;
use Google::Ads::AdWords::v201402::Feed;
use Google::Ads::AdWords::v201402::FeedOperation;
use Google::Ads::AdWords::v201402::Function;
use Google::Ads::AdWords::v201402::PlacesLocationFeedData;
use Google::Ads::AdWords::v201402::OAuthInfo;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# See the Placeholder reference page for a list of all the placeholder types and
# fields.
# https://developers.google.com/adwords/api/docs/appendix/placeholders
use constant PLACEHOLDER_LOCATION => 7;

# The maximum number of CustomerFeed ADD operation attempts to make before
# throwing an exception.
use constant MAX_CUSTOMER_FEED_ADD_ATTEMPTS => 10;

# Replace with valid values of your account.
my $places_email_address = 'INSERT_PLACES_EMAIL_ADDRESS_HERE';

# To obtain an access token for your Places account, run the
# generate_offline_credentials example with the scope changed to
# "https://www.google.com/local/add" and capture the Credential's access token.
my $places_access_token = 'INSERT_PLACES_ACCESS_TOKEN_HERE';

# Example main subroutine.
sub add_places_location_extensions {
  my ($client, $places_email_address, $places_access_token) = @_;

  # Create a feed that will sync to the Google Places account specified
  # by places_email_address. Do not add FeedAttributes to this object,
  # as AdWords will add them automatically because this will be a
  # system generated feed.
  my $places_feed = Google::Ads::AdWords::v201402::Feed->new({
    name => "Places feed " . uniqid(),
    # Since this feed's feed items will be managed by AdWords,
    # you must set its origin to ADWORDS.
    origin => "ADWORDS"
  });

  my $oauth_info = Google::Ads::AdWords::v201402::OAuthInfo->new({
    httpMethod => "GET",
    httpRequestUrl => "https://www.google.com/local/add",
    httpAuthorizationHeader => "Bearer ${places_access_token}"
  });
  my $feed_data = Google::Ads::AdWords::v201402::PlacesLocationFeedData->new({
    emailAddress => $places_email_address,
    oAuthInfo => $oauth_info
  });

  $places_feed->set_systemFeedGenerationData($feed_data);

  # Create an operation to add the feed.
  my $feed_operation = Google::Ads::AdWords::v201402::FeedOperation->new({
    operand => $places_feed,
    operator => "ADD"
  });

  # Add the feed. Since it is a system generated feed, AdWords will
  # automatically:
  # 1. Set up the FeedAttributes on the feed.
  # 2. Set up a FeedMapping that associates the FeedAttributes of the feed
  # with the placeholder fields of the LOCATION placeholder type.
  my $feed_result = $client->FeedService()->mutate({
    operations => [
      Google::Ads::AdWords::v201402::FeedOperation->new({
        operator => "ADD",
        operand => $places_feed
      })
    ]
  });

  my $added_feed = $feed_result->get_value(0);

  printf "Added places feed with ID %d\n", $added_feed->get_id();

  # Add a CustomerFeed that associates the feed with this customer for
  # the LOCATION placeholder type.
  my $customer_feed = Google::Ads::AdWords::v201402::CustomerFeed->new({
    feedId => $added_feed->get_id(),
    placeholderTypes => [ PLACEHOLDER_LOCATION ]
  });

  # Create a matching function that will always evaluate to true.
  my $customer_matching_function =
    Google::Ads::AdWords::v201402::Function->new({
      lhsOperand => [ Google::Ads::AdWords::v201402::ConstantOperand->new({
          type => "BOOLEAN",
          booleanValue => 1
        })
      ],
      operator => "IDENTITY"
  });

  $customer_feed->set_matchingFunction($customer_matching_function);

  # Create an operation to add the customer feed.
  my $customer_feed_operation =
    Google::Ads::AdWords::v201402::CustomerFeedOperation->new({
      operand => $customer_feed,
      operator => "ADD"
  });

  # After the completion of the Feed ADD operation above the added feed will not
  # be available for usage in a CustomerFeed until the sync between the AdWords
  # and Places accounts completes.  The loop below will retry adding the
  # CustomerFeed up to ten times with an exponential back-off policy.
  my $added_customer_feed = undef;
  my $number_of_attempts = 0;
  # Disable die on faults for this section because we want to retry failed
  # attempts to add the customer feed.
  $client->set_die_on_faults(0);
  do {
    $number_of_attempts++;
    my $customer_feed_result = $client->CustomerFeedService()->mutate({
      operations => [ $customer_feed_operation ]
    });

    if ($customer_feed_result->isa("SOAP::WSDL::SOAP::Typelib::Fault11")) {
      # Wait using exponential backoff policy
      my $sleep_seconds = 5 * (2 ** $number_of_attempts);
      printf "Attempt #%d to add the CustomerFeed was not successful. " .
        "Waiting %d seconds before trying again.\n", $number_of_attempts,
        $sleep_seconds;
      sleep $sleep_seconds;
    } else {
      $added_customer_feed = $customer_feed_result->get_value(0);
      printf "Attempt #%d to add the CustomerFeed was successful.\n",
        $number_of_attempts;
    }
  } while ($number_of_attempts < MAX_CUSTOMER_FEED_ADD_ATTEMPTS and
    !$added_customer_feed);

  # Restore the previous setting of die on faults now that we are done retrying
  # requests.
  $client->set_die_on_faults(1);

  if (!$added_customer_feed) {
    die "Could not create the CustomerFeed after " .
      MAX_CUSTOMER_FEED_ADD_ATTEMPTS . " attempts. Please retry " .
      "the CustomerFeed ADD operation later.";
  }

  printf "Added CustomerFeed for feed ID %d and placeholder type %d\n",
        $added_customer_feed->get_feedId(),
        PLACEHOLDER_LOCATION;

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
add_places_location_extensions($client, $places_email_address,
  $places_access_token);
