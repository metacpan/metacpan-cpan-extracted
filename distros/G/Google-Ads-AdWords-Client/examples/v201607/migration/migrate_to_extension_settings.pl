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
# This code example migrates your feed based sitelinks at campaign level to use
# extension settings.
# To learn more about extensionsettings, see
# https://developers.google.com/adwords/api/docs/guides/extension-settings.
# To learn more about migrating Feed based extensions to extension settings, see
# https://developers.google.com/adwords/api/docs/guides/migrate-to-extension-settings.

use strict;
use lib "../../../lib";

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201607::CampaignExtensionSetting;
use Google::Ads::AdWords::v201607::CampaignExtensionSettingOperation;
use Google::Ads::AdWords::v201607::CampaignFeedOperation;
use Google::Ads::AdWords::v201607::ExtensionSetting;
use Google::Ads::AdWords::v201607::ExtensionSetting::Platform;
use Google::Ads::AdWords::v201607::FeedItem;
use Google::Ads::AdWords::v201607::FeedItemOperation;
use Google::Ads::AdWords::v201607::SitelinkFeedItem;
use Google::Ads::AdWords::v201607::UrlList;
use Google::Ads::AdWords::Utilities::PageProcessor;

use constant PAGE_SIZE => 500;

use Cwd qw(abs_path);

# See the Placeholder reference page for a list of all the placeholder types and
# fields.
# https://developers.google.com/adwords/api/docs/appendix/placeholders
use constant PLACEHOLDER_SITELINKS                        => 1;
use constant PLACEHOLDER_FIELD_SITELINK_LINK_TEXT         => 1;
use constant PLACEHOLDER_FIELD_SITELINK_URL               => 2;
use constant PLACEHOLDER_FIELD_SITELINK_FINAL_URLS        => 5;
use constant PLACEHOLDER_FIELD_SITELINK_FINAL_MOBILE_URLS => 6;
use constant PLACEHOLDER_FIELD_SITELINK_TRACKING_TEMPLATE => 7;
use constant PLACEHOLDER_FIELD_SITELINK_LINE_1_TEXT       => 3;
use constant PLACEHOLDER_FIELD_SITELINK_LINE_2_TEXT       => 4;

# Example main subroutine.
sub migrate_to_extension_settings {
  my ($client) = @_;

  # Get all of the feeds for the client's account.
  my $feeds = get_feeds($client);

  foreach my $feed (@{$feeds}) {
    # Retrieve all the sitelinks from the current feed.
    my $feed_items = get_sitelinks_from_feed($client, $feed);

    # Get all the instances where a sitelink from this feed has been added to
    # a campaign.
    my $campaign_feeds =
      get_campaign_feeds($client, $feed, PLACEHOLDER_SITELINKS);

    my @all_feed_items_to_delete = ();
    foreach my $campaign_feed (@{$campaign_feeds}) {
      # Retrieve the sitelinks that have been associated with this campaign.
      my $feed_item_ids =
        get_feed_item_ids_for_campaign($client, $campaign_feed);
      my $platform_restriction =
        get_platform_restrictions_for_campaign($campaign_feed);

      if (@{$feed_item_ids}) {
        # Delete the campaign feed that associates the sitelinks from the feed
        # to the campaign.
        delete_campaign_feed($client, $campaign_feed);

        # Create extension settings instead of sitelinks.
        create_extension_setting($client, $feed_items, $campaign_feed,
          $feed_item_ids, $platform_restriction);

        # Mark the sitelinks from the feed for deletion.
        push @all_feed_items_to_delete, @{$feed_item_ids};
      } else {
        printf "Migration skipped for campaign feed with campaign ID %d " .
          "and feed ID %d because no mapped feed item IDs were found in " .
          "the campaign feed's matching function.\n",
          $campaign_feed->get_campaignId(),
          $campaign_feed->get_feedId();
      }
    }

    # Delete all the sitelinks from the feed.
    delete_old_feed_items($client, \@all_feed_items_to_delete, $feed);

    printf "Finished processing feed ID %d.\n", $feed->get_id();
  }
}

