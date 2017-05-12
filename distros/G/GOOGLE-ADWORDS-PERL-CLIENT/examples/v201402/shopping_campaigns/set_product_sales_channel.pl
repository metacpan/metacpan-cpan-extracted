#!/usr/bin/perl -w
#
# Copyright 2012, Google Inc. All Rights Reserved.
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
# This example sets the product sales channel.
#
# Tags: CampaignCriterionService.mutate
# Author: Josh Radcliff <api.jradcliff@gmail.com>

use strict;
use lib "../../../lib";

use Data::Uniqid qw(uniqid);

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201402::CampaignCriterion;
use Google::Ads::AdWords::v201402::CampaignCriterionOperation;
use Google::Ads::AdWords::v201402::ProductSalesChannel;

use Cwd qw(abs_path);

# ProductSalesChannel is a fixedId criterion, with the possible values
# defined here.
use constant ONLINE => 200;
use constant LOCAL => 201;

# Replace with valid values of your account.
my $campaign_id = "INSERT_CAMPAIGN_ID_HERE";

# Example main subroutine.
sub set_product_sales_channel_example {
  my $client = shift;

  my $product_sales_channel =
    Google::Ads::AdWords::v201402::ProductSalesChannel->new({
      id => ONLINE
  });

  my $campaign_criterion =
    Google::Ads::AdWords::v201402::CampaignCriterion->new({
      campaignId => $campaign_id,
      criterion => $product_sales_channel
  });

  # Create operation.
  my $operation =
    Google::Ads::AdWords::v201402::CampaignCriterionOperation->new({
      operand => $campaign_criterion,
      operator => "ADD"
  });

  # Make the mutate request.
  my $result = $client->CampaignCriterionService()->mutate({
    operations => [ $operation ]
  });

  # Display result.
  $campaign_criterion = $result->get_value()->[0];

  printf "Created a ProductSalesChannel criterion with ID %d.\n",
         $campaign_criterion->get_criterion()->get_id();

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
set_product_sales_channel_example($client, $campaign_id);
