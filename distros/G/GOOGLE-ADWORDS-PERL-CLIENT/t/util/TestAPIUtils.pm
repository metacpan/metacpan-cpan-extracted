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
#
# Author: David Torres <api.davidtorres@gmail.com>

package TestAPIUtils;

use strict;
use vars qw(@EXPORT_OK @ISA);

use Google::Ads::Common::MediaUtils;

use Data::Uniqid qw(uniqid);
use Exporter;
use File::Basename;
use File::Spec;
use POSIX;

@ISA = qw(Exporter);
@EXPORT_OK = qw(get_api_package create_campaign delete_campaign create_ad_group
                delete_ad_group create_text_ad delete_text_ad create_keyword
                delete_keyword  create_campaign_location_extension
                delete_campaign_ad_extension get_test_image
                get_location_for_address create_experiment delete_experiment);

sub get_api_package {
  my $client = shift;
  my $name = shift;
  my $import = shift;

  my $api_version = $client->get_version();
  my $full_package_name = "Google::Ads::AdWords::${api_version}::${name}";
  if ($import) {
    eval("use $full_package_name");
  }

  return $full_package_name;
}

sub create_campaign {
  my $client = shift;
  my $bidding_strategy = shift;
  if (!$bidding_strategy) {
    if ($client->get_version() ge "v201302") {
      $bidding_strategy =
          get_api_package($client, "BiddingStrategyConfiguration", 1)->new({
            biddingStrategyType => "MANUAL_CPC",
            biddingScheme =>
                get_api_package($client, "ManualCpcBiddingScheme", 1)->new({
                  enhancedCpcEnabled => 0
                })
          });
    } else {
      $bidding_strategy = get_api_package($client, "ManualCPC", 1);
    }
  }
  my $budget;
  my $campaign;


  if ($client->get_version() ge "v201209") {
    $budget = get_api_package($client, "Budget", 1)->new({
      name => "Test " . uniqid(),
      period => "DAILY",
      amount => { microAmount => 50000000 },
      deliveryMethod => "STANDARD"
    });
    my $budget_operation = get_api_package($client, "BudgetOperation", 1)->new({
      operand => $budget,
      operator => "ADD"
    });
    $budget = $client->BudgetService()->mutate({
      operations => ($budget_operation)
    })->get_value();
  } else {
    $budget = get_api_package($client, "Budget", 1)->new({
      period => "DAILY",
      amount => { microAmount => 50000000 },
      deliveryMethod => "STANDARD"
    });
  }
  if ($client->get_version() ge "v201302") {
    $campaign = get_api_package($client, "Campaign", 1)->new({
      name => "Campaign #" . uniqid(),
      biddingStrategyConfiguration => $bidding_strategy,
      budget => $budget,
    });
  } else {
    $campaign = get_api_package($client, "Campaign", 1)->new({
      name => "Campaign #" . uniqid(),
      biddingStrategy => $bidding_strategy->new(),
      budget => $budget
    });
  }

  if ($client->get_version() ge "v201209") {
    $campaign->set_settings([
      get_api_package($client, "KeywordMatchSetting", 1)->new({
        optIn => 1
      })
    ]);
  }

  if ($client->get_version() ge "v201402") {
    $campaign->set_advertisingChannelType("SEARCH");
  }

  my $operation = get_api_package($client, "CampaignOperation", 1)->new({
    operand => $campaign,
    operator => "ADD"
  });

  $campaign = $client->CampaignService()->mutate({
    operations => [$operation]
  })->get_value();

  return $campaign;
}

sub delete_campaign {
  my $client = shift;
  my $campaign_id = shift;

  my $campaign = get_api_package($client, "Campaign", 1)->new({
    id => $campaign_id,
    status => "DELETED"
  });

  my $operation = get_api_package($client, "CampaignOperation", 1)->new({
    operand => $campaign,
    operator => "SET"
  });

  $client->CampaignService()->mutate({
    operations => [$operation]
  });
}

