#!/usr/bin/perl -w
#
# Copyright 2020, Google LLC
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
# Creates a rule-based user list defined by a combination of rules for users who
# have visited two different pages of a website.

use strict;
use warnings;
use utf8;

use FindBin qw($Bin);
use lib "$Bin/../../lib";
use Google::Ads::GoogleAds::Client;
use Google::Ads::GoogleAds::Utils::GoogleAdsHelper;
use Google::Ads::GoogleAds::V20::Resources::UserList;
use Google::Ads::GoogleAds::V20::Common::UserListRuleItemInfo;
use Google::Ads::GoogleAds::V20::Common::UserListStringRuleItemInfo;
use Google::Ads::GoogleAds::V20::Common::UserListRuleInfo;
use Google::Ads::GoogleAds::V20::Common::UserListRuleItemGroupInfo;
use Google::Ads::GoogleAds::V20::Common::FlexibleRuleUserListInfo;
use Google::Ads::GoogleAds::V20::Common::FlexibleRuleOperandInfo;
use Google::Ads::GoogleAds::V20::Common::RuleBasedUserListInfo;
use Google::Ads::GoogleAds::V20::Enums::UserListFlexibleRuleOperatorEnum
  qw(AND);
use Google::Ads::GoogleAds::V20::Enums::UserListStringRuleItemOperatorEnum
  qw(EQUALS);
use Google::Ads::GoogleAds::V20::Enums::UserListPrepopulationStatusEnum
  qw(REQUESTED);
use Google::Ads::GoogleAds::V20::Enums::UserListMembershipStatusEnum qw(OPEN);
use Google::Ads::GoogleAds::V20::Services::UserListService::UserListOperation;

use Getopt::Long qw(:config auto_help);
use Pod::Usage;
use Cwd          qw(abs_path);
use Data::Uniqid qw(uniqid);

use constant URL_STRING => "url__";

# [START add_combined_rule_user_list]
sub add_combined_rule_user_list {
  my ($api_client, $customer_id) = @_;

  # Create a UserListRuleInfo object containing the first rule.
  my $user_visited_site1_rule_info =
    create_user_list_rule_info_from_url("http://example.com/example1");

  # Create a UserListRuleInfo object containing the second rule.
  my $user_visited_site2_rule_info =
    create_user_list_rule_info_from_url("http://example.com/example2");

  # Create a UserListRuleInfo object containing the third rule.
  my $user_visited_site3_rule_info =
    create_user_list_rule_info_from_url("http://example.com/example3");

  # Create the user list "Visitors of page 1 AND page 2, but not page 3".
  # To create the user list "Visitors of page 1 *OR* page 2, but not page 3",
  # change the UserListFlexibleRuleOperator from AND to OR.
  my $flexible_rule_user_list_info =
    Google::Ads::GoogleAds::V20::Common::FlexibleRuleUserListInfo->new({
      inclusiveRuleOperator => AND,
      # Inclusive operands are joined together with the specified inclusiveRuleOperator.
      # This represents the set of users that should be included in the user list.
      inclusiveOperands => [
        Google::Ads::GoogleAds::V20::Common::FlexibleRuleOperandInfo->new({
            rule => $user_visited_site1_rule_info,
            # Optionally add a lookback window for this rule, in days.
            lookbackWindowDays => 7
          }
        ),
        Google::Ads::GoogleAds::V20::Common::FlexibleRuleOperandInfo->new({
            rule => $user_visited_site2_rule_info,
            # Optionally add a lookback window for this rule, in days.
            lookbackWindowDays => 7
          })
      ],
      # Exclusive operands are joined together with OR.
      # This represents the set of users to be excluded from the user list.
      exclusiveOperands => [
        Google::Ads::GoogleAds::V20::Common::FlexibleRuleOperandInfo->new({
            rule => $user_visited_site3_rule_info
          })
      ],
    });

  # Define a representation of a user list that is generated by a rule.
  my $rule_based_user_list_info =
    Google::Ads::GoogleAds::V20::Common::RuleBasedUserListInfo->new({
      # Optional: To include past users in the user list, set the prepopulationStatus
      # to REQUESTED.
      prepopulationStatus  => REQUESTED,
      flexibleRuleUserList => $flexible_rule_user_list_info
    });

  # Create a user list.
  my $user_list = Google::Ads::GoogleAds::V20::Resources::UserList->new({
    name        => "Flexible rule user list for example.com #" . uniqid(),
    description => "Visitors of both http://example.com/example1 AND " .
      "http://example.com/example2 but NOT http://example.com/example3",
    membershipStatus  => OPEN,
    ruleBasedUserList => $rule_based_user_list_info
  });

  # Create the operation.
  my $user_list_operation =
    Google::Ads::GoogleAds::V20::Services::UserListService::UserListOperation->
    new({
      create => $user_list
    });

  # Issue a mutate request to add the user list and print some information.
  my $user_lists_response = $api_client->UserListService()->mutate({
      customerId => $customer_id,
      operations => [$user_list_operation]});
  printf "Created user list with resource name '%s'.\n",
    $user_lists_response->{results}[0]{resourceName};

  return 1;
}
# [END add_combined_rule_user_list]

# Create a UserListRuleInfo object containing a rule targeting any user
# that visited the provided URL.
sub create_user_list_rule_info_from_url {
  my ($url_string) = @_;

  # Create a rule targeting any user that visited a URL that equals
  # the given url_string.
  my $user_visited_site_rule =
    Google::Ads::GoogleAds::V20::Common::UserListRuleItemInfo->new({
      # Use a built-in parameter to create a domain URL rule.
      name           => URL_STRING,
      stringRuleItem =>
        Google::Ads::GoogleAds::V20::Common::UserListStringRuleItemInfo->new({
          operator => EQUALS,
          value    => $url_string
        })});

  # Return a UserListRuleInfo object containing the rule.
  return Google::Ads::GoogleAds::V20::Common::UserListRuleInfo->new({
      ruleItemGroups =>
        Google::Ads::GoogleAds::V20::Common::UserListRuleItemGroupInfo->new({
          ruleItems => [$user_visited_site_rule]})});

}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
  return 1;
}

# Get Google Ads Client, credentials will be read from ~/googleads.properties.
my $api_client = Google::Ads::GoogleAds::Client->new();

# By default examples are set to die on any server returned fault.
$api_client->set_die_on_faults(1);

my $customer_id = undef;

# Parameters passed on the command line will override any parameters set in code.
GetOptions("customer_id=s" => \$customer_id);

# Print the help message if the parameters are not initialized in the code nor
# in the command line.
pod2usage(2) if not check_params($customer_id);

# Call the example.
add_combined_rule_user_list($api_client, $customer_id =~ s/-//gr);

=pod

=head1 NAME

add_combined_rule_user_list

=head1 DESCRIPTION

Creates a rule-based user list defined by a combination of rules for users who
have visited two different pages of a website.

=head1 SYNOPSIS

add_combined_rule_user_list.pl [options]

    -help                       Show the help message.
    -customer_id                The Google Ads customer ID.

=cut
