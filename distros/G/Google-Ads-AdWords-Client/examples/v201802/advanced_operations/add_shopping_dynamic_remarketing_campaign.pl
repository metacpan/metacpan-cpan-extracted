#!/usr/bin/perl -w
#
# Copyright 2018, Google Inc. All Rights Reserved.
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
#
# This example adds a Shopping dynamic remarketing campaign for the Display
# Network via the following steps:
# * Creates a new Display Network campaign.
# * Links the campaign with Merchant Center.
# * Links the user list to the ad group.
# * Creates a responsive display ad to render the dynamic text.

use strict;
use lib "../../../lib";
use utf8;

use Google::Ads::AdWords::Client;
use Google::Ads::AdWords::Logging;
use Google::Ads::AdWords::v201802::AdGroup;
use Google::Ads::AdWords::v201802::AdGroupOperation;
use Google::Ads::AdWords::v201802::AdGroupAd;
use Google::Ads::AdWords::v201802::AdGroupAdOperation;
use Google::Ads::AdWords::v201802::AdGroupCriterionOperation;
use Google::Ads::AdWords::v201802::BiddableAdGroupCriterion;
use Google::Ads::AdWords::v201802::BiddingStrategyConfiguration;
use Google::Ads::AdWords::v201802::Budget;
use Google::Ads::AdWords::v201802::Campaign;
use Google::Ads::AdWords::v201802::CampaignOperation;
use Google::Ads::AdWords::v201802::CriterionUserList;
use Google::Ads::AdWords::v201802::DynamicSettings;
use Google::Ads::AdWords::v201802::Image;
use Google::Ads::AdWords::v201802::ResponsiveDisplayAd;
use Google::Ads::AdWords::v201802::ShoppingSetting;
use Google::Ads::Common::MediaUtils;

use Cwd qw(abs_path);
use Data::Uniqid qw(uniqid);

# Replace with valid values of your account.
my $budget_id    = "INSERT_BUDGET_ID_HERE";
my $merchant_id  = "INSERT_MERCHANT_ID_HERE";
my $user_list_id = "INSERT_USER_LIST_ID_HERE";

# Example main subroutine.
sub add_shopping_dynamic_remarketing_campaign {
  my ($client, $merchant_id, $budget_id, $user_list_id) = @_;

  my $campaign = _create_campaign($client, $merchant_id, $budget_id);
  printf("Campaign with name '%s' and ID %d was added.\n",
    $campaign->get_name(), $campaign->get_id());

  my $ad_group = _create_ad_group($client, $campaign);
  printf("Ad group with name '%s' and ID %d was added.\n",
    $ad_group->get_name(), $ad_group->get_id());

  my $ad_group_ad = _create_ad($client, $ad_group);
  printf("Responsive display ad with ID %d was added.\n",
    $ad_group_ad->get_ad()->get_id());

  _attach_user_list($client, $ad_group, $user_list_id);
  printf("User list with ID %d was attached to ad group with ID %d.\n",
    $user_list_id, $ad_group->get_id());

  return 1;
}

# Creates a Shopping dynamic remarketing campaign object (not including ad
# group level and below). This creates a Display campaign with the merchant
# center feed attached. Merchant Center is used for the product information in
# combination with a user list which contains hits with ecomm_prodid specified.
# See https://developers.google.com/adwords-remarketing-tag/parameters#retail"
# for more detail.
sub _create_campaign {
  my ($client, $merchant_id, $budget_id) = @_;

  my $campaign = Google::Ads::AdWords::v201802::Campaign->new({
      name => sprintf("Shopping campaign #%s", uniqid()),
      # Dynamic remarketing campaigns are only available on the Google Display
      # Network.
      advertisingChannelType => "DISPLAY",
      status                 => "PAUSED",
      budget =>
        Google::Ads::AdWords::v201802::Budget->new({budgetId => $budget_id}),
      # This example uses a Manual CPC bidding strategy, but you should select
      # the strategy that best aligns with your sales goals. More details here:
      # https://support.google.com/adwords/answer/2472725
      biddingStrategyConfiguration =>
        Google::Ads::AdWords::v201802::BiddingStrategyConfiguration->new({
          biddingStrategyType => "MANUAL_CPC"
        }
        ),
      settings => [
        Google::Ads::AdWords::v201802::ShoppingSetting->new({
            # Campaigns with numerically higher priorities take precedence over
            # those with lower priorities.
            campaignPriority => 0,
            # Set the Merchant Center account ID from which to source products.
            merchantId => $merchant_id,
            # Display Network campaigns do not support partition by country.
            # The only supported value is "ZZ". This signals that products
            # from all countries are available in the campaign. The actual
            # products which serve are based on the products tagged in the user
            # list entry.
            salesCountry => "ZZ",
            # Optional: Enable local inventory ads (items for sale in physical
            # stores.)
            enableLocal => 1,
            # Optional: Declare whether purchases are only made on the merchant
            # store, or completed on Google.
            purchasePlatform => "MERCHANT"
          })
      ],
    });

  # Create operation.
  my $campaign_operation =
    Google::Ads::AdWords::v201802::CampaignOperation->new({
      operator => "ADD",
      operand  => $campaign
    });

  my $result =
    $client->CampaignService()->mutate({operations => [$campaign_operation]});
  return $result->get_value()->[0];
}