# Returns a list of all enabled feeds.
sub get_feeds() {
  my ($client) = @_;

  my $query =
    "SELECT Id, Name, Attributes WHERE Origin = 'USER' AND " .
    "FeedStatus = 'ENABLED'";

  # Paginate through results automatically, and retrieve the feeds.
  my @feeds = Google::Ads::AdWords::Utilities::PageProcessor->new({
      client    => $client,
      service   => $client->FeedService(),
      query     => $query,
      page_size => PAGE_SIZE
    })->get_entries();

  return \@feeds;
}

# Returns a dictionary of feed item ID to a list where each element is a
# dictionary of attribute name/value pairs representing a single sitelink
# feed item.
sub get_sitelinks_from_feed() {
  my ($client, $feed) = @_;

  my $feed_attribute_mappings =
    get_feed_mapping_attributes($client, $feed, PLACEHOLDER_SITELINKS);

  my $feed_items_by_id = {};
  foreach my $feed_item (@{get_feed_items($client, $feed)}) {
    my $attributes = {};

    foreach my $attribute_value (@{$feed_item->get_attributeValues()}) {
      my $field_ids =
        $feed_attribute_mappings->{$attribute_value->get_feedAttributeId()};

      if ($field_ids) {
        foreach my $field_id (@{$field_ids}) {
          if ($field_id == PLACEHOLDER_FIELD_SITELINK_LINK_TEXT) {
            $attributes->{'text'} = $attribute_value->get_stringValue();
          } elsif ($field_id == PLACEHOLDER_FIELD_SITELINK_URL) {
            $attributes->{'url'} = $attribute_value->get_stringValue();
          } elsif ($field_id == PLACEHOLDER_FIELD_SITELINK_FINAL_URLS) {
            $attributes->{'final_urls'} = $attribute_value->get_stringValues();
          } elsif ($field_id == PLACEHOLDER_FIELD_SITELINK_FINAL_MOBILE_URLS) {
            $attributes->{'final_mobile_urls'} =
              $attribute_value->get_stringValue();
          } elsif ($field_id == PLACEHOLDER_FIELD_SITELINK_TRACKING_TEMPLATE) {
            $attributes->{'tracking_url_template'} =
              $attribute_value->get_stringValue();
          } elsif ($field_id == PLACEHOLDER_FIELD_SITELINK_LINE_1_TEXT) {
            $attributes->{'line_1'} = $attribute_value->get_stringValue();
          } elsif ($field_id == PLACEHOLDER_FIELD_SITELINK_LINE_2_TEXT) {
            $attributes->{'line_2'} = $attribute_value->get_stringValue();
          }
        }
      }
    }
    if ($feed_item->get_scheduling()) {
      $attributes->{'scheduling'} = $feed_item->get_scheduling();
    }

    $feed_items_by_id->{$feed_item->get_feedItemId()} = $attributes;
  }

  return $feed_items_by_id;
}

# Returns a map from feed attribute ID to the set of field IDs mapped to the
# attribute.
sub get_feed_mapping_attributes() {
  my ($client, $feed, $placeholder_type) = @_;

  my $query =
    sprintf "SELECT FeedMappingId, AttributeFieldMappings " .
    "WHERE FeedId = %d and PlaceholderType = %d " . "AND Status = 'ENABLED'",
    $feed->get_id(), $placeholder_type;

  # Paginate through results.
  # The contents of the subroutine will be executed for each feed mapping.
  # The attribute mappings hash is being passed as an argument to the
  # subroutine in order to populate it.
  my %attribute_mappings;
  Google::Ads::AdWords::Utilities::PageProcessor->new({
      client    => $client,
      service   => $client->FeedMappingService(),
      query     => $query,
      page_size => PAGE_SIZE
    }
    )->process_entries(
    # Normally, a feed attribute is mapped only to one field. However, you may
    # map it to more than one field if needed.
    sub {
      my ($feed_mapping) = @_;
      my @attributes = @{$feed_mapping->get_attributeFieldMappings()};
      foreach my $attribute_mapping (@attributes) {
        my $attribute_id = $attribute_mapping->get_feedAttributeId();
        if (!$attribute_mappings{$attribute_id}) {
          $attribute_mappings{$attribute_id} = [];
        }
        push $attribute_mappings{$attribute_id},
          $attribute_mapping->get_fieldId();
      }
    },
    );

  return \%attribute_mappings;
}

