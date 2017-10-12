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
# This example adds a prices feed and associates it with a campaign.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201710::CustomerExtensionSetting;
use Google::Ads::AdWords::v201710::CustomerExtensionSettingOperation;
use Google::Ads::AdWords::v201710::FeedItemCampaignTargeting;
use Google::Ads::AdWords::v201710::FeedItemSchedule;
use Google::Ads::AdWords::v201710::FeedItemScheduling;
use Google::Ads::AdWords::v201710::Keyword;
use Google::Ads::AdWords::v201710::Location;
use Google::Ads::AdWords::v201710::Money;
use Google::Ads::AdWords::v201710::MoneyWithCurrency;
use Google::Ads::AdWords::v201710::PriceFeedItem;
use Google::Ads::AdWords::v201710::PriceTableRow;
use Google::Ads::AdWords::v201710::UrlList;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $campaign_id = "INSERT_CAMPAIGN_ID_HERE";

# Example main subroutine.
sub add_prices {
  my ($client, $campaign_id) = @_;

  # Create the price extension feed item.
  my $price_feed_item = Google::Ads::AdWords::v201710::PriceFeedItem->new({
      priceExtensionType => "SERVICES",
      # Price qualifer is optional.
      priceQualifier      => "FROM",
      trackingUrlTemplate => "http://tracker.example.com/?u={lpurl}",
      language            => 'en',
      campaignTargeting =>
        Google::Ads::AdWords::v201710::FeedItemCampaignTargeting->new({
          TargetingCampaignId => $campaign_id
        }
        ),
      scheduling => Google::Ads::AdWords::v201710::FeedItemScheduling->new({
          feedItemSchedules => [
            Google::Ads::AdWords::v201710::FeedItemSchedule->new({
                dayOfWeek   => "SUNDAY",
                startHour   => "10",
                startMinute => "ZERO",
                endHour     => "18",
                endMinute   => "ZERO"
              }
            ),
            Google::Ads::AdWords::v201710::FeedItemSchedule->new({
                dayOfWeek   => "SATURDAY",
                startHour   => "10",
                startMinute => "ZERO",
                endHour     => "22",
                endMinute   => "ZERO"
              })]})});

  # To create a price extension, at least three table rows are needed.
  my @table_rows = ();
  push @table_rows, create_price_table_row(
    "Scrubs",
    "Body Scrub, Salt Scrub",
    "http://www.example.com/scrubs",
    "http://m.example.com/scrubs",
    60000000,    # 60 USD
    "USD",
    "PER_HOUR"
  );
  push @table_rows, create_price_table_row(
    "Hair Cuts",
    "Once a month",
    "http://www.example.com/haircuts",
    "http://m.example.com/haircuts",
    75000000,    # 75 USD
    "USD",
    "PER_MONTH"
  );
  push @table_rows, create_price_table_row(
    "Skin Care Package",
    "Four times a month",
    "http://www.example.com/skincarepackage",
    undef,
    250000000,    # 250 USD
    "USD",
    "PER_MONTH"
  );
  $price_feed_item->set_tableRows(\@table_rows);

  # Create your customer extension settings. This associates the price
  # extension to your account.
  my $customer_extension_setting =
    Google::Ads::AdWords::v201710::CustomerExtensionSetting->new({
      extensionType    => 'PRICE',
      extensionSetting => Google::Ads::AdWords::v201710::ExtensionSetting->new({
          extensions => [$price_feed_item]})});

  my $mutate_result = $client->CustomerExtensionSettingService()->mutate({
      operations => [
        Google::Ads::AdWords::v201710::CustomerExtensionSettingOperation->new({
            operand  => $customer_extension_setting,
            operator => 'ADD'
          })]});

  my $new_extension_setting = $mutate_result->get_value(0);

  printf "Extension setting with type '%s' was added to your account.\n",
    $new_extension_setting->get_extensionType();
  return 1;
}

# Creates a new price table row with the specified attributes.
sub create_price_table_row {
  my ($header, $description, $final_url, $final_mobile_url, $price_in_micros,
    $currency_code, $price_unit)
    = @_;
  my $price_table_row = Google::Ads::AdWords::v201710::PriceTableRow->new({
      header      => $header,
      description => $description,
      finalUrls =>
        [Google::Ads::AdWords::v201710::UrlList->new({urls => [$final_url]})],
      price => Google::Ads::AdWords::v201710::MoneyWithCurrency->new({
          money => Google::Ads::AdWords::v201710::Money->new({
              microAmount => $price_in_micros
            }
          ),
          currencyCode => $currency_code
        }
      ),
      priceUnit => $price_unit
    });

  # Optional: set the mobile final URLs.
  if ($final_mobile_url) {
    $price_table_row->set_finalMobileUrls([
        Google::Ads::AdWords::v201710::UrlList->new(
          {urls => [$final_mobile_url]})]);
  }

  return $price_table_row;
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
add_prices($client, $campaign_id);

