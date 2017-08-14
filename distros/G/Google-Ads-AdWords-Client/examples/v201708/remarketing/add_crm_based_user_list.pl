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
# This example adds a user list (a.k.a. audience) and uploads members
# to populate the list.
#
# Note: It may take up to several hours for the list to be populated
# with members. Email addresses must be associated with a Google account.
# For privacy purposes, the user list size will show as zero until the list
# has at least 1000 members. After that, the size will be rounded to the
# two most significant digits.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201708::AddressInfo;
use Google::Ads::AdWords::v201708::CrmBasedUserList;
use Google::Ads::AdWords::v201708::Member;
use Google::Ads::AdWords::v201708::MutateMembersOperand;
use Google::Ads::AdWords::v201708::MutateMembersOperation;
use Google::Ads::AdWords::v201708::UserListOperation;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);
use Digest::SHA qw(sha256_hex);

sub add_crm_based_user_list {
  my $client = shift;

  # Create a user list.
  my $user_list = Google::Ads::AdWords::v201708::CrmBasedUserList->new({
    name        => "Customer relationship management list #" . uniqid(),
    description => "A list of customers that originated from email addresses",
    # See limit here:
    # https://support.google.com/adwords/answer/6276125#requirements.
    membershipLifeSpan => "30"
  });

  # Create operation.
  my $operation = Google::Ads::AdWords::v201708::UserListOperation->new({
    operator => "ADD",
    operand  => $user_list
  });

  # Add user list.
  my $result =
    $client->AdwordsUserListService()->mutate({operations => [$operation]});

  # Display user list.
  if ($result->get_value()) {
    my $user_list_added = $result->get_value()->[0];
    printf(
      "User list with name '%s' and ID '%d' was added.\n",
      $user_list_added->get_name(),
      $user_list_added->get_id());
  }

  my @members = ();
  # Add e-mails to the user list.
  if ($result->get_value()) {
    # Use SHA256 to encode the e-mails.
    # All e-mails MUST be trimmed and lower-cased before encoding.
    my @email_list = (
      'customer1@example.com', 'customer2@example.com',
      ' Customer3@example.com '
    );
    foreach my $email (@email_list) {
      $email = sha256_hex(_to_normalized_string($email));
      my $member = Google::Ads::AdWords::v201708::Member->new({
        hashedEmail => $email
      });
      push @members, $member;
    }

    # Adding address info is currently available on a whitelist-only basis.
    # This code demonstrates how to do it, and you can uncomment it if you are
    # on the whitelist.
    # my $first_name   = "John";
    # my $last_name    = "Doe";
    # my $country_code = "US";
    # my $zip_code     = "10011";
    #
    # my $address_info = Google::Ads::AdWords::v201708::AddressInfo->new({
    #   # First and last name must be normalized and hashed.
    #   hashedFirstName => sha256_hex(_to_normalized_string($first_name)),
    #   hashedLastName  => sha256_hex(_to_normalized_string($last_name)),
    #   # Country code and zip code are sent in plaintext.
    #   countryCode => $country_code,
    #   zipCode     => $zip_code
    # });
    #
    # my $member_by_address = Google::Ads::AdWords::v201708::Member->new({
    #   addressInfo => $address_info
    # });
    # push @members, $member_by_address;

    my $userlist_id = $result->get_value()->[0]->get_id();
    my $operand     = Google::Ads::AdWords::v201708::MutateMembersOperand->new({
      userListId => $userlist_id,
      membersList => \@members
    });

    my $member_operation =
      Google::Ads::AdWords::v201708::MutateMembersOperation->new({
        operator => "ADD",
        operand  => $operand
      });

    # Add members to the user list based on email addresses.
    my $result =
      $client->AdwordsUserListService()
      ->mutateMembers({operations => [$member_operation]});

    # Display results.
    # Reminder: it may take up to 9 hours for the list to be populated
    # with members.
    for $user_list ($result->get_userLists()) {
      printf(
        "%d email addresses were uploaded to user list with name '%s' " .
          "and ID '%d' and are scheduled for review.\n",
        scalar(@email_list), $user_list->get_name(),
        $user_list->get_id());
    }

  } else {
    print "No user list was added.";
  }

  return 1;
}

sub _to_normalized_string {
  my ($input_string) = @_;
  $input_string =~ s/^\s+|\s+$//g;
  $input_string = lc $input_string;
  return $input_string;
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
add_crm_based_user_list($client);
