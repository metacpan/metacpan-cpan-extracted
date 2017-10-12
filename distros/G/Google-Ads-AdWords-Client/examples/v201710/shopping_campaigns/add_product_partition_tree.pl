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
# This example creates a ProductPartition tree.

use strict;
use lib "../../../lib";
use utf8;

use Data::Uniqid qw(uniqid);

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201710::AdGroupCriterionOperation;
use Google::Ads::AdWords::v201710::BiddableAdGroupCriterion;
use Google::Ads::AdWords::v201710::BiddingStrategyConfiguration;
use Google::Ads::AdWords::v201710::CpcBid;
use Google::Ads::AdWords::v201710::Criterion;
use Google::Ads::AdWords::v201710::Money;
use Google::Ads::AdWords::v201710::NegativeAdGroupCriterion;
use Google::Ads::AdWords::v201710::ProductBiddingCategory;
use Google::Ads::AdWords::v201710::ProductCanonicalCondition;
use Google::Ads::AdWords::v201710::ProductBrand;
use Google::Ads::AdWords::v201710::ProductPartition;

use Cwd qw(abs_path);

# Replace with valid values of your account.
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";

# Example main subroutine.
sub add_product_partition_tree {
  my ($client, $ad_group_id) = @_;

  my $operations = [];

  # The next temporary criterion ID to be used.
  #
  # When creating our tree we need to specify the parent-child relationships
  # between nodes. However, until a criterion has been created on the server
  # we do not have a criterionId with which to refer to it.
  #
  # Instead we can specify temporary IDs that are specific to a single mutate
  # request. Once the criteria have been created they are assigned an ID as
  # normal and the temporary ID will no longer refer to it.
  #
  # A valid temporary ID is any negative integer.
  my $next_id = -1;

  # The most trivial partition tree has only a unit node as the root:
  #   create_unit($operations, $ad_group_id, null, null, 100000);
  my $root = create_subdivision($operations, $next_id--, $ad_group_id);

  create_unit(
    $operations,
    $ad_group_id,
    $root,
    Google::Ads::AdWords::v201710::ProductCanonicalCondition->new(
      {condition => "NEW"}
    ),
    200000
  );

  create_unit(
    $operations,
    $ad_group_id,
    $root,
    Google::Ads::AdWords::v201710::ProductCanonicalCondition->new(
      {condition => "USED"}
    ),
    100000
  );

  my $other_condition =
    create_subdivision($operations, $next_id--, $ad_group_id, $root,
    Google::Ads::AdWords::v201710::ProductCanonicalCondition->new());

  create_unit($operations, $ad_group_id, $other_condition,
    Google::Ads::AdWords::v201710::ProductBrand->new({value => "CoolBrand"}),
    900000);

  create_unit($operations, $ad_group_id, $other_condition,
    Google::Ads::AdWords::v201710::ProductBrand->new({value => "CheapBrand"}),
    10000);

  my $other_brand =
    create_subdivision($operations, $next_id--, $ad_group_id, $other_condition,
    Google::Ads::AdWords::v201710::ProductBrand->new());

  # The value for the bidding category is a fixed ID for the 'Luggage & Bags'
  # category. You can retrieve IDs for categories from the ConstantDataService.
  # See the 'get_product_category_taxonomy' example for more details.
  create_unit(
    $operations,
    $ad_group_id,
    $other_brand,
    Google::Ads::AdWords::v201710::ProductBiddingCategory->new({
        type  => "BIDDING_CATEGORY_L1",
        value => -5914235892932915235
      }
    ),
    750000
  );

  create_unit(
    $operations,
    $ad_group_id,
    $other_brand,
    Google::Ads::AdWords::v201710::ProductBiddingCategory->new(
      {type => "BIDDING_CATEGORY_L1",}
    ),
    110000
  );

  my $result =
    $client->AdGroupCriterionService()->mutate({operations => $operations});

  my $children = {};
  my $root_node;
  # For each criterion, make an array containing each of its children.
  # We always create the parent before the child, so we can rely on that here.
  foreach my $ad_group_criterion (@{$result->get_value()}) {
    $children->{$ad_group_criterion->get_criterion()->get_id()} = [];

    my $parent_criterion_id =
      $ad_group_criterion->get_criterion()->get_parentCriterionId();
    if ($parent_criterion_id) {
      push $children->{$parent_criterion_id},
        $ad_group_criterion->get_criterion();
    } else {
      $root_node = $ad_group_criterion->get_criterion();
    }
  }

  # Show the tree
  display_tree($root_node, $children);

  return 1;
}