# Returns the feed items for a feed.
sub get_feed_items() {
  my ($client, $feed) = @_;

  my $query =
    sprintf "SELECT FeedItemId, AttributeValues, Scheduling " .
    "WHERE Status = 'ENABLED' AND FeedId = %d",
    $feed->get_id();

  # Paginate through results automatically, and retrieve the feed items.
  my @feed_items = Google::Ads::AdWords::Utilities::PageProcessor->new({
      client    => $client,
      service   => $client->FeedItemService(),
      query     => $query,
      page_size => PAGE_SIZE
    })->get_entries();

  return \@feed_items;
}

# Returns the campaign feeds that use a particular feed for a particular
# placeholder type.
sub get_campaign_feeds() {
  my ($client, $feed, $placeholder_type) = @_;

  my $query =
    sprintf "SELECT CampaignId, MatchingFunction, PlaceholderTypes " .
    "WHERE Status = 'ENABLED' AND FeedId = %d AND " .
    "PlaceholderTypes CONTAINS_ANY [%d]",
    $feed->get_id(), $placeholder_type;

  # Paginate through results automatically, and retrieve the campaign feeds.
  my @campaign_feeds = Google::Ads::AdWords::Utilities::PageProcessor->new({
      client    => $client,
      service   => $client->CampaignFeedService(),
      query     => $query,
      page_size => PAGE_SIZE
    })->get_entries();

  return \@campaign_feeds;
}

# Returns platform restrictions for site links in a campaign.
sub get_platform_restrictions_for_campaign() {
  my ($campaign_feed) = @_;

  # If the campaign feed has multiple arguments joined with AND in the matching
  # function, then iterate through each of the arguments looking for
  # something similar to EQUALS(CONTEXT.DEVICE, 'Mobile').
  my $matching_function = $campaign_feed->get_matchingFunction();
  if ($matching_function->get_operator() eq 'AND') {
    foreach my $argument (@{$matching_function->get_lhsOperand()}) {
      if ( $argument->isa("Google::Ads::AdWords::v201607::FunctionOperand")
        && $argument->get_value()->get_operator() eq 'EQUALS')
      {
        my $lhs_operand = $argument->get_value()->get_lhsOperand()->[0];
        if (
          $lhs_operand->isa(
            "Google::Ads::AdWords::v201607::RequestContextOperand")
          && $lhs_operand->get_contextType() eq 'DEVICE_PLATFORM'
          )
        {
          my $platformRestriction =
            $argument->get_value()->get_rhsOperand()->[0]->get_stringValue();
          return Google::Ads::AdWords::v201607::ExtensionSetting::Platform->new(
            {value => uc $platformRestriction});
        }
      }
    }
  }
  return Google::Ads::AdWords::v201607::ExtensionSetting::Platform->new(
    {value => 'NONE'});
}

# Returns the list of feed item IDs that are used by a campaign through a given
# campaign feed.
sub get_feed_item_ids_for_campaign() {
  my ($client, $campaign_feed) = @_;

  my @feed_item_ids = ();

  my $matching_function = $campaign_feed->get_matchingFunction();
  my $operator          = $matching_function->get_operator();

  if ($operator eq 'IN') {
    # Check if matchingFunction is of the form IN(FEED_ITEM_ID,{xxx,xxx}).
    push @feed_item_ids,
      @{get_feed_items_from_argument($campaign_feed->get_matchingFunction())};
  } elsif ($operator eq 'AND') {
    foreach my $argument (@{$matching_function->get_lhsOperand()}) {
      # Check if matchingFunction is of the form IN(FEED_ITEM_ID,{xxx,xxx}).
      if ( $argument->isa("Google::Ads::AdWords::v201607::FunctionOperand")
        && $argument->get_value()->get_operator() eq 'IN')
      {
        push @feed_item_ids,
          @{get_feed_items_from_argument($argument->get_value())};
      }
    }
  }
  return \@feed_item_ids;
}

# Returns an array of feed item ids for a specified Function.
sub get_feed_items_from_argument() {
  my ($function) = @_;

  my @feed_item_ids = ();

  my $lhs_operand      = $function->get_lhsOperand();
  my $lhs_operand_size = @{$lhs_operand};
  if ( $lhs_operand_size == 1
    && $lhs_operand->[0]
    ->isa("Google::Ads::AdWords::v201607::RequestContextOperand")
    && $lhs_operand->get_contextType eq 'FEED_ITEM_ID')
  {

    foreach my $argument (@{$function->get_rhsOperand()}) {
      push @feed_item_ids, $argument->get_longValue();
    }
  }

  return \@feed_item_ids;
}

