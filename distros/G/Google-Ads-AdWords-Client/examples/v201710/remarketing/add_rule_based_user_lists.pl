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
# This example adds two rule-based remarketing user lists: one with no site
# visit date restrictions, and another that will only include users who visit
# your site in the next six months.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201710::BasicUserList;
use Google::Ads::AdWords::v201710::CombinedRuleUserList;
use Google::Ads::AdWords::v201710::DateKey;
use Google::Ads::AdWords::v201710::DateRuleItem;
use Google::Ads::AdWords::v201710::DateSpecificRuleUserList;
use Google::Ads::AdWords::v201710::ExpressionRuleUserList;
use Google::Ads::AdWords::v201710::NumberKey;
use Google::Ads::AdWords::v201710::NumberRuleItem;
use Google::Ads::AdWords::v201710::Operator;
use Google::Ads::AdWords::v201710::Rule;
use Google::Ads::AdWords::v201710::RuleItem;
use Google::Ads::AdWords::v201710::RuleItemGroup;
use Google::Ads::AdWords::v201710::StringKey;
use Google::Ads::AdWords::v201710::StringRuleItem;
use Google::Ads::AdWords::v201710::UserListOperation;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Example main subroutine.
sub add_rule_based_user_lists {
  my $client = shift;

  # First rule item group - users who visited the checkout page and had more
  # than one item in their shopping cart.
  my $checkout_string_rule_item =
    Google::Ads::AdWords::v201710::StringRuleItem->new({
      key => Google::Ads::AdWords::v201710::StringKey->new(
        {name => "ecomm_pagetype"}
      ),
      op    => "EQUALS",
      value => "checkout"
    });
  my $checkout_rule_item = Google::Ads::AdWords::v201710::RuleItem->new(
    {StringRuleItem => $checkout_string_rule_item});

  my $cart_size_number_rule_item =
    Google::Ads::AdWords::v201710::NumberRuleItem->new({
      key =>
        Google::Ads::AdWords::v201710::NumberKey->new({name => "cartsize"}),
      op    => "GREATER_THAN",
      value => "1"
    });
  my $cart_size_rule_item = Google::Ads::AdWords::v201710::RuleItem->new(
    {NumberRuleItem => $cart_size_number_rule_item});

  # Combine the two rule items into a RuleItemGroup so AdWords will AND their
  # rules together.
  my $checkout_multiple_item_group =
    Google::Ads::AdWords::v201710::RuleItemGroup->new(
    {items => [$checkout_rule_item, $cart_size_rule_item]});

  # Second rule item group - users who check out during the next three months.
  my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
  my $rule_start_date =
    sprintf("%d%02d%02d", ($year + 1900), ($mon + 1), $mday);
  ($sec, $min, $hour, $mday, $mon, $year) =
    localtime(time + 60 * 60 * 24 * 30 * 3);
  my $rule_end_date = sprintf("%d%02d%02d", ($year + 1900), ($mon + 1), $mday);

  my $start_date_date_rule_item =
    Google::Ads::AdWords::v201710::DateRuleItem->new({
      key =>
        Google::Ads::AdWords::v201710::DateKey->new({name => "checkoutdate"}),
      op    => "AFTER",
      value => $rule_start_date
    });

  my $start_date_rule_item = Google::Ads::AdWords::v201710::RuleItem->new(
    {DateRuleItem => $start_date_date_rule_item});

  my $end_date_date_rule_item =
    Google::Ads::AdWords::v201710::DateRuleItem->new({
      key =>
        Google::Ads::AdWords::v201710::DateKey->new({name => "checkoutdate"}),
      op    => "BEFORE",
      value => $rule_end_date
    });

  my $end_date_rule_item = Google::Ads::AdWords::v201710::RuleItem->new(
    {DateRuleItem => $end_date_date_rule_item});

  # Combine the date rule items into a RuleItemGroup.
  my $checked_out_next_three_months_item_group =
    Google::Ads::AdWords::v201710::RuleItemGroup->new(
    {items => [$start_date_rule_item, $end_date_rule_item]});

  # Combine the rule item groups into a Rule so AdWords knows how to apply the
  # rules.
  my $rule = Google::Ads::AdWords::v201710::Rule->new({
      groups => [
        $checkout_multiple_item_group, $checked_out_next_three_months_item_group
      ],
      # ExpressionRuleUserLists can use either CNF or DNF for matching. CNF
      # means 'at least one item in each rule item group must match', and DNF
      # means 'at least one entire rule item group must match'.
      # DateSpecificRuleUserList only supports DNF. You can also omit the rule
      # type altogether to default to DNF.
      ruleType => 'DNF'
    });

  # Third and fourth rule item groups
  # Visitors of a page who visited another page.
  my $site1_string_rule_item =
    Google::Ads::AdWords::v201710::StringRuleItem->new({
      key => Google::Ads::AdWords::v201710::StringKey->new(
        {name => "url__"}
      ),
      op    => "EQUALS",
      value => "example.com/example1"
    });
  my $site1_rule_item = Google::Ads::AdWords::v201710::RuleItem->new(
    {StringRuleItem => $site1_string_rule_item});
  my $site2_string_rule_item =
    Google::Ads::AdWords::v201710::StringRuleItem->new({
      key => Google::Ads::AdWords::v201710::StringKey->new(
        {name => "url__"}
      ),
      op    => "EQUALS",
      value => "example.com/example2"
    });
  my $site2_rule_item = Google::Ads::AdWords::v201710::RuleItem->new(
    {StringRuleItem => $site2_string_rule_item});

  # Create two RuleItemGroups to show that a visitor browsed two sites.
  my $site1_item_group = Google::Ads::AdWords::v201710::RuleItemGroup->new(
    {items => [$site1_rule_item]});
  my $site2_item_group = Google::Ads::AdWords::v201710::RuleItemGroup->new(
    {items => [$site2_rule_item]});

  # Create two rules to show that a visitor browsed two sites.
  my $user_visited_site1_rule = Google::Ads::AdWords::v201710::Rule->new({
      groups => [$site1_item_group]
    });
  my $user_visited_site2_rule = Google::Ads::AdWords::v201710::Rule->new({
      groups => [$site2_item_group]
    });

  # Create the user list with no restrictions on site visit date.
  ($sec, $min, $hour, $mday, $mon, $year) = localtime();
  my $creation_time = sprintf(
    "%d%02d%02d_%02d%02d%02d",
    ($year + 1900),
    ($mon + 1),
    $mday, $hour, $min, $sec
  );
  my $expression_user_list =
    Google::Ads::AdWords::v201710::ExpressionRuleUserList->new({
      name        => "Expression based user list created at ${creation_time}",
      description => "Users who checked out in six month window OR " .
        "visited the checkout page with more than one item in their cart",
      rule => $rule,
      # Optional: Set the prepopulationStatus to REQUESTED to include past
      # users in the user list.
      prepopulationStatus => "REQUESTED"
    });

  # Create the user list restricted to users who visit your site within the
  # next six months.
  ($sec, $min, $hour, $mday, $mon, $year) = localtime();
  my $list_start_date =
    sprintf("%d%02d%02d", ($year + 1900), ($mon + 1), $mday);
  ($sec, $min, $hour, $mday, $mon, $year) =
    localtime(time + 60 * 60 * 24 * 30 * 6);
  my $list_end_date = sprintf("%d%02d%02d", ($year + 1900), ($mon + 1), $mday);

  my $date_user_list =
    Google::Ads::AdWords::v201710::DateSpecificRuleUserList->new({
      name        => "Date rule user list created at ${creation_time}",
      description => "Users who visited the site between " .
        "${list_start_date} and ${list_end_date} and checked out " .
        "in three month window OR visited the checkout page with " .
        "more than one item in their cart.",
      rule      => $rule,
      startDate => $list_start_date,
      endDate   => $list_end_date
    });

  # Create the user list where "Visitors of a page who did visit another page".
  # To create a user list where "Visitors of a page who did not visit another
  # page", change the ruleOperator from AND to AND_NOT.
  my $combined_user_list =
    Google::Ads::AdWords::v201710::CombinedRuleUserList->new({
      name         => "Combined rule user list created at ${creation_time}",
      description  => "Users who visited two sites.",
      leftOperand  => $user_visited_site1_rule,
      rightOperand => $user_visited_site2_rule,
      ruleOperator => "AND"
    });

  # Create operations to add the user lists.
  my $operations = [
    Google::Ads::AdWords::v201710::UserListOperation->new({
        operator => "ADD",
        operand  => $expression_user_list
      }
    ),
    Google::Ads::AdWords::v201710::UserListOperation->new({
        operator => "ADD",
        operand  => $date_user_list
      }
    ),
    Google::Ads::AdWords::v201710::UserListOperation->new({
        operator => "ADD",
        operand  => $combined_user_list
      })];

  # Submit the operations.
  my $result =
    $client->AdwordsUserListService()->mutate({operations => $operations});

  if ($result->get_value()) {
    foreach my $user_list (@{$result->get_value}) {
      printf "User list added with ID %d, name '%s', status '%s', list " .
        "type '%s', accountUserListStatus '%s', description '%s'.\n",
        $user_list->get_id(),     $user_list->get_name(),
        $user_list->get_status(), $user_list->get_listType(),
        $user_list->get_accountUserListStatus(),
        $user_list->get_description();
    }
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
my $client = Google::Ads::AdWords::Client->new({version => "v201710"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_rule_based_user_lists($client);
