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
# This example adds a universal app campaign. To get campaigns, run
# get_campaigns.pl. To upload image assets for this campaign, run
# upload_image.pl.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201708::BiddingStrategyConfiguration;
use Google::Ads::AdWords::v201708::Budget;
use Google::Ads::AdWords::v201708::BudgetOperation;
use Google::Ads::AdWords::v201708::Campaign;
use Google::Ads::AdWords::v201708::CampaignCriterion;
use Google::Ads::AdWords::v201708::CampaignCriterionOperation;
use Google::Ads::AdWords::v201708::CampaignOperation;
use Google::Ads::AdWords::v201708::GeoTargetTypeSetting;
use Google::Ads::AdWords::v201708::Language;
use Google::Ads::AdWords::v201708::Location;
use Google::Ads::AdWords::v201708::Money;
use Google::Ads::AdWords::v201708::NetworkSetting;
use Google::Ads::AdWords::v201708::TargetCpaBiddingScheme;
use Google::Ads::AdWords::v201708::UniversalAppCampaignSetting;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Example main subroutine.
sub add_universal_app_campaign {
  my $client = shift;

  # Set the campaign's assets and ad text ideas. These values will be used to
  # generate ads.
  my $universalAppSetting =
    Google::Ads::AdWords::v201708::UniversalAppCampaignSetting->new({
      appId        => "com.labpixies.colordrips",
      description1 => "A cool puzzle game",
      description2 => "Remove connected blocks",
      description3 => "3 difficulty levels",
      description4 => "4 colorful fun skins"
    });

  # Optional: You can set up to 10 image assets for your campaign.
  # See upload_image.pl for an example on how to upload images.
  # universalAppSetting->set_imageMediaIds([INSERT_IMAGE_MEDIA_ID_HERE]);

  # Optimize this campaign for getting new users for your app.
  $universalAppSetting->set_universalAppBiddingStrategyGoalType(
    "OPTIMIZE_FOR_INSTALL_CONVERSION_VOLUME");

  # If you select the OPTIMIZE_FOR_IN_APP_CONVERSION_VOLUME goal type, then also
  # specify your in-app conversion types so AdWords can focus your campaign on
  # people who are most likely to complete the corresponding in-app actions.
  # Conversion type IDs can be retrieved using ConversionTrackerService.get.

  # my $selectiveOptimization =
  # Google::Ads::AdWords::v201708::SelectiveOptimization->new({
  #  conversionTypeIds =>
  #    [INSERT_CONVERSION_TYPE_ID_1_HERE, INSERT_CONVERSION_TYPE_ID_2_HERE]
  # });
  # $campaign->set_selectiveOptimization($selectiveOptimization);

  # Optional: Set the campaign settings for advanced location options.
  my $geoSetting = Google::Ads::AdWords::v201708::GeoTargetTypeSetting->new({
    positiveGeoTargetType => "LOCATION_OF_PRESENCE",
    negativeGeoTargetType => "DONT_CARE"
  });

  my (undef, undef, undef, $mday, $mon, $year) = localtime(time + 60 * 60 * 24);
  my $start_date = sprintf("%d%02d%02d", ($year + 1900), ($mon + 1), $mday);
  (undef, undef, undef, $mday, $mon, $year) =
    localtime(time + 60 * 60 * 24 * 365);
  my $end_date = sprintf("%d%02d%02d", ($year + 1900), ($mon + 1), $mday);

  my $budgetId = create_budget($client);

  my $campaign = Google::Ads::AdWords::v201708::Campaign->new({
      name => "Interplanetary Cruise App #" . uniqid(),
      # Bidding strategy (required).
      # Set the campaign's bidding strategy. Universal app campaigns
      # only support TARGET_CPA bidding strategy.
      biddingStrategyConfiguration =>
        Google::Ads::AdWords::v201708::BiddingStrategyConfiguration->new({
          biddingStrategyType => "TARGET_CPA",
          # Set the target CPA to $1 / app install.
          biddingScheme =>
            Google::Ads::AdWords::v201708::TargetCpaBiddingScheme->new({
              targetCpa => Google::Ads::AdWords::v201708::Money->new(
                {microAmount => 1000000})})}
        ),
      # Budget (required) - note only the budgetId is required.
      budget =>
        Google::Ads::AdWords::v201708::Budget->new({budgetId => $budgetId}),
      # Advertising channel type (required).
      # Set the advertising channel and subchannel types for universal
      # app campaigns.
      advertisingChannelType    => "MULTI_CHANNEL",
      advertisingChannelSubType => "UNIVERSAL_APP_CAMPAIGN",
      settings                  => [$universalAppSetting, $geoSetting],
      # Additional properties (non-required).
      startDate => $start_date,
      endDate   => $end_date,
      # Recommendation: Set the campaign to PAUSED when creating it to stop
      # the ads from immediately serving. Set to ENABLED once you've added
      # targeting and the ads are ready to serve.
      status    => "PAUSED"
    });

  # Create operation.
  my $campaign_operation =
    Google::Ads::AdWords::v201708::CampaignOperation->new({
      operator => "ADD",
      operand  => $campaign
    });

  # Add campaigns.
  my $result =
    $client->CampaignService()->mutate({operations => [$campaign_operation]});

  # Display campaigns.
  foreach my $new_campaign (@{$result->get_value()}) {
    printf "Universal app campaign with name \"%s\" and ID %s was added.\n",
      $new_campaign->get_name(), $new_campaign->get_id();
    # Optional: Set the campaign's location and language targeting. No other
    # targeting criteria can be used for universal app campaigns.
    set_campaign_targeting_criteria($client, $new_campaign->get_id());
  }

  return 1;
}

