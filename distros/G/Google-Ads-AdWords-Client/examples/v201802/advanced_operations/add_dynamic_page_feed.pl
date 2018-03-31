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
# This code example adds a page feed to specify precisely which URLs to use
# with your Dynamic Search Ads campaign. To create a Dynamic Search Ads
# campaign, run add_dynamic_search_ads_campaign.pl. To get campaigns, run
# get_campaigns.pl.

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::Utilities::PageProcessor;
use Google::Ads::AdWords::v201802::AdGroupCriterionOperation;
use Google::Ads::AdWords::v201802::AttributeFieldMapping;
use Google::Ads::AdWords::v201802::BiddableAdGroupCriterion;
use Google::Ads::AdWords::v201802::Campaign;
use Google::Ads::AdWords::v201802::CampaignFeed;
use Google::Ads::AdWords::v201802::CampaignFeedOperation;
use Google::Ads::AdWords::v201802::CampaignOperation;
use Google::Ads::AdWords::v201802::Feed;
use Google::Ads::AdWords::v201802::FeedAttribute;
use Google::Ads::AdWords::v201802::FeedItem;
use Google::Ads::AdWords::v201802::FeedItemAttributeValue;
use Google::Ads::AdWords::v201802::FeedItemGeoRestriction;
use Google::Ads::AdWords::v201802::FeedItemOperation;
use Google::Ads::AdWords::v201802::FeedMapping;
use Google::Ads::AdWords::v201802::FeedMappingOperation;
use Google::Ads::AdWords::v201802::FeedOperation;
use Google::Ads::AdWords::v201802::Function;
use Google::Ads::AdWords::v201802::Location;
use Google::Ads::AdWords::v201802::PageFeed;
use Google::Ads::AdWords::v201802::Paging;
use Google::Ads::AdWords::v201802::Predicate;
use Google::Ads::AdWords::v201802::Selector;
use Google::Ads::AdWords::v201802::Webpage;
use Google::Ads::AdWords::v201802::WebpageCondition;
use Google::Ads::AdWords::v201802::WebpageParameter;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);
use constant PAGE_SIZE => 500;
# The criterion type to be used for DSA page feeds. DSA page feeds use the
# criterionType field instead of the placeholderType field unlike most other
# feed types.
use constant DSA_PAGE_FEED_CRITERION_TYPE => 61;
# ID that corresponds to the page URLs.
use constant DSA_PAGE_URLS_FIELD_ID => 1;
# ID that corresponds to the labels.
use constant DSA_LABEL_FIELD_ID => 2;

# Replace with valid values of your account.
my $campaign_id = "INSERT_CAMPAIGN_ID_HERE";
my $ad_group_id = "INSERT_AD_GROUP_ID_HERE";

# Example main subroutine.
sub add_dynamic_page_feed {
  my ($client, $campaign_id, $ad_group_id) = @_;
  my $dsa_page_url_label = "discounts";

  # Get the page feed details. This code example creates a new feed, but you can
  # fetch and re-use an existing feed.
  my $feed_details = _create_feed($client);
  _create_feed_mapping($client, $feed_details);
  _create_feed_items($client, $feed_details, $dsa_page_url_label);

  # Associate the page feed with the campaign.
  _update_campaign_dsa_setting($client, $campaign_id, $feed_details);

  # Optional: Target web pages matching the feed's label in the ad group.
  _add_dsa_targeting($client, $ad_group_id, $dsa_page_url_label);

  printf("Dynamic page feed setup is complete for campaign ID %s.\n",
    $campaign_id);

  return 1;
}

sub _create_feed {
  my ($client) = @_;

  #  Create attributes.
  my $url_attribute = Google::Ads::AdWords::v201802::FeedAttribute->new({
    type => "URL_LIST",
    name => "Page URL"
  });

  my $label_attribute = Google::Ads::AdWords::v201802::FeedAttribute->new({
    type => "STRING_LIST",
    name => "Label"
  });

  # Create the feed.
  my $dsa_page_feed = Google::Ads::AdWords::v201802::Feed->new({
    name       => sprintf("DSA Feed #%s", uniqid()),
    attributes => [$url_attribute,        $label_attribute],
    origin     => "USER"
  });

  # Create operation.
  my $operation = Google::Ads::AdWords::v201802::FeedOperation->new({
    operator => "ADD",
    operand  => $dsa_page_feed
  });

  # Add the feed.
  my $feed_result =
    $client->FeedService()->mutate({operations => [$operation]});
  my $new_feed = $feed_result->get_value(0);

  my $feed_details = {
    "feedId"           => $new_feed->get_id(),
    "urlAttributeId"   => $new_feed->get_attributes()->[0]->get_id(),
    "labelAttributeId" => $new_feed->get_attributes()->[1]->get_id()};

  printf(
    "Feed with name '%s' and ID %d with urlAttributeId %d " .
      " and labelAttributeId %d was created.\n",
    $new_feed->get_name(),             $feed_details->{"feedId"},
    $feed_details->{"urlAttributeId"}, $feed_details->{"labelAttributeId"});

  return $feed_details;
}

