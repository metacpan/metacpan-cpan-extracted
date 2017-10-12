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
# This example adds an ad customizer feed, and then adds an ad in two different
# ad groups that uses the feed to populate dynamic data.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201710::AdCustomizerFeed;
use Google::Ads::AdWords::v201710::AdCustomizerFeedAttribute;
use Google::Ads::AdWords::v201710::AdCustomizerFeedOperation;
use Google::Ads::AdWords::v201710::AdGroupAd;
use Google::Ads::AdWords::v201710::AdGroupAdOperation;
use Google::Ads::AdWords::v201710::ConstantOperand;
use Google::Ads::AdWords::v201710::ExpandedTextAd;
use Google::Ads::AdWords::v201710::Feed;
use Google::Ads::AdWords::v201710::FeedAttribute;
use Google::Ads::AdWords::v201710::FeedItem;
use Google::Ads::AdWords::v201710::FeedItemAdGroupTargeting;
use Google::Ads::AdWords::v201710::FeedItemAttributeValue;
use Google::Ads::AdWords::v201710::FeedItemOperation;
use Google::Ads::AdWords::v201710::Function;
use Google::Ads::AdWords::v201710::FunctionOperand;
use Google::Ads::AdWords::v201710::RequestContextOperand;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $ad_group_ids = ["INSERT_ADGROUP_ID_HERE", "INSERT_ADGROUP_ID_HERE"];
my $feed_name = "INSERT_FEED_NAME_HERE";

# Example main subroutine.
sub add_ad_customizers {
  my $client = shift;

  my $ad_group_ids = shift;

  my $feed_name = shift;

  # Create a customizer feed. One feed per account can be used for all ads.
  my $ad_customizer_feed = create_customizer_feed($client, $feed_name);

  # Add feed items containing the values we'd like to place in ads.
  create_customizer_feed_items($client, $ad_customizer_feed, $ad_group_ids);

  # All set! We can now create ads with customizations.
  create_ads_with_customizations($client, $ad_group_ids, $feed_name);

  return 1;
}

sub create_customizer_feed {
  my ($client, $feed_name) = @_;

  my $name_attribute =
    Google::Ads::AdWords::v201710::AdCustomizerFeedAttribute->new({
      type => "STRING",
      name => "Name"
    });
  my $price_attribute =
    Google::Ads::AdWords::v201710::AdCustomizerFeedAttribute->new({
      type => "STRING",
      name => "Price"
    });
  my $date_attribute =
    Google::Ads::AdWords::v201710::AdCustomizerFeedAttribute->new({
      type => "DATE_TIME",
      name => "Date"
    });
  my $ad_customizer_feed = Google::Ads::AdWords::v201710::AdCustomizerFeed->new(
    {
      feedName       => $feed_name,
      feedAttributes => [$name_attribute, $price_attribute, $date_attribute]});

  my $operation = Google::Ads::AdWords::v201710::AdCustomizerFeedOperation->new(
    {
      operator => "ADD",
      operand  => $ad_customizer_feed
    });

  my $feed_result =
    $client->AdCustomizerFeedService()->mutate({operations => [$operation]});

  my $added_feed = $feed_result->get_value(0);

  printf(
    "Created ad customizer feed with ID %d, and name '%s' and attributes:\n",
    $added_feed->get_feedId(),
    $added_feed->get_feedName());
  foreach my $feed_attribute ($added_feed->get_feedAttributes()) {
    printf "  ID: %d, name: '%s', type: '%s'\n",
      $feed_attribute->get_id(), $feed_attribute->get_name(),
      $feed_attribute->get_type();
  }

  return $added_feed;
}

sub create_customizer_feed_items {
  my ($client, $ad_customizer_feed, $ad_group_ids) = @_;

  my @operations = ();

  push @operations,
    create_feed_item_add_operation($ad_customizer_feed,
    "Mars", "\$1234.56", "20140601 000000",
    $ad_group_ids->[0]);
  push @operations,
    create_feed_item_add_operation($ad_customizer_feed,
    "Venus", "\$1450.00", "20140615 120000",
    $ad_group_ids->[1]);

  my $result = $client->FeedItemService()->mutate({operations => \@operations});

  foreach my $feed_item (@{$result->get_value()}) {
    printf "FeedItem with feedItemId %d was added.\n",
      $feed_item->get_feedItemId();
  }
}

sub create_feed_item_add_operation {
  my ($ad_customizer_feed, $name, $price, $date, $ad_group_id) = @_;

  my $name_attribute_value =
    Google::Ads::AdWords::v201710::FeedItemAttributeValue->new({
      feedAttributeId =>
        $ad_customizer_feed->get_feedAttributes()->[0]->get_id(),
      stringValue => $name
    });
  my $price_attribute_value =
    Google::Ads::AdWords::v201710::FeedItemAttributeValue->new({
      feedAttributeId =>
        $ad_customizer_feed->get_feedAttributes()->[1]->get_id(),
      stringValue => $price
    });
  my $date_attribute_value =
    Google::Ads::AdWords::v201710::FeedItemAttributeValue->new({
      feedAttributeId =>
        $ad_customizer_feed->get_feedAttributes()->[2]->get_id(),
      stringValue => $date
    });

  my $feed_item = Google::Ads::AdWords::v201710::FeedItem->new({
      feedId => $ad_customizer_feed->get_feedId(),
      attributeValues =>
        [$name_attribute_value, $price_attribute_value, $date_attribute_value],
      adGroupTargeting =>
        Google::Ads::AdWords::v201710::FeedItemAdGroupTargeting->new(
        {TargetingAdGroupId => $ad_group_id})});

  my $operation = Google::Ads::AdWords::v201710::FeedItemOperation->new({
    operand  => $feed_item,
    operator => "ADD"
  });

  return $operation;
}

sub create_ads_with_customizations {
  my ($client, $ad_group_ids, $feed_name) = @_;

  my $text_ad = Google::Ads::AdWords::v201710::ExpandedTextAd->new({
      headlinePart1 => sprintf("Luxury Cruise to {=%s.Name}", $feed_name),
      headlinePart2 => sprintf("Only {=%s.Price}",            $feed_name),
      description =>
        sprintf("Offer ends in {=countdown(%s.Date)}!", $feed_name),
      finalUrls => ['http://www.example.com']});

  # We add the same ad to both ad groups. When they serve, they will show
  # different values, since they match different feed items.
  my @operations = ();

  foreach my $ad_group_id (@{$ad_group_ids}) {
    push @operations,
      Google::Ads::AdWords::v201710::AdGroupAdOperation->new({
        operator => "ADD",
        operand  => Google::Ads::AdWords::v201710::AdGroupAd->new({
            adGroupId => $ad_group_id,
            ad        => $text_ad
          })});
  }

  my $result =
    $client->AdGroupAdService()->mutate({operations => \@operations});

  foreach my $ad_group_ad (@{$result->get_value()}) {
    printf "Created an ad with ID %d, type '%s', and status '%s'.\n",
      $ad_group_ad->get_ad()->get_id(), $ad_group_ad->get_ad()->get_Ad__Type(),
      $ad_group_ad->get_status();
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
add_ad_customizers($client, $ad_group_ids, $feed_name);
