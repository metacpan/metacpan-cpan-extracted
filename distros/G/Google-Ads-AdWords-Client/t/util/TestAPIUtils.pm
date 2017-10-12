# Copyright 2011, Google Inc. All Rights Reserved.
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

package TestAPIUtils;

use strict;
use vars qw(@EXPORT_OK @ISA);

use Google::Ads::Common::MediaUtils;

use Data::Uniqid qw(uniqid);
use Exporter;
use File::Basename;
use File::Spec;
use POSIX;

@ISA       = qw(Exporter);
@EXPORT_OK = qw(get_api_package create_campaign delete_campaign create_ad_group
  delete_ad_group create_text_ad delete_text_ad create_keyword
  delete_keyword get_test_image
  get_location_for_address create_experiment delete_experiment add_draft
  delete_draft add_trial delete_trial);

sub get_api_package {
  my $client = shift;
  my $name   = shift;
  my $import = shift;

  my $api_version       = $client->get_version();
  my $full_package_name = "Google::Ads::AdWords::${api_version}::${name}";
  if ($import) {
    eval("use $full_package_name");
  }

  return $full_package_name;
}

sub create_campaign {
  my $client           = shift;
  my $advertising_type = shift;
  my $bidding_strategy = shift;
  if (!$bidding_strategy) {
    $bidding_strategy =
      get_api_package($client, "BiddingStrategyConfiguration", 1)->new({
        biddingStrategyType => "MANUAL_CPC",
        biddingScheme => get_api_package($client, "ManualCpcBiddingScheme", 1)
          ->new({enhancedCpcEnabled => 0})});
  }

  my $budget = get_api_package($client, "Budget", 1)->new({
      name               => "Test " . uniqid(),
      amount             => {microAmount => 50000000},
      deliveryMethod     => "STANDARD",
      isExplicitlyShared => "false"
  });
  my $budget_operation = get_api_package($client, "BudgetOperation", 1)->new({
      operand  => $budget,
      operator => "ADD"
  });
  $budget =
    $client->BudgetService()->mutate({operations => ($budget_operation)})
    ->get_value();

  my $campaign = get_api_package($client, "Campaign", 1)->new({
      name                         => "Campaign #" . uniqid(),
      biddingStrategyConfiguration => $bidding_strategy,
      budget                       => $budget,
  });

  $campaign->set_advertisingChannelType($advertising_type);

  my $operation = get_api_package($client, "CampaignOperation", 1)->new({
      operand  => $campaign,
      operator => "ADD"
  });

  $campaign =
    $client->CampaignService()->mutate({operations => [$operation]})
    ->get_value();

  return $campaign;
}

sub delete_campaign {
  my $client      = shift;
  my $campaign_id = shift;

  my $campaign =
    get_api_package($client, "Campaign", 1)->new({id => $campaign_id,});

  $campaign->set_status("REMOVED");

  my $operation = get_api_package($client, "CampaignOperation", 1)->new({
      operand  => $campaign,
      operator => "SET"
  });

  $client->CampaignService()->mutate({operations => [$operation]});
}

sub create_ad_group {
  my $client      = shift;
  my $campaign_id = shift;
  my $name        = shift || uniqid();
  my $bids        = shift;
  my $adgroup;

  $adgroup = get_api_package($client, "AdGroup", 1)->new({
      name       => $name,
      campaignId => $campaign_id,
      biddingStrategyConfiguration =>
        get_api_package($client, "BiddingStrategyConfiguration", 1)->new({
          bids => $bids
            || [
            get_api_package($client, "CpcBid", 1)->new({
                bid => get_api_package($client, "Money", 1)
                  ->new({microAmount => "500000"})}
            ),
            ]})});

  my $operations = [
    get_api_package($client, "AdGroupOperation", 1)->new({
        operand  => $adgroup,
        operator => "ADD"
      })];

  my $return_ad_group =
    $client->AdGroupService()->mutate({operations => $operations})->get_value();

  return $return_ad_group;
}

sub delete_ad_group {
  my $client     = shift;
  my $adgroup_id = shift;

  my $adgroup =
    get_api_package($client, "AdGroup", 1)->new({id => $adgroup_id,});

  $adgroup->set_status("REMOVED");

  my $operation = get_api_package($client, "AdGroupOperation", 1)->new({
      operand  => $adgroup,
      operator => "SET"
  });

  return $client->AdGroupService()->mutate({operations => [$operation]});
}

sub create_keyword {
  my $client      = shift;
  my $ad_group_id = shift;

  my $criterion = get_api_package($client, "Keyword", 1)->new({
      text      => "Luxury Cruise to Mars",
      matchType => "BROAD"
  });
  my $keyword_biddable_ad_group_criterion =
    get_api_package($client, "BiddableAdGroupCriterion", 1)->new({
      adGroupId => $ad_group_id,
      criterion => $criterion
    });
  my $result = $client->AdGroupCriterionService()->mutate({
      operations => [
        get_api_package($client, "AdGroupCriterionOperation", 1)->new({
            operator => "ADD",
            operand  => $keyword_biddable_ad_group_criterion
          })]});

  return $result->get_value()->[0]->get_criterion();
}

sub delete_keyword {
  my $client       = shift;
  my $ad_group_id  = shift;
  my $criterion_id = shift;

  my $ad_group_criterion = get_api_package($client, "AdGroupCriterion", 1)->new(
    {
      adGroupId => $ad_group_id,
      criterion =>
        get_api_package($client, "Criterion", 1)->new({id => $criterion_id})});

  my $operation = get_api_package($client, "AdGroupCriterionOperation", 1)->new(
    {
      operand  => $ad_group_criterion,
      operator => "REMOVE"
    });

  return $client->AdGroupCriterionService()
    ->mutate({operations => [$operation]});
}

