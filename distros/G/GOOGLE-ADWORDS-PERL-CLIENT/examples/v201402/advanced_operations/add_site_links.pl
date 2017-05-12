#!/usr/bin/perl -w
#
# Copyright 2013, Google Inc. All Rights Reserved.
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
# This example adds a sitelinks feed and associates it with a campaign.
#
# Tags: Tags: CampaignFeedService.mutate, FeedItemService.mutate, FeedMappingService.mutate
# Tags: FeedService.mutate
# Author: Josh Radcliff <api.jradcliff@gmail.com>

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201402::AttributeFieldMapping;
use Google::Ads::AdWords::v201402::CampaignFeed;
use Google::Ads::AdWords::v201402::CampaignFeedOperation;
use Google::Ads::AdWords::v201402::ConstantOperand;
use Google::Ads::AdWords::v201402::Feed;
use Google::Ads::AdWords::v201402::FeedAttribute;
use Google::Ads::AdWords::v201402::FeedItem;
use Google::Ads::AdWords::v201402::FeedItemAttributeValue;
use Google::Ads::AdWords::v201402::FeedItemOperation;
use Google::Ads::AdWords::v201402::FeedMapping;
use Google::Ads::AdWords::v201402::FeedMappingOperation;
use Google::Ads::AdWords::v201402::FeedOperation;
use Google::Ads::AdWords::v201402::Function;
use Google::Ads::AdWords::v201402::FunctionOperand;
use Google::Ads::AdWords::v201402::RequestContextOperand;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# See the Placeholder reference page for a list of all the placeholder types and
# fields.
# https://developers.google.com/adwords/api/docs/appendix/placeholders
use constant PLACEHOLDER_SITELINKS => 1;
use constant PLACEHOLDER_FIELD_SITELINK_LINK_TEXT => 1;
use constant PLACEHOLDER_FIELD_SITELINK_URL => 2;
use constant PLACEHOLDER_FIELD_SITELINK_LINE_1_TEXT => 3;
use constant PLACEHOLDER_FIELD_SITELINK_LINE_2_TEXT => 4;

# Replace with valid values of your account.
my $campaign_id = "INSERT_CAMPAIGN_ID_HERE";

# Example main subroutine.
sub add_site_links {
  my $client = shift;

  my $site_links_data = {
    "siteLinksFeedId" => 0,
    "linkTextFeedAttributeId" => 0,
    "linkUrlFeedAttributeId" => 0,
    "line1FeedAttributeId" => 0,
    "line2FeedAttributeId" => 0,
    "feedItemIds" => []
  };

  create_site_links_feed($client, $site_links_data);
  create_site_links_feed_items($client, $site_links_data);
  create_site_links_feed_mapping($client, $site_links_data);
  create_site_links_campaign_feed($client, $site_links_data, $campaign_id);

  return 1;
}

sub create_site_links_feed() {
  my ($client, $site_links_data) = @_;

  my $text_attribute = Google::Ads::AdWords::v201402::FeedAttribute->new({
    type => "STRING",
    name => "Link Text"
  });
  my $url_attribute = Google::Ads::AdWords::v201402::FeedAttribute->new({
    type => "URL",
    name => "Link URL"
  });
  my $line_1_attribute = Google::Ads::AdWords::v201402::FeedAttribute->new({
    type => "STRING",
    name => "Line 1 Description"
  });
  my $line_2_attribute = Google::Ads::AdWords::v201402::FeedAttribute->new({
    type => "STRING",
    name => "Line 2 Description"
  });
  my $feed = Google::Ads::AdWords::v201402::Feed->new({
    name => "Feed For Site Links " . uniqid(),
    attributes => [ $text_attribute, $url_attribute, $line_1_attribute,
        $line_2_attribute ],
    origin => "USER"
  });

  my $operation =
    Google::Ads::AdWords::v201402::FeedOperation->new({
      operator => "ADD",
      operand => $feed
  });

  my $feed_result = $client->FeedService()->mutate({
    operations => [ $operation ]
  });

  my $saved_feed = $feed_result->get_value(0);

  $site_links_data->{"siteLinksFeedId"} = $saved_feed->get_id();

  my $saved_attributes = $saved_feed->get_attributes();

  $site_links_data->{"linkTextFeedAttributeId"} = $saved_attributes->[0]->
    get_id();
  $site_links_data->{"linkUrlFeedAttributeId"} = $saved_attributes->[1]->
    get_id();
  $site_links_data->{"line1FeedAttributeId"} = $saved_attributes->[2]->
    get_id();
  $site_links_data->{"line2FeedAttributeId"} = $saved_attributes->[3]->
    get_id();
  printf("Feed with name '%s' and ID %d with linkTextAttributeId %d" .
        " and linkUrlAttributeId %d and line1AttributeId %d" .
        " and line2AttributeId %d was created.\n",
        $saved_feed->get_name(),
        $saved_feed->get_id(),
        $saved_attributes->[0]->get_id(),
        $saved_attributes->[1]->get_id(),
        $saved_attributes->[2]->get_id(),
        $saved_attributes->[3]->get_id()
  );
}

