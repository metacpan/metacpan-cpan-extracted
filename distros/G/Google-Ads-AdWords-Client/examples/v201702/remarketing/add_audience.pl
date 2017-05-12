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
# This example adds a remarketing user list (a.k.a. Audience) and shows its
# associated conversion tracker code snippet.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201702::Predicate;
use Google::Ads::AdWords::v201702::BasicUserList;
use Google::Ads::AdWords::v201702::Selector;
use Google::Ads::AdWords::v201702::UserListConversionType;
use Google::Ads::AdWords::v201702::UserListOperation;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Example main subroutine.
sub add_audience {
  my $client = shift;

  # Create conversion type (tag).
  my $name = "Mars cruise customers #" . uniqid();

  my $conversion_type =
    Google::Ads::AdWords::v201702::UserListConversionType->new({name => $name});

  # Create remarketing user list.
  my $user_list = Google::Ads::AdWords::v201702::BasicUserList->new({
      name            => $name,
      conversionTypes => [$conversion_type],
      # Additional properties (non-required).
      description        => "A list of mars cruise customers in the last year",
      membershipLifeSpan => 365,
      status             => "OPEN"
  });

  # Create operation.
  my $operation = Google::Ads::AdWords::v201702::UserListOperation->new({
      operator => "ADD",
      operand  => $user_list
  });

  # Add user list.
  my $result =
    $client->AdwordsUserListService()->mutate({operations => [$operation]});

  if ($result->get_value()) {
    my $user_list = $result->get_value()->[0];

    # Due to a bug in the service we need to retrieve the conversion trackers
    # info in a separate request after a few seconds.
    sleep(5);
    my $predicate = Google::Ads::AdWords::v201702::Predicate->new({
        field    => "Id",
        operator => "IN",
        values   => [$user_list->get_id()->get_value()]});
    my $selector = Google::Ads::AdWords::v201702::Selector->new({
        fields     => ["ConversionTypes"],
        predicates => [$predicate]});
    my $conversion_trackers_page =
      $client->AdwordsUserListService()->get({serviceSelector => $selector});

    # Get associated conversion snippets.
    my $conversion_id =
      $conversion_trackers_page->get_entries()->[0]->get_conversionTypes()->[0]
      ->get_id()->get_value();

    # Create selector.
    my $conversion_type_predicate =
      Google::Ads::AdWords::v201702::Predicate->new({
        field    => "Id",
        operator => "IN",
        values   => [$conversion_id]});
    $selector = Google::Ads::AdWords::v201702::Selector->new({
        fields     => ["Id"],
        predicates => [$conversion_type_predicate]});

    # Get all conversion trackers.
    my $page =
      $client->ConversionTrackerService()->get({serviceSelector => $selector});

    my $conversion_tracker = $page->get_entries()->[0];

    # Display results.
    printf "User list with name \"%s\" and id \"%d\" was added.\n",
      $user_list->get_name(), $user_list->get_id();
    printf "Conversion type code snippet associated to the list:\n%s\n",
      $conversion_tracker->get_snippet();
  } else {
    print "No user list was added.";
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
my $client = Google::Ads::AdWords::Client->new({version => "v201702"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_audience($client);