# Creates the feed mapping for the DSA page feeds.
sub _create_feed_mapping {
  my ($client, $feed_details) = @_;

  # Map the FeedAttributeIds to the fieldId constants.
  my $url_field_mapping =
    Google::Ads::AdWords::v201802::AttributeFieldMapping->new({
      feedAttributeId => $feed_details->{"urlAttributeId"},
      fieldId         => DSA_PAGE_URLS_FIELD_ID
    });

  my $label_field_mapping =
    Google::Ads::AdWords::v201802::AttributeFieldMapping->new({
      feedAttributeId => $feed_details->{"labelAttributeId"},
      fieldId         => DSA_LABEL_FIELD_ID
    });

  # Create the FeedMapping and operation.
  my $feed_mapping = Google::Ads::AdWords::v201802::FeedMapping->new({
      criterionType          => DSA_PAGE_FEED_CRITERION_TYPE,
      feedId                 => $feed_details->{"feedId"},
      attributeFieldMappings => [$url_field_mapping, $label_field_mapping]});

  my $operation = Google::Ads::AdWords::v201802::FeedMappingOperation->new({
    operand  => $feed_mapping,
    operator => "ADD"
  });

  # Save the feed mapping.
  my $result =
    $client->FeedMappingService()->mutate({operations => [$operation]});
  my $new_feed_mapping = $result->get_value()->[0];
  printf "Feed mapping with ID %d and criterionType %d was saved for " .
    "feed with ID %d.\n", $new_feed_mapping->get_feedMappingId(),
    $new_feed_mapping->get_criterionType(),
    $new_feed_mapping->get_feedId();
}

sub _create_feed_items {
  my ($client, $feed_details, $label_name) = @_;

  # Create operations to add FeedItems.
  my @operations = ();
  push @operations,
    _create_dsa_url_add_operation($feed_details,
    "http://www.example.com/discounts/rental-cars", $label_name);
  push @operations,
    _create_dsa_url_add_operation($feed_details,
    "http://www.example.com/discounts/hotel-deals", $label_name);
  push @operations,
    _create_dsa_url_add_operation($feed_details,
    "http://www.example.com/discounts/flight-deals", $label_name);

  my $result = $client->FeedItemService()->mutate({operations => \@operations});

  foreach my $feed_item (@{$result->get_value()}) {
    printf "Feed item with feed item ID %d was added.\n",
      $feed_item->get_feedItemId();
  }
}

# Creates a {@link FeedItemOperation} to add the DSA URL.
sub _create_dsa_url_add_operation {
  my ($feed_details, $url, $label_name) = @_;

  # Create the FeedItemAttributeValues for the URL and label.
  my $url_attribute_value =
    Google::Ads::AdWords::v201802::FeedItemAttributeValue->new({
      feedAttributeId => $feed_details->{"urlAttributeId"},
      # See https://support.google.com/adwords/answer/7166527 for
      # page feed URL recommendations and rules.
      stringValues => sprintf("%s", $url)});

  my $label_attribute_value =
    Google::Ads::AdWords::v201802::FeedItemAttributeValue->new({
      feedAttributeId => $feed_details->{"labelAttributeId"},
      stringValues    => $label_name
    });

  # Create the feed item and operation.
  my $feed_item = Google::Ads::AdWords::v201802::FeedItem->new({
      feedId          => $feed_details->{"feedId"},
      attributeValues => [$url_attribute_value, $label_attribute_value]});

  my $operation = Google::Ads::AdWords::v201802::FeedItemOperation->new({
    operand  => $feed_item,
    operator => "ADD"
  });

  return $operation;
}