# Return a new subdivision product partition and add to the provided list
# an operation to create the partition. The parent and value fields
# should not be specified for the root node.
# operations: The list of operations to add to.
# temp_id: The temporary ID to use for the new partition.
# ad_group_id: The ID of the ad group for the new partition.
# parent: (Optional) The parent partition for the new partition.
# value: (Optional) The case value (product dimension) for the new partition.
sub create_subdivision {
  my ($operations, $temp_id, $ad_group_id, $parent, $value) = @_;
  my $division = Google::Ads::AdWords::v201710::ProductPartition->new({
      partitionType => "SUBDIVISION",
      id            => $temp_id
  });

  # The root node has neither a parent nor a value.
  if ($parent) {
    $division->set_parentCriterionId($parent->get_id());
    $division->set_caseValue($value);
  }

  my $criterion = Google::Ads::AdWords::v201710::BiddableAdGroupCriterion->new({
      adGroupId => $ad_group_id,
      criterion => $division
  });

  push $operations, create_add_operation($criterion);

  return $division;
}

# Return a new unit product partition and add to the provided list
# an operation to create the partition. The parent, value and bid_amount
# fields should not be specified for the root node.
# operations: The list of operations to add to.
# ad_group_id: The ID of the ad group for the new partition.
# parent: (Optional) The parent partition for the new partition.
# value: (Optional) The case value (product dimension) for the new partition.
# bid_amount: (Optional) The bid amount for the AdGroupCriterion.  If specified
#   then the AdGroupCriterion will be a BiddableAdGroupCriterion.
sub create_unit {
  my ($operations, $ad_group_id, $parent, $value, $bid_amount) = @_;
  my $unit = Google::Ads::AdWords::v201710::ProductPartition->new(
    {partitionType => "UNIT",});

  # The root node has neither a parent nor a value.
  if ($parent) {
    $unit->set_parentCriterionId($parent->get_id());
    $unit->set_caseValue($value);
  }

  my $criterion;
  if ($bid_amount && $bid_amount > 0) {
    my $biddingStrategyConfiguration =
      Google::Ads::AdWords::v201710::BiddingStrategyConfiguration->new({
        bids => [
          Google::Ads::AdWords::v201710::CpcBid->new({
              bid => Google::Ads::AdWords::v201710::Money->new(
                {microAmount => $bid_amount})})]});

    $criterion =
      Google::Ads::AdWords::v201710::BiddableAdGroupCriterion->new({
        biddingStrategyConfiguration => $biddingStrategyConfiguration
      });
  } else {
    $criterion = Google::Ads::AdWords::v201710::NegativeAdGroupCriterion->new();
  }

  $criterion->set_adGroupId($ad_group_id);
  $criterion->set_criterion($unit);

  push $operations, create_add_operation($criterion);

  return $unit;
}

# Return a new ADD operation for the specified ad group criterion.
# ad_group_criterion: The ad group criterion for the new operation.
sub create_add_operation {
  my ($ad_group_criterion) = @_;
  my $operation = Google::Ads::AdWords::v201710::AdGroupCriterionOperation->new(
    {
      operand  => $ad_group_criterion,
      operator => "ADD"
    });

  return $operation;
}

# Recursively display a node and each of its children.
# node: The node (Criterion) to display.
# children: Reference to a hash of each criterion ID to the array of its
#   child criteria.
# level: (Optional) The depth of node in the criteria tree.
sub display_tree {
  my ($node, $children, $level) = @_;

  # Recursively display a node and each of its children.
  $level = 0 unless $level;
  my $value = '';
  my $type  = '';

  my $node_dimension = $node->get_caseValue();
  if ($node_dimension) {
    $type = $node_dimension->get_ProductDimension__Type();
    if ($type eq 'ProductCanonicalCondition') {
      $value = $node_dimension->get_condition();
    } elsif ($type eq 'ProductBiddingCategory') {
      $value =
        $node_dimension->get_type() . "(" .
        ($node_dimension->get_value() or '') . ")";
    } elsif ($type eq 'ProductBrand') {
      $value = $node_dimension->get_value();
    } else {
      $value = $node_dimension;
    }
    $value = '' unless $value;
  }

  printf "%sid: %s, type: %s, value: %s\n", "  " x $level,
    $node->get_id(), $type, $value;
  foreach my $child_node (@{$children->{$node->get_id()}}) {
    display_tree($child_node, $children, $level + 1);
  }
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
add_product_partition_tree($client, $ad_group_id);