# Creates an ad group in the specified campaign.
sub _create_ad_group {
  my ($client, $campaign) = @_;

  my $ad_group = Google::Ads::AdWords::v201802::AdGroup->new({
    name       => sprintf("Dynamic remarketing ad group"),
    campaignId => $campaign->get_id(),
    status     => "ENABLED"
  });

  my $ad_group_operation =
    Google::Ads::AdWords::v201802::AdGroupOperation->new({
      operator => "ADD",
      operand  => $ad_group
    });

  my $result =
    $client->AdGroupService()->mutate({operations => [$ad_group_operation]});
  return $result->get_value()->[0];
}

# Attach a user list to an ad group. The user list provides positive targeting
# and feed information to drive the dynamic content of the ad.
# Note: User lists must be attached at the ad group level for positive
# targeting in Shopping dynamic remarketing campaigns.
sub _attach_user_list {
  my ($client, $ad_group, $user_list_id) = @_;

  my $user_list = Google::Ads::AdWords::v201802::CriterionUserList->new({
    userListId => $user_list_id
  });

  my $ad_group_criterion =
    Google::Ads::AdWords::v201802::BiddableAdGroupCriterion->new({
      adGroupId => $ad_group->get_id(),
      criterion => $user_list
    });

  my $operation = Google::Ads::AdWords::v201802::AdGroupCriterionOperation->new(
    {
      operand  => $ad_group_criterion,
      operator => "ADD"
    });
  $client->AdGroupCriterionService()->mutate({operations => [$operation]});
}

# Creates an ad for serving dynamic content in a remarketing campaign.
sub _create_ad {
  my ($client, $ad_group) = @_;

  # This ad format does not allow the creation of an image using the
  # Image.data field. An image must first be created using the MediaService,
  # and Image.mediaId must be populated when creating the ad.
  my $ad_image = _upload_image($client, "https://goo.gl/3b9Wfh");
  my $marketing_image = Google::Ads::AdWords::v201802::Image->new(
    {mediaId => $ad_image->get_mediaId()});

  # Create the responsive display ad.
  my $responsive_display_ad =
    Google::Ads::AdWords::v201802::ResponsiveDisplayAd->new({
      marketingImage => $marketing_image,
      shortHeadline  => "Travel",
      longHeadline   => "Travel the World",
      description    => "Take to the air!",
      businessName   => "Interplanetary Cruises",
      finalUrls      => ["http://www.example.com/"]});

  # Optional: Call to action text.
  # Valid texts: https://support.google.com/adwords/answer/7005917
  $responsive_display_ad->set_callToActionText("Apply Now");

  # Optional: Set dynamic display ad settings, composed of landscape logo
  # image, promotion text, and price prefix.
  my $dynamic_settings = _create_dynamic_display_ad_settings($client);
  $responsive_display_ad->set_dynamicDisplayAdSettings($dynamic_settings);

  # Optional: Create a logo image and set it to the ad.
  my $logo_image = _upload_image($client, "https://goo.gl/mtt54n");
  my $logo_marketing_image = Google::Ads::AdWords::v201802::Image->new(
    {mediaId => $logo_image->get_mediaId()});
  $responsive_display_ad->set_logoImage($logo_marketing_image);

  # Optional: Create a square marketing image and set it to the ad.
  my $square_image = _upload_image($client, "https://goo.gl/mtt54n");
  my $square_marketing_image = Google::Ads::AdWords::v201802::Image->new(
    {mediaId => $square_image->get_mediaId()});
  $responsive_display_ad->set_squareMarketingImage($square_marketing_image);

  # Whitelisted accounts only: Set color settings using hexadecimal values.
  # Set allowFlexibleColor to false if you want your ads to render by always
  # using your colors strictly.
  # $responsiveDisplayAd->set_mainColor("#0000ff");
  # $responsiveDisplayAd->set_accentColor("#ffff00");
  # $responsiveDisplayAd->set_allowFlexibleColor(0);

  # Whitelisted accounts only: Set the format setting that the ad will be
  # served in.
  # $responsiveDisplayAd->set_formatSetting("NON_NATIVE");

  # Create ad group ad for the responsive display ad.
  my $responsive_display_ad_group_ad =
    Google::Ads::AdWords::v201802::AdGroupAd->new({
      adGroupId => $ad_group->get_id(),
      ad        => $responsive_display_ad
    });

  my $responsive_display_ad_group_ad_operation =
    Google::Ads::AdWords::v201802::AdGroupAdOperation->new({
      operator => "ADD",
      operand  => $responsive_display_ad_group_ad
    });

  my $result =
    $client->AdGroupAdService()
    ->mutate({operations => [$responsive_display_ad_group_ad_operation]});
  return $result->get_value()->[0];
}

# Creates the additional content (images, promo text, etc.) supported by
# dynamic ads.
sub _create_dynamic_display_ad_settings {
  my ($client) = @_;

  my $logo_image = _upload_image($client, 'https://goo.gl/dEvQeF');
  my $logo = Google::Ads::AdWords::v201802::Image->new({
    mediaId => $logo_image->get_mediaId(),
  });

  my $dynamic_settings = Google::Ads::AdWords::v201802::DynamicSettings->new({
    landscapeLogoImage => $logo,
    pricePrefix        => "as low as",
    promoText          => "Free shipping!"
  });

  return $dynamic_settings;
}

# Uploads the image from the specified URL.
sub _upload_image {
  my ($client, $url) = @_;

  # Creates an image and upload it to the server.
  my $image_data =
    Google::Ads::Common::MediaUtils::get_base64_data_from_url($url);
  my $image = Google::Ads::AdWords::v201802::Image->new({
    data => $image_data,
    type => "IMAGE"
  });

  return $client->MediaService()->upload({media => [$image]});
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
add_shopping_dynamic_remarketing_campaign($client, $merchant_id, $budget_id,
  $user_list_id);