# Deletes a campaign feed.
sub delete_campaign_feed() {
  my ($client, $campaign_feed) = @_;

  my $result = $client->CampaignFeedService()->mutate({
      operations => [
        Google::Ads::AdWords::v201607::CampaignFeedOperation->new({
            operand  => $campaign_feed,
            operator => 'REMOVE'
          })]});

  printf "Deleted campaign feed for campaign ID %d and feed ID %d.\n",
    $campaign_feed->get_campaignId(), $campaign_feed->get_feedId();
  return $result->get_value(0);
}

# Creates the extension setting for a list of feed items.
sub create_extension_setting() {
  my ($client, $feed_items, $campaign_feed, $feed_item_ids,
    $platform_restriction)
    = @_;

  my $campaign_extension_setting =
    Google::Ads::AdWords::v201607::CampaignExtensionSetting->new({
      campaignId    => $campaign_feed->get_campaignId(),
      extensionType => 'SITELINK'
    });

  my @extension_feed_items = ();

  foreach my $feed_item_id (@{$feed_item_ids}) {
    my $item_attributes = $feed_items->{$feed_item_id};

    my $sitelink_feed_item =
      Google::Ads::AdWords::v201607::SitelinkFeedItem->new({
        sitelinkText  => $item_attributes->{'text'},
        sitelinkLine2 => $item_attributes->{'line_1'},
        sitelinkLine3 => $item_attributes->{'line_2'}});

    if ($item_attributes->{'final_urls'}) {
      $sitelink_feed_item->set_sitelinkFinalUrls(
        Google::Ads::AdWords::v201607::UrlList->new(
          {urls => $item_attributes->{'final_urls'}}));
      if ($item_attributes->{'final_mobile_urls'}) {
        $sitelink_feed_item->set_sitelinkFinalMobileUrls(
          Google::Ads::AdWords::v201607::UrlList->new(
            {urls => $item_attributes->{'final_mobile_urls'}}));
      }
      if ($item_attributes->{'tracking_url_template'}) {
        $sitelink_feed_item->set_trackingUrlTemplate(
          $item_attributes->{'tracking_url_template'});
      }
    } else {
      $sitelink_feed_item->set_sitelinkUrl($item_attributes->{'url'});
    }

    if ($item_attributes->{'scheduling'}) {
      $sitelink_feed_item->set_scheduling($item_attributes->{'scheduling'});
    }

    push @extension_feed_items, $sitelink_feed_item;
  }

  $campaign_extension_setting->set_extensionSetting(
    Google::Ads::AdWords::v201607::ExtensionSetting->new({
        extensions           => \@extension_feed_items,
        platformRestrictions => $platform_restriction
      }));

  my $result = $client->CampaignExtensionSettingService()->mutate({
      operations => [
        Google::Ads::AdWords::v201607::CampaignExtensionSettingOperation->new({
            operand  => $campaign_extension_setting,
            operator => 'ADD'
          })]});

  printf "Created extension setting for campaign ID %d.\n",
    $campaign_feed->get_campaignId();
  return $result->get_value(0);
}

# Deletes the old feed items for which extension settings have been created.
sub delete_old_feed_items() {
  my ($client, $feed_item_ids, $feed) = @_;

  if (!@{$feed_item_ids}) {
    printf "No old feed items to delete for feed ID %d.\n", $feed->get_id();
    return;
  }

  my @operations = ();
  foreach my $feed_item_id (@{$feed_item_ids}) {
    push @operations,
      Google::Ads::AdWords::v201607::FeedItemOperation->new({
        operator => 'REMOVE',
        operand  => Google::Ads::AdWords::v201607::FeedItem->new({
            feedId     => $feed->get_id(),
            feedItemId => $feed_item_id
          })});
  }

  my $result = $client->FeedItemService()->mutate({operations => \@operations});

  my $number_of_operations = @{$result->get_value()};
  printf "Deleted %d old feed items from feed ID %d.\n",
    $number_of_operations, $feed->get_id();
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
migrate_to_extension_settings($client);