sub create_text_ad {
  my $client      = shift;
  my $ad_group_id = shift;

  my $text_ad = get_api_package($client, "ExpandedTextAd", 1)->new({
      headlinePart1 => "Luxury Cruise to Mars",
      headlinePart2 => "Best Space Cruise Line",
      description   => "Buy your tickets now!",
      finalUrls     => ["http://www.example.com/"],
      path1         => "all-inclusive",
      path2         => "deals"});
  my $ad_group_ad = get_api_package($client, "AdGroupAd", 1)->new({
      adGroupId => $ad_group_id,
      ad        => $text_ad
  });
  my $result = $client->AdGroupAdService()->mutate({
      operations => [
        get_api_package($client, "AdGroupAdOperation", 1)->new({
            operator => "ADD",
            operand  => $ad_group_ad
          })]});

  return $result->get_value()->[0]->get_ad();
}

sub delete_text_ad {
  my $client      = shift;
  my $ad_group_id = shift;
  my $text_ad_id  = shift;

  my $ad_group_ad =
    get_api_package($client, "AdGroupAd", 1)
    ->new({
      adGroupId => $ad_group_id,
      ad => get_api_package($client, "Ad", 1)->new({id => $text_ad_id})});

  my $operation = get_api_package($client, "AdGroupAdOperation", 1)->new({
      operand  => $ad_group_ad,
      operator => "REMOVE"
  });

  return $client->AdGroupAdService()->mutate({operations => [$operation]});
}

sub create_experiment {
  my $client      = shift;
  my $campaign_id = shift;

  my $experiment = get_api_package($client, "Experiment", 1)->new({
      campaignId      => $campaign_id,
      name            => "Test experiment",
      queryPercentage => 50
  });
  my $result = $client->ExperimentService()->mutate({
      operations => [
        get_api_package($client, "ExperimentOperation", 1)->new({
            operator => "ADD",
            operand  => $experiment
          })]});

  return $result->get_value()->[0];
}

sub delete_experiment {
  my $client        = shift;
  my $experiment_id = shift;

  my $experiment =
    get_api_package($client, "Experiment", 1)->new({id => $experiment_id});

  my $operation = get_api_package($client, "ExperimentOperation", 1)->new({
      operand  => $experiment,
      operator => "REMOVE"
  });

  return $client->ExperimentService()->mutate({operations => [$operation]});
}

sub get_test_image {
  return Google::Ads::Common::MediaUtils::get_base64_data_from_url(
    "https://goo.gl/3b9Wfh");
}

sub get_any_child_client_email {
  my $client            = shift;
  my $current_client_id = $client->get_client_id();
  $client->set_client_id(undef);

  my $email;
  my $selector =
    get_api_package($client, "Selector", 1)
    ->new({fields => ["Login", "CanManageClients"]});
  my $page =
    $client->ManagedCustomerService()->get({serviceSelector => $selector});
  foreach my $customer (@{$page->get_entries()}) {
    if ($customer->get_login() ne "" && !$customer->get_canManageClients()) {
      $email = $customer->get_login()->get_value();
      last;
    }
  }

  $client->set_client_id($current_client_id);

  return $email;
}

sub create_draft {
  my $client           = shift;
  my $base_campaign_id = shift;

  my $draft = get_api_package($client, "Draft", 1)->new({
      baseCampaignId => $base_campaign_id,
      draftName      => sprintf("Test Draft #%s", uniqid())});

  # Create operation.
  my $draft_operation = get_api_package($client, "DraftOperation", 1)->new({
      operator => "ADD",
      operand  => $draft
  });

  # Add draft.
  my $result =
    $client->DraftService()->mutate({operations => [$draft_operation]});

  $draft = $result->get_value()->[0];

  return $draft;
}

sub delete_draft {
  my $client           = shift;
  my $base_campaign_id = shift;
  my $draft_id         = shift;

  my $draft = get_api_package($client, "Draft", 1)->new({
      baseCampaignId => $base_campaign_id,
      draftId        => $draft_id,
      draftStatus    => "ARCHIVED"
  });

  my $operation = get_api_package($client, "DraftOperation", 1)->new({
      operand  => $draft,
      operator => "SET"
  });

  return $client->DraftService()->mutate({operations => [$operation]});
}

sub create_trial {
  my $client           = shift;
  my $base_campaign_id = shift;
  my $draft_id         = shift;

  my $trial = get_api_package($client, "Trial", 1)->new({
      draftId             => $draft_id,
      baseCampaignId      => $base_campaign_id,
      name                => sprintf("Test Trial #%s", uniqid()),
      trafficSplitPercent => 50,
  });

  # Create operation.
  my $trial_operation = get_api_package($client, "TrialOperation", 1)->new({
      operator => "ADD",
      operand  => $trial
  });

  # Add trial.
  my $result =
    $client->TrialService()->mutate({operations => [$trial_operation]});

  $trial = $result->get_value()->[0];

  return $trial;
}

sub delete_trial {
  my $client   = shift;
  my $trial_id = shift;

  my $trial =
    get_api_package($client, "Trial", 1)
    ->new({id => $trial_id, status => "ARCHIVED"});

  my $operation = get_api_package($client, "TrialOperation", 1)->new({
      operand  => $trial,
      operator => "SET"
  });

  return $client->TrialService()->mutate({operations => [$operation]});
}

return 1;