# Update the campaign DSA setting to add DSA pagefeeds.
sub _update_campaign_dsa_setting {
  my ($client, $campaign_id, $feed_details) = @_;

  my $paging = Google::Ads::AdWords::v201802::Paging->new({
    startIndex    => 0,
    numberResults => PAGE_SIZE
  });
  my $selector = Google::Ads::AdWords::v201802::Selector->new({
      fields     => ["Id", "Settings"],
      predicates => [
        Google::Ads::AdWords::v201802::Predicate->new({
            field    => "CampaignId",
            operator => "EQUALS",
            values   => [$campaign_id]})
      ],
      paging => $paging
    });

  my $dsa_setting = undef;
  Google::Ads::AdWords::Utilities::PageProcessor->new({
      client   => $client,
      service  => $client->CampaignService(),
      selector => $selector
    }
    )->process_entries(
    sub {
      my ($campaign) = @_;
      if ($campaign->get_settings()) {
        foreach my $setting (@{$campaign->get_settings()}) {
          if (
            $setting->isa(
              "Google::Ads::AdWords::v201802::DynamicSearchAdsSetting"))
          {
            $dsa_setting = $setting;
            last;
          }
        }
      }
    });

  if (!$dsa_setting) {
    die sprintf("Campaign with ID %s is not a DSA campaign.", $campaign_id);
  }

  # Use a page feed to specify precisely which URLs to use with your
  # Dynamic Search Ads.
  my $page_feed = Google::Ads::AdWords::v201802::PageFeed->new({
      feedIds => [$feed_details->{"feedId"}]});
  $dsa_setting->set_pageFeed($page_feed);

  # Optional: Specify whether only the supplied URLs should be used with your
  # Dynamic Search Ads.
  $dsa_setting->set_useSuppliedUrlsOnly(1);

  my $updated_campaign = Google::Ads::AdWords::v201802::Campaign->new({
      id       => $campaign_id,
      settings => [$dsa_setting]});

  my $operation = Google::Ads::AdWords::v201802::CampaignOperation->new({
    operand  => $updated_campaign,
    operator => "SET"
  });

  $client->CampaignService()->mutate({operations => [$operation]});
  printf(
    "DSA page feed for campaign ID %d was updated with feed ID %d.\n",
    $updated_campaign->get_id(),
    $feed_details->{"feedId"});
}

# Sets custom targeting for the page feed URLs based on a list of labels.
sub _add_dsa_targeting {
  my ($client, $ad_group_id, $dsa_page_url_label) = @_;

  # Create a webpage criterion.
  # Add a condition for label=specified_label_name.
  my $condition = Google::Ads::AdWords::v201802::WebpageCondition->new({
    operand  => "CUSTOM_LABEL",
    argument => $dsa_page_url_label
  });

  # Create a webpage criterion for special offers.
  my $parameter = Google::Ads::AdWords::v201802::WebpageParameter->new({
      criterionName => "Test criterion",
      conditions    => [$condition]});

  my $webpage = Google::Ads::AdWords::v201802::Webpage->new({
    parameter => $parameter
  });

  # Create biddable ad group criterion.
  my $biddable_ad_group_criterion =
    Google::Ads::AdWords::v201802::BiddableAdGroupCriterion->new({
      adGroupId => $ad_group_id,
      criterion => $webpage,
      # Set a custom bid for this criterion.
      biddingStrategyConfiguration =>
        Google::Ads::AdWords::v201802::BiddingStrategyConfiguration->new({
          bids => [
            Google::Ads::AdWords::v201802::CpcBid->new({
                bid => Google::Ads::AdWords::v201802::Money->new(
                  {microAmount => 1500000}
                ),
              }
            ),
          ]})});

  # Create operation.
  my $operation =
    Google::Ads::AdWords::v201802::AdGroupCriterionOperation->new({
      operator => "ADD",
      operand  => $biddable_ad_group_criterion
    });

  # Create the criterion.
  my $result =
    $client->AdGroupCriterionService()->mutate({operations => [$operation]});
  my $new_ad_group_criterion = $result->get_value()->[0];
  printf "Web page criterion with ID %d and status '%s' was created.\n",
    $new_ad_group_criterion->get_criterion()->get_id(),
    $new_ad_group_criterion->get_userStatus();
}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
  return 1;
}

# Log SOAP XML request, response and API errors.
Google::Ads::AdWords::Logging::enable_all_logging();

# Get AdWords Client, credentials will be read from ~/adwords.properties.
my $client = Google::Ads::AdWords::Client->new({version => "v201802"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Call the example
add_dynamic_page_feed($client, $campaign_id, $ad_group_id);
