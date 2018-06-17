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
# This example restricts the products that will be included in the campaign by
# setting a ProductScope.

use strict;
use lib "../../../lib";
use utf8;

use Data::Uniqid qw(uniqid);

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201806::CampaignCriterion;
use Google::Ads::AdWords::v201806::CampaignCriterionOperation;
use Google::Ads::AdWords::v201806::ProductBiddingCategory;
use Google::Ads::AdWords::v201806::ProductBrand;
use Google::Ads::AdWords::v201806::ProductCanonicalCondition;
use Google::Ads::AdWords::v201806::ProductCustomAttribute;
use Google::Ads::AdWords::v201806::ProductOfferId;
use Google::Ads::AdWords::v201806::ProductScope;
use Google::Ads::AdWords::v201806::ProductType;

use Cwd qw(abs_path);

# Replace with valid values of your account.
my $campaign_id = "INSERT_CAMPAIGN_ID_HERE";

# Example main subroutine.
sub add_product_scope {
  my $client      = shift;
  my $campaign_id = shift;

  my $product_scope = Google::Ads::AdWords::v201806::ProductScope->new({
      # This set of dimensions is for demonstration purposes only. It would be
      # extremely unlikely that you want to include so many dimensions in your
      # product scope.
      dimensions => [
        Google::Ads::AdWords::v201806::ProductBrand->new({value => "Nexus"}),
        Google::Ads::AdWords::v201806::ProductCanonicalCondition->new(
          {condition => "NEW"}
        ),
        Google::Ads::AdWords::v201806::ProductCustomAttribute->new({
            type  => "CUSTOM_ATTRIBUTE_0",
            value => "my attribute value"
          }
        ),
        Google::Ads::AdWords::v201806::ProductOfferId->new({value => "book1"}),
        Google::Ads::AdWords::v201806::ProductType->new({
            type  => "PRODUCT_TYPE_L1",
            value => "Media"
          }
        ),
        Google::Ads::AdWords::v201806::ProductType->new({
            type  => "PRODUCT_TYPE_L2",
            value => "Books"
          }
        ),
        # The value for the bidding category is a fixed ID for the
        # 'Luggage & Bags' category. You can retrieve IDs for categories from the
        # ConstantDataService. See the 'get_product_category_taxonomy' example for
        # more details.
        Google::Ads::AdWords::v201806::ProductBiddingCategory->new({
            type  => "BIDDING_CATEGORY_L1",
            value => -5914235892932915235
          })]});

  my $campaign_criterion =
    Google::Ads::AdWords::v201806::CampaignCriterion->new({
      campaignId => $campaign_id,
      criterion  => $product_scope
    });

  # Create operation.
  my $operation =
    Google::Ads::AdWords::v201806::CampaignCriterionOperation->new({
      operand  => $campaign_criterion,
      operator => "ADD"
    });

  # Make the mutate request.
  my $result =
    $client->CampaignCriterionService()->mutate({operations => [$operation]});

  # Display result.
  $campaign_criterion = $result->get_value()->[0];

  printf("Created a ProductScope criterion with ID '%s'.\n",
    $campaign_criterion->get_criterion()->get_id());

  return 1;
}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
  return 1;
}

# Log SOAP XML request, response and API errors.
Google::Ads::AdWords::Logging::enable_all_logging();

# Get AdWords Client, credentials will be read from ~/adwords.properties.
my $client = Google::Ads::AdWords::Client->new({version => "v201806"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_product_scope($client, $campaign_id);