# Create the budget.
sub create_budget() {
  my ($client) = @_;

  # Create the campaign budget.
  my $budget = Google::Ads::AdWords::v201708::Budget->new({
    # Required attributes.
    name => "Interplanetary Cruise App Budget #" . uniqid(),
    amount =>
      Google::Ads::AdWords::v201708::Money->new({microAmount => 5000000}),
    deliveryMethod => "STANDARD",
    # Universal app campaigns don't support shared budgets.
    isExplicitlyShared => 0
  });

  my $budget_operation = Google::Ads::AdWords::v201708::BudgetOperation->new({
    operator => "ADD",
    operand  => $budget
  });

  # Add budget.
  my $addedBudget =
    $client->BudgetService()->mutate({operations => ($budget_operation)})
    ->get_value();
  printf
    "Budget with name '%s' and ID %d was created.\n",
    $addedBudget->get_name(), $addedBudget->get_budgetId()->get_value();
  my $budget_id = $addedBudget->get_budgetId()->get_value();
  return $budget_id;
}

# Set the campaign targeting criteria.
sub set_campaign_targeting_criteria() {
  my ($client, $campaign_id) = @_;
  my @criteria = ();

  # Create locations. The IDs can be found in the documentation or retrieved
  # with the LocationCriterionService.
  my $california = Google::Ads::AdWords::v201708::Location->new({id => 21137});
  push @criteria, $california;
  my $mexico = Google::Ads::AdWords::v201708::Location->new({id => 2484});
  push @criteria, $mexico;

  # Create languages. The IDs can be found in the documentation or retrieved
  # with the ConstantDataService.
  my $english = Google::Ads::AdWords::v201708::Language->new({id => 1000});
  push @criteria, $english;
  my $spanish = Google::Ads::AdWords::v201708::Language->new({id => 1003});
  push @criteria, $spanish;

  # Create operations.
  my @operations = ();
  foreach my $criterion (@criteria) {
    my $operation =
      Google::Ads::AdWords::v201708::CampaignCriterionOperation->new({
        operator => "ADD",
        operand  => Google::Ads::AdWords::v201708::CampaignCriterion->new({
            campaignId => $campaign_id,
            criterion  => $criterion
          })});
    push @operations, $operation;
  }

  # Set campaign criteria.
  my $result =
    $client->CampaignCriterionService()->mutate({operations => \@operations});

  # Display campaign criteria.
  if ($result->get_value()) {
    foreach my $campaign_criterion (@{$result->get_value()}) {
      printf "Campaign criterion of type '%s' and ID %s was added.\n",
        $campaign_criterion->get_criterion()->get_type(),
        $campaign_criterion->get_criterion()->get_id();
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
my $client = Google::Ads::AdWords::Client->new({version => "v201708"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_universal_app_campaign($client);