sub create_site_links_feed_items() {
  my ($client, $site_links_data) = @_;

  my @operations = ();

  push @operations, create_feed_item_add_operation($site_links_data,
    "Home", "http://www.example.com", "Home line 1", "Home line 2");
  push @operations, create_feed_item_add_operation(
    $site_links_data,
    "Stores", "http://www.example.com/stores", "Stores line 1",
    "Stores line 2");
  push @operations, create_feed_item_add_operation(
    $site_links_data,
    "On Sale", "http://www.example.com/sale", "On Sale line 1",
    "On Sale line 2");
  push @operations, create_feed_item_add_operation(
    $site_links_data,
    "Support", "http://www.example.com/support", "Support line 1",
    "Support line 2");
  push @operations, create_feed_item_add_operation(
    $site_links_data,
    "Products", "http://www.example.com/prods", "Products line 1",
    "Products line 2");
  push @operations, create_feed_item_add_operation(
    $site_links_data,
    "About Us", "http://www.example.com/about", "About Us line 1",
    "About Us line 2");

  my $result = $client->FeedItemService()->mutate({
    operations => \@operations
  });

  foreach my $feed_item (@{$result->get_value()}) {
    printf "FeedItem with feedItemId %d was added.\n",
      $feed_item->get_feedItemId();
    push $site_links_data->{"feedItemIds"}, $feed_item->get_feedItemId();
  }
}

sub create_feed_item_add_operation() {
  my ($site_links_data, $text, $url, $line_1, $line_2) = @_;

  my $text_attribute_value =
    Google::Ads::AdWords::v201402::FeedItemAttributeValue->new({
      feedAttributeId => $site_links_data->{"linkTextFeedAttributeId"},
      stringValue => $text
  });
  my $url_attribute_value =
    Google::Ads::AdWords::v201402::FeedItemAttributeValue->new({
      feedAttributeId => $site_links_data->{"linkUrlFeedAttributeId"},
      stringValue => $url
  });
  my $line_1_attribute_value =
    Google::Ads::AdWords::v201402::FeedItemAttributeValue->new({
      feedAttributeId => $site_links_data->{"line1FeedAttributeId"},
      stringValue => $line_1
  });
  my $line_2_attribute_value =
    Google::Ads::AdWords::v201402::FeedItemAttributeValue->new({
      feedAttributeId => $site_links_data->{"line2FeedAttributeId"},
      stringValue => $line_2
  });

  my $feed_item = Google::Ads::AdWords::v201402::FeedItem->new({
    feedId => $site_links_data->{"siteLinksFeedId"},
    attributeValues => [ $text_attribute_value, $url_attribute_value,
        $line_1_attribute_value, $line_2_attribute_value ]
  });

  my $operation = Google::Ads::AdWords::v201402::FeedItemOperation->new({
    operand => $feed_item,
    operator => "ADD"
  });

  return $operation;
}

