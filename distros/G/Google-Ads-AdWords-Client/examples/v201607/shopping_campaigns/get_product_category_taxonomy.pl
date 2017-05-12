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
# This example fetches the set of valid ProductBiddingCategories.

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201607::Selector;
use Google::Ads::AdWords::v201607::Predicate;

use Cwd qw(abs_path);

# Example main subroutine.
sub get_product_category_taxonomy {
  my $client = shift;

  # Create selector.
  my $selector = Google::Ads::AdWords::v201607::Selector->new({
      fields     => ["DimensionValue", "ParentDimensionValue", "DisplayValue"],
      predicates => [
        Google::Ads::AdWords::v201607::Predicate->new({
            field    => "Country",
            operator => "IN",
            values   => ["US"]})]});

  my $results =
    $client->ConstantDataService()
    ->getProductBiddingCategoryData({selector => $selector});

  if ($results) {
    # %bidding_categories is a hash where key=dimension ID
    # and value=a hash of properties
    my %bidding_categories = ();
    my @root_categories    = ();
    foreach my $product_bidding_category_data (@{$results}) {
      my $id =
        $product_bidding_category_data->get_dimensionValue()->get_value();
      my $parent_id;
      my $name =
        $product_bidding_category_data->get_displayValue()->[0]->get_value();
      if ($product_bidding_category_data->get_parentDimensionValue()) {
        $parent_id =
          $product_bidding_category_data->get_parentDimensionValue()
          ->get_value();
      }

      if (!(exists $bidding_categories{$id})) {
        $bidding_categories{$id} = {};
      }

      my $category = $bidding_categories{$id};

      if ($parent_id) {
        if (!(exists $bidding_categories{$parent_id})) {
          $bidding_categories{$parent_id} = {};
        }
        my $parent = $bidding_categories{$parent_id};

        if (!(exists $parent->{"children"})) {
          $parent->{"children"} = [];
        }
        my $children = $parent->{"children"};
        push $children, $category;
      } else {
        push @root_categories, $category;
      }

      $category->{"id"}   = $id;
      $category->{"name"} = $name;
    }
    display_categories(\@root_categories, "");
  } else {
    print "No product bidding category data items were found.\n";
  }

  return 1;
}

sub display_categories {
  my $categories = shift;
  my $prefix     = shift;
  foreach my $category (@{$categories}) {
    printf "%s%s [%s]\n", $prefix, $category->{"name"}, $category->{"id"};
    if (exists $category->{"children"}) {
      my $category_name = $category->{"name"};
      my $children      = $category->{"children"};
      display_categories($children, "${prefix}${category_name} > ");
    }
  }
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
get_product_category_taxonomy($client);