sub create_ad_group {
  my $client = shift;
  my $campaign_id = shift;
  my $name = shift || uniqid();
  my $bids = shift;
  my $adgroup;

  if ($client->get_version() ge "v201302") {
    $adgroup = get_api_package($client, "AdGroup", 1)->new({
      name => $name,
      campaignId => $campaign_id,
      biddingStrategyConfiguration =>
          get_api_package($client, "BiddingStrategyConfiguration", 1)->new({
            bids =>  $bids || [
              get_api_package($client, "CpcBid", 1)->new({
                bid => get_api_package($client, "Money", 1)->new({
                  microAmount => "500000"
                })
              }),
            ]
          })
    });
  } else {
    $adgroup = get_api_package($client, "AdGroup", 1)->new({
      name => $name,
      campaignId => $campaign_id,
      bids => $bids || get_api_package($client, "ManualCPCAdGroupBids", 1)->new({
        keywordMaxCpc => get_api_package($client, "Bid", 1)->new({
          amount => get_api_package($client, "Money", 1)->new({
            microAmount => "500000"
          })
        })
      })
    });
  }

  my $operations = [
    get_api_package($client, "AdGroupOperation", 1)->new({
      operand => $adgroup,
      operator => "ADD"
    })
  ];

  my $return_ad_group = $client->AdGroupService()->mutate({
    operations => $operations
  })->get_value();

  return $return_ad_group;
}

sub delete_ad_group {
  my $client = shift;
  my $adgroup_id = shift;

  my $adgroup = get_api_package($client, "AdGroup", 1)->new({
    id => $adgroup_id,
    status => "DELETED"
  });

  my $operation = get_api_package($client, "AdGroupOperation", 1)->new({
    operand => $adgroup,
    operator => "SET"
  });

  return $client->AdGroupService()->mutate({
    operations => [$operation]
  });
}

sub create_keyword {
  my $client = shift;
  my $ad_group_id = shift;

  my $criterion = get_api_package($client, "Keyword", 1)->new({
    text => "Luxury Cruise to Mars",
    matchType => "BROAD"
  });
  my $keyword_biddable_ad_group_criterion =
      get_api_package($client, "BiddableAdGroupCriterion", 1)->new({
        adGroupId => $ad_group_id,
        criterion => $criterion
      });
  my $result = $client->AdGroupCriterionService()->mutate({
    operations => [get_api_package($client,
                                   "AdGroupCriterionOperation", 1)->new({
      operator => "ADD",
      operand => $keyword_biddable_ad_group_criterion
    })]
  });

  return $result->get_value()->[0]->get_criterion();
}

sub delete_keyword {
  my $client = shift;
  my $ad_group_id = shift;
  my $criterion_id = shift;

  my $ad_group_criterion =
      get_api_package($client, "AdGroupCriterion", 1)->new({
        adGroupId => $ad_group_id,
        criterion => get_api_package($client, "Criterion", 1)->new({
          id => $criterion_id
        })
      });

  my $operation =
      get_api_package($client, "AdGroupCriterionOperation", 1)->new({
        operand => $ad_group_criterion,
        operator => "REMOVE"
      });

  return $client->AdGroupCriterionService()->mutate({
    operations => [$operation]
  });
}

sub create_text_ad {
  my $client = shift;
  my $ad_group_id = shift;

  my $text_ad = get_api_package($client, "TextAd", 1)->new({
    headline => "Luxury Cruise to Mars",
    description1 => "Visit the Red Planet in style.",
    description2 => "Low-gravity fun for everyone!",
    displayUrl => "www.example.com",
    url => "http://www.example.com"
  });
  my $ad_group_ad = get_api_package($client, "AdGroupAd", 1)->new({
    adGroupId => $ad_group_id,
    ad => $text_ad
  });
  my $result = $client->AdGroupAdService()->mutate({
    operations => [get_api_package($client, "AdGroupAdOperation", 1)->new({
      operator => "ADD",
      operand => $ad_group_ad
    })]
  });

  return $result->get_value()->[0]->get_ad();
}

sub delete_text_ad {
  my $client = shift;
  my $text_ad_id = shift;

  my $ad_group_ad = get_api_package($client, "AdGroupAd", 1)->new({
    ad => get_api_package($client, "Ad", 1)->new({
      id => $text_ad_id
    })
  });

  my $operation = get_api_package($client, "AdGroupAdOperation", 1)->new({
    operand => $ad_group_ad,
    operator => "REMOVE"
  });

  return $client->AdGroupAdService()->mutate({
    operations => [$operation]
  });
}