sub create_site_links_feed_mapping() {
  my ($client, $site_links_data) = @_;

  # Map the FeedAttributeIds to the fieldId constants.
  my $text_field_mapping =
    Google::Ads::AdWords::v201402::AttributeFieldMapping->new({
      feedAttributeId => $site_links_data->{"linkTextFeedAttributeId"},
      fieldId => PLACEHOLDER_FIELD_SITELINK_LINK_TEXT
  });
  my $url_field_mapping =
    Google::Ads::AdWords::v201402::AttributeFieldMapping->new({
      feedAttributeId => $site_links_data->{"linkUrlFeedAttributeId"},
      fieldId => PLACEHOLDER_FIELD_SITELINK_URL
  });
  my $line_1_field_mapping =
    Google::Ads::AdWords::v201402::AttributeFieldMapping->new({
      feedAttributeId => $site_links_data->{"line1FeedAttributeId"},
      fieldId => PLACEHOLDER_FIELD_SITELINK_LINE_1_TEXT
  });
  my $line_2_field_mapping =
    Google::Ads::AdWords::v201402::AttributeFieldMapping->new({
      feedAttributeId => $site_links_data->{"line2FeedAttributeId"},
      fieldId => PLACEHOLDER_FIELD_SITELINK_LINE_2_TEXT
  });

  # Create the FeedMapping and operation.
  my $feed_mapping = Google::Ads::AdWords::v201402::FeedMapping->new({
    placeholderType => PLACEHOLDER_SITELINKS,
    feedId => $site_links_data->{"siteLinksFeedId"},
    attributeFieldMappings => [ $text_field_mapping, $url_field_mapping,
        $line_1_field_mapping, $line_2_field_mapping ]
  });

  my $operation = Google::Ads::AdWords::v201402::FeedMappingOperation->new({
    operand => $feed_mapping,
    operator => "ADD"
  });

  # Save the feed mapping.
  my $result = $client->FeedMappingService()->mutate({
    operations => [ $operation ]
  });

  foreach my $saved_feed_mapping (@{$result->get_value()}) {
    printf "Feed mapping with ID %d and placeholderType %d was saved for " .
      "feed with ID %d.\n", $saved_feed_mapping->get_feedMappingId(),
      $saved_feed_mapping->get_placeholderType(),
      $saved_feed_mapping->get_feedId();
  }
}

sub create_site_links_campaign_feed() {
  my ($client, $site_links_data, $campaign_id) = @_;

  my $request_context_operand =
    Google::Ads::AdWords::v201402::RequestContextOperand->new({
      contextType => "FEED_ITEM_ID"
  });

  my @feed_item_id_operands = ();
  foreach my $feed_item_id (@{$site_links_data->{"feedItemIds"}}) {
    push @feed_item_id_operands,
      Google::Ads::AdWords::v201402::ConstantOperand->new({
        longValue => $feed_item_id,
        type => "LONG"
      });
  }

  my $feed_item_function = Google::Ads::AdWords::v201402::Function->new({
    lhsOperand => [ $request_context_operand ],
    operator => "IN",
    rhsOperand => \@feed_item_id_operands
  });

  # Optional: to target to a platform, define a function and 'AND' it with
  # the feed item ID link:
  my $platform_request_context_operand =
    Google::Ads::AdWords::v201402::RequestContextOperand->new({
      contextType => "DEVICE_PLATFORM"
  });

  my $platform_operand = Google::Ads::AdWords::v201402::ConstantOperand->new({
    stringValue => "Mobile",
    type => "STRING"
  });

  my $platform_function = Google::Ads::AdWords::v201402::Function->new({
    lhsOperand => [ $platform_request_context_operand ],
    operator => "EQUALS",
    rhsOperand => [ $platform_operand ]
  });

  # Combine the two functions using an AND operation.
  my $feed_item_function_operand =
    Google::Ads::AdWords::v201402::FunctionOperand->new({
      value => $feed_item_function
  });

  my $platform_function_operand =
    Google::Ads::AdWords::v201402::FunctionOperand->new({
      value => $platform_function
  });

  my $combined_function = Google::Ads::AdWords::v201402::Function->new({
    lhsOperand => [ $feed_item_function_operand, $platform_function_operand ],
    operator => "AND"
  });

  my $campaign_feed = Google::Ads::AdWords::v201402::CampaignFeed->new({
    feedId => $site_links_data->{"siteLinksFeedId"},
    campaignId => $campaign_id,
    matchingFunction => $combined_function,
    # Specifying placeholder types on the CampaignFeed allows the same feed
    # to be used for different placeholders in different Campaigns.
    placeholderTypes => [ PLACEHOLDER_SITELINKS ]
  });

  my $result = $client->CampaignFeedService()->mutate({
    operations => [
      Google::Ads::AdWords::v201402::CampaignFeedOperation->new({
        operand => $campaign_feed,
        operator => "ADD"
      })
    ]
  });

  $campaign_feed = $result->get_value(0);

  printf "Campaign with ID %d was associated with feed with ID %d.\n",
    $campaign_feed->get_campaignId(), $campaign_feed->get_feedId();
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
add_site_links($client, $campaign_id);