sub create_campaign_location_extension {
  my $client = shift;
  my $campaign_id = shift;

  my $address = get_api_package($client, "Address", 1)->new({
    streetAddress => "1600 Amphitheatre Pkwy, Mountain View",
    countryCode => "US"
  });
  my $location = get_location_for_address($client, $address);
  my $location_extension =
      get_api_package($client, "LocationExtension", 1)->new({
        address => $location->get_address(),
        geoPoint => $location->get_geoPoint(),
        encodedLocation => $location->get_encodedLocation(),
        source => "ADWORDS_FRONTEND"
      });
  my $extension = get_api_package($client, "CampaignAdExtension", 1)->new({
    campaignId => $campaign_id,
    status => "ACTIVE",
    adExtension => $location_extension
  });
  my $result = $client->CampaignAdExtensionService()->mutate({
    operations => [get_api_package($client, "CampaignAdExtensionOperation",
                                   1)->new({
      operator => "ADD",
      operand => $extension
    })]
  });

  return $result->get_value()->[0];
}

sub delete_campaign_ad_extension {
  my $client = shift;
  my $campaign_id = shift;
  my $extension_id = shift;

  my $extension = get_api_package($client, "CampaignAdExtension", 1)->new({
    adExtension => get_api_package($client, "AdExtension", 1)->new({
      id => $extension_id
    }),
    campaignId => $campaign_id
  });

  my $operation =
      get_api_package($client, "CampaignAdExtensionOperation", 1)->new({
        operand => $extension,
        operator => "REMOVE"
      });

  return $client->CampaignAdExtensionService()->mutate({
    operations => [$operation]
  });
}

sub create_experiment {
  my $client = shift;
  my $campaign_id = shift;

  my $experiment = get_api_package($client, "Experiment", 1)->new({
    campaignId => $campaign_id,
    name => "Test experiment",
    queryPercentage => 50
  });
  my $result = $client->ExperimentService()->mutate({
    operations => [get_api_package($client, "ExperimentOperation", 1)->new({
      operator => "ADD",
      operand => $experiment
    })]
  });

  return $result->get_value()->[0];
}

sub delete_experiment {
  my $client = shift;
  my $experiment_id = shift;

  my $experiment = get_api_package($client, "Experiment", 1)->new({
    id => $experiment_id
  });

  my $operation = get_api_package($client, "ExperimentOperation", 1)->new({
    operand => $experiment,
    operator => "REMOVE"
  });

  return $client->ExperimentService()->mutate({
    operations => [$operation]
  });
}

sub get_test_image {
  return Google::Ads::Common::MediaUtils::get_base64_data_from_url(
      "http://goo.gl/HJM3L");
}

sub get_location_for_address {
  my $client = shift;
  my $address = shift;

  my $selector = get_api_package($client, "GeoLocationSelector", 1)->new({
    addresses => [$address]
  });

  return $client->GeoLocationService()->get({
    selector => [$selector]
  })->[0];
}

sub get_any_child_client_email {
  my $client = shift;
  my $current_client_id = $client->get_client_id();
  $client->set_client_id(undef);

  my $email;
  if ($client->get_version() lt "v201209") {
    my $selector = get_api_package($client, "ServicedAccountSelector", 1)->new({
      enablePaging => 0
    });
    my $graph = $client->ServicedAccountService()->get({
      selector => $selector
    });
    foreach my $account (@{$graph->get_accounts()}) {
      if ($account->get_login() ne "" && !$account->get_canManageClients()) {
        $email = $account->get_login()->get_value();
        last;
      }
    }
  } else {
    my $selector = get_api_package($client, "Selector", 1)->new({
      fields => ["Login", "CanManageClients"]
    });
    my $page = $client->ManagedCustomerService()->get({
      serviceSelector => $selector
    });
    foreach my $customer (@{$page->get_entries()}) {
      if ($customer->get_login() ne "" && !$customer->get_canManageClients()) {
        $email = $customer->get_login()->get_value();
        last;
      }
    }
  }

  $client->set_client_id($current_client_id);

  return $email;
}

return 1;
